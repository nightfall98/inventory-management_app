class Item {
  String? id;
  String name;
  int quantity;
  String category;
  String? description;
  String? createdAt;
  String? userId;

  Item({
    this.id,
    required this.name,
    required this.quantity,
    required this.category,
    this.description,
    this.createdAt,
    this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'category': category,
      'description': description,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
      'userId': userId,
    };
  }

  // For SQLite compatibility
  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id']?.toString(),
      name: map['name'],
      quantity: map['quantity'],
      category: map['category'],
      description: map['description'],
      createdAt: map['created_at'],
      userId: map['userId'],
    );
  }

  // For Firebase Firestore
  factory Item.fromFirestore(Map<String, dynamic> data) {
    return Item(
      id: data['id'],
      name: data['name'] ?? '',
      quantity: data['quantity'] ?? 0,
      category: data['category'] ?? '',
      description: data['description'],
      createdAt: data['created_at']?.toString(),
      userId: data['userId'],
    );
  }

  // Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'quantity': quantity,
      'category': category,
      'description': description,
      'userId': userId,
    };
  }

  // Create a copy with updated fields
  Item copyWith({
    String? id,
    String? name,
    int? quantity,
    String? category,
    String? description,
    String? createdAt,
    String? userId,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
    );
  }

  @override
  String toString() {
    return 'Item{id: $id, name: $name, quantity: $quantity, category: $category, description: $description, userId: $userId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Item && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
