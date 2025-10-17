/// 基金仓位数据DTO
///
/// 用于表示股票型基金的仓位信息，包括日期、收盘价和持仓比例
class FundPositionDto {
  final DateTime date;
  final double close;
  final double position;

  FundPositionDto({
    required this.date,
    required this.close,
    required this.position,
  });

  /// 从JSON创建FundPositionDto
  factory FundPositionDto.fromJson(Map<String, dynamic> json) {
    return FundPositionDto(
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      close: double.tryParse(json['close']?.toString() ?? '0') ?? 0.0,
      position: double.tryParse(json['position']?.toString() ?? '0') ?? 0.0,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String().split('T')[0],
      'close': close,
      'position': position,
    };
  }

  @override
  String toString() {
    return 'FundPositionDto(date: $date, close: $close, position: $position%)';
  }
}
