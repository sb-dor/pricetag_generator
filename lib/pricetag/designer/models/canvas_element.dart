import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';

/// Base sealed class for all draggable elements on the label canvas.
/// Positions (x, y) and sizes (width, height) are in logical canvas units (mm).
sealed class CanvasElement {
  final String id;
  final double x;
  final double y;
  final double width;
  final double height;

  const CanvasElement({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  CanvasElement copyWithPosition(double x, double y);
  CanvasElement copyWithSize(double width, double height);

  Rect get rect => Rect.fromLTWH(x, y, width, height);

  Map<String, dynamic> toJson();

  static CanvasElement fromJson(Map<String, dynamic> json) {
    return switch (json['type'] as String) {
      'barcode' => BarcodeElement.fromJson(json),
      'text' => TextElement.fromJson(json),
      _ => throw FormatException('Unknown element type: ${json['type']}'),
    };
  }
}

// ── Barcode ──────────────────────────────────────────────────────────────────

class BarcodeElement extends CanvasElement {
  final Barcode barcodeType;
  final String value;
  final bool showText;

  const BarcodeElement({
    required super.id,
    required super.x,
    required super.y,
    required super.width,
    required super.height,
    required this.barcodeType,
    required this.value,
    this.showText = true,
  });

  @override
  BarcodeElement copyWithPosition(double x, double y) => copyWith(x: x, y: y);

  @override
  BarcodeElement copyWithSize(double width, double height) =>
      copyWith(width: width, height: height);

  BarcodeElement copyWith({
    Barcode? barcodeType,
    String? value,
    bool? showText,
    double? x,
    double? y,
    double? width,
    double? height,
  }) {
    return BarcodeElement(
      id: id,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      barcodeType: barcodeType ?? this.barcodeType,
      value: value ?? this.value,
      showText: showText ?? this.showText,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'barcode',
        'id': id,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'barcodeType': barcodeTypeToKey(barcodeType),
        'value': value,
        'showText': showText,
      };

  factory BarcodeElement.fromJson(Map<String, dynamic> json) => BarcodeElement(
        id: json['id'] as String,
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        width: (json['width'] as num).toDouble(),
        height: (json['height'] as num).toDouble(),
        barcodeType: barcodeTypeFromKey(json['barcodeType'] as String),
        value: json['value'] as String,
        showText: json['showText'] as bool? ?? true,
      );
}

// ── Text ─────────────────────────────────────────────────────────────────────

enum TextRole { productName, price, discount, custom }

class TextElement extends CanvasElement {
  final String text;
  final double fontSize;
  final bool isBold;
  final Color color;
  final TextRole role;

  const TextElement({
    required super.id,
    required super.x,
    required super.y,
    required super.width,
    required super.height,
    required this.text,
    required this.role,
    this.fontSize = 14,
    this.isBold = false,
    this.color = Colors.black,
  });

  @override
  TextElement copyWithPosition(double x, double y) => copyWith(x: x, y: y);

  @override
  TextElement copyWithSize(double width, double height) =>
      copyWith(width: width, height: height);

  TextElement copyWith({
    String? text,
    double? fontSize,
    bool? isBold,
    Color? color,
    TextRole? role,
    double? x,
    double? y,
    double? width,
    double? height,
  }) {
    return TextElement(
      id: id,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      text: text ?? this.text,
      fontSize: fontSize ?? this.fontSize,
      isBold: isBold ?? this.isBold,
      color: color ?? this.color,
      role: role ?? this.role,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'text',
        'id': id,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'text': text,
        'fontSize': fontSize,
        'isBold': isBold,
        'color': color.toARGB32(),
        'role': role.name,
      };

  factory TextElement.fromJson(Map<String, dynamic> json) => TextElement(
        id: json['id'] as String,
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        width: (json['width'] as num).toDouble(),
        height: (json['height'] as num).toDouble(),
        text: json['text'] as String,
        fontSize: (json['fontSize'] as num).toDouble(),
        isBold: json['isBold'] as bool? ?? false,
        color: Color(json['color'] as int),
        role: TextRole.values.byName(json['role'] as String),
      );
}

// ── Barcode type serialization helpers ───────────────────────────────────────

const _barcodeKeys = <String, Barcode Function()>{
  'ean13':   Barcode.ean13,
  'ean8':    Barcode.ean8,
  'qrCode':  Barcode.qrCode,
  'code128': Barcode.code128,
  'code39':  Barcode.code39,
  'upca':    Barcode.upcA,
  'upce':    Barcode.upcE,
  'pdf417':  Barcode.pdf417,
  'dataMatrix': Barcode.dataMatrix,
  'aztec':   Barcode.aztec,
};

String barcodeTypeToKey(Barcode barcode) {
  for (final entry in _barcodeKeys.entries) {
    if (entry.value().name == barcode.name) return entry.key;
  }
  return 'ean13'; // fallback
}

Barcode barcodeTypeFromKey(String key) =>
    (_barcodeKeys[key] ?? Barcode.ean13)();