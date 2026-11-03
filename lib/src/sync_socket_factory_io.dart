import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Opens a client WebSocket with an optional ping keepalive.
///
/// When [pingInterval] is set the socket sends a ping every interval and the
/// connection is closed if a pong is not received within that interval. This
/// lets clients detect zombie TCP connections quickly — a blackholed link
/// otherwise keeps accepting writes silently until the OS gives up on TCP
/// retransmits, which can take tens of minutes.
WebSocketChannel connectSyncSocket(Uri uri, {Duration? pingInterval}) =>
    IOWebSocketChannel.connect(uri, pingInterval: pingInterval);
