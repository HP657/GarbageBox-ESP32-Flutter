// TODO: BLE 스캔 기능
// TODO: BLE 자동 연결
// TODO: ESP32 데이터 수신
// TODO: 실시간 상태 갱신

abstract class BleService {
  Future<void> connect();
  Future<void> disconnect();
  Stream<String> get messages;
}
