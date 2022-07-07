import 'package:cbor/cbor.dart';

class Header {
  final int type;
  final int flags;
  final int length;
  final int group;
  final int sequence;
  final int id;

  const Header({
    required this.type,
    required this.flags,
    required this.length,
    required this.group,
    required this.sequence,
    required this.id,
  });

  static const encodedLength = 8;

  Header.decode(List<int> input)
      : type = input[0] & 0x07,
        flags = input[1],
        length = ((input[2] << 8) | input[3]),
        group = ((input[4] << 8) | input[5]),
        sequence = input[6],
        id = input[7];

  List<int> encode() {
    return [
      type & 0x07,
      flags,
      (length >> 8) & 0xFF,
      length & 0xFF,
      (group >> 8) & 0xFF,
      group & 0xFF,
      sequence,
      id
    ];
  }

  @override
  String toString() {
    return 'Header{type: $type, flags: $flags, length: $length, group: $group, sequence: $sequence, id: $id}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Header &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          flags == other.flags &&
          length == other.length &&
          group == other.group &&
          sequence == other.sequence &&
          id == other.id;

  @override
  int get hashCode =>
      type.hashCode ^
      flags.hashCode ^
      length.hashCode ^
      group.hashCode ^
      sequence.hashCode ^
      id.hashCode;
}

class Packet {
  final Header header;
  final List<int> content;

  const Packet({
    required this.header,
    required this.content,
  });

  @override
  String toString() {
    return 'Packet{header: $header, content: ${cbor.decode(content)}}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Packet &&
          runtimeType == other.runtimeType &&
          header == other.header &&
          content.length == other.content.length &&
          // slow, but this is only used in tests
          content.toString() == other.content.toString();

  @override
  int get hashCode => header.hashCode ^ content.hashCode;
}
