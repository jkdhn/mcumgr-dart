import 'package:cbor/cbor.dart';

class Operation {
  static const int read = 0;
  static const int readResponse = 1;
  static const int write = 2;
  static const int writeResponse = 3;
}

/// A message sent to or received from a device.
class Message {
  final int op;
  final int group;
  final int id;
  final int flags;
  final CborMap data;

  Message({
    required this.op,
    required this.group,
    required this.id,
    required this.flags,
    required this.data,
  });

  @override
  String toString() {
    return 'Message{op: $op, group: $group, id: $id, flags: $flags, data: $data}';
  }
}
