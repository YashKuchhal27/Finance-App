class Category {
  final int? id;
  final String name;
  final bool isDefault;
  final String color;

  Category({
    this.id,
    required this.name,
    this.isDefault = false,
    this.color = '#2196F3',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isDefault': isDefault ? 1 : 0,
      'color': color,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      isDefault: map['isDefault'] == 1,
      color: map['color'],
    );
  }

  Category copyWith({
    int? id,
    String? name,
    bool? isDefault,
    String? color,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      isDefault: isDefault ?? this.isDefault,
      color: color ?? this.color,
    );
  }
}


