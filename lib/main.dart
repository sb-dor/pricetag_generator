import 'package:flutter/material.dart';

import 'pricetag/core/di/app_scope.dart';
import 'pricetag/core/di/printer_settings.dart';
import 'pricetag/designer/notifiers/canvas_notifier.dart';
import 'pricetag/screens/designer_screen.dart';
import 'receipt/catalog/notifiers/catalog_notifier.dart';
import 'receipt/core/di/receipt_scope.dart';
import 'receipt/core/di/receipt_settings.dart';
import 'receipt/receipt/notifiers/receipt_notifier.dart';
import 'receipt/screens/receipt_main_screen.dart';
import 'receipt/template/notifiers/template_notifier.dart';

void main() {
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  // Pricetag
  final _canvasNotifier = CanvasNotifier();
  final _printerSettings = PrinterSettings();

  // Receipt
  final _receiptNotifier = ReceiptNotifier();
  final _catalogNotifier = CatalogNotifier();
  final _templateNotifier = TemplateNotifier();
  final _receiptSettings = ReceiptSettings();

  @override
  void dispose() {
    _canvasNotifier.dispose();
    _printerSettings.dispose();
    _receiptNotifier.dispose();
    _catalogNotifier.dispose();
    _templateNotifier.dispose();
    _receiptSettings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      canvasNotifier: _canvasNotifier,
      printerSettings: _printerSettings,
      child: ReceiptScope(
        receiptNotifier: _receiptNotifier,
        catalogNotifier: _catalogNotifier,
        templateNotifier: _templateNotifier,
        settings: _receiptSettings,
        child: MaterialApp(
          title: 'Печать',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo), useMaterial3: true),
          home: const HomeScreen(),
        ),
      ),
    );
  }
}

// ── Home screen ───────────────────────────────────────────────────────────────

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Печать')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _FeatureCard(
            icon: Icons.label_outline,
            title: 'Ценники',
            subtitle: 'Дизайнер ценников с печатью\nна Xprinter и Zebra',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DesignerScreen())),
          ),
          const SizedBox(height: 16),
          _FeatureCard(
            icon: Icons.receipt_long_outlined,
            title: 'Чеки',
            subtitle: 'Печать чеков с каталогом товаров\nна Xprinter и Zebra',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReceiptMainScreen())),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FeatureCard({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
