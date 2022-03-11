import 'package:cbor/cbor.dart';

enum Operation { read, write }

class Message {
  final Operation op;
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
