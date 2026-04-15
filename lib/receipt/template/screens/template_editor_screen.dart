import 'package:flutter/material.dart';
import '../../core/di/receipt_scope.dart';
import '../models/receipt_block.dart';
import '../models/receipt_template.dart';
import '../notifiers/template_notifier.dart';

class TemplateEditorScreen extends StatefulWidget {
  final ReceiptTemplate template;
  const TemplateEditorScreen({super.key, required this.template});

  @override
  State<TemplateEditorScreen> createState() => _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends State<TemplateEditorScreen> {
  @override
  void initState() {
    super.initState();
    ReceiptScope.read(context).templateNotifier.startEditing(widget.template);
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ReceiptScope.of(context).templateNotifier;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактор шаблона'),
        actions: [
          IconButton(
            icon: const Icon(Icons.preview_outlined),
            tooltip: 'Предпросмотр',
            onPressed: () => _showPreview(context, notifier),
          ),
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Сохранить',
            onPressed: () async {
              await notifier.saveEditing();
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: notifier,
        builder: (context, _) {
          final tmpl = notifier.editing;
          return Column(
            children: [
              // ── Paper width ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    const Text('Ширина бумаги:', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(width: 12),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 58, label: Text('58 мм')),
                        ButtonSegment(value: 80, label: Text('80 мм')),
                      ],
                      selected: {tmpl.paperWidthMm},
                      onSelectionChanged: (s) => notifier.setEditingPaperWidth(s.first),
                    ),
                  ],
                ),
              ),
              const Divider(height: 20),
              // ── Blocks reorderable list ──────────────────────────────────
              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: tmpl.blocks.length,
                  onReorder: notifier.reorderBlocks,
                  itemBuilder: (_, i) {
                    final block = tmpl.blocks[i];
                    return _BlockTile(key: ValueKey(i), block: block, index: i, notifier: notifier);
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBlockSheet(context, notifier),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddBlockSheet(BuildContext context, TemplateNotifier notifier) {
    void pick(ReceiptBlock block) {
      Navigator.pop(context);
      notifier.addBlock(block);
    }

    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.horizontal_rule),
              title: const Text('Разделитель'),
              onTap: () => pick(DividerBlock()),
            ),
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: const Text('Произвольный текст'),
              onTap: () => pick(CustomTextBlock()),
            ),
            ListTile(
              leading: const Icon(Icons.access_time_outlined),
              title: const Text('Дата и время'),
              onTap: () => pick(DateTimeBlock()),
            ),
            ListTile(
              leading: const Icon(Icons.store_outlined),
              title: const Text('Шапка магазина'),
              onTap: () => pick(HeaderBlock()),
            ),
          ],
        ),
      ),
    );
  }

  void _showPreview(BuildContext context, TemplateNotifier notifier) {
    final tmpl = notifier.editing;
    final cols = tmpl.cols;
    final lines = <String>[];

    for (final block in tmpl.blocks.where((b) => b.visible)) {
      switch (block) {
        case HeaderBlock b:
          lines.add(_center(b.storeName, cols));
          if (b.subtitle != null) lines.add(_center(b.subtitle!, cols));
        case DateTimeBlock _:
          lines.add('01.01.2025  14:30');
        case DividerBlock b:
          lines.add(b.char * cols);
        case ItemsTableBlock _:
          lines.add('Кофе                  2 шт x 150.00₽');
          lines.add('  Скидка 10%:               -30.00₽');
          lines.add('Круассан              1 шт x  80.00₽');
        case TotalsBlock _:
          lines.add('Итого без скидки:          380.00₽');
          lines.add('Скидка:                    -30.00₽');
          lines.add('ИТОГО:                     350.00₽');
        case FooterBlock b:
          lines.add(_center(b.text, cols));
        case CustomTextBlock b:
          lines.add(b.text);
      }
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Предпросмотр'),
        content: SingleChildScrollView(
          child: Text(
            lines.join('\n'),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Закрыть')),
        ],
      ),
    );
  }

  String _center(String text, int cols) {
    if (text.length >= cols) return text;
    final pad = (cols - text.length) ~/ 2;
    return ' ' * pad + text;
  }
}

// ── Block tile ────────────────────────────────────────────────────────────────

class _BlockTile extends StatelessWidget {
  final ReceiptBlock block;
  final int index;
  final TemplateNotifier notifier;

  const _BlockTile({super.key, required this.block, required this.index, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ReorderableDragStartListener(index: index, child: const Icon(Icons.drag_handle)),
      title: Text(block.displayName),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(value: block.visible, onChanged: (_) => notifier.toggleBlockVisible(index)),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            onPressed: () => _showConfigSheet(context),
          ),
        ],
      ),
    );
  }

  void _showConfigSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _BlockConfigPanel(block: block, index: index, notifier: notifier),
      ),
    );
  }
}

// ── Block config panel ────────────────────────────────────────────────────────

class _BlockConfigPanel extends StatefulWidget {
  final ReceiptBlock block;
  final int index;
  final TemplateNotifier notifier;

  const _BlockConfigPanel({required this.block, required this.index, required this.notifier});

  @override
  State<_BlockConfigPanel> createState() => _BlockConfigPanelState();
}

class _BlockConfigPanelState extends State<_BlockConfigPanel> {
  late ReceiptBlock _block;

  @override
  void initState() {
    super.initState();
    _block = widget.block;
  }

  void _save() {
    widget.notifier.updateBlock(widget.index, _block);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _block.displayName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._fields(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
                const SizedBox(width: 8),
                FilledButton(onPressed: _save, child: const Text('Применить')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _fields() {
    return switch (_block) {
      HeaderBlock b => [
        _textField(
          'Название магазина',
          b.storeName,
          (v) => setState(() => _block = b..storeName = v),
        ),
        const SizedBox(height: 8),
        _textField(
          'Подзаголовок (необязательно)',
          b.subtitle ?? '',
          (v) => setState(() => _block = b..subtitle = v.isEmpty ? null : v),
        ),
      ],
      DividerBlock b => [
        _textField(
          'Символ разделителя',
          b.char,
          (v) => setState(() => _block = b..char = v.isEmpty ? '-' : v[0]),
        ),
      ],
      FooterBlock b => [
        _textField('Текст подвала', b.text, (v) => setState(() => _block = b..text = v)),
      ],
      CustomTextBlock b => [
        _textField('Текст', b.text, (v) => setState(() => _block = b..text = v)),
        SwitchListTile(
          title: const Text('Жирный'),
          value: b.isBold,
          onChanged: (v) => setState(() => _block = b..isBold = v),
        ),
      ],
      ItemsTableBlock b => [
        SwitchListTile(
          title: const Text('Показывать скидку'),
          value: b.showDiscount,
          onChanged: (v) => setState(() => _block = b..showDiscount = v),
        ),
        SwitchListTile(
          title: const Text('Показывать единицу товара'),
          value: b.showUnit,
          onChanged: (v) => setState(() => _block = b..showUnit = v),
        ),
      ],
      TotalsBlock b => [
        SwitchListTile(
          title: const Text('Итого без скидки'),
          value: b.showSubtotal,
          onChanged: (v) => setState(() => _block = b..showSubtotal = v),
        ),
        SwitchListTile(
          title: const Text('Строка скидки'),
          value: b.showDiscountLine,
          onChanged: (v) => setState(() => _block = b..showDiscountLine = v),
        ),
      ],
      _ => [const Text('Нет настроек для этого блока.')],
    };
  }

  Widget _textField(String label, String value, ValueChanged<String> onChanged) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      onChanged: onChanged,
    );
  }
}
