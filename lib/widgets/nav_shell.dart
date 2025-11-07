import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavShell extends StatelessWidget {
  final Widget child;
  const NavShell({super.key, required this.child});

  int _indexForLocation(String location) {
    if (location.startsWith('/chat')) return 0; // 左侧 对话
    if (location.startsWith('/profile')) return 2; // 右侧 我的
    return 1; // 中间 主页
  }

  void _goForIndex(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/chat');
        break;
      case 1:
        context.go('/home');
        break;
      case 2:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    final currentIndex = _indexForLocation(loc);
    return Scaffold(
      // 移除整个标题栏，仅在首页保留右上角“打开日历”引导入口
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: child),
            if (currentIndex == 1)
              Positioned(
                top: 10,
                right: 12,
                child: _CalendarHint(),
              ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: currentIndex,
        onTap: (i) => _goForIndex(context, i),
      ),
    );
  }
}

class _CalendarHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => GoRouter.of(context).push('/calendar'),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF2A2436).withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 6)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.calendar_month, color: Colors.white, size: 18),
              SizedBox(width: 6),
              Text('打开日历', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  static const Color bg = Color(0xFF1A1724);
  static const Color gold = Color(0xFFFFD57A);
  static const Color grey = Color(0xFF8A809E);

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).padding.bottom;
    const double baseHeight = 96; // 降低底部导航高度，保持固定
    return Container(
      decoration: const BoxDecoration(color: bg),
      height: baseHeight + bottomInset,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _NavItem(
              label: '对话',
              icon: Icons.chat_bubble,
              selected: currentIndex == 0,
              isCenter: false,
              onTap: () => onTap(0),
            ),
            _NavItem(
              label: '主页',
              icon: Icons.home,
              selected: currentIndex == 1,
              isCenter: true,
              onTap: () => onTap(1),
            ),
            _NavItem(
              label: '我的',
              icon: Icons.person,
              selected: currentIndex == 2,
              isCenter: false,
              onTap: () => onTap(2),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool isCenter;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.isCenter,
    required this.onTap,
  });

  static const Color gold = Color(0xFFFFD57A);
  static const Color grey = Color(0xFF8A809E);

  @override
  Widget build(BuildContext context) {
    final double size = isCenter ? (selected ? 62 : 54) : 40;
    final Color fg = selected ? gold : grey;
    final List<BoxShadow> glow = selected
        ? [
            BoxShadow(color: gold.withOpacity(0.55), blurRadius: 28, spreadRadius: 3),
          ]
        : [
            BoxShadow(color: gold.withOpacity(0.16), blurRadius: 10, spreadRadius: 0.8),
          ];

    final Gradient? grad = (selected && isCenter)
        ? const LinearGradient(
            colors: [Color(0xFFFFD57A), Color(0xFFFFB75C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : null;

    final BoxDecoration deco = BoxDecoration(
      shape: BoxShape.circle,
      color: grad == null ? null : null,
      gradient: grad,
      border: selected && isCenter
          ? null
          : Border.all(color: fg.withOpacity(0.4), width: 1.2),
      boxShadow: glow,
    );

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 58, // 减少高度以避免溢出
            width: isCenter ? 62 : 44,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: size,
                height: size,
                decoration: deco,
                alignment: Alignment.center,
                child: Icon(icon, color: (selected && isCenter) ? Colors.black87 : fg),
              ),
            ),
          ),
          const SizedBox(height: 4), // 减少间距
          Text(label, style: TextStyle(color: fg, fontSize: 12)),
        ],
      ),
    );
  }
}
