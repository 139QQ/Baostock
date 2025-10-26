import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'fund_info.g.dart';

/// 基金信息模型 - 精简字段，优化缓存性能
@JsonSerializable()
@HiveType(typeId: 20)
class FundInfo extends HiveObject {
  @HiveField(0)
  @JsonKey(name: '基金代码')
  final String code;

  @HiveField(1)
  @JsonKey(name: '基金简称')
  final String name;

  @HiveField(2)
  @JsonKey(name: '基金类型')
  final String type;

  @HiveField(3)
  @JsonKey(name: '拼音缩写')
  final String pinyinAbbr;

  @HiveField(4)
  @JsonKey(name: '拼音全称')
  final String pinyinFull;

  FundInfo({
    required this.code,
    required this.name,
    required this.type,
    required this.pinyinAbbr,
    required this.pinyinFull,
  });

  /// 从JSON创建对象
  factory FundInfo.fromJson(Map<String, dynamic> json) =>
      _$FundInfoFromJson(json);

  /// 转换为JSON
  Map<String, dynamic> toJson() => _$FundInfoToJson(this);

  /// 简化基金类型显示
  String get simplifiedType {
    if (type.startsWith('混合型')) return '混合型';
    if (type.startsWith('股票型')) return '股票型';
    if (type.startsWith('债券型')) return '债券型';
    if (type.startsWith('货币型')) return '货币型';
    if (type.startsWith('指数型')) return '指数型';
    if (type.startsWith('QDII')) return 'QDII';
    if (type.startsWith('FOF')) return 'FOF';
    return type;
  }

  /// 搜索匹配检查
  bool matchesQuery(String query) {
    if (query.isEmpty) return true;

    final lowerQuery = query.toLowerCase();

    // 精确代码匹配
    if (code == query) return true;

    // 名称包含
    if (name.toLowerCase().contains(lowerQuery)) return true;

    // 拼音缩写匹配
    if (pinyinAbbr.toLowerCase().contains(lowerQuery)) return true;

    // 拼音全称匹配
    if (pinyinFull.toLowerCase().contains(lowerQuery)) return true;

    // 简化类型匹配
    if (simplifiedType.toLowerCase().contains(lowerQuery)) return true;

    return false;
  }

  /// 多条件搜索匹配
  bool matchesMultipleQueries(List<String> queries) {
    if (queries.isEmpty) return true;

    return queries.every((query) => matchesQuery(query));
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FundInfo && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() {
    return 'FundInfo{code: $code, name: $name, type: $simplifiedType}';
  }
}
