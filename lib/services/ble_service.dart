import 'dart:async';
import 'dart:convert';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BleService {
  final FlutterReactiveBle _ble = FlutterReactiveBle();

  static const String serviceUuid =
      "12345678-1234-1234-1234-123456789abc";

  static const String characteristicUuid =
      "87654321-4321-4321-4321-cba987654321";

  final StreamController<String> _controller =
      StreamController.broadcast();

  Stream<String> get messages => _controller.stream;

  DiscoveredDevice? _device;

  Future<void> connect() async {
    await for (final device in _ble.scanForDevices(
      withServices: [],
      scanMode: ScanMode.lowLatency,
    )) {
      if (device.name == "GarbageBox") {
        _device = device;
        break;
      }
    }

    if (_device == null) {
      throw Exception("GarbageBox 장치를 찾을 수 없음");
    }

    _ble.connectToDevice(
      id: _device!.id,
      connectionTimeout: const Duration(seconds: 10),
    ).listen((state) {
      if (state.connectionState ==
          DeviceConnectionState.connected) {
        _startNotify();
      }
    });
  }

  void _startNotify() {
    final characteristic = QualifiedCharacteristic(
      serviceId: Uuid.parse(serviceUuid),
      characteristicId: Uuid.parse(characteristicUuid),
      deviceId: _device!.id,
    );

    _ble
        .subscribeToCharacteristic(characteristic)
        .listen((data) {
      _controller.add(
        utf8.decode(data),
      );
    });
  }
}