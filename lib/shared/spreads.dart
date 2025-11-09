import 'dart:math' as math;

class RelPos {
  final double dx;
  final double dy;
  const RelPos(this.dx, this.dy);
}

class SpreadSpec {
  final String title;
  final String desc;
  final int cards;
  final List<RelPos> positions;
  final List<String> labels;
  const SpreadSpec(this.title, this.desc, this.cards, this.positions, {this.labels = const []});
}

List<RelPos> _rowPositions(int n) {
  final List<RelPos> res = [];
  final int perRow = n <= 5 ? n : 5;
  final int rows = (n / perRow).ceil();
  for (int r = 0; r < rows; r++) {
    final int start = r * perRow;
    final int end = (start + perRow).clamp(0, n);
    final int count = end - start;
    for (int i = 0; i < count; i++) {
      final double x = 0.1 + (0.8 * (count == 1 ? 0.5 : i / (count - 1)));
      final double y = rows == 1 ? 0.5 : (0.35 + r * 0.3);
      res.add(RelPos(x, y));
    }
  }
  return res;
}

List<RelPos> ringPositions(int n, {double cx = 0.5, double cy = 0.5, double rx = 0.35, double ry = 0.30, double startAngle = -math.pi / 2}) {
  return List<RelPos>.generate(n, (i) {
    final double theta = startAngle + (2 * math.pi * i / n);
    return RelPos(cx + rx * math.cos(theta), cy + ry * math.sin(theta));
  });
}

List<RelPos> gridPositions(int cols, int rows, {double left = 0.14, double right = 0.86, double top = 0.22, double bottom = 0.78}) {
  final List<RelPos> res = [];
  final List<double> xs = List<double>.generate(cols, (i) => left + (right - left) * (cols == 1 ? 0.5 : i / (cols - 1)));
  final List<double> ys = List<double>.generate(rows, (i) => top + (bottom - top) * (rows == 1 ? 0.5 : i / (rows - 1)));
  for (int r = 0; r < rows; r++) {
    for (int c = 0; c < cols; c++) {
      res.add(RelPos(xs[c], ys[r]));
    }
  }
  return res;
}

List<RelPos> verticalPositions(int n, {double x = 0.5, double startY = 0.18, double step = 0.10}) {
  return List<RelPos>.generate(n, (i) => RelPos(x, startY + i * step));
}

class SpreadRegistry {
  static final List<SpreadSpec> spreads = [
    SpreadSpec('每日一张', '今日能量', 1, [RelPos(0.50, 0.50)], labels: ['今日']),
    SpreadSpec('圣三角', '过去-现在-未来（三角）', 3, [RelPos(0.25, 0.70), RelPos(0.50, 0.30), RelPos(0.75, 0.70)], labels: ['过去','现在','未来']),
    SpreadSpec('三张牌', '过去-现在-未来', 3, [RelPos(0.15, 0.50), RelPos(0.50, 0.50), RelPos(0.85, 0.50)], labels: ['过去','现在','未来']),
    SpreadSpec('五张牌', '现状-挑战-建议-外力-结果', 5, [RelPos(0.10, 0.50), RelPos(0.30, 0.50), RelPos(0.50, 0.50), RelPos(0.70, 0.50), RelPos(0.90, 0.50)], labels: ['现状','挑战','建议','外力','结果']),
    SpreadSpec('五角星', '现状-挑战-资源-行动-结果', 5, [RelPos(0.50, 0.20), RelPos(0.30, 0.38), RelPos(0.38, 0.70), RelPos(0.62, 0.70), RelPos(0.70, 0.38)], labels: ['现状','挑战','资源','行动','结果']),
    SpreadSpec('关系五点', '你-TA-现状-阻碍-建议', 5, [RelPos(0.50, 0.30), RelPos(0.30, 0.50), RelPos(0.50, 0.50), RelPos(0.70, 0.50), RelPos(0.50, 0.70)], labels: ['你','TA','现状','阻碍','建议']),
    SpreadSpec('关系六点', '你-TA-现状-阻碍-建议-结果', 6, [RelPos(0.20, 0.35), RelPos(0.50, 0.35), RelPos(0.80, 0.35), RelPos(0.20, 0.65), RelPos(0.50, 0.65), RelPos(0.80, 0.65)], labels: ['你','TA','现状','阻碍','建议','结果']),
    SpreadSpec('七点马蹄', '行动-阻碍-资源-关系-转折-建议-结果', 7, [RelPos(0.15, 0.65), RelPos(0.25, 0.55), RelPos(0.35, 0.45), RelPos(0.50, 0.40), RelPos(0.65, 0.45), RelPos(0.75, 0.55), RelPos(0.85, 0.65)], labels: ['行动','阻碍','资源','关系','转折','建议','结果']),
    SpreadSpec('七脉轮', '根-腹-胃-心-喉-眉-顶', 7, verticalPositions(7), labels: ['根','腹','胃','心','喉','眉','顶']),
    SpreadSpec('事业四象限', '目标-优势-劣势-行动', 4, [RelPos(0.35, 0.35), RelPos(0.65, 0.35), RelPos(0.35, 0.65), RelPos(0.65, 0.65)], labels: ['目标','优势','劣势','行动']),
    SpreadSpec('决策两选一', '选项A-选项B-对比-结论', 4, [RelPos(0.35, 0.35), RelPos(0.65, 0.35), RelPos(0.35, 0.65), RelPos(0.65, 0.65)], labels: ['选项A','选项B','对比','结论']),
    SpreadSpec('月度洞察', '上旬-中旬-下旬-整体建议', 4, [RelPos(0.35, 0.35), RelPos(0.65, 0.35), RelPos(0.35, 0.65), RelPos(0.65, 0.65)], labels: ['上旬','中旬','下旬','整体建议']),
    SpreadSpec('九宫格', '综合九项维度观测', 9, [RelPos(0.20, 0.25), RelPos(0.50, 0.25), RelPos(0.80, 0.25), RelPos(0.20, 0.50), RelPos(0.50, 0.50), RelPos(0.80, 0.50), RelPos(0.20, 0.75), RelPos(0.50, 0.75), RelPos(0.80, 0.75)]),
    SpreadSpec('金字塔八点', '基础-现状-阻碍-资源-机会-行动-外力-结果', 8, [RelPos(0.50, 0.20), RelPos(0.35, 0.40), RelPos(0.65, 0.40), RelPos(0.25, 0.60), RelPos(0.50, 0.60), RelPos(0.75, 0.60), RelPos(0.35, 0.80), RelPos(0.65, 0.80)], labels: ['基础','现状','阻碍','资源','机会','行动','外力','结果']),
    SpreadSpec('凯尔特十字', '经典综合解析', 10, [RelPos(0.35, 0.50), RelPos(0.35, 0.50), RelPos(0.35, 0.70), RelPos(0.20, 0.50), RelPos(0.35, 0.30), RelPos(0.50, 0.50), RelPos(0.80, 0.75), RelPos(0.80, 0.60), RelPos(0.80, 0.45), RelPos(0.80, 0.30)], labels: ['现状','挑战','根源','过去','目标','近期','自我态度','外部环境','希望恐惧','结果']),
    SpreadSpec('十二宫', '十二领域环阵', 12, ringPositions(12, rx: 0.38, ry: 0.30)),
    SpreadSpec('年度十二月', '月份洞察 3x4', 12, gridPositions(4, 3), labels: ['一月','二月','三月','四月','五月','六月','七月','八月','九月','十月','十一月','十二月']),
  ];

  static List<RelPos> positionsForTitle(String? title, int count) {
    if (title != null && title.isNotEmpty) {
      // 宽松匹配：包含关键字即可
      final spec = spreads.firstWhere(
        (s) => title.contains(s.title) && s.cards == count,
        orElse: () => spreads.firstWhere((s) => s.cards == count, orElse: () => SpreadSpec('自选牌阵', '', count, const [])),
      );
      if (spec.positions.isNotEmpty) return spec.positions;
    }
    // 按张数匹配
    final byCount = spreads.where((s) => s.cards == count).toList();
    if (byCount.isNotEmpty && byCount.first.positions.isNotEmpty) {
      return byCount.first.positions;
    }
    // 兜底：水平排列并自动换行
    return _rowPositions(count);
  }

  static List<String> labelsForTitle(String? title, int count) {
    if (title != null && title.isNotEmpty) {
      final spec = spreads.firstWhere(
        (s) => title.contains(s.title) && s.cards == count,
        orElse: () => spreads.firstWhere((s) => s.cards == count, orElse: () => SpreadSpec('自选牌阵', '', count, const [])),
      );
      if (spec.labels.isNotEmpty) return spec.labels;
    }
    final byCount = spreads.where((s) => s.cards == count).toList();
    if (byCount.isNotEmpty && byCount.first.labels.isNotEmpty) {
      return byCount.first.labels;
    }
    return const [];
  }

  static String inferTitleForCount(int n) {
    switch (n) {
      case 1:
        return '每日一张';
      case 3:
        return '三张牌';
      case 4:
        return '四象限';
      case 5:
        return '五张牌';
      case 6:
        return '关系六点';
      case 7:
        return '七点马蹄';
      case 8:
        return '金字塔八点';
      case 9:
        return '九宫格';
      case 10:
        return '凯尔特十字';
      case 12:
        return '十二宫';
      default:
        return '自选牌阵';
    }
  }
}
