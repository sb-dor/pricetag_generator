class ReceiptItem {
  final String id;
  final String label;
  final String unit;
  final double price;
  final double qty;
  final double? discountPct; // null = no discount

  const ReceiptItem({
    required this.id,
    required this.label,
    required this.unit,
    required this.price,
    required this.qty,
    this.discountPct,
  });

  double get lineSubtotal => price * qty;

  double get lineDiscount => discountPct != null ? lineSubtotal * discountPct! / 100 : 0;

  double get lineTotal => lineSubtotal - lineDiscount;
  
  bool get hasDiscount => discountPct != null && discountPct! > 0;

  ReceiptItem copyWith({
    final String? id,
    final String? label,
    final String? unit,
    final double? price,
    final double? qty,
    final double? discountPct,
    bool clearDiscount = false,
  }) => ReceiptItem(
    id: id ?? this.id,
    label: label ?? this.label,
    unit: unit ?? this.unit,
    price: price ?? this.price,
    qty: qty ?? this.qty,
    discountPct: clearDiscount ? null : (discountPct ?? this.discountPct),
  );
}
