import 'package:cbor/cbor.dart';
import 'package:mcumgr/msg.dart';

/// Thrown if the response contains a non-zero response code.
class McuException implements Exception {
  final int rc;

  McuException(this.rc);

  @override
  String toString() {
    return "mcumgr: response code $rc";
  }
}

extension FutureMessageExtension on Future<Message> {
  /// Checks the response code and throws [McuException] on error.
  /// Otherwise, simply returns this message.
  Future<Message> unwrap() {
    return then(
      (value) {
        final rcValue = value.data[CborString("rc")];
        if (rcValue is CborInt) {
          final rc = rcValue.toInt();
          if (rc != 0) {
            throw McuException(rc);
          }
        }
        return value;
      },
    );
  }
}
