import 'package:flutter/material.dart';
import '../../pricetag/transport/tcp_transport.dart';
import '../catalog/screens/catalog_screen.dart';
import '../core/di/receipt_scope.dart';
import '../core/di/receipt_settings.dart';
import '../printer/esc_pos_receipt_service.dart';
import '../printer/zpl_receipt_service.dart';
import '../receipt/models/receipt_item.dart';
import '../receipt/notifiers/receipt_notifier.dart';
import '../template/models/receipt_template.dart';
import '../template/screens/template_editor_screen.dart';
import 'receipt_settings_screen.dart';

class ReceiptMainScreen extends StatefulWidget {
  const ReceiptMainScreen({super.key});

  @override
  State<ReceiptMainScreen> createState() => _ReceiptMainScreenState();
}

class _ReceiptMainScreenState extends State<ReceiptMainScreen> {
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    // Load catalog and templates on first open
    final scope = ReceiptScope.read(context);
    scope.catalogNotifier.load();
    scope.templateNotifier.load();
  }

  @override
  Widget build(BuildContext context) {
    final scope = ReceiptScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: ListenableBuilder(
          listenable: scope.receiptNotifier,
          builder: (_, _) => Text(scope.receiptNotifier.template.name),
        ),
        actions: [
          // Template picker
          IconButton(
            icon: const Icon(Icons.style_outlined),
            tooltip: 'Шаблон чека',
            onPressed: () => _showTemplatePicker(context),
          ),
          // Catalog
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            tooltip: 'Каталог товаров',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CatalogScreen()),
            ),
          ),
          // Settings
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Настройки',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ReceiptSettingsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Store name banner ───────────────────────────────────────────
          ListenableBuilder(
            listenable: scope.settings,
            builder: (_, _) => Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.primaryContainer,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                scope.settings.storeName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // ── Items list ──────────────────────────────────────────────────
          Expanded(
            child: ListenableBuilder(
              listenable: scope.receiptNotifier,
              builder: (_, _) {
                final notifier = scope.receiptNotifier;
                if (notifier.isEmpty) {
                  return const Center(
                    child: Text('Нажмите «+ Товар» чтобы добавить позицию',
                        style: TextStyle(color: Colors.grey)),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: notifier.items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) => _ReceiptItemTile(
                    item: notifier.items[i],
                    index: i,
                    notifier: notifier,
                  ),
                );
              },
            ),
          ),

          // ── Totals summary ──────────────────────────────────────────────
          ListenableBuilder(
            listenable: scope.receiptNotifier,
            builder: (_, _) {
              final n = scope.receiptNotifier;
              if (n.isEmpty) return const SizedBox.shrink();
              return _TotalsSummary(notifier: n);
            },
          ),

          // ── Bottom actions ──────────────────────────────────────────────
          _BottomBar(
            isBusy: _isBusy,
            onAddItem: () => _showProductPicker(context),
            onClear: () => _confirmClear(context),
            onPrint: () => _print(context),
          ),
        ],
      ),
    );
  }

  // ── Template picker ───────────────────────────────────────────────────────

  void _showTemplatePicker(BuildContext context) {
    final scope = ReceiptScope.read(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        expand: false,
        builder: (_, ctrl) => ListenableBuilder(
          listenable: scope.templateNotifier,
          builder: (ctx, _) {
            final templates = scope.templateNotifier.templates;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      const Text('Выбор шаблона',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      TextButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Создать'),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TemplateEditorScreen(
                                template: ReceiptTemplate(
                                  id: DateTime.now()
                                      .microsecondsSinceEpoch
                                      .toString(),
                                  name: 'Новый шаблон',
                                  paperWidthMm: ReceiptTemplate
                                      .defaultTemplate.paperWidthMm,
                                  blocks: List.of(
                                      ReceiptTemplate.defaultTemplate.blocks),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    controller: ctrl,
                    itemCount: templates.length,
                    itemBuilder: (_, i) {
                      final t = templates[i];
                      final isSelected =
                          scope.receiptNotifier.template.id == t.id;
                      return ListTile(
                        leading: Icon(
                          Icons.receipt_long_outlined,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        title: Text(t.name),
                        subtitle: Text('${t.paperWidthMm} мм'),
                        selected: isSelected,
                        trailing: t.id != 'default'
                            ? IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          TemplateEditorScreen(template: t),
                                    ),
                                  );
                                },
                              )
                            : null,
                        onTap: () {
                          scope.receiptNotifier.setTemplate(t);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Product picker ────────────────────────────────────────────────────────

  void _showProductPicker(BuildContext context) {
    final scope = ReceiptScope.read(context);
    final searchCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        expand: false,
        builder: (_, ctrl) => StatefulBuilder(
          builder: (ctx, setS) {
            final results =
                scope.catalogNotifier.search(searchCtrl.text);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: TextField(
                    controller: searchCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Поиск товара...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => setS(() {}),
                  ),
                ),
                Expanded(
                  child: results.isEmpty
                      ? const Center(child: Text('Нет товаров'))
                      : ListView.builder(
                          controller: ctrl,
                          itemCount: results.length,
                          itemBuilder: (_, i) {
                            final p = results[i];
                            return ListTile(
                              title: Text(p.name),
                              subtitle: Text(
                                  '${p.price.toStringAsFixed(2)} ₽ / ${p.unit}'),
                              onTap: () {
                                scope.receiptNotifier.addProduct(p);
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Print ─────────────────────────────────────────────────────────────────

  Future<void> _print(BuildContext context) async {
    final scope = ReceiptScope.read(context);
    final settings = scope.settings;
    final receipt =
        scope.receiptNotifier.buildReceipt(settings.storeName);
    final template = scope.receiptNotifier.template;
    final transport =
        TcpTransport(host: settings.host, port: settings.port);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isBusy = true);
    try {
      if (settings.printerType == ReceiptPrinterType.xprinter) {
        await EscPosReceiptService()
            .printReceipt(receipt: receipt, template: template, transport: transport);
      } else {
        await ZplReceiptService()
            .printReceipt(receipt: receipt, template: template, transport: transport);
      }
      messenger.showSnackBar(
          const SnackBar(content: Text('Чек отправлен на принтер')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text('Ошибка: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Очистить чек?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена')),
          FilledButton(
            onPressed: () {
              ReceiptScope.read(context).receiptNotifier.clear();
              Navigator.pop(ctx);
            },
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
  }
}

// ── Receipt item tile ─────────────────────────────────────────────────────────

class _ReceiptItemTile extends StatelessWidget {
  final ReceiptItem item;
  final int index;
  final ReceiptNotifier notifier;

  const _ReceiptItemTile({
    required this.item,
    required this.index,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          // Name + discount
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                if (item.hasDiscount)
                  Text('Скидка ${item.discountPct!.toStringAsFixed(0)}%',
                      style: TextStyle(
                          fontSize: 12, color: Colors.green.shade700)),
              ],
            ),
          ),

          // Qty controls
          _QtyControl(
            qty: item.qty,
            unit: item.product.unit,
            onChanged: (q) =>
                notifier.updateItem(index, item.copyWith(qty: q)),
          ),

          const SizedBox(width: 8),

          // Line total
          SizedBox(
            width: 72,
            child: Text(
              '${item.lineTotal.toStringAsFixed(2)} ₽',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),

          // Discount button
          IconButton(
            icon: Icon(
              Icons.discount_outlined,
              color: item.hasDiscount ? Colors.green : Colors.grey,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => _editDiscount(context),
          ),

          // Delete button
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => notifier.removeItem(index),
          ),
        ],
      ),
    );
  }

  void _editDiscount(BuildContext context) {
    final ctrl = TextEditingController(
        text: item.discountPct?.toStringAsFixed(0) ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Скидка на «${item.product.name}»'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
              labelText: 'Скидка %',
              hintText: '10',
              suffixText: '%',
              border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () {
              notifier.updateItem(index, item.copyWith(clearDiscount: true));
              Navigator.pop(ctx);
            },
            child: const Text('Убрать скидку'),
          ),
          FilledButton(
            onPressed: () {
              final pct = double.tryParse(ctrl.text.replaceAll(',', '.'));
              if (pct != null && pct >= 0 && pct <= 100) {
                notifier.updateItem(
                    index, item.copyWith(discountPct: pct));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Применить'),
          ),
        ],
      ),
    );
  }
}

// ── Qty control ───────────────────────────────────────────────────────────────

class _QtyControl extends StatelessWidget {
  final double qty;
  final String unit;
  final ValueChanged<double> onChanged;

  const _QtyControl(
      {required this.qty, required this.unit, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final label =
        qty == qty.truncateToDouble() ? qty.toInt().toString() : qty.toString();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _btn(Icons.remove, () => onChanged((qty - 1).clamp(1, 999))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text('$label $unit',
              style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
        _btn(Icons.add, () => onChanged(qty + 1)),
      ],
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 18),
        ),
      );
}

// ── Totals summary ────────────────────────────────────────────────────────────

class _TotalsSummary extends StatelessWidget {
  final ReceiptNotifier notifier;
  const _TotalsSummary({required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        children: [
          if (notifier.hasDiscount) ...[
            _row('Итого без скидки',
                '${notifier.subtotal.toStringAsFixed(2)} ₽'),
            _row('Скидка',
                '-${notifier.totalDiscount.toStringAsFixed(2)} ₽',
                color: Colors.green.shade700),
          ],
          _row(
            'ИТОГО',
            '${notifier.total.toStringAsFixed(2)} ₽',
            bold: true,
            large: true,
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value,
      {bool bold = false, bool large = false, Color? color}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontSize: large ? 18 : 14,
      color: color,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}

// ── Bottom bar ────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final bool isBusy;
  final VoidCallback onAddItem;
  final VoidCallback onClear;
  final VoidCallback onPrint;

  const _BottomBar({
    required this.isBusy,
    required this.onAddItem,
    required this.onClear,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
        child: Row(
          children: [
            OutlinedButton.icon(
              onPressed: onAddItem,
              icon: const Icon(Icons.add),
              label: const Text('Товар'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: onClear,
              child: const Icon(Icons.delete_sweep_outlined),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: isBusy ? null : onPrint,
                icon: isBusy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.print_outlined),
                label: Text(isBusy ? 'Печать...' : 'Печать чека'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
