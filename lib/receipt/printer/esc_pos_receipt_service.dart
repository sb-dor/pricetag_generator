import 'dart:typed_data';

import 'package:flutter/material.dart' show TextAlign;

import '../../pricetag/transport/printer_transport.dart';
import '../receipt/models/receipt.dart';
import '../receipt/models/receipt_item.dart';
import '../template/models/receipt_block.dart';
import '../template/models/receipt_template.dart';
import 'receipt_printer_service.dart';

/// ESC/POS receipt printer using raw byte commands.
///
/// All text is encoded manually to CP866 (DOS Russian) and written as raw
/// bytes — this bypasses any encoding transformation inside third-party
/// generator libraries, guaranteeing that Cyrillic characters are sent
/// correctly to the printer.
class EscPosReceiptService implements ReceiptPrinterService {
  // ── ESC/POS raw command constants ─────────────────────────────────────────

  // Reset printer
  static const _reset = [0x1B, 0x40];

  // Code page: CP866 (DOS Russian) = table 17
  static const _cp866 = [0x1B, 0x74, 0x11];

  // Bold on / off
  static const _boldOn = [0x1B, 0x45, 0x01];
  static const _boldOff = [0x1B, 0x45, 0x00];

  // Double-height on / off  (for store header)
  static const _dblHOn = [0x1B, 0x21, 0x10];
  static const _dblHOff = [0x1B, 0x21, 0x00];

  // Alignment: left / center / right
  static const _left = [0x1B, 0x61, 0x00];
  static const _center = [0x1B, 0x61, 0x01];
  static const _right = [0x1B, 0x61, 0x02];

  // Line feed
  static const _lf = [0x0A];

  // Feed N lines: [0x1B, 0x64, n]
  static List<int> _feedLines(int n) => [0x1B, 0x64, n];

  // Partial cut
  static const _cut = [0x1D, 0x56, 0x42, 0x00];

  // ── Public API ─────────────────────────────────────────────────────────────

  @override
  Future<void> printReceipt({
    required Receipt receipt,
    required ReceiptTemplate template,
    required PrinterTransport transport,
  }) async {
    final bytes = _buildCommands(receipt, template);
    await transport.connect();
    await transport.send(Uint8List.fromList(bytes));
    await transport.disconnect();
  }

  // ── Command builder ────────────────────────────────────────────────────────

  List<int> _buildCommands(Receipt receipt, ReceiptTemplate template) {
    final buf = <int>[];
    final cols = template.cols;

    buf
      ..addAll(_reset)
      ..addAll(_cp866);

    for (final block in template.blocks.where((b) => b.visible)) {
      _writeBlock(buf, block, receipt, cols);
    }

    buf
      ..addAll(_feedLines(4))
      ..addAll(_cut);

    return buf;
  }

  // ── Block renderers ────────────────────────────────────────────────────────

  void _writeBlock(List<int> buf, ReceiptBlock block, Receipt receipt, int cols) {
    switch (block) {
      case HeaderBlock b:
        final name = b.storeName.isNotEmpty ? b.storeName : receipt.storeName;
        buf
          ..addAll(_alignCmd(b.align))
          ..addAll(_boldOn)
          ..addAll(_dblHOn)
          ..addAll(_encode(name))
          ..addAll(_dblHOff)
          ..addAll(_boldOff)
          ..addAll(_lf);
        if (b.subtitle != null && b.subtitle!.isNotEmpty) {
          buf
            ..addAll(_alignCmd(b.align))
            ..addAll(_encode(b.subtitle!))
            ..addAll(_lf);
        }

      case DateTimeBlock b:
        buf
          ..addAll(_left)
          ..addAll(_encode(_formatDate(DateTime.now(), b.format)))
          ..addAll(_lf);

      case DividerBlock b:
        buf
          ..addAll(_left)
          ..addAll(_encode(b.char * cols))
          ..addAll(_lf);

      case ItemsTableBlock b:
        for (final item in receipt.items) {
          _writeItem(buf, item, b, cols);
        }

      case TotalsBlock b:
        _writeTotals(buf, b, receipt, cols);

      case FooterBlock b:
        buf
          ..addAll(_alignCmd(b.align))
          ..addAll(_encode(b.text))
          ..addAll(_lf);

      case CustomTextBlock b:
        if (b.isBold) buf.addAll(_boldOn);
        buf
          ..addAll(_alignCmd(b.align))
          ..addAll(_encode(b.text))
          ..addAll(_lf);
        if (b.isBold) buf.addAll(_boldOff);
    }
  }

  void _writeItem(List<int> buf, ReceiptItem item, ItemsTableBlock block, int cols) {
    final unit = block.showUnit ? ' ${item.product.unit}' : '';
    final qty = _fmtNum(item.qty);
    final price = _fmtMoney(item.product.price);
    final right = '$qty$unit x ${price}r.'; // 'r.' instead of ₽ (not in CP866)
    final left = item.product.name;

    buf
      ..addAll(_left)
      ..addAll(_encode(_padRow(left, right, cols)))
      ..addAll(_lf);

    if (block.showDiscount && item.hasDiscount) {
      final disc = '  Скидка ${item.discountPct!.toStringAsFixed(0)}%:';
      final discAmt = '-${_fmtMoney(item.lineDiscount)}r.';
      buf
        ..addAll(_left)
        ..addAll(_encode(_padRow(disc, discAmt, cols)))
        ..addAll(_lf);
    }
  }

  void _writeTotals(List<int> buf, TotalsBlock block, Receipt receipt, int cols) {
    if (block.showSubtotal && receipt.hasDiscount) {
      // Itogo bez skidki
      buf
        ..addAll(_left)
        ..addAll(_encode(_padRow('Итого без скидки:', '${_fmtMoney(receipt.subtotal)}r.', cols)))
        ..addAll(_lf);
    }
    if (block.showDiscountLine && receipt.hasDiscount) {
      buf
        ..addAll(_left)
        ..addAll(_encode(_padRow('Скидка:', '-${_fmtMoney(receipt.totalDiscount)}r.', cols)))
        ..addAll(_lf);
    }
    buf
      ..addAll(_left)
      ..addAll(_boldOn)
      ..addAll(_encode(_padRow('ИТОГО:', '${_fmtMoney(receipt.total)}р.', cols)))
      ..addAll(_boldOff)
      ..addAll(_lf);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  List<int> _alignCmd(TextAlign align) => switch (align) {
    TextAlign.center => _center,
    TextAlign.right => _right,
    _ => _left,
  };

  /// Left-pad [right] so the combined line fills [cols] characters.
  String _padRow(String left, String right, int cols) {
    final gap = cols - left.length - right.length;
    if (gap <= 0) return '$left $right';
    return '$left${' ' * gap}$right';
  }

  String _fmtMoney(double v) => v.toStringAsFixed(2);

  String _fmtNum(double v) => v == v.truncateToDouble() ? v.toInt().toString() : v.toString();

  String _formatDate(DateTime dt, String fmt) => fmt
      .replaceAll('dd', dt.day.toString().padLeft(2, '0'))
      .replaceAll('MM', dt.month.toString().padLeft(2, '0'))
      .replaceAll('yyyy', dt.year.toString())
      .replaceAll('HH', dt.hour.toString().padLeft(2, '0'))
      .replaceAll('mm', dt.minute.toString().padLeft(2, '0'));

  // ── CP866 encoder ──────────────────────────────────────────────────────────

  /// Converts a Dart [String] to a CP866 byte list for direct ESC/POS
  /// transmission. ASCII (< 0x80) is passed through unchanged.
  List<int> _encode(String input) {
    final bytes = <int>[];
    for (final rune in input.runes) {
      if (rune < 0x80) {
        bytes.add(rune);
      } else if (rune >= 0x0410 && rune <= 0x042F) {
        bytes.add(rune - 0x0410 + 0x80); // А–Я → 0x80–0x9F
      } else if (rune >= 0x0430 && rune <= 0x043F) {
        bytes.add(rune - 0x0430 + 0xA0); // а–п → 0xA0–0xAF
      } else if (rune >= 0x0440 && rune <= 0x044F) {
        bytes.add(rune - 0x0440 + 0xE0); // р–я → 0xE0–0xEF
      } else if (rune == 0x0401) {
        bytes.add(0xF0); // Ё
      } else if (rune == 0x0451) {
        bytes.add(0xF1); // ё
      } else {
        bytes.add(0x3F); // '?' for anything else (e.g. ₽)
      }
    }
    return bytes;
  }
}
