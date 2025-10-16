class Transaction {
  final int? id;
  final String name;
  final double amount;
  final String category;
  final DateTime dateTime;
  final bool isTiffin;
  final String monthYear;
  final String? receiptPath; // local file path to receipt image

  Transaction({
    this.id,
    required this.name,
    required this.amount,
    required this.category,
    required this.dateTime,
    this.isTiffin = false,
    required this.monthYear,
    this.receiptPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'category': category,
      'dateTime': dateTime.millisecondsSinceEpoch,
      'isTiffin': isTiffin ? 1 : 0,
      'monthYear': monthYear,
      'receiptPath': receiptPath,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      name: map['name'],
      amount: map['amount'].toDouble(),
      category: map['category'],
      dateTime: DateTime.fromMillisecondsSinceEpoch(map['dateTime']),
      isTiffin: map['isTiffin'] == 1,
      monthYear: map['monthYear'],
      receiptPath: map['receiptPath'] as String?,
    );
  }

  Transaction copyWith({
    int? id,
    String? name,
    double? amount,
    String? category,
    DateTime? dateTime,
    bool? isTiffin,
    String? monthYear,
    String? receiptPath,
  }) {
    return Transaction(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      dateTime: dateTime ?? this.dateTime,
      isTiffin: isTiffin ?? this.isTiffin,
      monthYear: monthYear ?? this.monthYear,
      receiptPath: receiptPath ?? this.receiptPath,
    );
  }
}
