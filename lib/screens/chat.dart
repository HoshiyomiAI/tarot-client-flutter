import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:flutter_svg/flutter_svg.dart';
import '../shared/spreads.dart';
import '../widgets/draw_modal/draw_modal.dart';

class ChatInit {
  final String? question;
  final List<String>? analysis;
  final String? scenarioDesc;
  final DrawSpreadResult? spreadResult;
  const ChatInit(
      {this.question, this.analysis, this.scenarioDesc, this.spreadResult});
}

class ChatScreen extends StatefulWidget {
  final ChatInit? init;
  const ChatScreen({super.key, this.init});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatMessage {
  final String role; // 'user' | 'assistant'
  final String text;
  final DateTime time;
  final List<_TarotCard>? draw; // 抽牌结果（可选）
  final String? spreadTitle; // 牌阵标题（可选，用于排列）
  _ChatMessage(
      {required this.role,
      required this.text,
      DateTime? time,
      this.draw,
      this.spreadTitle})
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
    // 若携带初始化数据：以新对话形式预填充情景与抽牌结果
    final init = widget.init;
    if (init != null) {
      // 用户提出的问题
      if (init.question != null && init.question!.trim().isNotEmpty) {
        _appendMessage(_ChatMessage(role: 'user', text: init.question!.trim()));
      }
      // 情景分析
      if (init.analysis != null && init.analysis!.isNotEmpty) {
        final lines = init.analysis!;
        final text = '情景分析：\n' + lines.map((e) => '• $e').join('\n');
        _appendMessage(_ChatMessage(role: 'assistant', text: text));
      }
      // 抽牌结果（包含牌阵标题与排列）
      final res = init.spreadResult;
      if (res != null && res.cards.isNotEmpty) {
        final cards =
            res.cards.map((r) => _TarotCard(r.name, r.reversed)).toList();
        final summary = cards
            .asMap()
            .entries
            .map((e) =>
                '${e.key + 1}.${e.value.name}${e.value.reversed ? '(逆位)' : '(正位)'}')
            .join('  ');
        _appendMessage(_ChatMessage(
          role: 'assistant',
          text: '抽牌结果（牌阵：${res.spreadTitle}，共${res.count}张）：\n$summary',
          draw: cards,
          spreadTitle: res.spreadTitle,
        ));
      }
    }
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
    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();
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
    HapticFeedback.selectionClick();
    final res = await DrawModal.show(context);
    if (res != null && res.cards.isNotEmpty) {
      final cards =
          res.cards.map((r) => _TarotCard(r.name, r.reversed)).toList();
      final summary = cards
          .asMap()
          .entries
          .map((e) =>
              '${e.key + 1}.${e.value.name}${e.value.reversed ? '(逆位)' : '(正位)'}')
          .join('  ');
      _appendMessage(_ChatMessage(
        role: 'assistant',
        text: '抽牌结果（牌阵：${res.spreadTitle}，共${res.count}张）：\n$summary',
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
          .map((e) =>
              '${e.key + 1}.${e.value.name}${e.value.reversed ? '(逆位)' : '(正位)'}')
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
    final int k = n.clamp(1, names.length);
    while (picked.length < k) {
      picked.add(rnd.nextInt(names.length));
    }
    return picked
        .map((i) => _TarotCard(names[i], rnd.nextBool()))
        .toList(growable: false);
  }

  List<String> _tarotNames() {
    const majors = [
      '愚者',
      '魔术师',
      '女祭司',
      '皇后',
      '皇帝',
      '教皇',
      '恋人',
      '战车',
      '力量',
      '隐者',
      '命运之轮',
      '正义',
      '倒吊人',
      '死神',
      '节制',
      '恶魔',
      '高塔',
      '星星',
      '月亮',
      '太阳',
      '审判',
      '世界'
    ];
    const suits = ['权杖', '圣杯', '宝剑', '星币'];
    const ranks = [
      '一',
      '二',
      '三',
      '四',
      '五',
      '六',
      '七',
      '八',
      '九',
      '十',
      '侍者',
      '骑士',
      '皇后',
      '国王'
    ];
    final minors = [
      for (final s in suits)
        for (final r in ranks) '$s$r'
    ];
    return [...majors, ...minors];
  }

  Color _colorForCardName(String name) {
    final names = _tarotNames();
    final total = names.length;
    int idx = names.indexOf(name);
    if (idx < 0) {
      // 回退：未匹配的名称按哈希分配颜色，保证稳定性
      idx = name.hashCode.abs() % total;
    }
    final h = (idx * 360.0 / total) % 360;
    return HSLColor.fromAHSL(1.0, h, 0.5, 0.6).toColor();
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
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final m = _messages[index];
              final isUser = m.role == 'user';
              final bubbleColor = isUser
                  ? theme.colorScheme.primary.withOpacity(0.85)
                  : const Color(0xFF2A2436);
              final align =
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: align,
                  children: [
                    InkWell(
                      onLongPress: () async {
                        await Clipboard.setData(ClipboardData(text: m.text));
                        HapticFeedback.selectionClick();
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('已复制消息')),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 520),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
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
                              _CardSpreadView(
                                  cards: m.draw!, spreadTitle: m.spreadTitle),
                            ],
                          ],
                        ),
                      ),
                    )
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
                        borderSide:
                            BorderSide(color: Colors.white.withOpacity(0.15)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
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
                    left: (positions[i].dx * constraints.maxWidth) -
                        slotWidth / 2,
                    top: (positions[i].dy * areaHeight) - slotHeight / 2,
                    width: slotWidth,
                    height: slotHeight,
                    child: _MiniCard(
                        name: cards[i].name,
                        reversed: cards[i].reversed,
                        width: slotWidth,
                        height: slotHeight),
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
  final String name;
  final bool reversed;
  final double? width;
  final double? height;
  const _MiniCard(
      {required this.name, required this.reversed, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = Colors.white.withOpacity(0.18);
    final shadow = Colors.black.withOpacity(0.22);
    final Color faceColor = _colorForCardName(name);
    return SizedBox(
      width: width ?? 84,
      height: height ?? 120,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(color: shadow, blurRadius: 6, offset: const Offset(0, 3)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: Transform.rotate(
            angle: reversed ? math.pi : 0,
            child: DecoratedBox(
              decoration: BoxDecoration(color: faceColor),
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
                          style: theme.textTheme.titleSmall?.copyWith(
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
    );
  }
}

// 根据牌名生成稳定的卡面颜色，规则与抽卡页一致
Color _colorForCardName(String name) {
  const majors = [
    '愚者',
    '魔术师',
    '女祭司',
    '皇后',
    '皇帝',
    '教皇',
    '恋人',
    '战车',
    '力量',
    '隐者',
    '命运之轮',
    '正义',
    '倒吊人',
    '死神',
    '节制',
    '恶魔',
    '高塔',
    '星星',
    '月亮',
    '太阳',
    '审判',
    '世界'
  ];
  const suits = ['权杖', '圣杯', '宝剑', '星币'];
  const ranks = [
    '一',
    '二',
    '三',
    '四',
    '五',
    '六',
    '七',
    '八',
    '九',
    '十',
    '侍者',
    '骑士',
    '皇后',
    '国王'
  ];
  final minors = [
    for (final s in suits)
      for (final r in ranks) '$s$r'
  ];
  final names = [...majors, ...minors];
  final total = names.length; // 78
  int idx = names.indexOf(name);
  if (idx < 0) {
    idx = name.hashCode.abs() % total; // 未匹配时回退到哈希索引
  }
  final h = (idx * 360.0 / total) % 360;
  return HSLColor.fromAHSL(1.0, h, 0.5, 0.6).toColor();
}

class _RelPos {
  final double dx;
  final double dy;
  const _RelPos(this.dx, this.dy);
}

List<_RelPos> _positionsForTitle(String? title, int n) {
  final positions = SpreadRegistry.positionsForTitle(title, n);
  return positions.map((p) => _RelPos(p.dx, p.dy)).toList();
}

String _inferSpreadTitle(int n) {
  return SpreadRegistry.inferTitleForCount(n);
}
