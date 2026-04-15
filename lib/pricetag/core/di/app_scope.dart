import 'package:flutter/widgets.dart';
import '../../designer/notifiers/canvas_notifier.dart';
import 'printer_settings.dart';

class AppScope extends InheritedWidget {
  final CanvasNotifier canvasNotifier;
  final PrinterSettings printerSettings;

  const AppScope({
    super.key,
    required this.canvasNotifier,
    required this.printerSettings,
    required super.child,
  });

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope found in context');
    return scope!;
  }

  /// Use this when you don't need to rebuild on changes (e.g. calling methods).
  static AppScope read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope found in context');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      canvasNotifier != oldWidget.canvasNotifier || printerSettings != oldWidget.printerSettings;
}
