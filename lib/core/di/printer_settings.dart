import 'package:flutter/foundation.dart';

enum PrinterType { xprinter, zebra }

class PrinterSettings extends ChangeNotifier {
  String _host = '192.168.1.100';
  int _port = 9100;
  PrinterType _printerType = PrinterType.xprinter;

  String get host => _host;
  int get port => _port;
  PrinterType get printerType => _printerType;

  void setHost(String host) {
    _host = host;
    notifyListeners();
  }

  void setPort(int port) {
    _port = port;
    notifyListeners();
  }

  void setPrinterType(PrinterType type) {
    _printerType = type;
    notifyListeners();
  }
}
