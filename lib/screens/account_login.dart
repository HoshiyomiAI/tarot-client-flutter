import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountLoginScreen extends StatefulWidget {
  const AccountLoginScreen({super.key});

  @override
  State<AccountLoginScreen> createState() => _AccountLoginScreenState();
}

class _AccountLoginScreenState extends State<AccountLoginScreen> {
  final TextEditingController _uid = TextEditingController();
  final TextEditingController _token = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _uid.text = prefs.getString('profile_user_id') ?? '';
      _token.text = prefs.getString('auth_token') ?? '';
      _loading = false;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_user_id', _uid.text.trim());
    await prefs.setString('auth_token', _token.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存登录信息')));
  }


  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('profile_user_id');
    await prefs.remove('auth_token');
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('登录 / 注册')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _FieldCard(
                  title: '用户ID',
                  child: TextField(
                    controller: _uid,
                    decoration: const InputDecoration(hintText: '输入用户ID'),
                  ),
                ),
                const SizedBox(height: 12),
                _FieldCard(
                  title: '登录令牌',
                  child: TextField(
                    controller: _token,
                    decoration: const InputDecoration(hintText: '输入令牌'),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(onPressed: _save, child: const Text('保存')),
                ),
                const SizedBox(height: 8),
                TextButton(onPressed: _logout, child: const Text('退出登录')),
              ],
            ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _FieldCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1A29),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.25)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
