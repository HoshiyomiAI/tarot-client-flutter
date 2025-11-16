import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountSecurityScreen extends StatefulWidget {
  const AccountSecurityScreen({super.key});

  @override
  State<AccountSecurityScreen> createState() => _AccountSecurityScreenState();
}

class _AccountSecurityScreenState extends State<AccountSecurityScreen> {
  bool _twoFA = false;
  DateTime? _pwdChangedAt;
  final TextEditingController _pwd = TextEditingController();
  final TextEditingController _pwd2 = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _twoFA = prefs.getBool('account_2fa_enabled') ?? false;
      final ts = prefs.getString('account_pwd_last_changed_at');
      _pwdChangedAt = ts == null ? null : DateTime.tryParse(ts);
    });
  }

  Future<void> _save2FA(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('account_2fa_enabled', v);
    await _load();
  }

  Future<void> _changePwd() async {
    final a = _pwd.text.trim();
    final b = _pwd2.text.trim();
    if (a.isEmpty || b.isEmpty || a != b) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入一致的新密码')));
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('account_password_hint', 'updated');
    await prefs.setString('account_pwd_last_changed_at', DateTime.now().toIso8601String());
    _pwd.clear();
    _pwd2.clear();
    await _load();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已更新密码')));
  }

  Future<void> _revokeSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已注销当前会话')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('账号安全')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _Box(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('双重验证'),
                Switch(value: _twoFA, onChanged: (v) => _save2FA(v)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Box(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('修改密码', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                TextField(controller: _pwd, decoration: const InputDecoration(hintText: '新密码'), obscureText: true),
                const SizedBox(height: 8),
                TextField(controller: _pwd2, decoration: const InputDecoration(hintText: '重复新密码'), obscureText: true),
                const SizedBox(height: 10),
                SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _changePwd, child: const Text('更新密码'))),
                const SizedBox(height: 6),
                Text(_pwdChangedAt == null ? '上次修改：无' : '上次修改：${_pwdChangedAt!.toLocal()}', style: theme.textTheme.labelSmall?.copyWith(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Box(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('注销当前会话'),
                ElevatedButton(onPressed: _revokeSession, child: const Text('注销')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Box extends StatelessWidget {
  final Widget child;
  const _Box({required this.child});

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
      child: child,
    );
  }
}

