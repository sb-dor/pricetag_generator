import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/di/app_scope.dart';
import '../core/di/printer_settings.dart';
import '../designer/models/label_size.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  late final TextEditingController _hostCtrl;
  late final TextEditingController _portCtrl;

  @override
  void initState() {
    super.initState();
    final settings = AppScope.read(context).printerSettings;
    _hostCtrl = TextEditingController(text: settings.host);
    _portCtrl = TextEditingController(text: settings.port.toString());
  }

  @override
  void dispose() {
    _hostCtrl.dispose();
    _portCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final settings = scope.printerSettings;
    final canvasNotifier = scope.canvasNotifier;

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки принтера')),
      body: ListenableBuilder(
        listenable: Listenable.merge([settings, canvasNotifier]),
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Printer type ──────────────────────────────────────────────
              const Text('Тип принтера', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SegmentedButton<PrinterType>(
                segments: const [
                  ButtonSegment(value: PrinterType.xprinter, label: Text('Xprinter')),
                  ButtonSegment(value: PrinterType.zebra, label: Text('Zebra')),
                ],
                selected: {settings.printerType},
                onSelectionChanged: (s) => settings.setPrinterType(s.first),
              ),
              const SizedBox(height: 24),

              // ── Connection ───────────────────────────────────────────────
              const Text('Соединение (WiFi/TCP)', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  final port = int.tryParse(v);
                  if (port != null) settings.setPort(port);
                },
              ),
              const SizedBox(height: 24),

              // ── Label size ───────────────────────────────────────────────
              const Text('Размер ценника', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              RadioGroup<LabelSize>(
                groupValue: canvasNotifier.labelSize,
                onChanged: (v) {
                  if (v != null) canvasNotifier.setLabelSize(v);
                },
                child: Column(
                  children: LabelSize.presets
                      .map(
                        (size) => RadioListTile<LabelSize>(
                          title: Text(size.name),
                          subtitle: Text(
                            '${size.widthMm.toInt()}×${size.heightMm.toInt()} мм  •  ${size.dpi} DPI',
                          ),
                          value: size,
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Свой размер'),
                onPressed: () => _showCustomSizeDialog(context, canvasNotifier),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCustomSizeDialog(BuildContext context, dynamic canvasNotifier) {
    final wCtrl = TextEditingController();
    final hCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Свой размер'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: wCtrl,
              decoration: const InputDecoration(
                labelText: 'Ширина (мм)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: hCtrl,
              decoration: const InputDecoration(
                labelText: 'Высота (мм)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
            onPressed: () {
              final w = double.tryParse(wCtrl.text);
              final h = double.tryParse(hCtrl.text);
              if (w != null && h != null && w > 0 && h > 0) {
                canvasNotifier.setLabelSize(
                  LabelSize(
                    name: '${w.toInt()}×${h.toInt()} мм',
                    widthMm: w,
                    heightMm: h,
                    dpi: 203,
                  ),
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Применить'),
          ),
        ],
      ),
    );
  }
}
