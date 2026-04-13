import 'dart:typed_data';
import 'printer_transport.dart';

/// Stub — USB transport.
/// Android: flutter_usb_printer / usb_serial
/// Windows/Linux: usb_serial
/// macOS: Platform Channel
class UsbTransport implements PrinterTransport {
  final String deviceId;

  UsbTransport({required this.deviceId});

  @override
  String get displayName => 'USB $deviceId';

  @override
  bool get isConnected => false;

  @override
  Future<void> connect() async {
    throw UnimplementedError('UsbTransport is not yet implemented');
  }

  @override
  Future<void> send(Uint8List data) async {
    throw UnimplementedError('UsbTransport is not yet implemented');
  }

  @override
  Future<void> disconnect() async {}
}
