import '../../catalog/models/product.dart';

class ReceiptItem {
  final Product product;
  final double qty;
  final double? discountPct; // null = no discount

  const ReceiptItem({required this.product, required this.qty, this.discountPct});

  double get lineSubtotal => product.price * qty;
  double get lineDiscount => discountPct != null ? lineSubtotal * discountPct! / 100 : 0;
  double get lineTotal => lineSubtotal - lineDiscount;
  bool get hasDiscount => discountPct != null && discountPct! > 0;

  ReceiptItem copyWith({double? qty, double? discountPct, bool clearDiscount = false}) =>
      ReceiptItem(
        product: product,
        qty: qty ?? this.qty,
        discountPct: clearDiscount ? null : (discountPct ?? this.discountPct),
      );
}
