import 'package:flutter/material.dart' show TextAlign;

import '../../receipt/models/receipt.dart';
import '../../receipt/models/receipt_item.dart';
import '../../template/models/receipt_block.dart';
import '../../template/models/receipt_template.dart';
import 'i_esc_pos_receipt_layout.dart';

/// Default block-based ESC/POS layout.
///
/// This is the original [_buildCommands] logic extracted verbatim from
/// [EscPosReceiptService]. Renders receipt using the block list from the template.
class DefaultEscLayout implements IEscPosReceiptLayout {
  const DefaultEscLayout();

  // ── ESC/POS raw command constants ─────────────────────────────────────────

  static const _reset = [0x1B, 0x40];
  static const _cp866 = [0x1B, 0x74, 0x11];
  static const _boldOn = [0x1B, 0x45, 0x01];
  static const _boldOff = [0x1B, 0x45, 0x00];
  static const _dblHOn = [0x1B, 0x21, 0x10];
  static const _dblHOff = [0x1B, 0x21, 0x00];
  static const _left = [0x1B, 0x61, 0x00];
  static const _center = [0x1B, 0x61, 0x01];
  static const _right = [0x1B, 0x61, 0x02];
  static const _lf = [0x0A];
  static const _cut = [0x1D, 0x56, 0x42, 0x00];

  static List<int> _feedLines(int n) => [0x1B, 0x64, n];

  // ── EscPosReceiptLayout ────────────────────────────────────────────────────

  @override
  List<int> build(Receipt receipt, ReceiptTemplate template) {
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
        final name = b.storeName ?? receipt.storeName;
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
    final unit = block.showUnit ? ' ${item.unit}' : '';
    final qty = _fmtNum(item.qty);
    final price = _fmtMoney(item.price);
    final right = '$qty$unit x $price';
    final left = item.label;

    buf
      ..addAll(_left)
      ..addAll(_encode(_padRow(left, right, cols)))
      ..addAll(_lf);

    if (block.showDiscount && item.hasDiscount) {
      final disc = 'Скидка ${item.discountPct!.toStringAsFixed(0)}%:';
      final discAmt = '-${_fmtMoney(item.lineDiscount)}';
      buf
        ..addAll(_left)
        ..addAll(_encode(_padRow(disc, discAmt, cols)))
        ..addAll(_lf);
    }
  }

  void _writeTotals(List<int> buf, TotalsBlock block, Receipt receipt, int cols) {
    if (block.showSubtotal && receipt.hasDiscount) {
      buf
        ..addAll(_left)
        ..addAll(_encode(_padRow('Итого без скидки:', _fmtMoney(receipt.subtotal), cols)))
        ..addAll(_lf);
    }
    if (block.showDiscountLine && receipt.hasDiscount) {
      buf
        ..addAll(_left)
        ..addAll(_encode(_padRow('Скидка:', '-${_fmtMoney(receipt.totalDiscount)}', cols)))
        ..addAll(_lf);
    }
    buf
      ..addAll(_left)
      ..addAll(_boldOn)
      ..addAll(_encode(_padRow('ИТОГО:', _fmtMoney(receipt.total), cols)))
      ..addAll(_boldOff)
      ..addAll(_lf);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  List<int> _alignCmd(TextAlign align) => switch (align) {
    TextAlign.center => _center,
    TextAlign.right => _right,
    _ => _left,
  };

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

  List<int> _encode(String input) {
    final bytes = <int>[];
    for (final rune in input.runes) {
      if (rune < 0x80) {
        bytes.add(rune);
      } else if (rune >= 0x0410 && rune <= 0x042F) {
        bytes.add(rune - 0x0410 + 0x80);
      } else if (rune >= 0x0430 && rune <= 0x043F) {
        bytes.add(rune - 0x0430 + 0xA0);
      } else if (rune >= 0x0440 && rune <= 0x044F) {
        bytes.add(rune - 0x0440 + 0xE0);
      } else if (rune == 0x0401) {
        bytes.add(0xF0);
      } else if (rune == 0x0451) {
        bytes.add(0xF1);
      } else {
        bytes.add(0x3F);
      }
    }
    return bytes;
  }
}
