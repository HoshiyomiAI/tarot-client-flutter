import 'package:flutter/material.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const double _triggerDistance = 80; // 上滑触发距离阈值
  static const double _bottomAreaFactor = 0.35; // 视为“最下部分”的比例（底部35%）

  bool _eligibleFromBottom = false;
  bool _triggered = false;
  double _startDy = 0;

  void _onPanStart(DragStartDetails details) {
    final height = MediaQuery.of(context).size.height;
    _startDy = details.localPosition.dy;
    // 起点在页面底部区域内，才允许触发关闭
    _eligibleFromBottom = _startDy >= height * (1 - _bottomAreaFactor);
    _triggered = false;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_eligibleFromBottom || _triggered) return;
    final delta = _startDy - details.localPosition.dy; // 上滑为正值
    if (delta > _triggerDistance) {
      _triggered = true;
      Navigator.of(context).pop();
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_triggered && _eligibleFromBottom) {
      // 快速上滑也允许触发
      if (details.velocity.pixelsPerSecond.dy < -900) {
        _triggered = true;
        Navigator.of(context).pop();
      }
    }
    _eligibleFromBottom = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      // 移除 AppBar，改为全屏内容
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: Stack(
          children: [
            // 引导 icon 已移动到窗帘面板内部的较不透明区域

            // 下拉窗帘效果的主体面板：顶部锚定，底部渐隐为透明
            const _CurtainPanel(),

            // 可选：在底部增加轻提示（不抢焦点）——暂时由顶部标签承担引导
          ],
        ),
      ),
    );
  }
}

class _BottomGuideIcon extends StatelessWidget {
  const _BottomGuideIcon();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2436).withOpacity(0.7),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: const Icon(Icons.keyboard_arrow_up, size: 20, color: Colors.white70),
    );
  }
}

class _CurtainPanel extends StatelessWidget {
  const _CurtainPanel();
  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return Align(
      alignment: Alignment.topCenter,
      child: SafeArea(
        top: false,
        left: false,
        right: false,
        bottom: false,
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            minHeight: height * 0.55,
            maxHeight: height * 0.86,
          ),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2436),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
              topLeft: Radius.circular(0),
              topRight: Radius.circular(0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: const [
              Center(
                child: Text(
                  '日历占位页面',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              // 引导按钮位于面板内部靠近底部，但略高于下缘，边界清晰
              const Positioned(
                left: 0,
                right: 0,
                bottom: 16,
                child: const _BottomGuideIcon(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
