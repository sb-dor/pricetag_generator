import 'dart:typed_data';
import 'printer_transport.dart';

/// Stub — Bluetooth (Classic SPP) transport.
/// TODO: implement with flutter_bluetooth_serial (Android) or platform channel.
class BluetoothTransport implements PrinterTransport {
  final String address;

  BluetoothTransport({required this.address});

  @override
  String get displayName => 'Bluetooth $address';

  @override
  bool get isConnected => false;

  @override
  Future<void> connect() async {
    throw UnimplementedError('BluetoothTransport is not yet implemented');
  }

  @override
  Future<void> send(Uint8List data) async {
    throw UnimplementedError('BluetoothTransport is not yet implemented');
  }

  @override
  Future<void> disconnect() async {}
}
