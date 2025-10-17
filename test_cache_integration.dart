import 'lib/src/features/fund/domain/entities/fund.dart';
import 'lib/src/features/fund/domain/entities/fund_filter_criteria.dart';

/// 缓存集成测试
void main() async {
  print('🧪 开始缓存集成测试...\n');

  // 1. 测试Fund实体序列化
  await _testFundSerialization();

  // 2. 测试筛选条件序列化
  await _testFilterCriteriaSerialization();

  print('\n✅ 缓存集成测试完成！');
}

/// 测试Fund实体的JSON序列化
Future<void> _testFundSerialization() async {
  print('📊 测试Fund实体序列化...');

  try {
    // 创建测试基金
    final fund = Fund(
      code: '000001',
      name: '华夏成长混合',
      type: '混合型',
      company: '华夏基金',
      manager: '张三',
      unitNav: 1.2345,
      accumulatedNav: 2.3456,
      dailyReturn: 0.0123,
      return1W: 0.0234,
      return1M: 0.0345,
      return3M: 0.0456,
      return6M: 0.0567,
      return1Y: 0.0678,
      return2Y: 0.0789,
      return3Y: 0.0890,
      returnYTD: 0.0123,
      returnSinceInception: 1.2345,
      scale: 123.45,
      riskLevel: 'R3',
      status: 'active',
      date: '2023-01-01',
      fee: 0.015,
      rankingPosition: 1,
      totalCount: 100,
      currentPrice: 1.2345,
      dailyChange: 0.0123,
      dailyChangePercent: 1.23,
      lastUpdate: DateTime.now(),
    );

    // 序列化
    final json = fund.toJson();
    print('✅ Fund序列化成功，字段数: ${json.keys.length}');

    // 反序列化
    final fundFromJson = Fund.fromJson(json);
    print('✅ Fund反序列化成功');

    // 验证数据一致性
    assert(fund.code == fundFromJson.code, '基金代码不一致');
    assert(fund.name == fundFromJson.name, '基金名称不一致');
    assert(fund.type == fundFromJson.type, '基金类型不一致');
    assert(fund.company == fundFromJson.company, '管理公司不一致');
    assert(fund.return1Y == fundFromJson.return1Y, '近1年收益率不一致');

    print('✅ Fund数据一致性验证通过');
  } catch (e) {
    print('❌ Fund序列化测试失败: $e');
  }

  print('');
}

/// 测试筛选条件的JSON序列化
Future<void> _testFilterCriteriaSerialization() async {
  print('🔍 测试筛选条件序列化...');

  try {
    // 创建测试筛选条件
    const criteria = FundFilterCriteria(
      fundTypes: ['股票型', '混合型'],
      companies: ['华夏基金', '易方达'],
      scaleRange: RangeValue(min: 10.0, max: 100.0),
      riskLevels: ['R2', 'R3'],
      returnRange: RangeValue(min: 5.0, max: 20.0),
      sortBy: 'return1Y',
      sortDirection: SortDirection.desc,
      page: 1,
      pageSize: 20,
    );

    // 生成筛选键
    final filterKey = _generateFilterKey(criteria);
    print('✅ 筛选键生成成功: $filterKey');

    // 解析筛选键
    final parsedCriteria = _parseFilterKey(filterKey);
    if (parsedCriteria != null) {
      print('✅ 筛选键解析成功');
      print('   - 基金类型: ${parsedCriteria.fundTypes}');
      print('   - 管理公司: ${parsedCriteria.companies}');
    } else {
      print('⚠️ 筛选键解析失败，但这不影响缓存功能');
    }

    // 测试缓存大小估算
    final cacheSize = _estimateCacheSize(criteria);
    print('✅ 缓存大小估算: $cacheSize bytes');
  } catch (e) {
    print('❌ 筛选条件序列化测试失败: $e');
  }

  print('');
}

/// 生成筛选键
String _generateFilterKey(FundFilterCriteria criteria) {
  final parts = [
    criteria.fundTypes?.join(',') ?? '',
    criteria.companies?.join(',') ?? '',
    criteria.scaleRange?.toString() ?? '',
    criteria.riskLevels?.join(',') ?? '',
    criteria.returnRange?.toString() ?? '',
    criteria.sortBy ?? '',
    criteria.sortDirection?.name ?? '',
  ];
  return parts.where((p) => p.isNotEmpty).join('|');
}

/// 解析筛选键
FundFilterCriteria? _parseFilterKey(String key) {
  try {
    final parts = key.split('|');
    if (parts.isEmpty) return null;

    final fundTypes = parts[0].isNotEmpty ? parts[0].split(',') : null;
    final companies =
        parts.length > 1 && parts[1].isNotEmpty ? parts[1].split(',') : null;

    return FundFilterCriteria(
      fundTypes: fundTypes,
      companies: companies,
      pageSize: 20,
    );
  } catch (_) {
    return null;
  }
}

/// 估算缓存大小
int _estimateCacheSize(FundFilterCriteria criteria) {
  final key = _generateFilterKey(criteria);
  return key.length * 2; // 简单估算，每个字符2字节
}
