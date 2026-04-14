import 'package:barcode_widget/barcode_widget.dart' hide BarcodeElement;
import 'package:flutter/material.dart';
import '../../core/di/app_scope.dart';
import '../models/canvas_element.dart';

/// Half-size of each corner resize handle in screen pixels.
const _kHandleRadius = 6.0;

/// Minimum element dimension in logical canvas units (mm).
const _kMinSize = 5.0;

class DraggableElementWidget extends StatelessWidget {
  final CanvasElement element;
  final double scale; // canvas logical px (mm) → screen px

  const DraggableElementWidget({
    super.key,
    required this.element,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final notifier = AppScope.read(context).canvasNotifier;
    final isSelected = notifier.selectedId == element.id;

    return Positioned(
      left: element.x * scale,
      top: element.y * scale,
      width: element.width * scale,
      height: element.height * scale,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Main content + drag + double-tap to edit ───────────────────
          Positioned.fill(
            child: GestureDetector(
              onTap: () => notifier.selectElement(element.id),
              onDoubleTap: () => _showEditDialog(context, notifier),
              onPanUpdate: (d) {
                notifier.updatePosition(
                  element.id,
                  element.x + d.delta.dx / scale,
                  element.y + d.delta.dy / scale,
                );
              },
              child: _buildContent(),
            ),
          ),

          // ── Selection border ────────────────────────────────────────────
          if (isSelected)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue, width: 1.5),
                  ),
                ),
              ),
            ),

          // ── Resize handles (4 corners) ──────────────────────────────────
          if (isSelected) ...[
            _ResizeHandle(
              corner: _Corner.topLeft,
              element: element,
              scale: scale,
              notifier: notifier,
            ),
            _ResizeHandle(
              corner: _Corner.topRight,
              element: element,
              scale: scale,
              notifier: notifier,
            ),
            _ResizeHandle(
              corner: _Corner.bottomLeft,
              element: element,
              scale: scale,
              notifier: notifier,
            ),
            _ResizeHandle(
              corner: _Corner.bottomRight,
              element: element,
              scale: scale,
              notifier: notifier,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent() {
    return switch (element) {
      BarcodeElement e => _BarcodeView(element: e),
      TextElement e => _TextView(element: e, scale: scale),
    };
  }

  void _showEditDialog(BuildContext context, dynamic notifier) {
    switch (element) {
      case TextElement e:
        _EditTextDialog.show(context, e, notifier);
      case BarcodeElement e:
        _EditBarcodeDialog.show(context, e, notifier);
    }
  }
}

// ── Resize handle ─────────────────────────────────────────────────────────────

enum _Corner { topLeft, topRight, bottomLeft, bottomRight }

class _ResizeHandle extends StatelessWidget {
  final _Corner corner;
  final CanvasElement element;
  final double scale;
  final dynamic notifier;

  const _ResizeHandle({
    required this.corner,
    required this.element,
    required this.scale,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    // Position handle so its center is at the element corner
    const s = _kHandleRadius * 2;
    const offset = -_kHandleRadius;

    double? left, top, right, bottom;
    switch (corner) {
      case _Corner.topLeft:
        left = offset; top = offset;
      case _Corner.topRight:
        right = offset; top = offset;
      case _Corner.bottomLeft:
        left = offset; bottom = offset;
      case _Corner.bottomRight:
        right = offset; bottom = offset;
    }

    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      width: s,
      height: s,
      child: GestureDetector(
        onPanUpdate: (d) => _onResize(d.delta),
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.blue, width: 1.5),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  void _onResize(Offset delta) {
    final dx = delta.dx / scale;
    final dy = delta.dy / scale;

    double newX = element.x;
    double newY = element.y;
    double newW = element.width;
    double newH = element.height;

    switch (corner) {
      case _Corner.topLeft:
        // Moving top-left corner: shift origin, shrink size
        newX = element.x + dx;
        newY = element.y + dy;
        newW = element.width - dx;
        newH = element.height - dy;
      case _Corner.topRight:
        // Moving top-right: only top moves, right expands
        newY = element.y + dy;
        newW = element.width + dx;
        newH = element.height - dy;
      case _Corner.bottomLeft:
        // Moving bottom-left: left moves, bottom expands
        newX = element.x + dx;
        newW = element.width - dx;
        newH = element.height + dy;
      case _Corner.bottomRight:
        // Moving bottom-right: only size changes
        newW = element.width + dx;
        newH = element.height + dy;
    }

    // Clamp to minimum size
    if (newW < _kMinSize) {
      if (corner == _Corner.topLeft || corner == _Corner.bottomLeft) {
        newX = element.x + element.width - _kMinSize;
      }
      newW = _kMinSize;
    }
    if (newH < _kMinSize) {
      if (corner == _Corner.topLeft || corner == _Corner.topRight) {
        newY = element.y + element.height - _kMinSize;
      }
      newH = _kMinSize;
    }

    final resized = element
        .copyWithPosition(newX, newY)
        .copyWithSize(newW, newH);
    notifier.updateElement(resized);
  }
}

// ── Edit text dialog ─────────────────────────────────────────────────────────

class _EditTextDialog {
  static void show(BuildContext context, TextElement element, dynamic notifier) {
    final ctrl = TextEditingController(text: element.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Редактировать текст'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Введите текст...',
          ),
          onSubmitted: (_) => _apply(ctx, element, ctrl.text, notifier),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => _apply(ctx, element, ctrl.text, notifier),
            child: const Text('Применить'),
          ),
        ],
      ),
    );
  }

  static void _apply(
      BuildContext ctx, TextElement element, String text, dynamic notifier) {
    if (text.trim().isEmpty) return;
    notifier.updateElement(element.copyWith(text: text.trim()));
    Navigator.pop(ctx);
  }
}

// ── Edit barcode dialog ───────────────────────────────────────────────────────

class _EditBarcodeDialog {
  static void show(
      BuildContext context, BarcodeElement element, dynamic notifier) {
    final ctrl = TextEditingController(text: element.value);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Редактировать штрихкод'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.text,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Значение штрихкода',
            hintText: '5901234123457',
          ),
          onSubmitted: (_) => _apply(ctx, element, ctrl.text, notifier),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => _apply(ctx, element, ctrl.text, notifier),
            child: const Text('Применить'),
          ),
        ],
      ),
    );
  }

  static void _apply(BuildContext ctx, BarcodeElement element, String value,
      dynamic notifier) {
    if (value.trim().isEmpty) return;
    notifier.updateElement(element.copyWith(value: value.trim()));
    Navigator.pop(ctx);
  }
}

// ── Barcode view ─────────────────────────────────────────────────────────────

class _BarcodeView extends StatelessWidget {
  final BarcodeElement element;
  const _BarcodeView({required this.element});

  @override
  Widget build(BuildContext context) {
    return BarcodeWidget(
      barcode: element.barcodeType,
      data: element.value.isEmpty ? '000000000000' : element.value,
      drawText: element.showText,
      color: Colors.black,
      backgroundColor: Colors.white,
    );
  }
}

// ── Text view ─────────────────────────────────────────────────────────────────

class _TextView extends StatelessWidget {
  final TextElement element;
  final double scale;
  const _TextView({required this.element, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        element.text,
        style: TextStyle(
          // fontSize хранится в мм → умножаем на scale чтобы получить экранные пиксели
          fontSize: (element.fontSize * scale).clamp(6.0, 200.0),
          fontWeight: element.isBold ? FontWeight.bold : FontWeight.normal,
          color: element.color,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }
}