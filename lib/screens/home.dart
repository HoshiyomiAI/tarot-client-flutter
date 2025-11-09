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
          SliverToBoxAdapter(child: const SizedBox(height: 12)),
          SliverToBoxAdapter(child: _DailyFortuneCard(onOpenDraw: () { HapticFeedback.selectionClick(); DrawModal.show(context); })),
          SliverToBoxAdapter(child: const SizedBox(height: 8)),
          SliverToBoxAdapter(child: _SectionTitle(title: '占卜仪式', trailing: TextButton(onPressed: () => context.push('/detail'), child: const Text('查看全部')))),
          SliverToBoxAdapter(child: const SizedBox(height: 8)),
          SliverToBoxAdapter(child: _RitualGrid(onSelect: _startRitual)),
          SliverToBoxAdapter(child: const SizedBox(height: 12)),
          SliverToBoxAdapter(child: _SectionTitle(title: '塔罗学习', trailing: TextButton(onPressed: () => context.push('/detail'), child: const Text('更多课程')))),
          SliverToBoxAdapter(child: const SizedBox(height: 8)),
          SliverToBoxAdapter(child: _LearningCard()),
          SliverToBoxAdapter(child: const SizedBox(height: 24)),
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

class _DailyFortuneCard extends StatelessWidget {
  final VoidCallback onOpenDraw;
  const _DailyFortuneCard({required this.onOpenDraw});
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
        child: Row(
          children: [
            SizedBox(
              width: 48,
              height: 78,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SvgPicture.asset('assets/images/tarot_back.svg', fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('今日运势', style: theme.textTheme.titleSmall),
                      const Spacer(),
                      Text('11月1日', style: theme.textTheme.labelSmall),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('命运之轮', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('今日是转变的好时机，新的机会正在向你招手，勇敢迎接变化。',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Row(
                    children: const [
                      _Metric(label: '爱情', value: 0.35, color: Color(0xFFE67FA4)),
                      SizedBox(width: 10),
                      _Metric(label: '事业', value: 0.65, color: Color(0xFF82A2E6)),
                      SizedBox(width: 10),
                      _Metric(label: '财运', value: 0.45, color: Color(0xFFF1C27D)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(icon: const Icon(Icons.style), onPressed: onOpenDraw),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final double value; // 0..1
  final Color color;
  const _Metric({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(Icons.favorite, size: 12, color: color), const SizedBox(width: 4), Text(label, style: theme.textTheme.labelSmall)]),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(value: value, minHeight: 4, color: color, backgroundColor: color.withOpacity(0.25)),
          ),
        ],
      ),
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
      child: GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 3.2,
        children: [
          _RitualTile(
            icon: Icons.favorite,
            title: '爱情占卜',
            subtitle: '探测情感状态与发展，解读亲密关系',
            onTap: () => onSelect?.call('爱情占卜', '探测情感状态与发展，解读亲密关系'),
          ),
          _RitualTile(
            icon: Icons.work,
            title: '事业占卜',
            subtitle: '衡量工作机遇与挑战，指引职业发展',
            onTap: () => onSelect?.call('事业占卜', '衡量工作机遇与挑战，指引职业发展'),
          ),
          _RitualTile(
            icon: Icons.savings,
            title: '财富占卜',
            subtitle: '探测财务机会与风险，提升稳健增长',
            onTap: () => onSelect?.call('财富占卜', '探测财务机会与风险，提升稳健增长'),
          ),
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

class _RitualTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  const _RitualTile({required this.icon, required this.title, required this.subtitle, this.onTap});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () { HapticFeedback.selectionClick(); onTap?.call(); },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1A29),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.25)),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: const Color(0xFF2A2436), borderRadius: BorderRadius.circular(999)),
              child: Icon(icon, color: const Color(0xFFFFD57A), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: theme.textTheme.labelSmall?.copyWith(color: Colors.white70)),
                ],
              ),
            ),
          ],
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
