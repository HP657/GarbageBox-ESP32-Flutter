import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService {
  final StreamController<String> _controller = StreamController.broadcast();
  Stream<String> get messages => _controller.stream;

  final StreamController<bool> _connectionStatusController = StreamController.broadcast();
  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  BluetoothDevice? _targetDevice;
  StreamSubscription? _scanSubscription;
  StreamSubscription? _dataSubscription;
  StreamSubscription? _connectionStateSubscription;

  Future<void> connect() async {
    try {
      print("🔎 윈도우 블루투스 스캔 시작...");
      
      // 10초 동안 주변 BLE 장치 스캔 시작
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

      // 스캔 결과 실시간 감시
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) async {
        for (ScanResult r in results) {
          // 장치 이름이 GarbageBox인지 확인
          if (r.device.platformName == "GarbageBox" || r.advertisementData.advName == "GarbageBox") {
            print("🎉 GarbageBox 장치를 찾았습니다! 연결을 시도합니다.");
            
            await FlutterBluePlus.stopScan(); // 장치를 찾았으므로 스캔 중지
            _scanSubscription?.cancel();
            _targetDevice = r.device;

            // 🔴 기기 연결 (최신 패키지 정책에 따른 필수 license 매개변수 추가)
            await _targetDevice!.connect(license: License.nonprofit);
            print("✅ ESP32 연결 성공! 서비스 탐색 중...");
            _connectionStatusController.add(true);

            _connectionStateSubscription = _targetDevice!.connectionState.listen((state) {
              if (state == BluetoothConnectionState.disconnected) {
                _connectionStatusController.add(false);
                print("🔌 블루투스 연결 끊김 (외부 요인)");
                _dataSubscription?.cancel();

                // Add a small delay before attempting to reconnect
                Future.delayed(const Duration(seconds: 2)).then((_) {
                  print("🔁 자동 재연결 시도...");
                  connect(); // Re-run the entire connection process
                });
              }
            });

            // 서비스 및 캐릭터리스틱 찾기
            List<BluetoothService> services = await _targetDevice!.discoverServices();
            for (BluetoothService service in services) {
              if (service.uuid.toString() == "12345678-1234-1234-1234-123456789abc") {
                for (BluetoothCharacteristic c in service.characteristics) {
                  if (c.uuid.toString() == "87654321-4321-4321-4321-cba987654321") {
                    
                    // Notify(알림) 구독 활성화
                    await c.setNotifyValue(true);
                    print("📡 실시간 데이터 수신 시작");

                    // ESP32에서 데이터가 들어오면 스트림에 추가
                    _dataSubscription = c.lastValueStream.listen((value) {
                      if (value.isNotEmpty) {
                        final String data = utf8.decode(value);
                        _controller.add(data); // HomeScreen 위젯으로 전송
                      }
                    });
                  }
                }
              }
            }
            break;
          }
        }
      });
    } catch (e) {
      _connectionStatusController.add(false);
      throw Exception("BLE 에러 발생: $e");
    }
  }

  Future<void> disconnect() async {
    await _targetDevice?.disconnect();
    _scanSubscription?.cancel();
    _dataSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _connectionStatusController.add(false);
    print("❌ 블루투스 연결 해제됨");
  }

  void dispose() {
    _controller.close();
    _connectionStatusController.close();
    _scanSubscription?.cancel();
    _dataSubscription?.cancel();
    _connectionStateSubscription?.cancel();
  }
}
