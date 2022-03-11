A client library for the [mcumgr](https://github.com/apache/mynewt-mcumgr) device management protocol.

## Features

* Upload firmware updates (DFU)

## Usage

This package just implements the protocol, you need to bring your own transport layer.

```dart
import 'package:mcumgr/mcumgr.dart';

final client = Client(
    input: receiveStream, // bytes received from the device (Stream<List<int>>)
    output: (bytes) { /* send bytes (List<int>) to the device */ }
);
```

### Bluetooth LE

Implementing the
[SMP Bluetooth transport](https://github.com/apache/mynewt-mcumgr/blob/master/transport/smp-bluetooth.md) using
flutter_blue:

```dart
final serviceUuid = Guid('8d53dc1d-1db7-4cd3-868b-8a527460aa84');
final characteristicUuid = Guid('da2e7828-fbce-4e01-ae9e-261174997c48');

// Increase the Bluetooth MTU (this is important!)
await device.requestMtu(252);

// Find the service and its characteristic
final service = services.singleWhere((e) => e.uuid == serviceUuid);
final characteristic = service.characteristics.singleWhere((e) => e.uuid == characteristicUuid);

// Subscribe to messages from the device
await characteristic.setNotifyValue(true);

final client = Client(
  // Used to receive messages from the device
  input: characteristic.onValueChangedStream,
  // Used to send messages to the device
  output: (value) => characteristic.write(value, withoutResponse: true),
);
```

### Firmware updates

1. Send the image to the device
2. Set the image to pending (bootloader will load it on the next boot only)
3. Tell the device to reboot
4. Reconnect to the device
5. Confirm the new image (bootloader will always load it)
