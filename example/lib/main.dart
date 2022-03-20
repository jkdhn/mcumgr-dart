import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:mcumgr_example/scanner.dart';

import 'device.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final flutterReactiveBle = FlutterReactiveBle();
  final scanner = Scanner(
    flutterReactiveBle,
    // withServices: [Uuid.parse("8d53dc1d-1db7-4cd3-868b-8a527460aa84")],
  );
  runApp(MyApp(
    flutterReactiveBle: flutterReactiveBle,
    scanner: scanner,
  ));
}

class MyApp extends StatelessWidget {
  final FlutterReactiveBle flutterReactiveBle;
  final Scanner scanner;

  const MyApp({
    Key? key,
    required this.flutterReactiveBle,
    required this.scanner,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'mcumgr',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(
        flutterReactiveBle: flutterReactiveBle,
        scanner: scanner,
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({
    Key? key,
    required this.flutterReactiveBle,
    required this.scanner,
  }) : super(key: key);

  final FlutterReactiveBle flutterReactiveBle;
  final Scanner scanner;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('mcumgr'),
      ),
      body: Center(
        child: StreamBuilder<ScannerState>(
          stream: scanner.stream,
          initialData: ScannerState.empty(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(snapshot.error.toString());
            }
            final data = snapshot.data!;
            return ListView.builder(
              itemCount: data.devices.length,
              itemBuilder: (context, index) {
                final device = data.devices[index];
                return ListTile(
                  title: Text(device.name),
                  subtitle: Text(device.id),
                  trailing: Text(device.rssi.toString()),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) {
                        return DeviceScreen(
                          ble: flutterReactiveBle,
                          device: device,
                        );
                      },
                    ));
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
