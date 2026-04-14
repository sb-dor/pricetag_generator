import 'package:flutter/widgets.dart';
import '../../catalog/notifiers/catalog_notifier.dart';
import '../../receipt/notifiers/receipt_notifier.dart';
import '../../template/notifiers/template_notifier.dart';
import 'receipt_settings.dart';

class ReceiptScope extends InheritedWidget {
  final ReceiptNotifier receiptNotifier;
  final CatalogNotifier catalogNotifier;
  final TemplateNotifier templateNotifier;
  final ReceiptSettings settings;

  const ReceiptScope({
    super.key,
    required this.receiptNotifier,
    required this.catalogNotifier,
    required this.templateNotifier,
    required this.settings,
    required super.child,
  });

  static ReceiptScope of(BuildContext context) {
    final s = context.dependOnInheritedWidgetOfExactType<ReceiptScope>();
    assert(s != null, 'No ReceiptScope found in context');
    return s!;
  }

  static ReceiptScope read(BuildContext context) {
    final s = context.getInheritedWidgetOfExactType<ReceiptScope>();
    assert(s != null, 'No ReceiptScope found in context');
    return s!;
  }

  @override
  bool updateShouldNotify(ReceiptScope old) =>
      receiptNotifier != old.receiptNotifier ||
      catalogNotifier != old.catalogNotifier ||
      templateNotifier != old.templateNotifier ||
      settings != old.settings;
}
