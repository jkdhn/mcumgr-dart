import 'package:mcumgr/msg.dart';
import 'package:mcumgr/packet.dart';

const eraseCommand = Packet(
  header: Header(
    type: Operation.write,
    flags: 0,
    length: 1,
    group: 1,
    sequence: 0,
    id: 5,
  ),
  content: [160],
);
const eraseCommandEncoded = [2, 0, 0, 1, 0, 1, 0, 5, 160];
const eraseResponse = Packet(
  header: Header(
    type: Operation.writeResponse,
    flags: 0,
    length: 6,
    group: 1,
    sequence: 0,
    id: 5,
  ),
  content: [191, 98, 114, 99, 0, 255],
);
const eraseResponseEncoded = [3, 0, 0, 6, 0, 1, 0, 5, 191, 98, 114, 99, 0, 255];
