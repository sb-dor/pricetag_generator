import 'package:flutter/material.dart';
import '../../core/di/receipt_scope.dart';
import '../models/product.dart';
import '../notifiers/catalog_notifier.dart';

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = ReceiptScope.of(context).catalogNotifier;

    return Scaffold(
      appBar: AppBar(title: const Text('Каталог товаров')),
      body: ListenableBuilder(
        listenable: notifier,
        builder: (context, _) {
          final products = notifier.products;
          if (products.isEmpty) {
            return const Center(
              child: Text(
                'Нет товаров. Нажмите + чтобы добавить.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }
          return ListView.separated(
            itemCount: products.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final p = products[i];
              return ListTile(
                title: Text(p.name),
                subtitle: Text('${p.price.toStringAsFixed(2)} ₽ / ${p.unit}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _showProductDialog(context, notifier, product: p),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _confirmDelete(context, notifier, p),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductDialog(context, notifier),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showProductDialog(BuildContext context, CatalogNotifier notifier, {Product? product}) {
    final isEdit = product != null;
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final priceCtrl = TextEditingController(text: product?.price.toStringAsFixed(2) ?? '');
    String unit = product?.unit ?? 'шт';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(isEdit ? 'Редактировать товар' : 'Новый товар'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Название',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Цена (₽)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: unit,
                decoration: const InputDecoration(
                  labelText: 'Единица',
                  border: OutlineInputBorder(),
                ),
                items: Product.units
                    .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                    .toList(),
                onChanged: (v) => setS(() => unit = v ?? 'шт'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final price = double.tryParse(priceCtrl.text.replaceAll(',', '.'));
                if (name.isEmpty || price == null || price < 0) return;

                if (isEdit) {
                  notifier.update(product.copyWith(name: name, price: price, unit: unit));
                } else {
                  notifier.add(
                    Product(
                      id: DateTime.now().microsecondsSinceEpoch.toString(),
                      name: name,
                      price: price,
                      unit: unit,
                    ),
                  );
                }
                Navigator.pop(ctx);
              },
              child: Text(isEdit ? 'Сохранить' : 'Добавить'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, CatalogNotifier notifier, Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить товар?'),
        content: Text('«${product.name}» будет удалён из каталога.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
            onPressed: () {
              notifier.remove(product.id);
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}
