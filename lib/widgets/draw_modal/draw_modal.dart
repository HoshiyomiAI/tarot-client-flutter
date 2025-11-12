import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import '../../shared/spreads.dart';

/// 抽卡结果（公开给外部消费）
class DrawCardResult {
  final String name;
  final bool reversed;
  const DrawCardResult(this.name, this.reversed);
}

/// 牌阵结果（含牌阵信息与按槽位顺序排列的卡片）
class DrawSpreadResult {
  final String spreadTitle;
  final int count;
  final List<DrawCardResult> cards;
  const DrawSpreadResult({required this.spreadTitle, required this.count, required this.cards});
}

/// 抽卡弹窗：返回抽取到的结果列表（取消返回 null）
class DrawScenario {
  final String title; // 情景/主题，如“爱情占卜”
  final String? desc; // 简要描述
  final List<String>? analysis; // 要点分析（可选）
  final String? preferredSpreadTitle; // 优先牌阵标题（可选）
  const DrawScenario({required this.title, this.desc, this.analysis, this.preferredSpreadTitle});
}

class DrawModal {
  static Future<DrawSpreadResult?> show(BuildContext context, {DrawScenario? scenario, int initialStep = 0}) async {
    return await showModalBottomSheet<DrawSpreadResult?>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      enableDrag: false,
      barrierColor: Colors.black.withOpacity(0.45),
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _DrawModalSheet(scenario: scenario, initialStep: initialStep);
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

final List<_SpreadMock> _mockSpreads = [
  for (final s in SpreadRegistry.spreads)
    _SpreadMock(s.title, s.desc, s.cards),
];

class _DrawModalSheet extends StatefulWidget {
  final DrawScenario? scenario;
  final int initialStep;
  const _DrawModalSheet({this.scenario, this.initialStep = 0});

  @override
  State<_DrawModalSheet> createState() => _DrawModalSheetState();
}

class _DrawModalSheetState extends State<_DrawModalSheet> {
  late int _step;
  late _SpreadMock _selectedSpread; // 在 initState 中初始化，可根据情景设定默认牌阵
  late List<bool> _revealed;
  // Step2：按所选牌阵的卡位进行抽取，记录已选卡（含正/逆位与顺序）
  late List<_PickedCard?> _pickedCards;
  final List<_Face> _deckFaces = _buildMockDeckFaces();

  bool get _allRevealed => _revealed.every((v) => v);

  DrawSpreadResult _buildResults() {
    final List<DrawCardResult> res = [];
    for (final pc in _pickedCards) {
      if (pc != null) {
        res.add(DrawCardResult(pc.face.label, pc.reversed));
      }
    }
    return DrawSpreadResult(
      spreadTitle: _selectedSpread.title,
      count: _selectedSpread.cards,
      cards: res,
    );
  }

  @override
  void initState() {
    super.initState();
    _step = widget.initialStep;
    // 默认牌阵：优先使用情景指定的牌阵标题，否则使用第一个
    final String? preferred = widget.scenario?.preferredSpreadTitle;
    int idx = preferred == null
        ? 0
        : _mockSpreads.indexWhere((s) => s.title.contains(preferred));
    if (widget.initialStep == 1) {
      final dailyIdx = _mockSpreads.indexWhere((s) => s.title == '每日一张');
      if (dailyIdx != -1) {
        idx = dailyIdx;
      }
    }
    _selectedSpread = idx >= 0 ? _mockSpreads[idx] : _mockSpreads.first;
    _revealed = List<bool>.filled(_selectedSpread.cards, false);
    _pickedCards = List<_PickedCard?>.filled(_selectedSpread.cards, null);

    // 每次进入页面：打乱底部牌堆顺序
    _deckFaces.shuffle(math.Random());
  }

  // 从牌堆中选择一张牌，按顺序填充到上半部分的下一个空卡位（保留正/逆位与顺序）
  bool _pickFromDeck(_PickEvent event) {
    final int nextIndex = _pickedCards.indexWhere((f) => f == null);
    if (nextIndex == -1) return false; // 已填满，拒绝继续抽
    setState(() {
      _pickedCards[nextIndex] = _PickedCard(
        face: event.face,
        reversed: event.reversed,
        order: event.order,
      );
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
      _pickedCards = List<_PickedCard?>.filled(s.cards, null);
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
                      child: Builder(builder: (context) {
                        final bool canFinish = _step == 1 && _allRevealed;
                        return ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.resolveWith(
                              (states) {
                                const deep = Color(0xFF1A1724); // 非常深的深紫色
                                if (states.contains(MaterialState.disabled)) {
                                  return deep.withOpacity(0.85);
                                }
                                if (states.contains(MaterialState.pressed)) {
                                  return deep.withOpacity(0.92);
                                }
                                return deep;
                              },
                            ),
                            foregroundColor: MaterialStateProperty.resolveWith(
                              (states) => states.contains(MaterialState.disabled)
                                  ? Colors.white70
                                  : Colors.white,
                            ),
                            shadowColor: MaterialStateProperty.resolveWith(
                              (states) => states.contains(MaterialState.disabled)
                                  ? Colors.transparent
                                  : Colors.black.withOpacity(0.2),
                            ),
                            elevation: MaterialStateProperty.resolveWith(
                              (states) => states.contains(MaterialState.disabled) ? 0 : 1,
                            ),
                            shape: MaterialStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.10),
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                          onPressed: _step == 0
                              ? () {
                                  HapticFeedback.lightImpact();
                                  setState(() => _step = 1);
                                }
                              : (canFinish
                                  ? () {
                                      HapticFeedback.mediumImpact();
                                      Navigator.of(context).pop(_buildResults());
                                    }
                                  : null),
                          child: Text(
                            _step == 0 ? '继续' : '完成',
                            style: textTheme.titleMedium,
                          ),
                        );
                      }),
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
              if (widget.scenario?.desc != null)
                _SectionCard(
                    title: '占卜情景',
                    child: Text(widget.scenario!.desc!),
                    paddingScale: spacingScale),
              SizedBox(height: 16 * spacingScale),
              _SectionCard(
                  title: '问题',
                  child: _QuestionMock(question: widget.scenario?.title ?? _mockQuestion),
                  paddingScale: spacingScale),
              SizedBox(height: 16 * spacingScale),
              _SectionCard(
                  title: '问题分析',
                  child: _AnalysisMock(lines: widget.scenario?.analysis ?? _mockAnalysis),
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
                      spread: _selectedSpread, slots: _pickedCards),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double deadZone = constraints.maxHeight * 0.05; // 底部保留不可触发区域，按高度比例
                return Stack(
                  children: [
                    // 扩大手势触发范围：让牌堆手势覆盖下半部分大区域，排除底部deadZone
                    Positioned.fill(
                      bottom: deadZone,
                      child: _PickDeckStrip(
                        faces: _deckFaces,
                        onPick: _pickFromDeck,
                      ),
                    ),
                    // 引导箭头与艺术字覆盖在底部，且不拦截手势
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: IgnorePointer(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 8 * spacingScale),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset(
                                'assets/images/arc_double_arrow.svg',
                                width: 160,
                                height: 36,
                              ),
                              SizedBox(height: 6 * spacingScale),
                              SizedBox(
                                width: 200,
                                height: 28,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Text(
                                      'Swipe to move',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 22,
                                        letterSpacing: 1,
                                        foreground: Paint()
                                          ..style = PaintingStyle.stroke
                                          ..strokeWidth = 1.2
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
                                        'Swipe to move',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 22,
                                          letterSpacing: 1,
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
                      ),
                    ),
                  ],
                );
              },
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

// 选中事件：自下方牌堆点击时传递的信息
class _PickEvent {
  final _Face face;
  final bool reversed; // true 表示逆位
  final int? order; // 第几张抽到
  final int index; // 牌堆中的索引
  const _PickEvent({required this.face, required this.reversed, this.order, required this.index});
}

// 已选中的卡：包含卡面与正/逆位以及抽取顺序
class _PickedCard {
  final _Face face;
  final bool reversed; // true 表示逆位
  final int? order; // 第几张抽到，可选
  const _PickedCard({required this.face, required this.reversed, this.order});
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
  final List<_PickedCard?> slots;
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
          final labels = SpreadRegistry.labelsForTitle(spread.title, spread.cards);
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
                      ? _EmptySlot(label: (i < labels.length) ? labels[i] : null, highlight: i == nextIndex)
                      : _FaceCard(
                          face: slots[i]!.face,
                          reversed: slots[i]!.reversed,
                          order: slots[i]!.order,
                          highlight: i == nextIndex,
                        ),
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
                    child: _EmptySlot(label: (i < labels.length) ? labels[i] : null, highlight: i == nextIndex),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  final String? label;
  final bool highlight;
  const _EmptySlot({this.label, this.highlight = false});
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
      child: Text(label ?? '待抽牌', style: Theme.of(context).textTheme.labelSmall),
    );
  }
}



class _FaceCard extends StatelessWidget {
  final _Face face;
  final bool reversed;
  final int? order;
  final bool highlight;
  const _FaceCard({required this.face, required this.reversed, this.order, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border =
        Border.all(color: theme.colorScheme.outline.withOpacity(0.35));
    // 主题色中的金色外发光（与主题主色混合偏金色）
    final Color glowColor =
        Color.lerp(theme.colorScheme.primary, Colors.amber, 0.5)!
            .withOpacity(0.7);
    return Stack(
      children: [
        Container(
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
            child: Transform.rotate(
              angle: reversed ? math.pi : 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: face.color, // 纯色背景替代图片
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        for (final ch in face.label.split(''))
                          Text(
                            ch,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  height: 1.05,
                                ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.75),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.35)),
            ),
            child: Text(
              '${order != null ? '第$order张 · ' : ''}${reversed ? '逆位' : '正位'}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ),
      ],
    );
  }
}

// 下半部分：横向牌堆，点击将卡面填充到上方卡位
class _PickDeckStrip extends StatefulWidget {
  final List<_Face> faces;
  final bool Function(_PickEvent event) onPick; // 返回是否接受本次抽牌
  const _PickDeckStrip({required this.faces, required this.onPick});

  @override
  State<_PickDeckStrip> createState() => _PickDeckStripState();
}

class _PickDeckStripState extends State<_PickDeckStrip>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<bool> _revealed;
  late List<bool> _reversed; // 每张牌的正位/逆位状态（true=逆位）
  late List<int?> _drawOrder; // 每张牌的抽取顺序（第几张），未抽为 null
  int _acceptedCount = 0; // 已接受的抽牌数量
  // Removed dedicated picked index; use revealed state to persist highlight/offset.
  static const double _alpha = 0.22; // 指针平滑系数（指数平滑）
  static const double _pixelThreshold = 0.6; // 小于该像素位移忽略，降低抖动
  double _lastDelta = 0.0; // 上一次平滑后的增量，用于EMA
  // 预计算：每张卡的基础角度与三角函数，减少每帧计算成本
  late List<double> _baseTheta;
  late List<double> _baseCos;
  late List<double> _baseSin;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this);
    _revealed = List<bool>.filled(widget.faces.length, false, growable: false);
    // 每次进入页面随机正逆位（预先确定，点击后不再改变）
    final rand = math.Random();
    _reversed = List<bool>.generate(widget.faces.length, (_) => rand.nextBool(), growable: false);
    _drawOrder = List<int?>.filled(widget.faces.length, null, growable: false);
    // 基础角度与三角函数：仅与索引相关，与实时旋转无关
    const double sweepAngle = math.pi * 1.5;
    const double theta0 = -math.pi / 2;
    final int numCards = widget.faces.length;
    _baseTheta = List<double>.generate(numCards, (index) {
      final double progress = index / (numCards - 1);
      return theta0 + (progress - 0.5) * sweepAngle;
    }, growable: false);
    _baseCos = List<double>.generate(numCards, (i) => math.cos(_baseTheta[i]), growable: false);
    _baseSin = List<double>.generate(numCards, (i) => math.sin(_baseTheta[i]), growable: false);
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
        // 卡牌尺寸按比例缩放，适配不同屏幕宽度
        final double cardWidth = constraints.maxWidth * 0.16; // 占宽度约 16%
        final double cardHeight = cardWidth / 0.62; // 保持统一比例（宽/高≈0.62）
        final int numCards = widget.faces.length;
        final double centerX = constraints.maxWidth / 2;
        // 统一垂直位置：将牌堆圆弧的“上沿基线”按高度百分比锚定
        // 基线位置（central card 的 y = baselineY），随容器高度按比例变化
        final double radius = constraints.maxWidth * 0.90; // 保持随宽度自适应的水平间距与旋转
        const double baselineRatio = 0.38; // 圆弧上沿位于容器高度的 38%
        final double baselineY = constraints.maxHeight * baselineRatio;
        final double centerY = baselineY + radius; // 使 top-of-circle 位于 baselineY
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
          behavior: HitTestBehavior.opaque, // 让整个区域都可命中手势，而不只卡片区域
          onHorizontalDragStart: (details) {
            _controller.stop();
            _lastDelta = 0.0;
          },
          onHorizontalDragUpdate: (details) {
            final double? primary = details.primaryDelta; // 沿水平轴的增量，去除垂直噪声
            if (primary == null) return;
            // 忽略极小位移，降低像素级抖动
            if (primary.abs() < _pixelThreshold) return;
            // 原始增量映射到角度
            final double raw = primary / (radius * 0.6);
            // 指数平滑，降低抖动
            final double smoothed = _alpha * raw + (1 - _alpha) * _lastDelta;
            _lastDelta = smoothed;
            final double next = _controller.value + smoothed;
            // 限幅，保持至少一定水平覆盖
            final double clamped = next.clamp(-phiLimit, phiLimit);
            _controller.value = clamped; // 直接驱动 AnimatedBuilder
          },
          onHorizontalDragEnd: (details) {
            // 保持当前角度，不做回弹
            _controller.stop();
            _lastDelta = 0.0;
          },
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final double rotation = _controller.value;
              // 旋转的三角函数（统一使用），与索引无关
              final double cosR = math.cos(rotation);
              final double sinR = math.sin(rotation);
              // 视窗矩形，用于剔除不可见元素（包含边缘留白）
              final double margin = constraints.maxWidth * 0.06; // 相对宽度的留白
              final Rect viewport = Rect.fromLTWH(
                -margin,
                -margin,
                constraints.maxWidth + margin * 2,
                constraints.maxHeight + margin * 2,
              );
              return Stack(
                fit: StackFit.expand, // 扩展至父布局的整个区域
                alignment: Alignment.center,
                children: () {
                  final List<Widget> cardChildren = [];
                  final List<Widget> labelChildren = []; // 确保标签在所有卡片之上渲染
                  for (int index = 0; index < numCards; index++) {
                    final double pickOffset = cardWidth * 0.18; // 选中外移距离基于卡宽
                    final double progress = index / (numCards - 1);
                    final double theta = theta0 + (progress - 0.5) * sweepAngle + rotation;
                    final bool isRevealed = _revealed[index];
                    final double localRadius = radius + (isRevealed ? pickOffset : 0.0);
                    // 复用预计算的基础 cos/sin，通过角度加法得到当前 cos/sin
                    final double baseCos = _baseCos[index];
                    final double baseSin = _baseSin[index];
                    final double cosTheta = baseCos * cosR - baseSin * sinR;
                    final double sinTheta = baseSin * cosR + baseCos * sinR;
                    final double x = centerX + localRadius * cosTheta;
                    final double y = centerY + localRadius * sinTheta;
                    // 卡片矩形用于可视剔除（近似，旋转误差由 margin 吸收）
                    final Rect cardRect = Rect.fromLTWH(
                      x - cardWidth / 2,
                      y - cardHeight / 2,
                      cardWidth,
                      cardHeight,
                    );
                    if (!viewport.overlaps(cardRect)) {
                      // 跳过不可见卡片，减少布局与绘制开销
                      continue;
                    }

                    // 卡片主体
                    cardChildren.add(Positioned(
                      left: x - cardWidth / 2,
                      top: y - cardHeight / 2,
                      child: Transform.rotate(
                        angle: theta - math.pi / 2,
                        child: _ArcDeckCard(
                          face: widget.faces[index],
                          width: cardWidth,
                          height: cardHeight,
                          reversed: _reversed[index],
                          onTap: () {
                            // 单击即抽牌，并在抽牌成功后短暂播放预览动画
                            if (!isRevealed) {
                              final int nextOrder = _acceptedCount + 1;
                              final bool accepted = widget.onPick(
                                _PickEvent(
                                  face: widget.faces[index],
                                  reversed: _reversed[index],
                                  order: nextOrder,
                                  index: index,
                                ),
                              );
                              if (accepted) {
                                setState(() {
                                  _revealed[index] = true;
                                  _drawOrder[index] = nextOrder;
                                  _acceptedCount++;
                                });
                                HapticFeedback.selectionClick();
                              }
                            }
                          },
                          onLongPress: null,
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
                  // 更外层圆环：从卡片外沿向外扩展，半径更大（按比例）
                  final double ringMargin = cardHeight * 0.25; // 与卡片边缘的间距按卡高比例
                  final double labelWidth = cardWidth * 1.50; // 标签宽度按卡宽比例
                  final double labelHeight = cardHeight * 0.22; // 标签高度按卡高比例
                  final double outerR = localRadius + cardHeight / 2 + ringMargin; // 外层圆环半径
                  final double lx = centerX + outerR * (baseCos * cosR - baseSin * sinR);
                  final double ly = centerY + outerR * (baseSin * cosR + baseCos * sinR);
                  final Rect labelRect = Rect.fromLTWH(
                    lx - labelWidth / 2,
                    ly - labelHeight / 2,
                    labelWidth,
                    labelHeight,
                  );
                  if (!viewport.overlaps(labelRect)) {
                    // 标签不可见则跳过绘制
                    continue;
                  }

                  labelChildren.add(Positioned(
                    left: lx - labelWidth / 2,
                    top: ly - labelHeight / 2,
                    child: IgnorePointer(
                      child: Transform.rotate(
                        // 将文字方向反转（在切线方向上旋转 180°）
                        angle: theta + math.pi / 2,
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
                  // 预览动画已抽离为独立组件，不再在此构建
                ];
              }()
            );
            },
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
  final bool reversed;
  final bool highlight;
  final bool isRevealed;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _ArcDeckCard(
      {required this.face,
      required this.width,
      required this.height,
      required this.onTap,
      required this.reversed,
      this.onLongPress,
      this.highlight = false,
      this.isRevealed = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: isRevealed ? null : onTap, // 已翻开的牌不能再次点击
      onLongPress: isRevealed ? null : onLongPress,
      child: SizedBox(
        width: width,
        height: height,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border:                Border.all(color: theme.colorScheme.outline.withOpacity(0.35)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
              ),
              if (highlight)
                // 单层金色发光，保持风格同时降低性能开销
                BoxShadow(
                  color: Colors.amber.withOpacity(0.38),
                  blurRadius: 18,
                  spreadRadius: 4,
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
                Transform.rotate(
                  angle: reversed ? math.pi : 0,
                  child: DecoratedBox(
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
    const bool usePng = false; // 如需切换为 PNG，请置为 true 并添加资源
    if (usePng) {
      return Image.asset(
        'assets/images/tarot_back.png',
        fit: BoxFit.fill,
        filterQuality: FilterQuality.low,
      );
    }
    return SvgPicture.asset(
      'assets/images/tarot_back.svg',
      fit: BoxFit.fill,
      alignment: Alignment.center,
      allowDrawingOutsideViewBox: false,
      excludeFromSemantics: true,
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
  final String question;
  const _QuestionMock({required this.question});

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
      child: Text(question, style: theme.textTheme.bodyMedium),
    );
  }
}

// 分析（Mock 展示为要点列表）
class _AnalysisMock extends StatelessWidget {
  final List<String> lines;
  const _AnalysisMock({required this.lines});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
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
                onTap: () { HapticFeedback.selectionClick(); onSelect?.call(item); },
              ),
            ),
          );
        },
      ),
    );
  }
}

//（已移除吸附居中物理与模拟）

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
          final labels = SpreadRegistry.labelsForTitle(spread.title, spread.cards);
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
                  child: _CardSlotPreview(label: (i < labels.length && labels.isNotEmpty) ? labels[i] : '${i + 1}'),
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
  final positions = SpreadRegistry.positionsForTitle(spread.title, spread.cards);
  if (positions.isEmpty) return const [_Pos(0.5, 0.5)];
  return positions.map((p) => _Pos(p.dx, p.dy)).toList();
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