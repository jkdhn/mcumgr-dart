import 'package:mcumgr/src/mgmt/header.dart';
import 'package:test/test.dart';

void main() {
  group('mgmt', () {
    test('encode', () {
      final header = Header(
        type: PacketType.read,
        flags: 11,
        length: 1234,
        group: 5678,
        sequence: 17,
        id: 51,
      );
      final output = header.encode();
      expect(output, [0, 11, 4, 210, 22, 46, 17, 51]);
    });
    test('decode', () {
      final input = [0, 11, 4, 210, 22, 46, 17, 51];
      final header = Header.decode(input);
      expect(header.type, PacketType.read);
      expect(header.flags, 11);
      expect(header.length, 1234);
      expect(header.group, 5678);
      expect(header.sequence, 17);
      expect(header.id, 51);
    });
    test('encode_erase_command', () {
      final header = Header(
        type: PacketType.write,
        flags: 0,
        length: 0,
        group: 1,
        sequence: 7,
        id: 5,
      );
      final output = header.encode();
      expect(output, [2, 0, 0, 0, 0, 1, 7, 5]);
    });
    test('decode_erase_response', () {
      const input = [3, 0, 0, 6, 0, 1, 8, 5];
      final header = Header.decode(input);
      expect(header.type, PacketType.writeResponse);
      expect(header.flags, 0);
      expect(header.length, 6);
      expect(header.group, 1);
      expect(header.sequence, 8);
      expect(header.id, 5);
    });
  });
}
