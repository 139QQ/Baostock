import 'dart:math' as math;
import 'dart:math';

import '../entities/fund.dart';
import '../entities/fund_filter_criteria.dart';
import '../entities/fund_search_criteria.dart';
import '../entities/fund_ranking.dart';
import '../entities/ranking_statistics.dart';
import '../entities/hot_ranking_type.dart';
import '../usecases/fund_filter_usecase.dart';
import '../repositories/fund_repository.dart';
import '../../data/datasources/fund_remote_data_source.dart';
import '../../data/datasources/fund_local_data_source.dart';
import '../../data/services/search_cache_service.dart';
import '../../../../core/utils/logger.dart';

/// 基金仓库实现类
class FundRepositoryImpl implements FundRepository {
  final FundRemoteDataSource remoteDataSource;
  final FundLocalDataSource localDataSource;
  final FundFilterUseCase? filterUseCase;
  final SearchCacheService? searchCacheService;
  final bool enableCache;
  final Duration cacheTimeout;

  FundRepositoryImpl(
    this.remoteDataSource,
    this.localDataSource, {
    this.filterUseCase,
    this.searchCacheService,
    this.enableCache = true,
    this.cacheTimeout = const Duration(minutes: 15),
  });

  @override
  Future<List<Fund>> getFundList() async {
    try {
      // 如果启用缓存且缓存有效，先从缓存获取
      if (enableCache &&
          await localDataSource.isCacheValid(maxAge: cacheTimeout)) {
        final cachedFunds = await localDataSource.getCachedFundList();
        if (cachedFunds.isNotEmpty) {
          return cachedFunds;
        }
      }

      // 从远程数据源获取数据
      final explorationFunds = await remoteDataSource.getFundList();
      final funds = explorationFunds.map(_convertToFundEntity).toList();

      // 缓存数据
      if (enableCache && funds.isNotEmpty) {
        await localDataSource.cacheFundList(funds);
      }

      return funds;
    } catch (e) {
      // 如果远程获取失败，尝试使用过期缓存
      if (enableCache) {
        try {
          final cachedFunds = await localDataSource.getCachedFundList();
          if (cachedFunds.isNotEmpty) {
            return cachedFunds;
          }
        } catch (_) {
          // 缓存也失败，抛出原始错误
        }
      }
      throw Exception('获取基金列表失败: $e');
    }
  }

  @override
  Future<List<Fund>> getFilteredFunds(FundFilterCriteria criteria) async {
    try {
      // 如果没有筛选条件，返回所有基金
      if (!criteria.hasAnyFilter) {
        return await getFundList();
      }

      // 如果启用缓存，先尝试从缓存获取筛选结果
      if (enableCache) {
        try {
          final cachedResults =
              await localDataSource.getCachedFilteredFunds(criteria);
          if (cachedResults.isNotEmpty) {
            return cachedResults;
          }
        } catch (_) {
          // 缓存获取失败，继续进行筛选
        }
      }

      // 获取所有基金数据进行筛选
      final allFunds = await getFundList();

      // 使用筛选用例进行筛选
      List<Fund> filteredFunds;
      if (filterUseCase != null) {
        final result = await filterUseCase!.execute(criteria);
        filteredFunds = result.funds;
      } else {
        // 如果没有筛选用例，进行基本的客户端筛选
        filteredFunds = _basicFilter(allFunds, criteria);
      }

      // 缓存筛选结果
      if (enableCache && filteredFunds.isNotEmpty) {
        await localDataSource.cacheFilteredFunds(criteria, filteredFunds);
      }

      return filteredFunds;
    } catch (e) {
      // 如果筛选失败，尝试使用缓存的筛选结果
      if (enableCache) {
        try {
          final cachedResults =
              await localDataSource.getCachedFilteredFunds(criteria);
          if (cachedResults.isNotEmpty) {
            return cachedResults;
          }
        } catch (_) {
          // 缓存也失败，抛出原始错误
        }
      }
      throw Exception('筛选基金失败: $e');
    }
  }

  @override
  Future<int> getFilteredFundsCount(FundFilterCriteria criteria) async {
    try {
      // 如果没有筛选条件，返回所有基金数量
      if (!criteria.hasAnyFilter) {
        final allFunds = await getFundList();
        return allFunds.length;
      }

      // 如果启用缓存，先尝试从缓存获取数量
      if (enableCache) {
        try {
          final cachedCount =
              await localDataSource.getCachedFilteredFundsCount(criteria);
          if (cachedCount != null) {
            return cachedCount;
          }
        } catch (_) {
          // 缓存获取失败，继续计算
        }
      }

      // 获取筛选结果并计算数量
      final filteredFunds = await getFilteredFunds(criteria);

      // 缓存数量结果
      if (enableCache) {
        await localDataSource.cacheFilteredFundsCount(
            criteria, filteredFunds.length);
      }

      return filteredFunds.length;
    } catch (e) {
      // 如果计算失败，尝试使用缓存的数量
      if (enableCache) {
        try {
          final cachedCount =
              await localDataSource.getCachedFilteredFundsCount(criteria);
          if (cachedCount != null) {
            return cachedCount;
          }
        } catch (_) {
          // 缓存也失败，抛出原始错误
        }
      }
      throw Exception('获取筛选基金数量失败: $e');
    }
  }

  @override
  Future<List<String>> getFilterOptions(FilterType type) async {
    try {
      // 如果启用缓存，先尝试从缓存获取筛选选项
      if (enableCache) {
        try {
          final cachedOptions =
              await localDataSource.getCachedFilterOptions(type);
          if (cachedOptions != null && cachedOptions.isNotEmpty) {
            return cachedOptions;
          }
        } catch (_) {
          // 缓存获取失败，继续计算
        }
      }

      // 获取所有基金并计算选项
      final allFunds = await getFundList();
      List<String> options;

      switch (type) {
        case FilterType.fundType:
          options = allFunds
              .map((fund) => fund.type)
              .where((type) => type.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
          break;
        case FilterType.company:
          options = allFunds
              .map((fund) => fund.company)
              .where((company) => company.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
          break;
        case FilterType.riskLevel:
          options = allFunds
              .map((fund) => fund.riskLevel)
              .where((risk) => risk.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
          break;
        case FilterType.status:
          options = allFunds
              .map((fund) => fund.status)
              .where((status) => status.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
          break;
        case FilterType.scale:
        case FilterType.establishmentDate:
        case FilterType.returnRate:
          // 这些类型需要范围选择，返回空列表
          options = [];
          break;
      }

      // 缓存筛选选项
      if (enableCache && options.isNotEmpty) {
        await localDataSource.cacheFilterOptions(type, options);
      }

      return options;
    } catch (e) {
      // 如果计算失败，尝试使用缓存的选项
      if (enableCache) {
        try {
          final cachedOptions =
              await localDataSource.getCachedFilterOptions(type);
          if (cachedOptions != null) {
            return cachedOptions;
          }
        } catch (_) {
          // 缓存也失败，抛出原始错误
        }
      }
      throw Exception('获取筛选选项失败: $e');
    }
  }

  /// 基本的客户端筛选实现
  List<Fund> _basicFilter(List<Fund> funds, FundFilterCriteria criteria) {
    return funds.where((fund) {
      // 基金类型筛选
      if (criteria.fundTypes?.isNotEmpty == true) {
        if (!criteria.fundTypes!.contains(fund.type)) return false;
      }

      // 管理公司筛选
      if (criteria.companies?.isNotEmpty == true) {
        if (!criteria.companies!.contains(fund.company)) return false;
      }

      // 基金规模筛选
      if (criteria.scaleRange != null) {
        if (!criteria.scaleRange!.contains(fund.scale)) return false;
      }

      // 风险等级筛选
      if (criteria.riskLevels?.isNotEmpty == true) {
        if (!criteria.riskLevels!.contains(fund.riskLevel)) return false;
      }

      // 基金状态筛选
      if (criteria.statuses?.isNotEmpty == true) {
        if (!criteria.statuses!.contains(fund.status)) return false;
      }

      // 收益率筛选
      if (criteria.returnRange != null) {
        if (!criteria.returnRange!.contains(fund.return1Y)) return false;
      }

      return true;
    }).toList();
  }

  /// 将fund_exploration的Fund模型转换为fund模块的Fund实体
  Fund _convertToFundEntity(dynamic explorationFund) {
    return Fund(
      code: explorationFund.code.toString(),
      name: explorationFund.name.toString(),
      type: explorationFund.type.toString(),
      company: explorationFund.company.toString(),
      manager: explorationFund.manager?.toString() ?? '',
      unitNav: (explorationFund.unitNav ?? 0.0).toDouble(),
      accumulatedNav: (explorationFund.accumulatedNav ?? 0.0).toDouble(),
      dailyReturn: (explorationFund.dailyReturn ?? 0.0).toDouble(),
      return1W: (explorationFund.return1W ?? 0.0).toDouble(),
      return1M: (explorationFund.return1M ?? 0.0).toDouble(),
      return3M: (explorationFund.return3M ?? 0.0).toDouble(),
      return6M: (explorationFund.return6M ?? 0.0).toDouble(),
      return1Y: (explorationFund.return1Y ?? 0.0).toDouble(),
      return2Y: 0.0, // explorationFund模型中没有此字段
      return3Y: (explorationFund.return3Y ?? 0.0).toDouble(),
      returnYTD: (explorationFund.returnYTD ?? 0.0).toDouble(),
      returnSinceInception:
          (explorationFund.returnSinceInception ?? 0.0).toDouble(),
      scale: (explorationFund.scale ?? 0.0).toDouble(),
      riskLevel: explorationFund.riskLevel?.toString() ?? '',
      status: explorationFund.status?.toString() ?? 'active',
      date: '', // explorationFund模型中没有此字段
      fee: 0.0, // explorationFund模型中没有此字段
      rankingPosition: 0, // explorationFund模型中没有此字段
      totalCount: 0, // explorationFund模型中没有此字段
      currentPrice: 0.0, // explorationFund模型中没有此字段
      dailyChange: 0.0, // explorationFund模型中没有此字段
      dailyChangePercent: 0.0, // explorationFund模型中没有此字段
      lastUpdate: DateTime.now(),
    );
  }

  // ===== 搜索功能实现 =====

  @override
  Future<List<Fund>> searchFunds(FundSearchCriteria criteria) async {
    try {
      // 如果搜索条件为空，返回所有基金
      if (!criteria.isValid) {
        return await getFundList();
      }

      // 如果启用缓存，先尝试从缓存获取搜索结果
      if (searchCacheService != null && enableCache) {
        try {
          final cachedResults =
              await searchCacheService!.getCachedSearchResults(criteria);
          if (cachedResults != null && cachedResults.isNotEmpty) {
            return cachedResults;
          }
        } catch (_) {
          // 缓存获取失败，继续搜索
        }
      }

      // 获取所有基金数据进行搜索
      final allFunds = await getFundList();
      final searchResults = _performSearch(allFunds, criteria);

      // 缓存搜索结果
      if (searchCacheService != null && searchResults.isNotEmpty) {
        await searchCacheService!.cacheSearchResults(criteria, searchResults);
      }

      return searchResults;
    } catch (e) {
      // 如果搜索失败，尝试使用缓存的搜索结果
      if (searchCacheService != null && enableCache) {
        try {
          final cachedResults =
              await searchCacheService!.getCachedSearchResults(criteria);
          if (cachedResults != null) {
            return cachedResults;
          }
        } catch (_) {
          // 缓存也失败，抛出原始错误
        }
      }
      throw Exception('搜索基金失败: $e');
    }
  }

  @override
  Future<List<String>> getSearchSuggestions(String keyword,
      {int limit = 10}) async {
    try {
      if (keyword.trim().isEmpty) return [];

      // 如果启用缓存，先尝试从缓存获取搜索建议
      if (searchCacheService != null && enableCache) {
        try {
          final cachedSuggestions =
              await searchCacheService!.getCachedSearchSuggestions(keyword);
          if (cachedSuggestions != null && cachedSuggestions.isNotEmpty) {
            return cachedSuggestions.take(limit).toList();
          }
        } catch (_) {
          // 缓存获取失败，继续计算
        }
      }

      // 获取所有基金并生成建议
      final allFunds = await getFundList();
      final suggestions = _generateSearchSuggestions(allFunds, keyword, limit);

      // 缓存搜索建议
      if (searchCacheService != null && suggestions.isNotEmpty) {
        await searchCacheService!.cacheSearchSuggestions(keyword, suggestions);
      }

      return suggestions;
    } catch (e) {
      // 如果生成建议失败，尝试使用缓存的建议
      if (searchCacheService != null && enableCache) {
        try {
          final cachedSuggestions =
              await searchCacheService!.getCachedSearchSuggestions(keyword);
          if (cachedSuggestions != null) {
            return cachedSuggestions.take(limit).toList();
          }
        } catch (_) {
          // 缓存也失败，抛出原始错误
        }
      }
      throw Exception('获取搜索建议失败: $e');
    }
  }

  @override
  Future<List<String>> getSearchHistory({int limit = 50}) async {
    try {
      if (searchCacheService != null) {
        return await searchCacheService!.getSearchHistory(limit: limit);
      }
      return [];
    } catch (e) {
      throw Exception('获取搜索历史失败: $e');
    }
  }

  @override
  Future<bool> saveSearchHistory(String keyword) async {
    try {
      if (searchCacheService != null) {
        return await searchCacheService!.saveSearchHistory(keyword);
      }
      return false;
    } catch (e) {
      throw Exception('保存搜索历史失败: $e');
    }
  }

  @override
  Future<bool> deleteSearchHistory(String keyword) async {
    try {
      if (searchCacheService != null) {
        return await searchCacheService!.deleteSearchHistory(keyword);
      }
      return false;
    } catch (e) {
      throw Exception('删除搜索历史失败: $e');
    }
  }

  @override
  Future<bool> clearSearchHistory() async {
    try {
      if (searchCacheService != null) {
        return await searchCacheService!.clearSearchHistory();
      }
      return false;
    } catch (e) {
      throw Exception('清空搜索历史失败: $e');
    }
  }

  @override
  Future<List<String>> getPopularSearches({int limit = 10}) async {
    try {
      if (searchCacheService != null) {
        final cachedPopular = await searchCacheService!.getPopularSearches();
        if (cachedPopular.isNotEmpty) {
          return cachedPopular.take(limit).toList();
        }
      }

      // 如果没有缓存数据，生成默认的热门搜索
      final defaultPopular = [
        '股票基金',
        '债券基金',
        '混合基金',
        '货币基金',
        '指数基金',
        '新能源',
        '科技主题',
        '医药健康',
        '消费升级',
        'ESG投资',
      ];

      // 缓存默认热门搜索
      if (searchCacheService != null) {
        await searchCacheService!.cachePopularSearches(defaultPopular);
      }

      return defaultPopular.take(limit).toList();
    } catch (e) {
      throw Exception('获取热门搜索失败: $e');
    }
  }

  @override
  Future<void> preloadSearchCache() async {
    try {
      if (searchCacheService != null) {
        // 预加载一些常用的搜索结果
        final popularSearches = await getPopularSearches();
        for (final keyword in popularSearches.take(5)) {
          await getSearchSuggestions(keyword);
        }
      }
    } catch (e) {
      AppLogger.error('预加载搜索缓存失败', e);
    }
  }

  @override
  Future<void> clearSearchCache() async {
    try {
      if (searchCacheService != null) {
        await searchCacheService!.clearSearchCache();
      }
    } catch (e) {
      AppLogger.error('清空搜索缓存失败', e);
    }
  }

  @override
  Future<Map<String, dynamic>> getSearchStatistics() async {
    try {
      if (searchCacheService != null) {
        return await searchCacheService!.getSearchStatistics();
      }
      return {
        'averageSearchTime': 0,
        'maxSearchTime': 0,
        'minSearchTime': 0,
        'totalSearches': 0,
        'cacheSize': 0,
      };
    } catch (e) {
      throw Exception('获取搜索统计失败: $e');
    }
  }

  /// 执行搜索的核心逻辑
  List<Fund> _performSearch(List<Fund> funds, FundSearchCriteria criteria) {
    final keyword = criteria.keyword!.trim().toLowerCase();
    final searchFields = criteria.searchFields.isEmpty
        ? [
            SearchField.code,
            SearchField.name,
            SearchField.company,
            SearchField.type
          ]
        : criteria.searchFields;

    return funds.where((fund) {
      // 跳过非活跃基金（如果设置了）
      if (!criteria.includeInactive && fund.status != 'active') {
        return false;
      }

      // 应用扩展筛选条件
      if (!_matchesExtendedFilters(fund, criteria.extendedFilters)) {
        return false;
      }

      // 根据搜索字段进行匹配
      for (final field in searchFields) {
        if (_matchesField(fund, field, keyword, criteria)) {
          return true;
        }
      }

      return false;
    }).toList();
  }

  /// 检查基金是否匹配扩展筛选条件
  bool _matchesExtendedFilters(
      Fund fund, Map<String, dynamic> extendedFilters) {
    if (extendedFilters.isEmpty) return true;

    // 基金类型筛选
    if (extendedFilters.containsKey('fundTypes')) {
      final fundTypes = extendedFilters['fundTypes'] as List<String>;
      if (fundTypes.isNotEmpty && !fundTypes.contains(fund.type)) {
        return false;
      }
    }

    // 管理公司筛选
    if (extendedFilters.containsKey('companies')) {
      final companies = extendedFilters['companies'] as List<String>;
      if (companies.isNotEmpty && !companies.contains(fund.company)) {
        return false;
      }
    }

    // 基金规模筛选
    if (extendedFilters.containsKey('scaleMin') ||
        extendedFilters.containsKey('scaleMax')) {
      final scaleMin = extendedFilters['scaleMin'] as double? ?? 0.0;
      final scaleMax =
          extendedFilters['scaleMax'] as double? ?? double.infinity;
      if (fund.scale < scaleMin || fund.scale > scaleMax) {
        return false;
      }
    }

    // 风险等级筛选
    if (extendedFilters.containsKey('riskLevels')) {
      final riskLevels = extendedFilters['riskLevels'] as List<String>;
      if (riskLevels.isNotEmpty && !riskLevels.contains(fund.riskLevel)) {
        return false;
      }
    }

    // 收益率筛选
    if (extendedFilters.containsKey('returnMin') ||
        extendedFilters.containsKey('returnMax')) {
      final returnMin =
          extendedFilters['returnMin'] as double? ?? -double.infinity;
      final returnMax =
          extendedFilters['returnMax'] as double? ?? double.infinity;
      if (fund.return1Y < returnMin || fund.return1Y > returnMax) {
        return false;
      }
    }

    // 基金状态筛选
    if (extendedFilters.containsKey('statuses')) {
      final statuses = extendedFilters['statuses'] as List<String>;
      if (statuses.isNotEmpty && !statuses.contains(fund.status)) {
        return false;
      }
    }

    return true;
  }

  /// 检查字段是否匹配搜索条件
  bool _matchesField(Fund fund, SearchField field, String keyword,
      FundSearchCriteria criteria) {
    String fieldValue = '';

    switch (field) {
      case SearchField.code:
        fieldValue =
            criteria.caseSensitive ? fund.code : fund.code.toLowerCase();
        break;
      case SearchField.name:
        fieldValue =
            criteria.caseSensitive ? fund.name : fund.name.toLowerCase();
        break;
      case SearchField.type:
        fieldValue =
            criteria.caseSensitive ? fund.type : fund.type.toLowerCase();
        break;
      case SearchField.company:
        fieldValue =
            criteria.caseSensitive ? fund.company : fund.company.toLowerCase();
        break;
      case SearchField.manager:
        fieldValue =
            criteria.caseSensitive ? fund.manager : fund.manager.toLowerCase();
        break;
      case SearchField.strategy:
        // 基金实体中没有strategy字段，返回false
        return false;
      case SearchField.all:
        // 搜索所有字段
        final allFields = [
          fund.code,
          fund.name,
          fund.type,
          fund.company,
          fund.manager,
        ];
        fieldValue = allFields.join(' ');
        if (!criteria.caseSensitive) {
          fieldValue = fieldValue.toLowerCase();
        }
        break;
    }

    // 执行匹配
    if (criteria.fuzzySearch) {
      // 模糊搜索
      return fieldValue.contains(keyword);
    } else {
      // 精确匹配
      switch (criteria.searchType) {
        case SearchType.exact:
          return fieldValue == keyword;
        case SearchType.mixed:
        case SearchType.fullText:
          return fieldValue.contains(keyword);
        default:
          return fieldValue.contains(keyword);
      }
    }
  }

  /// 生成搜索建议
  List<String> _generateSearchSuggestions(
      List<Fund> funds, String keyword, int limit) {
    final suggestions = <String>{};
    final lowerKeyword = keyword.toLowerCase();

    // 从基金代码生成建议
    for (final fund in funds) {
      if (fund.code.toLowerCase().startsWith(lowerKeyword)) {
        suggestions.add(fund.code);
      }
      if (suggestions.length >= limit) break;
    }

    // 从基金名称生成建议
    if (suggestions.length < limit) {
      for (final fund in funds) {
        if (fund.name.toLowerCase().startsWith(lowerKeyword)) {
          suggestions.add(fund.name);
        }
        if (suggestions.length >= limit) break;
      }
    }

    // 从基金类型生成建议
    if (suggestions.length < limit) {
      for (final fund in funds) {
        if (fund.type.toLowerCase().contains(lowerKeyword)) {
          suggestions.add(fund.type);
        }
        if (suggestions.length >= limit) break;
      }
    }

    // 从基金公司生成建议
    if (suggestions.length < limit) {
      for (final fund in funds) {
        if (fund.company.toLowerCase().contains(lowerKeyword)) {
          suggestions.add(fund.company);
        }
        if (suggestions.length >= limit) break;
      }
    }

    return suggestions.take(limit).toList();
  }

  @override
  Future<List<Fund>> getFunds() async {
    return await getFundList();
  }

  @override
  Future<List<Fund>> getFundRankings(String symbol) async {
    // 实现基本的基金排名功能，基于symbol返回单个基金的排名信息
    // 这是一个简化实现，实际应用中可能需要更复杂的逻辑
    try {
      final allFunds = await getFundList();
      final matchingFunds = allFunds.where((f) => f.code == symbol).toList();

      if (matchingFunds.isEmpty) {
        throw Exception('基金代码 $symbol 不存在');
      }

      // 返回包含该基金的列表，实际应用中这里应该返回排名信息
      return [matchingFunds.first];
    } catch (e) {
      throw Exception('获取基金排名失败: $e');
    }
  }

  // ===== 排行榜功能实现 =====

  @override
  Future<PaginatedRankingResult> getFundRankingsByCriteria(
    RankingCriteria criteria, {
    bool forceRefresh = false,
  }) async {
    try {
      AppLogger.business(
          '开始获取基金排行榜 (forceRefresh: $forceRefresh)', 'Repository');
      AppLogger.debug('排行榜条件: ${criteria.toString()}', 'Repository');

      // 如果启用缓存且不强制刷新，先尝试从缓存获取
      if (enableCache && !forceRefresh) {
        try {
          final cachedRankings =
              await localDataSource.getCachedRankings(criteria);
          if (cachedRankings != null && cachedRankings.rankings.isNotEmpty) {
            AppLogger.business(
                '从缓存获取排行榜数据: ${cachedRankings.rankings.length}条', 'Repository');
            return cachedRankings;
          }
        } catch (e) {
          AppLogger.warn('缓存获取失败，继续获取数据: $e');
        }
      }

      // 构建API请求参数
      String symbol = '全部'; // 默认获取全部

      // 根据筛选条件设置symbol参数
      if (criteria.fundType != null && criteria.fundType!.isNotEmpty) {
        symbol = criteria.fundType!;
      } else if (criteria.company != null && criteria.company!.isNotEmpty) {
        symbol = criteria.company!;
      }

      // 从远程数据源获取排行榜数据，强制刷新时绕过缓存
      List<Fund> rankingsData =
          await _getFundRankingsWithRetry(symbol, forceRefresh: forceRefresh);

      // 转换为FundRanking实体
      List<FundRanking> rankings = rankingsData
          .map((fund) => _convertFundToRanking(fund, criteria))
          .where((ranking) => ranking != null)
          .cast<FundRanking>()
          .toList();

      // 根据排序条件进行排序
      rankings = _sortRankings(rankings, criteria.sortBy);

      // 应用分页
      final startIndex = (criteria.page - 1) * criteria.pageSize;
      final paginatedRankings =
          rankings.skip(startIndex).take(criteria.pageSize).toList();

      // 计算分页信息
      final totalCount = rankings.length;
      final totalPages = (totalCount / criteria.pageSize).ceil();
      final hasNextPage = criteria.page < totalPages;
      final hasPreviousPage = criteria.page > 1;

      final result = PaginatedRankingResult(
        rankings: paginatedRankings,
        currentPage: criteria.page,
        pageSize: criteria.pageSize,
        totalCount: totalCount,
        totalPages: totalPages,
        hasNextPage: hasNextPage,
        hasPreviousPage: hasPreviousPage,
      );

      // 缓存结果（仅在成功且有数据时）
      if (enableCache && result.rankings.isNotEmpty) {
        await localDataSource.cacheRankings(criteria, result);
        AppLogger.business('缓存排行榜数据: ${result.rankings.length}条', 'Repository');
      }

      AppLogger.business(
          '获取排行榜成功: 总计$totalCount条，当前页${result.rankings.length}条',
          'Repository');
      return result;
    } catch (e) {
      AppLogger.error('获取基金排行榜失败', e.toString());

      // 如果获取失败，尝试使用缓存的排行榜数据
      if (enableCache) {
        try {
          final cachedRankings =
              await localDataSource.getCachedRankings(criteria);
          if (cachedRankings != null && cachedRankings.rankings.isNotEmpty) {
            AppLogger.business(
                '使用缓存数据作为备选: ${cachedRankings.rankings.length}条', 'Repository');
            return cachedRankings;
          }
        } catch (_) {
          AppLogger.warn('缓存数据也获取失败');
        }
      }

      // 提供详细的错误信息
      String errorMessage = e.toString();
      if (errorMessage.contains('timeout') || errorMessage.contains('超时')) {
        throw Exception('请求超时，请检查网络连接后重试');
      } else if (errorMessage.contains('connection') ||
          errorMessage.contains('network')) {
        throw Exception('网络连接失败，请检查网络设置');
      } else if (errorMessage.contains('500')) {
        throw Exception('服务器暂时不可用，请稍后重试');
      } else if (errorMessage.contains('403')) {
        throw Exception('访问被拒绝，请检查CORS配置');
      } else if (errorMessage.contains('400') ||
          errorMessage.contains('参数错误')) {
        throw Exception('请求参数错误，请检查输入条件');
      } else {
        throw Exception('获取基金排行榜失败: $errorMessage');
      }
    }
  }

  @override
  Future<List<FundRanking>> getFundRankingHistory(
    String fundCode,
    RankingPeriod period, {
    int days = 30,
  }) async {
    try {
      // 生成模拟的历史排名数据
      // 在实际应用中，这里应该从远程数据源获取真实的历史数据
      final List<FundRanking> history = [];
      final now = DateTime.now();

      for (int i = 0; i < days; i++) {
        final date = now.subtract(Duration(days: days - i));
        final position = _generateMockPosition(date, fundCode, period);

        // 创建历史排名数据
        history.add(FundRanking(
          fundCode: fundCode,
          fundName: '模拟基金名称', // 实际应用中应该获取真实名称
          fundType: '股票型',
          company: '模拟基金公司',
          rankingPosition: position,
          totalCount: 1000, // 模拟总数
          unitNav: 1.2345 + (i * 0.001),
          accumulatedNav: 1.5678 + (i * 0.002),
          dailyReturn: _generateMockReturn(date),
          return1W: _generateMockReturn(date) * 7,
          return1M: _generateMockReturn(date) * 30,
          return3M: _generateMockReturn(date) * 90,
          return6M: _generateMockReturn(date) * 180,
          return1Y: _generateMockReturn(date) * 365,
          return2Y: _generateMockReturn(date) * 730,
          return3Y: _generateMockReturn(date) * 1095,
          returnYTD: _generateMockReturn(date) *
              date.difference(DateTime(date.year, 1, 1)).inDays,
          returnSinceInception: _generateMockReturn(date) * 365 * 3,
          rankingDate: date,
          previousPosition: i > 0 ? history[i - 1].rankingPosition : null,
          positionChange: i > 0
              ? (history[i - 1].rankingPosition - position).toDouble()
              : null,
          rankingType: RankingType.overall,
          rankingPeriod: period,
        ));
      }

      return history;
    } catch (e) {
      throw Exception('获取基金排名历史失败: $e');
    }
  }

  @override
  Future<PaginatedRankingResult> searchRankings(
    String query,
    RankingCriteria criteria,
  ) async {
    try {
      // 先获取基础排行榜数据
      final baseRankings = await getFundRankingsByCriteria(criteria);

      // 在排行榜数据中搜索
      final lowerQuery = query.toLowerCase();
      final filteredRankings = baseRankings.rankings.where((ranking) {
        return ranking.fundCode.toLowerCase().contains(lowerQuery) ||
            ranking.fundName.toLowerCase().contains(lowerQuery) ||
            ranking.fundType.toLowerCase().contains(lowerQuery) ||
            ranking.company.toLowerCase().contains(lowerQuery);
      }).toList();

      // 重新计算分页
      final totalCount = filteredRankings.length;
      final totalPages = (totalCount / criteria.pageSize).ceil();
      final startIndex = (criteria.page - 1) * criteria.pageSize;
      final paginatedRankings =
          filteredRankings.skip(startIndex).take(criteria.pageSize).toList();

      return PaginatedRankingResult(
        rankings: paginatedRankings,
        currentPage: criteria.page,
        pageSize: criteria.pageSize,
        totalCount: totalCount,
        totalPages: totalPages,
        hasNextPage: criteria.page < totalPages,
        hasPreviousPage: criteria.page > 1,
      );
    } catch (e) {
      throw Exception('搜索排行榜失败: $e');
    }
  }

  @override
  Future<RankingStatistics> getRankingStatistics(
      RankingCriteria criteria) async {
    try {
      // 获取排行榜数据
      final rankings = await getFundRankingsByCriteria(criteria);

      // 计算统计数据
      final rankingsList = rankings.rankings;
      if (rankingsList.isEmpty) {
        return RankingStatistics(
          totalFunds: 0,
          averageReturn: 0.0,
          topPerformer: null,
          worstPerformer: null,
          volatilityIndex: 0.0,
          sharpeRatio: 0.0,
          maxDrawdown: 0.0,
          positiveReturnRate: 0.0,
          averageRiskLevel: 0.0,
          updateTime: DateTime.now(),
        );
      }

      // 计算平均收益率
      final totalReturn =
          rankingsList.fold<double>(0.0, (sum, r) => sum + r.return1Y);
      final averageReturn = totalReturn / rankingsList.length;

      // 找出表现最好和最差的基金
      final sortedByReturn = List<FundRanking>.from(rankingsList)
        ..sort((a, b) => b.return1Y.compareTo(a.return1Y));
      final topPerformer = sortedByReturn.first;
      final worstPerformer = sortedByReturn.last;

      // 计算波动率（简化计算）
      final variance = rankingsList.fold<double>(0.0, (sum, r) {
            final diff = r.return1Y - averageReturn;
            return sum + (diff * diff);
          }) /
          rankingsList.length;
      final volatilityIndex = variance > 0 ? variance.sqrt() : 0.0;

      // 计算正收益率比例
      final positiveReturns = rankingsList.where((r) => r.return1Y > 0).length;
      final positiveReturnRate = positiveReturns / rankingsList.length;

      // 计算其他统计指标（简化计算）
      final sharpeRatio =
          volatilityIndex > 0 ? averageReturn / volatilityIndex : 0.0;
      final maxDrawdown = _calculateMaxDrawdown(rankingsList);
      final averageRiskLevel = _calculateAverageRiskLevel(rankingsList);

      return RankingStatistics(
        totalFunds: rankings.totalCount,
        averageReturn: averageReturn,
        topPerformer: topPerformer,
        worstPerformer: worstPerformer,
        volatilityIndex: volatilityIndex,
        sharpeRatio: sharpeRatio,
        maxDrawdown: maxDrawdown,
        positiveReturnRate: positiveReturnRate,
        averageRiskLevel: averageRiskLevel,
        updateTime: DateTime.now(),
      );
    } catch (e) {
      throw Exception('获取排行榜统计失败: $e');
    }
  }

  @override
  Future<PaginatedRankingResult> getFavoriteFundsRankings(
    List<String> fundCodes,
    RankingCriteria criteria,
  ) async {
    try {
      if (fundCodes.isEmpty) {
        return const PaginatedRankingResult(
          rankings: [],
          currentPage: 0,
          pageSize: 0,
          totalCount: 0,
          totalPages: 0,
          hasNextPage: false,
          hasPreviousPage: false,
        );
      }

      // 获取所有基金排行榜数据
      final allRankings = await getFundRankingsByCriteria(criteria);

      // 筛选出收藏的基金
      final favoriteRankings = allRankings.rankings
          .where((ranking) => fundCodes.contains(ranking.fundCode))
          .toList();

      // 重新计算分页
      final totalCount = favoriteRankings.length;
      final totalPages = (totalCount / criteria.pageSize).ceil();
      final startIndex = (criteria.page - 1) * criteria.pageSize;
      final paginatedRankings =
          favoriteRankings.skip(startIndex).take(criteria.pageSize).toList();

      return PaginatedRankingResult(
        rankings: paginatedRankings,
        currentPage: criteria.page,
        pageSize: criteria.pageSize,
        totalCount: totalCount,
        totalPages: totalPages,
        hasNextPage: criteria.page < totalPages,
        hasPreviousPage: criteria.page > 1,
      );
    } catch (e) {
      throw Exception('获取收藏基金排行榜失败: $e');
    }
  }

  @override
  Future<bool> saveFavoriteFunds(Set<String> fundCodes) async {
    try {
      // 保存收藏基金列表到本地存储
      return await localDataSource.saveFavoriteFunds(fundCodes);
    } catch (e) {
      throw Exception('保存收藏基金失败: $e');
    }
  }

  @override
  Future<Set<String>> getFavoriteFunds() async {
    try {
      // 从本地存储获取收藏基金列表
      return await localDataSource.getFavoriteFunds();
    } catch (e) {
      throw Exception('获取收藏基金失败: $e');
    }
  }

  @override
  Future<List<HotRankingType>> getHotRankingTypes() async {
    try {
      // 返回热门排行榜类型（模拟数据）
      return [
        const HotRankingType(
          type: RankingType.overall,
          period: RankingPeriod.oneMonth,
          name: '月度总榜',
          description: '最近一个月表现最佳的基金',
          popularity: 95,
        ),
        const HotRankingType(
          type: RankingType.byType,
          period: RankingPeriod.oneYear,
          name: '股票型年榜',
          description: '股票型基金年度排行榜',
          popularity: 88,
        ),
        const HotRankingType(
          type: RankingType.byCompany,
          period: RankingPeriod.threeMonths,
          name: '公司季榜',
          description: '各基金公司季度表现对比',
          popularity: 76,
        ),
      ];
    } catch (e) {
      throw Exception('获取热门排行榜类型失败: $e');
    }
  }

  @override
  Future<List<String>> getFundTypes() async {
    try {
      // 从所有基金中获取基金类型列表
      final allFunds = await getFundList();
      return allFunds
          .map((fund) => fund.type)
          .where((type) => type.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
    } catch (e) {
      throw Exception('获取基金类型失败: $e');
    }
  }

  @override
  Future<List<String>> getFundCompanies() async {
    try {
      // 从所有基金中获取基金公司列表
      final allFunds = await getFundList();
      return allFunds
          .map((fund) => fund.company)
          .where((company) => company.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
    } catch (e) {
      throw Exception('获取基金公司失败: $e');
    }
  }

  @override
  Future<bool> refreshRankingCache({
    RankingType? rankingType,
    RankingPeriod? period,
  }) async {
    try {
      // 创建一个基础的排行榜条件
      final criteria = RankingCriteria(
        rankingType: rankingType ?? RankingType.overall,
        rankingPeriod: period ?? RankingPeriod.oneMonth,
      );

      // 强制刷新排行榜数据
      await getFundRankingsByCriteria(criteria, forceRefresh: true);

      return true;
    } catch (e) {
      AppLogger.error('刷新排行榜缓存失败', e);
      return false;
    }
  }

  @override
  Future<void> clearRankingCache() async {
    try {
      await localDataSource.clearRankingCache();
    } catch (e) {
      AppLogger.error('清空排行榜缓存失败', e);
    }
  }

  @override
  Future<DateTime?> getRankingUpdateTime({
    RankingType? rankingType,
    RankingPeriod? period,
  }) async {
    try {
      return await localDataSource.getRankingUpdateTime(rankingType, period);
    } catch (e) {
      AppLogger.error('获取排行榜更新时间失败', e);
      return null;
    }
  }

  // ===== 私有辅助方法 =====

  /// 根据基金数据生成排行榜
  List<FundRanking> _generateRankings(
      List<Fund> funds, RankingCriteria criteria) {
    // 根据筛选条件过滤基金
    List<Fund> filteredFunds = funds;

    if (criteria.fundType?.isNotEmpty == true) {
      filteredFunds = filteredFunds
          .where((fund) => fund.type == criteria.fundType)
          .toList();
    }

    if (criteria.company?.isNotEmpty == true) {
      filteredFunds = filteredFunds
          .where((fund) => fund.company == criteria.company)
          .toList();
    }

    // 根据排序方式排序
    switch (criteria.sortBy) {
      case RankingSortBy.returnRate:
        filteredFunds.sort((a, b) =>
            _getReturnValueByPeriod(b, criteria.rankingPeriod)
                .compareTo(_getReturnValueByPeriod(a, criteria.rankingPeriod)));
        break;
      case RankingSortBy.unitNav:
        filteredFunds.sort((a, b) => b.unitNav.compareTo(a.unitNav));
        break;
      case RankingSortBy.accumulatedNav:
        filteredFunds
            .sort((a, b) => b.accumulatedNav.compareTo(a.accumulatedNav));
        break;
      case RankingSortBy.dailyReturn:
        filteredFunds.sort((a, b) => b.dailyReturn.compareTo(a.dailyReturn));
        break;
      case RankingSortBy.rankingPosition:
        // 按排名排序，这里保持原顺序
        break;
    }

    // 转换为排行榜数据
    final rankings = filteredFunds.asMap().entries.map((entry) {
      final index = entry.key;
      final fund = entry.value;

      return FundRanking(
        fundCode: fund.code,
        fundName: fund.name,
        fundType: fund.type,
        company: fund.company,
        rankingPosition: index + 1,
        totalCount: filteredFunds.length,
        unitNav: fund.unitNav,
        accumulatedNav: fund.accumulatedNav,
        dailyReturn: fund.dailyReturn,
        return1W: fund.return1W,
        return1M: fund.return1M,
        return3M: fund.return3M,
        return6M: fund.return6M,
        return1Y: fund.return1Y,
        return2Y: fund.return2Y,
        return3Y: fund.return3Y,
        returnYTD: fund.returnYTD,
        returnSinceInception: fund.returnSinceInception,
        rankingDate: DateTime.now(),
        previousPosition: null, // 实际应用中应该从缓存或历史数据获取
        positionChange: null,
        rankingType: criteria.rankingType,
        rankingPeriod: criteria.rankingPeriod,
      );
    }).toList();

    return rankings;
  }

  /// 根据时间段获取收益率
  double _getReturnValueByPeriod(Fund fund, RankingPeriod period) {
    switch (period) {
      case RankingPeriod.daily:
        return fund.dailyReturn;
      case RankingPeriod.oneWeek:
        return fund.return1W;
      case RankingPeriod.oneMonth:
        return fund.return1M;
      case RankingPeriod.threeMonths:
        return fund.return3M;
      case RankingPeriod.sixMonths:
        return fund.return6M;
      case RankingPeriod.oneYear:
        return fund.return1Y;
      case RankingPeriod.twoYears:
        return fund.return2Y;
      case RankingPeriod.threeYears:
        return fund.return3Y;
      case RankingPeriod.ytd:
        return fund.returnYTD;
      case RankingPeriod.sinceInception:
        return fund.returnSinceInception;
    }
  }

  /// 生成模拟的排名位置
  int _generateMockPosition(
      DateTime date, String fundCode, RankingPeriod period) {
    // 使用基金代码和日期生成一个相对稳定的随机数
    final seed = fundCode.hashCode + date.millisecondsSinceEpoch;
    final random = Random(seed);
    return random.nextInt(100) + 1; // 1-100的排名
  }

  /// 生成模拟的收益率
  double _generateMockReturn(DateTime date) {
    // 使用日期生成一个相对稳定的随机收益率
    final seed = date.millisecondsSinceEpoch;
    final random = Random(seed);
    return (random.nextDouble() - 0.3) * 10; // -3% 到 +7% 的收益率
  }

  /// 计算最大回撤（简化计算）
  double _calculateMaxDrawdown(List<FundRanking> rankings) {
    if (rankings.isEmpty) return 0.0;

    double maxDrawdown = 0.0;
    double peak = rankings.first.return1Y;

    for (final ranking in rankings) {
      if (ranking.return1Y > peak) {
        peak = ranking.return1Y;
      } else {
        final drawdown = (peak - ranking.return1Y) / peak;
        if (drawdown > maxDrawdown) {
          maxDrawdown = drawdown;
        }
      }
    }

    return maxDrawdown;
  }

  /// 计算平均风险等级（简化计算）
  double _calculateAverageRiskLevel(List<FundRanking> rankings) {
    if (rankings.isEmpty) return 0.0;

    // 根据基金类型映射风险等级
    double totalRisk = 0.0;
    for (final ranking in rankings) {
      switch (ranking.fundType) {
        case '股票型':
          totalRisk += 4.0;
          break;
        case '混合型':
          totalRisk += 3.0;
          break;
        case '债券型':
          totalRisk += 2.0;
          break;
        case '货币型':
          totalRisk += 1.0;
          break;
        default:
          totalRisk += 2.5;
      }
    }

    return totalRisk / rankings.length;
  }

  /// 带智能重试机制的基金排行榜获取
  Future<List<Fund>> _getFundRankingsWithRetry(String symbol,
      {bool forceRefresh = false}) async {
    try {
      AppLogger.business(
          '获取基金排行榜数据 (symbol: $symbol, forceRefresh: $forceRefresh)',
          'Repository');

      // 直接调用远程数据源获取排行榜数据，传递forceRefresh参数
      final rankingsData = await remoteDataSource.getFundRankings(symbol,
          forceRefresh: forceRefresh);

      AppLogger.business('排行榜数据获取成功: ${rankingsData.length}条', 'Repository');
      return rankingsData;
    } catch (e) {
      AppLogger.error('获取排行榜数据失败', e.toString());
      rethrow;
    }
  }

  /// 将Fund实体转换为FundRanking实体
  FundRanking? _convertFundToRanking(Fund fund, RankingCriteria criteria) {
    try {
      return FundRanking(
        fundCode: fund.code,
        fundName: fund.name,
        fundType: fund.type,
        company: fund.company,
        rankingPosition: 0, // 将在排序后设置
        totalCount: 0, // 将在排序后设置
        unitNav: fund.unitNav,
        accumulatedNav: fund.accumulatedNav,
        dailyReturn: fund.dailyReturn,
        return1W: fund.return1W,
        return1M: fund.return1M,
        return3M: fund.return3M,
        return6M: fund.return6M,
        return1Y: fund.return1Y,
        return2Y: fund.return2Y,
        return3Y: fund.return3Y,
        returnYTD: fund.returnYTD,
        returnSinceInception: fund.returnSinceInception,
        rankingDate: DateTime.now(),
        previousPosition: null, // 可以后续实现
        positionChange: null, // 可以后续实现
        rankingType: criteria.rankingType,
        rankingPeriod: criteria.rankingPeriod,
      );
    } catch (e) {
      AppLogger.error('转换基金数据为排行榜失败: ${fund.code}', e.toString());
      return null;
    }
  }

  /// 根据排序条件对排行榜进行排序
  List<FundRanking> _sortRankings(
      List<FundRanking> rankings, RankingSortBy sortBy) {
    switch (sortBy) {
      case RankingSortBy.returnRate:
        rankings.sort((a, b) =>
            _getRankingReturnValueByPeriod(b, b.rankingPeriod)
                .compareTo(_getRankingReturnValueByPeriod(a, a.rankingPeriod)));
        break;
      case RankingSortBy.unitNav:
        rankings.sort((a, b) => b.unitNav.compareTo(a.unitNav));
        break;
      case RankingSortBy.accumulatedNav:
        rankings.sort((a, b) => b.accumulatedNav.compareTo(a.accumulatedNav));
        break;
      case RankingSortBy.dailyReturn:
        rankings.sort((a, b) => b.dailyReturn.compareTo(a.dailyReturn));
        break;
      case RankingSortBy.rankingPosition:
        // 按排名排序，保持原顺序或按收益率排序
        rankings.sort((a, b) =>
            _getRankingReturnValueByPeriod(b, b.rankingPeriod)
                .compareTo(_getRankingReturnValueByPeriod(a, a.rankingPeriod)));
        break;
    }

    // 设置排名位置
    for (int i = 0; i < rankings.length; i++) {
      rankings[i] = rankings[i].copyWith(
        rankingPosition: i + 1,
        totalCount: rankings.length,
      );
    }

    return rankings;
  }

  /// 根据排行榜实体获取收益率
  double _getRankingReturnValueByPeriod(
      FundRanking ranking, RankingPeriod period) {
    switch (period) {
      case RankingPeriod.daily:
        return ranking.dailyReturn;
      case RankingPeriod.oneWeek:
        return ranking.return1W;
      case RankingPeriod.oneMonth:
        return ranking.return1M;
      case RankingPeriod.threeMonths:
        return ranking.return3M;
      case RankingPeriod.sixMonths:
        return ranking.return6M;
      case RankingPeriod.oneYear:
        return ranking.return1Y;
      case RankingPeriod.twoYears:
        return ranking.return2Y;
      case RankingPeriod.threeYears:
        return ranking.return3Y;
      case RankingPeriod.ytd:
        return ranking.returnYTD;
      case RankingPeriod.sinceInception:
        return ranking.returnSinceInception;
    }
  }
}

/// 数学扩展方法
extension on double {
  double sqrt() => math.sqrt(this);
}
