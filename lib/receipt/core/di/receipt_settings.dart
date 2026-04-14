import 'package:flutter/foundation.dart';

enum ReceiptPrinterType { xprinter, zebra }

class ReceiptSettings extends ChangeNotifier {
  String _storeName = 'Мой магазин';
  String _host = '192.168.1.100';
  int _port = 9100;
  ReceiptPrinterType _printerType = ReceiptPrinterType.xprinter;
  int _paperWidthMm = 80; // 58 or 80

  String get storeName => _storeName;
  String get host => _host;
  int get port => _port;
  ReceiptPrinterType get printerType => _printerType;
  int get paperWidthMm => _paperWidthMm;

  void setStoreName(String v) { _storeName = v; notifyListeners(); }
  void setHost(String v) { _host = v; notifyListeners(); }
  void setPort(int v) { _port = v; notifyListeners(); }
  void setPrinterType(ReceiptPrinterType v) { _printerType = v; notifyListeners(); }
  void setPaperWidth(int mm) { _paperWidthMm = mm; notifyListeners(); }
}
