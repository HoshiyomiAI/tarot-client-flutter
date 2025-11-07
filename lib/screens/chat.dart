import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/draw_modal/draw_modal.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatMessage {
  final String role; // 'user' | 'assistant'
  final String text;
  final DateTime time;
  final List<_TarotCard>? draw; // 抽牌结果（可选）
  final String? spreadTitle; // 牌阵标题（可选，用于排列）
  _ChatMessage({required this.role, required this.text, DateTime? time, this.draw, this.spreadTitle})
      : time = time ?? DateTime.now();
}

class _TarotCard {
  final String name;
  final bool reversed; // true=逆位
  const _TarotCard(this.name, this.reversed);
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<_ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    // 移除角色预置文案，不进行任何预填充
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _sendText() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    _appendMessage(_ChatMessage(role: 'user', text: text));
    _handleCommand(text);
  }

  void _appendMessage(_ChatMessage m) {
    setState(() => _messages.add(m));
    // 延迟滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _openDrawModal() async {
    // 打开抽卡弹窗，并在返回后插入结果到聊天
    final res = await DrawModal.show(context);
    if (res != null && res.cards.isNotEmpty) {
      final cards = res.cards.map((r) => _TarotCard(r.name, r.reversed)).toList();
      final summary = cards
          .asMap()
          .entries
          .map((e) => '${e.key + 1}.${e.value.name}${e.value.reversed ? '(逆位)' : '(正位)'}')
          .join('  ');
      _appendMessage(_ChatMessage(
        role: 'assistant',
        text: '抽牌结果：\n$summary',
        draw: cards,
        spreadTitle: res.spreadTitle,
      ));
    }
  }

  void _handleCommand(String text) {
    // 支持 “/抽卡 N” 命令；默认 N=3
    final RegExp cmd = RegExp(r"^\s*\/抽卡(?:\s+(\d+))?\s*$");
    final match = cmd.firstMatch(text);
    if (match != null) {
      final n = int.tryParse(match.group(1) ?? '') ?? 3;
      final cards = _randomDraw(n);
      final summary = cards
          .asMap()
          .entries
          .map((e) => '${e.key + 1}.${e.value.name}${e.value.reversed ? '(逆位)' : '(正位)'}')
          .join('  ');
      _appendMessage(_ChatMessage(
        role: 'assistant',
        text: '抽牌结果：\n$summary',
        draw: cards,
        spreadTitle: _inferSpreadTitle(cards.length),
      ));
    }
  }

  List<_TarotCard> _randomDraw(int n) {
    final names = _tarotNames();
    final rnd = math.Random();
    final Set<int> picked = {};
    final int k = n.clamp(1, math.min(5, names.length));
    while (picked.length < k) {
      picked.add(rnd.nextInt(names.length));
    }
    return picked
        .map((i) => _TarotCard(names[i], rnd.nextBool()))
        .toList(growable: false);
  }

  List<String> _tarotNames() {
    const majors = [
      '愚者','魔术师','女祭司','皇后','皇帝','教皇','恋人','战车','力量','隐者','命运之轮','正义','倒吊人','死神','节制','恶魔','高塔','星星','月亮','太阳','审判','世界'
    ];
    const suits = ['权杖','圣杯','宝剑','星币'];
    const ranks = ['一','二','三','四','五','六','七','八','九','十','侍者','骑士','皇后','国王'];
    final minors = [for (final s in suits) for (final r in ranks) '$s$r'];
    return [...majors, ...minors];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    return Column(
      children: [
        // 头部卡片（中性标题 + 抽卡入口）
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text('聊天', style: textTheme.titleMedium),
              ),
              TextButton.icon(
                onPressed: _openDrawModal,
                icon: const Icon(Icons.style, size: 18),
                label: const Text('抽卡'),
              ),
            ],
          ),
        ),

        // 消息列表
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final m = _messages[index];
              final isUser = m.role == 'user';
              final bubbleColor = isUser
                  ? theme.colorScheme.primary.withOpacity(0.85)
                  : const Color(0xFF2A2436);
              final align = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: align,
                  children: [
                    Container(
                      constraints: const BoxConstraints(maxWidth: 520),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.text,
                            style: textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              height: 1.35,
                            ),
                          ),
                          if (m.draw != null) ...[
                            const SizedBox(height: 10),
                            _CardSpreadView(cards: m.draw!, spreadTitle: m.spreadTitle),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Quick actions / 建议（已移除“抽卡三张”）

        // 输入栏
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    decoration: InputDecoration(
                      hintText: '消息',
                      filled: true,
                      fillColor: const Color(0xFF2A2436),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendText(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _openDrawModal,
                  icon: const Icon(Icons.style),
                  tooltip: '抽卡',
                ),
                const SizedBox(width: 4),
                ElevatedButton(onPressed: _sendText, child: const Text('发送')),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CardSpreadView extends StatelessWidget {
  final List<_TarotCard> cards;
  final String? spreadTitle;
  const _CardSpreadView({required this.cards, this.spreadTitle});

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
          final positions = _positionsForTitle(spreadTitle, cards.length);
          final int n = cards.length;
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
          final double slotHeight = slotWidth / 0.7;
          final int len = math.min(positions.length, cards.length);
          // 计算行数以确定固定高度，避免父布局提供无限高度导致 Stack 断言失败
          final Set<int> rowLevels = {
            for (int i = 0; i < len; i++) (positions[i].dy * 10).round(),
          };
          final int rows = math.max(1, rowLevels.length);
          final double areaHeight = slotHeight * rows + 16.0 * (rows + 1);
          return SizedBox(
            height: areaHeight,
            width: double.infinity,
            child: Stack(
              children: [
                for (int i = 0; i < len; i++)
                  Positioned(
                    left: (positions[i].dx * constraints.maxWidth) - slotWidth / 2,
                    top: (positions[i].dy * areaHeight) - slotHeight / 2,
                    width: slotWidth,
                    height: slotHeight,
                    child: _MiniCard(reversed: cards[i].reversed, width: slotWidth, height: slotHeight),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final bool reversed;
  final double? width;
  final double? height;
  const _MiniCard({required this.reversed, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    final borderColor = Colors.white.withOpacity(0.18);
    final shadow = Colors.black.withOpacity(0.22);
    return SizedBox(
      width: width ?? 84,
      height: height ?? 132,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(color: shadow, blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Transform.rotate(
            angle: reversed ? math.pi : 0,
            child: SvgPicture.asset(
              'assets/images/tarot_back.svg',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}

class _RelPos {
  final double dx;
  final double dy;
  const _RelPos(this.dx, this.dy);
}

List<_RelPos> _positionsForTitle(String? title, int n) {
  final t = title ?? '';
  if (t.contains('三') && n == 3) {
    return const [
      _RelPos(0.15, 0.5),
      _RelPos(0.5, 0.5),
      _RelPos(0.85, 0.5),
    ];
  }
  if (t.contains('五') && n == 5) {
    return const [
      _RelPos(0.1, 0.5),
      _RelPos(0.3, 0.5),
      _RelPos(0.5, 0.5),
      _RelPos(0.7, 0.5),
      _RelPos(0.9, 0.5),
    ];
  }
  if (t.contains('凯尔特') && n == 10) {
    return const [
      _RelPos(0.35, 0.50),
      _RelPos(0.35, 0.50),
      _RelPos(0.35, 0.70),
      _RelPos(0.20, 0.50),
      _RelPos(0.35, 0.30),
      _RelPos(0.50, 0.50),
      _RelPos(0.80, 0.75),
      _RelPos(0.80, 0.60),
      _RelPos(0.80, 0.45),
      _RelPos(0.80, 0.30),
    ];
  }
  if (t.contains('马蹄') && n == 7) {
    return const [
      _RelPos(0.15, 0.65),
      _RelPos(0.25, 0.55),
      _RelPos(0.35, 0.45),
      _RelPos(0.50, 0.40),
      _RelPos(0.65, 0.45),
      _RelPos(0.75, 0.55),
      _RelPos(0.85, 0.65),
    ];
  }
  if ((t.contains('关系') || n == 6) && n == 6) {
    return const [
      _RelPos(0.20, 0.35),
      _RelPos(0.50, 0.35),
      _RelPos(0.80, 0.35),
      _RelPos(0.20, 0.65),
      _RelPos(0.50, 0.65),
      _RelPos(0.80, 0.65),
    ];
  }
  if ((t.contains('四象限') || t.contains('两选一') || t.contains('月度')) && n == 4) {
    return const [
      _RelPos(0.35, 0.35),
      _RelPos(0.65, 0.35),
      _RelPos(0.35, 0.65),
      _RelPos(0.65, 0.65),
    ];
  }
  if (t.contains('九宫') && n == 9) {
    return const [
      _RelPos(0.20, 0.25),
      _RelPos(0.50, 0.25),
      _RelPos(0.80, 0.25),
      _RelPos(0.20, 0.50),
      _RelPos(0.50, 0.50),
      _RelPos(0.80, 0.50),
      _RelPos(0.20, 0.75),
      _RelPos(0.50, 0.75),
      _RelPos(0.80, 0.75),
    ];
  }
  if (t.contains('金字塔') && n == 8) {
    return const [
      _RelPos(0.50, 0.20),
      _RelPos(0.35, 0.40),
      _RelPos(0.65, 0.40),
      _RelPos(0.25, 0.60),
      _RelPos(0.50, 0.60),
      _RelPos(0.75, 0.60),
      _RelPos(0.35, 0.80),
      _RelPos(0.65, 0.80),
    ];
  }
  // 默认：水平排列 n 张；超过 5 自动换行
  final List<_RelPos> res = [];
  final int perRow = n <= 5 ? n : 5;
  final int rows = (n / perRow).ceil();
  for (int r = 0; r < rows; r++) {
    final int start = r * perRow;
    final int end = (start + perRow).clamp(0, n);
    final int count = end - start;
    for (int i = 0; i < count; i++) {
      final double x = 0.1 + (0.8 * (count == 1 ? 0.5 : i / (count - 1)));
      final double y = rows == 1 ? 0.5 : (0.35 + r * 0.3);
      res.add(_RelPos(x, y));
    }
  }
  return res;
}

String _inferSpreadTitle(int n) {
  switch (n) {
    case 3:
      return '三张牌';
    case 5:
      return '五张牌';
    case 4:
      return '四象限';
    case 6:
      return '关系六点';
    case 7:
      return '七点马蹄';
    case 8:
      return '金字塔八点';
    case 9:
      return '九宫格';
    case 10:
      return '凯尔特十字';
    default:
      return '自选牌阵';
  }
}
