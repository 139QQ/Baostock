import 'dart:async';
import '../base/i_unified_service.dart';
import '../../utils/logger.dart';

/// UI-配置协调器
///
/// 协调UI服务和配置服务之间的交互
class UIConfigCoordinator extends IUnifiedService {
  // ========== 服务状态 ==========
  bool _isInitialized = false;
  bool _isDisposed = false;

  // ========== 事件流控制器 ==========
  final StreamController<String> _eventController =
      StreamController<String>.broadcast();

  // ========== 构造函数 ==========
  UIConfigCoordinator();

  // ========== IUnifiedService 接口实现 ==========
  @override
  String get serviceName => 'UIConfigCoordinator';

  @override
  String get version => '1.0.0';

  @override
  List<String> get dependencies => ['UnifiedUIService', 'UnifiedConfigService'];

  @override
  Future<void> initialize(ServiceContainer container) async {
    setLifecycleState(ServiceLifecycleState.initializing);

    try {
      // 简化实现：直接记录初始化完成
      _isInitialized = true;
      setLifecycleState(ServiceLifecycleState.initialized);

      AppLogger.info('UIConfigCoordinator initialized successfully');
    } catch (e) {
      setLifecycleState(ServiceLifecycleState.error);
      throw ServiceInitializationException(
        serviceName,
        'Failed to initialize UIConfigCoordinator: $e',
        e,
      );
    }
  }

  @override
  Future<void> dispose() async {
    setLifecycleState(ServiceLifecycleState.disposing);

    try {
      // 关闭事件流
      await _eventController.close();
      _isDisposed = true;

      setLifecycleState(ServiceLifecycleState.disposed);

      AppLogger.info('UIConfigCoordinator disposed successfully');
    } catch (e) {
      setLifecycleState(ServiceLifecycleState.error);
      AppLogger.error('Error disposing UIConfigCoordinator', e);
    }
  }

  @override
  Future<ServiceHealthStatus> checkHealth() async {
    try {
      final isHealthy = _isInitialized && !_isDisposed;

      return ServiceHealthStatus(
        isHealthy: isHealthy,
        message: isHealthy
            ? 'UIConfigCoordinator is healthy'
            : 'UIConfigCoordinator has issues',
        lastCheck: DateTime.now(),
      );
    } catch (e) {
      return ServiceHealthStatus(
        isHealthy: false,
        message: 'Health check failed: $e',
        lastCheck: DateTime.now(),
      );
    }
  }

  @override
  ServiceStats getStats() {
    return ServiceStats(
      serviceName: serviceName,
      version: version,
      uptime: DateTime.now().difference(DateTime.now()), // TODO: 实际启动时间
      memoryUsage: 0,
      customMetrics: {
        'isInitialized': _isInitialized,
        'isDisposed': _isDisposed,
      },
    );
  }

  /// 获取事件流
  Stream<String> get eventStream => _eventController.stream;

  /// 发送事件
  void emitEvent(String event) {
    if (!_isDisposed) {
      _eventController.add(event);
    }
  }
}
