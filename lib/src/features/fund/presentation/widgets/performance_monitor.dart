import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/logger.dart';

/// 性能监控组件
///
/// 监控毛玻璃效果的性能指标：
/// - 帧率 (FPS)
/// - 渲染时间
/// - 内存使用
/// - 自动降级机制
class PerformanceMonitor extends StatefulWidget {
  /// 子组件
  final Widget child;

  /// 性能阈值配置
  final PerformanceThresholds thresholds;

  /// 性能回调
  final Function(PerformanceMetrics)? onPerformanceUpdate;

  /// 是否启用自动降级
  final bool enableAutoDowngrade;

  /// 调试模式
  final bool debugMode;

  const PerformanceMonitor({
    super.key,
    required this.child,
    this.thresholds = const PerformanceThresholds(),
    this.onPerformanceUpdate,
    this.enableAutoDowngrade = true,
    this.debugMode = false,
  });

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

/// 重试配置
class RetryConfig {
  final int maxRetries;
  final Duration initialDelay;
  final double backoffMultiplier;

  const RetryConfig({
    this.maxRetries = 3,
    this.initialDelay = const Duration(milliseconds: 100),
    this.backoffMultiplier = 2.0,
  });
}

/// 熔断器状态
enum CircuitBreakerState { closed, open, halfOpen }

/// 简单的熔断器实现
class CircuitBreaker {
  CircuitBreakerState _state = CircuitBreakerState.closed;
  int _failureCount = 0;
  DateTime? _lastFailureTime;
  final int failureThreshold;
  final Duration timeout;

  CircuitBreaker(
      {this.failureThreshold = 5, this.timeout = const Duration(seconds: 30)});

  bool get canExecute {
    switch (_state) {
      case CircuitBreakerState.closed:
        return true;
      case CircuitBreakerState.open:
        return DateTime.now().difference(_lastFailureTime!) > timeout;
      case CircuitBreakerState.halfOpen:
        return true;
    }
  }

  T execute<T>(T Function() operation) {
    if (!canExecute) {
      throw Exception('Circuit breaker is open');
    }

    try {
      final result = operation();
      _onSuccess();
      return result;
    } catch (e) {
      _onFailure();
      rethrow;
    }
  }

  void _onSuccess() {
    _failureCount = 0;
    _state = CircuitBreakerState.closed;
  }

  void _onFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();

    if (_failureCount >= failureThreshold) {
      _state = CircuitBreakerState.open;
    }
  }
}

class _PerformanceMonitorState extends State<PerformanceMonitor>
    with TickerProviderStateMixin {
  late AnimationController _monitorController;
  PerformanceMetrics _currentMetrics =
      PerformanceMetrics(timestamp: DateTime.now());
  bool _isDowngraded = false;

  // 重试和熔断器相关
  final CircuitBreaker _circuitBreaker = CircuitBreaker();
  final RetryConfig _retryConfig = const RetryConfig();
  int _retryCount = 0;
  DateTime? _lastSuccessfulMeasurement;

  @override
  void initState() {
    super.initState();
    _monitorController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();

    _monitorController.addListener(_onMonitorTick);
  }

  @override
  void dispose() {
    _monitorController.dispose();
    super.dispose();
  }

  void _onMonitorTick() {
    if (!mounted) return;

    _measurePerformanceWithRetry();
  }

  /// 带重试机制的性能测量
  Future<void> _measurePerformanceWithRetry() async {
    if (!_circuitBreaker.canExecute) {
      AppLogger.warn('PerformanceMonitor: 熔断器开启，跳过性能测量');
      _logCircuitBreakerStatus();
      return;
    }

    try {
      final newMetrics = _circuitBreaker.execute(() => _measurePerformance());

      // 成功测量，更新状态
      setState(() {
        _currentMetrics = newMetrics;
      });

      // 重置重试计数
      _retryCount = 0;
      _lastSuccessfulMeasurement = DateTime.now();

      // 检查是否需要降级
      if (widget.enableAutoDowngrade && !_isDowngraded) {
        _checkAndApplyDowngrade(newMetrics);
      }

      widget.onPerformanceUpdate?.call(newMetrics);

      // 记录成功日志
      _logPerformanceMeasurement(newMetrics, success: true);
    } catch (e, stackTrace) {
      AppLogger.error('PerformanceMonitor: 性能测量失败', e, stackTrace);
      _logPerformanceFailure(e);

      // 尝试重试
      await _retryPerformanceMeasurement();
    }
  }

  /// 重试性能测量
  Future<void> _retryPerformanceMeasurement() async {
    if (_retryCount >= _retryConfig.maxRetries) {
      AppLogger.error(
          'PerformanceMonitor: 性能测量重试次数已达上限: ${_retryConfig.maxRetries}',
          'RetryLimitException');
      _logRetryExhausted();
      return;
    }

    _retryCount++;
    final delay = Duration(
      milliseconds:
          (_retryConfig.initialDelay.inMilliseconds * (1 << _retryCount))
              .toInt(),
    );

    AppLogger.info('PerformanceMonitor',
        '第$_retryCount次重试性能测量，延迟${delay.inMilliseconds}ms');

    await Future.delayed(delay);

    if (mounted) {
      _measurePerformanceWithRetry();
    }
  }

  /// 记录性能测量日志
  void _logPerformanceMeasurement(PerformanceMetrics metrics,
      {required bool success}) {
    if (!widget.debugMode) return;

    final logData = 'FPS: ${metrics.frameRate.toStringAsFixed(1)}, '
        'Render: ${metrics.renderTime.toStringAsFixed(1)}μs, '
        'Memory: ${metrics.memoryUsage.toStringAsFixed(1)}MB, '
        'Downgraded: $_isDowngraded, '
        'Retry: $_retryCount, '
        'CB: ${_circuitBreaker._state.name}';

    if (success) {
      AppLogger.info('PerformanceMonitor: 性能测量成功', logData);
    } else {
      AppLogger.warn('PerformanceMonitor: 性能测量异常', logData);
    }
  }

  /// 记录性能失败日志
  void _logPerformanceFailure(dynamic error) {
    final logData = 'Retry: $_retryCount/${_retryConfig.maxRetries}, '
        'CB Failures: ${_circuitBreaker._failureCount}, '
        'CB State: ${_circuitBreaker._state.name}, '
        'Last Success: ${_lastSuccessfulMeasurement?.toIso8601String() ?? 'Never'}';

    AppLogger.error('PerformanceMonitor: 性能测量失败详情 - $logData', error);
  }

  /// 记录熔断器状态
  void _logCircuitBreakerStatus() {
    final logData = 'State: ${_circuitBreaker._state.name}, '
        'Failures: ${_circuitBreaker._failureCount}/5, '
        'Last Failure: ${_circuitBreaker._lastFailureTime?.toIso8601String() ?? 'Never'}, '
        'Timeout: ${_circuitBreaker.timeout.inSeconds}s';

    AppLogger.warn('PerformanceMonitor: 熔断器状态详情 - $logData');
  }

  /// 记录重试耗尽日志
  void _logRetryExhausted() {
    final logData = 'Total Retries: $_retryCount, '
        'Max Retries: ${_retryConfig.maxRetries}, '
        'Last Success: ${_lastSuccessfulMeasurement?.toIso8601String() ?? 'Never'}, '
        'Recommendation: 建议检查系统性能或降低性能监控频率';

    AppLogger.error(
        'PerformanceMonitor: 性能测量重试机制耗尽 - $logData', 'RetryExhaustedException');
  }

  PerformanceMetrics _measurePerformance() {
    // 使用当前时间作为渲染时间的近似值
    final now = DateTime.now();

    return PerformanceMetrics(
      frameRate: _calculateFrameRate(),
      renderTime: now.millisecondsSinceEpoch.toDouble() * 1000, // 转换为微秒
      memoryUsage: _estimateMemoryUsage(),
      timestamp: now,
    );
  }

  double _calculateFrameRate() {
    // 简化的FPS计算
    // 实际项目中应该使用更精确的方法
    return 60.0; // 假设目标帧率为60fps
  }

  double _estimateMemoryUsage() {
    // 简化的内存使用估算
    // 实际项目中应该使用更精确的方法
    return 0.0;
  }

  void _checkAndApplyDowngrade(PerformanceMetrics metrics) {
    if (metrics.frameRate < widget.thresholds.minFrameRate ||
        metrics.renderTime > widget.thresholds.maxRenderTime) {
      setState(() {
        _isDowngraded = true;
      });

      if (widget.debugMode) {
        debugPrint('PerformanceMonitor: Auto-downgrade triggered');
        debugPrint('Frame Rate: ${metrics.frameRate.toStringAsFixed(1)} FPS');
        debugPrint('Render Time: ${metrics.renderTime.toStringAsFixed(1)} μs');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,

        // 调试信息覆盖层
        if (widget.debugMode)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'FPS: ${_currentMetrics.frameRate.toStringAsFixed(1)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Text(
                    'Render: ${(_currentMetrics.renderTime / 1000).toStringAsFixed(1)}ms',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                  if (_isDowngraded)
                    const Text(
                      'DOWNGRADED',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  if (_circuitBreaker._state != CircuitBreakerState.closed)
                    Text(
                      'CB: ${_circuitBreaker._state.name.toUpperCase()}',
                      style: TextStyle(
                        color:
                            _circuitBreaker._state == CircuitBreakerState.open
                                ? Colors.red
                                : Colors.yellow,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  if (_retryCount > 0)
                    Text(
                      'RETRY: $_retryCount/${_retryConfig.maxRetries}',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// 性能指标数据类
class PerformanceMetrics {
  final double frameRate;
  final double renderTime;
  final double memoryUsage;
  final DateTime timestamp;

  const PerformanceMetrics({
    this.frameRate = 0.0,
    this.renderTime = 0.0,
    this.memoryUsage = 0.0,
    required this.timestamp,
  });

  bool get isGoodPerformance =>
      frameRate >= 55.0 && renderTime <= 16666.0; // 16.66ms
  bool get isPoorPerformance =>
      frameRate < 30.0 || renderTime > 33333.0; // 33.33ms

  @override
  String toString() {
    return 'PerformanceMetrics(frameRate: $frameRate, renderTime: $renderTime, memoryUsage: $memoryUsage)';
  }
}

/// 性能阈值配置
class PerformanceThresholds {
  /// 最小帧率 (FPS)
  final double minFrameRate;

  /// 最大渲染时间 (微秒)
  final double maxRenderTime;

  /// 最大内存使用 (MB)
  final double maxMemoryUsage;

  const PerformanceThresholds({
    this.minFrameRate = 55.0,
    this.maxRenderTime = 16666.0, // 16.66ms for 60fps
    this.maxMemoryUsage = 100.0,
  });

  /// 性能优先配置
  static const PerformanceThresholds performance = PerformanceThresholds(
    minFrameRate: 60.0,
    maxRenderTime: 15000.0, // 15ms
  );

  /// 平衡配置
  static const PerformanceThresholds balanced = PerformanceThresholds(
    minFrameRate: 55.0,
    maxRenderTime: 16666.0, // 16.66ms
  );

  /// 兼容性配置
  static const PerformanceThresholds compatibility = PerformanceThresholds(
    minFrameRate: 30.0,
    maxRenderTime: 33333.0, // 33.33ms
  );
}

/// 性能等级枚举
enum PerformanceLevel {
  excellent,
  good,
  fair,
  poor,
}

extension PerformanceLevelExtension on PerformanceLevel {
  String get displayName {
    switch (this) {
      case PerformanceLevel.excellent:
        return '优秀';
      case PerformanceLevel.good:
        return '良好';
      case PerformanceLevel.fair:
        return '一般';
      case PerformanceLevel.poor:
        return '较差';
    }
  }

  Color get color {
    switch (this) {
      case PerformanceLevel.excellent:
        return Colors.green;
      case PerformanceLevel.good:
        return Colors.blue;
      case PerformanceLevel.fair:
        return Colors.orange;
      case PerformanceLevel.poor:
        return Colors.red;
    }
  }
}

/// 性能工具类
class PerformanceUtils {
  /// 根据性能指标计算性能等级
  static PerformanceLevel calculatePerformanceLevel(
      PerformanceMetrics metrics) {
    if (metrics.frameRate >= 58.0 && metrics.renderTime <= 15000.0) {
      return PerformanceLevel.excellent;
    } else if (metrics.frameRate >= 55.0 && metrics.renderTime <= 16666.0) {
      return PerformanceLevel.good;
    } else if (metrics.frameRate >= 30.0 && metrics.renderTime <= 33333.0) {
      return PerformanceLevel.fair;
    } else {
      return PerformanceLevel.poor;
    }
  }

  /// 建议的毛玻璃配置（基于性能）
  static GlassmorphismConfig suggestGlassmorphismConfig(
    PerformanceLevel level,
    bool isDarkTheme,
  ) {
    switch (level) {
      case PerformanceLevel.excellent:
        return isDarkTheme
            ? GlassmorphismConfig.strong
            : GlassmorphismConfig.strong;
      case PerformanceLevel.good:
        return isDarkTheme
            ? GlassmorphismConfig.medium
            : GlassmorphismConfig.medium;
      case PerformanceLevel.fair:
        return GlassmorphismConfig.light;
      case PerformanceLevel.poor:
        return GlassmorphismConfig.performance;
    }
  }
}
