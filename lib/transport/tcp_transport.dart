import 'dart:io';
import 'dart:typed_data';
import 'printer_transport.dart';

class TcpTransport implements PrinterTransport {
  final String host;
  final int port;

  Socket? _socket;

  TcpTransport({required this.host, required this.port});

  @override
  String get displayName => 'WiFi $host:$port';

  @override
  bool get isConnected => _socket != null;

  @override
  Future<void> connect() async {
    _socket = await Socket.connect(
      host,
      port,
      timeout: const Duration(seconds: 5),
    );
  }

  @override
  Future<void> send(Uint8List data) async {
    if (_socket == null) await connect();
    _socket!.add(data);
    await _socket!.flush();
  }

  @override
  Future<void> disconnect() async {
    await _socket?.close();
    _socket = null;
  }
}
