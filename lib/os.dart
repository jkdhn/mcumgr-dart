import 'package:cbor/cbor.dart';
import 'package:mcumgr/client.dart';
import 'package:mcumgr/msg.dart';
import 'package:mcumgr/util.dart';

const _osGroup = 0;
const _osCmdReset = 5;

extension ClientOsExtension on Client {
  Future<void> reset(Duration timeout) {
    return execute(
      Message(
        op: Operation.write,
        group: _osGroup,
        id: _osCmdReset,
        flags: 0,
        data: CborMap({}),
      ),
      timeout,
    ).unwrap();
  }
}
