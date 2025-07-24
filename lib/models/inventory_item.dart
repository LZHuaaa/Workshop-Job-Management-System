class InventoryItem {
  final String id;
  final String name;
  final String category;
  final int currentStock;
  final int minStock;
  final int maxStock;
  final double unitPrice;
  final String supplier;
  final String location;
  final String description;
  final DateTime? lastRestocked;
  final String? imageUrl;

  InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.currentStock,
    required this.minStock,
    required this.maxStock,
    required this.unitPrice,
    required this.supplier,
    required this.location,
    required this.description,
    this.lastRestocked,
    this.imageUrl,
  });

  bool get isLowStock => currentStock <= minStock;
  bool get isCriticalStock => currentStock <= (minStock * 0.5);
  bool get isOutOfStock => currentStock == 0;
  bool get isOverstocked => currentStock > maxStock;

  double get stockPercentage => currentStock / maxStock;

  int get stockNeeded => maxStock - currentStock;
  int get stockToReorder => maxStock - currentStock;

  double get totalValue => currentStock * unitPrice;

  InventoryItem copyWith({
    String? id,
    String? name,
    String? category,
    int? currentStock,
    int? minStock,
    int? maxStock,
    double? unitPrice,
    String? supplier,
    String? location,
    String? description,
    DateTime? lastRestocked,
    String? imageUrl,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      currentStock: currentStock ?? this.currentStock,
      minStock: minStock ?? this.minStock,
      maxStock: maxStock ?? this.maxStock,
      unitPrice: unitPrice ?? this.unitPrice,
      supplier: supplier ?? this.supplier,
      location: location ?? this.location,
      description: description ?? this.description,
      lastRestocked: lastRestocked ?? this.lastRestocked,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'currentStock': currentStock,
      'minStock': minStock,
      'maxStock': maxStock,
      'unitPrice': unitPrice,
      'supplier': supplier,
      'location': location,
      'description': description,
      'lastRestocked': lastRestocked?.toIso8601String(),
      'imageUrl': imageUrl,
    };
  }

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      currentStock: json['currentStock'],
      minStock: json['minStock'],
      maxStock: json['maxStock'],
      unitPrice: json['unitPrice'].toDouble(),
      supplier: json['supplier'],
      location: json['location'],
      description: json['description'],
      lastRestocked: json['lastRestocked'] != null
          ? DateTime.parse(json['lastRestocked'])
          : null,
      imageUrl: json['imageUrl'],
    );
  }
}
