class Product {
  final String id;
  final String name;
  final double price;
  final String unit; // 'шт', 'кг', 'л', 'м', etc.

  const Product({
    required this.id,
    required this.name,
    required this.price,
    this.unit = 'шт',
  });

  Product copyWith({String? name, double? price, String? unit}) => Product(
        id: id,
        name: name ?? this.name,
        price: price ?? this.price,
        unit: unit ?? this.unit,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'unit': unit,
      };

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j['id'] as String,
        name: j['name'] as String,
        price: (j['price'] as num).toDouble(),
        unit: j['unit'] as String? ?? 'шт',
      );

  static const units = ['шт', 'кг', 'г', 'л', 'мл', 'м', 'см'];
}
