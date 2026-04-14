import '../../pricetag/transport/printer_transport.dart';
import '../receipt/models/receipt.dart';
import '../template/models/receipt_template.dart';

abstract class ReceiptPrinterService {
  Future<void> printReceipt({
    required Receipt receipt,
    required ReceiptTemplate template,
    required PrinterTransport transport,
  });
}
