class MonthlyBalance {
  final int? id;
  final String monthYear;
  final double initialBalance;
  final DateTime createdAt;

  MonthlyBalance({
    this.id,
    required this.monthYear,
    required this.initialBalance,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'monthYear': monthYear,
      'initialBalance': initialBalance,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory MonthlyBalance.fromMap(Map<String, dynamic> map) {
    return MonthlyBalance(
      id: map['id'],
      monthYear: map['monthYear'],
      initialBalance: map['initialBalance'].toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }

  MonthlyBalance copyWith({
    int? id,
    String? monthYear,
    double? initialBalance,
    DateTime? createdAt,
  }) {
    return MonthlyBalance(
      id: id ?? this.id,
      monthYear: monthYear ?? this.monthYear,
      initialBalance: initialBalance ?? this.initialBalance,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}


