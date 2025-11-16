import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class AccountDataScreen extends StatefulWidget {
  const AccountDataScreen({super.key});

  @override
  State<AccountDataScreen> createState() => _AccountDataScreenState();
}

class _AccountDataScreenState extends State<AccountDataScreen> {
  String _exportText = '';
  final TextEditingController _importText = TextEditingController();
  bool _includeToken = false;

  Future<void> _doExport() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final Map<String, dynamic> data = {};
    for (final k in keys) {
      if (k == 'auth_token' && !_includeToken) continue;
      data[k] = prefs.getString(k);
    }
    setState(() {
      _exportText = const JsonEncoder.withIndent('  ').convert(data);
    });
  }

  Future<void> _copyExport() async {
    await Clipboard.setData(ClipboardData(text: _exportText));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制导出数据')));
  }

  Future<void> _doImport() async {
    final s = _importText.text.trim();
    if (s.isEmpty) return;
    Map<String, dynamic>? data;
    try {
      data = jsonDecode(s) as Map<String, dynamic>;
    } catch (_) {}
    if (data == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('导入内容格式错误')));
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    for (final e in data.entries) {
      final k = e.key;
      final v = e.value;
      if (v is String) {
        await prefs.setString(k, v);
      } else if (v == null) {
        await prefs.remove(k);
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('导入完成')));
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().toList();
    for (final k in keys) {
      if (k.startsWith('chat_thread_') || k == 'chat_threads_v1' || k == 'chat_last_thread_v1') {
        await prefs.remove(k);
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已清除聊天历史')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('数据与隐私')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1A29),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.25)),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('导出数据'),
                    Row(children: [
                      const Text('包含令牌'),
                      Switch(value: _includeToken, onChanged: (v) => setState(() => _includeToken = v)),
                    ])
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(onPressed: _doExport, child: const Text('生成导出')),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2436),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Text(_exportText.isEmpty ? '无导出内容' : _exportText, style: theme.textTheme.bodySmall),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(onPressed: _exportText.isEmpty ? null : _copyExport, child: const Text('复制导出内容')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1A29),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.25)),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('导入数据'),
                const SizedBox(height: 8),
                TextField(
                  controller: _importText,
                  maxLines: 6,
                  decoration: const InputDecoration(hintText: '粘贴导出的JSON内容'),
                ),
                const SizedBox(height: 8),
                SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _doImport, child: const Text('导入'))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1A29),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.25)),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('清除聊天历史'),
                ElevatedButton(onPressed: _clearHistory, child: const Text('清除')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

