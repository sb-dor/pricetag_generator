import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../core/di/app_scope.dart';
import '../core/di/printer_settings.dart';
import '../designer/models/canvas_element.dart';
import '../designer/widgets/element_toolbar.dart';
import '../designer/widgets/label_canvas_widget.dart';
import '../printer/xprinter_service.dart';
import '../printer/zebra_service.dart';
import '../services/export_service.dart';
import '../services/template_service.dart';
import '../transport/tcp_transport.dart';
import 'printer_settings_screen.dart';

class DesignerScreen extends StatefulWidget {
  const DesignerScreen({super.key});

  @override
  State<DesignerScreen> createState() => _DesignerScreenState();
}

class _DesignerScreenState extends State<DesignerScreen> {
  final GlobalKey _repaintKey = GlobalKey();
  final _templateService = TemplateService();
  final _exportService = ExportService();
  bool _isBusy = false;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: ListenableBuilder(
          listenable: scope.canvasNotifier,
          builder: (_, _) => Text(scope.canvasNotifier.labelSize.name),
        ),
        actions: [
          // ── Templates ──────────────────────────────────────────────────
          IconButton(
            icon: const Icon(Icons.bookmark_outline),
            tooltip: 'Шаблоны',
            onPressed: () => _showTemplatesSheet(context),
          ),
          // ── Export ─────────────────────────────────────────────────────
          IconButton(
            icon: const Icon(Icons.ios_share_outlined),
            tooltip: 'Экспорт',
            onPressed: _isBusy ? null : () => _showExportSheet(context),
          ),
          // ── Clear ──────────────────────────────────────────────────────
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Очистить',
            onPressed: () => _confirmClear(context),
          ),
          // ── Settings ───────────────────────────────────────────────────
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Настройки принтера',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrinterSettingsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Canvas ───────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: LabelCanvasWidget(repaintKey: _repaintKey),
            ),
          ),

          // ── Selected element properties ───────────────────────────────────
          ListenableBuilder(
            listenable: scope.canvasNotifier,
            builder: (_, _) {
              final selected = scope.canvasNotifier.selectedElement;
              if (selected == null) return const SizedBox.shrink();
              return _ElementPropertiesBar(element: selected);
            },
          ),

          // ── Add-elements toolbar ──────────────────────────────────────────
          const ElementToolbar(),

          // ── Bottom action bar (Print) ─────────────────────────────────────
          _BottomActionBar(isBusy: _isBusy, onPrint: () => _print(context)),
        ],
      ),
    );
  }

  // ── Capture ──────────────────────────────────────────────────────────────

  Future<Uint8List> _captureCanvas() async {
    final boundary = _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final dpi = AppScope.read(context).canvasNotifier.labelSize.dpi.toDouble();
    final image = await boundary.toImage(pixelRatio: dpi / 96.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  // ── Print ────────────────────────────────────────────────────────────────

  Future<void> _print(BuildContext context) async {
    final scope = AppScope.read(context);
    final settings = scope.printerSettings;
    final size = scope.canvasNotifier.labelSize;
    final printerType = settings.printerType;
    final transport = TcpTransport(host: settings.host, port: settings.port);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isBusy = true);
    try {
      final pngBytes = await _captureCanvas();
      if (printerType == PrinterType.xprinter) {
        await XprinterService().printLabel(pngBytes: pngBytes, size: size, transport: transport);
      } else {
        await ZebraService().printLabel(pngBytes: pngBytes, size: size, transport: transport);
      }
      messenger.showSnackBar(const SnackBar(content: Text('Отправлено на принтер')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  // ── Export sheet ─────────────────────────────────────────────────────────

  void _showExportSheet(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('Сохранить как PDF'),
              onTap: () async {
                Navigator.pop(context);
                setState(() => _isBusy = true);
                try {
                  final size = AppScope.read(context).canvasNotifier.labelSize;
                  final png = await _captureCanvas();
                  await _exportService.saveAsPdf(png, size);
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
                  );
                } finally {
                  if (mounted) setState(() => _isBusy = false);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('Сохранить как PNG'),
              onTap: () async {
                Navigator.pop(context);
                setState(() => _isBusy = true);
                try {
                  final size = AppScope.read(context).canvasNotifier.labelSize;
                  final png = await _captureCanvas();
                  await _exportService.saveAsImage(png, size);
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
                  );
                } finally {
                  if (mounted) setState(() => _isBusy = false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Templates sheet ──────────────────────────────────────────────────────

  void _showTemplatesSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TemplatesSheet(
        templateService: _templateService,
        onSave: (name) async {
          final notifier = AppScope.read(context).canvasNotifier;
          await _templateService.save(notifier, name);
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Шаблон "$name" сохранён')));
          }
        },
        onLoad: (template) {
          _templateService.apply(template, AppScope.read(context).canvasNotifier);
          Navigator.pop(context);
        },
        onDelete: (name) async {
          await _templateService.delete(name);
        },
      ),
    );
  }

  // ── Clear ────────────────────────────────────────────────────────────────

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Очистить канвас?'),
        content: const Text('Все элементы будут удалены.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
            onPressed: () {
              AppScope.read(context).canvasNotifier.clear();
              Navigator.pop(ctx);
            },
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
  }
}

// ── Bottom action bar ─────────────────────────────────────────────────────────

class _BottomActionBar extends StatelessWidget {
  final bool isBusy;
  final VoidCallback onPrint;

  const _BottomActionBar({required this.isBusy, required this.onPrint});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      child: SafeArea(
        top: false,
        child: FilledButton.icon(
          onPressed: isBusy ? null : onPrint,
          icon: isBusy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.print_outlined),
          label: Text(isBusy ? 'Обработка...' : 'Печать'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
        ),
      ),
    );
  }
}

// ── Element properties bar ────────────────────────────────────────────────────

class _ElementPropertiesBar extends StatelessWidget {
  final CanvasElement element;
  const _ElementPropertiesBar({required this.element});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: Colors.blue.shade50,
      child: Row(
        children: [
          const Icon(Icons.open_with, size: 16, color: Colors.blue),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _label(),
              style: const TextStyle(fontSize: 12, color: Colors.blue),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Удалить элемент',
            onPressed: () => AppScope.read(context).canvasNotifier.removeElement(element.id),
          ),
        ],
      ),
    );
  }

  String _label() => switch (element) {
    BarcodeElement e => 'Штрихкод: ${e.value}  •  тяни за углы чтобы изменить размер',
    TextElement e => 'Текст: ${e.text}  •  тяни за углы чтобы изменить размер',
  };
}

// ── Templates bottom sheet ────────────────────────────────────────────────────

class _TemplatesSheet extends StatefulWidget {
  final TemplateService templateService;
  final Future<void> Function(String name) onSave;
  final void Function(TemplateModel template) onLoad;
  final Future<void> Function(String name) onDelete;

  const _TemplatesSheet({
    required this.templateService,
    required this.onSave,
    required this.onLoad,
    required this.onDelete,
  });

  @override
  State<_TemplatesSheet> createState() => _TemplatesSheetState();
}

class _TemplatesSheetState extends State<_TemplatesSheet> {
  late Future<List<TemplateModel>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = widget.templateService.loadAll();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          // ── Header ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                const Text('Шаблоны', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                FilledButton.icon(
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Сохранить текущий'),
                  onPressed: () => _promptSave(context),
                ),
              ],
            ),
          ),
          const Divider(height: 16),
          // ── List ──────────────────────────────────────────────────────
          Expanded(
            child: FutureBuilder<List<TemplateModel>>(
              future: _future,
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final templates = snap.data ?? [];
                if (templates.isEmpty) {
                  return const Center(
                    child: Text('Нет сохранённых шаблонов', style: TextStyle(color: Colors.grey)),
                  );
                }
                return ListView.builder(
                  controller: scrollController,
                  itemCount: templates.length,
                  itemBuilder: (_, i) {
                    final t = templates[i];
                    return ListTile(
                      leading: const Icon(Icons.bookmark),
                      title: Text(t.name),
                      subtitle: Text(
                        '${t.labelSize.name}  •  ${t.elements.length} эл.  •  '
                        '${t.savedAt.day}.${t.savedAt.month}.${t.savedAt.year}',
                      ),
                      onTap: () => widget.onLoad(t),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () async {
                          await widget.onDelete(t.name);
                          setState(_reload);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _promptSave(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Сохранить шаблон'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Название шаблона',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              await widget.onSave(name);
              setState(_reload);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }
}
