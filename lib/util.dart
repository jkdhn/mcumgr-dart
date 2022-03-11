import 'package:cbor/cbor.dart';
import 'package:mcumgr/msg.dart';

class McuException implements Exception {
  final int rc;

  McuException(this.rc);

  @override
  String toString() {
    return "mcumgr: response code $rc";
  }
}

extension FutureMessageExtension on Future<Message> {
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
