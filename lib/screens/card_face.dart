import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CardFaceScreen extends StatefulWidget {
  const CardFaceScreen({super.key});

  @override
  State<CardFaceScreen> createState() => _CardFaceScreenState();
}

class _CardFaceScreenState extends State<CardFaceScreen> {
  String _frontVariant = 'classic';
  String _backVariant = 'classic';
  bool _saving = false;
  final List<_Variant> _catalog = const [
    _Variant(id: 'classic', name: '经典书籍塔罗', desc: '经典塔罗氛围，色调沉稳，适合偏静谧的占卜体验。', frontA: Color(0xFF353245), frontB: Color(0xFF6E617F), backA: Color(0xFF2A2436), backB: Color(0xFF4B435C)),
    _Variant(id: 'midnight', name: '午夜塔罗', desc: '冷色夜幕风格，氛围感强烈，适合深度思考场景。', frontA: Color(0xFF0E1020), frontB: Color(0xFF1D2740), backA: Color(0xFF101320), backB: Color(0xFF22314E)),
    _Variant(id: 'emerald', name: '水晶塔罗', desc: '绿色系清晰风格，传递舒缓能量，适合疗愈主题。', frontA: Color(0xFF0F3B2E), frontB: Color(0xFF2F7A5F), backA: Color(0xFF134034), backB: Color(0xFF3A8C70)),
    _Variant(id: 'royal', name: '金色神秘塔罗', desc: '暖色质感风格，具有仪式感，适合正式场合与分享。', frontA: Color(0xFF3B2A1E), frontB: Color(0xFF8C5A2B), backA: Color(0xFF2E2016), backB: Color(0xFF7A4B24)),
    _Variant(id: 'minimal', name: '极简塔罗', desc: '灰黑极简风格，界面干净，强调信息与牌义。', frontA: Color(0xFF262626), frontB: Color(0xFF4A4A4A), backA: Color(0xFF1F1F1F), backB: Color(0xFF3A3A3A)),
    _Variant(id: 'sunset', name: '幻想插画塔罗', desc: '暖紫与橙光过渡，柔和且有层次，适合浪漫主题。', frontA: Color(0xFF4B2E4B), frontB: Color(0xFFB36F5B), backA: Color(0xFF3E2545), backB: Color(0xFFA85C4C)),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final f = prefs.getString('card_face_front_variant');
    final b = prefs.getString('card_face_back_variant');
    setState(() {
      _frontVariant = _hasVariant(f) ? f! : 'classic';
      _backVariant = _hasVariant(b) ? b! : 'classic';
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('card_face_front_variant', _frontVariant);
    await prefs.setString('card_face_back_variant', _backVariant);
    setState(() => _saving = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存牌面选择')));
  }

  bool _hasVariant(String? id) => id != null && _catalog.any((v) => v.id == id);

  Widget _section(String title, bool isFront) {
    final theme = Theme.of(context);
    final selected = isFront ? _frontVariant : _backVariant;
    const accent = Color(0xFFFFD57A);
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: theme.textTheme.titleSmall),
              Text('当前：${_catalog.firstWhere((v) => v.id == selected).name}', style: theme.textTheme.labelSmall?.copyWith(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final v in _catalog)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isFront) {
                        _frontVariant = v.id;
                      } else {
                        _backVariant = v.id;
                      }
                    });
                  },
                  child: Container(
                    width: 100,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AspectRatio(
                          aspectRatio: 3 / 4,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: LinearGradient(
                                colors: isFront ? [v.frontA, v.frontB] : [v.backA, v.backB],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(v.name, style: theme.textTheme.labelSmall?.copyWith(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(v.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelSmall),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('牌面更换')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _section('正面', true),
          const SizedBox(height: 12),
          _section('反面', false),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? '保存中...' : '保存'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Variant {
  final String id;
  final String name;
  final String desc;
  final Color frontA;
  final Color frontB;
  final Color backA;
  final Color backB;
  const _Variant({required this.id, required this.name, required this.desc, required this.frontA, required this.frontB, required this.backA, required this.backB});
}

class CardFaceFrontScreen extends StatefulWidget {
  const CardFaceFrontScreen({super.key});

  @override
  State<CardFaceFrontScreen> createState() => _CardFaceFrontScreenState();
}

class _CardFaceFrontScreenState extends State<CardFaceFrontScreen> {
  String _selected = 'classic';
  final List<_Variant> _catalog = const [
    _Variant(id: 'classic', name: '经典书籍塔罗', desc: '经典塔罗氛围，色调沉稳，适合偏静谧的占卜体验。', frontA: Color(0xFF353245), frontB: Color(0xFF6E617F), backA: Color(0xFF2A2436), backB: Color(0xFF4B435C)),
    _Variant(id: 'midnight', name: '午夜塔罗', desc: '冷色夜幕风格，氛围感强烈，适合深度思考场景。', frontA: Color(0xFF0E1020), frontB: Color(0xFF1D2740), backA: Color(0xFF101320), backB: Color(0xFF22314E)),
    _Variant(id: 'emerald', name: '水晶塔罗', desc: '绿色系清晰风格，传递舒缓能量，适合疗愈主题。', frontA: Color(0xFF0F3B2E), frontB: Color(0xFF2F7A5F), backA: Color(0xFF134034), backB: Color(0xFF3A8C70)),
    _Variant(id: 'royal', name: '金色神秘塔罗', desc: '暖色质感风格，具有仪式感，适合正式场合与分享。', frontA: Color(0xFF3B2A1E), frontB: Color(0xFF8C5A2B), backA: Color(0xFF2E2016), backB: Color(0xFF7A4B24)),
    _Variant(id: 'minimal', name: '极简塔罗', desc: '灰黑极简风格，界面干净，强调信息与牌义。', frontA: Color(0xFF262626), frontB: Color(0xFF4A4A4A), backA: Color(0xFF1F1F1F), backB: Color(0xFF3A3A3A)),
    _Variant(id: 'sunset', name: '幻想插画塔罗', desc: '暖紫与橙光过渡，柔和且有层次，适合浪漫主题。', frontA: Color(0xFF4B2E4B), frontB: Color(0xFFB36F5B), backA: Color(0xFF3E2545), backB: Color(0xFFA85C4C)),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString('card_face_front_variant');
    setState(() {
      _selected = _catalog.any((e) => e.id == v) ? v! : 'classic';
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('card_face_front_variant', _selected);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存牌面选择')));
  }

  Widget _variantRow(_Variant v) {
    final theme = Theme.of(context);
    const accent = Color(0xFFFFD57A);
    final bool isSelected = _selected == v.id;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => setState(() => _selected = v.id),
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.white.withOpacity(0.06),
        highlightColor: Colors.white.withOpacity(0.04),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1A29),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? accent : theme.colorScheme.outline.withOpacity(0.25)),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(v.name, style: theme.textTheme.titleSmall),
                  const SizedBox.shrink(),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 4,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    return AspectRatio(
                      aspectRatio: 3 / 4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [v.frontA, v.frontB],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text('${i + 1}', style: theme.textTheme.labelSmall?.copyWith(color: Colors.white)),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(v.desc, style: theme.textTheme.labelSmall?.copyWith(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('牌面更换'), actions: [
        IconButton(onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('选择喜欢的牌面风格，应用后影响所有卡牌展示。')));
        }, icon: const Icon(Icons.info_outline))
      ]),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('选择你喜欢的塔罗牌面风格，应用后将改变所有占卜中的卡牌展示效果。'),
          ),
          for (final v in _catalog) ...[
            _variantRow(v),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: _save, child: const Text('保存')),
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('自定义风格敬请期待')));
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1A29),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.25)),
                ),
                padding: const EdgeInsets.all(16),
                alignment: Alignment.centerLeft,
                child: Row(
                  children: const [
                    Icon(Icons.photo_library_outlined, color: Colors.white70),
                    SizedBox(width: 8),
                    Text('自定义牌面风格', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CardFaceBackScreen extends StatefulWidget {
  const CardFaceBackScreen({super.key});

  @override
  State<CardFaceBackScreen> createState() => _CardFaceBackScreenState();
}

class _CardFaceBackScreenState extends State<CardFaceBackScreen> {
  String _selected = 'classic';
  final List<_Variant> _catalog = const [
    _Variant(id: 'classic', name: '经典书籍塔罗', desc: '经典塔罗氛围，色调沉稳，适合偏静谧的占卜体验。', frontA: Color(0xFF353245), frontB: Color(0xFF6E617F), backA: Color(0xFF2A2436), backB: Color(0xFF4B435C)),
    _Variant(id: 'midnight', name: '午夜塔罗', desc: '冷色夜幕风格，氛围感强烈，适合深度思考场景。', frontA: Color(0xFF0E1020), frontB: Color(0xFF1D2740), backA: Color(0xFF101320), backB: Color(0xFF22314E)),
    _Variant(id: 'emerald', name: '水晶塔罗', desc: '绿色系清晰风格，传递舒缓能量，适合疗愈主题。', frontA: Color(0xFF0F3B2E), frontB: Color(0xFF2F7A5F), backA: Color(0xFF134034), backB: Color(0xFF3A8C70)),
    _Variant(id: 'royal', name: '金色神秘塔罗', desc: '暖色质感风格，具有仪式感，适合正式场合与分享。', frontA: Color(0xFF3B2A1E), frontB: Color(0xFF8C5A2B), backA: Color(0xFF2E2016), backB: Color(0xFF7A4B24)),
    _Variant(id: 'minimal', name: '极简塔罗', desc: '灰黑极简风格，界面干净，强调信息与牌义。', frontA: Color(0xFF262626), frontB: Color(0xFF4A4A4A), backA: Color(0xFF1F1F1F), backB: Color(0xFF3A3A3A)),
    _Variant(id: 'sunset', name: '幻想插画塔罗', desc: '暖紫与橙光过渡，柔和且有层次，适合浪漫主题。', frontA: Color(0xFF4B2E4B), frontB: Color(0xFFB36F5B), backA: Color(0xFF3E2545), backB: Color(0xFFA85C4C)),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString('card_face_back_variant');
    setState(() {
      _selected = _catalog.any((e) => e.id == v) ? v! : 'classic';
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('card_face_back_variant', _selected);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存牌背选择')));
  }

  Widget _variantRow(_Variant v) {
    final theme = Theme.of(context);
    const accent = Color(0xFFFFD57A);
    final bool isSelected = _selected == v.id;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => setState(() => _selected = v.id),
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.white.withOpacity(0.06),
        highlightColor: Colors.white.withOpacity(0.04),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1A29),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? accent : theme.colorScheme.outline.withOpacity(0.25)),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(v.name, style: theme.textTheme.titleSmall),
                  const SizedBox.shrink(),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 4,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    return AspectRatio(
                      aspectRatio: 3 / 4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [v.backA, v.backB],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text('${i + 1}', style: theme.textTheme.labelSmall?.copyWith(color: Colors.white)),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(v.desc, style: theme.textTheme.labelSmall?.copyWith(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('牌背更换'), actions: [
        IconButton(onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('选择喜欢的牌背风格，应用后影响所有卡牌背面展示。')));
        }, icon: const Icon(Icons.info_outline))
      ]),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('选择你喜欢的塔罗牌背风格，应用后将改变所有占卜中的卡牌背面展示效果。'),
          ),
          for (final v in _catalog) ...[
            _variantRow(v),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: _save, child: const Text('保存')),
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('自定义风格敬请期待')));
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1A29),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.25)),
                ),
                padding: const EdgeInsets.all(16),
                alignment: Alignment.centerLeft,
                child: Row(
                  children: const [
                    Icon(Icons.photo_library_outlined, color: Colors.white70),
                    SizedBox(width: 8),
                    Text('自定义牌背风格', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
