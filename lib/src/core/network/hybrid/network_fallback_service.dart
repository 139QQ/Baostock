import 'dart:async';
import 'package:dio/dio.dart';
import '../utils/logger.dart';
import 'fund_api_adapter.dart';
import '../fund_api_client.dart';

/// 网络降级服务
///
/// 在混合数据获取断开时，确保HTTP API功能正常工作
/// 提供无缝的降级和恢复机制
class NetworkFallbackService {
  /// 单例实例
  static final NetworkFallbackService _instance =
      NetworkFallbackService._internal();

  factory NetworkFallbackService() => _instance;

  NetworkFallbackService._internal() {
    _initialize();
  }

  /// 服务状态
  bool _isInitialized = false;
  bool _isRunning = false;

  /// 网络状态监控
  final StreamController<NetworkFallbackStatus> _statusController =
      StreamController<NetworkFallbackStatus>.broadcast();

  /// 降级状态
  bool _isInFallbackMode = false;

  /// 最后成功的时间
  DateTime? _lastSuccessTime;

  /// 连续失败计数
  int _consecutiveFailures = 0;

  /// 降级阈值
  final int _fallbackThreshold = 3;

  /// 恢复检查间隔
  final Duration _recoveryCheckInterval = const Duration(seconds: 30);

  /// 恢复检查定时器
  Timer? _recoveryTimer;

  /// 混合数据适配器引用
  FundApiAdapter? _hybridAdapter;

  /// 监控的端点列表
  final List<String> _monitoredEndpoints = [
    '/api/public/fund_open_fund_rank_em',
    '/api/public/fund_etf_spot_em',
    '/api/public/fund_lof_spot_em',
  ];

  /// 初始化服务
  Future<void> _initialize() async {
    if (_isInitialized) return;

    try {
      AppLogger.info('NetworkFallbackService: 初始化网络降级服务');

      _isInitialized = true;
      _startService();

      AppLogger.info('NetworkFallbackService: 网络降级服务初始化完成');
    } catch (e) {
      AppLogger.error('NetworkFallbackService: 初始化失败', e);
      rethrow;
    }
  }

  /// 启动服务
  Future<void> _startService() async {
    if (_isRunning) return;

    try {
      _isRunning = true;
      _updateStatus(NetworkFallbackStatus.initializing);

      // 尝试初始化混合数据适配器
      _hybridAdapter = FundApiClient.hybridAdapter;

      // 执行初始连接测试
      await _performInitialConnectivityTest();

      // 启动恢复检查定时器
      _startRecoveryTimer();

      _updateStatus(NetworkFallbackStatus.normal);
      AppLogger.info('NetworkFallbackService: 服务已启动');
    } catch (e) {
      _updateStatus(NetworkFallbackStatus.error);
      AppLogger.error('NetworkFallbackService: 服务启动失败', e);
      rethrow;
    }
  }

  /// 执行初始连接测试
  Future<void> _performInitialConnectivityTest() async {
    try {
      // 测试基础HTTP连接
      final basicConnectivity = await _testBasicHttpConnectivity();
      if (!basicConnectivity) {
        throw Exception('基础HTTP连接测试失败');
      }

      // 如果混合数据适配器可用，测试混合数据连接
      if (_hybridAdapter != null) {
        final hybridConnectivity = await _testHybridDataConnectivity();
        if (!hybridConnectivity) {
          AppLogger.warn('NetworkFallbackService: 混合数据连接测试失败，将使用基础HTTP');
        }
      }

      _lastSuccessTime = DateTime.now();
      _consecutiveFailures = 0;
    } catch (e) {
      _consecutiveFailures++;
      AppLogger.error('NetworkFallbackService: 初始连接测试失败', e);

      // 即使混合数据测试失败，也不阻止服务启动
      // 基础HTTP功能仍然可用
    }
  }

  /// 测试基础HTTP连接
  Future<bool> _testBasicHttpConnectivity() async {
    try {
      final response = await FundApiClient.healthCheck();
      return response;
    } catch (e) {
      AppLogger.warn('NetworkFallbackService: 基础HTTP连接测试失败', e);
      return false;
    }
  }

  /// 测试混合数据连接
  Future<bool> _testHybridDataConnectivity() async {
    try {
      if (_hybridAdapter == null) return false;

      final healthStatus = _hybridAdapter!.getHealthStatus();
      return healthStatus['initialized'] == true;
    } catch (e) {
      AppLogger.warn('NetworkFallbackService: 混合数据连接测试失败', e);
      return false;
    }
  }

  /// 启动恢复检查定时器
  void _startRecoveryTimer() {
    _recoveryTimer?.cancel();
    _recoveryTimer = Timer.periodic(_recoveryCheckInterval, (_) {
      _checkForRecovery();
    });
  }

  /// 检查网络恢复状态
  Future<void> _checkForRecovery() async {
    if (!_isInFallbackMode) return;

    try {
      AppLogger.debug('NetworkFallbackService: 检查网络恢复状态');

      // 测试基础HTTP连接
      final basicConnectivity = await _testBasicHttpConnectivity();
      if (basicConnectivity) {
        // 测试混合数据连接（如果可用）
        final hybridConnectivity = _hybridAdapter != null
            ? await _testHybridDataConnectivity()
            : false;

        if (basicConnectivity &&
            (_hybridAdapter == null || hybridConnectivity)) {
          _recoverFromFallback();
        }
      }
    } catch (e) {
      AppLogger.debug('NetworkFallbackService: 恢复检查失败', e);
    }
  }

  /// 从降级模式恢复
  void _recoverFromFallback() {
    if (!_isInFallbackMode) return;

    try {
      AppLogger.info('NetworkFallbackService: 从降级模式恢复');

      _isInFallbackMode = false;
      _consecutiveFailures = 0;
      _lastSuccessTime = DateTime.now();

      // 重新启用混合数据功能（如果之前启用过）
      if (_hybridAdapter != null) {
        FundApiClient.setHybridDataEnabled(true);
      }

      _updateStatus(NetworkFallbackStatus.recovered);

      // 一段时间后切换到正常状态
      Timer(const Duration(seconds: 5), () {
        _updateStatus(NetworkFallbackStatus.normal);
      });
    } catch (e) {
      AppLogger.error('NetworkFallbackService: 恢复过程中出错', e);
    }
  }

  /// 执行降级操作
  void _enterFallbackMode(String reason) {
    if (_isInFallbackMode) return;

    try {
      AppLogger.warn('NetworkFallbackService: 进入降级模式', reason);

      _isInFallbackMode = true;

      // 确保基础HTTP功能仍然可用
      FundApiClient.setHybridDataEnabled(false);

      _updateStatus(NetworkFallbackStatus.fallback);
    } catch (e) {
      AppLogger.error('NetworkFallbackService: 进入降级模式失败', e);
    }
  }

  /// 更新状态
  void _updateStatus(NetworkFallbackStatus status) {
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  /// 获取状态流
  Stream<NetworkFallbackStatus> get statusStream => _statusController.stream;

  /// 获取当前状态
  NetworkFallbackStatus get currentStatus {
    if (_isInFallbackMode) {
      return NetworkFallbackStatus.fallback;
    } else if (_consecutiveFailures >= _fallbackThreshold) {
      return NetworkFallbackStatus.degraded;
    } else if (!_isRunning) {
      return NetworkFallbackStatus.stopped;
    } else {
      return NetworkFallbackStatus.normal;
    }
  }

  /// 报告成功操作
  void reportSuccess(String operation) {
    _consecutiveFailures = 0;
    _lastSuccessTime = DateTime.now();

    // 如果当前在降级模式，尝试恢复
    if (_isInFallbackMode) {
      _checkForRecovery();
    }

    AppLogger.debug('NetworkFallbackService: 报告成功操作', operation);
  }

  /// 报告失败操作
  void reportFailure(String operation, dynamic error) {
    _consecutiveFailures++;

    AppLogger.warn('NetworkFallbackService: 报告失败操作',
        '操作: $operation, 连续失败次数: $_consecutiveFailures, 错误: $error');

    // 检查是否需要降级
    if (_consecutiveFailures >= _fallbackThreshold && !_isInFallbackMode) {
      _enterFallbackMode('连续$_consecutiveFailures次失败: $operation');
    }

    // 如果失败过多，切换到错误状态
    if (_consecutiveFailures >= _fallbackThreshold * 2) {
      _updateStatus(NetworkFallbackStatus.error);
    }
  }

  /// 执行带降级保护的请求
  Future<T> executeWithFallback<T>(
    Future<T> Function() operation,
    String operationName, {
    T? fallbackResult,
    Duration? timeout,
  }) async {
    try {
      final result =
          await operation().timeout(timeout ?? const Duration(seconds: 30));

      reportSuccess(operationName);
      return result;
    } catch (e) {
      reportFailure(operationName, e);

      // 如果有降级结果，返回降级结果
      if (fallbackResult != null) {
        AppLogger.info('NetworkFallbackService: 使用降级结果', operationName);
        return fallbackResult;
      }

      // 否则重新抛出异常
      rethrow;
    }
  }

  /// 获取服务健康报告
  Map<String, dynamic> getHealthReport() {
    final now = DateTime.now();

    return {
      'isInitialized': _isInitialized,
      'isRunning': _isRunning,
      'currentStatus': currentStatus.name,
      'isInFallbackMode': _isInFallbackMode,
      'consecutiveFailures': _consecutiveFailures,
      'lastSuccessTime': _lastSuccessTime?.toIso8601String(),
      'timeSinceLastSuccess': _lastSuccessTime != null
          ? now.difference(_lastSuccessTime!).inMilliseconds
          : null,
      'monitoredEndpointsCount': _monitoredEndpoints.length,
      'hybridAdapterAvailable': _hybridAdapter != null,
      'recoveryCheckInterval': _recoveryCheckInterval.inSeconds,
    };
  }

  /// 停止服务
  Future<void> stop() async {
    if (!_isRunning) return;

    try {
      AppLogger.info('NetworkFallbackService: 停止网络降级服务');

      _recoveryTimer?.cancel();
      _recoveryTimer = null;

      _isRunning = false;
      _updateStatus(NetworkFallbackStatus.stopped);

      AppLogger.info('NetworkFallbackService: 网络降级服务已停止');
    } catch (e) {
      AppLogger.error('NetworkFallbackService: 停止服务失败', e);
    }
  }

  /// 释放资源
  Future<void> dispose() async {
    await stop();

    await _statusController.close();
    _hybridAdapter = null;
    _isInitialized = false;

    AppLogger.info('NetworkFallbackService: 资源已释放');
  }
}

/// 网络降级状态
enum NetworkFallbackStatus {
  /// 未初始化
  initializing,

  /// 正常状态
  normal,

  /// 性能下降
  degraded,

  /// 降级模式
  fallback,

  /// 已恢复
  recovered,

  /// 错误状态
  error,

  /// 已停止
  stopped;

  /// 获取状态描述
  String get description {
    switch (this) {
      case NetworkFallbackStatus.initializing:
        return '初始化中';
      case NetworkFallbackStatus.normal:
        return '正常运行';
      case NetworkFallbackStatus.degraded:
        return '性能下降';
      case NetworkFallbackStatus.fallback:
        return '降级模式';
      case NetworkFallbackStatus.recovered:
        return '已恢复';
      case NetworkFallbackStatus.error:
        return '错误状态';
      case NetworkFallbackStatus.stopped:
        return '已停止';
    }
  }

  /// 是否为健康状态
  bool get isHealthy {
    switch (this) {
      case NetworkFallbackStatus.normal:
      case NetworkFallbackStatus.recovered:
        return true;
      default:
        return false;
    }
  }

  /// 是否需要干预
  bool get needsIntervention {
    switch (this) {
      case NetworkFallbackStatus.error:
      case NetworkFallbackStatus.stopped:
        return true;
      default:
        return false;
    }
  }
}
