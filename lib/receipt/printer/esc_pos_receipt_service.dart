import 'dart:typed_data';

import '../../pricetag/transport/printer_transport.dart';
import '../receipt/models/receipt.dart';
import '../template/models/receipt_template.dart';
import 'i_receipt_printer_service.dart';
import 'layouts/default_esc_layout.dart';
import 'layouts/i_esc_pos_receipt_layout.dart';

/// ESC/POS receipt printer using raw byte commands.
///
/// Delegates all byte-building to an [EscPosReceiptLayout] strategy.
/// Pass a custom layout to the constructor, or leave [layout] null to use
/// the default block-based layout ([DefaultEscLayout]).
class EscPosReceiptService implements IReceiptPrinterService {
  const EscPosReceiptService({final IEscPosReceiptLayout? layout})
    : layout = layout ?? const DefaultEscLayout();

  final IEscPosReceiptLayout layout;

  @override
  Future<void> printReceipt({
    required Receipt receipt,
    required ReceiptTemplate template,
    required PrinterTransport transport,
  }) async {
    final bytes = layout.build(receipt, template);
    await transport.connect();
    await transport.send(Uint8List.fromList(bytes));
    await transport.disconnect();
  }
}
