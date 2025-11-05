import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/draw_modal/draw_modal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const double _triggerDistance = 80; // 下滑触发距离阈值

  bool _eligibleFromTopHalf = false;
  bool _triggered = false;
  double _startDy = 0;

  void _onPanStart(DragStartDetails details) {
    final height = MediaQuery.of(context).size.height;
    _startDy = details.localPosition.dy;
    _eligibleFromTopHalf = _startDy <= height * 0.5;
    _triggered = false;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_eligibleFromTopHalf || _triggered) return;
    final dy = details.localPosition.dy - _startDy;
    if (dy > _triggerDistance) {
      _triggered = true;
      context.push('/calendar');
    }
  }

  void _onPanEnd(DragEndDetails details) {
    // 如果没有达到位移阈值，但下滑速度足够快，也允许触发
    if (!_triggered && _eligibleFromTopHalf) {
      if (details.velocity.pixelsPerSecond.dy > 800) {
        _triggered = true;
        context.push('/calendar');
      }
    }
    _eligibleFromTopHalf = false;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('首页占位页面'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.push('/calendar'),
              child: const Text('打开日历'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => DrawModal.show(context),
              child: const Text('打开抽卡弹窗（占位）'),
            ),
            const SizedBox(height: 28),
            const Text(
              '提示：在屏幕上半部分下滑可打开日历',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
