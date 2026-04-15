import 'package:flutter/material.dart';

sealed class ReceiptBlock {
  bool visible;

  ReceiptBlock({this.visible = true});

  String get displayName;

  Map<String, dynamic> toJson();

  static ReceiptBlock fromJson(Map<String, dynamic> j) {
    return switch (j['type'] as String) {
      'header' => HeaderBlock.fromJson(j),
      'datetime' => DateTimeBlock.fromJson(j),
      'divider' => DividerBlock.fromJson(j),
      'items' => ItemsTableBlock.fromJson(j),
      'totals' => TotalsBlock.fromJson(j),
      'footer' => FooterBlock.fromJson(j),
      'customText' => CustomTextBlock.fromJson(j),
      _ => throw FormatException('Unknown block type: ${j['type']}'),
    };
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class HeaderBlock extends ReceiptBlock {
  String storeName;
  String? subtitle;
  TextAlign align;

  HeaderBlock({
    super.visible,
    this.storeName = 'Название магазина',
    this.subtitle,
    this.align = TextAlign.center,
  });

  @override
  String get displayName => 'Шапка (название магазина)';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'header',
    'visible': visible,
    'storeName': storeName,
    'subtitle': subtitle,
    'align': align.index,
  };

  factory HeaderBlock.fromJson(Map<String, dynamic> j) => HeaderBlock(
    visible: j['visible'] as bool? ?? true,
    storeName: j['storeName'] as String? ?? 'Название магазина',
    subtitle: j['subtitle'] as String?,
    align: TextAlign.values[j['align'] as int? ?? TextAlign.center.index],
  );
}

// ── DateTime ──────────────────────────────────────────────────────────────────

class DateTimeBlock extends ReceiptBlock {
  String format;

  DateTimeBlock({super.visible, this.format = 'dd.MM.yyyy  HH:mm'});

  @override
  String get displayName => 'Дата и время';

  @override
  Map<String, dynamic> toJson() => {'type': 'datetime', 'visible': visible, 'format': format};

  factory DateTimeBlock.fromJson(Map<String, dynamic> j) => DateTimeBlock(
    visible: j['visible'] as bool? ?? true,
    format: j['format'] as String? ?? 'dd.MM.yyyy  HH:mm',
  );
}

// ── Divider ───────────────────────────────────────────────────────────────────

class DividerBlock extends ReceiptBlock {
  String char;

  DividerBlock({super.visible, this.char = '-'});

  @override
  String get displayName => 'Разделитель ($char)';

  @override
  Map<String, dynamic> toJson() => {'type': 'divider', 'visible': visible, 'char': char};

  factory DividerBlock.fromJson(Map<String, dynamic> j) =>
      DividerBlock(visible: j['visible'] as bool? ?? true, char: j['char'] as String? ?? '-');
}

// ── Items table ───────────────────────────────────────────────────────────────

class ItemsTableBlock extends ReceiptBlock {
  bool showDiscount;
  bool showUnit;

  ItemsTableBlock({super.visible, this.showDiscount = true, this.showUnit = true});

  @override
  String get displayName => 'Таблица товаров';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'items',
    'visible': visible,
    'showDiscount': showDiscount,
    'showUnit': showUnit,
  };

  factory ItemsTableBlock.fromJson(Map<String, dynamic> j) => ItemsTableBlock(
    visible: j['visible'] as bool? ?? true,
    showDiscount: j['showDiscount'] as bool? ?? true,
    showUnit: j['showUnit'] as bool? ?? true,
  );
}

// ── Totals ────────────────────────────────────────────────────────────────────

class TotalsBlock extends ReceiptBlock {
  bool showSubtotal;
  bool showDiscountLine;

  TotalsBlock({super.visible, this.showSubtotal = true, this.showDiscountLine = true});

  @override
  String get displayName => 'Итоги (сумма, скидка)';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'totals',
    'visible': visible,
    'showSubtotal': showSubtotal,
    'showDiscountLine': showDiscountLine,
  };

  factory TotalsBlock.fromJson(Map<String, dynamic> j) => TotalsBlock(
    visible: j['visible'] as bool? ?? true,
    showSubtotal: j['showSubtotal'] as bool? ?? true,
    showDiscountLine: j['showDiscountLine'] as bool? ?? true,
  );
}

// ── Footer ────────────────────────────────────────────────────────────────────

class FooterBlock extends ReceiptBlock {
  String text;
  TextAlign align;

  FooterBlock({super.visible, this.text = 'Спасибо за покупку!', this.align = TextAlign.center});

  @override
  String get displayName => 'Подвал (текст снизу)';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'footer',
    'visible': visible,
    'text': text,
    'align': align.index,
  };

  factory FooterBlock.fromJson(Map<String, dynamic> j) => FooterBlock(
    visible: j['visible'] as bool? ?? true,
    text: j['text'] as String? ?? 'Спасибо за покупку!',
    align: TextAlign.values[j['align'] as int? ?? TextAlign.center.index],
  );
}

// ── Custom text ───────────────────────────────────────────────────────────────

class CustomTextBlock extends ReceiptBlock {
  String text;
  bool isBold;
  TextAlign align;

  CustomTextBlock({
    super.visible,
    this.text = 'Дополнительный текст',
    this.isBold = false,
    this.align = TextAlign.left,
  });

  @override
  String get displayName => 'Произвольный текст';

  @override
  Map<String, dynamic> toJson() => {
    'type': 'customText',
    'visible': visible,
    'text': text,
    'isBold': isBold,
    'align': align.index,
  };

  factory CustomTextBlock.fromJson(Map<String, dynamic> j) => CustomTextBlock(
    visible: j['visible'] as bool? ?? true,
    text: j['text'] as String? ?? '',
    isBold: j['isBold'] as bool? ?? false,
    align: TextAlign.values[j['align'] as int? ?? TextAlign.left.index],
  );
}
