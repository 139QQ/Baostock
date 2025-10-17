# 基速 (JiSu) - 基金探索页面数据库设计

## 数据库架构概述

基速将采用**分层数据存储策略**，专门针对基金探索页面的复杂需求：

### 1.1 存储架构分层
- **内存缓存层**：高频访问的基金列表、排行榜数据 (TTL: 15分钟)
- **Hive缓存层**：基金基础信息、搜索历史、用户偏好 (TTL: 24小时)
- **SQLite本地层**：完整基金数据、用户自选、分析结果 (持久化)
- **网络API层**：akshare实时数据、增量更新 (按需获取)

### 1.2 基金探索页面专用优化
- **搜索索引优化**：基金名称、代码、经理、公司全字段索引
- **筛选性能优化**：基金类型、风险等级、业绩指标预聚合存储
- **排行榜缓存**：不同时间维度排行榜数据预计算和缓存
- **对比分析缓存**：基金对比结果和分析指标本地存储

## 2. 基金探索页面专用表结构

## 本地数据库设计 (SQLite)

### 2.1 基金探索基础信息表 (`fund_discovery_basic`)

| 字段名             | 类型    | 描述             | 约束                      |
| :----------------- | :------ | :--------------- | :------------------------ |
| id                 | INTEGER | 主键             | PRIMARY KEY AUTOINCREMENT |
| fund_code          | TEXT    | 基金代码         | NOT NULL UNIQUE           |
| fund_name          | TEXT    | 基金名称         | NOT NULL                  |
| fund_name_abbr     | TEXT    | 基金简称         | NOT NULL                  |
| fund_type          | TEXT    | 基金类型         | NOT NULL                  |
| fund_company       | TEXT    | 基金管理公司     | NOT NULL                  |
| company_code       | TEXT    | 公司代码         |                           |
| manager_name       | TEXT    | 基金经理         |                           |
| manager_code       | TEXT    | 经理代码         |                           |
| risk_level         | TEXT    | 风险等级 (R1-R5) |                           |
| establish_date     | TEXT    | 成立日期         |                           |
| listing_date       | TEXT    | 上市日期         |                           |
| fund_scale         | REAL    | 基金规模(亿元)   |                           |
| minimum_investment | REAL    | 最低申购金额     |                           |
| management_fee     | REAL    | 管理费率         |                           |
| custody_fee        | REAL    | 托管费率         |                           |
| purchase_fee       | REAL    | 申购费率         |                           |
| redemption_fee     | REAL    | 赎回费率         |                           |
| performance_benchmark | TEXT | 业绩基准        |                           |
| investment_target  | TEXT    | 投资目标         |                           |
| investment_scope   | TEXT    | 投资范围         |                           |
| currency           | TEXT    | 币种             | DEFAULT 'CNY'            |
| status             | TEXT    | 状态             | DEFAULT 'active'         |
| created_at         | INTEGER | 创建时间戳       | NOT NULL                  |
| updated_at         | INTEGER | 更新时间戳       | NOT NULL                  |
| last_sync_time     | INTEGER | 最后同步时间     |                           |
| data_source        | TEXT    | 数据来源         |                           |

**索引优化：**
- INDEX `idx_fund_type` (`fund_type`)
- INDEX `idx_company` (`fund_company`)
- INDEX `idx_manager` (`manager_name`)
- INDEX `idx_risk_level` (`risk_level`)
- INDEX `idx_status` (`status`)
- INDEX `idx_updated_at` (`updated_at`)
- FULLTEXT INDEX `idx_search` (`fund_name`, `fund_name_abbr`, `fund_company`, `manager_name`)

### 2.2 基金净值历史表 (`fund_nav_history`)

| 字段名               | 类型    | 描述             | 约束                      |
| :------------------- | :------ | :--------------- | :------------------------ |
| id                   | INTEGER | 主键             | PRIMARY KEY AUTOINCREMENT |
| fund_code            | TEXT    | 基金代码         | NOT NULL                  |
| nav_date             | TEXT    | 净值日期         | NOT NULL                  |
| unit_nav             | REAL    | 单位净值         | NOT NULL                  |
| accumulated_nav      | REAL    | 累计净值         |                           |
| daily_return         | REAL    | 日涨跌幅(%)      |                           |
| total_net_assets     | REAL    | 基金总资产(亿元) |                           |
| subscription_status  | TEXT    | 申购状态         |                           |
| redemption_status    | TEXT    | 赎回状态         |                           |
| created_at           | INTEGER | 创建时间戳       | NOT NULL                  |
| updated_at           | INTEGER | 更新时间戳       | NOT NULL                  |

**索引优化：**
- UNIQUE INDEX `uk_fund_date` (`fund_code`, `nav_date`)
- INDEX `idx_nav_date` (`nav_date`)
- INDEX `idx_daily_return` (`daily_return`)
- INDEX `idx_fund_updated` (`fund_code`, `updated_at`)

### 2.3 基金业绩排名表 (`fund_performance_ranking`)

| 字段名               | 类型    | 描述                     | 约束                      |
| :------------------- | :------ | :----------------------- | :------------------------ |
| id                   | INTEGER | 主键                     | PRIMARY KEY AUTOINCREMENT |
| fund_code            | TEXT    | 基金代码                 | NOT NULL                  |
| ranking_date         | TEXT    | 排名日期                 | NOT NULL                  |
| time_period          | TEXT    | 时间周期                 | NOT NULL                  |
| return_rate          | REAL    | 收益率(%)                |                           |
| ranking_position     | INTEGER | 排名位置                 |                           |
| total_count          | INTEGER | 同类基金总数             |                           |
| ranking_percentile   | REAL    | 排名百分位               |                           |
| sharpe_ratio         | REAL    | 夏普比率                 |                           |
| max_drawdown         | REAL    | 最大回撤(%)              |                           |
| volatility           | REAL    | 波动率(%)                |                           |
| alpha                | REAL    | Alpha值                  |                           |
| beta                 | REAL    | Beta值                   |                           |
| created_at           | INTEGER | 创建时间戳               | NOT NULL                  |
| updated_at           | INTEGER | 更新时间戳               | NOT NULL                  |

**索引优化：**
- UNIQUE INDEX `uk_fund_ranking` (`fund_code`, `ranking_date`, `time_period`)
- INDEX `idx_ranking_date` (`ranking_date`)
- INDEX `idx_time_period` (`time_period`)
- INDEX `idx_return_rate` (`return_rate`)
- INDEX `idx_ranking_position` (`ranking_position`)
- INDEX `idx_sharpe_ratio` (`sharpe_ratio`)

### 2.4 基金经理信息表 (`fund_manager_info`)

| 字段名                      | 类型    | 描述                 | 约束                      |
| :-------------------------- | :------ | :------------------- | :------------------------ |
| id                          | INTEGER | 主键                 | PRIMARY KEY AUTOINCREMENT |
| manager_code                | TEXT    | 经理代码             | NOT NULL UNIQUE           |
| manager_name                | TEXT    | 经理姓名             | NOT NULL                  |
| avatar_url                  | TEXT    | 头像URL              |                           |
| education_background        | TEXT    | 教育背景             |                           |
| professional_experience     | TEXT    | 从业经历             |                           |
| manage_start_date           | TEXT    | 任职开始日期         |                           |
| total_manage_duration     | INTEGER | 总管理时长(天)       |                           |
| current_fund_count          | INTEGER | 当前管理基金数量     |                           |
| total_asset_under_management| REAL    | 管理总资产(亿元)     |                           |
| average_return_rate         | REAL    | 平均年化收益率(%)    |                           |
| best_fund_performance       | REAL    | 最佳基金业绩(%)      |                           |
| risk_adjusted_return        | REAL    | 风险调整后收益       |                           |
| created_at                  | INTEGER | 创建时间戳           | NOT NULL                  |
| updated_at                  | INTEGER | 更新时间戳           | NOT NULL                  |

**索引优化：**
- INDEX `idx_manager_name` (`manager_name`)
- INDEX `idx_manage_duration` (`total_manage_duration`)
- INDEX `idx_avg_return` (`average_return_rate`)
- INDEX `idx_current_funds` (`current_fund_count`)

### 2.5 基金公司信息表 (`fund_company_info`)

| 字段名                       | 类型    | 描述               | 约束                      |
| :--------------------------- | :------ | :----------------- | :------------------------ |
| id                           | INTEGER | 主键               | PRIMARY KEY AUTOINCREMENT |
| company_code                 | TEXT    | 公司代码           | NOT NULL UNIQUE           |
| company_name                 | TEXT    | 公司名称           | NOT NULL                  |
| company_short_name         | TEXT    | 公司简称           |                           |
| establishment_date           | TEXT    | 成立日期           |                           |
| registered_capital           | REAL    | 注册资本(亿元)     |                           |
| company_type                 | TEXT    | 公司类型           |                           |
| legal_representative       | TEXT    | 法定代表人       |                           |
| headquarters_location      | TEXT    | 总部所在地         |                           |
| website_url                  | TEXT    | 官方网站           |                           |
| contact_phone                | TEXT    | 联系电话           |                           |
| total_funds_under_management | INTEGER | 管理基金总数       |                           |
| total_asset_under_management | REAL    | 管理总资产(亿元)   |                           |
| company_rating               | TEXT    | 公司评级           |                           |
| rating_agency                | TEXT    | 评级机构           |                           |
| created_at                   | INTEGER | 创建时间戳         | NOT NULL                  |
| updated_at                   | INTEGER | 更新时间戳         | NOT NULL                  |

**索引优化：**
- INDEX `idx_company_name` (`company_name`)
- INDEX `idx_total_asset` (`total_asset_under_management`)
- INDEX `idx_company_rating` (`company_rating`)

### 2.6 基金持仓明细表 (`fund_portfolio_holdings`)

| 字段名              | 类型    | 描述             | 约束                      |
| :------------------ | :------ | :--------------- | :------------------------ |
| id                  | INTEGER | 主键             | PRIMARY KEY AUTOINCREMENT |
| fund_code           | TEXT    | 基金代码         | NOT NULL                  |
| report_date         | TEXT    | 报告日期         | NOT NULL                  |
| holding_type        | TEXT    | 持仓类型         | NOT NULL                  |
| stock_code          | TEXT    | 股票代码         |                           |
| stock_name          | TEXT    | 股票名称         |                           |
| holding_quantity    | INTEGER | 持股数量         |                           |
| holding_value       | REAL    | 持仓市值(万元)   |                           |
| holding_percentage  | REAL    | 持仓占比(%)      |                           |
| market_value        | REAL    | 股票市值         |                           |
| sector              | TEXT    | 所属行业         |                           |
| created_at          | INTEGER | 创建时间戳       | NOT NULL                  |
| updated_at          | INTEGER | 更新时间戳       | NOT NULL                  |

**索引优化：**
- UNIQUE INDEX `uk_fund_holding` (`fund_code`, `report_date`, `stock_code`)
- INDEX `idx_report_date` (`report_date`)
- INDEX `idx_holding_type` (`holding_type`)
- INDEX `idx_sector` (`sector`)
- INDEX `idx_holding_percentage` (`holding_percentage`)

### 2.7 热门基金推荐表 (`hot_fund_recommendations`)

| 字段名               | 类型    | 描述             | 约束                      |
| :------------------- | :------ | :--------------- | :------------------------ |
| id                   | INTEGER | 主键             | PRIMARY KEY AUTOINCREMENT |
| fund_code            | TEXT    | 基金代码         | NOT NULL                  |
| recommendation_type  | TEXT    | 推荐类型         | NOT NULL                  |
| ranking_position     | INTEGER | 推荐排名         |                           |
| recommendation_score | REAL    | 推荐评分         |                           |
| performance_1w       | REAL    | 近1周收益率(%)   |                           |
| performance_1m       | REAL    | 近1月收益率(%)   |                           |
| performance_3m       | REAL    | 近3月收益率(%)   |                           |
| performance_1y       | REAL    | 近1年收益率(%)   |                           |
| sharpe_ratio         | REAL    | 夏普比率         |                           |
| max_drawdown         | REAL    | 最大回撤(%)      |                           |
| popularity_score     | REAL    | 关注度评分       |                           |
| created_at           | INTEGER | 创建时间戳       | NOT NULL                  |
| updated_at           | INTEGER | 更新时间戳       | NOT NULL                  |
| expires_at           | INTEGER | 过期时间         |                           |

**索引优化：**
- INDEX `idx_rec_type` (`recommendation_type`)
- INDEX `idx_rec_score` (`recommendation_score`)
- INDEX `idx_performance_1y` (`performance_1y`)
- INDEX `idx_popularity` (`popularity_score`)
- INDEX `idx_expires` (`expires_at`)

### 2.8 基金排行榜表 (`fund_rankings`)

| 字段名               | 类型    | 描述             | 约束                      |
| :------------------- | :------ | :--------------- | :------------------------ |
| id                   | INTEGER | 主键             | PRIMARY KEY AUTOINCREMENT |
| fund_code            | TEXT    | 基金代码         | NOT NULL                  |
| ranking_date         | TEXT    | 排名日期         | NOT NULL                  |
| ranking_type         | TEXT    | 排名类型         | NOT NULL                  |
| time_period          | TEXT    | 时间周期         | NOT NULL                  |
| ranking_position     | INTEGER | 排名位置         |                           |
| total_count          | INTEGER | 同类基金总数     |                           |
| return_rate          | REAL    | 收益率(%)        |                           |
| ranking_percentile   | REAL    | 排名百分位       |                           |
| created_at           | INTEGER | 创建时间戳       | NOT NULL                  |
| updated_at           | INTEGER | 更新时间戳       | NOT NULL                  |

**索引优化：**
- INDEX `idx_ranking_type_date` (`ranking_type`, `ranking_date`)
- INDEX `idx_time_period` (`time_period`)
- INDEX `idx_ranking_position` (`ranking_position`)
- INDEX `idx_return_rate` (`return_rate`)

### 2.9 用户搜索历史表 (`user_search_history`)

| 字段名               | 类型    | 描述             | 约束                      |
| :------------------- | :------ | :--------------- | :------------------------ |
| id                   | INTEGER | 主键             | PRIMARY KEY AUTOINCREMENT |
| search_type          | TEXT    | 搜索类型         | NOT NULL                  |
| search_keyword       | TEXT    | 搜索关键词       | NOT NULL                  |
| search_result_count  | INTEGER | 搜索结果数量     |                           |
| clicked_result       | TEXT    | 点击的结果       |                           |
| search_timestamp     | INTEGER | 搜索时间戳       | NOT NULL                  |
| user_session_id      | TEXT    | 用户会话ID       |                           |

**索引优化：**
- INDEX `idx_search_type` (`search_type`)
- INDEX `idx_search_timestamp` (`search_timestamp`)
- INDEX `idx_search_keyword` (`search_keyword`)
- INDEX `idx_session` (`user_session_id`)

### 2.10 用户自选基金表 (`user_favorite_funds`)

| 字段名               | 类型    | 描述             | 约束                      |
| :------------------- | :------ | :--------------- | :------------------------ |
| id                   | INTEGER | 主键             | PRIMARY KEY AUTOINCREMENT |
| fund_code            | TEXT    | 基金代码         | NOT NULL                  |
| group_name           | TEXT    | 分组名称         | DEFAULT '默认'           |
| notes                | TEXT    | 用户备注         |                           |
| tags                 | TEXT    | 标签(JSON数组)   |                           |
| sort_order           | INTEGER | 排序顺序         | DEFAULT 0                |
| added_date           | INTEGER | 添加时间戳       | NOT NULL                  |
| alert_enabled        | INTEGER | 是否启用提醒     | DEFAULT 0                |
| alert_threshold      | REAL    | 提醒阈值         |                           |
| alert_type           | TEXT    | 提醒类型         |                           |

**索引优化：**
- UNIQUE INDEX `uk_user_fund_group` (`fund_code`, `group_name`)
- INDEX `idx_group_name` (`group_name`)
- INDEX `idx_added_date` (`added_date`)
- INDEX `idx_alert_enabled` (`alert_enabled`)

## 3. 基金探索页面专用缓存策略

### 3.1 多级缓存架构

```
用户请求 → 内存缓存 → Hive缓存 → SQLite数据库 → 网络API
     ↑         ↑         ↑           ↑           ↑
   15分钟    24小时    持久化     增量更新    实时数据
```

### 3.2 缓存数据类型与TTL配置

#### 热点数据缓存 (TTL: 15分钟)
```dart
class HotDataCache {
  static const Duration hotFunds = Duration(minutes: 15);      // 热门基金推荐
  static const Duration rankings = Duration(minutes: 15);      // 基金排行榜
  static const Duration marketDynamics = Duration(minutes: 15); // 市场动态
  static const Duration searchSuggestions = Duration(minutes: 15); // 搜索建议
}
```

#### 基础信息缓存 (TTL: 24小时)
```dart
class BasicDataCache {
  static const Duration fundBasicInfo = Duration(hours: 24);   // 基金基础信息
  static const Duration managerInfo = Duration(hours: 24);     // 基金经理信息
  static const Duration companyInfo = Duration(hours: 24);     // 基金公司信息
  static const Duration searchHistory = Duration(hours: 24);   // 搜索历史
}
```

#### 历史数据缓存 (TTL: 6小时)
```dart
class HistoricalDataCache {
  static const Duration navData = Duration(hours: 6);          // 净值数据
  static const Duration performanceData = Duration(hours: 6);  // 业绩数据
  static const Duration rankingData = Duration(hours: 6);      // 排名数据
  static const Duration chartData = Duration(hours: 6);        // 图表数据
}
```

### 3.3 Hive缓存对象设计

#### 基金搜索结果缓存
```dart
@HiveType(typeId: 10)
class FundSearchCache extends HiveObject {
  @HiveField(0)
  final String searchKey;           // 搜索关键词
  
  @HiveField(1)
  final List<String> fundCodes;     // 搜索结果基金代码列表
  
  @HiveField(2)
  final int resultCount;            // 结果数量
  
  @HiveField(3)
  final DateTime cachedAt;          // 缓存时间
  
  @HiveField(4)
  final DateTime expiresAt;         // 过期时间
  
  @HiveField(5)
  final Map<String, dynamic> filters; // 筛选条件
}
```

#### 基金排行榜缓存
```dart
@HiveType(typeId: 11)
class FundRankingCache extends HiveObject {
  @HiveField(0)
  final String rankingType;         // 排行榜类型
  
  @HiveField(1)
  final String timePeriod;          // 时间周期
  
  @HiveField(2)
  final String fundType;            // 基金类型
  
  @HiveField(3)
  final List<Map<String, dynamic>> rankings; // 排名数据
  
  @HiveField(4)
  final DateTime cachedAt;          // 缓存时间
  
  @HiveField(5)
  final DateTime expiresAt;         // 过期时间
}
```

#### 基金对比结果缓存
```dart
@HiveType(typeId: 12)
class FundComparisonCache extends HiveObject {
  @HiveField(0)
  final List<String> fundCodes;     // 对比的基金代码
  
  @HiveField(1)
  final Map<String, dynamic> comparisonData; // 对比数据
  
  @HiveField(2)
  final List<String> indicators;    // 对比指标
  
  @HiveField(3)
  final DateTime cachedAt;          // 缓存时间
  
  @HiveField(4)
  final DateTime expiresAt;         // 过期时间
}
```

## 4. 数据获取与同步策略

### 4.1 分层加载策略

#### 首屏加载策略
```dart
class FirstScreenLoadStrategy {
  // 1. 优先加载缓存数据 (显示界面)
  Future<List<Fund>> loadCachedFunds() async {
    return await hiveCache.getHotFunds();
  }
  
  // 2. 异步加载最新数据 (后台更新)
  Future<void> loadLatestFunds() async {
    final latestFunds = await apiService.getHotFunds();
    await hiveCache.saveHotFunds(latestFunds);
    await sqlite.saveFunds(latestFunds);
  }
  
  // 3. 增量更新机制
  Future<void> incrementalUpdate() async {
    final lastSyncTime = await getLastSyncTime();
    final changes = await apiService.getFundChanges(since: lastSyncTime);
    await applyChanges(changes);
  }
}
```

#### 滚动加载策略
```dart
class ScrollLoadStrategy {
  static const int pageSize = 20;   // 每页加载数量
  static const int preloadThreshold = 5; // 预加载阈值
  
  Future<List<Fund>> loadNextPage(int currentPage) async {
    final startIndex = currentPage * pageSize;
    
    // 1. 检查本地缓存
    final cachedFunds = await sqlite.getFunds(start: startIndex, limit: pageSize);
    if (cachedFunds.length >= pageSize) {
      return cachedFunds;
    }
    
    // 2. 本地不足时从API获取
    final apiFunds = await apiService.getFunds(start: startIndex, limit: pageSize);
    await sqlite.saveFunds(apiFunds);
    return apiFunds;
  }
}
```

### 4.2 按需加载详细数据

```dart
class OnDemandLoadStrategy {
  // 基金详情页按需加载
  Future<FundDetail> loadFundDetail(String fundCode) async {
    // 1. 基础信息 (缓存)
    final basicInfo = await getFundBasicInfo(fundCode);
    
    // 2. 实时数据 (API)
    final realtimeData = await apiService.getFundRealtime(fundCode);
    
    // 3. 历史数据 (本地缓存 + 增量更新)
    final navHistory = await getNavHistory(fundCode);
    
    // 4. 分析指标 (计算或缓存)
    final indicators = await calculateIndicators(fundCode);
    
    return FundDetail(
      basicInfo: basicInfo,
      realtimeData: realtimeData,
      navHistory: navHistory,
      indicators: indicators,
    );
  }
}
```

### 4.3 智能缓存失效机制

```dart
class SmartCacheInvalidation {
  // 基于数据变化频率的自适应失效
  Duration getCacheTTL(String dataType, String fundCode) {
    // 热门基金：更短TTL
    if (isHotFund(fundCode)) {
      return Duration(minutes: 15);
    }
    
    // 基于数据类型
    switch (dataType) {
      case 'nav':
        return Duration(hours: 4);
      case 'ranking':
        return Duration(hours: 6);
      case 'basic':
        return Duration(hours: 24);
      default:
        return Duration(hours: 12);
    }
  }
  
  // 用户行为触发的缓存更新
  Future<void> updateCacheByUserBehavior(String action, String fundCode) async {
    switch (action) {
      case 'view_detail':
        // 查看详情时预加载相关数据
        await preloadRelatedData(fundCode);
        break;
      case 'add_to_watchlist':
        // 添加到自选时更新关注数据
        await updateWatchlistData(fundCode);
        break;
      case 'search':
        // 搜索时更新搜索缓存
        await updateSearchCache(fundCode);
        break;
    }
  }
}
```

## 5. API接口优化策略

### 5.1 请求优化

#### 合并同类请求
```dart
class BatchRequestOptimizer {
  // 合并多个基金详情请求
  Future<List<FundDetail>> batchGetFundDetails(List<String> fundCodes) async {
    // 将多个单个请求合并为批量请求
    final batchSize = 50; // 每批最多50个基金
    final results = <FundDetail>[];
    
    for (int i = 0; i < fundCodes.length; i += batchSize) {
      final batch = fundCodes.sublist(i, min(i + batchSize, fundCodes.length));
      final batchResults = await apiService.getFundDetailsBatch(batch);
      results.addAll(batchResults);
    }
    
    return results;
  }
}
```

#### 请求取消机制
```dart
class RequestCancellation {
  final Map<String, CancelToken> _activeRequests = {};
  
  // 发起请求时创建取消令牌
  Future<T> makeCancellableRequest<T>(
    String requestId,
    Future<T> Function(CancelToken) request,
  ) async {
    final cancelToken = CancelToken();
    _activeRequests[requestId] = cancelToken;
    
    try {
      return await request(cancelToken);
    } finally {
      _activeRequests.remove(requestId);
    }
  }
  
  // 页面切换时取消相关请求
  void cancelRequestsByPattern(String pattern) {
    _activeRequests.forEach((requestId, cancelToken) {
      if (requestId.contains(pattern)) {
        cancelToken.cancel('Page navigation');
        _activeRequests.remove(requestId);
      }
    });
  }
}
```

### 5.2 接口参数优化

#### 新增接口建议
```dart
// 优化后的基金搜索接口
class OptimizedFundSearchApi {
  // 支持多维度搜索和筛选
  Future<FundSearchResponse> searchFunds({
    required String keyword,
    String? fundType,           // 基金类型筛选
    String? riskLevel,          // 风险等级筛选
    String? company,            // 基金公司筛选
    String? manager,            // 基金经理筛选
    DateTime? establishStart,   // 成立时间范围
    DateTime? establishEnd,
    double? minScale,           // 规模范围
    double? maxScale,
    String? sortBy,             // 排序字段
    String? sortOrder,          // 排序方式
    int page = 1,               // 分页参数
    int pageSize = 20,
    List<String>? fields,       // 指定返回字段
  }) async {
    // 实现搜索逻辑
  }
}

// 基金对比分析接口
class FundComparisonApi {
  Future<FundComparisonResponse> compareFunds({
    required List<String> fundCodes,    // 对比基金代码
    required List<String> timePeriods,  // 时间周期
    required List<String> indicators,   // 对比指标
    bool includeHoldings = false,       // 是否包含持仓对比
    bool includeRisk = true,            // 是否包含风险指标
  }) async {
    // 实现对比分析逻辑
  }
}

// 定投计算接口
class InvestmentCalculatorApi {
  Future<InvestmentCalcResult> calculateSIP({
    required String fundCode,           // 基金代码
    required double amount,             // 定投金额
    required String frequency,          // 定投频率
    required int durationMonths,        // 定投时长(月)
    DateTime? startDate,                // 开始日期
    double? stepUpRate,                 // 递增率
    bool adjustForInflation = false,    // 是否考虑通胀
  }) async {
    // 实现定投计算逻辑
  }
}
```

## 6. 性能监控与优化

### 6.1 数据库性能监控

```dart
class DatabasePerformanceMonitor {
  // 查询性能监控
  Future<QueryPerformance> monitorQueryPerformance(
    String query,
    Future<dynamic> Function() queryExecution,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await queryExecution();
      stopwatch.stop();
      
      return QueryPerformance(
        query: query,
        executionTime: stopwatch.elapsedMilliseconds,
        success: true,
        resultCount: result.length,
      );
    } catch (e) {
      stopwatch.stop();
      
      return QueryPerformance(
        query: query,
        executionTime: stopwatch.elapsedMilliseconds,
        success: false,
        error: e.toString(),
      );
    }
  }
  
  // 慢查询日志
  void logSlowQuery(QueryPerformance performance) {
    if (performance.executionTime > 1000) { // 超过1秒视为慢查询
      // 记录慢查询日志
      _slowQueryLog.add({
        'timestamp': DateTime.now().toIso8601String(),
        'query': performance.query,
        'executionTime': performance.executionTime,
        'resultCount': performance.resultCount,
      });
    }
  }
}
```

### 6.2 缓存命中率监控

```dart
class CacheHitRateMonitor {
  int _totalRequests = 0;
  int _cacheHits = 0;
  
  void recordRequest(bool isCacheHit) {
    _totalRequests++;
    if (isCacheHit) _cacheHits++;
  }
  
  double get hitRate {
    return _totalRequests > 0 ? _cacheHits / _totalRequests : 0.0;
  }
  
  Map<String, dynamic> getStats() {
    return {
      'totalRequests': _totalRequests,
      'cacheHits': _cacheHits,
      'cacheMisses': _totalRequests - _cacheHits,
      'hitRate': hitRate,
      'hitRatePercentage': (hitRate * 100).toStringAsFixed(2) + '%',
    };
  }
}
```

### 6.3 异常处理与恢复

```dart
class DataExceptionHandler {
  // 数据库异常处理
  Future<T> handleDatabaseException<T>(
    Future<T> Function() operation,
  ) async {
    try {
      return await operation();
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        // 唯一约束冲突，尝试更新而非插入
        return await handleUniqueConstraintError(operation);
      } else if (e.isDatabaseLockedError()) {
        // 数据库锁定，重试机制
        return await retryOperation(operation, maxRetries: 3);
      } else {
        // 其他数据库异常
        rethrow;
      }
    }
  }
  
  // 网络异常处理
  Future<T> handleNetworkException<T>(
    Future<T> Function() operation,
  ) async {
    try {
      return await operation();
    } on SocketException catch (e) {
      // 网络连接异常，使用离线数据
      return await useOfflineData<T>();
    } on TimeoutException catch (e) {
      // 请求超时，使用缓存数据
      return await useCachedData<T>();
    } on HttpException catch (e) {
      // HTTP异常，根据状态码处理
      return await handleHttpException<T>(e);
    }
  }
}
```

这个数据库设计专门针对基金探索页面的需求，提供了完整的数据存储、缓存、同步和优化方案。通过分层存储、智能缓存、批量请求等策略，确保基金探索页面的高性能和良好用户体验。

| 字段名     | 类型    | 描述         | 约束                      |
| :--------- | :------ | :----------- | :------------------------ |
| id         | INTEGER | 主键         | PRIMARY KEY AUTOINCREMENT |
| key        | TEXT    | 配置键       | NOT NULL UNIQUE           |
| value      | TEXT    | 配置值(JSON) | NOT NULL                  |
| updated_at | INTEGER | 更新时间戳   | NOT NULL                  |

### 5. 缓存元数据表 (`cache_metadata`)

| 字段名       | 类型    | 描述                    | 约束                      |
| :----------- | :------ | :---------------------- | :------------------------ |
| id           | INTEGER | 主键                    | PRIMARY KEY AUTOINCREMENT |
| data_type    | TEXT    | 数据类型                | NOT NULL                  |
| identifier   | TEXT    | 标识符                  | NOT NULL                  |
| last_updated | INTEGER | 最后更新时间            | NOT NULL                  |
| expires_at   | INTEGER | 过期时间                | NOT NULL                  |
| **复合索引** |         | (data_type, identifier) | UNIQUE                    |





### 数据库连接配置



```dart
// 数据库连接配置
const sqlServerConfig = {
  'host': '154.44.25.92',
  'port': 1433,
  'username': 'SA',
  'password': 'Miami@2024',
  'database': 'JiSuDB',
  'timeout': 30,
  'encrypt': true, // 启用加密连接
};
```



### 用户账户系统设计

#### 1. 用户表 (`Users`)

## 本地键值存储设计 (Hive)





```sql
CREATE TABLE Users (
    UserId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    Username NVARCHAR(50) NOT NULL UNIQUE,
    Email NVARCHAR(100) NOT NULL UNIQUE,
    PasswordHash NVARCHAR(255) NOT NULL,
    PasswordSalt NVARCHAR(255) NOT NULL,
    DisplayName NVARCHAR(100),
    AvatarUrl NVARCHAR(255),
    CreatedAt DATETIME2 DEFAULT GETUTCDATE(),
    LastLoginAt DATETIME2,
    IsActive BIT DEFAULT 1,
    SubscriptionType INT DEFAULT 0, -- 0: 免费版, 1: 专业版, 2: 企业版
    SubscriptionExpiry DATETIME2,
    CONSTRAINT CHK_Username_Length CHECK (LEN(Username) >= 3),
    CONSTRAINT CHK_Email_Format CHECK (Email LIKE '%_@%_.%_')
);

CREATE INDEX IX_Users_Email ON Users(Email);
CREATE INDEX IX_Users_Username ON Users(Username);
```



#### 2. 用户会话表 (`UserSessions`)



```sql
CREATE TABLE UserSessions (
    SessionId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    UserId UNIQUEIDENTIFIER NOT NULL,
    DeviceId NVARCHAR(255),
    DeviceType NVARCHAR(50),
    AuthToken NVARCHAR(255) NOT NULL,
    RefreshToken NVARCHAR(255) NOT NULL,
    CreatedAt DATETIME2 DEFAULT GETUTCDATE(),
    ExpiresAt DATETIME2 NOT NULL,
    LastActivityAt DATETIME2 DEFAULT GETUTCDATE(),
    IsRevoked BIT DEFAULT 0,
    FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE CASCADE
);

CREATE INDEX IX_UserSessions_UserId ON UserSessions(UserId);
CREATE INDEX IX_UserSessions_AuthToken ON UserSessions(AuthToken);
CREATE INDEX IX_UserSessions_RefreshToken ON UserSessions(RefreshToken);
```



### 基金数据表优化

#### 1. 基金基本信息表 (`Funds`)

sql

```
CREATE TABLE Funds (
    FundId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    FundCode NVARCHAR(20) NOT NULL UNIQUE,
    FundName NVARCHAR(200) NOT NULL,
    FundType NVARCHAR(50) NOT NULL,
    CompanyId UNIQUEIDENTIFIER,
    CompanyName NVARCHAR(200),
    EstablishmentDate DATE,
    Benchmark NVARCHAR(100),
    RiskLevel INT, -- R1-R5
    MinInvestment DECIMAL(18, 2),
    ManagementFee DECIMAL(5, 4),
    CustodyFee DECIMAL(5, 4),
    CreatedAt DATETIME2 DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME2 DEFAULT GETUTCDATE(),
    IsActive BIT DEFAULT 1,
    CONSTRAINT UQ_FundCode UNIQUE (FundCode)
);

CREATE INDEX IX_Funds_FundCode ON Funds(FundCode);
CREATE INDEX IX_Funds_FundType ON Funds(FundType);
CREATE INDEX IX_Funds_CompanyId ON Funds(CompanyId);
```



#### 2. 基金净值表 (`FundNavs`)

sql

```
CREATE TABLE FundNavs (
    NavId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    FundId UNIQUEIDENTIFIER NOT NULL,
    NavDate DATE NOT NULL,
    NetValue DECIMAL(10, 4) NOT NULL,
    AccumulatedValue DECIMAL(10, 4),
    DailyReturn DECIMAL(8, 4),
    TotalNetAssets DECIMAL(18, 2), -- 基金规模
    CreatedAt DATETIME2 DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME2 DEFAULT GETUTCDATE(),
    FOREIGN KEY (FundId) REFERENCES Funds(FundId) ON DELETE CASCADE,
    CONSTRAINT UQ_FundId_NavDate UNIQUE (FundId, NavDate)
);

CREATE INDEX IX_FundNavs_FundId ON FundNavs(FundId);
CREATE INDEX IX_FundNavs_NavDate ON FundNavs(NavDate);
CREATE INDEX IX_FundNavs_FundId_NavDate ON FundNavs(FundId, NavDate);
```



#### 3. 用户自选基金表 (`UserWatchlists`)

sql

```sql
CREATE TABLE UserWatchlists (
    WatchlistId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    UserId UNIQUEIDENTIFIER NOT NULL,
    FundId UNIQUEIDENTIFIER NOT NULL,
    GroupName NVARCHAR(100) DEFAULT '默认',
    Notes NVARCHAR(500),
    Tags NVARCHAR(500), -- JSON格式存储标签
    SortOrder INT DEFAULT 0,
    AddedAt DATETIME2 DEFAULT GETUTCDATE(),
    NotifyPriceChange BIT DEFAULT 0,
    NotifyThreshold DECIMAL(8, 4),
    FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE CASCADE,
    FOREIGN KEY (FundId) REFERENCES Funds(FundId) ON DELETE CASCADE,
    CONSTRAINT UQ_User_Fund_Group UNIQUE (UserId, FundId, GroupName)
);

CREATE INDEX IX_UserWatchlists_UserId ON UserWatchlists(UserId);
CREATE INDEX IX_UserWatchlists_FundId ON UserWatchlists(FundId);
```



对于非关系型数据，使用Hive进行存储：

### 1. 基金指标缓存

```dart
@HiveType(typeId: 1)
class FundMetricsCache extends HiveObject {
  @HiveField(0)
  final String fundCode;
  
  @HiveField(1)
  final Map<String, dynamic> metrics; // 夏普比率、最大回撤等
  
  @HiveField(2)
  final DateTime calculatedAt;
  
  @HiveField(3)
  final DateTime expiresAt;
}

```

### 2. 图表数据缓存

```dart
@HiveType(typeId: 2)
class ChartDataCache extends HiveObject {
  @HiveField(0)
  final String chartKey; // 如: "fund_000001_trend_1y"
  
  @HiveField(1)
  final List<Map<String, dynamic>> data;
  
  @HiveField(2)
  final DateTime generatedAt;
  
  @HiveField(3)
  final DateTime expiresAt;
}
```

### 3. 应用状态

```dart
@HiveType(typeId: 3)
class AppState extends HiveObject {
  @HiveField(0)
  final String currentPage;
  
  @HiveField(1)
  final Map<String, dynamic> pageState;
  
  @HiveField(2)
  final DateTime savedAt;
}
```

## 数据访问层设计

### 1. 数据库助手类



```dart
class DatabaseHelper {
  static Database? _database;
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), 'jisu.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
      onConfigure: _onConfigure,
    );
  }
  
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }
  
  Future<void> _createDatabase(Database db, int version) async {
    // 创建所有表
    await db.execute('''
      CREATE TABLE funds(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        company TEXT,
        establishment_date TEXT,
        benchmark TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    
    // 其他表的创建语句...
  }
}
```

### 2. 数据仓库模式



```dart
abstract class FundRepository {
  Future<Fund> getFundByCode(String code);
  Future<List<Fund>> searchFunds(String query);
  Future<List<NavData>> getNavHistory(String fundCode, DateTime start, DateTime end);
  Future<void> addToWatchlist(String fundCode);
  Future<void> removeFromWatchlist(String fundCode);
  Future<List<Fund>> getWatchlist();
}

class FundRepositoryImpl implements FundRepository {
  final AkshareApiService apiService;
  final LocalDataSource localDataSource;
  
  @override
  Future<Fund> getFundByCode(String code) async {
    // 先尝试从本地获取
    try {
      final localFund = await localDataSource.getFund(code);
      if (localFund != null && !_isDataExpired(localFund.updatedAt)) {
        return localFund;
      }
    } catch (e) {
      // 本地数据获取失败，继续从API获取
    }
    
    // 从API获取
    final fund = await apiService.getFundDetail(code);
    // 保存到本地
    await localDataSource.saveFund(fund);
    return fund;
  }
  
  // 其他方法实现...
}
```

## 数据缓存策略

### 1. 缓存时间配置



```dart
class CachePolicy {
  static const Duration fundBasicInfo = Duration(hours: 24);
  static const Duration fundNavData = Duration(hours: 4);
  static const Duration fundMetrics = Duration(hours: 12);
  static const Duration chartData = Duration(hours: 6);
  static const Duration searchResults = Duration(minutes: 30);
}
```

### 2. 缓存清理策略

dart

```dart
class CacheManager {
  Future<void> cleanExpiredCache() async {
    final db = await DatabaseHelper().database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // 清理过期的净值数据(保留最近365天)
    await db.delete(
      'fund_nav',
      where: 'date < ? AND created_at < ?',
      whereArgs: [
        DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 365))),
        now - const Duration(days: 30).inMilliseconds
      ]
    );
    
    // 清理缓存元数据表中的过期条目
    await db.delete(
      'cache_metadata',
      where: 'expires_at < ?',
      whereArgs: [now]
    );
  }
  
  Future<void> optimizeDatabase() async {
    // 定期执行VACUUM优化数据库
    final db = await DatabaseHelper().database;
    await db.execute('VACUUM');
  }
}
```

## 云端数据同步设计（未来扩展）

### 1. 用户数据同步表

dart

```dart
// 用于跟踪需要同步的更改
class SyncQueue {
  final int id;
  final String tableName;
  final String operation; // INSERT, UPDATE, DELETE
  final String recordId;
  final String data; // JSON格式的数据
  final int createdAt;
  final int syncedAt; // 0表示未同步
}
```

### 2. 同步服务接口

dart

```dart
abstract class SyncService {
  Future<bool> syncWatchlist();
  Future<bool> syncUserSettings();
  Future<bool> syncPortfolios();
  Future<bool> fullSync();
}
```

## 数据库迁移策略

### 版本管理



```dart
class MigrationManager {
  static const Map<int, List<String>> migrations = {
    1: [
      // 初始表创建
      'CREATE TABLE funds(...)',
      'CREATE TABLE fund_nav(...)',
      // ... 其他初始表
    ],
    2: [
      // 版本2的迁移脚本
      'ALTER TABLE funds ADD COLUMN risk_level INTEGER DEFAULT 0',
    ],
    // 后续版本...
  };
  
  static Future<void> migrate(Database db, int oldVersion, int newVersion) async {
    for (int version = oldVersion + 1; version <= newVersion; version++) {
      if (migrations.containsKey(version)) {
        final batch = db.batch();
        for (final script in migrations[version]!) {
          batch.execute(script);
        }
        await batch.commit();
      }
    }
  }
}
```

## 桌面端特定优化

### 1. 大容量数据存储



```dart
// 针对桌面端可能存储大量历史数据优化
class DesktopStorageOptimizer {
  static Future<void> configureForDesktop() async {
    // 增加SQLite缓存大小
    final db = await DatabaseHelper().database;
    await db.execute('PRAGMA cache_size = -10000'); // 10MB缓存
    await db.execute('PRAGMA journal_mode = WAL'); // 写前日志模式
    await db.execute('PRAGMA synchronous = NORMAL'); // 平衡性能与安全性
  }
}
```

### 2. 本地文件存储



```dart
// 用于存储导出报表、备份等
class FileStorageManager {
  static Future<File> getExportFile(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${directory.path}/exports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return File('${exportDir.path}/$fileName');
  }
  
  static Future<File> getBackupFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${directory.path}/backups');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return File('${backupDir.path}/jisu_backup_$timestamp.db');
  }
}
```

这个数据库设计充分考虑了桌面端应用的特点，包括大容量数据存储、本地缓存策略和性能优化。设计采用了分层架构，使得未来扩展到移动端或Web端时，只需调整数据访问层的实现即可。



后续优化建议

### 数据同步与缓存机制

#### 1. 数据同步状态表 (`DataSyncStatus`)

sql

```
CREATE TABLE DataSyncStatus (
    SyncId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    UserId UNIQUEIDENTIFIER NOT NULL,
    DataType NVARCHAR(50) NOT NULL, -- 'Watchlist', 'Settings', 'Portfolio'
    LastSyncVersion BIGINT DEFAULT 0,
    LastSyncTime DATETIME2 DEFAULT GETUTCDATE(),
    SyncStatus NVARCHAR(20) DEFAULT 'Success', -- Success, Failed, InProgress
    ErrorMessage NVARCHAR(500),
    DeviceId NVARCHAR(255),
    FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE CASCADE,
    CONSTRAINT UQ_User_DataType_Device UNIQUE (UserId, DataType, DeviceId)
);
```



### 数据库访问层优化

#### 1. SQL Server 数据库助手类

dart

```
class SqlServerDatabase {
  final String connectionString;
  
  SqlServerDatabase({required this.connectionString});
  
  Future<SqlConnection> getConnection() async {
    final conn = SqlConnection(connectionString);
    await conn.open();
    return conn;
  }
  
  // 用户认证相关方法
  Future<User?> authenticateUser(String username, String password) async {
    final conn = await getConnection();
    try {
      final result = await conn.query(
        'SELECT UserId, Username, Email, DisplayName, PasswordHash, PasswordSalt '
        'FROM Users WHERE Username = @username AND IsActive = 1',
        parameters: {'username': username}
      );
      
      if (result.isEmpty) return null;
      
      final userRow = result.first;
      final storedHash = userRow['PasswordHash'] as String;
      final salt = userRow['PasswordSalt'] as String;
      
      // 验证密码
      final inputHash = _hashPassword(password, salt);
      if (inputHash != storedHash) return null;
      
      return User(
        id: userRow['UserId'],
        username: userRow['Username'],
        email: userRow['Email'],
        displayName: userRow['DisplayName'],
      );
    } finally {
      await conn.close();
    }
  }
  
  String _hashPassword(String password, String salt) {
    // 实现密码哈希算法
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  // 基金数据查询方法
  Future<List<Fund>> searchFunds(String query, {int limit = 50}) async {
    final conn = await getConnection();
    try {
      final result = await conn.query(
        'SELECT TOP (@limit) * FROM Funds '
        'WHERE (FundCode LIKE @query OR FundName LIKE @query) '
        'AND IsActive = 1 ORDER BY FundCode',
        parameters: {
          'query': '%$query%',
          'limit': limit
        }
      );
      
      return result.map((row) => Fund.fromSqlRow(row)).toList();
    } finally {
      await conn.close();
    }
  }
}
```



#### 2. 混合数据仓库实现

dart

```
class HybridFundRepository implements FundRepository {
  final SqlServerDatabase cloudDb;
  final LocalDatabase localDb;
  final Connectivity connectivity;
  
  HybridFundRepository({
    required this.cloudDb,
    required this.localDb,
    required this.connectivity
  });
  
  @override
  Future<List<Fund>> searchFunds(String query) async {
    final hasConnection = await connectivity.hasNetworkConnection();
    
    if (hasConnection) {
      try {
        // 从云端获取数据
        final funds = await cloudDb.searchFunds(query);
        // 缓存到本地
        await localDb.cacheFunds(funds);
        return funds;
      } catch (e) {
        // 云端失败时使用本地缓存
        return localDb.searchFunds(query);
      }
    } else {
      // 无网络时使用本地缓存
      return localDb.searchFunds(query);
    }
  }
  
  @override
  Future<void> addToWatchlist(String fundCode, String userId) async {
    final hasConnection = await connectivity.hasNetworkConnection();
    
    if (hasConnection) {
      try {
        // 直接同步到云端
        await cloudDb.addToWatchlist(fundCode, userId);
      } catch (e) {
        // 云端失败时保存到本地同步队列
        await localDb.addToSyncQueue(
          operation: 'ADD_WATCHLIST',
          data: {'fundCode': fundCode, 'userId': userId}
        );
      }
    } else {
      // 无网络时保存到本地同步队列
      await localDb.addToSyncQueue(
        operation: 'ADD_WATCHLIST',
        data: {'fundCode': fundCode, 'userId': userId}
      );
    }
  }
}
```



### 安全性与性能优化

#### 1. 数据库连接池配置

dart

```
// 数据库连接池管理
class ConnectionPool {
  static final _pool = _createPool();
  
  static Future<Pool> _createPool() async {
    return Pool(
      () => SqlConnection(sqlServerConfig['connectionString']),
      max: 10, // 最大连接数
      min: 2,  // 最小连接数
      idleTimeout: Duration(minutes: 5),
    );
  }
  
  static Future<T> withConnection<T>(Future<T> Function(SqlConnection) action) async {
    final conn = await _pool.acquire();
    try {
      return await action(conn);
    } finally {
      _pool.release(conn);
    }
  }
}
```



#### 2. 数据加密与安全

dart

```
// 敏感数据加密
class DataEncryption {
  static final _encrypter = Encrypter(AES(Key.fromLength(32)));
  
  static String encrypt(String data) {
    return _encrypter.encrypt(data).base64;
  }
  
  static String decrypt(String encryptedData) {
    return _encrypter.decrypt(Encrypted.fromBase64(encryptedData));
  }
}
```



### 数据同步策略

#### 1. 后台同步服务

dart

```
class BackgroundSyncService {
  final LocalDatabase localDb;
  final SqlServerDatabase cloudDb;
  final Connectivity connectivity;
  
  BackgroundSyncService({
    required this.localDb,
    required this.cloudDb,
    required this.connectivity
  });
  
  Future<void> startSync() async {
    // 检查网络连接
    final hasConnection = await connectivity.hasNetworkConnection();
    if (!hasConnection) return;
    
    // 同步待处理的操作
    await _syncPendingOperations();
    
    // 同步用户数据
    await _syncUserData();
    
    // 同步基金数据缓存
    await _syncFundDataCache();
  }
  
  Future<void> _syncPendingOperations() async {
    final pendingOps = await localDb.getPendingSyncOperations();
    
    for (final op in pendingOps) {
      try {
        switch (op.operation) {
          case 'ADD_WATCHLIST':
            await cloudDb.addToWatchlist(op.data['fundCode'], op.data['userId']);
            break;
          case 'REMOVE_WATCHLIST':
            await cloudDb.removeFromWatchlist(op.data['fundCode'], op.data['userId']);
            break;
          // 其他操作类型...
        }
        
        // 同步成功，移除待处理操作
        await localDb.removeSyncOperation(op.id);
      } catch (e) {
        // 同步失败，更新重试次数
        await localDb.updateSyncOperationRetry(op.id);
      }
    }
  }
}
```



## 部署与维护建议

### 1. 数据库备份策略

sql

```
-- 创建自动备份作业
USE [JiSuDB];
GO

-- 完整备份（每日）
EXEC msdb.dbo.sp_add_job
    @job_name = N'JiSuDB_FullBackup',
    @enabled = 1;
GO

-- 差异备份（每小时）
EXEC msdb.dbo.sp_add_job
    @job_name = N'JiSuDB_DiffBackup',
    @enabled = 1;
GO
```



### 2. 性能监控与优化

sql

```
-- 创建索引使用情况监控
SELECT 
    OBJECT_NAME(i.object_id) AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    s.user_seeks,
    s.user_scans,
    s.user_lookups,
    s.user_updates
FROM sys.indexes i
LEFT JOIN sys.dm_db_index_usage_stats s 
    ON s.object_id = i.object_id AND s.index_id = i.index_id
WHERE OBJECT_NAME(i.object_id) IN ('Funds', 'FundNavs', 'UserWatchlists')
ORDER BY TableName, IndexName;
```