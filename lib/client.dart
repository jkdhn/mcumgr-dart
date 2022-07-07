import 'dart:async';

import 'package:cbor/cbor.dart';
import 'package:mcumgr/mcumgr.dart';
import 'package:mcumgr/msg.dart';
import 'package:mcumgr/packet.dart';
import 'package:mcumgr/src/encoding.dart';
import 'package:mcumgr/src/smp.dart';

typedef WriteCallback = void Function(List<int>);

/// An mcumgr client.
///
/// Pass your own transport layer to the constructor.
/// Call methods on this class to execute commands.
///
/// Multiple commands may be executed at the same time.
class Client {
  final _input = StreamController<Packet>.broadcast();
  final _output = StreamController<Packet>.broadcast();
  late StreamSubscription<Packet> _subscription;
  var _sequence = 0;

  /// Creates a client.
  ///
  /// When executing a client, the request is sent using the [output] callback
  /// and the response is read from the [input] stream.
  Client({
    required Stream<List<int>> input,
    required WriteCallback output,
    Encoding encoding = smp,
  }) {
    _subscription = encoding.decode(input).listen(
          _input.add,
          onError: _input.addError,
          onDone: _input.close,
        );
    _output.stream.listen((packet) {
      output(encoding.encode(packet));
    });
  }

  Future<void> close() async {
    await _subscription.cancel();
    await _input.close();
    await _output.close();
  }

  Stream<Packet> get incoming => _input.stream;

  Stream<Packet> get outgoing => _output.stream;

  Future<Packet> _execute(Packet packet, Duration timeout) {
    final future = _input.stream
        .where((m) => m.header.sequence == packet.header.sequence)
        .where((m) => _isResponse(m))
        .timeout(timeout)
        .first;

    send(packet);

    return future;
  }

  Packet _createPacket(Message msg) {
    final sequence = _sequence++ & 0xFF;
    final content = cbor.encode(msg.data);
    return Packet(
      header: Header(
        type: msg.op,
        flags: msg.flags,
        length: content.length,
        group: msg.group,
        sequence: sequence,
        id: msg.id,
      ),
      content: content,
    );
  }

  bool _isResponse(Packet packet) {
    switch (packet.header.type) {
      case Operation.readResponse:
      case Operation.writeResponse:
        return true;
      default:
        return false;
    }
  }

  Message _createMessage(Packet packet) {
    final data = cbor.decode(packet.content) as CborMap;
    return Message(
      op: packet.header.type,
      group: packet.header.group,
      id: packet.header.id,
      flags: packet.header.flags,
      data: data,
    );
  }

  /// Executes a message.
  ///
  /// Fails if no response is received within the timeout.
  ///
  /// If available, use high-level API methods such as
  /// [ClientImgExtension.uploadImage] instead.
  /// This low-level method requires building the message and decoding
  /// the response (including error codes) yourself.
  Future<Message> execute(Message msg, Duration timeout) =>
      _execute(_createPacket(msg), timeout).then(_createMessage);

  /// Sends the [packet].
  ///
  /// Unless you need full control over the protocol, use [execute] instead.
  /// This method returns instantly and doesn't wait for a response.
  void send(Packet packet) {
    _output.add(packet);
  }
}
