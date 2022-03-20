import 'dart:async';
import 'dart:developer';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

/// Provides a stream with a list of discovered devices.
class Scanner {
  final FlutterReactiveBle _ble;
  final List<DiscoveredDevice> _devices = [];
  final StreamController<ScannerState> _controller =
      StreamController.broadcast();

  Scanner(this._ble, {List<Uuid> withServices = const []}) {
    _controller.onListen = () {
      log("Started scanning");

      final subscription =
          _ble.scanForDevices(withServices: withServices).listen(
        (event) {
          _handle(event);
        },
        onError: _controller.addError,
        onDone: _controller.close,
      );

      _controller.onCancel = () async {
        await subscription.cancel();
        log("Stopped scanning");
      };
    };
  }

  void _handle(DiscoveredDevice device) {
    // Add to list or replace existing list entry
    final index = _devices.indexWhere((element) => element.id == device.id);
    if (index == -1) {
      _devices.add(device);
    } else {
      _devices[index] = device;
    }
    _controller.add(ScannerState(_devices));
  }

  Stream<ScannerState> get stream {
    return _controller.stream;
  }
}

class ScannerState {
  final List<DiscoveredDevice> devices;

  ScannerState(this.devices);

  ScannerState.empty() : this([]);
}
