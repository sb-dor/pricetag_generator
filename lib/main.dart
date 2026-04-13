import 'package:flutter/material.dart';

import 'core/di/app_scope.dart';
import 'core/di/printer_settings.dart';
import 'designer/notifiers/canvas_notifier.dart';
import 'screens/designer_screen.dart';

void main() {
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final _canvasNotifier = CanvasNotifier();
  final _printerSettings = PrinterSettings();

  @override
  void dispose() {
    _canvasNotifier.dispose();
    _printerSettings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      canvasNotifier: _canvasNotifier,
      printerSettings: _printerSettings,
      child: MaterialApp(
        title: 'Ценник',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo), useMaterial3: true),
        home: const DesignerScreen(),
      ),
    );
  }
}
