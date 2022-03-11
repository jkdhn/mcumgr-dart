import 'dart:async';

import 'package:cbor/cbor.dart';
import 'package:mcumgr/msg.dart';
import 'package:mcumgr/src/encoding.dart';
import 'package:mcumgr/src/mgmt/header.dart';
import 'package:mcumgr/src/mgmt/packet.dart';
import 'package:mcumgr/src/smp/smp.dart';

typedef WriteCallback = void Function(List<int>);

class Client {
  final Stream<Packet> _input;
  final WriteCallback _output;
  final Encoding _encoding;
  var _sequence = 0;

  Client({
    required Stream<List<int>> input,
    required WriteCallback output,
    Encoding encoding = smp,
  })  : _input = encoding.decode(input),
        _output = output,
        _encoding = encoding;

  Future<Packet> _execute(Packet packet, Duration timeout) {
    final future = _input
        .where((m) => m.header.sequence == packet.header.sequence)
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

  Future<Message> execute(Message msg, Duration timeout) =>
      _execute(_createPacket(msg), timeout).then(_createMessage);
}
