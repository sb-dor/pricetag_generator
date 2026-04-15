import 'receipt_item.dart';

class Receipt {
  const Receipt({
    required this.storeName,
    required this.items,
    required this.printedAt,
    this.customerCode,
    this.customerName,
    this.previousDebt,
  });

  final String storeName;
  final List<ReceiptItem> items;
  final DateTime printedAt;

  /// Optional customer info printed after СДАЧА.
  ///
  /// Example:
  /// ```
  /// Receipt(
  ///   customerCode: '123456987',
  ///   customerName: 'Mansur',
  ///   previousDebt: 170,
  /// )
  /// ```
  /// When [customerCode] or [customerName] is provided the section is printed.
  /// [currentDebt] is computed automatically as [previousDebt] + receipt.total.
  final String? customerCode;
  final String? customerName;
  final double? previousDebt;

  double get subtotal => items.fold(0.0, (s, i) => s + i.lineSubtotal);

  double get totalDiscount => items.fold(0.0, (s, i) => s + i.lineDiscount);

  double get total => subtotal - totalDiscount;

  bool get hasDiscount => totalDiscount > 0;

  bool get isEmpty => items.isEmpty;
}
