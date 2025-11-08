// 为了向后兼容，创建 FundData 的类型别名
typedef FundData = Fund;

class Fund {
  final String code;
  final String name;
  final String type;
  final String company;
  final String manager;
  final double unitNav;
  final double accumulatedNav;
  final double dailyReturn;
  final double return1W;
  final double return1M;
  final double return3M;
  final double return6M;
  final double return1Y;
  final double return2Y;
  final double return3Y;
  final double returnYTD;
  final double returnSinceInception;
  final double scale;
  final String riskLevel;
  final String status;
  final String date;
  final double fee;
  final int rankingPosition;
  final int totalCount;
  final double currentPrice;
  final double dailyChange;
  final double dailyChangePercent;
  final DateTime lastUpdate;

  Fund({
    required this.code,
    required this.name,
    required this.type,
    required this.company,
    this.manager = '',
    this.unitNav = 0.0,
    this.accumulatedNav = 0.0,
    this.dailyReturn = 0.0,
    this.return1W = 0.0,
    this.return1M = 0.0,
    this.return3M = 0.0,
    this.return6M = 0.0,
    this.return1Y = 0.0,
    this.return2Y = 0.0,
    this.return3Y = 0.0,
    this.returnYTD = 0.0,
    this.returnSinceInception = 0.0,
    this.scale = 0.0,
    this.riskLevel = '',
    this.status = 'active',
    this.date = '',
    this.fee = 0.0,
    this.rankingPosition = 0,
    this.totalCount = 0,
    this.currentPrice = 0.0,
    this.dailyChange = 0.0,
    this.dailyChangePercent = 0.0,
    required this.lastUpdate,
  });

  Fund copyWith({
    String? code,
    String? name,
    String? type,
    String? company,
    String? manager,
    double? unitNav,
    double? accumulatedNav,
    double? dailyReturn,
    double? return1W,
    double? return1M,
    double? return3M,
    double? return6M,
    double? return1Y,
    double? return2Y,
    double? return3Y,
    double? returnYTD,
    double? returnSinceInception,
    double? scale,
    String? riskLevel,
    String? status,
    String? date,
    double? fee,
    int? rankingPosition,
    int? totalCount,
    double? currentPrice,
    double? dailyChange,
    double? dailyChangePercent,
    DateTime? lastUpdate,
  }) {
    return Fund(
      code: code ?? this.code,
      name: name ?? this.name,
      type: type ?? this.type,
      company: company ?? this.company,
      manager: manager ?? this.manager,
      unitNav: unitNav ?? this.unitNav,
      accumulatedNav: accumulatedNav ?? this.accumulatedNav,
      dailyReturn: dailyReturn ?? this.dailyReturn,
      return1W: return1W ?? this.return1W,
      return1M: return1M ?? this.return1M,
      return3M: return3M ?? this.return3M,
      return6M: return6M ?? this.return6M,
      return1Y: return1Y ?? this.return1Y,
      return2Y: return2Y ?? this.return2Y,
      return3Y: return3Y ?? this.return3Y,
      returnYTD: returnYTD ?? this.returnYTD,
      returnSinceInception: returnSinceInception ?? this.returnSinceInception,
      scale: scale ?? this.scale,
      riskLevel: riskLevel ?? this.riskLevel,
      status: status ?? this.status,
      date: date ?? this.date,
      fee: fee ?? this.fee,
      rankingPosition: rankingPosition ?? this.rankingPosition,
      totalCount: totalCount ?? this.totalCount,
      currentPrice: currentPrice ?? this.currentPrice,
      dailyChange: dailyChange ?? this.dailyChange,
      dailyChangePercent: dailyChangePercent ?? this.dailyChangePercent,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }

  factory Fund.fromJson(Map<String, dynamic> json) {
    return Fund(
      code: json['代码'] ?? json['code'] ?? '',
      name: json['名称'] ?? json['name'] ?? '',
      type: json['类型'] ?? json['type'] ?? '',
      company: json['管理公司'] ?? json['company'] ?? '',
      manager: json['基金经理'] ?? json['manager'] ?? '',
      unitNav: _parseDouble(json['单位净值'] ?? json['unitNav'] ?? 0.0),
      accumulatedNav:
          _parseDouble(json['累计净值'] ?? json['accumulatedNav'] ?? 0.0),
      dailyReturn: _parseDouble(json['日增长率'] ?? json['dailyReturn'] ?? 0.0),
      return1W: _parseDouble(json['近1周'] ?? json['return1W'] ?? 0.0),
      return1M: _parseDouble(json['近1月'] ?? json['return1M'] ?? 0.0),
      return3M: _parseDouble(json['近3月'] ?? json['return3M'] ?? 0.0),
      return6M: _parseDouble(json['近6月'] ?? json['return6M'] ?? 0.0),
      return1Y: _parseDouble(json['近1年'] ?? json['return1Y'] ?? 0.0),
      return2Y: _parseDouble(json['近2年'] ?? json['return2Y'] ?? 0.0),
      return3Y: _parseDouble(json['近3年'] ?? json['return3Y'] ?? 0.0),
      returnYTD: _parseDouble(json['今年来'] ?? json['returnYTD'] ?? 0.0),
      returnSinceInception:
          _parseDouble(json['成立来'] ?? json['returnSinceInception'] ?? 0.0),
      scale: _parseDouble(json['基金规模'] ?? json['scale'] ?? 0.0),
      riskLevel: json['风险等级'] ?? json['riskLevel'] ?? '',
      status: json['状态'] ?? json['status'] ?? 'active',
      date: json['日期'] ?? json['date'] ?? '',
      fee: _parseDouble(json['手续费'] ?? json['fee'] ?? 0.0),
      rankingPosition: json['序号'] ?? json['rankingPosition'] ?? 0,
      totalCount: json['总数'] ?? json['totalCount'] ?? 0,
      currentPrice: _parseDouble(json['当前价'] ?? json['currentPrice'] ?? 0.0),
      dailyChange: _parseDouble(json['日涨跌'] ?? json['dailyChange'] ?? 0.0),
      dailyChangePercent:
          _parseDouble(json['日涨跌幅'] ?? json['dailyChangePercent'] ?? 0.0),
      lastUpdate: DateTime.tryParse(json['lastUpdate'] ?? '') ?? DateTime.now(),
    );
  }

  /// 将Fund对象转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'type': type,
      'company': company,
      'manager': manager,
      'unitNav': unitNav,
      'accumulatedNav': accumulatedNav,
      'dailyReturn': dailyReturn,
      'return1W': return1W,
      'return1M': return1M,
      'return3M': return3M,
      'return6M': return6M,
      'return1Y': return1Y,
      'return2Y': return2Y,
      'return3Y': return3Y,
      'returnYTD': returnYTD,
      'returnSinceInception': returnSinceInception,
      'scale': scale,
      'riskLevel': riskLevel,
      'status': status,
      'date': date,
      'fee': fee,
      'rankingPosition': rankingPosition,
      'totalCount': totalCount,
      'currentPrice': currentPrice,
      'dailyChange': dailyChange,
      'dailyChangePercent': dailyChangePercent,
      'lastUpdate': lastUpdate.toIso8601String(),
    };
  }

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Fund &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          name == other.name;

  @override
  int get hashCode => code.hashCode ^ name.hashCode;
}
