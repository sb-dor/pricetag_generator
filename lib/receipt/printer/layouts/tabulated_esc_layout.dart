import '../../receipt/models/receipt.dart';
import '../../receipt/models/receipt_item.dart';
import '../../template/models/receipt_template.dart';
import 'i_esc_pos_receipt_layout.dart';

/// Tabulated ESC/POS layout matching the printed receipt style:
///
/// ```
///        Авази Нукриддин
/// 15.04.26 15:00
/// ...............................................
/// №  Наименование          Кол-во   Цена    Сумм
/// ...............................................
/// 1  Кофе
///                          2 x 150.00 = 300.00
/// ...............................................
/// 2  Круассан
///                          1 x 80.00 = 80.00
/// ...............................................
/// ВСЕГО:                                  380.00
/// Скидка %:                               -30.00
/// ...............................................
/// ИТОГО К ОПЛАТЕ:                         350.00
/// НАЛИЧНЫМИ:                              350.00
/// СДАЧА:                                    0.00
/// ```
class TabulatedEscLayout implements IEscPosReceiptLayout {
  const TabulatedEscLayout();

  // ── ESC/POS raw command constants ─────────────────────────────────────────

  static const _reset = [0x1B, 0x40];
  static const _cp866 = [0x1B, 0x74, 0x11];
  static const _boldOn = [0x1B, 0x45, 0x01];
  static const _boldOff = [0x1B, 0x45, 0x00];
  static const _dblHOn = [0x1B, 0x21, 0x10];
  static const _dblHOff = [0x1B, 0x21, 0x00];
  static const _left = [0x1B, 0x61, 0x00];
  static const _center = [0x1B, 0x61, 0x01];
  static const _lf = [0x0A];
  static const _cut = [0x1D, 0x56, 0x42, 0x00];

  static List<int> _feedLines(int n) => [0x1B, 0x64, n];

  // ── Column header text ────────────────────────────────────────────────────

  static const _colHeader = '№  Наименование          Кол-во   Цена    Сумм';

  // ── EscPosReceiptLayout ────────────────────────────────────────────────────

  @override
  List<int> build(Receipt receipt, ReceiptTemplate template) {
    final buf = <int>[];
    final cols = template.cols;
    final dots = '.' * cols;

    buf
      ..addAll(_reset)
      ..addAll(_cp866);

    // Store name — centered, bold, double-height
    buf
      ..addAll(_center)
      ..addAll(_boldOn)
      ..addAll(_dblHOn)
      ..addAll(_encode(receipt.storeName))
      ..addAll(_dblHOff)
      ..addAll(_boldOff)
      ..addAll(_lf);

    // Date line — left aligned, 2-digit year
    buf
      ..addAll(_left)
      ..addAll(_encode(_formatDate(DateTime.now())))
      ..addAll(_lf);

    // Dots + column headers + dots
    buf
      ..addAll(_left)
      ..addAll(_encode(dots))
      ..addAll(_lf)
      ..addAll(_encode(_colHeader))
      ..addAll(_lf)
      ..addAll(_encode(dots))
      ..addAll(_lf);

    // Items
    for (var i = 0; i < receipt.items.length; i++) {
      _writeItem(buf, i + 1, receipt.items[i], cols, dots);
    }

    // Totals
    _writeTotals(buf, receipt, cols, dots);

    buf
      ..addAll(_feedLines(4))
      ..addAll(_cut);

    return buf;
  }

  // ── Item renderer ──────────────────────────────────────────────────────────

  void _writeItem(List<int> buf, int index, ReceiptItem item, int cols, String dots) {
    // Row 1: index + name
    buf
      ..addAll(_left)
      ..addAll(_encode('$index  ${item.label}'))
      ..addAll(_lf);

    // Row 2: qty x price = total (right-aligned)
    final qty = _fmtNum(item.qty);
    final price = _fmtMoney(item.price);
    final total = _fmtMoney(item.lineTotal);
    final row2 = '$qty x $price = $total';
    buf
      ..addAll(_left)
      ..addAll(_encode(_padRight(row2, cols)))
      ..addAll(_lf);

    // Discount row (if applicable)
    if (item.hasDiscount) {
      final pct = item.discountPct!.toStringAsFixed(0);
      final disc = 'Скидка $pct%: -${_fmtMoney(item.lineDiscount)}';
      buf
        ..addAll(_left)
        ..addAll(_encode(_padRight(disc, cols)))
        ..addAll(_lf);
    }

    // Separator dots after each item
    buf
      ..addAll(_left)
      ..addAll(_encode(dots))
      ..addAll(_lf);
  }

  // ── Totals renderer ────────────────────────────────────────────────────────

  void _writeTotals(List<int> buf, Receipt receipt, int cols, String dots) {
    // ВСЕГО
    buf
      ..addAll(_left)
      ..addAll(_encode(_padRow('ВСЕГО:', _fmtMoney(receipt.subtotal), cols)))
      ..addAll(_lf);

    // Скидка % (only when there is a discount)
    if (receipt.hasDiscount) {
      buf
        ..addAll(_left)
        ..addAll(_encode(_padRow('Скидка %:', '-${_fmtMoney(receipt.totalDiscount)}', cols)))
        ..addAll(_lf);
    }

    // Separator dots
    buf
      ..addAll(_left)
      ..addAll(_encode(dots))
      ..addAll(_lf);

    // ИТОГО К ОПЛАТЕ (bold)
    buf
      ..addAll(_left)
      ..addAll(_boldOn)
      ..addAll(_encode(_padRow('ИТОГО К ОПЛАТЕ:', _fmtMoney(receipt.total), cols)))
      ..addAll(_boldOff)
      ..addAll(_lf);

    // НАЛИЧНЫМИ (= total paid, same as total)
    buf
      ..addAll(_left)
      ..addAll(_encode(_padRow('НАЛИЧНЫМИ:', _fmtMoney(receipt.total), cols)))
      ..addAll(_lf);

    // СДАЧА (= 0.00)
    buf
      ..addAll(_left)
      ..addAll(_encode(_padRow('СДАЧА:', _fmtMoney(0), cols)))
      ..addAll(_lf);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Pads [right] to the far-right column so the combined line is [cols] chars wide.
  String _padRow(String left, String right, int cols) {
    final gap = cols - left.length - right.length;
    if (gap <= 0) return '$left $right';
    return '$left${' ' * gap}$right';
  }

  /// Returns [text] right-aligned within [cols] characters.
  String _padRight(String text, int cols) {
    if (text.length >= cols) return text;
    return '${' ' * (cols - text.length)}$text';
  }

  String _fmtMoney(double v) => v.toStringAsFixed(2);

  String _fmtNum(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toString();

  /// Formats date as `dd.MM.yy HH:mm` (2-digit year, as shown in the receipt image).
  String _formatDate(DateTime dt) {
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final yy = (dt.year % 100).toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$dd.$mm.$yy $hh:$min';
  }

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
