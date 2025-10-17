import 'package:flutter_test/flutter_test.dart';
import 'package:jisu_fund_analyzer/src/features/fund/domain/entities/fund_filter_criteria.dart';

void main() {
  group('FundFilterCriteria', () {
    test('应该正确创建空的筛选条件', () {
      // Arrange & Act
      final criteria = FundFilterCriteria.empty();

      // Assert
      expect(criteria.fundTypes, isNull);
      expect(criteria.companies, isNull);
      expect(criteria.scaleRange, isNull);
      expect(criteria.establishmentDateRange, isNull);
      expect(criteria.riskLevels, isNull);
      expect(criteria.returnRange, isNull);
      expect(criteria.statuses, isNull);
      expect(criteria.sortBy, isNull);
      expect(criteria.sortDirection, isNull);
      expect(criteria.page, equals(1));
      expect(criteria.pageSize, equals(20));
      expect(criteria.hasAnyFilter, isFalse);
    });

    test('应该正确识别有筛选条件', () {
      // Arrange & Act
      const criteria = FundFilterCriteria(
        fundTypes: ['股票型', '混合型'],
        scaleRange: RangeValue(min: 10.0, max: 100.0),
      );

      // Assert
      expect(criteria.hasAnyFilter, isTrue);
      expect(criteria.hasFilterType(FilterType.fundType), isTrue);
      expect(criteria.hasFilterType(FilterType.company), isFalse);
      expect(criteria.hasFilterType(FilterType.scale), isTrue);
    });

    test('应该正确复制筛选条件', () {
      // Arrange
      const originalCriteria = FundFilterCriteria(
        fundTypes: ['股票型'],
        page: 1,
        pageSize: 10,
      );

      // Act
      final updatedCriteria = originalCriteria.copyWith(
        fundTypes: ['债券型'],
        page: 2,
      );

      // Assert
      expect(originalCriteria.fundTypes, equals(['股票型']));
      expect(originalCriteria.page, equals(1));
      expect(updatedCriteria.fundTypes, equals(['债券型']));
      expect(updatedCriteria.page, equals(2));
      expect(updatedCriteria.pageSize, equals(10)); // 保持不变
    });

    test('应该正确重置筛选条件', () {
      // Arrange
      const criteria = FundFilterCriteria(
        fundTypes: ['股票型'],
        companies: ['华夏基金'],
        scaleRange: RangeValue(min: 10.0, max: 100.0),
      );

      // Act
      final resetCriteria = criteria.reset();

      // Assert
      expect(resetCriteria.hasAnyFilter, isFalse);
      expect(resetCriteria.fundTypes, isNull);
      expect(resetCriteria.companies, isNull);
      expect(resetCriteria.scaleRange, isNull);
    });

    test('应该正确重置特定类型的筛选条件', () {
      // Arrange
      const criteria = FundFilterCriteria(
        fundTypes: ['股票型'],
        companies: ['华夏基金'],
        scaleRange: RangeValue(min: 10.0, max: 100.0),
      );

      // Act
      final resetCriteria = criteria.resetFilterType(FilterType.fundType);

      // Assert
      expect(resetCriteria.fundTypes, isNull);
      expect(resetCriteria.companies, equals(['华夏基金'])); // 保持不变
      expect(resetCriteria.scaleRange,
          const RangeValue(min: 10.0, max: 100.0)); // 保持不变
    });

    test('应该正确序列化为JSON', () {
      // Arrange
      const criteria = FundFilterCriteria(
        fundTypes: ['股票型', '混合型'],
        scaleRange: RangeValue(min: 10.0, max: 100.0),
        sortBy: 'return1Y',
        sortDirection: SortDirection.desc,
        page: 2,
        pageSize: 15,
      );

      // Act
      final json = criteria.toJson();

      // Assert
      expect(json['fundTypes'], equals(['股票型', '混合型']));
      expect(json['scaleRange'], equals({'min': 10.0, 'max': 100.0}));
      expect(json['sortBy'], equals('return1Y'));
      expect(json['sortDirection'], equals('desc'));
      expect(json['page'], equals(2));
      expect(json['pageSize'], equals(15));
    });

    test('应该正确从JSON创建筛选条件', () {
      // Arrange
      final json = {
        'fundTypes': ['股票型', '混合型'],
        'scaleRange': {'min': 10.0, 'max': 100.0},
        'sortBy': 'return1Y',
        'sortDirection': 'desc',
        'page': 2,
        'pageSize': 15,
      };

      // Act
      final criteria = FundFilterCriteria.fromJson(json);

      // Assert
      expect(criteria.fundTypes, equals(['股票型', '混合型']));
      expect(criteria.scaleRange, const RangeValue(min: 10.0, max: 100.0));
      expect(criteria.sortBy, equals('return1Y'));
      expect(criteria.sortDirection, SortDirection.desc);
      expect(criteria.page, equals(2));
      expect(criteria.pageSize, equals(15));
    });

    test('应该正确处理空的JSON', () {
      // Arrange
      final json = <String, dynamic>{};

      // Act
      final criteria = FundFilterCriteria.fromJson(json);

      // Assert
      expect(criteria.hasAnyFilter, isFalse);
      expect(criteria.page, equals(1));
      expect(criteria.pageSize, equals(20));
    });

    test('应该正确比较筛选条件', () {
      // Arrange
      const criteria1 = FundFilterCriteria(
        fundTypes: ['股票型'],
        page: 1,
      );

      const criteria2 = FundFilterCriteria(
        fundTypes: ['股票型'],
        page: 1,
      );

      const criteria3 = FundFilterCriteria(
        fundTypes: ['债券型'],
        page: 1,
      );

      // Assert
      expect(criteria1, equals(criteria2));
      expect(criteria1, isNot(equals(criteria3)));
    });

    test('应该正确生成字符串表示', () {
      // Arrange
      const criteria = FundFilterCriteria(
        fundTypes: ['股票型', '混合型'],
        scaleRange: RangeValue(min: 10.0, max: 100.0),
        riskLevels: ['中风险'],
      );

      // Act
      final description = criteria.toString();

      // Assert
      expect(description, contains('类型: 股票型, 混合型'));
      expect(description, contains('规模: 10.0-100.0亿'));
      expect(description, contains('风险: 中风险'));
    });

    test('应该正确生成空筛选条件的字符串表示', () {
      // Arrange & Act
      final description = FundFilterCriteria.empty().toString();

      // Assert
      expect(description, equals('无筛选条件'));
    });
  });

  group('RangeValue', () {
    test('应该正确创建范围值', () {
      // Arrange & Act
      const range = RangeValue(min: 10.0, max: 100.0);

      // Assert
      expect(range.min, equals(10.0));
      expect(range.max, equals(100.0));
    });

    test('应该正确检查数值是否在范围内', () {
      // Arrange
      const range = RangeValue(min: 10.0, max: 100.0);

      // Act & Assert
      expect(range.contains(5.0), isFalse); // 小于最小值
      expect(range.contains(10.0), isTrue); // 等于最小值
      expect(range.contains(50.0), isTrue); // 在范围内
      expect(range.contains(100.0), isTrue); // 等于最大值
      expect(range.contains(150.0), isFalse); // 大于最大值
    });

    test('应该正确序列化和反序列化', () {
      // Arrange
      const original = RangeValue(min: 10.5, max: 99.5);

      // Act
      final json = original.toJson();
      final restored = RangeValue.fromJson(json);

      // Assert
      expect(restored, equals(original));
    });

    test('应该正确生成字符串表示', () {
      // Arrange & Act
      final description = const RangeValue(min: 10.0, max: 100.0).toString();

      // Assert
      expect(description, equals('10.0-100.0'));
    });
  });

  group('DateRange', () {
    test('应该正确创建日期范围', () {
      // Arrange
      final start = DateTime(2020, 1, 1);
      final end = DateTime(2023, 12, 31);

      // Act
      final range = DateRange(start: start, end: end);

      // Assert
      expect(range.start, equals(start));
      expect(range.end, equals(end));
    });

    test('应该正确检查日期是否在范围内', () {
      // Arrange
      final start = DateTime(2020, 1, 1);
      final end = DateTime(2023, 12, 31);
      final range = DateRange(start: start, end: end);

      // Act & Assert
      expect(range.contains(DateTime(2019, 12, 31)), isFalse); // 早于开始日期
      expect(range.contains(DateTime(2020, 1, 1)), isTrue); // 等于开始日期
      expect(range.contains(DateTime(2021, 6, 15)), isTrue); // 在范围内
      expect(range.contains(DateTime(2023, 12, 31)), isTrue); // 等于结束日期
      expect(range.contains(DateTime(2024, 1, 1)), isFalse); // 晚于结束日期
    });

    test('应该正确序列化和反序列化', () {
      // Arrange
      final start = DateTime(2020, 1, 1);
      final end = DateTime(2023, 12, 31);
      final original = DateRange(start: start, end: end);

      // Act
      final json = original.toJson();
      final restored = DateRange.fromJson(json);

      // Assert
      expect(restored, equals(original));
    });

    test('应该正确生成字符串表示', () {
      // Arrange
      final start = DateTime(2020, 1, 1);
      final end = DateTime(2023, 12, 31);
      final range = DateRange(start: start, end: end);

      // Act
      final description = range.toString();

      // Assert
      expect(description, equals('2020-01-01 - 2023-12-31'));
    });
  });

  group('FilterType', () {
    test('应该正确获取显示名称', () {
      expect(FilterType.fundType.displayName, equals('基金类型'));
      expect(FilterType.company.displayName, equals('管理公司'));
      expect(FilterType.scale.displayName, equals('基金规模'));
      expect(FilterType.establishmentDate.displayName, equals('成立时间'));
      expect(FilterType.riskLevel.displayName, equals('风险等级'));
      expect(FilterType.returnRate.displayName, equals('收益率'));
      expect(FilterType.status.displayName, equals('基金状态'));
    });

    test('应该正确转换为字符串', () {
      expect(FilterType.fundType.toString(), equals('基金类型'));
      expect(FilterType.company.toString(), equals('管理公司'));
    });
  });

  group('SortDirection', () {
    test('应该正确获取显示名称', () {
      expect(SortDirection.asc.displayName, equals('升序'));
      expect(SortDirection.desc.displayName, equals('降序'));
    });

    test('应该正确转换为字符串', () {
      expect(SortDirection.asc.toString(), equals('升序'));
      expect(SortDirection.desc.toString(), equals('降序'));
    });
  });

  group('边界条件和错误处理', () {
    test('RangeValue构造函数应该拒绝无效范围', () {
      // Arrange & Act & Assert
      expect(
        () => RangeValue(min: 100.0, max: 10.0),
        throwsAssertionError,
      );
    });

    test('DateRange构造函数应该拒绝无效日期范围', () {
      // Arrange
      final start = DateTime(2023, 12, 31);
      final end = DateTime(2020, 1, 1);

      // Act & Assert
      expect(
        () => DateRange(start: start, end: end),
        throwsAssertionError,
      );
    });

    test('应该处理相等边界日期', () {
      // Arrange
      final date = DateTime(2023, 6, 15);
      final range = DateRange(start: date, end: date);

      // Act & Assert
      expect(range.contains(date), isTrue);
    });

    test('应该处理范围值中的负数', () {
      // Arrange & Act
      const range = RangeValue(min: -100.0, max: 50.0);

      // Assert
      expect(range.contains(-50.0), isTrue);
      expect(range.contains(0.0), isTrue);
      expect(range.contains(50.0), isTrue);
      expect(range.contains(100.0), isFalse);
    });
  });
}
