import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../widgets/draw_modal/draw_modal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const double _triggerDistance = 80; // 下滑触发距离阈值
  static const double _excludeBottom = 72; // 最底部排除区域高度（避免与底部导航冲突）

  bool _eligibleFromLowerHalfExceptBottom = false;
  bool _triggered = false;
  double _startDy = 0;

  void _onPanStart(DragStartDetails details) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    _startDy = details.localPosition.dy;
    final double lowerHalfStart = size.height * 0.5;
    final double bottomLimit = size.height - padding.bottom - _excludeBottom;
    _eligibleFromLowerHalfExceptBottom = _startDy >= lowerHalfStart && _startDy <= bottomLimit;
    _triggered = false;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_eligibleFromLowerHalfExceptBottom || _triggered) return;
    final dy = details.localPosition.dy - _startDy;
    if (dy > _triggerDistance) {
      _triggered = true;
      context.push('/calendar');
    }
  }

  void _onPanEnd(DragEndDetails details) {
    // 如果没有达到位移阈值，但下滑速度足够快，也允许触发
    if (!_triggered && _eligibleFromLowerHalfExceptBottom) {
      if (details.velocity.pixelsPerSecond.dy > 800) {
        _triggered = true;
        context.push('/calendar');
      }
    }
    _eligibleFromLowerHalfExceptBottom = false;
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
            SizedBox(
              width: 220,
              height: 26,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    'Swipe down to open calendar',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      letterSpacing: 1.2,
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 1
                        ..color = const Color(0xFF6A4B0A),
                      fontFamilyFallback: const [
                        'Brush Script MT',
                        'Snell Roundhand',
                        'Apple Chancery',
                        'Segoe Script',
                        'Lucida Handwriting',
                        'Pacifico',
                        'cursive',
                      ],
                    ),
                  ),
                  ShaderMask(
                    shaderCallback: (Rect bounds) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFF7D87A),
                        Color(0xFFE9C75C),
                        Color(0xFFD4AF37),
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ).createShader(bounds),
                    blendMode: BlendMode.srcIn,
                    child: const Text(
                      'Swipe down to open calendar',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        letterSpacing: 1.2,
                        color: Colors.white,
                        fontFamilyFallback: [
                          'Brush Script MT',
                          'Snell Roundhand',
                          'Apple Chancery',
                          'Segoe Script',
                          'Lucida Handwriting',
                          'Pacifico',
                          'cursive',
                        ],
                      ),
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
}
