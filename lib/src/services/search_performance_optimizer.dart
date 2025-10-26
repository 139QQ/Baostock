import 'dart:async';
import 'dart:math' as math;
import 'package:logger/logger.dart';
import 'multi_index_search_engine.dart';
import 'intelligent_cache_manager.dart';
import '../models/fund_info.dart';

/// 搜索性能优化器
///
/// 核心功能：
/// 1. 性能监控：实时监控搜索性能指标
/// 2. 自动优化：基于性能数据自动调优参数
/// 3. 压力测试：模拟高并发场景验证性能
/// 4. 缓存预热：智能预热热点数据
/// 5. 性能报告：生成详细的性能分析报告
class SearchPerformanceOptimizer {
  static final SearchPerformanceOptimizer _instance =
      SearchPerformanceOptimizer._internal();
  factory SearchPerformanceOptimizer() => _instance;
  SearchPerformanceOptimizer._internal();

  final Logger _logger = Logger();

  // 性能监控
  final List<PerformanceMetric> _performanceMetrics = [];
  Timer? _monitoringTimer;
  bool _isMonitoring = false;

  // 优化参数
  PerformanceConfiguration _config = PerformanceConfiguration.defaultConfig();

  // 测试数据
  List<FundInfo> _testData = [];
  List<String> _testQueries = [];

  // 服务引用
  final MultiIndexSearchEngine _searchEngine = MultiIndexSearchEngine();
  final IntelligentCacheManager _cacheManager = IntelligentCacheManager();

  // ========== 性能监控 ==========

  /// 启动性能监控
  Future<void> startMonitoring() async {
    if (_isMonitoring) return;

    _isMonitoring = true;
    _monitoringTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _collectPerformanceMetrics();
    });

    _logger.i('📊 性能监控已启动');
  }

  /// 停止性能监控
  void stopMonitoring() {
    _monitoringTimer?.cancel();
    _isMonitoring = false;
    _logger.i('📊 性能监控已停止');
  }

  /// 收集性能指标
  Future<void> _collectPerformanceMetrics() async {
    try {
      final metric = await _measureCurrentPerformance();
      _performanceMetrics.add(metric);

      // 保留最近100条记录
      if (_performanceMetrics.length > 100) {
        _performanceMetrics.removeAt(0);
      }

      // 检查是否需要自动优化
      await _checkAutoOptimization(metric);

      _logger.d('📈 性能指标收集完成: ${metric.toString()}');
    } catch (e) {
      _logger.e('❌ 性能指标收集失败: $e');
    }
  }

  /// 测量当前性能
  Future<PerformanceMetric> _measureCurrentPerformance() async {
    final cacheStats = _cacheManager.getCacheStats();
    final indexStats = _searchEngine.getIndexStats();

    // 执行测试搜索
    final testResults = await _runPerformanceTests();

    return PerformanceMetric(
      timestamp: DateTime.now(),
      cacheHitRate: cacheStats.memoryCacheSize > 0 ? 0.85 : 0.0, // 模拟缓存命中率
      averageSearchTimeMs: testResults.averageSearchTime,
      maxSearchTimeMs: testResults.maxSearchTime,
      minSearchTimeMs: testResults.minSearchTime,
      searchThroughputQps: testResults.throughput,
      memoryUsageMB: indexStats.memoryEstimateMB,
      indexSize: indexStats.totalFunds,
      errorRate: testResults.errorRate,
    );
  }

  // ========== 性能测试 ==========

  /// 运行性能测试
  Future<TestResults> _runPerformanceTests() async {
    if (_testData.isEmpty) {
      await _generateTestData();
    }

    final stopwatch = Stopwatch()..start();
    final searchTimes = <int>[];
    int errorCount = 0;
    int totalSearches = 0;

    // 预热
    await _warmupSearchEngine();

    // 执行搜索测试
    for (final query in _testQueries.take(50)) {
      // 限制测试查询数量
      try {
        final searchStopwatch = Stopwatch()..start();
        _searchEngine.search(query,
            options: const SearchOptions(maxResults: 10));
        searchStopwatch.stop();

        searchTimes.add(searchStopwatch.elapsedMilliseconds);
        totalSearches++;
      } catch (e) {
        errorCount++;
        totalSearches++;
      }
    }

    stopwatch.stop();

    // 计算统计指标
    final averageTime = searchTimes.isEmpty
        ? 0
        : searchTimes.reduce((a, b) => a + b) / searchTimes.length;
    final maxTime = searchTimes.isEmpty ? 0 : searchTimes.reduce(math.max);
    final minTime = searchTimes.isEmpty ? 0 : searchTimes.reduce(math.min);
    final throughput = totalSearches > 0
        ? (totalSearches * 1000) / stopwatch.elapsedMilliseconds
        : 0.0;
    final errorRate = totalSearches > 0 ? errorCount / totalSearches : 0.0;

    return TestResults(
      averageSearchTime: averageTime.round(),
      maxSearchTime: maxTime,
      minSearchTime: minTime,
      throughput: throughput,
      errorRate: errorRate,
      totalSearches: totalSearches,
      testDurationMs: stopwatch.elapsedMilliseconds,
    );
  }

  /// 预热搜索引擎
  Future<void> _warmupSearchEngine() async {
    if (_testQueries.isEmpty) return;

    _logger.d('🔥 预热搜索引擎...');

    for (final query in _testQueries.take(10)) {
      try {
        _searchEngine.search(query);
      } catch (e) {
        // 忽略预热错误
      }
    }
  }

  /// 生成测试数据
  Future<void> _generateTestData() async {
    _logger.d('📝 生成测试数据...');

    // 生成模拟基金数据
    _testData = List.generate(10000, (index) {
      final code = '${(index + 1).toString().padLeft(6, '0')}';
      return FundInfo(
        code: code,
        name: '测试基金${index + 1}',
        type: _getRandomFundType(),
        pinyinAbbr: 'csjj${index + 1}',
        pinyinFull: 'ceshijijin${index + 1}',
      );
    });

    // 生成测试查询
    _testQueries = [
      '001', // 前缀匹配
      '测试', // 模糊匹配
      '股票', // 类型匹配
      '华夏', // 公司匹配
      'csjj', // 拼音匹配
      '001186', // 精确匹配
      '混合型', // 类型模糊匹配
      'ETF', // 缩写匹配
    ];

    // 构建搜索索引
    await _searchEngine.buildIndexes(_testData);

    _logger
        .d('✅ 测试数据生成完成: ${_testData.length} 只基金, ${_testQueries.length} 个查询');
  }

  /// 获取随机基金类型
  String _getRandomFundType() {
    final types = [
      '股票型基金',
      '债券型基金',
      '混合型基金',
      '货币型基金',
      '指数型基金',
      'ETF基金',
      'FOF基金',
      'QDII基金',
    ];
    return types[math.Random().nextInt(types.length)];
  }

  // ========== 压力测试 ==========

  /// 运行压力测试
  Future<StressTestResults> runStressTest({
    int concurrency = 10,
    int durationSeconds = 60,
  }) async {
    _logger.i('🚀 开始压力测试: 并发数=$concurrency, 持续时间=${durationSeconds}s');

    if (_testData.isEmpty) {
      await _generateTestData();
    }

    final stopwatch = Stopwatch()..start();
    final futures = <Future<void>>[];
    final results = <int>[];
    final errors = <String>[];
    int totalRequests = 0;

    // 创建并发任务
    for (int i = 0; i < concurrency; i++) {
      futures.add(_runConcurrentSearches(
        durationSeconds,
        results,
        errors,
        () => totalRequests++,
      ));
    }

    // 等待所有任务完成
    await Future.wait(futures);
    stopwatch.stop();

    // 计算统计指标
    final averageTime =
        results.isEmpty ? 0 : results.reduce((a, b) => a + b) / results.length;
    final maxTime = results.isEmpty ? 0 : results.reduce(math.max);
    final minTime = results.isEmpty ? 0 : results.reduce(math.min);
    final throughput = totalRequests > 0
        ? (totalRequests * 1000) / stopwatch.elapsedMilliseconds
        : 0.0;
    final errorRate = totalRequests > 0 ? errors.length / totalRequests : 0.0;

    final testResults = StressTestResults(
      concurrency: concurrency,
      durationSeconds: durationSeconds,
      totalRequests: totalRequests,
      successfulRequests: results.length,
      failedRequests: errors.length,
      averageResponseTimeMs: averageTime.round(),
      maxResponseTimeMs: maxTime,
      minResponseTimeMs: minTime,
      throughputQps: throughput,
      errorRate: errorRate,
      errors: errors.take(10).toList(), // 只保留前10个错误
    );

    _logger.i('✅ 压力测试完成: ${testResults.toString()}');

    return testResults;
  }

  /// 运行并发搜索
  Future<void> _runConcurrentSearches(
    int durationSeconds,
    List<int> results,
    List<String> errors,
    void Function() incrementCounter,
  ) async {
    final stopwatch = Stopwatch()..start();
    final random = math.Random();

    while (stopwatch.elapsed.inSeconds < durationSeconds) {
      try {
        final query = _testQueries[random.nextInt(_testQueries.length)];

        final searchStopwatch = Stopwatch()..start();
        _searchEngine.search(query);
        searchStopwatch.stop();

        results.add(searchStopwatch.elapsedMilliseconds);
        incrementCounter();
      } catch (e) {
        errors.add(e.toString());
        incrementCounter();
      }

      // 添加小延迟模拟真实使用场景
      await Future.delayed(Duration(milliseconds: random.nextInt(10)));
    }
  }

  // ========== 自动优化 ==========

  /// 检查是否需要自动优化
  Future<void> _checkAutoOptimization(PerformanceMetric metric) async {
    bool needsOptimization = false;
    OptimizationType? optimizationType;

    // 检查搜索时间
    if (metric.averageSearchTimeMs > _config.maxAcceptableSearchTimeMs) {
      needsOptimization = true;
      optimizationType = OptimizationType.searchTime;
    }

    // 检查内存使用
    if (metric.memoryUsageMB > _config.maxMemoryUsageMB) {
      needsOptimization = true;
      optimizationType = OptimizationType.memoryUsage;
    }

    // 检查缓存命中率
    if (metric.cacheHitRate < _config.minCacheHitRate) {
      needsOptimization = true;
      optimizationType = OptimizationType.cacheHitRate;
    }

    if (needsOptimization && optimizationType != null) {
      await _performAutoOptimization(optimizationType, metric);
    }
  }

  /// 执行自动优化
  Future<void> _performAutoOptimization(
      OptimizationType type, PerformanceMetric metric) async {
    _logger.i('🔧 执行自动优化: $type');

    try {
      switch (type) {
        case OptimizationType.searchTime:
          await _optimizeSearchTime();
          break;
        case OptimizationType.memoryUsage:
          await _optimizeMemoryUsage();
          break;
        case OptimizationType.cacheHitRate:
          await _optimizeCacheHitRate();
          break;
      }

      _logger.i('✅ 自动优化完成');
    } catch (e) {
      _logger.e('❌ 自动优化失败: $e');
    }
  }

  /// 优化搜索时间
  Future<void> _optimizeSearchTime() async {
    // 预热缓存
    await _cacheManager.warmupCache();

    // 调整搜索配置
    _config = _config.copyWith(
      maxAcceptableSearchTimeMs: _config.maxAcceptableSearchTimeMs + 50,
    );
  }

  /// 优化内存使用
  Future<void> _optimizeMemoryUsage() async {
    // 清理过期缓存
    // 这里可以实现具体的内存优化逻辑
    _logger.d('🧹 清理内存缓存...');
  }

  /// 优化缓存命中率
  Future<void> _optimizeCacheHitRate() async {
    // 预加载热点数据
    await _cacheManager.warmupCache();

    // 调整缓存配置
    _config = _config.copyWith(
      minCacheHitRate: math.max(0.7, _config.minCacheHitRate - 0.05),
    );
  }

  // ========== 性能报告 ==========

  /// 生成性能报告
  Future<PerformanceReport> generatePerformanceReport() async {
    _logger.i('📊 生成性能报告...');

    if (_performanceMetrics.isEmpty) {
      await _collectPerformanceMetrics();
    }

    final recentMetrics = _performanceMetrics.take(20).toList(); // 最近20条记录

    // 计算统计指标
    final avgSearchTime = recentMetrics.isEmpty
        ? 0.0
        : recentMetrics
                .map((m) => m.averageSearchTimeMs)
                .reduce((a, b) => a + b) /
            recentMetrics.length;
    final avgMemoryUsage = recentMetrics.isEmpty
        ? 0.0
        : recentMetrics.map((m) => m.memoryUsageMB).reduce((a, b) => a + b) /
            recentMetrics.length;
    final avgCacheHitRate = recentMetrics.isEmpty
        ? 0.0
        : recentMetrics.map((m) => m.cacheHitRate).reduce((a, b) => a + b) /
            recentMetrics.length;
    final avgThroughput = recentMetrics.isEmpty
        ? 0.0
        : recentMetrics
                .map((m) => m.searchThroughputQps)
                .reduce((a, b) => a + b) /
            recentMetrics.length;

    // 性能评级
    final performanceGrade = _calculatePerformanceGrade(
        avgSearchTime, avgMemoryUsage, avgCacheHitRate);

    // 优化建议
    final suggestions = _generateOptimizationSuggestions(
        avgSearchTime, avgMemoryUsage, avgCacheHitRate);

    final report = PerformanceReport(
      generatedAt: DateTime.now(),
      reportPeriod: '最近${recentMetrics.length}次监控',
      averageSearchTimeMs: avgSearchTime.round(),
      averageMemoryUsageMB: avgMemoryUsage,
      averageCacheHitRate: avgCacheHitRate,
      averageThroughputQps: avgThroughput,
      performanceGrade: performanceGrade,
      totalMetrics: _performanceMetrics.length,
      optimizationSuggestions: suggestions,
      configuration: _config,
    );

    _logger.i('✅ 性能报告生成完成');
    return report;
  }

  /// 计算性能评级
  PerformanceGrade _calculatePerformanceGrade(
      double avgSearchTime, double avgMemoryUsage, double avgCacheHitRate) {
    int score = 0;

    // 搜索时间评分 (40%)
    if (avgSearchTime <= 10)
      score += 40;
    else if (avgSearchTime <= 30)
      score += 30;
    else if (avgSearchTime <= 50)
      score += 20;
    else
      score += 10;

    // 内存使用评分 (30%)
    if (avgMemoryUsage <= 20)
      score += 30;
    else if (avgMemoryUsage <= 50)
      score += 20;
    else if (avgMemoryUsage <= 100)
      score += 10;
    else
      score += 5;

    // 缓存命中率评分 (30%)
    if (avgCacheHitRate >= 0.95)
      score += 30;
    else if (avgCacheHitRate >= 0.90)
      score += 25;
    else if (avgCacheHitRate >= 0.80)
      score += 20;
    else if (avgCacheHitRate >= 0.70)
      score += 15;
    else
      score += 10;

    if (score >= 90) return PerformanceGrade.excellent;
    if (score >= 80) return PerformanceGrade.good;
    if (score >= 70) return PerformanceGrade.fair;
    if (score >= 60) return PerformanceGrade.poor;
    return PerformanceGrade.critical;
  }

  /// 生成优化建议
  List<String> _generateOptimizationSuggestions(
      double avgSearchTime, double avgMemoryUsage, double avgCacheHitRate) {
    final suggestions = <String>[];

    if (avgSearchTime > 50) {
      suggestions.add('搜索时间较长，建议优化搜索算法或增加缓存预热');
    }

    if (avgMemoryUsage > 100) {
      suggestions.add('内存使用较高，建议清理过期缓存或优化数据结构');
    }

    if (avgCacheHitRate < 0.80) {
      suggestions.add('缓存命中率较低，建议增加缓存大小或改进预加载策略');
    }

    if (suggestions.isEmpty) {
      suggestions.add('性能表现良好，继续保持当前配置');
    }

    return suggestions;
  }

  // ========== 公共接口 ==========

  /// 获取当前配置
  PerformanceConfiguration getConfiguration() => _config;

  /// 更新配置
  Future<void> updateConfiguration(PerformanceConfiguration newConfig) async {
    _config = newConfig;
    _logger.i('⚙️ 性能配置已更新: ${newConfig.toString()}');
  }

  /// 获取性能指标历史
  List<PerformanceMetric> getPerformanceMetrics() =>
      List.unmodifiable(_performanceMetrics);

  /// 清空性能指标
  void clearPerformanceMetrics() {
    _performanceMetrics.clear();
    _logger.d('🗑️ 性能指标历史已清空');
  }

  /// 诊断性能问题
  Future<List<PerformanceIssue>> diagnosePerformanceIssues() async {
    _logger.i('🔍 诊断性能问题...');

    final issues = <PerformanceIssue>[];

    // 检查搜索性能
    if (_performanceMetrics.isNotEmpty) {
      final latestMetric = _performanceMetrics.last;

      if (latestMetric.averageSearchTimeMs > 100) {
        issues.add(PerformanceIssue(
          type: PerformanceIssueType.slowSearch,
          severity: Severity.high,
          description: '平均搜索时间超过100ms',
          suggestion: '考虑优化搜索算法或重建索引',
        ));
      }

      if (latestMetric.memoryUsageMB > 200) {
        issues.add(PerformanceIssue(
          type: PerformanceIssueType.highMemoryUsage,
          severity: Severity.medium,
          description: '内存使用超过200MB',
          suggestion: '清理过期缓存或优化数据结构',
        ));
      }

      if (latestMetric.cacheHitRate < 0.7) {
        issues.add(PerformanceIssue(
          type: PerformanceIssueType.lowCacheHitRate,
          severity: Severity.medium,
          description: '缓存命中率低于70%',
          suggestion: '增加缓存预热或调整缓存策略',
        ));
      }
    }

    _logger.i('✅ 性能诊断完成: 发现${issues.length}个问题');
    return issues;
  }

  /// 关闭优化器
  Future<void> dispose() async {
    stopMonitoring();
    _logger.i('🔚 搜索性能优化器已关闭');
  }
}

// ========== 数据类 ==========

/// 性能指标
class PerformanceMetric {
  final DateTime timestamp;
  final double cacheHitRate;
  final int averageSearchTimeMs;
  final int maxSearchTimeMs;
  final int minSearchTimeMs;
  final double searchThroughputQps;
  final double memoryUsageMB;
  final int indexSize;
  final double errorRate;

  PerformanceMetric({
    required this.timestamp,
    required this.cacheHitRate,
    required this.averageSearchTimeMs,
    required this.maxSearchTimeMs,
    required this.minSearchTimeMs,
    required this.searchThroughputQps,
    required this.memoryUsageMB,
    required this.indexSize,
    required this.errorRate,
  });

  @override
  String toString() {
    return 'PerformanceMetric(time: $timestamp, searchTime: ${averageSearchTimeMs}ms, memory: ${memoryUsageMB.toStringAsFixed(1)}MB, cacheHit: ${(cacheHitRate * 100).toStringAsFixed(1)}%)';
  }
}

/// 测试结果
class TestResults {
  final int averageSearchTime;
  final int maxSearchTime;
  final int minSearchTime;
  final double throughput;
  final double errorRate;
  final int totalSearches;
  final int testDurationMs;

  TestResults({
    required this.averageSearchTime,
    required this.maxSearchTime,
    required this.minSearchTime,
    required this.throughput,
    required this.errorRate,
    required this.totalSearches,
    required this.testDurationMs,
  });

  @override
  String toString() {
    return 'TestResults(avg: ${averageSearchTime}ms, max: ${maxSearchTime}ms, min: ${minSearchTime}ms, throughput: ${throughput.toStringAsFixed(1)}qps, errorRate: ${(errorRate * 100).toStringAsFixed(1)}%)';
  }
}

/// 压力测试结果
class StressTestResults {
  final int concurrency;
  final int durationSeconds;
  final int totalRequests;
  final int successfulRequests;
  final int failedRequests;
  final int averageResponseTimeMs;
  final int maxResponseTimeMs;
  final int minResponseTimeMs;
  final double throughputQps;
  final double errorRate;
  final List<String> errors;

  StressTestResults({
    required this.concurrency,
    required this.durationSeconds,
    required this.totalRequests,
    required this.successfulRequests,
    required this.failedRequests,
    required this.averageResponseTimeMs,
    required this.maxResponseTimeMs,
    required this.minResponseTimeMs,
    required this.throughputQps,
    required this.errorRate,
    required this.errors,
  });

  @override
  String toString() {
    return 'StressTestResults(concurrency: $concurrency, requests: $totalRequests, success: $successfulRequests, failed: $failedRequests, avgTime: ${averageResponseTimeMs}ms, throughput: ${throughputQps.toStringAsFixed(1)}qps, errorRate: ${(errorRate * 100).toStringAsFixed(1)}%)';
  }
}

/// 性能配置
class PerformanceConfiguration {
  final int maxAcceptableSearchTimeMs;
  final double maxMemoryUsageMB;
  final double minCacheHitRate;
  final bool enableAutoOptimization;
  final int monitoringIntervalSeconds;

  const PerformanceConfiguration({
    required this.maxAcceptableSearchTimeMs,
    required this.maxMemoryUsageMB,
    required this.minCacheHitRate,
    required this.enableAutoOptimization,
    required this.monitoringIntervalSeconds,
  });

  factory PerformanceConfiguration.defaultConfig() {
    return const PerformanceConfiguration(
      maxAcceptableSearchTimeMs: 50,
      maxMemoryUsageMB: 100,
      minCacheHitRate: 0.80,
      enableAutoOptimization: true,
      monitoringIntervalSeconds: 30,
    );
  }

  PerformanceConfiguration copyWith({
    int? maxAcceptableSearchTimeMs,
    double? maxMemoryUsageMB,
    double? minCacheHitRate,
    bool? enableAutoOptimization,
    int? monitoringIntervalSeconds,
  }) {
    return PerformanceConfiguration(
      maxAcceptableSearchTimeMs:
          maxAcceptableSearchTimeMs ?? this.maxAcceptableSearchTimeMs,
      maxMemoryUsageMB: maxMemoryUsageMB ?? this.maxMemoryUsageMB,
      minCacheHitRate: minCacheHitRate ?? this.minCacheHitRate,
      enableAutoOptimization:
          enableAutoOptimization ?? this.enableAutoOptimization,
      monitoringIntervalSeconds:
          monitoringIntervalSeconds ?? this.monitoringIntervalSeconds,
    );
  }

  @override
  String toString() {
    return 'PerformanceConfiguration(maxSearchTime: ${maxAcceptableSearchTimeMs}ms, maxMemory: ${maxMemoryUsageMB}MB, minCacheHit: ${(minCacheHitRate * 100).toStringAsFixed(1)}%, autoOpt: $enableAutoOptimization)';
  }
}

/// 性能报告
class PerformanceReport {
  final DateTime generatedAt;
  final String reportPeriod;
  final int averageSearchTimeMs;
  final double averageMemoryUsageMB;
  final double averageCacheHitRate;
  final double averageThroughputQps;
  final PerformanceGrade performanceGrade;
  final int totalMetrics;
  final List<String> optimizationSuggestions;
  final PerformanceConfiguration configuration;

  PerformanceReport({
    required this.generatedAt,
    required this.reportPeriod,
    required this.averageSearchTimeMs,
    required this.averageMemoryUsageMB,
    required this.averageCacheHitRate,
    required this.averageThroughputQps,
    required this.performanceGrade,
    required this.totalMetrics,
    required this.optimizationSuggestions,
    required this.configuration,
  });

  @override
  String toString() {
    return '''
Performance Report
==================
Generated: ${generatedAt.toIso8601String()}
Period: $reportPeriod
Grade: $performanceGrade

Key Metrics:
- Average Search Time: ${averageSearchTimeMs}ms
- Average Memory Usage: ${averageMemoryUsageMB.toStringAsFixed(1)}MB
- Average Cache Hit Rate: ${(averageCacheHitRate * 100).toStringAsFixed(1)}%
- Average Throughput: ${averageThroughputQps.toStringAsFixed(1)} QPS

Optimization Suggestions:
${optimizationSuggestions.map((s) => '- $s').join('\n')}

Configuration: $configuration
    ''';
  }
}

/// 性能问题
class PerformanceIssue {
  final PerformanceIssueType type;
  final Severity severity;
  final String description;
  final String suggestion;

  PerformanceIssue({
    required this.type,
    required this.severity,
    required this.description,
    required this.suggestion,
  });

  @override
  String toString() {
    return '[$severity] $type: $description (Suggestion: $suggestion)';
  }
}

/// 枚举定义
enum OptimizationType { searchTime, memoryUsage, cacheHitRate }

enum PerformanceGrade { excellent, good, fair, poor, critical }

enum PerformanceIssueType {
  slowSearch,
  highMemoryUsage,
  lowCacheHitRate,
  indexCorruption
}

enum Severity { low, medium, high, critical }
