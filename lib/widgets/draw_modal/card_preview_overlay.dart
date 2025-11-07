import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// 独立的卡牌预览动画组件：
/// - 线性放大到目标比例
/// - 3D Y 轴翻转显示正面
/// - 停留一段时间后回到牌堆原位并移除
/// - 带背景虚化
class CardPreviewOverlay extends StatefulWidget {
  final Widget front; // 卡牌正面
  final Widget back; // 卡牌背面
  final Size cardSize; // 原始卡牌尺寸（宽高）
  final Offset startGlobalCenter; // 起始中心点（全局坐标）
  final Duration enterDuration; // 入场动画时长
  final Duration holdDuration; // 停留时长
  final double targetScale; // 最大缩放比例
  final double blurSigma; // 背景虚化强度
  final Curve scaleCurve; // 放大曲线（线性）
  final Curve flipCurve; // 翻转曲线
  final VoidCallback? onClosed; // 关闭回调（用于移除 OverlayEntry）
  final double startAngleZ; // 起始二维旋转角（与牌堆一致）

  const CardPreviewOverlay({
    super.key,
    required this.front,
    required this.back,
    required this.cardSize,
    required this.startGlobalCenter,
    this.enterDuration = const Duration(milliseconds: 420),
    this.holdDuration = const Duration(milliseconds: 1400),
    this.targetScale = 1.35,
    this.blurSigma = 6.0,
    this.scaleCurve = Curves.linear,
    this.flipCurve = Curves.easeInOut,
    this.onClosed,
    this.startAngleZ = 0.0,
  });

  /// 静态方法：插入到 Overlay 并返回该条目。
  static OverlayEntry show({
    required BuildContext context,
    required Widget front,
    required Widget back,
    required Size cardSize,
    required Offset startGlobalCenter,
    Duration enterDuration = const Duration(milliseconds: 420),
    Duration holdDuration = const Duration(milliseconds: 1400),
    double targetScale = 1.35,
    double blurSigma = 6.0,
    Curve scaleCurve = Curves.linear,
    Curve flipCurve = Curves.easeInOut,
    double startAngleZ = 0.0,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => CardPreviewOverlay(
        front: front,
        back: back,
        cardSize: cardSize,
        startGlobalCenter: startGlobalCenter,
        enterDuration: enterDuration,
        holdDuration: holdDuration,
        targetScale: targetScale,
        blurSigma: blurSigma,
        scaleCurve: scaleCurve,
        flipCurve: flipCurve,
        startAngleZ: startAngleZ,
        onClosed: () {
          // 移除自身并完成
          entry.remove();
        },
      ),
    );
    overlay.insert(entry);
    return entry;
  }

  @override
  State<CardPreviewOverlay> createState() => _CardPreviewOverlayState();
}

class _CardPreviewOverlayState extends State<CardPreviewOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl;
  Timer? _holdTimer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.enterDuration);
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _holdTimer?.cancel();
        _holdTimer = Timer(widget.holdDuration, _reverse);
      } else if (status == AnimationStatus.dismissed) {
        widget.onClosed?.call();
      }
    });
    _ctrl.forward();
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _reverse() {
    if (_ctrl.status == AnimationStatus.completed ||
        _ctrl.status == AnimationStatus.forward) {
      _ctrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.of(context).size;
    final Offset target = Offset(screen.width / 2, screen.height / 2);
    final double t = _ctrl.value; // 0..1

    // 位置插值：起点 -> 屏幕中心（轻缓动）
    final double posTx = Curves.easeOut.transform(t);
    final Offset pos = Offset(
      ui.lerpDouble(widget.startGlobalCenter.dx, target.dx, posTx)!,
      ui.lerpDouble(widget.startGlobalCenter.dy, target.dy, posTx)!,
    );

    // 缩放：线性从 1 -> targetScale（满足“线性放大”）
    final double scale = ui.lerpDouble(1.0, widget.targetScale,
        widget.scaleCurve.transform(t))!;

    // 3D 翻转：0 -> π（在 0.4~0.9 区间完成翻转）
    final double flipIntervalT = _interval(t, 0.4, 0.9);
    final double flipY = math.pi * widget.flipCurve.transform(flipIntervalT);
    final bool showFront = flipY >= (math.pi / 2);

    // 计算卡片左上角位置（保持中心对齐）
    final double left = pos.dx - (widget.cardSize.width * scale) / 2;
    final double top = pos.dy - (widget.cardSize.height * scale) / 2;

    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _reverse, // 点击任意处关闭返回
        child: Stack(
          children: [
            // 背景虚化 + 半透明遮罩
            Positioned.fill(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(
                    sigmaX: widget.blurSigma, sigmaY: widget.blurSigma),
                child: Container(
                  color: Colors.black.withOpacity(0.12),
                ),
              ),
            ),
            Positioned(
              left: left,
              top: top,
              child: Transform.rotate(
                angle: widget.startAngleZ,
                child: Transform.scale(
                  scale: scale,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001) // 轻透视
                      ..rotateY(flipY),
                    child: SizedBox(
                      width: widget.cardSize.width,
                      height: widget.cardSize.height,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // 背面与正面随翻转切换显示
                          if (!showFront) widget.back else widget.front,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 将 0..1 的 t 映射到 [begin, end] 区间的 0..1 子区间，超出则钳制
  double _interval(double t, double begin, double end) {
    if (t <= begin) return 0.0;
    if (t >= end) return 1.0;
    return (t - begin) / (end - begin);
  }
}
