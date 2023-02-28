import 'dart:async';

import 'package:mcumgr/mcumgr.dart';
import 'package:mcumgr/packet.dart';
import 'package:mcumgr/src/smp.dart';

typedef MockClientHandler = Packet Function(Packet);

class MockClient extends Client {
  MockClient._create(StreamController<List<int>> controller, MockClientHandler handler)
      : super(
          mtu: 498,
          input: controller.stream,
          output: (msg) {
            final header = Header.decode(msg);
            final command = Packet(
              header: header,
              content: msg.sublist(Header.encodedLength),
            );
            final response = handler(command);
            final encoded = smp.encode(response);
            controller.add(encoded);
          },
        );

  factory MockClient(MockClientHandler handler) {
    return MockClient._create(StreamController.broadcast(), handler);
  }
}
