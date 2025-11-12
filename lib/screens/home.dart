import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;
import 'package:go_router/go_router.dart';
import '../widgets/draw_modal/draw_modal.dart';
import 'chat.dart';

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

  String _newThreadId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rnd = math.Random().nextInt(1000000);
    return 't${now}_$rnd';
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
    final theme = Theme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _HeroBanner()),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          const SliverToBoxAdapter(child: _DailyFortuneCard()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          const SliverToBoxAdapter(child: _SectionTitle(title: '占卜仪式')),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          SliverToBoxAdapter(child: _RitualGrid(onSelect: _startRitual)),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Future<void> _startRitual(String title, String subtitle) async {
    // 根据仪式类型构造情景与推荐牌阵
    DrawScenario scenario;
    switch (title) {
      case '爱情占卜':
        scenario = DrawScenario(
          title: '关于爱情的近期走向与建议？',
          desc: subtitle,
          analysis: const [
            '确认双方沟通频率与互动质量',
            '明确未来三个月的关系发展趋势',
            '识别可能的阻碍并给出建议',
          ],
          preferredSpreadTitle: '关系五点',
        );
        break;
      case '事业占卜':
        scenario = DrawScenario(
          title: '当前事业的机会、挑战与行动建议？',
          desc: subtitle,
          analysis: const [
            '盘点当下目标与资源',
            '识别主要挑战与外部影响',
            '给出可执行的行动建议',
          ],
          preferredSpreadTitle: '事业四象限',
        );
        break;
      case '财富占卜':
        scenario = DrawScenario(
          title: '近期财务的机会与风险如何把握？',
          desc: subtitle,
          analysis: const [
            '观察现金流与支出结构',
            '识别潜在机会与外部支持',
            '制定稳健增长的行动方案',
          ],
          preferredSpreadTitle: '五角星',
        );
        break;
      case '命运占卜':
      default:
        scenario = DrawScenario(
          title: '当下人生进程的关键转折与指引？',
          desc: subtitle,
          analysis: const [
            '梳理当前状态与近期变化',
            '识别内外部影响因素',
            '给出阶段性的方向与建议',
          ],
          preferredSpreadTitle: '圣三角',
        );
        break;
    }

    final res = await DrawModal.show(context, scenario: scenario);
    if (!mounted) return;
    if (res != null) {
      final init = ChatInit(
        question: scenario.title,
        analysis: scenario.analysis,
        scenarioDesc: scenario.desc,
        spreadResult: res,
      );
      final tid = _newThreadId();
      context.push('/chat?t=${Uri.encodeComponent(tid)}', extra: init);
    }
  }
}

class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Container(
              height: 160,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF3C2F4D), Color(0xFF1D1828)],
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.15), Colors.black.withOpacity(0.35)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              top: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('今日塔罗指引', style: theme.textTheme.labelSmall?.copyWith(color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text('神秘的旅程', style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: Row(
                children: [
                  const CircleAvatar(radius: 16, backgroundColor: Color(0xFFFFD57A)),
                  const SizedBox(width: 8),
                  Text('星语者', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const _SectionTitle({required this.title, this.trailing});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _DailyFortuneCard extends StatefulWidget {
  const _DailyFortuneCard();

  @override
  State<_DailyFortuneCard> createState() => _DailyFortuneCardState();
}

class _DailyFortuneCardState extends State<_DailyFortuneCard> {
  bool _isFlipped = false;
  String _cardName = '命运之轮'; // Default card name
  String _cardInterpretation = '• 今日能量流转加速，变化带来新机\n• 主动拥抱新节奏，顺势而为\n• 用迭代心态推进关键事项'; // 更丰富的默认 mock 解读
  DrawSpreadResult? _lastResult; // 保存完整抽卡结果（含正逆位）

  // 依据名称生成与抽卡第二页一致的颜色（与 draw_modal 的 _buildMockDeckFaces 同步）
  Color _colorForCardName(String name) {
    const List<String> majors = [
      '愚者', '魔术师', '女祭司', '皇后', '皇帝', '教皇', '恋人', '战车', '力量', '隐者',
      '命运之轮', '正义', '倒吊人', '死神', '节制', '恶魔', '高塔', '星星', '月亮', '太阳', '审判', '世界'
    ];
    const List<String> suits = ['权杖', '圣杯', '宝剑', '星币'];
    const List<String> ranks = [
      '一', '二', '三', '四', '五', '六', '七', '八', '九', '十', '侍者', '骑士', '皇后', '国王'
    ];
    final List<String> minors = [
      for (final suit in suits)
        for (final rank in ranks) '$suit$rank'
    ];
    final List<String> names = [...majors, ...minors];
    final int totalCards = names.length;
    final int idx = names.indexOf(name);
    if (idx < 0) {
      return Colors.black.withOpacity(0.2);
    }
    return HSLColor.fromAHSL(1.0, (idx * 360.0 / totalCards) % 360, 0.5, 0.6).toColor();
  }

  // 根据牌名与正逆位生成更贴近主题的 mock 解读
  String _buildMockInterpretation(String name, bool reversed) {
    const majors = [
      '愚者', '魔术师', '女祭司', '皇后', '皇帝', '教皇', '恋人', '战车', '力量', '隐者',
      '命运之轮', '正义', '倒吊人', '死神', '节制', '恶魔', '高塔', '星星', '月亮', '太阳', '审判', '世界'
    ];
    final isMajor = majors.contains(name);

    String bullets(List<String> lines) => lines.map((l) => '• $l').join('\n');

    if (isMajor) {
      switch (name) {
        case '命运之轮':
          return reversed
              ? bullets([
                  '外界变动暂时不可控，先稳定节奏',
                  '接受阶段性停滞，观察合适的窗口',
                  '以小步试探代替大幅转向'
                ])
              : bullets([
                  '今日能量流转加速，变化带来新机',
                  '主动拥抱新节奏，顺势而为',
                  '用迭代心态推进关键事项'
                ]);
        case '太阳':
          return reversed
              ? bullets([
                  '乐观情绪易被外界打扰，回到内在稳定',
                  '避免过度暴露与承诺，先做扎实验证',
                  '以清晰边界守住个人节奏'
                ])
              : bullets([
                  '清晰与活力上升，信心驱动推进',
                  '主动表达与分享，获得外部支持',
                  '以简洁方案落地关键目标'
                ]);
        case '月亮':
          return reversed
              ? bullets([
                  '情绪波动减弱但仍需辨识真伪',
                  '用事实校准直觉，避免误判',
                  '建立信息来源的可靠性'
                ])
              : bullets([
                  '直觉敏锐，潜意识讯息活跃',
                  '暂缓仓促决定，先观察与记录',
                  '夜间适合梳理与反思'
                ]);
        case '星星':
          return reversed
              ? bullets([
                  '理想感受挫折，先修复自信',
                  '缩小目标范围，聚焦一件可完成的事',
                  '用持续的小步恢复秩序'
                ])
              : bullets([
                  '希望与指引清晰，愿景可见',
                  '允许灵感引路，制定轻量计划',
                  '持续与耐心带来正向反馈'
                ]);
        case '力量':
          return reversed
              ? bullets([
                  '意志感偏紧绷，试着柔性掌控',
                  '避免硬推进，借助支持系统',
                  '以呼吸与休息恢复内在力量'
                ])
              : bullets([
                  '内在力量稳固，自律带来进展',
                  '以温柔但坚定的方式沟通',
                  '将目标拆分为可控的节律'
                ]);
        case '恋人':
          return reversed
              ? bullets([
                  '关系与选择需要更清晰的边界',
                  '暂缓受情绪驱动的决定',
                  '以价值观校准下一步'
                ])
              : bullets([
                  '连接与合作适合推进',
                  '通过对话达成共识与互补',
                  '以长期愿景选择路径'
                ]);
        case '正义':
          return reversed
              ? bullets([
                  '信息与规则理解有偏差，先查漏补缺',
                  '避免草率判断，以证据说话',
                  '重新校准利弊与公平'
                ])
              : bullets([
                  '理性与秩序占优，适合做清晰决策',
                  '规范流程，减少模糊地带',
                  '以公平原则处理分配'
                ]);
        case '节制':
          return reversed
              ? bullets([
                  '节奏失衡，先调整输入与输出',
                  '减少多线并行，守住核心节律',
                  '以耐心恢复系统的协调'
                ])
              : bullets([
                  '平衡与调和显现，水到渠成',
                  '温和推进，避免过度',
                  '将资源合理配比到关键处'
                ]);
        case '高塔':
          return reversed
              ? bullets([
                  '小范围的结构性波动仍需重视',
                  '及时止损与加固，避免连锁反应',
                  '用事实清点风险点'
                ])
              : bullets([
                  '突发变化促使结构重构',
                  '快速评估影响面并重启方案',
                  '以最小可行架构恢复运行'
                ]);
        case '审判':
          return reversed
              ? bullets([
                  '阶段复盘尚未完成，先整合旧账',
                  '避免仓促跃迁，准备好再出发',
                  '以真实反馈修正方向'
                ])
              : bullets([
                  '召唤与更新来临，适合定调下一阶段',
                  '公开回顾与复盘，吸取经验',
                  '以崭新身份开展行动'
                ]);
        case '世界':
          return reversed
              ? bullets([
                  '收官环节仍需打磨与整合',
                  '补齐文档与交付标准',
                  '避免过早庆祝，确保闭环'
                ])
              : bullets([
                  '阶段圆满，成果可见',
                  '对外发布与共享价值',
                  '规划下一轮的扩展与演进'
                ]);
        default:
          return reversed
              ? bullets(['主题能量暂时受阻', '放慢决策，先理清优先级', '保持耐心与复盘'])
              : bullets(['主题能量清晰可感', '把握当下窗口，推进一件关键事', '保持节制与专注']);
      }
    }

    // 小阿尔克那：按花色给出主题，结合正逆位给建议
    String suit;
    if (name.startsWith('权杖')) {
      suit = '行动与驱动力';
    } else if (name.startsWith('圣杯')) {
      suit = '情感与连接';
    } else if (name.startsWith('宝剑')) {
      suit = '思维与沟通';
    } else if (name.startsWith('星币')) {
      suit = '资源与落实';
    } else {
      suit = '当下主题';
    }

    final List<String> lines = [];
    lines.add('$suit为主线，围绕当前情境展开');
    if (reversed) {
      lines.add('能量略显阻滞，放慢推进节奏');
      lines.add('先校准信息与优先级，再做决定');
    } else {
      lines.add('能量顺畅，适合小步快跑');
      lines.add('抓住关键节点完成一次具体推进');
    }
    return bullets(lines);
  }

  // 复刻抽卡第二页的卡片样式（颜色与文字），支持正逆位旋转
  Widget _buildFaceCardView(String name, bool reversed, {double width = 120}) {
    final theme = Theme.of(context);
    final double height = width / 0.62; // 与弹窗中的比例一致
    final border = Border.all(color: theme.colorScheme.outline.withOpacity(0.35));
    final Color bg = _colorForCardName(name);
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: border,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, spreadRadius: 1),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              clipBehavior: Clip.antiAliasWithSaveLayer,
              child: Transform.rotate(
                angle: reversed ? math.pi : 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: bg),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          for (final ch in name.split(''))
                            Text(
                              ch,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium?.copyWith(
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
                reversed ? '逆位' : '正位',
                style: theme.textTheme.labelSmall,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleTap() async {
    if (!_isFlipped) {
      final scenario = DrawScenario(
        title: '今日运势',
        desc: '抽取一张牌，获取今日的指引。',
        analysis: const [
          '检视今日的整体能量状态',
          '识别潜在的机遇与挑战',
          '获取积极度过今日的建议',
        ],
        preferredSpreadTitle: '每日一张',
      );

      final res = await DrawModal.show(context, scenario: scenario, initialStep: 1);

      if (res != null && res.cards.isNotEmpty) {
        final card = res.cards.first;
        setState(() {
          _lastResult = res;
          _cardName = card.name;
          _cardInterpretation = _buildMockInterpretation(card.name, card.reversed); // 使用更丰富的 mock 解读
          _isFlipped = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        height: 380,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1A29),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('今日运势', style: theme.textTheme.titleMedium),
            ),
            Expanded(
              child: AnimatedCrossFade(
                duration: const Duration(milliseconds: 500),
                crossFadeState: _isFlipped ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                firstChild: _buildCardBack(context),
                secondChild: _buildCardFront(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBack(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Transform.translate(
          offset: const Offset(0, -12), // 与抽卡后位置一致的上移
          child: SizedBox(
            width: 120,
            height: 196,
            child: SvgPicture.asset('assets/images/tarot_back.svg', fit: BoxFit.contain),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            '• 点击卡牌开始今日指引\n• 抽到后将展示正/逆位与解读',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
        ),
      ],
    );
  }

  Widget _buildCardFront(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Transform.translate(
          offset: const Offset(0, -12), // 稍微上移卡牌，给解读更多空间
          child: (_lastResult != null && _lastResult!.cards.isNotEmpty)
              ? _buildFaceCardView(_lastResult!.cards.first.name, _lastResult!.cards.first.reversed)
              : _buildFaceCardView(_cardName, false),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            _cardInterpretation,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
        ),
      ],
    );
  }
}

class _RitualGrid extends StatelessWidget {
  final void Function(String title, String subtitle)? onSelect;
  const _RitualGrid({this.onSelect});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          _RitualTile(
            icon: Icons.favorite,
            title: '爱情占卜',
            subtitle: '探测情感状态与发展，解读亲密关系',
            onTap: () => onSelect?.call('爱情占卜', '探测情感状态与发展，解读亲密关系'),
          ),
          const SizedBox(height: 12),
          _RitualTile(
            icon: Icons.work,
            title: '事业占卜',
            subtitle: '衡量工作机遇与挑战，指引职业发展',
            onTap: () => onSelect?.call('事业占卜', '衡量工作机遇与挑战，指引职业发展'),
          ),
          const SizedBox(height: 12),
          _RitualTile(
            icon: Icons.savings,
            title: '财富占卜',
            subtitle: '探测财务机会与风险，提升稳健增长',
            onTap: () => onSelect?.call('财富占卜', '探测财务机会与风险，提升稳健增长'),
          ),
          const SizedBox(height: 12),
          _RitualTile(
            icon: Icons.auto_stories,
            title: '学业占卜',
            subtitle: '分析学习状态与瓶颈，规划提升路径',
            onTap: () => onSelect?.call('学业占卜', '分析学习状态与瓶颈，规划提升路径'),
          ),
          const SizedBox(height: 12),
          _RitualTile(
            icon: Icons.health_and_safety,
            title: '健康占卜',
            subtitle: '洞察身心能量流动，提供调适建议',
            onTap: () => onSelect?.call('健康占卜', '洞察身心能量流动，提供调适建议'),
          ),
          const SizedBox(height: 12),
          _RitualTile(
            icon: Icons.people,
            title: '人际关系',
            subtitle: '解析社交互动模式，改善人际联结',
            onTap: () => onSelect?.call('人际关系', '解析社交互动模式，改善人际联结'),
          ),
          const SizedBox(height: 12),
          _RitualTile(
            icon: Icons.self_improvement,
            title: '个人成长',
            subtitle: '探索内在潜能与方向，实现自我超越',
            onTap: () => onSelect?.call('个人成长', '探索内在潜能与方向，实现自我超越'),
          ),
          const SizedBox(height: 12),
          _RitualTile(
            icon: Icons.auto_fix_high,
            title: '命运占卜',
            subtitle: '洞察人生方向与轨迹，解读命运转折',
            onTap: () => onSelect?.call('命运占卜', '洞察人生方向与轨迹，解读命运转折'),
          ),
        ],
      ),
    );
  }
}

class _RitualTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  const _RitualTile({required this.icon, required this.title, required this.subtitle, this.onTap});
  @override
  State<_RitualTile> createState() => _RitualTileState();
}

class _RitualTileState extends State<_RitualTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const Color accent = Color(0xFFFFD57A);
    final Color glowColor = accent.withOpacity(_pressed ? 0.28 : 0.14);
    return AnimatedScale(
      scale: _pressed ? 1.01 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1A29),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 12, spreadRadius: 0, offset: const Offset(0, 2)),
            BoxShadow(color: glowColor, blurRadius: 18, spreadRadius: 1),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onTap?.call();
            },
            onHighlightChanged: (v) => setState(() => _pressed = v),
            borderRadius: BorderRadius.circular(12),
            splashColor: accent.withOpacity(0.15),
            highlightColor: accent.withOpacity(0.10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF342B45), Color(0xFF2A2436)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(color: glowColor, blurRadius: 12, spreadRadius: 0),
                    ],
                  ),
                  child: Icon(widget.icon, color: accent, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(widget.subtitle, style: theme.textTheme.labelSmall?.copyWith(color: Colors.white70, letterSpacing: 0.2)),
                    ],
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

class _LearningCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1A29),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.25)),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('入门课程', style: theme.textTheme.labelSmall),
            const SizedBox(height: 4),
            Text('塔罗基础：22张大阿尔卡纳解读', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: const [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                    child: LinearProgressIndicator(value: 0.25, minHeight: 6),
                  ),
                ),
                SizedBox(width: 8),
                Text('3/12课'),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('继续学习'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
