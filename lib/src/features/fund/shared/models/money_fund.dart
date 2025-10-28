import 'package:equatable/equatable.dart';

/// 货币型基金数据模型
///
/// 专门处理货币型基金的API数据结构，包括动态日期字段
class MoneyFund extends Equatable {
  /// 基金代码
  final String fundCode;

  /// 基金简称
  final String fundName;

  /// 当前万份收益（最近交易日的数据）
  final double dailyIncome;

  /// 当前7日年化收益率（最近交易日的数据）
  final double sevenDayYield;

  /// 前一日万份收益
  final double previousDailyIncome;

  /// 前一日7日年化收益率
  final double previousSevenDayYield;

  /// 单位净值（货币基金通常为1.0或---）
  final String unitNav;

  /// 日涨幅
  final String dailyChange;

  /// 成立日期
  final String establishDate;

  /// 基金经理
  final String fundManager;

  /// 手续费
  final String managementFee;

  /// 可购状态
  final String purchaseStatus;

  /// 数据日期（用于标识数据是哪一天的）
  final String dataDate;

  const MoneyFund({
    required this.fundCode,
    required this.fundName,
    required this.dailyIncome,
    required this.sevenDayYield,
    this.previousDailyIncome = 0.0,
    this.previousSevenDayYield = 0.0,
    this.unitNav = '---',
    this.dailyChange = '---',
    this.establishDate = '',
    this.fundManager = '',
    this.managementFee = '',
    this.purchaseStatus = '',
    required this.dataDate,
  });

  /// 从JSON创建MoneyFund对象
  ///
  /// 处理动态日期字段名，如：2025-10-27-万份收益、2025-10-27-7日年化%
  factory MoneyFund.fromJson(Map<String, dynamic> json) {
    // 数据解析函数
    double parseDouble(dynamic value) {
      if (value == null || value == '---' || value == '') return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) {
        // 移除百分号和其他非数字字符
        final cleanValue = value.replaceAll(RegExp(r'[^\d.-]'), '');
        return double.tryParse(cleanValue) ?? 0.0;
      }
      return 0.0;
    }

    String parseString(dynamic value) {
      return value?.toString() ?? '';
    }

    final fundCode = parseString(json['基金代码']);
    final fundName = parseString(json['基金简称']);
    final unitNav =
        parseString(json['2025-10-27-单位净值'] ?? json['单位净值'] ?? '---');
    final dailyChange = parseString(json['日涨幅'] ?? '---');
    final establishDate = parseString(json['成立日期']);
    final fundManager = parseString(json['基金经理']);
    final managementFee = parseString(json['手续费']);
    final purchaseStatus = parseString(json['可购全部']);

    // 解析动态日期字段
    double dailyIncome = 0.0;
    double sevenDayYield = 0.0;
    double previousDailyIncome = 0.0;
    double previousSevenDayYield = 0.0;
    String dataDate = '';

    // 查找所有带日期前缀的字段
    final datePattern = RegExp(r'(\d{4}-\d{2}-\d{2})-(.+)');
    final dateFields = <String, Map<String, dynamic>>{};

    for (final entry in json.entries) {
      final match = datePattern.firstMatch(entry.key);
      if (match != null) {
        final date = match.group(1)!;
        final fieldType = match.group(2)!;

        if (!dateFields.containsKey(date)) {
          dateFields[date] = {};
        }

        dateFields[date]![fieldType] = entry.value;
      }
    }

    // 按日期排序，获取最近的数据
    final sortedDates = dateFields.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // 降序，最新的在前

    if (sortedDates.isNotEmpty) {
      dataDate = sortedDates.first; // 最新日期
      final latestFields = dateFields[dataDate]!;

      dailyIncome = parseDouble(latestFields['万份收益']);
      sevenDayYield = parseDouble(latestFields['7日年化%']);

      // 如果有前一天的数据，也解析出来
      if (sortedDates.length > 1) {
        final previousDate = sortedDates[1];
        final previousFields = dateFields[previousDate]!;
        previousDailyIncome = parseDouble(previousFields['万份收益']);
        previousSevenDayYield = parseDouble(previousFields['7日年化%']);
      }
    }

    return MoneyFund(
      fundCode: fundCode,
      fundName: fundName,
      dailyIncome: dailyIncome,
      sevenDayYield: sevenDayYield,
      previousDailyIncome: previousDailyIncome,
      previousSevenDayYield: previousSevenDayYield,
      unitNav: unitNav,
      dailyChange: dailyChange,
      establishDate: establishDate,
      fundManager: fundManager,
      managementFee: managementFee,
      purchaseStatus: purchaseStatus,
      dataDate: dataDate,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'fundCode': fundCode,
      'fundName': fundName,
      'dailyIncome': dailyIncome,
      'sevenDayYield': sevenDayYield,
      'previousDailyIncome': previousDailyIncome,
      'previousSevenDayYield': previousSevenDayYield,
      'unitNav': unitNav,
      'dailyChange': dailyChange,
      'establishDate': establishDate,
      'fundManager': fundManager,
      'managementFee': managementFee,
      'purchaseStatus': purchaseStatus,
      'dataDate': dataDate,
    };
  }

  /// 获取格式化的万份收益
  String get formattedDailyIncome {
    return dailyIncome.toStringAsFixed(4);
  }

  /// 获取格式化的7日年化收益率
  String get formattedSevenDayYield {
    return '${sevenDayYield.toStringAsFixed(4)}%';
  }

  /// 计算万份收益日变化
  double get dailyIncomeChange {
    return dailyIncome - previousDailyIncome;
  }

  /// 计算7日年化日变化
  double get sevenDayYieldChange {
    return sevenDayYield - previousSevenDayYield;
  }

  /// 是否为上涨
  bool get isIncomeIncreasing => dailyIncomeChange > 0;

  /// 是否收益率上涨
  bool get isYieldIncreasing => sevenDayYieldChange > 0;

  /// 获取万份收益变化描述
  String get dailyIncomeChangeDescription {
    if (previousDailyIncome == 0.0) return '无数据';
    final change = dailyIncomeChange;
    final changePercent =
        previousDailyIncome != 0 ? (change / previousDailyIncome * 100) : 0.0;
    return '${change > 0 ? '+' : ''}${change.toStringAsFixed(4)} (${changePercent > 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%)';
  }

  /// 获取7日年化变化描述
  String get sevenDayYieldChangeDescription {
    if (previousSevenDayYield == 0.0) return '无数据';
    final change = sevenDayYieldChange;
    return '${change > 0 ? '+' : ''}${change.toStringAsFixed(4)}%';
  }

  @override
  List<Object> get props => [
        fundCode,
        fundName,
        dailyIncome,
        sevenDayYield,
        previousDailyIncome,
        previousSevenDayYield,
        unitNav,
        dailyChange,
        establishDate,
        fundManager,
        managementFee,
        purchaseStatus,
        dataDate,
      ];

  @override
  String toString() {
    return 'MoneyFund{'
        'fundCode: $fundCode, '
        'fundName: $fundName, '
        'dailyIncome: $formattedDailyIncome, '
        'sevenDayYield: $formattedSevenDayYield, '
        'dataDate: $dataDate'
        '}';
  }
}
