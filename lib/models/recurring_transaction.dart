class RecurringTransaction {
  final int? id;
  final String name;
  final double amount;
  final String category;
  final bool isTiffin;
  final String frequency; // daily, weekly, monthly
  final int? dayOfMonth; // for monthly (1-31)
  final int? weekday; // for weekly (1-7, Mon-Sun)
  final DateTime nextRunAt;

  RecurringTransaction({
    this.id,
    required this.name,
    required this.amount,
    required this.category,
    this.isTiffin = false,
    required this.frequency,
    this.dayOfMonth,
    this.weekday,
    required this.nextRunAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'category': category,
      'isTiffin': isTiffin ? 1 : 0,
      'frequency': frequency,
      'dayOfMonth': dayOfMonth,
      'weekday': weekday,
      'nextRunAt': nextRunAt.millisecondsSinceEpoch,
    };
  }

  factory RecurringTransaction.fromMap(Map<String, dynamic> map) {
    return RecurringTransaction(
      id: map['id'] as int?,
      name: map['name'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      isTiffin: (map['isTiffin'] as int) == 1,
      frequency: map['frequency'] as String,
      dayOfMonth: map['dayOfMonth'] as int?,
      weekday: map['weekday'] as int?,
      nextRunAt: DateTime.fromMillisecondsSinceEpoch(map['nextRunAt'] as int),
    );
  }

  RecurringTransaction copyWith({
    int? id,
    String? name,
    double? amount,
    String? category,
    bool? isTiffin,
    String? frequency,
    int? dayOfMonth,
    int? weekday,
    DateTime? nextRunAt,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      isTiffin: isTiffin ?? this.isTiffin,
      frequency: frequency ?? this.frequency,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      weekday: weekday ?? this.weekday,
      nextRunAt: nextRunAt ?? this.nextRunAt,
    );
  }

  // Calculate next run date based on frequency
  DateTime calculateNextRun() {
    final now = DateTime.now();
    switch (frequency) {
      case 'daily':
        return DateTime(now.year, now.month, now.day + 1);
      case 'weekly':
        final daysUntilNext = (weekday! - now.weekday + 7) % 7;
        return DateTime(now.year, now.month, now.day + (daysUntilNext == 0 ? 7 : daysUntilNext));
      case 'monthly':
        final nextMonth = DateTime(now.year, now.month + 1, 1);
        final lastDayOfMonth = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
        final targetDay = dayOfMonth! > lastDayOfMonth ? lastDayOfMonth : dayOfMonth!;
        return DateTime(nextMonth.year, nextMonth.month, targetDay);
      default:
        return now.add(const Duration(days: 1));
    }
  }
}
