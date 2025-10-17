import '../entities/fund.dart';
import '../entities/fund_filter_criteria.dart';
import '../repositories/fund_repository.dart';

/// 基金筛选用例类
///
/// 负责处理基金筛选的业务逻辑，包括：
/// - 多维度条件筛选
/// - 组合逻辑处理（AND/OR）
/// - 性能优化（分页、缓存）
/// - 筛选结果排序
///
/// 时间复杂度: O(n) 其中n是基金总数
/// 空间复杂度: O(m) 其中m是符合条件的基金数量
class FundFilterUseCase {
  final FundRepository _repository;

  FundFilterUseCase(this._repository);

  /// 根据筛选条件获取基金列表
  ///
  /// [criteria] 筛选条件对象
  /// 返回符合条件的基金列表，支持分页
  Future<FundFilterResult> execute(FundFilterCriteria criteria) async {
    try {
      // 验证筛选条件
      _validateCriteria(criteria);

      // 获取所有基金
      final allFunds = await _repository.getFundList();

      // 应用筛选逻辑
      final filteredFunds = await _applyFilters(allFunds, criteria);

      // 应用排序
      final sortedFunds = _applySorting(filteredFunds, criteria);

      // 应用分页
      final paginatedFunds = _applyPagination(sortedFunds, criteria);

      // 获取总数
      final totalCount = criteria.hasAnyFilter
          ? await _repository.getFilteredFundsCount(criteria)
          : allFunds.length;

      return FundFilterResult(
        funds: paginatedFunds,
        totalCount: totalCount,
        hasMore: _hasMore(criteria, totalCount),
        criteria: criteria,
      );
    } catch (e) {
      throw FundFilterException('筛选基金时发生错误: ${e.toString()}');
    }
  }

  /// 直接筛选基金数据（用于性能测试）
  ///
  /// [funds] 基金数据列表
  /// [criteria] 筛选条件对象
  /// 返回筛选结果，包含筛选后的基金列表和分页数据
  Future<FundFilterResult> filterFunds(
      List<Fund> funds, FundFilterCriteria criteria) async {
    try {
      // 验证筛选条件
      _validateCriteria(criteria);

      // 应用筛选逻辑
      final filteredFunds = await _applyFilters(funds, criteria);

      // 应用排序
      final sortedFunds = _applySorting(filteredFunds, criteria);

      // 应用分页
      final paginatedFunds = _applyPagination(sortedFunds, criteria);

      return FundFilterResult.withPagination(
        filteredFunds: filteredFunds,
        paginatedFunds: paginatedFunds,
        totalCount: filteredFunds.length,
        hasMore: _hasMore(criteria, filteredFunds.length),
        criteria: criteria,
      );
    } catch (e) {
      throw FundFilterException('筛选基金时发生错误: ${e.toString()}');
    }
  }

  /// 获取筛选选项列表
  ///
  /// [type] 筛选类型
  /// 返回该类型的所有可用选项
  Future<List<String>> getFilterOptions(FilterType type) async {
    try {
      return await _repository.getFilterOptions(type);
    } catch (e) {
      throw FundFilterException('获取筛选选项时发生错误: ${e.toString()}');
    }
  }

  /// 验证筛选条件
  void _validateCriteria(FundFilterCriteria criteria) {
    if (criteria.page < 1) {
      throw FundFilterException('页码必须大于0');
    }
    if (criteria.pageSize < 1 || criteria.pageSize > 100) {
      throw FundFilterException('每页数量必须在1-100之间');
    }
    if (criteria.scaleRange != null) {
      if (criteria.scaleRange!.min < 0 || criteria.scaleRange!.max < 0) {
        throw FundFilterException('基金规模不能为负数');
      }
    }
    if (criteria.returnRange != null) {
      if (criteria.returnRange!.min < -100 ||
          criteria.returnRange!.max > 1000) {
        throw FundFilterException('收益率范围不合理');
      }
    }
  }

  /// 应用筛选条件
  Future<List<Fund>> _applyFilters(
      List<Fund> funds, FundFilterCriteria criteria) async {
    if (!criteria.hasAnyFilter) {
      return funds;
    }

    List<Fund> filteredFunds = List.from(funds);

    // 基金类型筛选（精确匹配）
    if (criteria.fundTypes?.isNotEmpty == true) {
      filteredFunds = filteredFunds
          .where((fund) => criteria.fundTypes!.contains(fund.type))
          .toList();
    }

    // 管理公司筛选（精确匹配）
    if (criteria.companies?.isNotEmpty == true) {
      filteredFunds = filteredFunds
          .where((fund) => criteria.companies!.contains(fund.company))
          .toList();
    }

    // 基金规模筛选（范围筛选）
    if (criteria.scaleRange != null) {
      filteredFunds = filteredFunds
          .where((fund) => criteria.scaleRange!.contains(fund.scale))
          .toList();
    }

    // 成立时间筛选（范围筛选）
    if (criteria.establishmentDateRange != null) {
      filteredFunds = filteredFunds
          .where((fund) =>
              _parseEstablishmentDate(fund.date) != null &&
              criteria.establishmentDateRange!
                  .contains(_parseEstablishmentDate(fund.date)!))
          .toList();
    }

    // 风险等级筛选（精确匹配）
    if (criteria.riskLevels?.isNotEmpty == true) {
      filteredFunds = filteredFunds
          .where((fund) => criteria.riskLevels!.contains(fund.riskLevel))
          .toList();
    }

    // 收益率筛选（范围筛选）
    if (criteria.returnRange != null) {
      filteredFunds = filteredFunds
          .where((fund) => criteria.returnRange!.contains(fund.return1Y))
          .toList();
    }

    // 基金状态筛选（精确匹配）
    if (criteria.statuses?.isNotEmpty == true) {
      filteredFunds = filteredFunds
          .where((fund) => criteria.statuses!.contains(fund.status))
          .toList();
    }

    return filteredFunds;
  }

  /// 应用排序
  List<Fund> _applySorting(List<Fund> funds, FundFilterCriteria criteria) {
    if (criteria.sortBy == null || criteria.sortBy!.isEmpty) {
      return funds;
    }

    final sortBy = criteria.sortBy!;
    final direction = criteria.sortDirection ?? SortDirection.asc;

    List<Fund> sortedFunds = List.from(funds);

    switch (sortBy.toLowerCase()) {
      case 'name':
      case '名称':
        sortedFunds.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'code':
      case '代码':
        sortedFunds.sort((a, b) => a.code.compareTo(b.code));
        break;
      case 'type':
      case '类型':
        sortedFunds.sort((a, b) => a.type.compareTo(b.type));
        break;
      case 'company':
      case '管理公司':
        sortedFunds.sort((a, b) => a.company.compareTo(b.company));
        break;
      case 'scale':
      case '规模':
        sortedFunds.sort((a, b) => a.scale.compareTo(b.scale));
        break;
      case 'return1y':
      case '近1年':
        sortedFunds.sort((a, b) => a.return1Y.compareTo(b.return1Y));
        break;
      case 'return3y':
      case '近3年':
        sortedFunds.sort((a, b) => a.return3Y.compareTo(b.return3Y));
        break;
      case 'dailyreturn':
      case '日收益率':
        sortedFunds.sort((a, b) => a.dailyReturn.compareTo(b.dailyReturn));
        break;
      case 'risklevel':
      case '风险等级':
        sortedFunds.sort((a, b) => a.riskLevel.compareTo(b.riskLevel));
        break;
      default:
        // 默认按名称排序
        sortedFunds.sort((a, b) => a.name.compareTo(b.name));
    }

    // 应用排序方向
    if (direction == SortDirection.desc) {
      sortedFunds = sortedFunds.reversed.toList();
    }

    return sortedFunds;
  }

  /// 应用分页
  List<Fund> _applyPagination(List<Fund> funds, FundFilterCriteria criteria) {
    final startIndex = (criteria.page - 1) * criteria.pageSize;
    final endIndex = startIndex + criteria.pageSize;

    if (startIndex >= funds.length) {
      return [];
    }

    if (endIndex > funds.length) {
      return funds.sublist(startIndex);
    }

    return funds.sublist(startIndex, endIndex);
  }

  /// 检查是否还有更多数据
  bool _hasMore(FundFilterCriteria criteria, int totalCount) {
    final currentPageEnd = criteria.page * criteria.pageSize;
    return currentPageEnd < totalCount;
  }

  /// 解析成立日期
  DateTime? _parseEstablishmentDate(String dateStr) {
    if (dateStr.isEmpty) return null;

    try {
      try {
        final parts = dateStr.split(RegExp(r'[-/]'));
        if (parts.length >= 2) {
          final year = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final day = parts.length > 2 ? int.parse(parts[2]) : 1;
          return DateTime(year, month, day);
        }
      } catch (_) {
        return null;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  /// 预加载常用筛选组合
  Future<Map<String, FundFilterCriteria>> getCommonFilterPresets() async {
    return {
      '高收益基金': const FundFilterCriteria(
        returnRange: RangeValue(min: 10.0, max: 100.0),
        sortBy: 'return1Y',
        sortDirection: SortDirection.desc,
      ),
      '大规模基金': const FundFilterCriteria(
        scaleRange: RangeValue(min: 50.0, max: 1000.0),
        sortBy: 'scale',
        sortDirection: SortDirection.desc,
      ),
      '低风险基金': const FundFilterCriteria(
        riskLevels: ['低风险', '中低风险'],
        sortBy: 'riskLevel',
        sortDirection: SortDirection.asc,
      ),
      '股票型基金': const FundFilterCriteria(
        fundTypes: ['股票型', '混合型'],
        sortBy: 'return1Y',
        sortDirection: SortDirection.desc,
      ),
      '债券型基金': const FundFilterCriteria(
        fundTypes: ['债券型', '货币型'],
        sortBy: 'return1Y',
        sortDirection: SortDirection.desc,
      ),
    };
  }

  /// 验证筛选条件组合的合理性
  bool validateFilterCombination(FundFilterCriteria criteria) {
    // 检查是否有矛盾的筛选条件
    if (criteria.returnRange != null &&
        criteria.returnRange!.min > criteria.returnRange!.max) {
      return false;
    }
    if (criteria.scaleRange != null &&
        criteria.scaleRange!.min > criteria.scaleRange!.max) {
      return false;
    }
    if (criteria.establishmentDateRange != null &&
        criteria.establishmentDateRange!.start
            .isAfter(criteria.establishmentDateRange!.end)) {
      return false;
    }

    return true;
  }

  /// 获取筛选条件统计信息
  Future<FilterStatistics> getFilterStatistics(
      FundFilterCriteria criteria) async {
    try {
      final allFunds = await _repository.getFundList();
      final filteredFunds = await _applyFilters(allFunds, criteria);

      // 计算统计信息
      final totalFunds = allFunds.length;
      final filteredCount = filteredFunds.length;
      final filterRatio = totalFunds > 0 ? filteredCount / totalFunds : 0.0;

      // 计算平均收益
      final avgReturn = filteredFunds.isNotEmpty
          ? filteredFunds.map((f) => f.return1Y).reduce((a, b) => a + b) /
              filteredFunds.length
          : 0.0;

      // 计算平均规模
      final avgScale = filteredFunds.isNotEmpty
          ? filteredFunds.map((f) => f.scale).reduce((a, b) => a + b) /
              filteredFunds.length
          : 0.0;

      return FilterStatistics(
        totalFunds: totalFunds,
        filteredFunds: filteredCount,
        filterRatio: filterRatio,
        averageReturn: avgReturn,
        averageScale: avgScale,
        criteria: criteria,
      );
    } catch (e) {
      throw FundFilterException('获取筛选统计信息时发生错误: ${e.toString()}');
    }
  }
}

/// 基金筛选结果
class FundFilterResult {
  final List<Fund> funds;
  final List<Fund> filteredFunds;
  final List<Fund> paginatedFunds;
  final int totalCount;
  final bool hasMore;
  final FundFilterCriteria criteria;

  FundFilterResult({
    required this.funds,
    required this.totalCount,
    required this.hasMore,
    required this.criteria,
  })  : filteredFunds = funds,
        paginatedFunds = funds;

  // 便捷构造函数，用于直接传入分页后的基金列表
  FundFilterResult.withPagination({
    required this.filteredFunds,
    required this.paginatedFunds,
    required this.totalCount,
    required this.hasMore,
    required this.criteria,
  }) : funds = paginatedFunds;

  @override
  String toString() =>
      'FundFilterResult(funds: ${funds.length}, totalCount: $totalCount, hasMore: $hasMore)';
}

/// 筛选统计信息
class FilterStatistics {
  final int totalFunds;
  final int filteredFunds;
  final double filterRatio;
  final double averageReturn;
  final double averageScale;
  final FundFilterCriteria criteria;

  FilterStatistics({
    required this.totalFunds,
    required this.filteredFunds,
    required this.filterRatio,
    required this.averageReturn,
    required this.averageScale,
    required this.criteria,
  });

  @override
  String toString() =>
      'FilterStatistics(total: $totalFunds, filtered: $filteredFunds, ratio: ${(filterRatio * 100).toStringAsFixed(1)}%)';
}

/// 基金筛选异常
class FundFilterException implements Exception {
  final String message;

  FundFilterException(this.message);

  @override
  String toString() => 'FundFilterException: $message';
}
