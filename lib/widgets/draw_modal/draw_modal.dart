import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;
import 'package:flutter/physics.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 抽卡弹窗（占位版）：用于确定布局与大致位置，无实际功能
class DrawModal {
  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      enableDrag: false,
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
  late List<_Face?> _pickedFaces =
      List<_Face?>.filled(_selectedSpread.cards, null);
  final List<_Face> _deckFaces = _buildMockDeckFaces();

  bool get _allRevealed => _revealed.every((v) => v);

  @override
  void initState() {
    super.initState();
    // 每次进入页面：打乱底部牌堆顺序
    _deckFaces.shuffle(math.Random());
  }

  // 从牌堆中选择一张牌，按顺序填充到上半部分的下一个空卡位
  bool _pickFromDeck(_Face face) {
    final int nextIndex = _pickedFaces.indexWhere((f) => f == null);
    if (nextIndex == -1) return false; // 已填满，拒绝继续抽
    setState(() {
      _pickedFaces[nextIndex] = face;
      _revealed[nextIndex] = true;
    });
    return true; // 接受本次抽牌
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
            BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 4),
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
                    padding: EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8 * spacingScale),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        Expanded(
                          child: Center(
                            child:
                                _DotsPlaceholder(count: 3, activeIndex: _step),
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
                      child: _step == 0
                          ? _buildStep1(context, spacingScale)
                          : _buildStep2(context, spacingScale),
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
          padding:
              EdgeInsets.symmetric(horizontal: 16, vertical: 8 * spacingScale),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _SectionCard(
                  title: '问题',
                  child: const _QuestionMock(),
                  paddingScale: spacingScale),
              SizedBox(height: 16 * spacingScale),
              _SectionCard(
                  title: '问题分析',
                  child: const _AnalysisMock(),
                  paddingScale: spacingScale),
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
                height: 300,
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8 * spacingScale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                SizedBox(height: 20 * spacingScale),
                Text(
                  'Tap to pick your card',
                  style: text.titleMedium
                      ?.copyWith(color: Colors.white.withOpacity(0.8)),
                ),
                SizedBox(height: 8 * spacingScale),
                Container(
                  width: 100,
                  height: 1,
                  color: Colors.white.withOpacity(0.5),
                ),
                SizedBox(height: 20 * spacingScale),
                Expanded(
                  child: _SpreadSlotsView(
                      spread: _selectedSpread, slots: _pickedFaces),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              children: [
                SizedBox(height: 10 * spacingScale),
                Text(
                  'Drag to move',
                  style: text.bodyMedium
                      ?.copyWith(color: Colors.white.withOpacity(0.8)),
                ),
                SizedBox(height: 20 * spacingScale),
                Expanded(
                  child: _PickDeckStrip(
                    faces: _deckFaces,
                    onPick: _pickFromDeck,
                  ),
                ),
              ],
            ),
          ),
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
  // 78 张塔罗牌：22 张大阿尔卡纳 + 56 张小阿尔卡纳（四花色×14）
  final List<String> majors = [
    '愚者', '魔术师', '女祭司', '皇后', '皇帝', '教皇', '恋人', '战车', '力量', '隐者',
    '命运之轮', '正义', '倒吊人', '死神', '节制', '恶魔', '高塔', '星星', '月亮', '太阳', '审判', '世界'
  ];
  final List<String> suits = ['权杖', '圣杯', '宝剑', '星币'];
  final List<String> ranks = [
    '一', '二', '三', '四', '五', '六', '七', '八', '九', '十', '侍者', '骑士', '皇后', '国王'
  ];

  // 生成小阿尔卡纳名称
  final List<String> minors = [
    for (final suit in suits)
      for (final rank in ranks) '$suit$rank'
  ];

  final List<String> names = [...majors, ...minors];
  // 为每张牌生成颜色（保持原有 HSL 渐变），和占位图片 URL（暂不使用）
  final int totalCards = names.length; // 78
  final List<Color> colors = List.generate(
      totalCards,
      (i) => HSLColor.fromAHSL(1.0, (i * 360.0 / totalCards) % 360, 0.5, 0.6)
          .toColor());
  return List.generate(totalCards, (i) {
    final url = 'https://picsum.photos/seed/${i + 1}/400/640';
    return _Face(color: colors[i], label: names[i], imageUrl: url);
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final positions = _positionsForSpread(spread);
          final int n = spread.cards;
          // 当前将被选中的卡位：第一个为空的位置
          final int nextIndex = slots.indexWhere((f) => f == null);
          // 自适应卡槽尺寸（随卡数缩放）
          double slotWidth;
          if (n <= 3) {
            slotWidth = 78;
          } else if (n <= 5) {
            slotWidth = 64;
          } else if (n <= 8) {
            slotWidth = 54;
          } else {
            slotWidth = 48;
          }
          // 正常卡牌比例：width / height ≈ 0.7，因此 height = width / 0.7
          final double slotHeight = slotWidth / 0.7;
          final int len = math.min(positions.length, slots.length);
          // 当位置数与卡位数不一致时，优先绘制有效范围，其余补空槽
          return Stack(
            children: [
              for (int i = 0; i < len; i++)
                Positioned(
                  left:
                      (positions[i].dx * constraints.maxWidth) - slotWidth / 2,
                  top: (positions[i].dy * constraints.maxHeight) -
                      slotHeight / 2,
                  width: slotWidth,
                  height: slotHeight,
                  child: slots[i] == null
                      ? _EmptySlot(highlight: i == nextIndex)
                      : _FaceCard(face: slots[i]!, highlight: i == nextIndex),
                ),
              if (positions.length > len)
                for (int i = len; i < positions.length; i++)
                  Positioned(
                    left: (positions[i].dx * constraints.maxWidth) -
                        slotWidth / 2,
                    top: (positions[i].dy * constraints.maxHeight) -
                        slotHeight / 2,
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
    final Color glowColor =
        Color.lerp(theme.colorScheme.primary, Colors.amber, 0.5)!
            .withOpacity(0.7);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              spreadRadius: 1),
          if (highlight)
            BoxShadow(color: glowColor, blurRadius: 28, spreadRadius: 2.5),
          if (highlight)
            BoxShadow(
                color: glowColor.withOpacity(0.45),
                blurRadius: 12,
                spreadRadius: 1.2),
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
    final border =
        Border.all(color: theme.colorScheme.outline.withOpacity(0.35));
    // 主题色中的金色外发光（与主题主色混合偏金色）
    final Color glowColor =
        Color.lerp(theme.colorScheme.primary, Colors.amber, 0.5)!
            .withOpacity(0.7);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: border,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              spreadRadius: 1),
          if (highlight)
            BoxShadow(color: glowColor, blurRadius: 30, spreadRadius: 2.5),
          if (highlight)
            BoxShadow(
                color: glowColor.withOpacity(0.45),
                blurRadius: 14,
                spreadRadius: 1.2),
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
                            colors: [
                              face.color.withOpacity(0.85),
                              face.color.withOpacity(0.55)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                            child: Text(face.label,
                                style: Theme.of(context).textTheme.labelSmall)),
                      );
                    },
                  ),
                ],
              )
            : DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      face.color.withOpacity(0.85),
                      face.color.withOpacity(0.55)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(face.label,
                      style: Theme.of(context).textTheme.labelSmall),
                ),
              ),
      ),
    );
  }
}

// 下半部分：横向牌堆，点击将卡面填充到上方卡位
class _PickDeckStrip extends StatefulWidget {
  final List<_Face> faces;
  final bool Function(_Face face) onPick; // 返回是否接受本次抽牌
  const _PickDeckStrip({required this.faces, required this.onPick});

  @override
  State<_PickDeckStrip> createState() => _PickDeckStripState();
}

class _PickDeckStripState extends State<_PickDeckStrip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _rotationAngle = 0.0;
  late List<bool> _revealed;
  late List<bool> _reversed; // 每张牌的正位/逆位状态（true=逆位）
  late List<int?> _drawOrder; // 每张牌的抽取顺序（第几张），未抽为 null
  int _acceptedCount = 0; // 已接受的抽牌数量
  // Removed dedicated picked index; use revealed state to persist highlight/offset.

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this)
      ..addListener(() {
        setState(() {
          _rotationAngle = _controller.value;
        });
      });
    _revealed = List<bool>.filled(widget.faces.length, false, growable: false);
    // 每次进入页面随机正逆位（预先确定，点击后不再改变）
    final rand = math.Random();
    _reversed = List<bool>.generate(widget.faces.length, (_) => rand.nextBool(), growable: false);
    _drawOrder = List<int?>.filled(widget.faces.length, null, growable: false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // --- 2D Arc Geometry centered below horizontal middle ---
        const cardWidth = 100.0;
        const cardHeight = 160.0;
        final int numCards = widget.faces.length;
        final double centerX = constraints.maxWidth / 2;
        final double centerY = constraints.maxHeight * 1.45; // move circle further down
        final double radius = constraints.maxWidth * 0.90; // larger radius for looser spacing and wider rotation
        // Wider sweep to increase spacing between cards along the arc
        final double sweepAngle = math.pi * 1.5;
        // Top-of-circle baseline so the arc sits above the center (concave up)
        const double theta0 = -math.pi / 2;
        // Limit rotation so at least a portion (minCoverageRatio) of horizontal width shows cards
        final double width = constraints.maxWidth;
        final double beta = sweepAngle / 2;
        // Linear limit: allow rotation up to a fraction of half-sweep
        const double minCoverageRatio = 0.10; // keep at least 10% horizontal coverage
        final double phiLimit = ((1.0 - minCoverageRatio) * beta).clamp(0.0, math.pi * 2);

        return GestureDetector(
          onPanStart: (details) {
            _controller.stop();
          },
          onPanUpdate: (details) {
            setState(() {
              // Increase sensitivity to expand the effective drag range
              final double delta = details.delta.dx / (radius * 0.6);
              final double next = _rotationAngle + delta;
              // Clamp to keep at least half the horizontal width covered by cards
              _rotationAngle = next.clamp(-phiLimit, phiLimit);
              _controller.value = _rotationAngle; // keep controller in sync
            });
          },
          onPanEnd: (details) {
            // Remove rebound/snap: keep the angle at release without animation.
            _controller.stop();
          },
          child: Stack(
            alignment: Alignment.center,
            children: () {
              final List<Widget> cardChildren = [];
              final List<Widget> labelChildren = []; // 确保标签在所有卡片之上渲染
              for (int index = 0; index < numCards; index++) {
                const double pickOffset = 18.0; // outward movement for revealed (selected) cards
                final double progress = index / (numCards - 1);
                final double theta = theta0 + (progress - 0.5) * sweepAngle + _rotationAngle;
                final bool isRevealed = _revealed[index];
                final double localRadius = radius + (isRevealed ? pickOffset : 0.0);
                final double x = centerX + localRadius * math.cos(theta);
                final double y = centerY + localRadius * math.sin(theta);

                // 卡片主体
                cardChildren.add(Positioned(
                  left: x - cardWidth / 2,
                  top: y - cardHeight / 2,
                  child: Transform(
                    transform: Matrix4.identity()..rotateZ(theta - math.pi / 2),
                    alignment: FractionalOffset.center,
                    child: _ArcDeckCard(
                      face: widget.faces[index],
                      width: cardWidth,
                      height: cardHeight,
                      onTap: () {
                        if (!isRevealed) {
                          final bool accepted = widget.onPick(widget.faces[index]);
                          if (accepted) {
                            setState(() {
                              _revealed[index] = true;
                              _drawOrder[index] = _acceptedCount + 1;
                              _acceptedCount++;
                            });
                          }
                        }
                      },
                      highlight: isRevealed,
                      isRevealed: isRevealed,
                    ),
                  ),
                ));

                // 翻开后在更外层圆环上显示卡名与正逆位（圆形排列）
                if (isRevealed) {
                  final bool reversed = _reversed[index];
                  final String orientationText = reversed ? '逆位' : '正位';
                  final int? order = _drawOrder[index];
                  final String orderText = order == null ? '' : '第${order}张 · ';
                  final String labelText = '$orderText${widget.faces[index].label} · $orientationText';
                  // 更外层圆环：从卡片外沿向外扩展，半径更大
                  const double ringMargin = 40.0; // 与卡片边缘的额外间距
                  const double labelWidth = 150.0;
                  const double labelHeight = 34.0;
                  final double outerR = localRadius + cardHeight / 2 + ringMargin; // 外层圆环半径
                  final double lx = centerX + outerR * math.cos(theta);
                  final double ly = centerY + outerR * math.sin(theta);

                  labelChildren.add(Positioned(
                    left: lx - labelWidth / 2,
                    top: ly - labelHeight / 2,
                    child: IgnorePointer(
                      child: Transform(
                        // 将文字方向反转（在切线方向上旋转 180°）
                        transform: Matrix4.identity()..rotateZ(theta + math.pi / 2),
                        alignment: FractionalOffset.center,
                        child: Container(
                          width: labelWidth,
                          height: labelHeight,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.35)),
                            // 背景颜色与卡牌颜色一致（纯色）
                            color: widget.faces[index].color,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.20),
                                blurRadius: 8,
                                spreadRadius: 2,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              labelText,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.white, // 文字颜色为白色
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ));
                }
              }
              // 先渲染卡片，再渲染外层标签，确保标签层级更外
              return [
                ...cardChildren,
                ...labelChildren,
              ];
            }(),
          ),

        );
      },
    );
  }
}

class _ArcDeckCard extends StatelessWidget {
  final _Face face;
  final double width;
  final double height;
  final bool highlight;
  final bool isRevealed;
  final VoidCallback? onTap;

  const _ArcDeckCard(
      {required this.face,
      required this.width,
      required this.height,
      required this.onTap,
      this.highlight = false,
      this.isRevealed = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: isRevealed ? null : onTap, // 已翻开的牌不能再次点击
      child: SizedBox(
        width: width,
        height: height,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border:                Border.all(color: theme.colorScheme.outline.withOpacity(0.35)),
            boxShadow: [
              // 增强基础阴影效果，使其更具立体感
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                spreadRadius: 2,
                offset: const Offset(0, 2),
              ),
              if (highlight)
                // 添加多层发光效果，营造金色外发光
                BoxShadow(
                  color: Colors.amber.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 5,
                  offset: const Offset(0, 0),
                ),
              if (highlight)
                BoxShadow(
                  color: Colors.amber.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 8,
                  offset: const Offset(0, 0),
                ),
              if (highlight)
                BoxShadow(
                  color: Colors.amber.withOpacity(0.2),
                  blurRadius: 40,
                  spreadRadius: 12,
                  offset: const Offset(0, 0),
                ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 根据是否已翻开显示不同的内容
              if (!isRevealed)
                const _TarotCardBack()
              else
                DecoratedBox(
                  decoration: BoxDecoration(
                    // 去除半透明，使用卡牌纯色背景
                    color: face.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      face.label,
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarotCardBack extends StatelessWidget {
  const _TarotCardBack();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/tarot_back.svg',
      fit: BoxFit.fill,
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final bool expandChild;
  final double? paddingScale;
  const _SectionCard(
      {required this.title,
      required this.child,
      this.expandChild = false,
      this.paddingScale});

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
  const _SpreadGridFillMock(
      {this.gap = 8, this.cardWidth = 260, this.selected, this.onSelect});

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
          final bool isSelected = (selected != null &&
              selected!.title == item.title &&
              selected!.cards == item.cards);
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

// 自定义吸附模拟，确保每次滚动都停在一张牌的中心位置
class _SnapScrollPhysics extends ScrollPhysics {
  final double itemExtent;
  final double viewportWidth;

  const _SnapScrollPhysics(
      {required this.itemExtent,
      required this.viewportWidth,
      ScrollPhysics? parent})
      : super(parent: parent);

  @override
  _SnapScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _SnapScrollPhysics(
      itemExtent: itemExtent,
      viewportWidth: viewportWidth,
      parent: buildParent(ancestor),
    );
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    // 调整速度阈值，使滚动吸附更灵敏
    // 当速度较小时，仍然可能需要创建吸附模拟以确保准确居中
    if (velocity.abs() < 50) {
      // 即使速度很小，也创建吸附模拟以确保精确居中
      return _SnapSimulation(
        position: position.pixels,
        velocity: velocity,
        extent: position.maxScrollExtent,
        itemExtent: itemExtent,
        viewportWidth: viewportWidth,
      );
    }

    return _SnapSimulation(
      position: position.pixels,
      velocity: velocity,
      extent: position.maxScrollExtent,
      itemExtent: itemExtent,
      viewportWidth: viewportWidth,
    );
  }

  @override
  bool get allowImplicitScrolling => false;

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    // 确保不会越过边界
    if (value < position.minScrollExtent)
      return position.minScrollExtent - value;
    if (value > position.maxScrollExtent)
      return value - position.maxScrollExtent;
    return 0.0;
  }
}

// 自定义吸附模拟，确保滚动停在最近的卡片中心
class _SnapSimulation extends Simulation {
  final double position;
  final double velocity;
  final double extent;
  final double itemExtent;
  final double viewportWidth;
  final double targetPosition;
  final double _duration;

  _SnapSimulation({
    required this.position,
    required this.velocity,
    required this.extent,
    required this.itemExtent,
    required this.viewportWidth,
  })  : _duration = 0.25, // 调整动画时间到250ms，使滚动更加流畅
        // 计算目标位置，确保选中的卡片居中显示
        targetPosition = _calculateTargetPosition(
            position, itemExtent, viewportWidth, extent);

  // 计算目标位置的静态方法
  static double _calculateTargetPosition(
      double position, double itemExtent, double viewportWidth, double extent) {
    // 计算当前视口中心位置对应的卡片索引
    final double viewportCenter = position + viewportWidth / 2;
    final int centerCardIndex = (viewportCenter / itemExtent).round();

    // 计算中心卡片应该居中的位置
    final double targetOffset =
        centerCardIndex * itemExtent - viewportWidth / 2 + itemExtent / 2;

    // 确保在边界范围内
    return targetOffset.clamp(0.0, extent);
  }

  @override
  double x(double time) {
    // 使用与ScrollEndNotification一致的动画时间，确保动画效果平滑
    final double t = (time / _duration).clamp(0.0, 1.0);
    final double easedT = _easeOutCubic(t);

    // 计算当前位置到目标位置的插值
    // 确保动画开始和结束位置准确无误
    final double result = lerpDouble(position, targetPosition, easedT)!;

    // 确保结果在有效范围内
    return result.clamp(0.0, extent);
  }

  @override
  double dx(double time) {
    // 计算速度
    final double dt = 0.016; // 约60fps
    if (time + dt > duration) return 0.0;
    return (x(time + dt) - x(time)) / dt;
  }

  @override
  bool isDone(double time) => time >= _duration;

  @override
  double get duration => _duration;

  // 缓动函数
  double _easeOutCubic(double t) {
    return 1.0 - math.pow(1.0 - t, 3.0);
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
  const _SpreadCardMock(
      {required this.spread,
      this.fill = false,
      this.selected = false,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = Theme.of(context).textTheme;
    final Color borderColor = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.outline.withOpacity(0.3);
    final List<BoxShadow> glow = selected
        ? [
            BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.25),
                blurRadius: 14,
                spreadRadius: 1.2)
          ]
        : [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                spreadRadius: 1)
          ];

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
              Text(spread.title,
                  style: text.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
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
              style: text.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.75)),
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
              child: Icon(Icons.check_circle,
                  color: theme.colorScheme.primary.withOpacity(0.9), size: 18),
            ),
        ],
      ),
    );
    return InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(12), child: card);
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
                  left:
                      (positions[i].dx * constraints.maxWidth) - slotWidth / 2,
                  top: (positions[i].dy * constraints.maxHeight) -
                      slotHeight / 2,
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
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              spreadRadius: 1),
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
  // 七点马蹄：对称马蹄形
  if (t.contains('马蹄') && n == 7) {
    return const [
      _Pos(0.15, 0.65), // 左下
      _Pos(0.25, 0.55), // 左中
      _Pos(0.35, 0.45), // 左上
      _Pos(0.50, 0.40), // 顶部中心
      _Pos(0.65, 0.45), // 右上
      _Pos(0.75, 0.55), // 右中
      _Pos(0.85, 0.65), // 右下
    ];
  }
  // 关系六点：两行各三张
  if ((t.contains('关系') || n == 6) && n == 6) {
    return const [
      _Pos(0.20, 0.35),
      _Pos(0.50, 0.35),
      _Pos(0.80, 0.35),
      _Pos(0.20, 0.65),
      _Pos(0.50, 0.65),
      _Pos(0.80, 0.65),
    ];
  }
  // 四象限 / 两选一 / 月度洞察：2x2
  if ((t.contains('四象限') || t.contains('两选一') || t.contains('月度')) && n == 4) {
    return const [
      _Pos(0.35, 0.35),
      _Pos(0.65, 0.35),
      _Pos(0.35, 0.65),
      _Pos(0.65, 0.65),
    ];
  }
  // 九宫格：3x3
  if (t.contains('九宫') && n == 9) {
    return const [
      _Pos(0.20, 0.25),
      _Pos(0.50, 0.25),
      _Pos(0.80, 0.25),
      _Pos(0.20, 0.50),
      _Pos(0.50, 0.50),
      _Pos(0.80, 0.50),
      _Pos(0.20, 0.75),
      _Pos(0.50, 0.75),
      _Pos(0.80, 0.75),
    ];
  }
  // 金字塔八点：1+2+3+2
  if (t.contains('金字塔') && n == 8) {
    return const [
      _Pos(0.50, 0.20),
      _Pos(0.35, 0.40),
      _Pos(0.65, 0.40),
      _Pos(0.25, 0.60),
      _Pos(0.50, 0.60),
      _Pos(0.75, 0.60),
      _Pos(0.35, 0.80),
      _Pos(0.65, 0.80),
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
      child: Text('$count 张',
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: theme.colorScheme.primary)),
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
  const _DrawCardsGrid(
      {required this.count,
      required this.revealed,
      required this.onFlip,
      required this.spacingScale});

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
                border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.35)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      spreadRadius: 1),
                ],
              ),
              alignment: Alignment.center,
              child: isOpen
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome,
                            color: theme.colorScheme.primary),
                        const SizedBox(height: 8),
                        Text('卡面 ${index + 1}', style: text.titleSmall),
                        Text('Mock 含义与关键词',
                            style: text.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.7))),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.style,
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.6)),
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
