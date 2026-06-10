import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../services/ble_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BleService _bleService = BleService();

  // 더미 데이터 사용 여부 플래그
  final bool _useDummyData = false;
  Timer? _dummyDataTimer;
  int _dummyDataIndex = 0;
  final List<String> _dummyData = [
    "25,0,대기중",
    "50,1,대기중",
    "75,0,실링중",
    "100,0,완료",
    "0,0,대기중",
  ];

  bool _isConnected = false;
  double _garbageLevel = 0;
  bool _isLidOpen = false;
  String _sealingStatus = "대기중";

  DateTime _lastUpdated = DateTime.now();

  @override
  void initState() {
    super.initState();

    if (_useDummyData) {
      // 더미 데이터 사용
      _dummyDataTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        _updateStateWithData(_dummyData[_dummyDataIndex]);
        _dummyDataIndex = (_dummyDataIndex + 1) % _dummyData.length;
      });
    } else {
      // 실제 BLE 데이터 사용 및 자동 연결
      _bleService.connectionStatus.listen((isConnected) {
        if (mounted) {
          setState(() {
            _isConnected = isConnected;
          });

          if (!isConnected) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("장치와의 연결이 끊어졌습니다."),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      });

      _bleService.messages.listen((message) {
        _updateStateWithData(message);
      });
      _connect();
    }
  }

  @override
  void dispose() {
    // 위젯이 종료될 때 타이머 해제
    _dummyDataTimer?.cancel();
    _bleService.disconnect(); // 연결 해제 로직 추가
    _bleService.dispose();
    super.dispose();
  }

  void _updateStateWithData(String message) {
    try {
      final data = message.split(",");

      setState(() {
        _garbageLevel = double.parse(data[0]) / 100;
        _isLidOpen = data[1] == "1";
        _sealingStatus = data[2];
        _lastUpdated = DateTime.now();
      });
    } catch (_) {}
  }

  Future<void> _connect() async {
    // 더미 데이터 모드에서는 연결 시도 안함
    if (_useDummyData) return;

    try {
      await _bleService.connect();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("장치에 연결되었습니다."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("연결 실패: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF2E323F),
      appBar: AppBar(
        title: const Text(
          "Smart Bin",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2E323F),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 40.0),
            child: Column(
              children: [
                _buildGauge(theme),
                const SizedBox(height: 30),
                _buildInfoGrid(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGauge(ThemeData theme) {
    final percentage = (_garbageLevel * 100).toInt();
    Color progressColor;
    if (percentage > 90) {
      progressColor = Colors.red.shade400;
    } else if (percentage > 70) {
      progressColor = Colors.orange.shade400;
    } else {
      progressColor = Colors.green.shade400;
    }

    return AspectRatio(
      aspectRatio: 1.5,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF3A4052),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((255 * 0.2).round()),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: SizedBox(
                width: 180,
                height: 180,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: _garbageLevel),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, value, child) {
                    return CircularProgressIndicator(
                      value: value,
                      strokeWidth: 12,
                      backgroundColor: const Color(0xFF2E323F),
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                      strokeCap: StrokeCap.round,
                    );
                  },
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "$percentage%",
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "적재율",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.4,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: [
        _buildInfoCard(
          "뚜껑 상태",
          _isLidOpen ? "열림" : "닫힘",
          _isLidOpen ? Icons.sensor_door_outlined : Icons.sensor_door,
          _isLidOpen ? Colors.orange.shade400 : Colors.white,
        ),
        _buildInfoCard(
          "실링 상태",
          _sealingStatus,
          Icons.autorenew_outlined,
          Colors.white,
        ),
        _buildInfoCard(
          "연결 상태",
          _isConnected ? "연결됨" : "연결 안됨",
          _isConnected ? Icons.bluetooth_connected_outlined : Icons.bluetooth_disabled_outlined,
          _isConnected ? Colors.blue.shade400 : Colors.white,
        ),
        _buildInfoCard(
          "업데이트",
          DateFormat("HH:mm:ss").format(_lastUpdated),
          Icons.update_outlined,
          Colors.white,
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color iconColor) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF3A4052),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}