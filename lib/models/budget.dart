class Budget {
  final int? id;
  final String monthYear; // e.g., 2025-10
  final double totalLimit;
  final bool rolloverEnabled;
  final double alertThreshold; // Percentage (0.0 to 1.0)
  final DateTime createdAt;

  Budget({
    this.id,
    required this.monthYear,
    required this.totalLimit,
    this.rolloverEnabled = true,
    this.alertThreshold = 0.8, // Default 80%
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'monthYear': monthYear,
      'totalLimit': totalLimit,
      'rolloverEnabled': rolloverEnabled ? 1 : 0,
      'alertThreshold': alertThreshold,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as int?,
      monthYear: map['monthYear'] as String,
      totalLimit: (map['totalLimit'] as num).toDouble(),
      rolloverEnabled: (map['rolloverEnabled'] as int) == 1,
      alertThreshold: (map['alertThreshold'] as num?)?.toDouble() ?? 0.8,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  Budget copyWith({
    int? id,
    String? monthYear,
    double? totalLimit,
    bool? rolloverEnabled,
    double? alertThreshold,
    DateTime? createdAt,
  }) {
    return Budget(
      id: id ?? this.id,
      monthYear: monthYear ?? this.monthYear,
      totalLimit: totalLimit ?? this.totalLimit,
      rolloverEnabled: rolloverEnabled ?? this.rolloverEnabled,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
