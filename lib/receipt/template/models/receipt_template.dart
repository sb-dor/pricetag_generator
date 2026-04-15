import 'package:flutter/material.dart';
import 'receipt_block.dart';

class ReceiptTemplate {
  final String id;
  final String name;
  final int paperWidthMm; // 58 or 80
  final List<ReceiptBlock> blocks;

  const ReceiptTemplate({
    required this.id,
    required this.name,
    required this.paperWidthMm,
    required this.blocks,
  });

  /// Number of characters per line for this paper width.
  int get cols => paperWidthMm == 80 ? 48 : 32;

  ReceiptTemplate copyWith({String? name, int? paperWidthMm, List<ReceiptBlock>? blocks}) =>
      ReceiptTemplate(
        id: id,
        name: name ?? this.name,
        paperWidthMm: paperWidthMm ?? this.paperWidthMm,
        blocks: blocks ?? this.blocks,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'paperWidthMm': paperWidthMm,
    'blocks': blocks.map((b) => b.toJson()).toList(),
  };

  factory ReceiptTemplate.fromJson(Map<String, dynamic> j) => ReceiptTemplate(
    id: j['id'] as String,
    name: j['name'] as String,
    paperWidthMm: j['paperWidthMm'] as int? ?? 80,
    blocks: (j['blocks'] as List)
        .map((b) => ReceiptBlock.fromJson(b as Map<String, dynamic>))
        .toList(),
  );

  static ReceiptTemplate get defaultTemplate => ReceiptTemplate(
    id: 'default',
    name: 'Стандартный',
    paperWidthMm: 80,
    blocks: [
      DividerBlock(char: '='),
      HeaderBlock(storeName: 'Название магазина', align: TextAlign.center),
      DividerBlock(char: '='),
      DateTimeBlock(format: 'dd.MM.yyyy  HH:mm'),
      DividerBlock(char: '-'),
      ItemsTableBlock(showDiscount: true, showUnit: true),
      DividerBlock(char: '-'),
      TotalsBlock(showSubtotal: true, showDiscountLine: true),
      DividerBlock(char: '='),
      FooterBlock(text: 'Спасибо за покупку!', align: TextAlign.center),
      DividerBlock(char: '='),
    ],
  );
}
