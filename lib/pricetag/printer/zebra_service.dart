import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../designer/models/label_size.dart';
import '../transport/printer_transport.dart';
import 'printer_service.dart';

class ZebraService implements PrinterService {
  @override
  Future<void> printLabel({
    required Uint8List pngBytes,
    required LabelSize size,
    required PrinterTransport transport,
  }) async {
    final decoded = img.decodeImage(pngBytes);
    if (decoded == null) throw Exception('Failed to decode PNG for printing');

    final printWidth = size.widthPx.round();
    final printHeight = size.heightPx.round();
    final resized = img.copyResize(decoded, width: printWidth, height: printHeight);
    final mono = img.grayscale(resized);

    // Convert to 1-bit monochrome hex string for ZPL ^GF command
    final hexData = _toZplHex(mono);
    final totalBytes = hexData.length ~/ 2;
    final rowBytes = (printWidth / 8).ceil();

    // ZPL label
    final zpl = StringBuffer();
    zpl.writeln('^XA');
    zpl.writeln('^CI28'); // UTF-8 encoding
    zpl.writeln('^MMT'); // media type thermal
    zpl.writeln('^PW${size.widthPx.round()}'); // label width in dots
    zpl.writeln('^LL${size.heightPx.round()}'); // label length in dots
    zpl.writeln('^LS0');
    zpl.writeln('^FO0,0');
    // ^GF A=ASCII-hex, total bytes, row bytes, width dots, data
    zpl.writeln('^GFA,$totalBytes,$totalBytes,$rowBytes,$hexData');
    zpl.writeln('^PQ1'); // print 1 copy
    zpl.writeln('^XZ');

    final bytes = utf8.encode(zpl.toString());
    await transport.connect();
    await transport.send(Uint8List.fromList(bytes));
    await transport.disconnect();
  }

  /// Converts a grayscale [image] to ZPL-compatible 1-bit hex string.
  /// A pixel is black (dot printed) if luminance < 128.
  String _toZplHex(img.Image image) {
    final buffer = StringBuffer();
    for (int y = 0; y < image.height; y++) {
      int byte = 0;
      int bitCount = 0;
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final luminance = img.getLuminance(pixel);
        // ZPL: bit=1 means black dot
        byte = (byte << 1) | (luminance < 128 ? 1 : 0);
        bitCount++;
        if (bitCount == 8) {
          buffer.write(byte.toRadixString(16).padLeft(2, '0').toUpperCase());
          byte = 0;
          bitCount = 0;
        }
      }
      // Pad remaining bits in last byte of row
      if (bitCount > 0) {
        byte = byte << (8 - bitCount);
        buffer.write(byte.toRadixString(16).padLeft(2, '0').toUpperCase());
      }
    }
    return buffer.toString();
  }
}
