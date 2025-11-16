import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loggedIn = false;
  String? _uid;
  String _front = '占位';
  String _back = '占位';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final uid = prefs.getString('profile_user_id');
    final front = prefs.getString('card_face_front_variant') ?? '占位';
    final back = prefs.getString('card_face_back_variant') ?? '占位';
    setState(() {
      _loggedIn = (token != null && token.isNotEmpty) || (uid != null && uid!.isNotEmpty);
      _uid = uid;
      _front = front;
      _back = back;
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('profile_user_id');
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1A29),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.25)),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF2A2436),
                    border: Border.all(color: Colors.white24),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.person, color: Colors.white70),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_loggedIn ? '已登录' : '未登录', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(_uid == null ? '用户ID：无' : '用户ID：${_uid}', style: theme.textTheme.labelSmall?.copyWith(color: Colors.white70)),
                    ],
                  ),
                ),
                if (_loggedIn)
                  TextButton(onPressed: _logout, child: const Text('退出登录')),
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
            child: ListTile(
              title: const Text('登录 / 注册'),
              subtitle: Text(_loggedIn ? '已登录' : '未登录'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/account/login'),
            ),
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1A29),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.25)),
            ),
            child: ListTile(
              title: const Text('数据与隐私'),
              subtitle: const Text('导出/导入数据、清除历史'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/account/data'),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1A29),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.25)),
            ),
            child: ListTile(
              title: const Text('牌面更换'),
              subtitle: Text('当前：$_front'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/card-face/front'),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1A29),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.25)),
            ),
            child: ListTile(
              title: const Text('牌背更换'),
              subtitle: Text('当前：$_back'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/card-face/back'),
            ),
          ),
        ],
      ),
    );
  }
}
