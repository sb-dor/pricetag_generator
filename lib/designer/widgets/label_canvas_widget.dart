import 'package:flutter/material.dart';
import '../../core/di/app_scope.dart';
import 'draggable_element_widget.dart';

/// Visual canvas that renders the label at a scaled-down size for editing.
/// Wrapped in RepaintBoundary for capture → PNG → printer.
class LabelCanvasWidget extends StatelessWidget {
  /// GlobalKey used by DesignerScreen to capture the canvas as an image.
  final GlobalKey repaintKey;

  const LabelCanvasWidget({super.key, required this.repaintKey});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final labelSize = scope.canvasNotifier.labelSize;

        // Scale the label to fit the available width, keeping aspect ratio
        final scale = constraints.maxWidth / labelSize.widthMm;
        final canvasW = constraints.maxWidth;
        final canvasH = labelSize.heightMm * scale;

        return Center(
          child: RepaintBoundary(
            key: repaintKey,
            child: GestureDetector(
              onTap: () => scope.canvasNotifier.selectElement(null),
              child: Container(
                width: canvasW,
                height: canvasH,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade400),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListenableBuilder(
                  listenable: scope.canvasNotifier,
                  builder: (context, _) {
                    final elements = scope.canvasNotifier.elements;
                    return Stack(
                      clipBehavior: Clip.hardEdge,
                      children: elements
                          .map((e) => DraggableElementWidget(
                                key: ValueKey(e.id),
                                element: e,
                                scale: scale,
                              ))
                          .toList(),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
