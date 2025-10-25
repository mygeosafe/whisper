import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final bleServiceProvider = Provider<BleService>((ref) {
  return BleService(FlutterBluePlus.instance);
});

class BleService {
  BleService(this._bluetooth);

  final FlutterBluePlus _bluetooth;
  final _pcmController = StreamController<Uint8List>.broadcast();
  final _statusController =
      StreamController<BluetoothConnectionState>.broadcast();

  Stream<Uint8List> get pcmStream => _pcmController.stream;
  Stream<BluetoothConnectionState> get statusStream => _statusController.stream;

  Future<void> ensurePermissions() async {
    await _bluetooth.turnOn();
  }

  Future<void> startScan() async {
    await _bluetooth.startScan(timeout: const Duration(seconds: 5));
    await for (final result in _bluetooth.scanResults) {
      final device = result.device;
      final name = device.platformName.isNotEmpty
          ? device.platformName
          : device.advName;
      if (name.contains('Whispair-LoopMind')) {
        await _bluetooth.stopScan();
        await _connect(device);
        break;
      }
    }
  }

  Future<void> _connect(BluetoothDevice device) async {
    await _statusController.addStream(device.connectionState);
    await device.connect(autoConnect: false).onError((_, __) {});
    final services = await device.discoverServices();
    for (final service in services) {
      for (final characteristic in service.characteristics) {
        if (characteristic.properties.notify) {
          await characteristic.setNotifyValue(true);
          characteristic.lastValueStream.listen((data) {
            _pcmController.add(Uint8List.fromList(data));
          });
        }
      }
    }
  }

  Future<void> dispose() async {
    await _bluetooth.stopScan();
    await _pcmController.close();
    await _statusController.close();
  }
}
