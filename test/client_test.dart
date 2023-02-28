import 'package:cbor/cbor.dart';
import 'package:mcumgr/mcumgr.dart';
import 'package:mcumgr/msg.dart';
import 'package:mcumgr/packet.dart';
import 'package:test/test.dart';

import 'client.dart';
import 'msg.dart';

void main() {
  group('client', () {
    test('erase', () async {
      final client = MockClient(
        (msg) {
          expect(msg, eraseCommand);
          return eraseResponse;
        },
      );
      final future = client.erase(Duration(seconds: 1));
      await future;
    });

    test('upload', () async {
      final localImage = List.generate(1234, (index) => index & 0xFF);
      final localHash = [1, 2, 3, 4];
      final chunkSize = 128;
      var uploadedImage = <int>[];

      final client = MockClient(
        (msg) {
          final content = cbor.decode(msg.content) as CborMap;
          final offset = (content[CborString("off")] as CborInt).toInt();
          final data = (content[CborString("data")] as CborBytes).bytes;
          expect(
            offset,
            allOf(
              uploadedImage.length,
              inClosedOpenRange(0, 1234),
            ),
          );

          if (offset == 0) {
            // start
            final image = (content[CborString("image")] as CborSmallInt).toInt();
            final len = (content[CborString("len")] as CborSmallInt).toInt();
            final sha = (content[CborString("sha")] as CborBytes).bytes;
            expect(image, 0);
            expect(len, localImage.length);
            expect(sha, localHash);
          }

          uploadedImage.addAll(data);

          if (uploadedImage.length != localImage.length) {
            // wasn't the last chunk - should have the full chunk size
            expect(data.length, chunkSize);
          }

          final response = cbor.encode(CborMap({
            CborString("rc"): CborSmallInt(0),
            CborString("off"): CborSmallInt(uploadedImage.length),
          }));
          return Packet(
            header: Header(
              type: Operation.writeResponse,
              flags: 0,
              length: response.length,
              group: 1,
              sequence: msg.header.sequence,
              id: 1,
            ),
            content: response,
          );
        },
      );
      await client.uploadImage(
        0,
        localImage,
        localHash,
        Duration(seconds: 1),
      );
      expect(uploadedImage, localImage);
    });
  });
}
