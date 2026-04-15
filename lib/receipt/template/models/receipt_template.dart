import 'package:canvas_barcode_generator/receipt/printer/layouts/i_esc_pos_receipt_layout.dart';
import 'package:flutter/material.dart';

import 'receipt_block.dart';

/// it's necssary I guess
enum PaperWidthMM {
  mm58._(58),
  mm80._(80);

  const PaperWidthMM._(this.value);

  static PaperWidthMM fromInt(final int? mm) {
    switch (mm) {
      case 58:
        return PaperWidthMM.mm58;
      case 80:
        return PaperWidthMM.mm80;
      default:
        return PaperWidthMM.mm80;
    }
  }

  final num value;
}

/// this class will not be necessary in Avera POS Cloud
/// cause templates will be injected as layout right inside [IEscPosReceiptLayout]
class ReceiptTemplate {
  final String id;
  final String name;
  final PaperWidthMM paperWidthMm; // 58 or 80
  final List<ReceiptBlock> blocks;

  const ReceiptTemplate({
    required this.id,
    required this.name,
    required this.paperWidthMm,
    required this.blocks,
  });

  /// Number of characters per line for this paper width.
  int get cols => paperWidthMm == PaperWidthMM.mm80 ? 48 : 32;

  ReceiptTemplate copyWith({
    String? name,
    PaperWidthMM? paperWidthMm,
    List<ReceiptBlock>? blocks,
  }) => ReceiptTemplate(
    id: id,
    name: name ?? this.name,
    paperWidthMm: paperWidthMm ?? this.paperWidthMm,
    blocks: blocks ?? this.blocks,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'paperWidthMm': paperWidthMm.value,
    'blocks': blocks.map((b) => b.toJson()).toList(),
  };

  factory ReceiptTemplate.fromJson(Map<String, dynamic> j) => ReceiptTemplate(
    id: j['id'] as String,
    name: j['name'] as String,
    paperWidthMm: PaperWidthMM.fromInt(j['paperWidthMm'] as int?),
    blocks: (j['blocks'] as List)
        .map((b) => ReceiptBlock.fromJson(b as Map<String, dynamic>))
        .toList(),
  );

  static ReceiptTemplate get defaultTemplate => ReceiptTemplate(
    id: 'default',
    name: 'Стандартный',
    paperWidthMm: PaperWidthMM.mm80,
    blocks: [
      DividerBlock(char: '='),
      HeaderBlock(align: TextAlign.center),
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
