import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryItem {
  final String id;
  final String title;
  final String? lastText;
  final DateTime updatedAt;
  const _HistoryItem({required this.id, required this.title, this.lastText, required this.updatedAt});
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const String _threadsKey = 'chat_threads_v1';
  static const String _lastThreadKey = 'chat_last_thread_v1';
  List<_HistoryItem> _items = [];
  bool _loading = true;
  String? _currentId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final s = prefs.getString(_threadsKey);
      final current = prefs.getString(_lastThreadKey);
      List<_HistoryItem> items = [];
      if (s != null && s.isNotEmpty) {
        final list = jsonDecode(s);
        if (list is List) {
          for (final e in list) {
            if (e is Map) {
              final id = (e['id'] ?? 'default') as String;
              final title = (e['title'] ?? '对话') as String;
              final lastText = e['lastText'] as String?;
              final t = DateTime.tryParse((e['updatedAt'] ?? '') as String) ?? DateTime.now();
              items.add(_HistoryItem(id: id, title: title, lastText: lastText, updatedAt: t));
            }
          }
        }
      }
      items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      setState(() {
        _items = items;
        _loading = false;
        _currentId = current;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('历史记录'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '新对话',
            onPressed: () {
              HapticFeedback.selectionClick();
              final id = _newThreadId();
              context.go('/chat?t=${Uri.encodeComponent(id)}');
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.selectionClick();
          final id = _newThreadId();
          context.go('/chat?t=${Uri.encodeComponent(id)}');
        },
        icon: const Icon(Icons.add),
        label: const Text('新对话'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Text('暂无历史对话', style: textTheme.bodyMedium),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final bool isCurrent = item.id == _currentId;
                    const Color accent = Color(0xFFFFD57A);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            context.go('/chat?t=${Uri.encodeComponent(item.id)}');
                          },
                          borderRadius: BorderRadius.circular(12),
                          splashColor: Colors.white.withOpacity(0.06),
                          highlightColor: Colors.white.withOpacity(0.04),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1A29),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isCurrent ? accent : theme.colorScheme.outline.withOpacity(0.25)),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isCurrent ? accent.withOpacity(0.18) : const Color(0xFF2A2436),
                                    border: Border.all(color: isCurrent ? accent : Colors.white24),
                                  ),
                                  child: Icon(Icons.chat_bubble_outline, size: 18, color: isCurrent ? accent : Colors.white70),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: isCurrent ? Colors.white : null),
                                      ),
                                      if (item.lastText != null && item.lastText!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          item.lastText!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: textTheme.labelSmall?.copyWith(color: isCurrent ? Colors.white70 : Colors.white70),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isCurrent)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: accent,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text('当前', style: textTheme.labelSmall?.copyWith(color: const Color(0xFF2A2436), fontWeight: FontWeight.w700)),
                                      ),
                                    if (isCurrent) const SizedBox(width: 8),
                                    Text(
                                      _formatTime(item.updatedAt),
                                      style: textTheme.labelSmall?.copyWith(color: Colors.white38),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    if (t.year == now.year && t.month == now.month && t.day == now.day) {
      return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }
    return '${t.month}/${t.day}';
  }

  String _newThreadId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rnd = math.Random().nextInt(1000000);
    return 't${now}_$rnd';
  }
}
