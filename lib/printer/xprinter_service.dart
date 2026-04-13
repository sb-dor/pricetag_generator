import 'dart:typed_data';
import 'package:esc_pos_utils_updated/esc_pos_utils_updated.dart';
import 'package:image/image.dart' as img;
import '../designer/models/label_size.dart';
import '../transport/printer_transport.dart';
import 'printer_service.dart';

class XprinterService implements PrinterService {
  @override
  Future<void> printLabel({
    required Uint8List pngBytes,
    required LabelSize size,
    required PrinterTransport transport,
  }) async {
    // Decode PNG → image package Image
    final decoded = img.decodeImage(pngBytes);
    if (decoded == null) throw Exception('Failed to decode PNG for printing');

    // Resize to exact printer dots
    final printWidth = size.widthPx.round();
    final printHeight = size.heightPx.round();
    final resized = img.copyResize(decoded, width: printWidth, height: printHeight);

    // Convert to monochrome (1-bit) for ESC/POS raster
    final mono = img.grayscale(resized);

    // Build ESC/POS commands
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);

    List<int> bytes = [];
    bytes += generator.reset();
    bytes += generator.imageRaster(mono, imageFn: PosImageFn.bitImageRaster);
    bytes += generator.feed(1);
    bytes += generator.cut();

    await transport.connect();
    await transport.send(Uint8List.fromList(bytes));
    await transport.disconnect();
  }
}
