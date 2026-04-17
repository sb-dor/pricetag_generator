import '../../receipt/models/receipt.dart';
import '../../receipt/models/receipt_item.dart';
import '../../template/models/receipt_template.dart';
import 'i_esc_pos_receipt_layout.dart';

/// Tabulated layout — style B (matches receipt image 4).
///
/// ```
///           Авази Нукриддин          ← bold + double-height
/// Дата: 15.04.26 15:13 -
/// №  Наименование       Кол-во    Цена   Сумма
/// ----------------------------------------------
/// 1  Трависил
///                           1 x     22 =    22
///                  Скидка -5%( -1.1 )      20.9
/// ----------------------------------------------
/// ВСЕГО:                                     22
/// Сумма скидки -5%                          1.1
/// ----------------------------------------------
/// ИТОГО К ОПЛАТЕ:                          20.9
/// НАЛИЧНЫМИ:                               20.9
/// СДАЧА:                                      0
/// ```
///
/// Differences from [TabulatedEscLayoutA]:
/// - Store name is bold + double-height
/// - Date line has `Дата: ` prefix and ` -` suffix
/// - Separator is dashes (`---`)
/// - Item row 2 has no unit / `сум.`
/// - Per-item discount shown as `Скидка -X%( -amt )  lineTotal`
/// - Totals discount label is `Сумма скидки -X%`
/// - `СДАЧА:` has a colon
class TabulatedEscLayoutB implements IEscPosReceiptLayout {
  const TabulatedEscLayoutB();

  // ── ESC/POS raw command constants ─────────────────────────────────────────

  static const _reset = [0x1B, 0x40];
  static const _cp866 = [0x1B, 0x74, 0x11];
  static const _boldOn = [0x1B, 0x45, 0x01];
  static const _boldOff = [0x1B, 0x45, 0x00];
  static const _left = [0x1B, 0x61, 0x00];
  static const _center = [0x1B, 0x61, 0x01];
  static const _lf = [0x0A];

  /// Half line feed — ESC J 16: advance paper ~16 dots (~half a normal line).
  static const _halfLf = [0x1B, 0x4A, 0x10];

  // GS ! n — character size: upper nibble = width multiplier−1, lower = height multiplier−1
  // 0x11 → 2× width + 2× height (80mm)
  // 0x01 → 1× width + 2× height (58mm — normal width keeps ESC a centering accurate)
  // 0x00 → normal
  static const _size2xWide = [0x1D, 0x21, 0x11]; // 80mm
  static const _size2xTall = [0x1D, 0x21, 0x01]; // 58mm
  static const _sizeNormal = [0x1D, 0x21, 0x00];

  static const _cut = [0x1D, 0x56, 0x42, 0x00];

  // ── Column geometry ────────────────────────────────────────────────────────

  static int _nameW(int cols) => cols >= 40 ? 20 : 12;
  static int _qtyW(int cols) => cols >= 40 ? 8 : 6;
  static int _priceW(int cols) => cols >= 40 ? 8 : 6;
  static int _totalW(int cols) => cols - _nameW(cols) - _qtyW(cols) - _priceW(cols);

  // ── IEscPosReceiptLayout ───────────────────────────────────────────────────

  @override
  List<int> build(Receipt receipt, ReceiptTemplate template) {
    final buf = <int>[];
    final cols = template.cols;
    final dashes = '-' * cols;

    buf
      ..addAll(_reset)
      ..addAll(_cp866)
      ..addAll(_halfLf); // tiny top margin

    // Store name — bold, sized.
    // 80mm: printer center alignment + 2×2 size works correctly.
    // 58mm: ESC a center is unreliable with GS! on narrow paper, so use left
    //       alignment and prepend spaces manually.
    final storeName = receipt.storeName;
    if (cols >= 40) {
      buf
        ..addAll(_center)
        ..addAll(_size2xWide)
        ..addAll(_boldOn)
        ..addAll(_encode(storeName))
        ..addAll(_boldOff)
        ..addAll(_sizeNormal);
    } else {
      final pad = ((cols - storeName.length) / 2).floor().clamp(0, cols);
      buf
        ..addAll(_left)
        ..addAll(_size2xTall)
        ..addAll(_boldOn)
        ..addAll(_encode(' ' * pad + storeName))
        ..addAll(_boldOff)
        ..addAll(_sizeNormal);
    }
    buf
      ..addAll(_lf)
      ..addAll(_halfLf); // half-height gap between store name and date

    // Date — left, "Дата: dd.MM.yy HH:mm -"
    buf
      ..addAll(_left)
      ..addAll(_encode('Дата: ${_fmtDate(DateTime.now())}'))
      ..addAll(_lf);

    // Column header
    buf
      ..addAll(_left)
      ..addAll(_encode(_colHeader(cols, 'Сумма')))
      ..addAll(_lf);

    // Dash separator
    buf
      ..addAll(_left)
      ..addAll(_encode(dashes))
      ..addAll(_lf);

    // Items
    for (var i = 0; i < receipt.items.length; i++) {
      _writeItem(buf, i + 1, receipt.items[i], cols, dashes);
    }

    // Totals
    _writeTotals(buf, receipt, cols, dashes);

    // Customer section — only printed when customerName is provided
    if (receipt.customerName != null) {
      _writeCustomer(buf, receipt, cols, dashes);
    }

    buf
      ..addAll(_halfLf) // tiny bottom margin before cut
      ..addAll(_cut);

    return buf;
  }

  // ── Item renderer ──────────────────────────────────────────────────────────

  void _writeItem(List<int> buf, int idx, ReceiptItem item, int cols, String dashes) {
    // Row 1: index + name (bold)
    buf
      ..addAll(_left)
      ..addAll(_boldOn)
      ..addAll(_encode('$idx  ${item.label}'))
      ..addAll(_boldOff)
      ..addAll(_lf);

    // Row 2: qty x | price = | lineSubtotal  (column-aligned, no unit / сум.)
    final qtyPart = '${_fmtAmt(item.qty)} x';
    final pricePart = '${_fmtAmt(item.price)} =';
    final totalPart = _fmtAmt(item.lineSubtotal);
    buf
      ..addAll(_left)
      ..addAll(_encode(_row2(qtyPart, pricePart, totalPart, cols)))
      ..addAll(_lf);

    // Discount row: "Скидка -X%( -amt )  lineTotal"  (column-aligned)
    if (item.hasDiscount) {
      final pct = _fmtAmt(item.discountPct!);
      final disc = _fmtAmt(item.lineDiscount);
      final label = 'Скидка -$pct%(-$disc)';
      final lineTotal = _fmtAmt(item.lineTotal);
      buf
        ..addAll(_left)
        ..addAll(_encode(_qtyRow(label, lineTotal, cols)))
        ..addAll(_lf);
    }

    // Dash separator
    buf
      ..addAll(_left)
      ..addAll(_encode(dashes))
      ..addAll(_lf);
  }

  // ── Totals renderer ────────────────────────────────────────────────────────

  void _writeTotals(List<int> buf, Receipt receipt, int cols, String dashes) {
    // ВСЕГО + Сумма скидки — only shown when there is a discount
    if (receipt.hasDiscount) {
      buf
        ..addAll(_left)
        ..addAll(_boldOn)
        ..addAll(_encode(_qtyRow('ВСЕГО:', _fmtAmt(receipt.subtotal), cols)))
        ..addAll(_boldOff)
        ..addAll(_lf);

      final pct = _fmtAmt(
        receipt.subtotal > 0 ? receipt.totalDiscount / receipt.subtotal * 100 : 0,
      );
      buf
        ..addAll(_left)
        ..addAll(_encode(_qtyRow('Сумма скидки -$pct%', _fmtAmt(receipt.totalDiscount), cols)))
        ..addAll(_lf);
    }

    // Dash separator — only needed when the discount block above was printed;
    // without discount the last item already ends with its own dash line.
    if (receipt.hasDiscount) {
      buf
        ..addAll(_left)
        ..addAll(_encode(dashes))
        ..addAll(_lf);
    }

    // ИТОГО К ОПЛАТЕ (bold) — indented to qty column
    buf
      ..addAll(_left)
      ..addAll(_boldOn)
      ..addAll(_encode(_qtyRow('ИТОГО К ОПЛАТЕ:', _fmtAmt(receipt.total), cols)))
      ..addAll(_boldOff)
      ..addAll(_lf);

    // НАЛИЧНЫМИ — indented to qty column
    buf
      ..addAll(_left)
      ..addAll(_encode(_qtyRow('НАЛИЧНЫМИ:', _fmtAmt(receipt.total), cols)))
      ..addAll(_lf);

    // СДАЧА: — indented to qty column
    buf
      ..addAll(_left)
      ..addAll(_encode(_qtyRow('СДАЧА:', '0', cols)))
      ..addAll(_lf);
  }

  // ── Customer section ──────────────────────────────────────────────────────

  void _writeCustomer(List<int> buf, Receipt receipt, int cols, String dashes) {
    // Separator before customer block
    buf
      ..addAll(_left)
      ..addAll(_encode(dashes))
      ..addAll(_lf);

    // Phone | - Name  (customerCode shown only when provided)
    final nameLine = receipt.customerCode != null
        ? '${receipt.customerCode} | - ${receipt.customerName}'
        : receipt.customerName!;
    buf
      ..addAll(_left)
      ..addAll(_boldOn)
      ..addAll(_encode(nameLine))
      ..addAll(_boldOff)
      ..addAll(_lf);

    // Debt lines — only when previousDebt was supplied
    if (receipt.previousDebt != null) {
      final prevDebt = receipt.previousDebt!;
      final currentDebt = prevDebt + receipt.total;
      buf
        ..addAll(_left)
        ..addAll(_encode(_qtyRow('Предыдущий долг:', _fmtAmt(prevDebt), cols)))
        ..addAll(_lf)
        ..addAll(_left)
        ..addAll(_encode(_qtyRow('Текущий долг:', _fmtAmt(currentDebt), cols)))
        ..addAll(_lf);
    }
  }

  // ── Layout helpers ─────────────────────────────────────────────────────────

  /// Column header: №  Наименование … Кол-во   Цена   [totalLabel]
  String _colHeader(int cols, String totalLabel) {
    final nw = _nameW(cols);
    final qw = _qtyW(cols);
    final pw = _priceW(cols);
    final tw = _totalW(cols);
    final nameLabel = cols >= 40 ? 'Наименование' : 'Наим';
    return _padEnd('№  $nameLabel', nw) +
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
    return ' ' * nw + _padLeft(qty, qw) + _padLeft(price, pw) + _padLeft(total, tw);
  }

  /// Row indented to the qty column: label left, value right-aligned to line end.
  /// Used for both discount rows and totals rows.
  String _qtyRow(String label, String value, int cols) {
    final nw = _nameW(cols);
    final remaining = cols - nw;
    final gap = remaining - label.length - value.length;
    if (gap <= 0) return ' ' * nw + '$label $value';
    return ' ' * nw + label + ' ' * gap + value;
  }

  /// Left-align [s] in a field of [width] chars (truncates if too long).
  String _padEnd(String s, int width) =>
      s.length >= width ? s.substring(0, width) : s + ' ' * (width - s.length);

  /// Right-align [s] in a field of [width] chars (truncates if too long).
  String _padLeft(String s, int width) => s.length >= width ? s : ' ' * (width - s.length) + s;

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
