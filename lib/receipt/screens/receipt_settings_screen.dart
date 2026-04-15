import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/di/receipt_scope.dart';
import '../core/di/receipt_settings.dart';

class ReceiptSettingsScreen extends StatefulWidget {
  const ReceiptSettingsScreen({super.key});

  @override
  State<ReceiptSettingsScreen> createState() => _ReceiptSettingsScreenState();
}

class _ReceiptSettingsScreenState extends State<ReceiptSettingsScreen> {
  late final TextEditingController _storeCtrl;
  late final TextEditingController _hostCtrl;
  late final TextEditingController _portCtrl;

  @override
  void initState() {
    super.initState();
    final s = ReceiptScope.read(context).settings;
    _storeCtrl = TextEditingController(text: s.storeName);
    _hostCtrl = TextEditingController(text: s.host);
    _portCtrl = TextEditingController(text: s.port.toString());
  }

  @override
  void dispose() {
    _storeCtrl.dispose();
    _hostCtrl.dispose();
    _portCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ReceiptScope.of(context).settings;

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки чека')),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Store ─────────────────────────────────────────────────────
            const Text('Магазин', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _storeCtrl,
              decoration: const InputDecoration(
                labelText: 'Название магазина',
                border: OutlineInputBorder(),
              ),
              onChanged: settings.setStoreName,
            ),
            const SizedBox(height: 24),

            // ── Printer type ──────────────────────────────────────────────
            const Text('Тип принтера', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<ReceiptPrinterType>(
              segments: const [
                ButtonSegment(value: ReceiptPrinterType.xprinter, label: Text('Xprinter')),
                ButtonSegment(value: ReceiptPrinterType.zebra, label: Text('Zebra')),
              ],
              selected: {settings.printerType},
              onSelectionChanged: (s) => settings.setPrinterType(s.first),
            ),
            const SizedBox(height: 24),

            // ── Connection ────────────────────────────────────────────────
            const Text('Подключение (WiFi/TCP)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _hostCtrl,
              decoration: const InputDecoration(
                labelText: 'IP адрес',
                hintText: '192.168.1.100',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              onChanged: settings.setHost,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _portCtrl,
              decoration: const InputDecoration(
                labelText: 'Порт',
                hintText: '9100',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) {
                final p = int.tryParse(v);
                if (p != null) settings.setPort(p);
              },
            ),
            const SizedBox(height: 24),

            // ── Paper width ───────────────────────────────────────────────
            const Text('Ширина бумаги', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 58, label: Text('58 мм')),
                ButtonSegment(value: 80, label: Text('80 мм')),
              ],
              selected: {settings.paperWidthMm},
              onSelectionChanged: (s) => settings.setPaperWidth(s.first),
            ),
          ],
        ),
      ),
    );
  }
}
