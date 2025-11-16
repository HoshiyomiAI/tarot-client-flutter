import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import '../shared/chat_history.dart' as chat_store;

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

            _CalendarPanel(),

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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.of(context).pop();
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2436).withOpacity(0.7),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: const Icon(Icons.keyboard_arrow_up, size: 20, color: Colors.white70),
      ),
    );
  }
}

class _CalendarPanel extends StatefulWidget {
  @override
  State<_CalendarPanel> createState() => _CalendarPanelState();
}

class _CalendarPanelState extends State<_CalendarPanel> {
  DateTime _focused = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selected = DateTime.now();
  final List<_DayRecord> _records = [];
  bool _loggedIn = false;
  final Set<int> _historyDays = <int>{};
  int _switchDir = 0;

  @override
  void initState() {
    super.initState();
    _loadForSelected();
    _refreshLoginAndMonthHistory();
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  int _daysInMonth(DateTime month) {
    final startNext = DateTime(month.year, month.month + 1, 1);
    final lastCurrent = startNext.subtract(const Duration(days: 1));
    return lastCurrent.day;
  }

  List<DateTime> _visibleDays(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final firstWeekday = first.weekday; // Mon=1..Sun=7
    final leading = firstWeekday - 1;
    final days = _daysInMonth(month);
    final total = leading + days;
    final trailing = (total % 7 == 0) ? 0 : (7 - total % 7);
    final count = total + trailing;
    final start = first.subtract(Duration(days: leading));
    return List.generate(count, (i) => start.add(Duration(days: i)));
  }

  void _prevMonth() {
    setState(() {
      _focused = DateTime(_focused.year, _focused.month - 1);
      _selected = DateTime(_focused.year, _focused.month, 1);
    });
    _loadForSelected();
    _refreshLoginAndMonthHistory();
  }

  void _nextMonth() {
    setState(() {
      _focused = DateTime(_focused.year, _focused.month + 1);
      _selected = DateTime(_focused.year, _focused.month, 1);
    });
    _loadForSelected();
    _refreshLoginAndMonthHistory();
  }

  void _prevDay() {
    final d = _selected.subtract(const Duration(days: 1));
    setState(() {
      _switchDir = -1;
      _selected = d;
      _focused = DateTime(d.year, d.month);
    });
    _loadForSelected();
    _refreshLoginAndMonthHistory();
  }

  void _nextDay() {
    final d = _selected.add(const Duration(days: 1));
    setState(() {
      _switchDir = 1;
      _selected = d;
      _focused = DateTime(d.year, d.month);
    });
    _loadForSelected();
    _refreshLoginAndMonthHistory();
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final dx = details.velocity.pixelsPerSecond.dx;
    if (dx < -150) {
      _nextDay();
    } else if (dx > 150) {
      _prevDay();
    }
  }

  String _weekdayLabel(int i) {
    const labels = ['周一','周二','周三','周四','周五','周六','周日'];
    return labels[i];
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    const Color accent = Color(0xFFFFD57A);
    final days = _visibleDays(_focused);
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
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: _onHorizontalDragEnd,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 48,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: _prevMonth,
                          icon: const Icon(Icons.chevron_left, color: Colors.white70),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${_focused.year}年', style: theme.textTheme.labelSmall?.copyWith(color: Colors.white70)),
                            Text('${_focused.month}月', style: theme.textTheme.titleLarge?.copyWith(color: accent, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        IconButton(
                          onPressed: _nextMonth,
                          icon: const Icon(Icons.chevron_right, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 24,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (i) => Expanded(
                        child: Center(
                          child: Text(_weekdayLabel(i), style: theme.textTheme.labelSmall?.copyWith(color: Colors.white54)),
                        ),
                      )),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 48 * 6 + 8 * 5, // 6 行，每行 48 高，间距 8
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1,
                      ),
                      itemCount: days.length,
                      itemBuilder: (context, index) {
                        final d = days[index];
                        final inMonth = d.month == _focused.month && d.year == _focused.year;
                        final isSelected = _sameDay(d, _selected);
                        final bg = isSelected ? accent : Colors.transparent;
                        final fg = isSelected ? const Color(0xFF2A2436) : (inMonth ? Colors.white70 : Colors.white24);
                        return InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            setState(() {
                              _selected = d;
                              if (!inMonth) {
                                _focused = DateTime(d.year, d.month);
                              }
                            });
                            _loadForSelected();
                            _refreshLoginAndMonthHistory();
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Text('${d.day}', style: theme.textTheme.bodyMedium?.copyWith(color: fg, fontWeight: FontWeight.w600)),
                                ),
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 6,
                                  child: _buildDayMarker(d, isSelected: isSelected),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('${_selected.month}月${_selected.day}日', style: theme.textTheme.titleMedium?.copyWith(color: Colors.white)),
                  const SizedBox(height: 6),
                  Text('当天历史记录', style: theme.textTheme.labelSmall?.copyWith(color: Colors.white60)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      transitionBuilder: (child, animation) {
                        final bool isIncoming = child.key == ValueKey<String>(_selected.toIso8601String());
                        final double dir = _switchDir > 0 ? 1.0 : -1.0;
                        final Offset begin = isIncoming ? Offset(dir, 0) : Offset(-dir, 0);
                        final Animation<double> fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
                        final Animation<Offset> slide = animation.drive(
                          Tween<Offset>(begin: begin, end: Offset.zero).chain(CurveTween(curve: Curves.easeOut)),
                        );
                        return FadeTransition(
                          opacity: fade,
                          child: SlideTransition(position: slide, child: child),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey<String>(_selected.toIso8601String()),
                        child: _records.isEmpty
                            ? Center(
                                child: Text('暂无记录', style: theme.textTheme.labelSmall?.copyWith(color: Colors.white38)),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: _records.length,
                                itemBuilder: (context, index) {
                                  final r = _records[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Material(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      child: InkWell(
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          Navigator.of(context).pop();
                                          GoRouter.of(context).go('/chat?t=${Uri.encodeComponent(r.threadId)}');
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        splashColor: Colors.white.withOpacity(0.06),
                                        highlightColor: Colors.white.withOpacity(0.04),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1E1A29),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: theme.colorScheme.outline.withOpacity(0.25)),
                                          ),
                                          padding: const EdgeInsets.all(12),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(r.title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                                                    const SizedBox(height: 4),
                                                    Text(r.preview, style: theme.textTheme.labelSmall?.copyWith(color: Colors.white70)),
                                                  ],
                                                ),
                                              ),
                                              Text(_fmtTime(r.time), style: theme.textTheme.labelSmall?.copyWith(color: Colors.white38)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ),
                    ],
                  ),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 16,
                child: _BottomGuideIcon(),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Future<void> _refreshLoginAndMonthHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final uid = prefs.getString('profile_user_id');
      final logged = (token != null && token.isNotEmpty) || (uid != null && uid.isNotEmpty);

      final daysWith = await chat_store.daysWithMessagesForMonth(prefs, _focused);
      if (mounted) {
        setState(() {
          _loggedIn = logged;
          _historyDays
            ..clear()
            ..addAll(daysWith);
        });
      }
    } catch (_) {}
  }

  Widget _buildDayMarker(DateTime d, {required bool isSelected}) {
    final inMonth = d.month == _focused.month && d.year == _focused.year;
    final bool hasHistory = inMonth && _historyDays.contains(d.day);
    if (hasHistory) {
      final Color c = isSelected ? Colors.black87 : const Color(0xFFFFD57A);
      return SvgPicture.asset(
        'assets/images/tarot_marker.svg',
        width: 16,
        height: 12,
        colorFilter: ColorFilter.mode(c, BlendMode.srcIn),
      );
    }
    if (!_loggedIn) {
      final Color c = isSelected ? Colors.black87 : Colors.white60;
      return SvgPicture.asset(
        'assets/images/mk_locked.svg',
        width: 14,
        height: 14,
        colorFilter: ColorFilter.mode(c, BlendMode.srcIn),
      );
    }
    final Color c = isSelected ? Colors.black54 : Colors.white38;
    return SvgPicture.asset(
      'assets/images/mk_empty.svg',
      width: 12,
      height: 12,
      colorFilter: ColorFilter.mode(c, BlendMode.srcIn),
    );
  }

  Future<void> _loadForSelected() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entries = await chat_store.loadAllMessages(prefs);
      final Map<String, _DayRecord> latestByThread = {};
      for (final e in entries) {
        final time = e.time;
        if (time != null && _sameDay(time, _selected)) {
          final prev = latestByThread[e.threadId];
          if (prev == null || time.isAfter(prev.time)) {
            latestByThread[e.threadId] = _DayRecord(
              threadId: e.threadId,
              role: e.role,
              time: time,
              title: (e.spreadTitle ?? '对话'),
              preview: e.text.isNotEmpty ? e.text : '无文本',
            );
          }
        }
      }
      final List<_DayRecord> list = latestByThread.values.toList();
      list.sort((a, b) => b.time.compareTo(a.time));
      if (mounted) {
        setState(() {
          _records
            ..clear()
            ..addAll(list);
        });
      }
    } catch (_) {}
  }

  String _fmtTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _DayRecord {
  final String threadId;
  final String role;
  final DateTime time;
  final String title;
  final String preview;
  _DayRecord({required this.threadId, required this.role, required this.time, required this.title, required this.preview});
}
