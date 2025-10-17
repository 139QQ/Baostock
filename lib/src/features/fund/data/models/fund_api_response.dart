import '../../domain/entities/fund.dart';

/// 基金API响应数据模型
///
/// 用于处理AKShare API返回的中文字段数据
class FundApiResponse {
  /// 将API原始数据转换为基金实体列表
  static List<Fund> fromRankingApi(List<Map<String, dynamic>> apiData) {
    return apiData.map((item) => _convertRankingItemToFund(item)).toList();
  }

  /// 转换单个基金排行数据项
  static Fund _convertRankingItemToFund(Map<String, dynamic> item) {
    return Fund(
      // 基本信息
      code: item['基金代码']?.toString() ?? '',
      name: item['基金简称']?.toString() ?? '',
      type: _determineFundType(item['基金简称']?.toString() ?? ''),
      company: _extractCompanyName(item['基金简称']?.toString() ?? ''),
      manager: '', // 从基金简称提取基金经理信息较复杂，暂时留空

      // 净值信息
      unitNav: (item['单位净值'] ?? 0).toDouble(),
      accumulatedNav: (item['累计净值'] ?? 0).toDouble(),
      dailyReturn: (item['日增长率'] ?? 0).toDouble(),

      // 收益率信息（多个时间段）
      return1W: (item['近1周'] ?? 0).toDouble(),
      return1M: (item['近1月'] ?? 0).toDouble(),
      return3M: (item['近3月'] ?? 0).toDouble(),
      return6M: (item['近6月'] ?? 0).toDouble(),
      return1Y: (item['近1年'] ?? 0).toDouble(),
      return2Y: (item['近2年'] ?? 0).toDouble(),
      return3Y: (item['近3年'] ?? 0).toDouble(),
      returnYTD: (item['今年来'] ?? 0).toDouble(),
      returnSinceInception: (item['成立来'] ?? 0).toDouble(),

      // 其他信息
      scale: 0, // 缓存中可能没有规模信息
      riskLevel: '', // 缓存中可能没有风险等级
      status: 'active', // 默认状态
      date: item['日期']?.toString() ?? DateTime.now().toIso8601String(),
      fee: _parseFee(item['手续费']?.toString()),
      rankingPosition: (item['序号'] ?? 0) as int,
      totalCount: 0, // 将在外部设置总数

      // 价格和变动信息（默认使用净值）
      currentPrice: (item['单位净值'] ?? 0).toDouble(),
      dailyChange: 0, // 日涨跌信息可能不存在，使用0作为默认值
      dailyChangePercent: (item['日增长率'] ?? 0).toDouble(),

      // 必需参数
      lastUpdate: DateTime.now(),
    );
  }

  /// 根据基金简称判断基金类型
  static String _determineFundType(String fundName) {
    if (fundName.contains('混合')) return '混合型';
    if (fundName.contains('股票')) return '股票型';
    if (fundName.contains('债券')) return '债券型';
    if (fundName.contains('指数')) return '指数型';
    if (fundName.contains('QDII')) return 'QDII';
    if (fundName.contains('货币')) return '货币型';
    return '混合型'; // 默认类型
  }

  /// 从基金简称提取公司名称
  static String _extractCompanyName(String fundName) {
    // 常见的基金公司名称模式
    final companyPatterns = [
      '易方达',
      '华夏',
      '南方',
      '嘉实',
      '博时',
      '广发',
      '富国',
      '汇添富',
      '国泰',
      '华安',
      '银华',
      '大成',
      '鹏华',
      '长盛',
      '融通',
      '建信',
      '工银瑞信',
      '招商',
      '中银',
      '兴业',
      '平安',
      '景顺长城',
      '中欧',
      '交银施罗德',
      '华泰柏瑞',
      '诺安',
      '海富通',
      '万家',
      '德邦',
      '信澳',
      '中信保诚'
    ];

    for (final pattern in companyPatterns) {
      if (fundName.contains(pattern)) {
        return pattern;
      }
    }

    return '未知公司';
  }

  /// 解析手续费百分比
  static double _parseFee(String? feeStr) {
    if (feeStr == null) return 0.0;

    try {
      // 处理 "0.15%" 这样的格式
      final cleaned = feeStr.replaceAll('%', '').trim();
      return double.parse(cleaned);
    } catch (e) {
      return 0.0;
    }
  }

  /// 创建基金排行模拟数据（用于测试）
  static List<Map<String, dynamic>> createMockRankingData() {
    return [
      {
        '序号': 1,
        '基金代码': '005827',
        '基金简称': '易方达蓝筹精选混合',
        '日期': '2025-09-19T00:00:00.000',
        '单位净值': 2.1567,
        '累计净值': 2.4567,
        '日增长率': 1.23,
        '近1周': 2.15,
        '近1月': 8.92,
        '近3月': 15.67,
        '近6月': 18.34,
        '近1年': 22.34,
        '近2年': 45.67,
        '近3年': 78.92,
        '今年来': 18.76,
        '成立来': 156.78,
        '手续费': '1.5%',
      },
      {
        '序号': 2,
        '基金代码': '161005',
        '基金简称': '富国天惠成长混合',
        '日期': '2025-09-19T00:00:00.000',
        '单位净值': 3.1234,
        '累计净值': 4.2345,
        '日增长率': 0.87,
        '近1周': 1.87,
        '近1月': 7.23,
        '近3月': 12.45,
        '近6月': 16.78,
        '近1年': 19.67,
        '近2年': 38.45,
        '近3年': 65.23,
        '今年来': 16.23,
        '成立来': 134.56,
        '手续费': '1.2%',
      },
    ];
  }
}
