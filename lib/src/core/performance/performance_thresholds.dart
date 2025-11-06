/// 性能监控阈值定义
///
/// 定义应用各项性能指标的阈值标准
/// 基于用户体验期望和行业最佳实践
class PerformanceThresholds {
  // 私有构造函数，防止实例化
  PerformanceThresholds._();

  // ========== 响应时间阈值 (毫秒) ==========

  /// 基金搜索响应时间阈值
  static const int searchResponseTimeOptimal = 200; // 最优：200ms
  static const int searchResponseTimeGood = 300; // 良好：300ms
  static const int searchResponseTimeWarning = 500; // 警告：500ms
  static const int searchResponseTimeCritical = 1000; // 危险：1000ms

  /// 应用启动时间阈值
  static const int appStartupTimeOptimal = 2000; // 最优：2秒
  static const int appStartupTimeGood = 3000; // 良好：3秒
  static const int appStartupTimeWarning = 5000; // 警告：5秒
  static const int appStartupTimeCritical = 8000; // 危险：8秒

  /// 页面切换时间阈值
  static const int pageNavigationTimeOptimal = 100; // 最优：100ms
  static const int pageNavigationTimeGood = 200; // 良好：200ms
  static const int pageNavigationTimeWarning = 500; // 警告：500ms
  static const int pageNavigationTimeCritical = 1000; // 危险：1000ms

  /// 数据加载时间阈值
  static const int dataLoadingTimeOptimal = 500; // 最优：500ms
  static const int dataLoadingTimeGood = 1000; // 良好：1秒
  static const int dataLoadingTimeWarning = 2000; // 警告：2秒
  static const int dataLoadingTimeCritical = 5000; // 危险：5秒

  // ========== 缓存性能阈值 ==========

  /// 缓存命中率阈值
  static const double cacheHitRateOptimal = 0.85; // 最优：85%
  static const double cacheHitRateGood = 0.70; // 良好：70%
  static const double cacheHitRateWarning = 0.50; // 警告：50%
  static const double cacheHitRateCritical = 0.30; // 危险：30%

  /// 缓存响应时间阈值
  static const int cacheResponseTimeOptimal = 10; // 最优：10ms
  static const int cacheResponseTimeGood = 50; // 良好：50ms
  static const int cacheResponseTimeWarning = 100; // 警告：100ms
  static const int cacheResponseTimeCritical = 200; // 危险：200ms

  // ========== 内存使用阈值 (MB) ==========

  /// 应用内存使用阈值
  static const int memoryUsageOptimal = 150; // 最优：150MB
  static const int memoryUsageGood = 250; // 良好：250MB
  static const int memoryUsageWarning = 400; // 警告：400MB
  static const int memoryUsageCritical = 600; // 危险：600MB

  /// 缓存内存使用阈值
  static const int cacheMemoryUsageOptimal = 50; // 最优：50MB
  static const int cacheMemoryUsageGood = 100; // 良好：100MB
  static const int cacheMemoryUsageWarning = 200; // 警告：200MB
  static const int cacheMemoryUsageCritical = 300; // 危险：300MB

  // ========== CPU使用率阈值 (%) ==========

  /// CPU使用率阈值
  static const double cpuUsageOptimal = 30.0; // 最优：30%
  static const double cpuUsageGood = 50.0; // 良好：50%
  static const double cpuUsageWarning = 70.0; // 警告：70%
  static const double cpuUsageCritical = 90.0; // 危险：90%

  // ========== 网络性能阈值 ==========

  /// API请求成功率阈值
  static const double apiSuccessRateOptimal = 0.99; // 最优：99%
  static const double apiSuccessRateGood = 0.95; // 良好：95%
  static const double apiSuccessRateWarning = 0.90; // 警告：90%
  static const double apiSuccessRateCritical = 0.80; // 危险：80%

  /// 网络错误率阈值
  static const double networkErrorRateOptimal = 0.01; // 最优：1%
  static const double networkErrorRateGood = 0.05; // 良好：5%
  static const double networkErrorRateWarning = 0.10; // 警告：10%
  static const double networkErrorRateCritical = 0.20; // 危险：20%

  // ========== UI性能阈值 ==========

  /// 帧率阈值 (FPS) - 针对异常高FPS值
  static const int frameRateOptimal = 120; // 最优：120 FPS (允许高刷新率)
  static const int frameRateGood = 200; // 良好：200 FPS
  static const int frameRateWarning = 300; // 警告：300 FPS
  static const int frameRateCritical = 500; // 危险：500 FPS (异常值)

  /// UI渲染时间阈值
  static const int uiRenderTimeOptimal = 16; // 最优：16ms (60 FPS)
  static const int uiRenderTimeGood = 20; // 良好：20ms (50 FPS)
  static const int uiRenderTimeWarning = 33; // 警告：33ms (30 FPS)
  static const int uiRenderTimeCritical = 50; // 危险：50ms (20 FPS)

  // ========== 业务特定阈值 ==========

  /// 基金数据更新频率阈值
  static const int fundDataUpdateIntervalOptimal = 30; // 最优：30秒
  static const int fundDataUpdateIntervalGood = 60; // 良好：1分钟
  static const int fundDataUpdateIntervalWarning = 300; // 警告：5分钟
  static const int fundDataUpdateIntervalCritical = 600; // 危险：10分钟

  /// 搜索建议生成时间阈值
  static const int searchSuggestionTimeOptimal = 100; // 最优：100ms
  static const int searchSuggestionTimeGood = 200; // 良好：200ms
  static const int searchSuggestionTimeWarning = 500; // 警告：500ms
  static const int searchSuggestionTimeCritical = 1000; // 危险：1000ms

  // ========== 工具方法 ==========

  /// 获取响应时间状态
  static PerformanceStatus getResponseTimeStatus(
      int responseTime, String operation) {
    switch (operation.toLowerCase()) {
      case 'search':
        if (responseTime <= searchResponseTimeOptimal) {
          return PerformanceStatus.optimal;
        }
        if (responseTime <= searchResponseTimeGood) {
          return PerformanceStatus.good;
        }
        if (responseTime <= searchResponseTimeWarning) {
          return PerformanceStatus.warning;
        }
        return PerformanceStatus.critical;

      case 'navigation':
        if (responseTime <= pageNavigationTimeOptimal) {
          return PerformanceStatus.optimal;
        }
        if (responseTime <= pageNavigationTimeGood) {
          return PerformanceStatus.good;
        }
        if (responseTime <= pageNavigationTimeWarning) {
          return PerformanceStatus.warning;
        }
        return PerformanceStatus.critical;

      case 'loading':
        if (responseTime <= dataLoadingTimeOptimal) {
          return PerformanceStatus.optimal;
        }
        if (responseTime <= dataLoadingTimeGood) return PerformanceStatus.good;
        if (responseTime <= dataLoadingTimeWarning) {
          return PerformanceStatus.warning;
        }
        return PerformanceStatus.critical;

      default:
        if (responseTime <= searchResponseTimeGood) {
          return PerformanceStatus.optimal;
        }
        if (responseTime <= searchResponseTimeWarning) {
          return PerformanceStatus.good;
        }
        return PerformanceStatus.critical;
    }
  }

  /// 获取缓存命中率状态
  static PerformanceStatus getCacheHitRateStatus(double hitRate) {
    if (hitRate >= cacheHitRateOptimal) return PerformanceStatus.optimal;
    if (hitRate >= cacheHitRateGood) return PerformanceStatus.good;
    if (hitRate >= cacheHitRateWarning) return PerformanceStatus.warning;
    return PerformanceStatus.critical;
  }

  /// 获取内存使用状态
  static PerformanceStatus getMemoryUsageStatus(int memoryUsageMB) {
    if (memoryUsageMB <= memoryUsageOptimal) return PerformanceStatus.optimal;
    if (memoryUsageMB <= memoryUsageGood) return PerformanceStatus.good;
    if (memoryUsageMB <= memoryUsageWarning) return PerformanceStatus.warning;
    return PerformanceStatus.critical;
  }

  /// 获取CPU使用率状态
  static PerformanceStatus getCpuUsageStatus(double cpuUsage) {
    if (cpuUsage <= cpuUsageOptimal) return PerformanceStatus.optimal;
    if (cpuUsage <= cpuUsageGood) return PerformanceStatus.good;
    if (cpuUsage <= cpuUsageWarning) return PerformanceStatus.warning;
    return PerformanceStatus.critical;
  }

  /// 获取API成功率状态
  static PerformanceStatus getApiSuccessRateStatus(double successRate) {
    if (successRate >= apiSuccessRateOptimal) return PerformanceStatus.optimal;
    if (successRate >= apiSuccessRateGood) return PerformanceStatus.good;
    if (successRate >= apiSuccessRateWarning) return PerformanceStatus.warning;
    return PerformanceStatus.critical;
  }

  /// 获取帧率状态 - 监控异常高FPS值
  static PerformanceStatus getFrameRateStatus(int fps) {
    if (fps <= frameRateOptimal) return PerformanceStatus.optimal;
    if (fps <= frameRateGood) return PerformanceStatus.good;
    if (fps <= frameRateWarning) return PerformanceStatus.warning;
    return PerformanceStatus.critical;
  }
}

/// 性能状态枚举
enum PerformanceStatus {
  optimal, // 最优状态 - 绿色
  good, // 良好状态 - 蓝色
  warning, // 警告状态 - 黄色
  critical, // 危险状态 - 红色
}

/// 性能指标类别
enum PerformanceCategory {
  responseTime, // 响应时间
  cache, // 缓存性能
  memory, // 内存使用
  cpu, // CPU使用率
  network, // 网络性能
  ui, // UI性能
  business, // 业务指标
}

/// 性能指标定义
class PerformanceMetric {
  final String name;
  final String description;
  final PerformanceCategory category;
  final String unit;
  final Map<PerformanceStatus, double> thresholds;

  const PerformanceMetric({
    required this.name,
    required this.description,
    required this.category,
    required this.unit,
    required this.thresholds,
  });

  /// 获取状态
  PerformanceStatus getStatus(double value) {
    // 对于frame_rate指标，使用反向逻辑
    if (name == 'frame_rate') {
      if (value <= thresholds[PerformanceStatus.optimal]!) {
        return PerformanceStatus.optimal;
      }
      if (value <= thresholds[PerformanceStatus.good]!) {
        return PerformanceStatus.good;
      }
      if (value <= thresholds[PerformanceStatus.warning]!) {
        return PerformanceStatus.warning;
      }
      return PerformanceStatus.critical;
    }

    // 对于其他指标，使用正常逻辑
    if (value <= thresholds[PerformanceStatus.optimal]!) {
      return PerformanceStatus.optimal;
    }
    if (value <= thresholds[PerformanceStatus.good]!) {
      return PerformanceStatus.good;
    }
    if (value <= thresholds[PerformanceStatus.warning]!) {
      return PerformanceStatus.warning;
    }
    return PerformanceStatus.critical;
  }

  /// 格式化数值
  String formatValue(double value) {
    switch (unit.toLowerCase()) {
      case 'ms':
        return '${value.toInt()}ms';
      case 'mb':
        return '${value.toInt()}MB';
      case '%':
        return '${value.toStringAsFixed(1)}%';
      case 'fps':
        return '${value.toInt()}FPS';
      default:
        return value.toStringAsFixed(2);
    }
  }
}

/// 预定义的性能指标
class PredefinedMetrics {
  static const List<PerformanceMetric> metrics = [
    // 响应时间指标
    PerformanceMetric(
      name: 'search_response_time',
      description: '基金搜索响应时间',
      category: PerformanceCategory.responseTime,
      unit: 'ms',
      thresholds: {
        PerformanceStatus.optimal: 200.0,
        PerformanceStatus.good: 300.0,
        PerformanceStatus.warning: 500.0,
        PerformanceStatus.critical: 1000.0,
      },
    ),

    PerformanceMetric(
      name: 'app_startup_time',
      description: '应用启动时间',
      category: PerformanceCategory.responseTime,
      unit: 'ms',
      thresholds: {
        PerformanceStatus.optimal: 2000.0,
        PerformanceStatus.good: 3000.0,
        PerformanceStatus.warning: 5000.0,
        PerformanceStatus.critical: 8000.0,
      },
    ),

    // 缓存性能指标
    PerformanceMetric(
      name: 'cache_hit_rate',
      description: '缓存命中率',
      category: PerformanceCategory.cache,
      unit: '%',
      thresholds: {
        PerformanceStatus.optimal: 85.0,
        PerformanceStatus.good: 70.0,
        PerformanceStatus.warning: 50.0,
        PerformanceStatus.critical: 30.0,
      },
    ),

    // 内存使用指标
    PerformanceMetric(
      name: 'memory_usage',
      description: '应用内存使用',
      category: PerformanceCategory.memory,
      unit: 'MB',
      thresholds: {
        PerformanceStatus.optimal: 150.0,
        PerformanceStatus.good: 250.0,
        PerformanceStatus.warning: 400.0,
        PerformanceStatus.critical: 600.0,
      },
    ),

    // CPU使用率指标
    PerformanceMetric(
      name: 'cpu_usage',
      description: 'CPU使用率',
      category: PerformanceCategory.cpu,
      unit: '%',
      thresholds: {
        PerformanceStatus.optimal: 30.0,
        PerformanceStatus.good: 50.0,
        PerformanceStatus.warning: 70.0,
        PerformanceStatus.critical: 90.0,
      },
    ),

    // UI性能指标
    PerformanceMetric(
      name: 'frame_rate',
      description: 'UI帧率',
      category: PerformanceCategory.ui,
      unit: 'FPS',
      thresholds: {
        PerformanceStatus.optimal: 120.0,
        PerformanceStatus.good: 200.0,
        PerformanceStatus.warning: 300.0,
        PerformanceStatus.critical: 500.0,
      },
    ),

    // 网络性能指标
    PerformanceMetric(
      name: 'api_success_rate',
      description: 'API请求成功率',
      category: PerformanceCategory.network,
      unit: '%',
      thresholds: {
        PerformanceStatus.optimal: 99.0,
        PerformanceStatus.good: 95.0,
        PerformanceStatus.warning: 90.0,
        PerformanceStatus.critical: 80.0,
      },
    ),
  ];
}
