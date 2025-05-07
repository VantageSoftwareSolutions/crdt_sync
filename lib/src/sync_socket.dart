import 'dart:async';
import 'dart:convert';

import 'package:crdt/crdt.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'globals.dart';

typedef Handshake = ({
  String nodeId,
  Hlc lastModified,
  Map<String, dynamic>? data,
});

class SyncSocket {
  final WebSocketChannel socket;
  final void Function(int? code, String? reason) onDisconnect;
  final void Function(CrdtChangeset changeset) onChangeset;
  final bool verbose;

  late final StreamSubscription _subscription;

  final _handshakeCompleter = Completer<Handshake>();

  /// Begin managing the socket:
  /// 1. Perform handshake.
  /// 2. Monitor for incoming changesets.
  /// 3. Send local changesets on demand.
  /// 4. Disconnect when done.
  SyncSocket(
    this.socket,
    String localNodeId, {
    required this.onDisconnect,
    required this.onChangeset,
    required this.verbose,
  }) {
    _subscription = socket.stream.map((e) => jsonDecode(e)).listen(
      (message) async {
        _log('⬇️ $message');
        if (!_handshakeCompleter.isCompleted) {
          // The first message is a handshake
          _handshakeCompleter.complete((
            nodeId: message['node_id'] as String,
            // Modified timestamps always use the local node id
            lastModified: Hlc.parse(message['last_modified'] as String)
                .apply(nodeId: localNodeId),
            data: message['data'] as Map<String, dynamic>?
          ));
        } else {
          // Merge into crdt
          final changeset = parseCrdtChangeset(message);
          onChangeset(changeset);
        }
      },
      cancelOnError: true,
      onError: (e) => _log('$e'),
      onDone: close,
    );
  }

  void _send(Map<String, Object?> data) {
    if (data.isEmpty) return;
    _log('⬆️ $data');
    try {
      socket.sink.add(jsonEncode(data));
    } catch (e, st) {
      _log('$e\n$st');
      close(4000, '$e');
    }
  }

  /// Monitor handshake completion. Useful for establishing connections.
  Future<Handshake> receiveHandshake() => _handshakeCompleter.future;

  /// Send local handshake
  void sendHandshake(String nodeId, Hlc lastModified, Object? data) => _send({
        'node_id': nodeId,
        'last_modified': lastModified,
        'data': data,
      });

  /// Send local changeset
  void sendChangeset(CrdtChangeset changeset) =>
      _send(changeset..removeWhere((key, value) => value.isEmpty));

  /// Close this connection
  Future<void> close([int? code, String? reason]) async {
    await Future.wait([
      _subscription.cancel(),
      socket.sink.close(code, reason),
    ]);

    onDisconnect(socket.closeCode, socket.closeReason);
  }

  void _log(String msg) {
    if (verbose) logDebug(msg);
  }
}
