import 'i_unified_search_service.dart';

/// 搜索选项工厂
///
/// 提供常用的搜索选项预设，简化使用
class SearchOptionsFactory {
  /// 创建快速搜索选项（优先性能）
  static UnifiedSearchOptions quickSearch() {
    return const UnifiedSearchOptions(
      limit: 10,
      useCache: true,
      cacheResults: true,
      fuzzyThreshold: 0.8,
      useEnhancedFeatures: false,
      enableBehaviorPreload: false,
      enableIncrementalLoad: false,
    );
  }

  /// 创建精确搜索选项（优先准确性）
  static UnifiedSearchOptions preciseSearch() {
    return const UnifiedSearchOptions(
      limit: 20,
      exactMatch: false,
      useCache: true,
      fuzzyThreshold: 0.9,
      enableFuzzy: true,
      enablePinyin: true,
      useEnhancedFeatures: true,
    );
  }

  /// 创建全面搜索选项（获取最多结果）
  static UnifiedSearchOptions comprehensiveSearch() {
    return const UnifiedSearchOptions(
      limit: 100,
      useCache: true,
      fuzzyThreshold: 0.6,
      enableFuzzy: true,
      enablePinyin: true,
      enableBehaviorPreload: true,
      enableIncrementalLoad: true,
      useEnhancedFeatures: true,
    );
  }

  /// 创建基金代码搜索选项（精确匹配）
  static UnifiedSearchOptions fundCodeSearch() {
    return const UnifiedSearchOptions(
      limit: 5,
      exactMatch: true,
      useCache: true,
      fuzzyThreshold: 1.0,
      sortBy: 'fundCode',
      useEnhancedFeatures: false,
    );
  }

  /// 创建基金名称搜索选项（智能模糊匹配）
  static UnifiedSearchOptions fundNameSearch() {
    return const UnifiedSearchOptions(
      limit: 20,
      exactMatch: false,
      useCache: true,
      fuzzyThreshold: 0.7,
      enableFuzzy: true,
      enablePinyin: true,
      sortBy: 'fundName',
      useEnhancedFeatures: true,
    );
  }

  /// 创建收益率排序搜索选项
  static UnifiedSearchOptions returnRankedSearch({
    bool sortBy1Year = true,
    int limit = 50,
  }) {
    return UnifiedSearchOptions(
      limit: limit,
      useCache: true,
      fuzzyThreshold: 0.7,
      enableFuzzy: true,
      sortBy: sortBy1Year ? 'return1y' : 'return3y',
      sortOrder: 'desc',
      useEnhancedFeatures: true,
    );
  }

  /// 创建规模排序搜索选项
  static UnifiedSearchOptions sizeRankedSearch({int limit = 50}) {
    return UnifiedSearchOptions(
      limit: limit,
      useCache: true,
      fuzzyThreshold: 0.7,
      sortBy: 'fundSize',
      sortOrder: 'desc',
      useEnhancedFeatures: true,
    );
  }

  /// 创建自动优化搜索选项（根据查询类型智能选择）
  static UnifiedSearchOptions autoOptimizedSearch(String query) {
    // 基金代码精确匹配
    if (RegExp(r'^\d{6}$').hasMatch(query)) {
      return fundCodeSearch();
    }

    // 简短查询使用快速搜索
    if (query.length <= 3) {
      return quickSearch();
    }

    // 长查询或包含关键词使用全面搜索
    if (query.length > 10 || _containsFundKeywords(query)) {
      return comprehensiveSearch();
    }

    // 默认使用精确搜索
    return preciseSearch();
  }

  /// 判断是否包含基金相关关键词
  static bool _containsFundKeywords(String query) {
    final keywords = [
      '股票',
      '债券',
      '混合',
      '货币',
      '指数',
      'qdii',
      'etf',
      'lof',
      '价值',
      '成长',
      '平衡',
      '稳健',
      '激进',
      '保本',
      '定投',
      '华夏',
      '易方达',
      '嘉实',
      '南方',
      '博时',
      '广发',
      '汇添富'
    ];

    final lowerQuery = query.toLowerCase();
    return keywords
        .any((keyword) => lowerQuery.contains(keyword.toLowerCase()));
  }

  /// 创建自定义搜索选项
  static UnifiedSearchOptions custom({
    int limit = 50,
    bool exactMatch = false,
    bool useCache = true,
    double fuzzyThreshold = 0.7,
    String sortBy = 'relevance',
    String sortOrder = 'desc',
    bool enableFuzzy = true,
    bool enablePinyin = true,
    bool enableBehaviorPreload = false,
    bool enableIncrementalLoad = false,
    bool useEnhancedFeatures = false,
  }) {
    return UnifiedSearchOptions(
      limit: limit,
      exactMatch: exactMatch,
      useCache: useCache,
      fuzzyThreshold: fuzzyThreshold,
      sortBy: sortBy,
      sortOrder: sortOrder,
      enableFuzzy: enableFuzzy,
      enablePinyin: enablePinyin,
      enableBehaviorPreload: enableBehaviorPreload,
      enableIncrementalLoad: enableIncrementalLoad,
      useEnhancedFeatures: useEnhancedFeatures,
    );
  }
}
