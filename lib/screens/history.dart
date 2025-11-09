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
  List<_HistoryItem> _items = [];
  bool _loading = true;

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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Text('暂无历史对话', style: textTheme.bodyMedium),
                )
              : ListView.separated(
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return ListTile(
                      title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: item.lastText == null
                          ? null
                          : Text(item.lastText!, maxLines: 1, overflow: TextOverflow.ellipsis),
                      leading: const Icon(Icons.chat_bubble_outline),
                      trailing: Text(_formatTime(item.updatedAt), style: textTheme.bodySmall),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        context.go('/chat?t=${Uri.encodeComponent(item.id)}');
                      },
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
