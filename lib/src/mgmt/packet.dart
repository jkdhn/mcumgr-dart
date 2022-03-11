import 'package:cbor/cbor.dart';
import 'package:mcumgr/src/mgmt/header.dart';

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
