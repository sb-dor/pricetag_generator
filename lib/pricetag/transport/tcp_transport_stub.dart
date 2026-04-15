import 'dart:typed_data';

import 'printer_transport.dart';

/// Web stub — TCP sockets are not available in browsers.
class TcpTransport implements PrinterTransport {
  TcpTransport({required String host, required int port});

  @override
  String get displayName => 'WiFi (недоступно в браузере)';

  @override
  bool get isConnected => false;

  @override
  Future<void> connect() async => throw Exception(
    'Печать через WiFi/TCP недоступна в веб-браузере. '
    'Используйте мобильное или десктопное приложение.',
  );

  @override
  Future<void> send(Uint8List data) async => connect();

  @override
  Future<void> disconnect() async {}
}
