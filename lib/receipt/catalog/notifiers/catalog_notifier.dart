import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';

class CatalogNotifier extends ChangeNotifier {
  static const _key = 'receipt_catalog';

  List<Product> _products = [];
  List<Product> get products => List.unmodifiable(_products);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    final list = jsonDecode(raw) as List;
    _products = list
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(_products.map((p) => p.toJson()).toList()),
    );
  }

  void add(Product product) {
    _products.add(product);
    notifyListeners();
    _persist();
  }

  void update(Product product) {
    final i = _products.indexWhere((p) => p.id == product.id);
    if (i == -1) return;
    _products[i] = product;
    notifyListeners();
    _persist();
  }

  void remove(String id) {
    _products.removeWhere((p) => p.id == id);
    notifyListeners();
    _persist();
  }

  List<Product> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return products;
    return _products
        .where((p) => p.name.toLowerCase().contains(q))
        .toList();
  }
}
