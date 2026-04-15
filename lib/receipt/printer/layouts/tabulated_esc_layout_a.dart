import '../../receipt/models/receipt.dart';
import '../../receipt/models/receipt_item.dart';
import '../../template/models/receipt_template.dart';
import 'i_esc_pos_receipt_layout.dart';

/// Tabulated layout — style A (matches receipt image 3).
///
/// ```
///           Авази Нукриддин
/// 15.04.26 15:10
/// №  Наименование       Кол-во    Цена    Сумм
/// ..............................................
/// 1  Evy baby 4
///                       1 уп. x    135 =   135 сум.
/// ..............................................
/// 2  Дафтар
///                           1 x     22 =    22 сум.
/// ..............................................
/// ВСЕГО:                                     157
/// Скидка 0.7%:                                -1
/// ..............................................
/// ИТОГО К ОПЛАТЕ:                            156
/// НАЛИЧНЫМИ:                                 156
/// СДАЧА                                        0
/// ```
///
/// Differences from [TabulatedEscLayoutB]:
/// - Store name is NOT bold / double-height
/// - Date has no prefix
/// - Separator is dots (`...`)
/// - Item row 2 includes unit suffix and `сум.`
/// - Totals discount label is `Скидка X%:`
/// - `СДАЧА` has no colon
class TabulatedEscLayoutA implements IEscPosReceiptLayout {
  const TabulatedEscLayoutA();

  // ── ESC/POS raw command constants ─────────────────────────────────────────

  static const _reset = [0x1B, 0x40];
  static const _cp866 = [0x1B, 0x74, 0x11];
  static const _boldOn = [0x1B, 0x45, 0x01];
  static const _boldOff = [0x1B, 0x45, 0x00];
  static const _left = [0x1B, 0x61, 0x00];
  static const _center = [0x1B, 0x61, 0x01];
  static const _lf = [0x0A];
  static const _cut = [0x1D, 0x56, 0x42, 0x00];

  static List<int> _feedLines(int n) => [0x1B, 0x64, n];

  // ── Column geometry ────────────────────────────────────────────────────────

  static int _nameW(int cols) => cols >= 40 ? 20 : 12;
  static int _qtyW(int cols) => cols >= 40 ? 8 : 6;
  static int _priceW(int cols) => cols >= 40 ? 8 : 6;
  static int _totalW(int cols) =>
      cols - _nameW(cols) - _qtyW(cols) - _priceW(cols);

  // ── IEscPosReceiptLayout ───────────────────────────────────────────────────

  @override
  List<int> build(Receipt receipt, ReceiptTemplate template) {
    final buf = <int>[];
    final cols = template.cols;
    final dots = '.' * cols;

    buf
      ..addAll(_reset)
      ..addAll(_cp866);

    // Store name — centered, plain weight (no bold, no double-height)
    buf
      ..addAll(_center)
      ..addAll(_encode(receipt.storeName))
      ..addAll(_lf);

    // Date — left, dd.MM.yy HH:mm
    buf
      ..addAll(_left)
      ..addAll(_encode(_fmtDate(DateTime.now())))
      ..addAll(_lf);

    // Column header
    buf
      ..addAll(_left)
      ..addAll(_encode(_colHeader(cols, 'Сумм')))
      ..addAll(_lf);

    // Dots separator
    buf
      ..addAll(_left)
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

  void _writeItem(
      List<int> buf, int idx, ReceiptItem item, int cols, String dots) {
    // Row 1: index + name
    buf
      ..addAll(_left)
      ..addAll(_encode('$idx  ${item.label}'))
      ..addAll(_lf);

    // Row 2: qty unit. x | price = | total сум.  (column-aligned)
    final unit = item.unit.isNotEmpty ? ' ${item.unit}.' : '';
    final qtyPart = '${_fmtAmt(item.qty)}$unit x';
    final pricePart = '${_fmtAmt(item.price)} =';
    final totalPart = '${_fmtAmt(item.lineSubtotal)} сум.';
    buf
      ..addAll(_left)
      ..addAll(_encode(_row2(qtyPart, pricePart, totalPart, cols)))
      ..addAll(_lf);

    // Dots separator
    buf
      ..addAll(_left)
      ..addAll(_encode(dots))
      ..addAll(_lf);
  }

  // ── Totals renderer ────────────────────────────────────────────────────────

  void _writeTotals(
      List<int> buf, Receipt receipt, int cols, String dots) {
    // ВСЕГО (bold)
    buf
      ..addAll(_left)
      ..addAll(_boldOn)
      ..addAll(_encode(_padRow('ВСЕГО:', _fmtAmt(receipt.subtotal), cols)))
      ..addAll(_boldOff)
      ..addAll(_lf);

    // Скидка X% (only when there is a discount)
    if (receipt.hasDiscount) {
      final pct = _fmtAmt(
          receipt.subtotal > 0 ? receipt.totalDiscount / receipt.subtotal * 100 : 0);
      buf
        ..addAll(_left)
        ..addAll(_encode(
            _padRow('Скидка $pct%:', '-${_fmtAmt(receipt.totalDiscount)}', cols)))
        ..addAll(_lf);
    }

    // Dots separator
    buf
      ..addAll(_left)
      ..addAll(_encode(dots))
      ..addAll(_lf);

    // ИТОГО К ОПЛАТЕ (bold)
    buf
      ..addAll(_left)
      ..addAll(_boldOn)
      ..addAll(_encode(_padRow('ИТОГО К ОПЛАТЕ:', _fmtAmt(receipt.total), cols)))
      ..addAll(_boldOff)
      ..addAll(_lf);

    // НАЛИЧНЫМИ
    buf
      ..addAll(_left)
      ..addAll(_encode(_padRow('НАЛИЧНЫМИ:', _fmtAmt(receipt.total), cols)))
      ..addAll(_lf);

    // СДАЧА (no colon, as in the receipt image)
    buf
      ..addAll(_left)
      ..addAll(_encode(_padRow('СДАЧА', '0', cols)))
      ..addAll(_lf);
  }

  // ── Layout helpers ─────────────────────────────────────────────────────────

  /// Column header: №  Наименование … Кол-во   Цена   [totalLabel]
  String _colHeader(int cols, String totalLabel) {
    final nw = _nameW(cols);
    final qw = _qtyW(cols);
    final pw = _priceW(cols);
    final tw = _totalW(cols);
    return _padEnd('№  Наименование', nw) +
        _padLeft('Кол-во', qw) +
        _padLeft('Цена', pw) +
        _padLeft(totalLabel, tw);
  }

  /// Item row 2: [nameW spaces] [qtyPart right in qtyW] [pricePart right in priceW] [totalPart right in totalW]
  String _row2(String qty, String price, String total, int cols) {
    final nw = _nameW(cols);
    final qw = _qtyW(cols);
    final pw = _priceW(cols);
    final tw = _totalW(cols);
    return ' ' * nw +
        _padLeft(qty, qw) +
        _padLeft(price, pw) +
        _padLeft(total, tw);
  }

  /// Left + right with spacing to fill [cols] characters.
  String _padRow(String left, String right, int cols) {
    final gap = cols - left.length - right.length;
    if (gap <= 0) return '$left $right';
    return '$left${' ' * gap}$right';
  }

  /// Left-align [s] in a field of [width] chars (truncates if too long).
  String _padEnd(String s, int width) =>
      s.length >= width ? s.substring(0, width) : s + ' ' * (width - s.length);

  /// Right-align [s] in a field of [width] chars (truncates if too long).
  String _padLeft(String s, int width) =>
      s.length >= width ? s : ' ' * (width - s.length) + s;

  // ── Number formatters ──────────────────────────────────────────────────────

  /// Formats a number without trailing zeros: 22.0 → "22", 20.9 → "20.9"
  String _fmtAmt(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    final s = v.toStringAsFixed(2);
    return s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }

  /// Date format: dd.MM.yy HH:mm (2-digit year)
  String _fmtDate(DateTime dt) {
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
        bytes.add(rune - 0x0410 + 0x80); // А–Я
      } else if (rune >= 0x0430 && rune <= 0x043F) {
        bytes.add(rune - 0x0430 + 0xA0); // а–п
      } else if (rune >= 0x0440 && rune <= 0x044F) {
        bytes.add(rune - 0x0440 + 0xE0); // р–я
      } else if (rune == 0x0401) {
        bytes.add(0xF0); // Ё
      } else if (rune == 0x0451) {
        bytes.add(0xF1); // ё
      } else if (rune == 0x2116) {
        bytes.add(0xFC); // №
      } else {
        bytes.add(0x3F); // '?'
      }
    }
    return bytes;
  }
}
