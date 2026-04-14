import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart' show TextAlign;
import '../../pricetag/transport/printer_transport.dart';
import '../receipt/models/receipt.dart';
import '../template/models/receipt_block.dart';
import '../template/models/receipt_template.dart';
import 'receipt_printer_service.dart';

class ZplReceiptService implements ReceiptPrinterService {
  @override
  Future<void> printReceipt({
    required Receipt receipt,
    required ReceiptTemplate template,
    required PrinterTransport transport,
  }) async {
    final zpl = _buildZpl(receipt, template);
    final bytes = utf8.encode(zpl);
    await transport.connect();
    await transport.send(Uint8List.fromList(bytes));
    await transport.disconnect();
  }

  String _buildZpl(Receipt receipt, ReceiptTemplate template) {
    final buf = StringBuffer();
    final dotsPerMm = 8; // 203 dpi ≈ 8 dots/mm
    final widthDots = template.paperWidthMm * dotsPerMm;
    final fontWidth = 18;
    final lineHeight = 28;
    int y = 30;

    buf.writeln('^XA');
    buf.writeln('^CI28');           // UTF-8
    buf.writeln('^PW$widthDots');   // paper width in dots
    buf.writeln('^LL2000');         // label length (generous; auto-cut at ^XZ)
    buf.writeln('^LH0,0');
    buf.writeln('^MTT');

    void addLine(String text,
        {bool bold = false, TextAlign align = TextAlign.left, int? yOverride}) {
      final yCurrent = yOverride ?? y;
      final fontName = bold ? 'B' : 'A';
      final x = switch (align) {
        TextAlign.center => (widthDots - text.length * fontWidth) ~/ 2,
        TextAlign.right => widthDots - text.length * fontWidth - 10,
        _ => 10,
      };
      buf.writeln('^FO${x.clamp(0, widthDots)},$yCurrent^A${fontName}N,${bold ? 30 : 24},${bold ? 16 : 13}^FD$text^FS');
      y = yCurrent + lineHeight;
    }

    void addDivider(String char) {
      final cols = template.cols;
      addLine(char * cols);
    }

    for (final block in template.blocks.where((b) => b.visible)) {
      switch (block) {
        case HeaderBlock b:
          final name =
              b.storeName.isNotEmpty ? b.storeName : receipt.storeName;
          addLine(name, bold: true, align: b.align);
          if (b.subtitle != null && b.subtitle!.isNotEmpty) {
            addLine(b.subtitle!, align: b.align);
          }

        case DateTimeBlock b:
          final now = DateTime.now();
          addLine(_formatDate(now, b.format));

        case DividerBlock b:
          addDivider(b.char);

        case ItemsTableBlock b:
          for (final item in receipt.items) {
            final unit = b.showUnit ? ' ${item.product.unit}' : '';
            final line =
                '${item.product.name}  ${_fmtNum(item.qty)}$unit x ${_fmtMoney(item.product.price)}\u20bd';
            addLine(line);
            if (b.showDiscount && item.hasDiscount) {
              addLine(
                  '  \u0421\u043a\u0438\u0434\u043a\u0430 ${item.discountPct!.toStringAsFixed(0)}%: -${_fmtMoney(item.lineDiscount)}\u20bd');
            }
          }

        case TotalsBlock b:
          if (b.showSubtotal && receipt.hasDiscount) {
            addLine(
                '\u0418\u0442\u043e\u0433\u043e \u0431\u0435\u0437 \u0441\u043a\u0438\u0434\u043a\u0438: ${_fmtMoney(receipt.subtotal)}\u20bd');
          }
          if (b.showDiscountLine && receipt.hasDiscount) {
            addLine(
                '\u0421\u043a\u0438\u0434\u043a\u0430: -${_fmtMoney(receipt.totalDiscount)}\u20bd');
          }
          addLine('\u0418\u0422\u041e\u0413\u041e: ${_fmtMoney(receipt.total)}\u20bd',
              bold: true);

        case FooterBlock b:
          addLine(b.text, align: b.align);

        case CustomTextBlock b:
          addLine(b.text, bold: b.isBold, align: b.align);
      }
    }

    buf.writeln('^PQ1');
    buf.writeln('^XZ');
    return buf.toString();
  }

  String _fmtMoney(double v) => v.toStringAsFixed(2);
  String _fmtNum(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toString();

  String _formatDate(DateTime dt, String fmt) => fmt
      .replaceAll('dd', dt.day.toString().padLeft(2, '0'))
      .replaceAll('MM', dt.month.toString().padLeft(2, '0'))
      .replaceAll('yyyy', dt.year.toString())
      .replaceAll('HH', dt.hour.toString().padLeft(2, '0'))
      .replaceAll('mm', dt.minute.toString().padLeft(2, '0'));
}
