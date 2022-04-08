import 'dart:async';

import 'package:cbor/cbor.dart';
import 'package:mcumgr/mcumgr.dart';
import 'package:mcumgr/msg.dart';
import 'package:mcumgr/src/encoding.dart';
import 'package:mcumgr/src/mgmt/header.dart';
import 'package:mcumgr/src/mgmt/packet.dart';
import 'package:mcumgr/src/smp/smp.dart';

typedef WriteCallback = void Function(List<int>);

/// An mcumgr client.
///
/// Pass your own transport layer to the constructor.
/// Call methods on this class to execute commands.
///
/// Multiple commands may be executed at the same time.
class Client {
  final _input = StreamController<Packet>.broadcast();
  final WriteCallback _output;
  final Encoding _encoding;
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
  })  : _output = output,
        _encoding = encoding {
    _subscription = encoding.decode(input).listen(
          _input.add,
          onError: _input.addError,
          onDone: _input.close,
        );
  }

  Future<void> close() async {
    await _subscription.cancel();
    await _input.close();
  }

  Future<Packet> _execute(Packet packet, Duration timeout) {
    final future = _input.stream
        .where((m) => m.header.sequence == packet.header.sequence)
        .where((m) => _isResponse(m))
        .timeout(timeout)
        .first;

    _output(_encoding.encode(packet));

    return future;
  }

  Packet _createPacket(Message msg) {
    final sequence = _sequence++ & 0xFF;
    final content = cbor.encode(msg.data);
    final PacketType type;
    switch (msg.op) {
      case Operation.read:
        type = PacketType.read;
        break;
      case Operation.write:
        type = PacketType.write;
        break;
    }

    return Packet(
      header: Header(
        type: type,
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
      case PacketType.readResponse:
      case PacketType.writeResponse:
        return true;
      default:
        return false;
    }
  }

  Message _createMessage(Packet packet) {
    final data = cbor.decode(packet.content) as CborMap;
    final Operation op;
    switch (packet.header.type) {
      case PacketType.readResponse:
        op = Operation.read;
        break;
      case PacketType.writeResponse:
        op = Operation.write;
        break;
      default:
        throw FormatException("type: ${packet.header.type}");
    }
    return Message(
      op: op,
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
}
