import 'package:mcumgr/packet.dart';

abstract class Encoding {
  /**
   * Encodes a single packet into a message.
   */
  List<int> encode(Packet msg);

  /**
   * Takes a stream of messages (List<int>) and turns it into a stream of packets.
   */
  Stream<Packet> decode(Stream<List<int>> input);
}
