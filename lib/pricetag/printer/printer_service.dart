import 'dart:typed_data';
import '../designer/models/label_size.dart';
import '../transport/printer_transport.dart';

abstract class PrinterService {
  /// Send [pngBytes] (PNG image at correct DPI) to the printer via [transport].
  Future<void> printLabel({
    required Uint8List pngBytes,
    required LabelSize size,
    required PrinterTransport transport,
  });
}
