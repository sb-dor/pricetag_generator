import '../../receipt/models/receipt.dart';
import '../../template/models/receipt_template.dart';

abstract interface class IEscPosReceiptLayout {
  /// Builds the full ESC/POS byte sequence for the given [receipt] and [template].
  List<int> build(Receipt receipt, ReceiptTemplate template);
}
