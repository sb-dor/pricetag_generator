// Conditional import: uses dart:io Socket on native, stub on web.
export 'tcp_transport_stub.dart'
    if (dart.library.io) 'tcp_transport_io.dart';
