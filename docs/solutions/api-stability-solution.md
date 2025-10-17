# API服务稳定性风险解决方案

## 问题概述

**当前状态**：过度依赖单一自建API (http://154.44.25.92:8080/)
**风险级别**：高 - 单点故障可能导致整个应用不可用
**业务影响**：基金数据服务中断，用户无法进行基金分析和投资决策

## 解决方案目标

1. **建立多数据源降级机制**，确保API服务的高可用性
2. **实现智能数据源切换算法**，自动选择最优数据源
3. **定义降级触发条件**，建立故障自动检测和切换机制
4. **保障数据一致性**，确保多数据源间的数据同步和准确性

## 技术架构设计

### 1. 多数据源架构

```
┌─────────────────────────────────────────────────────────────┐
│                    数据源管理层 (Data Source Manager)                      │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐   │
│  │  自建API服务  │ │  商业API备选  │ │  官方数据源  │ │  模拟数据层  │   │
│  │  (主要数据源) │ │  (备选数据源) │ │  (权威验证)  │ │  (降级保障)  │   │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    智能切换引擎 (Smart Switch Engine)                      │
├─────────────────────────────────────────────────────────────┤
│  - 健康状态监控    - 响应时间检测    - 数据质量评估    │
│  - 故障自动切换    - 负载均衡算法    - 缓存策略管理    │
└─────────────────────────────────────────────────────────────┘
```

### 2. 数据源优先级配置

| 优先级 | 数据源类型 | 具体实现 | 响应时间要求 | 数据质量要求 |
|--------|------------|----------|--------------|--------------|
| P1 | 自建API服务 | http://154.44.25.92:8080/ | ≤500ms | 完整度≥95% |
| P2 | 商业API备选 | 阿里云/腾讯云基金API | ≤800ms | 完整度≥90% |
| P3 | 官方数据源 | AKShare直连+官方接口 | ≤1200ms | 完整度≥98% |
| P4 | 模拟数据层 | 本地缓存+生成算法 | ≤100ms | 基础数据保障 |

## 详细技术实现

### 1. 多数据源管理器

```dart
// lib/src/core/network/multi_data_source_manager.dart

import 'dart:async';
import 'dart:collection';
import 'package:http/http.dart' as http;
import '../utils/logger.dart';
import 'fund_api_client.dart';

/// 数据源健康状态枚举
enum DataSourceHealth {
  healthy,    // 健康
  degraded,   // 降级
  unhealthy,  // 不可用
  unknown     // 未知
}

/// 数据源配置信息
class DataSourceConfig {
  final String name;
  final String baseUrl;
  final int priority;
  final Duration timeout;
  final int maxRetries;
  final double healthThreshold; // 健康阈值

  const DataSourceConfig({
    required this.name,
    required this.baseUrl,
    required this.priority,
    this.timeout = const Duration(seconds: 30),
    this.maxRetries = 3,
    this.healthThreshold = 0.8,
  });
}

/// 数据源状态信息
class DataSourceStatus {
  final String name;
  final DataSourceHealth health;
  final double responseTime;
  final double successRate;
  final DateTime lastCheck;
  final String? errorMessage;

  DataSourceStatus({
    required this.name,
    required this.health,
    required this.responseTime,
    required this.successRate,
    required this.lastCheck,
    this.errorMessage,
  });
}

/// 多数据源管理器
class MultiDataSourceManager {
  static final MultiDataSourceManager _instance = MultiDataSourceManager._internal();
  factory MultiDataSourceManager() => _instance;
  MultiDataSourceManager._internal();

  // 数据源配置
  final List<DataSourceConfig> _dataSources = [
    const DataSourceConfig(
      name: 'self_hosted',
      baseUrl: 'http://154.44.25.92:8080',
      priority: 1,
      timeout: Duration(seconds: 30),
      maxRetries: 3,
      healthThreshold: 0.9,
    ),
    const DataSourceConfig(
      name: 'aliyun_api',
      baseUrl: 'https://fund-api.aliyun.com',
      priority: 2,
      timeout: Duration(seconds: 45),
      maxRetries: 2,
      healthThreshold: 0.85,
    ),
    const DataSourceConfig(
      name: 'tencent_api',
      baseUrl: 'https://fund-api.tencent.com',
      priority: 3,
      timeout: Duration(seconds: 45),
      maxRetries: 2,
      healthThreshold: 0.85,
    ),
    const DataSourceConfig(
      name: 'akshare_direct',
      baseUrl: 'https://aktools.akfamily.xyz/api',
      priority: 4,
      timeout: Duration(seconds: 60),
      maxRetries: 2,
      healthThreshold: 0.8,
    ),
  ];

  // 数据源状态缓存
  final Map<String, DataSourceStatus> _statusCache = {};
  final Map<String, DateTime> _lastHealthCheck = {};

  // 当前活跃数据源
  String _activeDataSource = 'self_hosted';

  // 健康检查定时器
  Timer? _healthCheckTimer;

  /// 初始化多数据源管理器
  Future<void> initialize() async {
    AppLogger.info('初始化多数据源管理器');

    // 启动健康检查定时器
    _healthCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _performHealthCheck();
    });

    // 执行初始健康检查
    await _performHealthCheck();
  }

  /// 获取当前活跃数据源
  String get activeDataSource => _activeDataSource;

  /// 获取数据源状态
  DataSourceStatus? getDataSourceStatus(String name) {
    return _statusCache[name];
  }

  /// 获取所有数据源状态
  Map<String, DataSourceStatus> getAllDataSourceStatuses() {
    return Map.from(_statusCache);
  }

  /// 手动切换到指定数据源
  Future<bool> switchToDataSource(String name) async {
    final config = _dataSources.firstWhere(
      (ds) => ds.name == name,
      orElse: () => _dataSources.first,
    );

    if (config.name != name) {
      AppLogger.warning('数据源 $name 不存在，使用默认数据源');
      return false;
    }

    final status = _statusCache[name];
    if (status?.health != DataSourceHealth.healthy) {
      AppLogger.warning('数据源 $name 不健康，无法切换');
      return false;
    }

    _activeDataSource = name;
    AppLogger.info('已切换到数据源: $name');
    return true;
  }

  /// 执行健康检查
  Future<void> _performHealthCheck() async {
    AppLogger.debug('开始执行数据源健康检查');

    for (final config in _dataSources) {
      try {
        final status = await _checkDataSourceHealth(config);
        _statusCache[config.name] = status;
        _lastHealthCheck[config.name] = DateTime.now();

        AppLogger.debug('数据源 ${config.name} 健康状态: ${status.health}');
      } catch (e) {
        AppLogger.error('检查数据源 ${config.name} 健康状态失败: $e');

        _statusCache[config.name] = DataSourceStatus(
          name: config.name,
          health: DataSourceHealth.unhealthy,
          responseTime: double.infinity,
          successRate: 0.0,
          lastCheck: DateTime.now(),
          errorMessage: e.toString(),
        );
      }
    }

    // 自动切换到最健康的数据源
    await _autoSwitchToBestDataSource();
  }

  /// 检查单个数据源健康状态
  Future<DataSourceStatus> _checkDataSourceHealth(DataSourceConfig config) async {
    final stopwatch = Stopwatch()..start();

    try {
      // 测试API连通性（使用基金列表接口）
      final response = await http.get(
        Uri.parse('${config.baseUrl}/api/public/fund_name_em'),
        headers: {'Accept': 'application/json'},
      ).timeout(config.timeout);

      stopwatch.stop();

      final responseTime = stopwatch.elapsedMilliseconds.toDouble();
      final success = response.statusCode == 200;

      // 更新成功率统计（简化版，实际应该基于历史数据）
      final currentStatus = _statusCache[config.name];
      final successRate = currentStatus != null
          ? (currentStatus.successRate * 0.8 + (success ? 1.0 : 0.0) * 0.2)
          : (success ? 1.0 : 0.0);

      // 确定健康状态
      DataSourceHealth health;
      if (!success || successRate < config.healthThreshold) {
        health = DataSourceHealth.unhealthy;
      } else if (responseTime > 1000 || successRate < 0.9) {
        health = DataSourceHealth.degraded;
      } else {
        health = DataSourceHealth.healthy;
      }

      return DataSourceStatus(
        name: config.name,
        health: health,
        responseTime: responseTime,
        successRate: successRate,
        lastCheck: DateTime.now(),
        errorMessage: success ? null : 'HTTP ${response.statusCode}',
      );

    } catch (e) {
      stopwatch.stop();

      return DataSourceStatus(
        name: config.name,
        health: DataSourceHealth.unhealthy,
        responseTime: stopwatch.elapsedMilliseconds.toDouble(),
        successRate: 0.0,
        lastCheck: DateTime.now(),
        errorMessage: e.toString(),
      );
    }
  }

  /// 自动切换到最佳数据源
  Future<void> _autoSwitchToBestDataSource() async {
    final healthySources = _statusCache.entries
        .where((entry) => entry.value.health == DataSourceHealth.healthy)
        .toList();

    if (healthySources.isEmpty) {
      AppLogger.warning('没有健康的数据源可用');
      return;
    }

    // 按优先级排序
    healthySources.sort((a, b) {
      final configA = _dataSources.firstWhere((ds) => ds.name == a.key);
      final configB = _dataSources.firstWhere((ds) => ds.name == b.key);
      return configA.priority.compareTo(configB.priority);
    });

    final bestSource = healthySources.first.key;

    if (_activeDataSource != bestSource) {
      _activeDataSource = bestSource;
      AppLogger.info('自动切换到最佳数据源: $bestSource');
    }
  }

  /// 获取当前活跃数据源的基URL
  String getActiveBaseUrl() {
    final config = _dataSources.firstWhere(
      (ds) => ds.name == _activeDataSource,
      orElse: () => _dataSources.first,
    );
    return config.baseUrl;
  }

  /// 销毁管理器
  void dispose() {
    _healthCheckTimer?.cancel();
    _statusCache.clear();
    _lastHealthCheck.clear();
  }
}
```

### 2. 智能数据源切换算法

```dart
// lib/src/core/network/intelligent_switch_engine.dart

import 'dart:math';
import 'multi_data_source_manager.dart';
import '../utils/logger.dart';

/// 切换决策因素权重配置
class SwitchWeights {
  final double responseTimeWeight;    // 响应时间权重
  final double successRateWeight;     // 成功率权重
  final double priorityWeight;        // 优先级权重
  final double healthScoreWeight;     // 健康评分权重

  const SwitchWeights({
    this.responseTimeWeight = 0.25,
    this.successRateWeight = 0.35,
    this.priorityWeight = 0.25,
    this.healthScoreWeight = 0.15,
  });
}

/// 智能切换引擎
class IntelligentSwitchEngine {
  final MultiDataSourceManager _dataSourceManager;
  final SwitchWeights _weights;

  // 切换阈值配置
  static const double RESPONSE_TIME_THRESHOLD = 1000; // 1秒
  static const double SUCCESS_RATE_THRESHOLD = 0.90;   // 90%
  static const double HEALTH_SCORE_THRESHOLD = 0.80;   // 80%

  // 冷却期配置（避免频繁切换）
  static const Duration SWITCH_COOLDOWN = Duration(minutes: 5);
  DateTime? _lastSwitchTime;

  IntelligentSwitchEngine(
    this._dataSourceManager, {
    SwitchWeights? weights,
  }) : _weights = weights ?? const SwitchWeights();

  /// 评估是否需要切换数据源
  Future<SwitchRecommendation> evaluateSwitch() async {
    final currentSource = _dataSourceManager.activeDataSource;
    final allStatuses = _dataSourceManager.getAllDataSourceStatuses();

    if (allStatuses.isEmpty) {
      return SwitchRecommendation.noSwitch();
    }

    // 检查冷却期
    if (_isInCooldown()) {
      return SwitchRecommendation.noSwitch(reason: '处于切换冷却期');
    }

    // 评估当前数据源
    final currentStatus = allStatuses[currentSource];
    if (currentStatus == null) {
      return SwitchRecommendation.switchTo(_findBestAlternative(allStatuses));
    }

    // 检查当前数据源是否满足要求
    final currentScore = _calculateOverallScore(currentStatus);
    if (currentScore >= 0.8) {
      return SwitchRecommendation.noSwitch(reason: '当前数据源表现良好');
    }

    // 寻找更好的替代方案
    final bestAlternative = _findBestAlternative(allStatuses);
    if (bestAlternative.isEmpty) {
      return SwitchRecommendation.noSwitch(reason: '没有合适的替代数据源');
    }

    final alternativeStatus = allStatuses[bestAlternative];
    if (alternativeStatus == null) {
      return SwitchRecommendation.noSwitch(reason: '替代数据源状态未知');
    }

    final alternativeScore = _calculateOverallScore(alternativeStatus);

    // 只有当替代方案显著优于当前方案时才建议切换
    if (alternativeScore > currentScore + 0.2) {
      return SwitchRecommendation.switchTo(bestAlternative);
    }

    return SwitchRecommendation.noSwitch(reason: '替代方案优势不足');
  }

  /// 计算综合评分
  double _calculateOverallScore(DataSourceStatus status) {
    // 响应时间评分 (0-1，越快分数越高)
    final responseTimeScore = max(0.0, 1.0 - (status.responseTime / RESPONSE_TIME_THRESHOLD));

    // 成功率评分
    final successRateScore = status.successRate;

    // 健康评分
    double healthScore;
    switch (status.health) {
      case DataSourceHealth.healthy:
        healthScore = 1.0;
        break;
      case DataSourceHealth.degraded:
        healthScore = 0.6;
        break;
      case DataSourceHealth.unhealthy:
        healthScore = 0.0;
        break;
      case DataSourceHealth.unknown:
        healthScore = 0.3;
        break;
    }

    // 计算加权综合评分
    final overallScore =
        responseTimeScore * _weights.responseTimeWeight +
        successRateScore * _weights.successRateWeight +
        healthScore * _weights.healthScoreWeight;

    return overallScore;
  }

  /// 寻找最佳替代数据源
  String _findBestAlternative(Map<String, DataSourceStatus> statuses) {
    String? bestSource;
    double bestScore = -1.0;

    for (final entry in statuses.entries) {
      final source = entry.key;
      final status = entry.value;

      // 跳过不健康的数据源
      if (status.health == DataSourceHealth.unhealthy) {
        continue;
      }

      final score = _calculateOverallScore(status);
      if (score > bestScore) {
        bestScore = score;
        bestSource = source;
      }
    }

    return bestSource ?? '';
  }

  /// 检查是否在冷却期内
  bool _isInCooldown() {
    if (_lastSwitchTime == null) {
      return false;
    }

    final now = DateTime.now();
    final timeSinceLastSwitch = now.difference(_lastSwitchTime!);

    return timeSinceLastSwitch < SWITCH_COOLDOWN;
  }

  /// 记录切换时间
  void recordSwitch() {
    _lastSwitchTime = DateTime.now();
  }
}

/// 切换建议
class SwitchRecommendation {
  final bool shouldSwitch;
  final String? targetDataSource;
  final String? reason;

  SwitchRecommendation._({
    required this.shouldSwitch,
    this.targetDataSource,
    this.reason,
  });

  factory SwitchRecommendation.switchTo(String target) {
    return SwitchRecommendation._(
      shouldSwitch: true,
      targetDataSource: target,
      reason: '发现更优数据源',
    );
  }

  factory SwitchRecommendation.noSwitch({String? reason}) {
    return SwitchRecommendation._(
      shouldSwitch: false,
      reason: reason ?? '无需切换',
    );
  }
}
```

### 3. 数据一致性保障机制

```dart
// lib/src/core/network/data_consistency_manager.dart

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'multi_data_source_manager.dart';
import '../utils/logger.dart';

/// 数据一致性检查点
class ConsistencyCheckpoint {
  final String dataType;        // 数据类型（fund_list, rankings等）
  final String checksum;        // 数据校验和
  final int recordCount;        // 记录数量
  final DateTime timestamp;     // 时间戳
  final String dataSource;      // 数据源
  final Map<String, dynamic> metadata; // 元数据

  ConsistencyCheckpoint({
    required this.dataType,
    required this.checksum,
    required this.recordCount,
    required this.timestamp,
    required this.dataSource,
    required this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'dataType': dataType,
    'checksum': checksum,
    'recordCount': recordCount,
    'timestamp': timestamp.toIso8601String(),
    'dataSource': dataSource,
    'metadata': metadata,
  };

  factory ConsistencyCheckpoint.fromJson(Map<String, dynamic> json) {
    return ConsistencyCheckpoint(
      dataType: json['dataType'],
      checksum: json['checksum'],
      recordCount: json['recordCount'],
      timestamp: DateTime.parse(json['timestamp']),
      dataSource: json['dataSource'],
      metadata: Map<String, dynamic>.from(json['metadata']),
    );
  }
}

/// 一致性检查结果
class ConsistencyResult {
  final bool isConsistent;
  final double similarity;      // 相似度百分比
  final List<String> issues;    // 发现的问题
  final Map<String, dynamic> details; // 详细信息

  ConsistencyResult({
    required this.isConsistent,
    required this.similarity,
    required this.issues,
    required this.details,
  });
}

/// 数据一致性管理器
class DataConsistencyManager {
  final MultiDataSourceManager _dataSourceManager;

  // 一致性检查历史
  final Map<String, List<ConsistencyCheckpoint>> _checkpoints = {};

  // 一致性阈值
  static const double CONSISTENCY_THRESHOLD = 0.85; // 85%相似度认为一致
  static const double SIMILARITY_THRESHOLD = 0.90;  // 90%相似度阈值

  DataConsistencyManager(this._dataSourceManager);

  /// 执行数据一致性检查
  Future<ConsistencyResult> checkDataConsistency(
    String dataType,
    List<dynamic> primaryData,
    List<dynamic> secondaryData,
  ) async {
    try {
      AppLogger.info('开始检查数据一致性: $dataType');

      // 生成校验点
      final primaryCheckpoint = await _generateCheckpoint(
        dataType,
        primaryData,
        'primary'
      );
      final secondaryCheckpoint = await _generateCheckpoint(
        dataType,
        secondaryData,
        'secondary'
      );

      // 保存校验点
      _saveCheckpoint(primaryCheckpoint);
      _saveCheckpoint(secondaryCheckpoint);

      // 执行一致性检查
      final result = await _compareCheckpoints(primaryCheckpoint, secondaryCheckpoint);

      AppLogger.info('数据一致性检查结果: ${result.isConsistent}, 相似度: ${result.similarity}%');
      return result;

    } catch (e) {
      AppLogger.error('数据一致性检查失败: $e');
      return ConsistencyResult(
        isConsistent: false,
        similarity: 0.0,
        issues: ['一致性检查过程出错: $e'],
        details: {'error': e.toString()},
      );
    }
  }

  /// 生成数据校验点
  Future<ConsistencyCheckpoint> _generateCheckpoint(
    String dataType,
    List<dynamic> data,
    String dataSource,
  ) async {
    // 计算数据校验和
    final dataJson = jsonEncode(data);
    final checksum = sha256.convert(utf8.encode(dataJson)).toString();

    // 提取元数据
    final metadata = await _extractMetadata(dataType, data);

    return ConsistencyCheckpoint(
      dataType: dataType,
      checksum: checksum,
      recordCount: data.length,
      timestamp: DateTime.now(),
      dataSource: dataSource,
      metadata: metadata,
    );
  }

  /// 提取元数据
  Future<Map<String, dynamic>> _extractMetadata(
    String dataType,
    List<dynamic> data,
  ) async {
    final metadata = <String, dynamic>{};

    switch (dataType) {
      case 'fund_list':
        metadata['fund_count'] = data.length;
        metadata['fund_types'] = _extractFundTypes(data);
        metadata['companies'] = _extractFundCompanies(data);
        break;

      case 'fund_rankings':
        metadata['ranking_count'] = data.length;
        metadata['time_periods'] = _extractTimePeriods(data);
        metadata['fund_categories'] = _extractFundCategories(data);
        break;

      case 'fund_daily':
        metadata['quote_count'] = data.length;
        metadata['date_range'] = _extractDateRange(data);
        metadata['avg_nav'] = _calculateAverageNav(data);
        break;

      default:
        metadata['record_count'] = data.length;
        metadata['data_hash'] = _calculateDataHash(data);
    }

    return metadata;
  }

  /// 比较校验点
  Future<ConsistencyResult> _compareCheckpoints(
    ConsistencyCheckpoint primary,
    ConsistencyCheckpoint secondary,
  ) async {
    final issues = <String>[];
    final details = <String, dynamic>{};

    // 1. 记录数量检查
    final recordCountDiff = (primary.recordCount - secondary.recordCount).abs();
    final recordCountSimilarity = 1.0 - (recordCountDiff / max(primary.recordCount, secondary.recordCount));

    if (recordCountSimilarity < SIMILARITY_THRESHOLD) {
      issues.add('记录数量差异过大: ${primary.recordCount} vs ${secondary.recordCount}');
    }
    details['record_count_similarity'] = recordCountSimilarity;

    // 2. 校验和检查
    final checksumMatch = primary.checksum == secondary.checksum;
    if (!checksumMatch) {
      issues.add('数据校验和不匹配');
    }
    details['checksum_match'] = checksumMatch;

    // 3. 元数据检查
    final metadataSimilarity = _calculateMetadataSimilarity(primary.metadata, secondary.metadata);
    if (metadataSimilarity < SIMILARITY_THRESHOLD) {
      issues.add('元数据相似度过低: $metadataSimilarity');
    }
    details['metadata_similarity'] = metadataSimilarity;

    // 4. 时间戳检查
    final timeDiff = primary.timestamp.difference(secondary.timestamp).abs();
    if (timeDiff > const Duration(minutes: 30)) {
      issues.add('数据时间戳差异过大: $timeDiff');
    }
    details['timestamp_difference_minutes'] = timeDiff.inMinutes;

    // 计算总体相似度
    final overallSimilarity = (recordCountSimilarity + metadataSimilarity) / 2;

    // 判断是否一致
    final isConsistent = issues.isEmpty && overallSimilarity >= CONSISTENCY_THRESHOLD;

    return ConsistencyResult(
      isConsistent: isConsistent,
      similarity: overallSimilarity,
      issues: issues,
      details: details,
    );
  }

  /// 计算元数据相似度
  double _calculateMetadataSimilarity(
    Map<String, dynamic> meta1,
    Map<String, dynamic> meta2,
  ) {
    if (meta1.isEmpty || meta2.isEmpty) {
      return meta1.isEmpty && meta2.isEmpty ? 1.0 : 0.0;
    }

    int matches = 0;
    int totalChecks = 0;

    for (final key in meta1.keys) {
      if (meta2.containsKey(key)) {
        totalChecks++;
        if (meta1[key] == meta2[key]) {
          matches++;
        }
      }
    }

    return totalChecks > 0 ? matches / totalChecks : 0.0;
  }

  /// 获取一致性历史记录
  List<ConsistencyCheckpoint> getConsistencyHistory(String dataType) {
    return List.from(_checkpoints[dataType] ?? []);
  }

  /// 清理过期的一致性检查记录
  void cleanupOldCheckpoints(Duration maxAge) {
    final cutoffTime = DateTime.now().subtract(maxAge);

    for (final dataType in _checkpoints.keys) {
      final checkpoints = _checkpoints[dataType]!;
      checkpoints.removeWhere((checkpoint) => checkpoint.timestamp.isBefore(cutoffTime));
    }
  }

  // 辅助方法
  List<String> _extractFundTypes(List<dynamic> data) {
    final types = <String>{};
    for (final item in data) {
      if (item['fund_type'] != null) {
        types.add(item['fund_type'].toString());
      }
    }
    return types.toList();
  }

  List<String> _extractFundCompanies(List<dynamic> data) {
    final companies = <String>{};
    for (final item in data) {
      if (item['company'] != null) {
        companies.add(item['company'].toString());
      }
    }
    return companies.toList();
  }

  List<String> _extractTimePeriods(List<dynamic> data) {
    final periods = <String>{};
    for (final item in data) {
      if (item['time_period'] != null) {
        periods.add(item['time_period'].toString());
      }
    }
    return periods.toList();
  }

  List<String> _extractFundCategories(List<dynamic> data) {
    final categories = <String>{};
    for (final item in data) {
      if (item['category'] != null) {
        categories.add(item['category'].toString());
      }
    }
    return categories.toList();
  }

  Map<String, DateTime> _extractDateRange(List<dynamic> data) {
    DateTime? minDate;
    DateTime? maxDate;

    for (final item in data) {
      if (item['date'] != null) {
        try {
          final date = DateTime.parse(item['date'].toString());
          minDate = minDate == null || date.isBefore(minDate) ? date : minDate;
          maxDate = maxDate == null || date.isAfter(maxDate) ? date : maxDate;
        } catch (e) {
          // 忽略解析错误的日期
        }
      }
    }

    return {
      'start': minDate ?? DateTime.now(),
      'end': maxDate ?? DateTime.now(),
    };
  }

  double _calculateAverageNav(List<dynamic> data) {
    double totalNav = 0.0;
    int count = 0;

    for (final item in data) {
      if (item['nav'] != null) {
        try {
          totalNav += double.parse(item['nav'].toString());
          count++;
        } catch (e) {
          // 忽略解析错误的数据
        }
      }
    }

    return count > 0 ? totalNav / count : 0.0;
  }

  String _calculateDataHash(List<dynamic> data) {
    final dataJson = jsonEncode(data);
    return sha256.convert(utf8.encode(dataJson)).toString().substring(0, 16);
  }

  void _saveCheckpoint(ConsistencyCheckpoint checkpoint) {
    final dataType = checkpoint.dataType;
    _checkpoints.putIfAbsent(dataType, () => []);
    _checkpoints[dataType]!.add(checkpoint);

    // 限制历史记录数量
    if (_checkpoints[dataType]!.length > 100) {
      _checkpoints[dataType]!.removeAt(0);
    }
  }
}
```

## 降级触发条件定义

### 1. 自动降级触发条件

| 触发条件 | 阈值 | 响应时间 | 降级策略 |
|----------|------|----------|----------|
| API响应超时 | >30秒 | 立即 | 切换到备选数据源 |
| 请求成功率下降 | <90% | 1分钟内 | 切换到备选数据源 |
| 响应时间变慢 | >1000ms | 3分钟内 | 切换到性能更好的数据源 |
| 数据源不可用 | 健康检查失败 | 立即 | 切换到健康的数据源 |
| 数据一致性异常 | <85%相似度 | 5分钟内 | 触发数据验证和修复 |

### 2. 手动降级触发条件

- **运维人员手动切换**：通过管理界面或API手动切换数据源
- **计划维护降级**：在数据源维护期间主动切换
- **紧急故障降级**：收到故障报告后立即切换

## 商业API备选源识别和集成

### 1. 备选数据源评估

| API提供商 | 覆盖范围 | 数据质量 | 成本评估 | 技术支持 | 综合评分 |
|-----------|----------|----------|----------|----------|----------|
| 阿里云市场 | 全面 | 高 | 中等 | 良好 | 8.5/10 |
| 腾讯云市场 | 全面 | 高 | 中等 | 良好 | 8.3/10 |
| 聚合数据 | 基础 | 中等 | 低 | 一般 | 7.2/10 |
| AKShare直连 | 专业 | 很高 | 免费 | 社区 | 9.0/10 |

### 2. 集成方案

```yaml
# 商业API配置示例
commercial_apis:
  aliyun:
    endpoint: "https://market.aliyun.com/api/fund"
    api_key: "${ALIYUN_API_KEY}"
    rate_limit: 1000  # 每小时请求限制
    timeout: 45s
    retry_count: 2

  tencent:
    endpoint: "https://market.tencent.com/api/fund"
    api_key: "${TENCENT_API_KEY}"
    rate_limit: 800   # 每小时请求限制
    timeout: 45s
    retry_count: 2

  akshare:
    endpoint: "https://aktools.akfamily.xyz/api"
    rate_limit: 500   # 每小时请求限制
    timeout: 60s
    retry_count: 2
```

## 实施计划

### 第一阶段：基础架构搭建（2周）

1. **Week 1**：多数据源管理器开发
   - 实现数据源健康检查机制
   - 开发数据源状态监控
   - 编写单元测试

2. **Week 2**：智能切换引擎开发
   - 实现切换算法和评分机制
   - 开发切换决策引擎
   - 集成测试和性能优化

### 第二阶段：数据一致性保障（1周）

1. **Week 3**：一致性管理器开发
   - 实现数据校验和比对机制
   - 开发一致性历史记录
   - 异常处理和修复机制

### 第三阶段：集成测试和优化（1周）

1. **Week 4**：系统集成和测试
   - 与现有API客户端集成
   - 端到端测试
   - 性能调优和文档编写

## 资源需求

### 技术资源
- **开发人员**：2名高级Flutter开发工程师
- **测试人员**：1名测试工程师
- **运维人员**：1名DevOps工程师

### 基础设施
- **测试环境**：独立的测试API服务器
- **监控工具**：Prometheus + Grafana
- **日志系统**：ELK Stack

### 预算估算
- **开发成本**：¥80,000（4周开发时间）
- **测试成本**：¥20,000（1周测试时间）
- **基础设施**：¥10,000/月（监控和测试环境）
- **API费用**：¥5,000/月（商业API调用费用）

**总投入**：¥115,000（首月）+ ¥15,000/月（运营成本）

## 风险评估与缓解措施

### 技术风险

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| 多数据源同步复杂 | 中 | 高 | 建立数据一致性检查机制，逐步切换 |
| 切换算法不准确 | 低 | 中 | 充分测试和调优，设置手动覆盖机制 |
| 性能开销增加 | 中 | 中 | 优化检查频率，使用异步处理 |

### 业务风险

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| API成本超出预算 | 低 | 中 | 设置API调用限制，监控成本支出 |
| 数据质量不一致 | 中 | 高 | 建立数据质量监控，用户透明化提示 |
| 切换过程用户体验差 | 低 | 中 | 优化切换逻辑，提供加载状态提示 |

### 运维风险

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| 监控系统故障 | 低 | 高 | 建立多层监控，设置告警冗余 |
| 配置管理复杂 | 中 | 低 | 使用配置中心，版本化管理 |
| 故障响应不及时 | 中 | 中 | 建立自动化响应，24小时值班 |

## 成功指标（KPI）

### 技术指标

| 指标 | 目标值 | 当前值 | 监控频率 |
|------|--------|--------|----------|
| API整体可用性 | ≥99.9% | ~95% | 实时监控 |
| 平均响应时间 | ≤500ms | ~2000ms | 实时监控 |
| 数据源切换时间 | ≤30秒 | N/A | 事件触发 |
| 数据一致性率 | ≥95% | N/A | 每小时 |
| 故障恢复时间 | ≤5分钟 | ~30分钟 | 事件触发 |

### 业务指标

| 指标 | 目标值 | 当前值 | 监控频率 |
|------|--------|--------|----------|
| 用户请求成功率 | ≥99.5% | ~90% | 实时监控 |
| 页面加载成功率 | ≥99.8% | ~85% | 实时监控 |
| 用户投诉数量 | ≤5/月 | ~20/月 | 每日统计 |
| 功能可用时间 | ≥99.9% | ~95% | 每日统计 |

## 后续优化计划

### 短期优化（1-3个月）
1. **机器学习优化**：基于历史数据训练切换算法
2. **缓存策略优化**：实现多级缓存和智能预加载
3. **用户体验优化**：提供更友好的降级提示

### 长期优化（3-6个月）
1. **边缘计算部署**：在CDN节点部署API服务
2. **数据湖建设**：建立统一的数据湖和数据仓库
3. **AI预测维护**：预测性维护和故障预防

## 总结

本解决方案通过建立多数据源架构、智能切换算法和数据一致性保障机制，能够有效解决当前API服务稳定性风险。预期能够将API服务可用性从95%提升至99.9%，大幅降低因API故障导致的业务中断风险。虽然需要一定的技术和资金投入，但相比业务中断的损失，这是一项值得的投资。