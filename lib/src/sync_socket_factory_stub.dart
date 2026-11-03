import 'package:web_socket_channel/web_socket_channel.dart';

/// Browser WebSockets don't support configuring a ping interval, so the plain
/// channel is used and keepalive is unavailable.
WebSocketChannel connectSyncSocket(Uri uri, {Duration? pingInterval}) =>
    WebSocketChannel.connect(uri);
