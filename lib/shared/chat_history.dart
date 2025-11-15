import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

const String lastThreadKey = 'chat_last_thread_v1';
const String threadsKey = 'chat_threads_v1';
String threadKey(String id) => 'chat_thread_${id}_v1';

class ChatEntry {
  final String threadId;
  final String role;
  final String text;
  final DateTime? time;
  final String? spreadTitle;
  ChatEntry({required this.threadId, required this.role, required this.text, required this.time, this.spreadTitle});
}

Future<List<ChatEntry>> loadAllMessages(SharedPreferences prefs) async {
  final List<ChatEntry> out = [];
  Map<String, DateTime?> threadUpdatedAt = {};
  try {
    final metaStr = prefs.getString(threadsKey);
    if (metaStr != null && metaStr.isNotEmpty) {
      final list = jsonDecode(metaStr);
      if (list is List) {
        for (final m in list) {
          if (m is Map && m['id'] is String) {
            final id = m['id'] as String;
            final ua = m['updatedAt'] as String?;
            threadUpdatedAt[id] = ua != null ? DateTime.tryParse(ua)?.toLocal() : null;
          }
        }
      }
    }
  } catch (_) {}
  final keys = prefs.getKeys();
  final List<String> threadKeys = [
    for (final k in keys)
      if (k.startsWith('chat_thread_') && k.endsWith('_v1')) k
  ];
  for (final k in threadKeys) {
    final s = prefs.getString(k);
    if (s == null || s.isEmpty) continue;
    try {
      final data = jsonDecode(s);
      if (data is List) {
        final id = k.substring('chat_thread_'.length, k.length - '_v1'.length);
        for (final j in data) {
          if (j is Map) {
            final ts = j['time'] as String?;
            final dt = ts != null ? DateTime.tryParse(ts)?.toLocal() : null;
            final fallback = threadUpdatedAt[id];
            out.add(ChatEntry(
              threadId: id,
              role: (j['role'] ?? 'assistant') as String,
              text: (j['text'] ?? '') as String,
              time: dt ?? fallback,
              spreadTitle: j['spreadTitle'] as String?,
            ));
          }
        }
      }
    } catch (_) {}
  }
  // 兜底：旧版全局历史
  if (out.isEmpty) {
    final legacy = prefs.getString('chat_history_v1');
    if (legacy != null && legacy.isNotEmpty) {
      try {
        final data = jsonDecode(legacy);
        if (data is List) {
          for (final j in data) {
            if (j is Map) {
              final ts = j['time'] as String?;
              final dt = ts != null ? DateTime.tryParse(ts)?.toLocal() : null;
              out.add(ChatEntry(
                threadId: 'default',
                role: (j['role'] ?? 'assistant') as String,
                text: (j['text'] ?? '') as String,
                time: dt,
                spreadTitle: j['spreadTitle'] as String?,
              ));
            }
          }
        }
      } catch (_) {}
    }
  }
  return out;
}

Future<Set<int>> daysWithMessagesForMonth(SharedPreferences prefs, DateTime month) async {
  final msgs = await loadAllMessages(prefs);
  final Set<int> days = {};
  for (final m in msgs) {
    final t = m.time;
    if (t == null) continue;
    if (t.year == month.year && t.month == month.month) {
      days.add(t.day);
    }
  }
  return days;
}
