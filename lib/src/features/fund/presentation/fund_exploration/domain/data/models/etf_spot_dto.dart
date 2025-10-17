/// ETF现货数据信息传输对象
class ETFSportDto {
  final String? symbol;
  final String? name;
  final double? currentPrice;
  final double? change;
  final double? changePercent;
  final double? volume;
  final double? turnover;
  final double? high;
  final double? low;
  final double? open;
  final double? previousClose;
  final String? updateTime;

  ETFSportDto({
    this.symbol,
    this.name,
    this.currentPrice,
    this.change,
    this.changePercent,
    this.volume,
    this.turnover,
    this.high,
    this.low,
    this.open,
    this.previousClose,
    this.updateTime,
  });

  factory ETFSportDto.fromJson(Map<String, dynamic> json) {
    return ETFSportDto(
      symbol: json['symbol']?.toString(),
      name: json['name']?.toString(),
      currentPrice: json['current_price'] != null
          ? double.tryParse(json['current_price'].toString())
          : null,
      change: json['change'] != null
          ? double.tryParse(json['change'].toString())
          : null,
      changePercent: json['change_percent'] != null
          ? double.tryParse(json['change_percent'].toString())
          : null,
      volume: json['volume'] != null
          ? double.tryParse(json['volume'].toString())
          : null,
      turnover: json['turnover'] != null
          ? double.tryParse(json['turnover'].toString())
          : null,
      high: json['high'] != null
          ? double.tryParse(json['high'].toString())
          : null,
      low: json['low'] != null ? double.tryParse(json['low'].toString()) : null,
      open: json['open'] != null
          ? double.tryParse(json['open'].toString())
          : null,
      previousClose: json['previous_close'] != null
          ? double.tryParse(json['previous_close'].toString())
          : null,
      updateTime: json['update_time']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'name': name,
      'current_price': currentPrice,
      'change': change,
      'change_percent': changePercent,
      'volume': volume,
      'turnover': turnover,
      'high': high,
      'low': low,
      'open': open,
      'previous_close': previousClose,
      'update_time': updateTime,
    };
  }
}
