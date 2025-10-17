import 'dart:convert';

class SharedBudget {
  final int? id;
  final String name;
  final String monthYear;
  final double totalLimit;
  final String ownerId;
  final List<String> memberIds;
  final Map<String, String> roles; // userId -> role (owner, admin, member)
  final DateTime createdAt;
  final DateTime updatedAt;

  SharedBudget({
    this.id,
    required this.name,
    required this.monthYear,
    required this.totalLimit,
    required this.ownerId,
    required this.memberIds,
    required this.roles,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'monthYear': monthYear,
      'totalLimit': totalLimit,
      'ownerId': ownerId,
      'memberIds': memberIds.join(','),
      'roles': roles.entries.map((e) => '${e.key}:${e.value}').join(','),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory SharedBudget.fromMap(Map<String, dynamic> map) {
    return SharedBudget(
      id: map['id'] as int?,
      name: map['name'] as String,
      monthYear: map['monthYear'] as String,
      totalLimit: (map['totalLimit'] as num).toDouble(),
      ownerId: map['ownerId'] as String,
      memberIds: (map['memberIds'] as String).split(',').where((id) => id.isNotEmpty).toList(),
      roles: Map.fromEntries(
        (map['roles'] as String)
            .split(',')
            .where((role) => role.isNotEmpty)
            .map((role) {
          final parts = role.split(':');
          return MapEntry(parts[0], parts[1]);
        }),
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
    );
  }

  SharedBudget copyWith({
    int? id,
    String? name,
    String? monthYear,
    double? totalLimit,
    String? ownerId,
    List<String>? memberIds,
    Map<String, String>? roles,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SharedBudget(
      id: id ?? this.id,
      name: name ?? this.name,
      monthYear: monthYear ?? this.monthYear,
      totalLimit: totalLimit ?? this.totalLimit,
      ownerId: ownerId ?? this.ownerId,
      memberIds: memberIds ?? this.memberIds,
      roles: roles ?? this.roles,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool isOwner(String userId) => ownerId == userId;
  bool isAdmin(String userId) => roles[userId] == 'admin';
  bool isMember(String userId) => memberIds.contains(userId);
  bool canEdit(String userId) => isOwner(userId) || isAdmin(userId);
  bool canView(String userId) => isMember(userId);
}

class ActivityFeedItem {
  final int? id;
  final String sharedBudgetId;
  final String userId;
  final String action; // created, updated, added_member, removed_member, added_transaction
  final String description;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  ActivityFeedItem({
    this.id,
    required this.sharedBudgetId,
    required this.userId,
    required this.action,
    required this.description,
    required this.metadata,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sharedBudgetId': sharedBudgetId,
      'userId': userId,
      'action': action,
      'description': description,
      'metadata': jsonEncode(metadata),
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory ActivityFeedItem.fromMap(Map<String, dynamic> map) {
    return ActivityFeedItem(
      id: map['id'] as int?,
      sharedBudgetId: map['sharedBudgetId'] as String,
      userId: map['userId'] as String,
      action: map['action'] as String,
      description: map['description'] as String,
      metadata: Map<String, dynamic>.from(jsonDecode(map['metadata'] as String)),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }
}
