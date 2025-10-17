/// ETF历史数据信息传输对象
class ETFHistDto {
  final String? date;
  final double? open;
  final double? high;
  final double? low;
  final double? close;
  final double? volume;
  final double? turnover;
  final double? change;
  final double? changePercent;

  ETFHistDto({
    this.date,
    this.open,
    this.high,
    this.low,
    this.close,
    this.volume,
    this.turnover,
    this.change,
    this.changePercent,
  });

  factory ETFHistDto.fromJson(Map<String, dynamic> json) {
    return ETFHistDto(
      date: json['date']?.toString(),
      open: json['open'] != null
          ? double.tryParse(json['open'].toString())
          : null,
      high: json['high'] != null
          ? double.tryParse(json['high'].toString())
          : null,
      low: json['low'] != null ? double.tryParse(json['low'].toString()) : null,
      close: json['close'] != null
          ? double.tryParse(json['close'].toString())
          : null,
      volume: json['volume'] != null
          ? double.tryParse(json['volume'].toString())
          : null,
      turnover: json['turnover'] != null
          ? double.tryParse(json['turnover'].toString())
          : null,
      change: json['change'] != null
          ? double.tryParse(json['change'].toString())
          : null,
      changePercent: json['change_percent'] != null
          ? double.tryParse(json['change_percent'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'open': open,
      'high': high,
      'low': low,
      'close': close,
      'volume': volume,
      'turnover': turnover,
      'change': change,
      'change_percent': changePercent,
    };
  }
}
