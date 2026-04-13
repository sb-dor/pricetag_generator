import 'package:barcode_widget/barcode_widget.dart' hide BarcodeElement;
import 'package:flutter/material.dart';
import '../../core/di/app_scope.dart';
import '../models/canvas_element.dart';

class ElementToolbar extends StatelessWidget {
  const ElementToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _ToolButton(
              icon: Icons.qr_code,
              label: 'Штрихкод',
              onTap: () => _addBarcode(context),
            ),
            _ToolButton(
              icon: Icons.label_outline,
              label: 'Название',
              onTap: () => _addText(context, TextRole.productName, 'Название товара'),
            ),
            _ToolButton(
              icon: Icons.attach_money,
              label: 'Цена',
              onTap: () => _addText(context, TextRole.price, '0.00 ₽'),
            ),
            _ToolButton(
              icon: Icons.discount_outlined,
              label: 'Скидка',
              onTap: () => _addText(context, TextRole.discount, '-0%'),
            ),
            _ToolButton(
              icon: Icons.text_fields,
              label: 'Текст',
              onTap: () => _addText(context, TextRole.custom, 'Текст'),
            ),
            const VerticalDivider(width: 16),
            _ToolButton(
              icon: Icons.delete_outline,
              label: 'Удалить',
              color: Colors.red.shade400,
              onTap: () => _deleteSelected(context),
            ),
          ],
        ),
      ),
    );
  }

  void _addBarcode(BuildContext context) {
    final notifier = AppScope.read(context).canvasNotifier;
    final w = notifier.labelSize.widthMm;
    final h = notifier.labelSize.heightMm;
    notifier.addElement(BarcodeElement(
      id: _uid(),
      x: w * 0.1,
      y: h * 0.1,
      width: w * 0.5,        // 50% ширины — разумный дефолт
      height: h * 0.4,       // 40% высоты
      barcodeType: Barcode.ean13(),
      value: '5901234123457',
    ));
  }

  void _addText(BuildContext context, TextRole role, String defaultText) {
    final notifier = AppScope.read(context).canvasNotifier;
    final w = notifier.labelSize.widthMm;
    final h = notifier.labelSize.heightMm;

    // Размеры в мм, не в экранных пикселях — масштабируются под ценник
    final (elemW, elemH) = switch (role) {
      TextRole.price       => (w * 0.45, h * 0.22),
      TextRole.productName => (w * 0.85, h * 0.20),
      TextRole.discount    => (w * 0.30, h * 0.20),
      TextRole.custom      => (w * 0.50, h * 0.18),
    };

    // fontSize в мм (будет масштабироваться через scale)
    final fontSize = switch (role) {
      TextRole.price       => h * 0.14,
      TextRole.productName => h * 0.10,
      _                    => h * 0.09,
    };

    notifier.addElement(TextElement(
      id: _uid(),
      x: w * 0.05,
      y: h * 0.05,
      width: elemW,
      height: elemH,
      text: defaultText,
      role: role,
      fontSize: fontSize,
      isBold: role == TextRole.price || role == TextRole.productName,
    ));
  }

  void _deleteSelected(BuildContext context) {
    final notifier = AppScope.read(context).canvasNotifier;
    final id = notifier.selectedId;
    if (id != null) notifier.removeElement(id);
  }

  String _uid() => DateTime.now().microsecondsSinceEpoch.toString();
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: c),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 11, color: c)),
            ],
          ),
        ),
      ),
    );
  }
}
