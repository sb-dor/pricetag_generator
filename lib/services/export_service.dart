import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../designer/models/label_size.dart';

class ExportService {
  /// Export canvas as PDF at exact label dimensions and open share/save dialog.
  Future<void> saveAsPdf(Uint8List pngBytes, LabelSize size) async {
    final doc = pw.Document();
    final image = pw.MemoryImage(pngBytes);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          size.widthMm * PdfPageFormat.mm,
          size.heightMm * PdfPageFormat.mm,
          marginAll: 0,
        ),
        build: (_) => pw.Image(image, fit: pw.BoxFit.fill),
      ),
    );

    final pdfBytes = await doc.save();

    // Printing.sharePdf handles save dialog on desktop, share sheet on mobile
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'pricetag_${size.widthMm.toInt()}x${size.heightMm.toInt()}mm.pdf',
    );
  }

  /// Export canvas as PNG image and open share/save dialog.
  Future<void> saveAsImage(Uint8List pngBytes, LabelSize size) async {
    final filename = 'pricetag_${size.widthMm.toInt()}x${size.heightMm.toInt()}mm.png';
    final file = await _writeTempFile(filename, pngBytes);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'image/png')],
      subject: 'Ценник ${size.name}',
    );
  }

  Future<File> _writeTempFile(String filename, Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    return file;
  }
}