/// 市场指数数据模型
class MarketIndicesData {
  final List<IndexData> indices;

  MarketIndicesData({required this.indices});

  /// 获取主指数（上证指数）
  IndexData get mainIndex {
    return indices.firstWhere(
      (index) => index.symbol == '000001',
      orElse: () => IndexData(
        symbol: '000001',
        name: '上证指数',
        latestPrice: 0.0,
        changeAmount: 0.0,
        changePercent: 0.0,
        volume: 0,
        amount: 0.0,
        openPrice: 0.0,
        highPrice: 0.0,
        lowPrice: 0.0,
        previousClose: 0.0,
        updateTime: '',
      ),
    );
  }

  /// 获取除主指数外的其他指数
  List<IndexData> get subIndices {
    return indices.where((index) => index.symbol != '000001').toList();
  }
}

/// 单个指数数据模型
class IndexData {
  final String symbol;
  final String name;
  final double latestPrice;
  final double changeAmount;
  final double changePercent;
  final int volume;
  final double amount;
  final double openPrice;
  final double highPrice;
  final double lowPrice;
  final double previousClose;
  final String updateTime;

  IndexData({
    required this.symbol,
    required this.name,
    required this.latestPrice,
    required this.changeAmount,
    required this.changePercent,
    required this.volume,
    required this.amount,
    required this.openPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.previousClose,
    required this.updateTime,
  });

  /// 是否为正涨跌
  bool get isPositive => changePercent >= 0;
}

/// 指数历史数据模型（日线）
class IndexHistoryData {
  final String symbol;
  final String name;
  final DateTime date;
  final double open;
  final double high;
  final double low;
  final double close;
  final int volume;
  final double amount;

  IndexHistoryData({
    required this.symbol,
    required this.name,
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    required this.amount,
  });

  /// 从东方财富API数据创建
  factory IndexHistoryData.fromEastMoney(
      Map<String, dynamic> data, String symbol, String name) {
    return IndexHistoryData(
      symbol: symbol,
      name: name,
      date: DateTime.parse(data['date']?.toString() ?? ''),
      open: (data['open'] ?? 0.0).toDouble(),
      high: (data['high'] ?? 0.0).toDouble(),
      low: (data['low'] ?? 0.0).toDouble(),
      close: (data['close'] ?? 0.0).toDouble(),
      volume: (data['volume'] ?? 0).toInt(),
      amount: (data['amount'] ?? 0.0).toDouble(),
    );
  }

  /// 从新浪API数据创建
  factory IndexHistoryData.fromSina(
      Map<String, dynamic> data, String symbol, String name) {
    return IndexHistoryData(
      symbol: symbol,
      name: name,
      date: DateTime.parse(data['date']?.toString() ?? ''),
      open: (data['open'] ?? 0.0).toDouble(),
      high: (data['high'] ?? 0.0).toDouble(),
      low: (data['low'] ?? 0.0).toDouble(),
      close: (data['close'] ?? 0.0).toDouble(),
      volume: (data['volume'] ?? 0).toInt(),
      amount: 0.0, // 新浪数据中没有amount字段
    );
  }

  /// 从腾讯API数据创建
  factory IndexHistoryData.fromTencent(
      Map<String, dynamic> data, String symbol, String name) {
    return IndexHistoryData(
      symbol: symbol,
      name: name,
      date: DateTime.parse(data['date']?.toString() ?? ''),
      open: (data['open'] ?? 0.0).toDouble(),
      high: (data['high'] ?? 0.0).toDouble(),
      low: (data['low'] ?? 0.0).toDouble(),
      close: (data['close'] ?? 0.0).toDouble(),
      volume: 0, // 腾讯数据中没有volume字段，amount单位是手
      amount: (data['amount'] ?? 0.0).toDouble(),
    );
  }

  /// 涨跌幅
  double get changePercent {
    if (open == 0) return 0.0;
    return ((close - open) / open) * 100;
  }

  /// 涨跌额
  double get changeAmount => close - open;
}

/// 指数分时数据模型
class IndexIntradayData {
  final String symbol;
  final String name;
  final DateTime time;
  final double open;
  final double close;
  final double high;
  final double low;
  final int volume;
  final double amount;
  final double avgPrice;

  IndexIntradayData({
    required this.symbol,
    required this.name,
    required this.time,
    required this.open,
    required this.close,
    required this.high,
    required this.low,
    required this.volume,
    required this.amount,
    required this.avgPrice,
  });

  /// 从东方财富分时API数据创建
  factory IndexIntradayData.fromEastMoney(
      Map<String, dynamic> data, String symbol, String name) {
    return IndexIntradayData(
      symbol: symbol,
      name: name,
      time: DateTime.parse(data['时间']?.toString() ?? ''),
      open: (data['开盘'] ?? 0.0).toDouble(),
      close: (data['收盘'] ?? 0.0).toDouble(),
      high: (data['最高'] ?? 0.0).toDouble(),
      low: (data['最低'] ?? 0.0).toDouble(),
      volume: (data['成交量'] ?? 0).toInt(),
      amount: (data['成交额'] ?? 0.0).toDouble(),
      avgPrice: (data['均价'] ?? 0.0).toDouble(),
    );
  }
}

/// 历史数据查询参数
class HistoryQueryParams {
  final String symbol;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? period; // 用于分时数据: '1', '5', '15', '30', '60'

  HistoryQueryParams({
    required this.symbol,
    this.startDate,
    this.endDate,
    this.period,
  });

  /// 转换为API查询参数
  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{
      'symbol': symbol,
    };

    if (startDate != null) {
      params['start_date'] = _formatDateTime(startDate!);
    }

    if (endDate != null) {
      params['end_date'] = _formatDateTime(endDate!);
    }

    if (period != null) {
      params['period'] = period;
    }

    return params;
  }

  /// 格式化日期时间为API所需格式
  String _formatDateTime(DateTime dateTime) {
    // 分时数据需要完整的时间格式: "2023-12-11 09:30:00"
    // 日线数据只需要日期格式: "2023-12-11"
    return period != null
        ? "${dateTime.year.toString().padLeft(4, '0')}-"
            "${dateTime.month.toString().padLeft(2, '0')}-"
            "${dateTime.day.toString().padLeft(2, '0')} "
            "${dateTime.hour.toString().padLeft(2, '0')}:"
            "${dateTime.minute.toString().padLeft(2, '0')}:"
            "${dateTime.second.toString().padLeft(2, '0')}"
        : "${dateTime.year.toString().padLeft(4, '0')}-"
            "${dateTime.month.toString().padLeft(2, '0')}-"
            "${dateTime.day.toString().padLeft(2, '0')}";
  }
}

/// 图表数据点模型
class ChartPoint {
  final double x;
  final double y;
  final DateTime? time;

  ChartPoint({
    required this.x,
    required this.y,
    this.time,
  });

  /// 获取价格（y值）
  double get price => y;

  /// 从历史数据创建
  factory ChartPoint.fromHistoryData(IndexHistoryData data, int index) {
    return ChartPoint(
      x: index.toDouble(),
      y: data.close,
      time: data.date,
    );
  }

  /// 从分时数据创建
  factory ChartPoint.fromIntradayData(IndexIntradayData data, int index) {
    return ChartPoint(
      x: index.toDouble(),
      y: data.close,
      time: data.time,
    );
  }
}
