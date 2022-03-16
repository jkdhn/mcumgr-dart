import 'package:cbor/cbor.dart';
import 'package:mcumgr/client.dart';
import 'package:mcumgr/msg.dart';
import 'package:mcumgr/util.dart';

const _osGroup = 0;
const _osCmdEcho = 0;
const _osCmdReset = 5;

extension ClientOsExtension on Client {
  /// Sends an echo message to the device.
  ///
  /// The response should contain the same message.
  Future<String> echo(String msg, Duration timeout) {
    return execute(
      Message(
        op: Operation.write,
        group: _osGroup,
        id: _osCmdEcho,
        flags: 0,
        data: CborMap({
          CborString("d"): CborString(msg),
        }),
      ),
      timeout,
    ).unwrap().then(
          (msg) => (msg.data[CborString("r")] as CborString).toString(),
        );
  }

  /// Resets (reboots) the device.
  ///
  /// You will probably have to reconnect and create a new client after
  /// calling this.
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
