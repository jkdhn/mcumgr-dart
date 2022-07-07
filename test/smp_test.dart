import 'package:mcumgr/src/smp.dart';
import 'package:test/test.dart';

import 'msg.dart';

void main() {
  group('smp', () {
    test('encode_erase_command', () {
      final output = smp.encode(eraseCommand);
      expect(output, eraseCommandEncoded);
    });
    test('decode_single', () {
      final input = Stream.fromIterable([eraseCommandEncoded]);
      final decoder = smp.decode(input);
      expect(
        decoder,
        emitsInOrder([
          eraseCommand,
          emitsDone,
        ]),
      );
    });
    test('decode_split', () {
      final input = Stream.fromIterable([
        // header can't be split
        eraseCommandEncoded.sublist(0, 8),
        eraseCommandEncoded.sublist(8),
      ]);
      final decoder = smp.decode(input);
      expect(
        decoder,
        emitsInOrder([
          eraseCommand,
          emitsDone,
        ]),
      );
    });
    test('decode_multiple', () {
      final input = Stream.fromIterable([
        // header can't be split
        eraseCommandEncoded.sublist(0, 8),
        eraseCommandEncoded.sublist(8),
        eraseResponseEncoded.sublist(0, 10),
        eraseResponseEncoded.sublist(10),
        eraseCommandEncoded,
      ]);
      final decoder = smp.decode(input);
      expect(
        decoder,
        emitsInOrder([
          eraseCommand,
          eraseResponse,
          eraseCommand,
          emitsDone,
        ]),
      );
    });
  });
}
