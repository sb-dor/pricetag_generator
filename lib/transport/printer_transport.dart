import 'dart:typed_data';

/// Abstract transport layer for printer communication.
/// Implementations: TcpTransport (now), BluetoothTransport, UsbTransport (future).
abstract class PrinterTransport {
  /// Human-readable name shown in UI (e.g. "WiFi 192.168.1.100:9100")
  String get displayName;

  bool get isConnected;

  Future<void> connect();

  Future<void> send(Uint8List data);

  Future<void> disconnect();
}
