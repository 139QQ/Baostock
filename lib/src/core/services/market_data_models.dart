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
}
