/// 缓存键配置文件
///
/// 定义项目中使用的所有缓存键常量和配置
library cache_key_config;

import '../cache/cache_key_manager.dart';

// ==================== 基金数据缓存键 ====================

/// 基金数据相关的缓存键
class FundDataKeys {
  FundDataKeys._();

  /// 基础基金信息
  static const String basicInfo = 'basic_info';

  /// 基金详细数据
  static const String detailedData = 'detailed_data';

  /// 基金实时数据
  static const String realtimeData = 'realtime_data';

  /// 基金历史数据
  static const String historicalData = 'historical_data';

  /// 基金净值数据
  static const String navData = 'nav_data';

  /// 基金分红数据
  static const String dividendData = 'dividend_data';

  /// 基金持仓数据
  static const String holdingData = 'holding_data';

  /// 基金经理信息
  static const String managerInfo = 'manager_info';

  /// 基金费率信息
  static const String feeInfo = 'fee_info';

  /// 基金评级信息
  static const String ratingInfo = 'rating_info';
}

/// 基金列表相关的缓存键
class FundListKeys {
  FundListKeys._();

  /// 开放式基金列表
  static const String openFunds = 'open_funds';

  /// 货币基金列表
  static const String moneyFunds = 'money_funds';

  /// 混合型基金列表
  static const String hybridFunds = 'hybrid_funds';

  /// 股票型基金列表
  static const String equityFunds = 'equity_funds';

  /// 债券型基金列表
  static const String bondFunds = 'bond_funds';

  /// 指数型基金列表
  static const String indexFunds = 'index_funds';

  /// QDII基金列表
  static const String qdiiFunds = 'qdii_funds';

  /// FOF基金列表
  static const String fofFunds = 'fof_funds';

  /// 热门基金列表
  static const String hotFunds = 'hot_funds';

  /// 新发基金列表
  static const String newFunds = 'new_funds';

  /// 排行榜基金列表
  static const String rankingFunds = 'ranking_funds';
}

// ==================== 搜索索引缓存键 ====================

/// 搜索索引相关的缓存键
class SearchIndexKeys {
  SearchIndexKeys._();

  /// 基金代码索引
  static const String fundCodeIndex = 'fund_code_index';

  /// 基金名称索引
  static const String fundNameIndex = 'fund_name_index';

  /// 基金拼音索引
  static const String fundPinyinIndex = 'fund_pinyin_index';

  /// 基金类型索引
  static const String fundTypeIndex = 'fund_type_index';

  /// 基金公司索引
  static const String fundCompanyIndex = 'fund_company_index';

  /// 基金经理索引
  static const String fundManagerIndex = 'fund_manager_index';

  /// 搜索关键词索引
  static const String keywordIndex = 'keyword_index';

  /// 热门搜索索引
  static const String hotSearchIndex = 'hot_search_index';

  /// 搜索历史索引
  static const String searchHistoryIndex = 'search_history_index';
}

// ==================== 用户偏好缓存键 ====================

/// 用户偏好相关的缓存键
class UserPreferenceKeys {
  UserPreferenceKeys._();

  /// 用户自选基金列表
  static const String favoriteFunds = 'favorite_funds';

  /// 用户关注基金列表
  static const String watchlistFunds = 'watchlist_funds';

  /// 用户搜索历史
  static const String searchHistory = 'search_history';

  /// 用户浏览历史
  static const String browsingHistory = 'browsing_history';

  /// 用户筛选偏好
  static const String filterPreferences = 'filter_preferences';

  /// 用户排序偏好
  static const String sortPreferences = 'sort_preferences';

  /// 用户显示偏好
  static const String displayPreferences = 'display_preferences';

  /// 用户通知设置
  static const String notificationSettings = 'notification_settings';

  /// 用户主题设置
  static const String themeSettings = 'theme_settings';

  /// 用户语言设置
  static const String languageSettings = 'language_settings';
}

// ==================== 元数据缓存键 ====================

/// 元数据相关的缓存键
class MetadataKeys {
  MetadataKeys._();

  /// 缓存创建时间
  static const String cacheCreatedTime = 'cache_created_time';

  /// 缓存更新时间
  static const String cacheUpdatedTime = 'cache_updated_time';

  /// 缓存过期时间
  static const String cacheExpireTime = 'cache_expire_time';

  /// 缓存版本信息
  static const String cacheVersion = 'cache_version';

  /// 数据版本信息
  static const String dataVersion = 'data_version';

  /// API版本信息
  static const String apiVersion = 'api_version';

  /// 系统配置版本
  static const String systemConfigVersion = 'system_config_version';

  /// 数据质量信息
  static const String dataQualityInfo = 'data_quality_info';

  /// 错误日志信息
  static const String errorLogInfo = 'error_log_info';

  /// 性能监控信息
  static const String performanceInfo = 'performance_info';

  /// 用户行为分析
  static const String userBehaviorAnalysis = 'user_behavior_analysis';
}

// ==================== 临时数据缓存键 ====================

/// 临时数据相关的缓存键
class TemporaryKeys {
  TemporaryKeys._();

  /// 当前会话数据
  static const String currentSession = 'current_session';

  /// 临时搜索结果
  static const String tempSearchResults = 'temp_search_results';

  /// 临时筛选结果
  static const String tempFilterResults = 'temp_filter_results';

  /// 临时排序结果
  static const String tempSortResults = 'temp_sort_results';

  /// 批量操作临时数据
  static const String batchOperationTemp = 'batch_operation_temp';

  /// 导入导出临时数据
  static const String importExportTemp = 'import_export_temp';

  /// 图片缓存临时数据
  static const String imageCacheTemp = 'image_cache_temp';

  /// 网络请求临时数据
  static const String networkRequestTemp = 'network_request_temp';

  /// 数据处理临时数据
  static const String dataProcessingTemp = 'data_processing_temp';

  /// 测试数据临时缓存
  static const String testDataTable = 'test_data_temp';
}

// ==================== 系统配置缓存键 ====================

/// 系统配置相关的缓存键
class SystemConfigKeys {
  SystemConfigKeys._();

  /// API配置信息
  static const String apiConfig = 'api_config';

  /// 缓存配置信息
  static const String cacheConfig = 'cache_config';

  /// 网络配置信息
  static const String networkConfig = 'network_config';

  /// 日志配置信息
  static const String logConfig = 'log_config';

  /// 安全配置信息
  static const String securityConfig = 'security_config';

  /// 性能配置信息
  static const String performanceConfig = 'performance_config';

  /// 调试配置信息
  static const String debugConfig = 'debug_config';

  /// 功能开关配置
  static const String featureFlags = 'feature_flags';

  /// 环境配置信息
  static const String environmentConfig = 'environment_config';

  /// 应用全局配置
  static const String appGlobalConfig = 'app_global_config';
}

// ==================== 缓存过期时间配置 ====================

/// 缓存过期时间配置
class ExpirationTimeConfig {
  ExpirationTimeConfig._();

  /// 短期缓存：5分钟
  static const Duration shortTerm = Duration(minutes: 5);

  /// 中期缓存：1小时
  static const Duration mediumTerm = Duration(hours: 1);

  /// 长期缓存：6小时
  static const Duration longTerm = Duration(hours: 6);

  /// 永久缓存：30天
  static const Duration permanent = Duration(days: 30);

  /// 实时数据缓存：1分钟
  static const Duration realtime = Duration(minutes: 1);

  /// 历史数据缓存：24小时
  static const Duration historical = Duration(hours: 24);

  /// 用户偏好缓存：30天
  static const Duration userPreference = Duration(days: 30);

  /// 系统配置缓存：7天
  static const Duration systemConfig = Duration(days: 7);

  /// 临时数据缓存：30分钟
  static const Duration temporary = Duration(minutes: 30);
}

// ==================== 缓存优先级配置 ====================

/// 缓存优先级配置
class PriorityConfig {
  PriorityConfig._();

  /// 低优先级
  static const String low = 'low';

  /// 普通优先级
  static const String normal = 'normal';

  /// 高优先级
  static const String high = 'high';

  /// 关键优先级
  static const String critical = 'critical';
}

/// 缓存键配置类
///
/// 集中管理所有缓存键相关的配置常量和便捷方法
class CacheKeyConfig {
  // 私有构造函数，防止实例化
  CacheKeyConfig._();

  // ==================== 便捷方法 ====================

  /// 生成基金数据缓存键
  static String generateFundDataKey(String dataType, String fundCode) {
    return CacheKeyManager.instance.generateKey(
      CacheKeyType.fundData,
      '${dataType}_$fundCode',
    );
  }

  /// 生成基金列表缓存键
  static String generateFundListKey(String listType,
      {Map<String, String>? filters}) {
    return CacheKeyManager.instance.fundListKey(listType, filters: filters);
  }

  /// 生成搜索索引缓存键
  static String generateSearchIndexKey(String indexType) {
    return CacheKeyManager.instance.searchIndexKey(indexType);
  }

  /// 生成用户偏好缓存键
  static String generateUserPreferenceKey(String preferenceName) {
    return CacheKeyManager.instance.userPreferenceKey(preferenceName);
  }

  /// 生成元数据缓存键
  static String generateMetadataKey(String metadataType, {String? specificId}) {
    return CacheKeyManager.instance
        .metadataKey(metadataType, specificId: specificId);
  }

  /// 生成临时数据缓存键
  static String generateTemporaryKey(String dataType, {String? sessionId}) {
    return CacheKeyManager.instance
        .temporaryKey(dataType, sessionId: sessionId);
  }

  /// 生成系统配置缓存键
  static String generateSystemConfigKey(String configName) {
    return CacheKeyManager.instance.systemConfigKey(configName);
  }
}
