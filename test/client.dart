import 'dart:async';

import 'package:mcumgr/mcumgr.dart';
import 'package:mcumgr/src/mgmt/header.dart';
import 'package:mcumgr/src/mgmt/packet.dart';
import 'package:mcumgr/src/smp/smp.dart';

typedef MockClientHandler = Packet Function(Packet);

class MockClient extends Client {
  final StreamController<List<int>> _controller;

  MockClient._create(this._controller, MockClientHandler handler)
      : super(
          input: _controller.stream,
          output: (msg) {
            final header = Header.decode(msg);
            final command = Packet(
              header: header,
              content: msg.sublist(Header.encodedLength),
            );
            final response = handler(command);
            final encoded = smp.encode(response);
            _controller.add(encoded);
          },
        );

  factory MockClient(MockClientHandler handler) {
    return MockClient._create(StreamController.broadcast(), handler);
  }

  Future<void> close() {
    return _controller.close();
  }
}
