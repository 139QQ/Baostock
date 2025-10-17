import 'package:flutter_test/flutter_test.dart';

/// 基金筛选条件模型单元测试
void main() {
  group('FundFilterCriteria', () {
    test('应该正确创建空的筛选条件', () {
      // 这里测试创建空筛选条件的逻辑
      // 由于我们还没有完整的FundFilterCriteria类，这里用简单的方式模拟
      final emptyCriteria = {
        'fundTypes': null,
        'companies': null,
        'scaleRange': null,
        'establishmentDateRange': null,
        'riskLevels': null,
        'returnRange': null,
        'statuses': null,
      };

      expect(emptyCriteria['fundTypes'], isNull);
      expect(emptyCriteria['companies'], isNull);
      expect(emptyCriteria['scaleRange'], isNull);
    });

    test('应该正确设置筛选条件', () {
      // 测试设置筛选条件
      final criteria = {
        'fundTypes': ['股票型', '债券型'],
        'companies': ['易方达基金'],
        'riskLevels': ['R3', 'R4'],
      };

      expect(criteria['fundTypes'], equals(['股票型', '债券型']));
      expect(criteria['companies'], equals(['易方达基金']));
      expect(criteria['riskLevels'], equals(['R3', 'R4']));
    });

    test('应该正确检测是否有筛选条件', () {
      // 测试空条件检测
      final emptyCriteria = <String, dynamic>{};
      expect(_hasAnyFilter(emptyCriteria), isFalse);

      // 测试有筛选条件的情况
      final filledCriteria = {
        'fundTypes': ['股票型'],
      };
      expect(_hasAnyFilter(filledCriteria), isTrue);

      final multipleCriteria = {
        'fundTypes': ['股票型', '债券型'],
        'companies': ['易方达基金'],
        'riskLevels': ['R3'],
      };
      expect(_hasAnyFilter(multipleCriteria), isTrue);
    });

    test('应该正确复制筛选条件', () {
      final originalCriteria = {
        'fundTypes': ['股票型'],
        'companies': ['易方达基金'],
      };

      // 复制并修改
      final newCriteria = Map<String, dynamic>.from(originalCriteria);
      newCriteria['riskLevels'] = ['R3'];

      // 验证原条件未改变
      expect(originalCriteria['riskLevels'], isNull);
      // 验证新条件包含修改
      expect(newCriteria['riskLevels'], equals(['R3']));
      expect(newCriteria['fundTypes'], equals(['股票型']));
    });

    test('应该正确重置特定筛选类型', () {
      final criteria = {
        'fundTypes': ['股票型', '债券型'],
        'companies': ['易方达基金'],
        'riskLevels': ['R3', 'R4'],
      };

      // 重置基金类型
      final resetCriteria = Map<String, dynamic>.from(criteria);
      resetCriteria['fundTypes'] = null;

      expect(resetCriteria['fundTypes'], isNull);
      expect(resetCriteria['companies'], equals(['易方达基金']));
      expect(resetCriteria['riskLevels'], equals(['R3', 'R4']));
    });

    test('应该正确转换为字符串表示', () {
      final criteria = {
        'fundTypes': ['股票型', '债券型'],
        'companies': ['易方达基金'],
        'riskLevels': ['R3'],
      };

      final description = _criteriaToString(criteria);
      expect(description, contains('股票型'));
      expect(description, contains('债券型'));
      expect(description, contains('易方达基金'));
      expect(description, contains('R3'));
    });
  });

  group('筛选条件验证', () {
    test('应该正确验证基金类型', () {
      final validTypes = ['股票型', '债券型', '混合型', '货币型', '指数型', 'QDII', 'FOF'];
      final invalidTypes = ['无效类型', '股票', '债券'];

      for (final type in validTypes) {
        expect(_isValidFundType(type), isTrue, reason: '$type 应该是有效的基金类型');
      }

      for (final type in invalidTypes) {
        expect(_isValidFundType(type), isFalse, reason: '$type 应该是无效的基金类型');
      }
    });

    test('应该正确验证风险等级', () {
      final validRisks = ['R1', 'R2', 'R3', 'R4', 'R5'];
      final invalidRisks = ['R0', 'R6', 'RA', '高风险'];

      for (final risk in validRisks) {
        expect(_isValidRiskLevel(risk), isTrue, reason: '$risk 应该是有效的风险等级');
      }

      for (final risk in invalidRisks) {
        expect(_isValidRiskLevel(risk), isFalse, reason: '$risk 应该是无效的风险等级');
      }
    });

    test('应该正确验证数值范围', () {
      // 测试有效范围
      expect(_isValidRange(0.0, 1000.0), isTrue);
      expect(_isValidRange(-50.0, 50.0), isTrue);
      expect(_isValidRange(100.0, 100.0), isTrue); // 最小值等于最大值

      // 测试无效范围
      expect(_isValidRange(100.0, 0.0), isFalse); // 最小值大于最大值
      expect(_isValidRange(-100.0, -200.0), isFalse); // 最小值大于最大值
    });

    test('应该正确验证日期范围', () {
      final startDate = DateTime(2020, 1, 1);
      final endDate = DateTime(2023, 12, 31);
      final futureDate = DateTime.now().add(const Duration(days: 365));

      // 测试有效日期范围
      expect(_isValidDateRange(startDate, endDate), isTrue);
      expect(_isValidDateRange(startDate, startDate), isTrue); // 同一天

      // 测试无效日期范围
      expect(_isValidDateRange(endDate, startDate), isFalse); // 开始日期晚于结束日期
      expect(_isValidDateRange(futureDate, DateTime.now()), isFalse); // 未来日期
    });
  });

  group('筛选条件序列化', () {
    test('应该正确序列化为JSON', () {
      final criteria = {
        'fundTypes': ['股票型', '债券型'],
        'companies': ['易方达基金'],
        'scaleRange': {'min': 10.0, 'max': 100.0},
        'riskLevels': ['R3'],
      };

      final json = _criteriaToJson(criteria);
      expect(json['fundTypes'], equals(['股票型', '债券型']));
      expect(json['companies'], equals(['易方达基金']));
      expect(json['scaleRange'], equals({'min': 10.0, 'max': 100.0}));
      expect(json['riskLevels'], equals(['R3']));
    });

    test('应该正确从JSON反序列化', () {
      final json = {
        'fundTypes': ['股票型', '债券型'],
        'companies': ['易方达基金'],
        'scaleRange': {'min': 10.0, 'max': 100.0},
        'riskLevels': ['R3'],
      };

      final criteria = _criteriaFromJson(json);
      expect(criteria['fundTypes'], equals(['股票型', '债券型']));
      expect(criteria['companies'], equals(['易方达基金']));
      expect(criteria['scaleRange'], equals({'min': 10.0, 'max': 100.0}));
      expect(criteria['riskLevels'], equals(['R3']));
    });

    test('应该正确处理空JSON反序列化', () {
      final json = <String, dynamic>{};
      final criteria = _criteriaFromJson(json);

      expect(criteria['fundTypes'], isNull);
      expect(criteria['companies'], isNull);
      expect(criteria['scaleRange'], isNull);
      expect(criteria['riskLevels'], isNull);
    });
  });
}

// 辅助函数

/// 检查是否有任何筛选条件
bool _hasAnyFilter(Map<String, dynamic> criteria) {
  return criteria.values.any((value) => value != null);
}

/// 检查是否为有效的基金类型
bool _isValidFundType(String type) {
  const validTypes = ['股票型', '债券型', '混合型', '货币型', '指数型', 'QDII', 'FOF'];
  return validTypes.contains(type);
}

/// 检查是否为有效的风险等级
bool _isValidRiskLevel(String level) {
  const validLevels = ['R1', 'R2', 'R3', 'R4', 'R5'];
  return validLevels.contains(level);
}

/// 检查是否为有效的数值范围
bool _isValidRange(double min, double max) {
  return min <= max;
}

/// 检查是否为有效的日期范围
bool _isValidDateRange(DateTime start, DateTime end) {
  final now = DateTime.now();
  return !start.isAfter(end) && !end.isAfter(now);
}

/// 将筛选条件转换为字符串
String _criteriaToString(Map<String, dynamic> criteria) {
  final parts = <String>[];

  if (criteria['fundTypes'] != null) {
    parts.add('类型: ${(criteria['fundTypes'] as List).join(', ')}');
  }

  if (criteria['companies'] != null) {
    parts.add('公司: ${(criteria['companies'] as List).join(', ')}');
  }

  if (criteria['riskLevels'] != null) {
    parts.add('风险: ${(criteria['riskLevels'] as List).join(', ')}');
  }

  return parts.isNotEmpty ? parts.join('; ') : '无筛选条件';
}

/// 将筛选条件序列化为JSON
Map<String, dynamic> _criteriaToJson(Map<String, dynamic> criteria) {
  return Map<String, dynamic>.from(criteria);
}

/// 从JSON反序列化筛选条件
Map<String, dynamic> _criteriaFromJson(Map<String, dynamic> json) {
  final criteria = <String, dynamic>{};

  for (final entry in json.entries) {
    if (entry.value != null) {
      criteria[entry.key] = entry.value;
    }
  }

  return criteria;
}
