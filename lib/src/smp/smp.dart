import 'dart:async';

import 'package:mcumgr/src/encoding.dart';
import 'package:mcumgr/src/mgmt/header.dart';
import 'package:mcumgr/src/mgmt/packet.dart';

const smp = Smp();

class Smp implements Encoding {
  const Smp();

  @override
  List<int> encode(Packet msg) {
    return msg.header.encode() + msg.content;
  }

  @override
  Stream<Packet> decode(Stream<List<int>> input) {
    final StreamController<Packet> controller = StreamController.broadcast();
    controller.onListen = () {
      Header? header;
      List<int> content = [];
      final subscription = input.listen(
        (data) {
          if (header == null) {
            // First part of message - read header
            header = Header.decode(data);
            content += data.sublist(Header.encodedLength);
          } else {
            content += data;
          }

          if (content.length == header!.length) {
            // Done
            final msg = Packet(
              header: header!,
              content: content,
            );
            controller.add(msg);

            // Reset
            header = null;
            content = [];
          }
        },
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = subscription.cancel;
    };
    return controller.stream;
  }
}
