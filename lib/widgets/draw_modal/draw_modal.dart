import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:math' as math;

/// 抽卡弹窗（占位版）：用于确定布局与大致位置，无实际功能
class DrawModal {
  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.45),
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return const _DrawModalSheet();
      },
    );
  }
}

// Mock 数据（Step1）
class _SpreadMock {
  final String title;
  final String desc;
  final int cards;
  const _SpreadMock(this.title, this.desc, this.cards);
}

const String _mockQuestion = '我与TA的关系是否会在未来三个月有所进展？';
const List<String> _mockAnalysis = [
  '当前沟通频率较低，但对方对你保持基本好感。',
  '近期星象显示情绪波动，需要把握合适的沟通窗口。',
  '建议先采用三张牌的关系发展牌阵进行初步洞察。',
];

const List<_SpreadMock> _mockSpreads = [
  _SpreadMock('三张牌', '过去-现在-未来', 3),
  _SpreadMock('五张牌', '现状-挑战-建议-外力-结果', 5),
  _SpreadMock('凯尔特十字', '经典综合解析', 10),
  _SpreadMock('七点马蹄', '行动-阻碍-资源-关系-转折-建议-结果', 7),
  _SpreadMock('关系六点', '你-TA-现状-阻碍-建议-结果', 6),
  _SpreadMock('事业四象限', '目标-优势-劣势-行动', 4),
  _SpreadMock('决策两选一', '选项A-选项B-对比-结论', 4),
  _SpreadMock('月度洞察', '上旬-中旬-下旬-整体建议', 4),
  _SpreadMock('九宫格', '综合九项维度观测', 9),
  _SpreadMock('金字塔八点', '基础-现状-阻碍-资源-机会-行动-外力-结果', 8),
];

class _DrawModalSheet extends StatefulWidget {
  const _DrawModalSheet();

  @override
  State<_DrawModalSheet> createState() => _DrawModalSheetState();
}

class _DrawModalSheetState extends State<_DrawModalSheet> {
  int _step = 0; // 0: Step1, 1: Step2
  _SpreadMock _selectedSpread = _mockSpreads.first; // 可变：支持在第一页选择牌阵
  List<bool> _revealed = List<bool>.filled(_mockSpreads.first.cards, false);
  // Step2：按所选牌阵的卡位进行抽取，记录已选卡面
  late List<_Face?> _pickedFaces = List<_Face?>.filled(_selectedSpread.cards, null);
  final List<_Face> _deckFaces = _buildMockDeckFaces();

  bool get _allRevealed => _revealed.every((v) => v);

  // 从牌堆中选择一张牌，按顺序填充到上半部分的下一个空卡位
  void _pickFromDeck(_Face face) {
    final int nextIndex = _pickedFaces.indexWhere((f) => f == null);
    if (nextIndex == -1) return; // 已填满
    setState(() {
      _pickedFaces[nextIndex] = face;
      _revealed[nextIndex] = true;
    });
  }

  // 在第一页选择牌阵后，更新当前选择并重置第二页的状态
  void _setSelectedSpread(_SpreadMock s) {
    if (identical(s, _selectedSpread)) return;
    setState(() {
      _selectedSpread = s;
      _revealed = List<bool>.filled(s.cards, false);
      _pickedFaces = List<_Face?>.filled(s.cards, null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final Size size = MediaQuery.of(context).size;
    // 自适应：高屏增大间距，短屏按比例缩小浮窗高度
    final double screenH = size.height;
    double heightFactor = 0.92;
    double spacingScale = 1.0;
    if (screenH >= 900) {
      spacingScale = 1.25;
    } else if (screenH >= 780) {
      spacingScale = 1.1;
    }
    if (screenH <= 720) {
      final double t = ((720 - screenH) / 300).clamp(0.0, 1.0);
      heightFactor = 0.92 - t * 0.12; // 最低约 0.80
    }
    final double maxHeight = size.height * heightFactor;

    return FractionallySizedBox(
      heightFactor: heightFactor,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, spreadRadius: 4),
          ],
        ),
        child: SafeArea(
          top: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  // 顶部栏：关闭 + 进度点 + 设置占位
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8 * spacingScale),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        Expanded(
                          child: Center(
                            child: _DotsPlaceholder(count: 3, activeIndex: _step),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.tune),
                          onPressed: null, // 占位无功能
                        ),
                      ],
                    ),
                  ),

                  // 内容区域：根据步骤切换
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _step == 0 ? _buildStep1(context, spacingScale) : _buildStep2(context, spacingScale),
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 16 + MediaQuery.of(context).padding.bottom,
                    ),
                    child: SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _step == 0
                            ? () => setState(() => _step = 1)
                            : () => Navigator.of(context).pop(),
                        child: Text(
                          _step == 0 ? '继续' : '完成',
                          style: textTheme.titleMedium,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // Step1 内容（原布局）
  Widget _buildStep1(BuildContext context, double spacingScale) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8 * spacingScale),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _SectionCard(title: '问题', child: const _QuestionMock(), paddingScale: spacingScale),
              SizedBox(height: 16 * spacingScale),
              _SectionCard(title: '问题分析', child: const _AnalysisMock(), paddingScale: spacingScale),
              SizedBox(height: 16 * spacingScale),
            ]),
          ),
        ),
        // 使用固定高度容器承载横向滚动，避免 Expanded 在不稳定约束下导致无法展示
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
            child: _SectionCard(
              title: '牌阵推荐',
              expandChild: false,
              paddingScale: spacingScale,
              child: SizedBox(
                // 提高容器高度以避免内部卡片内容溢出产生黑黄条纹
                height: 280,
                child: _SpreadGridFillMock(
                  gap: 8 * spacingScale,
                  selected: _selectedSpread,
                  onSelect: _setSelectedSpread,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Step2 内容：抽牌交互
  Widget _buildStep2(BuildContext context, double spacingScale) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final opened = _pickedFaces.where((f) => f != null).length;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8 * spacingScale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _SectionCard(
              title: _selectedSpread.title,
              expandChild: true,
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 牌阵卡槽区（参考设计图，固定高度）
                    SizedBox(
                      height: 220,
                      child: _SpreadSlotsView(spread: _selectedSpread, slots: _pickedFaces),
                    ),
                    SizedBox(height: 12 * spacingScale),
                    Center(child: Text('Tap to pick your card', style: text.bodyMedium)),
                    const SizedBox(height: 6),
                    const Icon(Icons.favorite_border, size: 18),
                    SizedBox(height: 12 * spacingScale),
                    // 横向牌堆（参考设计图）
                    SizedBox(
                      height: 180,
                      child: _PickDeckStrip(
                        faces: _deckFaces,
                        onPick: _pickFromDeck,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 10 * spacingScale),
          Text('已选：$opened/${_selectedSpread.cards}', style: text.bodyMedium),
        ],
      ),
    );
  }
}

// Mock：卡面简化模型（颜色 + 标签）
class _Face {
  final Color color;
  final String label;
  final String? imageUrl; // 支持图片卡面
  const _Face({required this.color, required this.label, this.imageUrl});
}

List<_Face> _buildMockDeckFaces() {
  const labels = [
    '山景', '猫咪', '海岸', '森林', '星空', '湖泊', '城市', '花朵', '沙漠', '河流', '雪地', '田野'
  ];
  const colors = [
    Colors.blueGrey,
    Colors.deepPurple,
    Colors.teal,
    Colors.indigo,
    Colors.brown,
    Colors.orange,
    Colors.pink,
    Colors.cyan,
    Colors.green,
    Colors.amber,
    Colors.red,
    Colors.lightBlue,
  ];
  return List.generate(labels.length, (i) {
    // 使用 Picsum 提供的示例图片，若加载失败将回退到渐变背景
    final url = 'https://picsum.photos/seed/${i + 1}/400/640';
    return _Face(color: colors[i % colors.length], label: labels[i], imageUrl: url);
  });
}

// 上半部分：按选定牌阵的 positions 展示可填充卡位
class _SpreadSlotsView extends StatelessWidget {
  final _SpreadMock spread;
  final List<_Face?> slots;
  const _SpreadSlotsView({required this.spread, required this.slots});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.25)),
      ),
      clipBehavior: Clip.hardEdge,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final positions = _positionsForSpread(spread);
          final int n = spread.cards;
          // 当前将被选中的卡位：第一个为空的位置
          final int nextIndex = slots.indexWhere((f) => f == null);
          // 自适应卡槽尺寸（随卡数缩放）
          double slotWidth;
          if (n <= 3) {
            slotWidth = 94;
          } else if (n <= 5) {
            slotWidth = 78;
          } else if (n <= 8) {
            slotWidth = 64;
          } else {
            slotWidth = 56;
          }
          // 正常卡牌比例：width / height ≈ 0.62，因此 height = width / 0.62
          final double slotHeight = slotWidth / 0.62;
          final int len = math.min(positions.length, slots.length);
          // 当位置数与卡位数不一致时，优先绘制有效范围，其余补空槽
          return Stack(
            children: [
              for (int i = 0; i < len; i++)
                Positioned(
                  left: (positions[i].dx * constraints.maxWidth) - slotWidth / 2,
                  top: (positions[i].dy * constraints.maxHeight) - slotHeight / 2,
                  width: slotWidth,
                  height: slotHeight,
                  child: slots[i] == null
                      ? _EmptySlot(highlight: i == nextIndex)
                      : _FaceCard(face: slots[i]!, highlight: i == nextIndex),
                ),
              if (positions.length > len)
                for (int i = len; i < positions.length; i++)
                  Positioned(
                    left: (positions[i].dx * constraints.maxWidth) - slotWidth / 2,
                    top: (positions[i].dy * constraints.maxHeight) - slotHeight / 2,
                    width: slotWidth,
                    height: slotHeight,
                    child: _EmptySlot(highlight: i == nextIndex),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  final bool highlight;
  const _EmptySlot({this.highlight = false});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 主题色中的金色外发光（与主题主色混合偏金色）
    final Color glowColor = Color.lerp(theme.colorScheme.primary, Colors.amber, 0.5)!
        .withOpacity(0.7);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.35), width: 1.2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, spreadRadius: 1),
          if (highlight)
            BoxShadow(color: glowColor, blurRadius: 28, spreadRadius: 2.5),
          if (highlight)
            BoxShadow(color: glowColor.withOpacity(0.45), blurRadius: 12, spreadRadius: 1.2),
        ],
      ),
      alignment: Alignment.center,
      child: Text('待抽牌', style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _FaceCard extends StatelessWidget {
  final _Face face;
  final bool highlight;
  const _FaceCard({required this.face, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = Border.all(color: theme.colorScheme.outline.withOpacity(0.35));
    // 主题色中的金色外发光（与主题主色混合偏金色）
    final Color glowColor = Color.lerp(theme.colorScheme.primary, Colors.amber, 0.5)!
        .withOpacity(0.7);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: border,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, spreadRadius: 1),
          if (highlight)
            BoxShadow(color: glowColor, blurRadius: 30, spreadRadius: 2.5),
          if (highlight)
            BoxShadow(color: glowColor.withOpacity(0.45), blurRadius: 14, spreadRadius: 1.2),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: face.imageUrl != null
          ? Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  face.imageUrl!,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stack) {
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [face.color.withOpacity(0.85), face.color.withOpacity(0.55)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(child: Text(face.label, style: Theme.of(context).textTheme.labelSmall)),
                    );
                  },
                ),
              ],
            )
          : DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [face.color.withOpacity(0.85), face.color.withOpacity(0.55)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(face.label, style: Theme.of(context).textTheme.labelSmall),
              ),
            ),
      ),
    );
  }
}

// 下半部分：横向牌堆，点击将卡面填充到上方卡位
class _PickDeckStrip extends StatefulWidget {
  final List<_Face> faces;
  final void Function(_Face face) onPick;
  const _PickDeckStrip({required this.faces, required this.onPick});

  @override
  State<_PickDeckStrip> createState() => _PickDeckStripState();
}

class _PickDeckStripState extends State<_PickDeckStrip> {
  late final ScrollController _controller;
  bool _offsetInitialized = false;

  // 为实现“无限循环”，将卡组重复到一个很大的数量
  static const int _repeatMultiplier = 5000; // 适度的大，避免过长构建
  int get _virtualCount => widget.faces.length * _repeatMultiplier;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final double deckHeight = constraints.maxHeight;
      // 卡牌尺寸：遵循正常塔罗卡比例（w/h≈0.58），并预留顶部的弧形下沉空间
      final double cardHeight = deckHeight * 0.82;
      final double cardWidth = cardHeight * 0.62;

      // 为了实现重叠与弧形效果，主轴宽度设置为小于卡牌宽度的 itemExtent
      // 这样相邻卡会互相覆盖（叠在一起），产生扇形效果
      final double itemExtent = cardWidth * 0.84;
      // 在轻微弧线基础上略微增大弧度
      final double radius = math.max(deckHeight * 3.2, constraints.maxWidth * 1.8);
      const double curvatureFactor = 0.40; // 小幅提升下沉幅度

      // 初次构建时，将滚动位置跳到“中点”，制造无限循环的体验
      if (!_offsetInitialized) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_controller.hasClients) return;
          final double midOffset = (_virtualCount / 2) * itemExtent - constraints.maxWidth / 2;
          final double clamped = midOffset.clamp(0.0, _controller.position.maxScrollExtent);
          _controller.jumpTo(clamped);
          _offsetInitialized = true;
        });
      }

      return ScrollConfiguration(
        behavior: const _HScrollBehavior(),
        child: NotificationListener<ScrollEndNotification>(
          onNotification: (notif) {
            if (!_controller.hasClients) return false;
            // 计算最接近中心的卡索引，并在滚动结束时吸附到该位置
            final double viewportCenter = _controller.offset + constraints.maxWidth / 2;
            final double centerIndexExact = (viewportCenter - itemExtent / 2) / itemExtent;
            final int snapIndex = centerIndexExact.round().clamp(0, _virtualCount - 1);
            final double targetOffset = snapIndex * itemExtent + itemExtent / 2 - constraints.maxWidth / 2;
            final double clamped = targetOffset.clamp(_controller.position.minScrollExtent, _controller.position.maxScrollExtent);
            _controller.animateTo(
              clamped,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
            );
            return false;
          },
          child: ListView.builder(
          controller: _controller,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          // 裁剪到牌堆区域，避免内容溢出浮窗块边界
          clipBehavior: Clip.hardEdge,
          itemCount: _virtualCount,
          itemExtent: itemExtent,
          itemBuilder: (context, index) {
            final _Face face = widget.faces[index % widget.faces.length];

            // 根据滚动位置计算与视口中心的水平距离，再映射到弧形的垂直位移与旋转角度
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final double viewportCenter = (_controller.hasClients ? _controller.offset : 0) + constraints.maxWidth / 2;
                final double itemCenter = index * itemExtent + itemExtent / 2;
                final double dx = itemCenter - viewportCenter;
                final double centerIndexExact = (viewportCenter - itemExtent / 2) / itemExtent;
                final int centerIndex = centerIndexExact.round();
                final bool isCenter = index == centerIndex;
                final double r = radius;
                final double clampedDx = dx.clamp(-r + 1, r - 1);
                double dropY = (r - math.sqrt(math.max(0.0, r * r - clampedDx * clampedDx))) * curvatureFactor;
                // 钳制垂直位移，确保不越出可视区域（牌堆高度内）
                final double allowedDown = math.max(0.0, (deckHeight - cardHeight) / 2 - 2);
                dropY = dropY.clamp(0.0, allowedDown);
                final double angle = (clampedDx / r) * 0.14; // 略微增加倾斜，呼应弧度增强
                // 中心卡往上抬升并轻微放大以凸显
                final double lift = isCenter ? -cardHeight * 0.08 : 0.0;
                final double scale = isCenter ? 1.06 : 1.0;

                return Center(
                  child: Transform.translate(
                    offset: Offset(0, dropY + lift),
                    child: Transform.rotate(
                      angle: angle,
                      child: Transform.scale(
                        scale: scale,
                        child: _ArcDeckCard(
                          face: face,
                          width: cardWidth,
                          height: cardHeight,
                          onTap: () => widget.onPick(face),
                          highlight: isCenter,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
        ),
      );
    });
  }
}

class _ArcDeckCard extends StatelessWidget {
  final _Face face;
  final double width;
  final double height;
  final VoidCallback onTap;
  final bool highlight;
  const _ArcDeckCard({required this.face, required this.width, required this.height, required this.onTap, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: height,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outline.withOpacity(0.35)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, spreadRadius: 1),
              if (highlight)
                BoxShadow(color: Color.lerp(Colors.amber, theme.colorScheme.primary, 0.3)!.withOpacity(0.25), blurRadius: 20, spreadRadius: 2),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAliasWithSaveLayer,
            child: Stack(
            fit: StackFit.expand,
            children: [
              const _TarotCardBack(),
              if (highlight)
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text('选择', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white)),
                  ),
                ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}

// 更符合塔罗风格的卡背（深紫金色、中心星徽与双层金边）
class _TarotCardBack extends StatelessWidget {
  const _TarotCardBack();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color gold = Color.lerp(Colors.amber, theme.colorScheme.primary, 0.15)!.withOpacity(0.95);
    final Color deep1 = const Color(0xFF160B2C); // 深紫
    final Color deep2 = const Color(0xFF0D071B); // 更深紫
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.0, -0.05),
          radius: 0.95,
          colors: [deep1, deep2],
          stops: const [0.2, 1.0],
        ),
      ),
      child: CustomPaint(
        painter: _TarotBackPainter(gold: gold),
      ),
    );
  }
}

class _TarotBackPainter extends CustomPainter {
  final Color gold;
  _TarotBackPainter({required this.gold});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // 外层与内层金边
    final outer = RRect.fromRectAndRadius(rect.deflate(1.2), const Radius.circular(12));
    final inner = RRect.fromRectAndRadius(rect.deflate(8), const Radius.circular(10));
    final outerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = gold;
    final innerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = gold.withOpacity(0.7);
    canvas.drawRRect(outer, outerPaint);
    canvas.drawRRect(inner, innerPaint);

    // 角饰花纹（轻微金色曲线）
    final deco = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = gold.withOpacity(0.45);
    // 左上
    final p1 = Path()
      ..moveTo(10, 22)
      ..quadraticBezierTo(size.width * 0.18, 8, size.width * 0.34, 24)
      ..quadraticBezierTo(size.width * 0.22, 18, size.width * 0.18, 28);
    canvas.drawPath(p1, deco);
    // 右上
    final p2 = Path()
      ..moveTo(size.width - 10, 22)
      ..quadraticBezierTo(size.width * 0.82, 8, size.width * 0.66, 24)
      ..quadraticBezierTo(size.width * 0.78, 18, size.width * 0.82, 28);
    canvas.drawPath(p2, deco);
    // 左下
    final p3 = Path()
      ..moveTo(10, size.height - 22)
      ..quadraticBezierTo(size.width * 0.18, size.height - 8, size.width * 0.34, size.height - 24)
      ..quadraticBezierTo(size.width * 0.22, size.height - 18, size.width * 0.18, size.height - 28);
    canvas.drawPath(p3, deco);
    // 右下
    final p4 = Path()
      ..moveTo(size.width - 10, size.height - 22)
      ..quadraticBezierTo(size.width * 0.82, size.height - 8, size.width * 0.66, size.height - 24)
      ..quadraticBezierTo(size.width * 0.78, size.height - 18, size.width * 0.82, size.height - 28);
    canvas.drawPath(p4, deco);

    // 中心星徽与环圈
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width * 0.18;
    final innerR = outerR * 0.45;
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = gold.withOpacity(0.7);
    canvas.drawCircle(center, outerR * 1.18, ringPaint);
    final starStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = gold;
    final star = _buildStarPath(center, outerR, innerR, 5);
    canvas.drawPath(star, starStroke);

    // 星环微光点缀
    final dotPaint = Paint()..color = gold.withOpacity(0.6);
    for (int t = 0; t < 20; t++) {
      final a = (2 * math.pi * t) / 20;
      final pos = center + Offset(math.cos(a), math.sin(a)) * (outerR * 1.18);
      canvas.drawCircle(pos, 0.9, dotPaint);
    }
  }

  Path _buildStarPath(Offset c, double outerR, double innerR, int points) {
    final path = Path();
    final step = math.pi / points; // 半步用于内外交替
    for (int i = 0; i < points * 2; i++) {
      final isOuter = i.isEven;
      final r = isOuter ? outerR : innerR;
      final a = -math.pi / 2 + i * step; // 从正上方开始
      final x = c.dx + r * math.cos(a);
      final y = c.dy + r * math.sin(a);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final bool expandChild;
  final double? paddingScale;
  const _SectionCard({required this.title, required this.child, this.expandChild = false, this.paddingScale});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final double h = MediaQuery.of(context).size.height;
    final double autoScale = h >= 900 ? 1.25 : (h >= 780 ? 1.1 : 1.0);
    final double scale = paddingScale ?? autoScale;
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(14 * scale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: textTheme.titleMedium),
            SizedBox(height: 10 * scale),
            // 当外部为有界高度（如 Step2 中使用 Expanded 包裹卡片）时，允许 child 占据剩余空间
            // 这样 SingleChildScrollView 将在卡片内部滚动，避免底部细微溢出
            expandChild ? Expanded(child: child) : child,
          ],
        ),
      ),
    );
  }
}

class _BoxPlaceholder extends StatelessWidget {
  final double height;
  final String label;
  const _BoxPlaceholder({required this.height, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
    );
  }
}

// 问题（Mock 展示，禁用输入样式）
class _QuestionMock extends StatelessWidget {
  const _QuestionMock();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InputDecorator(
      decoration: InputDecoration(
        labelText: '输入你的问题',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabled: false,
        filled: true,
      ),
      child: Text(
        _mockQuestion,
        style: theme.textTheme.bodyMedium,
      ),
    );
  }
}

// 分析（Mock 展示为要点列表）
class _AnalysisMock extends StatelessWidget {
  const _AnalysisMock();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in _mockAnalysis)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 6, right: 10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(line, style: theme.textTheme.bodyMedium),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// 牌阵推荐（Mock 展示）
class _SpreadGridFillMock extends StatelessWidget {
  final double gap;
  final double cardWidth;
  final _SpreadMock? selected;
  final ValueChanged<_SpreadMock>? onSelect;
  const _SpreadGridFillMock({this.gap = 8, this.cardWidth = 260, this.selected, this.onSelect});

  @override
  Widget build(BuildContext context) {
    // 横向滚动：按总内容宽度滚动（不重复、不无限）
    // 并开启鼠标拖拽支持，以便在 Web/桌面上通过拖动进行滚动
    return ScrollConfiguration(
      behavior: const _HScrollBehavior(),
      child: ListView.builder(
        key: const PageStorageKey('spread_recommend_list'),
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _mockSpreads.length,
        itemBuilder: (context, index) {
          final _SpreadMock item = _mockSpreads[index];
          final bool isSelected = (selected != null && selected!.title == item.title && selected!.cards == item.cards);
          return Padding(
            padding: EdgeInsets.only(right: gap),
            child: SizedBox(
              width: cardWidth,
              child: _SpreadCardMock(
                spread: item,
                fill: true,
                selected: isSelected,
                onTap: () => onSelect?.call(item),
              ),
            ),
          );
        },
      ),
    );
  }
}

// 横向滚动的拖拽行为：允许鼠标与触控设备进行拖拽滚动
class _HScrollBehavior extends MaterialScrollBehavior {
  const _HScrollBehavior();
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
      };
}

class _SpreadCardMock extends StatelessWidget {
  final _SpreadMock spread;
  final bool fill;
  final bool selected;
  final VoidCallback? onTap;
  const _SpreadCardMock({required this.spread, this.fill = false, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = Theme.of(context).textTheme;
    final Color borderColor = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.outline.withOpacity(0.3);
    final List<BoxShadow> glow = selected
        ? [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.25), blurRadius: 14, spreadRadius: 1.2)]
        : [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, spreadRadius: 1)];

    final card = Container(
      // 当 fill=true 时由父布局控制高度，这里不设置固定高度
      height: fill ? null : 100,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: selected ? 1.4 : 1.0),
        boxShadow: glow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(spread.title, style: text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              const Spacer(),
              _CountBadge(count: spread.cards),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 40,
            child: Text(
              spread.desc,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.75)),
            ),
          ),
          if (fill) const SizedBox(height: 8),
          // 固定高度的牌区占位，保持页面一大小不变
          if (fill)
            SizedBox(
              height: 160,
              child: _SpreadPreview(spread: spread),
            ),
          if (selected)
            Align(
              alignment: Alignment.bottomRight,
              child: Icon(Icons.check_circle, color: theme.colorScheme.primary.withOpacity(0.9), size: 18),
            ),
        ],
      ),
    );
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: card);
  }
}

// 牌阵预览：根据塔罗牌阵的常见布局在占位区域内绘制卡位示意
class _SpreadPreview extends StatelessWidget {
  final _SpreadMock spread;
  const _SpreadPreview({required this.spread});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      clipBehavior: Clip.hardEdge,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final positions = _positionsForSpread(spread);
          // 固定卡槽尺寸，适合 160 高度容器
          final double slotWidth = 44;
          // 正常卡牌比例：width / height ≈ 0.62，因此 height = width / 0.62
          final double slotHeight = slotWidth / 0.62;
          return Stack(
            children: [
              for (int i = 0; i < positions.length; i++)
                Positioned(
                  left: (positions[i].dx * constraints.maxWidth) - slotWidth / 2,
                  top: (positions[i].dy * constraints.maxHeight) - slotHeight / 2,
                  width: slotWidth,
                  height: slotHeight,
                  child: _CardSlotPreview(label: '${i + 1}'),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CardSlotPreview extends StatelessWidget {
  final String label;
  const _CardSlotPreview({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, spreadRadius: 1),
        ],
      ),
      alignment: Alignment.center,
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _Pos {
  final double dx; // 0..1 横向相对位置
  final double dy; // 0..1 纵向相对位置
  const _Pos(this.dx, this.dy);
}

List<_Pos> _positionsForSpread(_SpreadMock spread) {
  final t = spread.title;
  final n = spread.cards;
  // 三张牌：水平排列
  if (t.contains('三') && n == 3) {
    return const [
      _Pos(0.15, 0.5),
      _Pos(0.5, 0.5),
      _Pos(0.85, 0.5),
    ];
  }
  // 五张牌：水平排列五张（现状-挑战-建议-外力-结果）
  if (t.contains('五') && n == 5) {
    return const [
      _Pos(0.1, 0.5),
      _Pos(0.3, 0.5),
      _Pos(0.5, 0.5),
      _Pos(0.7, 0.5),
      _Pos(0.9, 0.5),
    ];
  }
  // 凯尔特十字：左侧十字 + 右侧权杖（7-10）
  if (t.contains('凯尔特') && n == 10) {
    return const [
      _Pos(0.35, 0.50), // 1 中心
      _Pos(0.35, 0.50), // 2 横置（示意：与1重叠附近）
      _Pos(0.35, 0.70), // 3 下
      _Pos(0.20, 0.50), // 4 左
      _Pos(0.35, 0.30), // 5 上
      _Pos(0.50, 0.50), // 6 右
      _Pos(0.80, 0.75), // 7 权杖下
      _Pos(0.80, 0.60), // 8
      _Pos(0.80, 0.45), // 9
      _Pos(0.80, 0.30), // 10 权杖上
    ];
  }
  // 七点马蹄：马蹄形弧线
  if (t.contains('马蹄') && n == 7) {
    return const [
      _Pos(0.10, 0.70),
      _Pos(0.25, 0.60),
      _Pos(0.40, 0.50),
      _Pos(0.55, 0.40),
      _Pos(0.70, 0.50),
      _Pos(0.85, 0.60),
      _Pos(0.90, 0.70),
    ];
  }
  // 关系六点：两行各三张
  if ((t.contains('关系') || n == 6) && n == 6) {
    return const [
      _Pos(0.20, 0.35), _Pos(0.50, 0.35), _Pos(0.80, 0.35),
      _Pos(0.20, 0.65), _Pos(0.50, 0.65), _Pos(0.80, 0.65),
    ];
  }
  // 四象限 / 两选一 / 月度洞察：2x2
  if ((t.contains('四象限') || t.contains('两选一') || t.contains('月度')) && n == 4) {
    return const [
      _Pos(0.35, 0.35), _Pos(0.65, 0.35),
      _Pos(0.35, 0.65), _Pos(0.65, 0.65),
    ];
  }
  // 九宫格：3x3
  if (t.contains('九宫') && n == 9) {
    return const [
      _Pos(0.20, 0.25), _Pos(0.50, 0.25), _Pos(0.80, 0.25),
      _Pos(0.20, 0.50), _Pos(0.50, 0.50), _Pos(0.80, 0.50),
      _Pos(0.20, 0.75), _Pos(0.50, 0.75), _Pos(0.80, 0.75),
    ];
  }
  // 金字塔八点：1+2+3+2
  if (t.contains('金字塔') && n == 8) {
    return const [
      _Pos(0.50, 0.20),
      _Pos(0.35, 0.40), _Pos(0.65, 0.40),
      _Pos(0.25, 0.60), _Pos(0.50, 0.60), _Pos(0.75, 0.60),
      _Pos(0.35, 0.80), _Pos(0.65, 0.80),
    ];
  }
  // 默认：水平排列 n 张，超出则自动压缩为换行
  final List<_Pos> res = [];
  final int perRow = n <= 5 ? n : 5;
  final int rows = (n / perRow).ceil();
  for (int r = 0; r < rows; r++) {
    final int start = r * perRow;
    final int end = (start + perRow).clamp(0, n);
    final int count = end - start;
    for (int i = 0; i < count; i++) {
      final double x = 0.1 + (0.8 * (count == 1 ? 0.5 : i / (count - 1)));
      final double y = rows == 1 ? 0.5 : (0.35 + r * 0.3);
      res.add(_Pos(x, y));
    }
  }
  return res;
}

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
      ),
      child: Text('$count 张', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary)),
    );
  }
}

class _DotsPlaceholder extends StatelessWidget {
  final int count;
  final int activeIndex;
  const _DotsPlaceholder({required this.count, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (index) {
        final bool active = index == activeIndex;
        return Container(
          width: active ? 10 : 8,
          height: active ? 10 : 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: active
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.4),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}

// 第二页：抽牌卡格
class _DrawCardsGrid extends StatelessWidget {
  final int count;
  final List<bool> revealed;
  final void Function(int index) onFlip;
  final double spacingScale;
  const _DrawCardsGrid({required this.count, required this.revealed, required this.onFlip, required this.spacingScale});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;

    int columns;
    if (count <= 3) {
      columns = count;
    } else if (count <= 5) {
      columns = 3;
    } else {
      columns = 5;
    }

    return GridView.count(
      crossAxisCount: columns,
      crossAxisSpacing: 12 * spacingScale,
      mainAxisSpacing: 12 * spacingScale,
      physics: const AlwaysScrollableScrollPhysics(),
      // 在 SectionCard 的 Expanded 中可自动填满
      children: List.generate(count, (index) {
        final isOpen = revealed[index];
        return InkWell(
          onTap: () => onFlip(index),
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 0.62, // 近似塔罗牌比例
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outline.withOpacity(0.35)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, spreadRadius: 1),
                ],
              ),
              alignment: Alignment.center,
              child: isOpen
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
                        const SizedBox(height: 8),
                        Text('卡面 ${index + 1}', style: text.titleSmall),
                        Text('Mock 含义与关键词', style: text.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7))),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.style, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                        const SizedBox(height: 8),
                        Text('点击翻开', style: text.bodySmall),
                      ],
                    ),
            ),
          ),
        );
      }),
    );
  }
}
