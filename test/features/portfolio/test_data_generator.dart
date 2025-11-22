import 'dart:math';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/fund_favorite/src/entities/fund_favorite.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/entities/portfolio_holding.dart';

/// 测试数据生成器
///
/// 为自选基金与持仓联动功能提供各种测试数据生成工具
class TestDataGenerator {
  static const String _tag = 'TestDataGenerator';

  /// 基金类型列表
  static const List<String> _fundTypes = [
    '股票型',
    '债券型',
    '混合型',
    '货币型',
    '指数型',
    'QDII',
    'FOF'
  ];

  /// 基金管理人列表
  static const List<String> _fundManagers = [
    '华夏基金管理有限公司',
    '易方达基金管理有限公司',
    '南方基金管理股份有限公司',
    '嘉实基金管理有限公司',
    '汇添富基金管理股份有限公司',
    '博时基金管理有限公司',
    '广发基金管理有限公司',
    '富国基金管理有限公司',
  ];

  /// 基金名称模板
  static const List<String> _fundNameTemplates = [
    '成长',
    '价值',
    '平衡',
    '稳健',
    '优选',
    '精选',
    '行业',
    '主题',
    '指数',
    '债券',
    '货币',
    'ETF',
    '联接',
  ];

  /// 生成单个自选基金
  static FundFavorite generateFavorite({
    String? fundCode,
    String? fundName,
    String? fundType,
    String? fundManager,
    double? currentNav,
    double? dailyChange,
    DateTime? addedAt,
    String? notes,
  }) {
    final code = fundCode ?? _generateRandomFundCode();
    final type = fundType ?? _fundTypes[_random.nextInt(_fundTypes.length)];
    final manager =
        fundManager ?? _fundManagers[_random.nextInt(_fundManagers.length)];
    final name = fundName ?? _generateRandomFundName(code, type);

    // 生成合理的净值数据
    final nav = currentNav ?? _generateRandomNav(type);
    final change = dailyChange ?? _generateRandomChange();
    final previousNav = nav / (1 + change / 100);

    return FundFavorite(
      fundCode: code,
      fundName: name,
      fundType: type,
      fundManager: manager,
      addedAt: addedAt ??
          DateTime.now().subtract(Duration(days: _random.nextInt(90) + 1)),
      updatedAt: DateTime.now(),
      currentNav: nav,
      dailyChange: change,
      previousNav: previousNav,
      notes: notes ?? _generateRandomNotes(),
    );
  }

  /// 生成指定数量的自选基金列表
  static List<FundFavorite> generateFavorites(
    int count, {
    bool useRealisticData = true,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    if (count <= 0) return [];

    final favorites = <FundFavorite>[];
    final usedCodes = <String>{};
    final now = DateTime.now();

    for (int i = 0; i < count; i++) {
      String code;
      do {
        code = _generateRandomFundCode();
      } while (usedCodes.contains(code));

      usedCodes.add(code);

      final addedAt = startDate != null && endDate != null
          ? _randomDateTime(startDate, endDate)
          : now.subtract(Duration(days: _random.nextInt(90) + 1));

      favorites.add(generateFavorite(
        fundCode: code,
        addedAt: addedAt,
      ));
    }

    return useRealisticData ? _applyRealisticMarketData(favorites) : favorites;
  }

  /// 生成单个持仓数据
  static PortfolioHolding generateHolding({
    String? fundCode,
    String? fundName,
    String? fundType,
    double? holdingAmount,
    double? costNav,
    double? currentNav,
    DateTime? holdingStartDate,
    bool? dividendReinvestment,
    HoldingStatus? status,
  }) {
    final code = fundCode ?? _generateRandomFundCode();
    final type = fundType ?? _fundTypes[_random.nextInt(_fundTypes.length)];
    final name = fundName ?? _generateRandomFundName(code, type);
    final amount = holdingAmount ?? _generateRandomAmount();
    final cost = costNav ?? _generateRandomNav(type);
    final current = currentNav ?? _generateRandomNav(type);
    final startDate = holdingStartDate ??
        DateTime.now().subtract(Duration(days: _random.nextInt(365) + 1));

    return PortfolioHolding(
      fundCode: code,
      fundName: name,
      fundType: type,
      holdingAmount: amount,
      costNav: cost,
      costValue: amount * cost,
      marketValue: amount * current,
      currentNav: current,
      accumulatedNav:
          current * (1 + _random.nextDouble() * 0.5), // 累计净值通常高于当前净值
      holdingStartDate: startDate,
      lastUpdatedDate: DateTime.now(),
      dividendReinvestment: dividendReinvestment ?? _random.nextBool(),
      status: status ?? HoldingStatus.active,
    );
  }

  /// 生成指定数量的持仓列表
  static List<PortfolioHolding> generateHoldings(
    int count, {
    bool useRealisticData = true,
    double totalValue = 100000.0, // 总投资金额
  }) {
    if (count <= 0) return [];

    final holdings = <PortfolioHolding>[];
    final usedCodes = <String>{};
    double remainingValue = totalValue;

    for (int i = 0; i < count; i++) {
      // 为最后一个持仓分配剩余金额
      final isLast = i == count - 1;
      final targetValue = isLast ? remainingValue : totalValue / count;

      String code;
      do {
        code = _generateRandomFundCode();
      } while (usedCodes.contains(code));

      usedCodes.add(code);

      final type = _fundTypes[_random.nextInt(_fundTypes.length)];
      final nav = _generateRandomNav(type);
      final amount = targetValue / nav;

      holdings.add(generateHolding(
        fundCode: code,
        fundType: type,
        holdingAmount: amount,
        costNav: nav,
        currentNav: nav,
      ));

      remainingValue -= targetValue;
    }

    return useRealisticData ? _applyRealisticHoldingData(holdings) : holdings;
  }

  /// 生成关联的自选基金和持仓数据
  static ({List<FundFavorite> favorites, List<PortfolioHolding> holdings})
      generateLinkedData({
    int favoriteCount = 10,
    int holdingCount = 5,
    double commonRatio = 0.6, // 共同基金的比例
  }) {
    final favorites = generateFavorites(favoriteCount);
    final commonCount = (holdingCount * commonRatio).round();

    // 从自选基金中选择共同基金
    final commonFavorites = favorites.take(commonCount).toList();

    // 生成包含共同基金的持仓
    final holdings = <PortfolioHolding>[];

    // 添加共同基金持仓
    for (final favorite in commonFavorites) {
      holdings.add(generateHolding(
        fundCode: favorite.fundCode,
        fundName: favorite.fundName,
        fundType: favorite.fundType,
        currentNav: favorite.currentNav,
      ));
    }

    // 添加额外的持仓
    final additionalHoldings = generateHoldings(holdingCount - commonCount);
    holdings.addAll(additionalHoldings);

    return (favorites: favorites, holdings: holdings);
  }

  /// 生成测试场景数据
  static TestScenarios generateScenarios() {
    return TestScenarios(
      // 场景1: 完全匹配
      perfectMatch: () {
        final favorites = generateFavorites(3);
        final holdings = favorites
            .map((f) => generateHolding(
                  fundCode: f.fundCode,
                  fundName: f.fundName,
                  fundType: f.fundType,
                  currentNav: f.currentNav,
                ))
            .toList();
        return (favorites: favorites, holdings: holdings);
      },

      // 场景2: 部分重叠
      partialOverlap: () {
        final favorites = generateFavorites(5);
        final holdings = <PortfolioHolding>[];

        // 添加2个共同的基金
        holdings.add(generateHolding(
          fundCode: favorites[0].fundCode,
          fundName: favorites[0].fundName,
          fundType: favorites[0].fundType,
        ));
        holdings.add(generateHolding(
          fundCode: favorites[1].fundCode,
          fundName: favorites[1].fundName,
          fundType: favorites[1].fundType,
        ));

        // 添加2个独立的持仓
        holdings.addAll(generateHoldings(2));

        return (favorites: favorites, holdings: holdings);
      },

      // 场景3: 数据不一致
      dataInconsistency: () {
        final favorites = generateFavorites(3);
        final holdings = favorites
            .map((f) => generateHolding(
                  fundCode: f.fundCode,
                  fundName: f.fundName,
                  fundType: f.fundType,
                  currentNav: f.currentNav! *
                      (1 + (_random.nextDouble() - 0.5) * 0.1), // 5%差异
                ))
            .toList();

        // 修改一个基金名称制造不一致
        if (holdings.isNotEmpty) {
          holdings[0] =
              holdings[0].copyWith(fundName: '${holdings[0].fundName}(旧)');
        }

        return (favorites: favorites, holdings: holdings);
      },

      // 场景4: 大量数据
      largeDataset: () {
        return generateLinkedData(
          favoriteCount: 50,
          holdingCount: 30,
          commonRatio: 0.7,
        );
      },

      // 场景5: 空数据
      emptyData: () {
        return (favorites: <FundFavorite>[], holdings: <PortfolioHolding>[]);
      },

      // 场景6: 单边数据
      oneSidedData: () {
        return (
          favorites: generateFavorites(5),
          holdings: <PortfolioHolding>[],
        );
      },
    );
  }

  /// 生成边界测试数据
  static BoundaryTestData generateBoundaryData() {
    return BoundaryTestData(
      // 空数据
      emptyFavorites: [],
      emptyHoldings: [],

      // 单个数据
      singleFavorite: [generateFavorite()],
      singleHolding: [generateHolding()],

      // 极值数据
      maximumFavorites: generateFavorites(100),
      maximumHoldings: generateHoldings(100),

      // 异常数据
      zeroNavFavorites:
          List.generate(5, (_) => generateFavorite(currentNav: 0.0)),
      negativeNavFavorites:
          List.generate(5, (_) => generateFavorite(currentNav: -1.0)),

      zeroAmountHoldings:
          List.generate(5, (_) => generateHolding(holdingAmount: 0.0)),
      negativeAmountHoldings:
          List.generate(5, (_) => generateHolding(holdingAmount: -100.0)),
    );
  }

  /// 生成性能测试数据
  static PerformanceTestData generatePerformanceData() {
    return PerformanceTestData(
      // 小数据集
      smallDataset: generateLinkedData(favoriteCount: 10, holdingCount: 5),

      // 中等数据集
      mediumDataset: generateLinkedData(favoriteCount: 50, holdingCount: 25),

      // 大数据集
      largeDataset: generateLinkedData(favoriteCount: 200, holdingCount: 100),

      // 超大数据集
      xlargeDataset: generateLinkedData(favoriteCount: 1000, holdingCount: 500),
    );
  }

  // 私有辅助方法

  static final _random = Random(DateTime.now().millisecondsSinceEpoch);

  static String _generateRandomFundCode() {
    // 生成6位数字基金代码
    return (_random.nextInt(900000) + 100000).toString();
  }

  static String _generateRandomFundName(String code, String type) {
    final adjective =
        _fundNameTemplates[_random.nextInt(_fundNameTemplates.length)];
    final template =
        _fundNameTemplates[_random.nextInt(_fundNameTemplates.length)];

    switch (type) {
      case '股票型':
        return '${_randomCompanyName()}$adjective股票';
      case '债券型':
        return '${_randomCompanyName()}$template债券';
      case '混合型':
        return '${_randomCompanyName()}$adjective混合';
      case '货币型':
        return '${_randomCompanyName()}$template货币';
      case '指数型':
        return '${_getRandomIndexName()}$adjective指数';
      case 'QDII':
        return '${_randomCompanyName()}$template QDII';
      case 'FOF':
        return '${_randomCompanyName()}$template FOF';
      default:
        return '${_randomCompanyName()}$adjective基金';
    }
  }

  static String _randomCompanyName() {
    final companies = [
      '华夏',
      '易方达',
      '南方',
      '嘉实',
      '汇添富',
      '博时',
      '广发',
      '富国',
      '招商',
      '工银'
    ];
    return companies[_random.nextInt(companies.length)];
  }

  static String _getRandomIndexName() {
    final indices = [
      '沪深300',
      '上证50',
      '中证500',
      '创业板指',
      '科创50',
      '恒生指数',
      '纳斯达克100'
    ];
    return indices[_random.nextInt(indices.length)];
  }

  static double _generateRandomNav(String fundType) {
    switch (fundType) {
      case '股票型':
        return _random.nextDouble() * 5 + 0.5; // 0.5-5.5
      case '债券型':
        return _random.nextDouble() * 2 + 0.8; // 0.8-2.8
      case '混合型':
        return _random.nextDouble() * 4 + 0.8; // 0.8-4.8
      case '货币型':
        return _random.nextDouble() * 0.5 + 0.5; // 0.5-1.0
      case '指数型':
        return _random.nextDouble() * 6 + 0.5; // 0.5-6.5
      default:
        return _random.nextDouble() * 3 + 0.5; // 0.5-3.5
    }
  }

  static double _generateRandomChange() {
    // 生成-5%到+5%的日涨跌幅
    return (_random.nextDouble() - 0.5) * 10;
  }

  static double _generateRandomAmount() {
    // 生成100-10000的持有份额
    return _random.nextDouble() * 9900 + 100;
  }

  static String? _generateRandomNotes() {
    final notes = [
      '优秀的基金，长期表现稳定',
      '适合长期持有，风险适中',
      '波动较大，适合风险承受能力强的投资者',
      '收益稳定，适合保守投资',
      '成长性好，值得关注',
      '基金经理经验丰富',
      '适合定投',
      '市场基准配置',
      '消费主题投资机会',
      '科技板块龙头基金',
    ];
    return _random.nextDouble() < 0.7
        ? notes[_random.nextInt(notes.length)]
        : null;
  }

  static DateTime _randomDateTime(DateTime start, DateTime end) {
    final difference = end.difference(start).inMilliseconds;
    final randomMilliseconds = _random.nextInt(difference);
    return start.add(Duration(milliseconds: randomMilliseconds));
  }

  static List<FundFavorite> _applyRealisticMarketData(
      List<FundFavorite> favorites) {
    // 应用市场关联性：同类型基金涨跌趋势相关
    if (favorites.isEmpty) return favorites;

    // 计算基准趋势
    final baseTrend = _random.nextDouble() - 0.3; // -0.3 到 0.7

    for (int i = 0; i < favorites.length; i++) {
      final favorite = favorites[i];

      // 根据基金类型调整趋势
      double typeMultiplier = 1.0;
      switch (favorite.fundType) {
        case '股票型':
          typeMultiplier = 1.5; // 股票型波动更大
          break;
        case '债券型':
          typeMultiplier = 0.3; // 债券型波动更小
          break;
        case '货币型':
          typeMultiplier = 0.1; // 货币型几乎无波动
          break;
        default:
          typeMultiplier = 1.0;
      }

      final trend = baseTrend * typeMultiplier;
      final randomNoise = (_random.nextDouble() - 0.5) * 0.02; // ±1%的随机噪声

      favorites[i] = favorite.copyWith(
        dailyChange: (trend + randomNoise) * 100,
      );
    }

    return favorites;
  }

  static List<PortfolioHolding> _applyRealisticHoldingData(
      List<PortfolioHolding> holdings) {
    // 应用持仓相关的现实数据
    for (int i = 0; i < holdings.length; i++) {
      final holding = holdings[i];
      final daysHeld =
          DateTime.now().difference(holding.holdingStartDate).inDays;

      // 根据持有时间调整累计净值
      double accumulatedMultiplier = 1.0;
      if (daysHeld > 0) {
        // 假设年化收益率5-15%
        final annualReturn = 0.05 + _random.nextDouble() * 0.10;
        accumulatedMultiplier = 1 + (annualReturn * daysHeld / 365);
      }

      holdings[i] = holding.copyWith(
        accumulatedNav: holding.currentNav * accumulatedMultiplier,
        lastUpdatedDate:
            DateTime.now().subtract(Duration(hours: _random.nextInt(24))),
      );
    }

    return holdings;
  }
}

/// 测试场景数据
class TestScenarios {
  final ({List<FundFavorite> favorites, List<PortfolioHolding> holdings})
      Function() perfectMatch;
  final ({List<FundFavorite> favorites, List<PortfolioHolding> holdings})
      Function() partialOverlap;
  final ({List<FundFavorite> favorites, List<PortfolioHolding> holdings})
      Function() dataInconsistency;
  final ({List<FundFavorite> favorites, List<PortfolioHolding> holdings})
      Function() largeDataset;
  final ({List<FundFavorite> favorites, List<PortfolioHolding> holdings})
      Function() emptyData;
  final ({List<FundFavorite> favorites, List<PortfolioHolding> holdings})
      Function() oneSidedData;

  const TestScenarios({
    required this.perfectMatch,
    required this.partialOverlap,
    required this.dataInconsistency,
    required this.largeDataset,
    required this.emptyData,
    required this.oneSidedData,
  });
}

/// 边界测试数据
class BoundaryTestData {
  final List<FundFavorite> emptyFavorites;
  final List<PortfolioHolding> emptyHoldings;
  final List<FundFavorite> singleFavorite;
  final List<PortfolioHolding> singleHolding;
  final List<FundFavorite> maximumFavorites;
  final List<PortfolioHolding> maximumHoldings;
  final List<FundFavorite> zeroNavFavorites;
  final List<FundFavorite> negativeNavFavorites;
  final List<PortfolioHolding> zeroAmountHoldings;
  final List<PortfolioHolding> negativeAmountHoldings;

  const BoundaryTestData({
    required this.emptyFavorites,
    required this.emptyHoldings,
    required this.singleFavorite,
    required this.singleHolding,
    required this.maximumFavorites,
    required this.maximumHoldings,
    required this.zeroNavFavorites,
    required this.negativeNavFavorites,
    required this.zeroAmountHoldings,
    required this.negativeAmountHoldings,
  });
}

/// 性能测试数据
class PerformanceTestData {
  final ({
    List<FundFavorite> favorites,
    List<PortfolioHolding> holdings
  }) smallDataset;
  final ({
    List<FundFavorite> favorites,
    List<PortfolioHolding> holdings
  }) mediumDataset;
  final ({
    List<FundFavorite> favorites,
    List<PortfolioHolding> holdings
  }) largeDataset;
  final ({
    List<FundFavorite> favorites,
    List<PortfolioHolding> holdings
  }) xlargeDataset;

  const PerformanceTestData({
    required this.smallDataset,
    required this.mediumDataset,
    required this.largeDataset,
    required this.xlargeDataset,
  });
}
