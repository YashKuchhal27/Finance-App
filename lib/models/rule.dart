class Rule {
  final int? id;
  final String name;
  final String condition; // merchant_contains, amount_greater_than, etc.
  final String conditionValue; // "Starbucks", "100", etc.
  final String action; // set_category, set_tiffin, add_tag, etc.
  final String actionValue; // "Food", "true", "coffee", etc.
  final bool isActive;
  final int priority; // Higher number = higher priority
  final DateTime createdAt;

  Rule({
    this.id,
    required this.name,
    required this.condition,
    required this.conditionValue,
    required this.action,
    required this.actionValue,
    this.isActive = true,
    this.priority = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'condition': condition,
      'conditionValue': conditionValue,
      'action': action,
      'actionValue': actionValue,
      'isActive': isActive ? 1 : 0,
      'priority': priority,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Rule.fromMap(Map<String, dynamic> map) {
    return Rule(
      id: map['id'] as int?,
      name: map['name'] as String,
      condition: map['condition'] as String,
      conditionValue: map['conditionValue'] as String,
      action: map['action'] as String,
      actionValue: map['actionValue'] as String,
      isActive: (map['isActive'] as int) == 1,
      priority: map['priority'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  Rule copyWith({
    int? id,
    String? name,
    String? condition,
    String? conditionValue,
    String? action,
    String? actionValue,
    bool? isActive,
    int? priority,
    DateTime? createdAt,
  }) {
    return Rule(
      id: id ?? this.id,
      name: name ?? this.name,
      condition: condition ?? this.condition,
      conditionValue: conditionValue ?? this.conditionValue,
      action: action ?? this.action,
      actionValue: actionValue ?? this.actionValue,
      isActive: isActive ?? this.isActive,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Check if this rule matches a transaction
  bool matches(Map<String, dynamic> transactionData) {
    if (!isActive) return false;

    switch (condition) {
      case 'merchant_contains':
        final merchant = (transactionData['name'] as String).toLowerCase();
        return merchant.contains(conditionValue.toLowerCase());
      
      case 'merchant_equals':
        final merchant = (transactionData['name'] as String).toLowerCase();
        return merchant == conditionValue.toLowerCase();
      
      case 'amount_greater_than':
        final amount = transactionData['amount'] as double;
        return amount > double.parse(conditionValue);
      
      case 'amount_less_than':
        final amount = transactionData['amount'] as double;
        return amount < double.parse(conditionValue);
      
      case 'category_equals':
        final category = transactionData['category'] as String;
        return category == conditionValue;
      
      case 'is_tiffin':
        final isTiffin = transactionData['isTiffin'] as bool;
        return isTiffin == (conditionValue.toLowerCase() == 'true');
      
      default:
        return false;
    }
  }

  // Apply this rule to a transaction
  Map<String, dynamic> apply(Map<String, dynamic> transactionData) {
    final result = Map<String, dynamic>.from(transactionData);

    switch (action) {
      case 'set_category':
        result['category'] = actionValue;
        break;
      
      case 'set_tiffin':
        result['isTiffin'] = actionValue.toLowerCase() == 'true';
        break;
      
      case 'add_tag':
        final existingTags = (result['tags'] as String?)?.split(',') ?? <String>[];
        if (!existingTags.contains(actionValue)) {
          existingTags.add(actionValue);
          result['tags'] = existingTags.join(',');
        }
        break;
      
      case 'set_merchant':
        result['name'] = actionValue;
        break;
    }

    return result;
  }
}

class RuleEngine {
  static List<Rule> _rules = [];

  static void loadRules(List<Rule> rules) {
    _rules = rules..sort((a, b) => b.priority.compareTo(a.priority));
  }

  static Map<String, dynamic> processTransaction(Map<String, dynamic> transactionData) {
    var result = Map<String, dynamic>.from(transactionData);

    for (final rule in _rules) {
      if (rule.matches(result)) {
        result = rule.apply(result);
      }
    }

    return result;
  }

  static List<Rule> getRules() => List.unmodifiable(_rules);
  
  static void addRule(Rule rule) {
    _rules.add(rule);
    _rules.sort((a, b) => b.priority.compareTo(a.priority));
  }
  
  static void removeRule(int ruleId) {
    _rules.removeWhere((rule) => rule.id == ruleId);
  }
  
  static void updateRule(Rule updatedRule) {
    final index = _rules.indexWhere((rule) => rule.id == updatedRule.id);
    if (index != -1) {
      _rules[index] = updatedRule;
      _rules.sort((a, b) => b.priority.compareTo(a.priority));
    }
  }
}
