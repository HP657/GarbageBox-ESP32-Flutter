import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 더미 데이터
  bool _isConnected = false;
  double _garbageLevel = 0.72; // 72%
  bool _isLidOpen = false;
  DateTime _lastUpdated = DateTime(2026, 6, 3, 21, 30);
  String _sealingStatus = '대기 중'; // 대기 중, 실링 중, 실링 완료
  bool _isSealing = false;

  // TODO: 실시간 상태 갱신 (BLE 서비스로부터 데이터를 받아 상태를 업데이트)

  void _handleSealing() async {
    if (_isSealing) return;

    setState(() {
      _isSealing = true;
      _sealingStatus = '실링 중...';
    });

    // 실링 과정 시뮬레이션 (3초)
    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      _sealingStatus = '실링 완료';
      _garbageLevel = 0.0; // 쓰레기통 비우기
      _lastUpdated = DateTime.now();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('쓰레기 봉투 실링 및 교체가 완료되었습니다.'),
          duration: Duration(seconds: 3),
        ),
      );
    }

    // 5초 후 다시 대기 상태로 변경
    await Future.delayed(const Duration(seconds: 5));
    setState(() {
      _sealingStatus = '대기 중';
      _isSealing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Garbage Box'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(
              icon: Icons.bluetooth_disabled,
              title: '연결 상태',
              content: _isConnected ? '연결됨' : '연결 안됨',
              color: _isConnected ? Colors.green : Colors.grey,
            ),
            const SizedBox(height: 16),
            _buildGarbageLevelCard(),
            const SizedBox(height: 16),
            _buildStatusCard(
              icon: Icons.autorenew,
              title: '실링 상태',
              content: _sealingStatus,
              color: _isSealing ? Theme.of(context).colorScheme.primary : Colors.grey,
            ),
            const SizedBox(height: 16),
            _buildStatusCard(
              icon: Icons.door_sliding,
              title: '뚜껑 상태',
              content: _isLidOpen ? '열림' : '닫힘',
            ),
            const SizedBox(height: 16),
            _buildStatusCard(
              icon: Icons.update,
              title: '마지막 업데이트',
              content: DateFormat('yyyy-MM-dd HH:mm').format(_lastUpdated),
            ),
            const Spacer(),
            // TODO: BLE 스캔 및 연결 버튼 구현
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.bluetooth_searching),
                      onPressed: () {
                        // TODO: BLE 스캔 기능
                        // TODO: BLE 자동 연결
                      },
                      label: const Text('장치 연결'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.settings),
                      onPressed: _isSealing ? null : _handleSealing,
                      label: const Text('실링 시작'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String title,
    required String content,
    Color? color,
  }) {
    final titleStyle = Theme.of(context).textTheme.titleMedium;
    final contentStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 32, color: color ?? Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: titleStyle),
                Text(content, style: contentStyle?.copyWith(color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGarbageLevelCard() {
    final contentStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold);
    
    Color progressColor;
    if (_garbageLevel > 0.9) {
      progressColor = Colors.red;
    } else if (_garbageLevel > 0.7) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.green;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('쓰레기 적재율', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _garbageLevel,
                      minHeight: 18,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${(_garbageLevel * 100).toStringAsFixed(0)}%',
                  style: contentStyle?.copyWith(color: progressColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
