// Package imports
import 'package:flutter/material.dart';

// Core imports
import '../../core/di/di_initializer.dart';
import '../../core/network/hybrid/hybrid_data_manager.dart';
import '../../core/network/polling/polling_manager.dart';
import '../../core/network/realtime/connection_monitor.dart';
import '../../core/network/realtime/fallback_http_service.dart';
import '../../core/network/realtime/websocket_manager.dart';
import '../../core/network/realtime/websocket_models.dart';
import '../../core/state/hybrid_data_status_cubit.dart';
import '../../core/state/realtime_connection_cubit.dart';

// Feature imports
import '../../features/fund/presentation/cubits/realtime_data_cubit.dart';
import '../../features/fund/presentation/fund_exploration/presentation/cubit/fund_exploration_cubit.dart';

// Story 2.3 市场指数相关导入
import '../../features/market/presentation/cubits/index_trend_cubit.dart';
import '../../features/market/presentation/cubits/market_index_cubit.dart';

/// 全局Cubit管理器
///
/// 负责管理应用中所有Cubit实例的生命周期，确保状态在页面切换时保持不变
/// 现在包含实时数据连接管理功能
class GlobalCubitManager {
  /// 私有构造函数，实现单例模式
  GlobalCubitManager._();

  static GlobalCubitManager? _instance;

  /// 获取全局Cubit管理器的单例实例
  static GlobalCubitManager get instance {
    _instance ??= GlobalCubitManager._();
    return _instance!;
  }

  /// WebSocket管理器
  WebSocketManager? _webSocketManager;

  /// HTTP轮询降级服务
  FallbackHttpService? _fallbackHttpService;

  /// 连接监控器
  ConnectionMonitor? _connectionMonitor;

  /// 实时连接状态Cubit
  RealtimeConnectionCubit? _realtimeConnectionCubit;

  /// 实时数据Cubit
  RealtimeDataCubit? _realtimeDataCubit;

  /// 混合数据管理器
  HybridDataManager? _hybridDataManager;

  /// 轮询管理器
  PollingManager? _pollingManager;

  /// 混合数据状态Cubit
  HybridDataStatusCubit? _hybridDataStatusCubit;

  /// 市场指数Cubit
  MarketIndexCubit? _marketIndexCubit;

  /// 指数趋势Cubit
  IndexTrendCubit? _indexTrendCubit;

  /// 是否已初始化实时连接服务
  bool _realtimeServicesInitialized = false;

  /// 是否已初始化混合数据服务
  bool _hybridDataServicesInitialized = false;

  /// 是否已初始化市场指数服务
  bool _marketIndexServicesInitialized = false;

  /// 获取或创建基金探索Cubit
  FundExplorationCubit getFundRankingCubit() {
    debugPrint('🔄 GlobalCubitManager: 获取统一的FundExplorationCubit实例');
    return sl<FundExplorationCubit>();
  }

  /// 初始化实时连接服务
  Future<void> initializeRealtimeServices() async {
    if (_realtimeServicesInitialized) {
      debugPrint('🔄 GlobalCubitManager: 实时连接服务已初始化');
      return;
    }

    try {
      debugPrint('🚀 GlobalCubitManager: 初始化实时连接服务');

      // 创建WebSocket配置
      const webSocketConfig = WebSocketConnectionConfig(
        url: 'ws://154.44.25.92:8080/ws', // 根据实际WebSocket服务器地址配置
        connectTimeout: Duration(seconds: 10),
        heartbeatInterval: Duration(seconds: 30),
        baseReconnectDelay: Duration(seconds: 1),
        maxReconnectDelay: Duration(seconds: 30),
        maxReconnectAttempts: -1, // 无限重连
        autoReconnect: true,
      );

      // 创建WebSocket管理器
      _webSocketManager = WebSocketManager(config: webSocketConfig);

      // 创建HTTP轮询配置
      const fallbackConfig = FallbackHttpConfig(
        basePollInterval: Duration(seconds: 5),
        maxPollInterval: Duration(minutes: 2),
        maxFailureCount: 5,
        endpoints: [
          FallbackEndpoint(path: '/api/public/fund_open_fund_rank_em'),
          FallbackEndpoint(path: '/api/public/fund_etf_spot_em'),
        ],
      );

      // 创建HTTP轮询降级服务
      _fallbackHttpService = FallbackHttpService(config: fallbackConfig);

      // 创建连接监控器
      const monitorConfig = ConnectionMonitorConfig(
        metricsCollectionInterval: Duration(seconds: 5),
        maxLatencyHistory: 100,
        maxEventHistory: 200,
      );
      _connectionMonitor = ConnectionMonitor(config: monitorConfig);

      // 创建实时连接状态Cubit
      _realtimeConnectionCubit = RealtimeConnectionCubit(_webSocketManager!);

      // 创建实时数据Cubit
      _realtimeDataCubit = RealtimeDataCubit(
        webSocketManager: _webSocketManager!,
        fallbackHttpService: _fallbackHttpService!,
        connectionCubit: _realtimeConnectionCubit!,
      );

      // 启动连接监控
      _connectionMonitor!.startMonitoring();

      _realtimeServicesInitialized = true;

      debugPrint('✅ GlobalCubitManager: 实时连接服务初始化完成');
    } catch (e) {
      debugPrint('❌ GlobalCubitManager: 实时连接服务初始化失败: $e');
      rethrow;
    }
  }

  /// 初始化混合数据服务
  Future<void> initializeHybridDataServices() async {
    if (_hybridDataServicesInitialized) {
      debugPrint('🔄 GlobalCubitManager: 混合数据服务已初始化');
      return;
    }

    try {
      debugPrint('🚀 GlobalCubitManager: 初始化混合数据服务');

      // 确保实时服务已初始化
      if (!_realtimeServicesInitialized) {
        await initializeRealtimeServices();
      }

      // 创建混合数据管理器
      _hybridDataManager = HybridDataManager();
      // HybridDataManager 在构造函数中自动初始化

      // 创建轮询管理器
      _pollingManager = PollingManager();
      // PollingManager 在构造函数中自动初始化

      // 创建混合数据状态Cubit
      _hybridDataStatusCubit = HybridDataStatusCubit(
        hybridDataManager: _hybridDataManager!,
        pollingManager: _pollingManager!,
      );

      _hybridDataServicesInitialized = true;

      debugPrint('✅ GlobalCubitManager: 混合数据服务初始化完成');
    } catch (e) {
      debugPrint('❌ GlobalCubitManager: 混合数据服务初始化失败: $e');
      rethrow;
    }
  }

  /// 获取实时连接状态Cubit
  RealtimeConnectionCubit? getRealtimeConnectionCubit() {
    if (!_realtimeServicesInitialized) {
      debugPrint('⚠️ GlobalCubitManager: 实时连接服务未初始化');
      return null;
    }
    return _realtimeConnectionCubit;
  }

  /// 获取实时数据Cubit
  RealtimeDataCubit? getRealtimeDataCubit() {
    if (!_realtimeServicesInitialized) {
      debugPrint('⚠️ GlobalCubitManager: 实时连接服务未初始化');
      return null;
    }
    return _realtimeDataCubit;
  }

  /// 获取混合数据状态Cubit
  HybridDataStatusCubit? getHybridDataStatusCubit() {
    if (!_hybridDataServicesInitialized) {
      debugPrint('⚠️ GlobalCubitManager: 混合数据服务未初始化');
      return null;
    }
    return _hybridDataStatusCubit;
  }

  /// 获取混合数据管理器
  HybridDataManager? getHybridDataManager() {
    return _hybridDataManager;
  }

  /// 获取轮询管理器
  PollingManager? getPollingManager() {
    return _pollingManager;
  }

  /// 获取WebSocket管理器
  WebSocketManager? getWebSocketManager() {
    return _webSocketManager;
  }

  /// 获取HTTP轮询服务
  FallbackHttpService? getFallbackHttpService() {
    return _fallbackHttpService;
  }

  /// 连接到实时数据服务
  Future<void> connectRealtime() async {
    if (!_realtimeServicesInitialized) {
      await initializeRealtimeServices();
    }

    try {
      await _realtimeDataCubit?.connect();
      debugPrint('🔗 GlobalCubitManager: 已连接到实时数据服务');
    } catch (e) {
      debugPrint('❌ GlobalCubitManager: 连接实时数据服务失败: $e');
      rethrow;
    }
  }

  /// 断开实时数据连接
  Future<void> disconnectRealtime() async {
    try {
      await _realtimeDataCubit?.disconnect();
      debugPrint('🔌 GlobalCubitManager: 已断开实时数据连接');
    } catch (e) {
      debugPrint('❌ GlobalCubitManager: 断开实时数据连接失败: $e');
    }
  }

  /// 刷新实时数据
  Future<void> refreshRealtimeData() async {
    try {
      _realtimeDataCubit?.refreshData();
      debugPrint('🔄 GlobalCubitManager: 正在刷新实时数据');
    } catch (e) {
      debugPrint('❌ GlobalCubitManager: 刷新实时数据失败: $e');
    }
  }

  /// 获取实时连接状态信息
  Map<String, dynamic> getRealtimeConnectionInfo() {
    if (!_realtimeServicesInitialized) {
      return {'error': '实时连接服务未初始化'};
    }

    try {
      return _realtimeDataCubit?.getConnectionStats() ?? {};
    } catch (e) {
      return {'error': '获取连接信息失败: $e'};
    }
  }

  /// 重置基金探索Cubit（用于应用重启或完全刷新）
  void resetFundRankingCubit() {
    debugPrint('🔄 GlobalCubitManager: 重置基金探索Cubit');
    // 注意：由于使用了依赖注入，这里不做close操作
    // 让依赖注入容器管理实例生命周期
  }

  /// 连接到混合数据服务
  Future<void> connectHybridData() async {
    if (!_hybridDataServicesInitialized) {
      await initializeHybridDataServices();
    }

    try {
      await _hybridDataManager?.start();
      await _pollingManager?.start();
      debugPrint('🔗 GlobalCubitManager: 已连接到混合数据服务');
    } catch (e) {
      debugPrint('❌ GlobalCubitManager: 连接混合数据服务失败: $e');
      rethrow;
    }
  }

  /// 断开混合数据连接
  Future<void> disconnectHybridData() async {
    try {
      await _pollingManager?.stop();
      await _hybridDataManager?.stop();
      debugPrint('🔌 GlobalCubitManager: 已断开混合数据连接');
    } catch (e) {
      debugPrint('❌ GlobalCubitManager: 断开混合数据连接失败: $e');
    }
  }

  /// 刷新混合数据状态
  Future<void> refreshHybridDataStatus() async {
    try {
      _hybridDataStatusCubit?.refresh();
      debugPrint('🔄 GlobalCubitManager: 正在刷新混合数据状态');
    } catch (e) {
      debugPrint('❌ GlobalCubitManager: 刷新混合数据状态失败: $e');
    }
  }

  /// 获取混合数据状态信息
  Map<String, dynamic> getHybridDataStatusInfo() {
    if (!_hybridDataServicesInitialized) {
      return {'error': '混合数据服务未初始化'};
    }

    try {
      return _hybridDataStatusCubit?.getStatusReport() ?? {};
    } catch (e) {
      return {'error': '获取混合数据状态失败: $e'};
    }
  }

  /// 重置实时连接服务
  Future<void> resetRealtimeServices() async {
    try {
      await disconnectRealtime();

      // 销毁现有服务
      _connectionMonitor?.dispose();
      await _webSocketManager?.dispose();
      await _fallbackHttpService?.dispose();
      await _realtimeConnectionCubit?.close();
      await _realtimeDataCubit?.close();

      _realtimeServicesInitialized = false;
      _webSocketManager = null;
      _fallbackHttpService = null;
      _connectionMonitor = null;
      _realtimeConnectionCubit = null;
      _realtimeDataCubit = null;

      debugPrint('🔄 GlobalCubitManager: 实时连接服务已重置');
    } catch (e) {
      debugPrint('❌ GlobalCubitManager: 重置实时连接服务失败: $e');
    }
  }

  /// 重置混合数据服务
  Future<void> resetHybridDataServices() async {
    try {
      await disconnectHybridData();

      // 销毁现有服务
      // 注意：PollingManager 和 HybridDataManager 没有 dispose 方法
      await _hybridDataStatusCubit?.close();

      _hybridDataServicesInitialized = false;
      _hybridDataManager = null;
      _pollingManager = null;
      _hybridDataStatusCubit = null;

      debugPrint('🔄 GlobalCubitManager: 混合数据服务已重置');
    } catch (e) {
      debugPrint('❌ GlobalCubitManager: 重置混合数据服务失败: $e');
    }
  }

  /// 获取或创建市场指数Cubit
  MarketIndexCubit getMarketIndexCubit() {
    if (!_marketIndexServicesInitialized) {
      debugPrint('⚠️ GlobalCubitManager: 市场指数服务未初始化，正在初始化...');
      initializeMarketIndexServices().catchError((e) {
        debugPrint('❌ GlobalCubitManager: 市场指数服务初始化失败: $e');
      });
    }

    debugPrint('🔄 GlobalCubitManager: 获取MarketIndexCubit实例');
    return _marketIndexCubit ??= sl<MarketIndexCubit>();
  }

  /// 获取或创建指数趋势Cubit
  IndexTrendCubit getIndexTrendCubit() {
    if (!_marketIndexServicesInitialized) {
      debugPrint('⚠️ GlobalCubitManager: 市场指数服务未初始化，正在初始化...');
      initializeMarketIndexServices().catchError((e) {
        debugPrint('❌ GlobalCubitManager: 市场指数服务初始化失败: $e');
      });
    }

    debugPrint('🔄 GlobalCubitManager: 获取IndexTrendCubit实例');
    return _indexTrendCubit ??= sl<IndexTrendCubit>();
  }

  /// 初始化市场指数服务
  Future<void> initializeMarketIndexServices() async {
    if (_marketIndexServicesInitialized) {
      debugPrint('🔄 GlobalCubitManager: 市场指数服务已初始化');
      return;
    }

    try {
      debugPrint('🚀 GlobalCubitManager: 初始化市场指数服务');

      // 创建市场指数Cubit
      _marketIndexCubit = sl<MarketIndexCubit>();

      // 创建指数趋势Cubit
      _indexTrendCubit = sl<IndexTrendCubit>();

      // 启动市场指数数据轮询
      _marketIndexCubit?.onEvent(const StartPolling());

      _marketIndexServicesInitialized = true;

      debugPrint('✅ GlobalCubitManager: 市场指数服务初始化完成');
    } catch (e) {
      debugPrint('❌ GlobalCubitManager: 市场指数服务初始化失败: $e');
      rethrow;
    }
  }

  /// 获取基金探索状态信息
  String getFundRankingStatusInfo() {
    try {
      final cubit = sl<FundExplorationCubit>();
      final state = cubit.state;
      return '状态: ${state.status}, 数据量: ${state.fundRankings.length}, 加载中: ${state.isLoading}, 错误: "${state.errorMessage ?? "无"}"';
    } catch (e) {
      return '获取状态失败: $e';
    }
  }

  /// 获取市场指数状态信息
  String getMarketIndexStatusInfo() {
    try {
      if (_marketIndexCubit == null) {
        return '市场指数服务未初始化';
      }

      final state = _marketIndexCubit!.state;
      return '指数数量: ${state.indices.length}, 轮询中: ${state.isPolling}, 加载中: ${state.isLoading}, 错误: "${state.error ?? "无"}"';
    } catch (e) {
      return '获取市场指数状态失败: $e';
    }
  }

  /// 获取综合状态信息
  Map<String, dynamic> getComprehensiveStatusInfo() {
    return {
      'fundExploration': getFundRankingStatusInfo(),
      'marketIndex': getMarketIndexStatusInfo(),
      'realtimeConnection': getRealtimeConnectionInfo(),
      'hybridDataStatus': getHybridDataStatusInfo(),
      'realtimeServicesInitialized': _realtimeServicesInitialized,
      'hybridDataServicesInitialized': _hybridDataServicesInitialized,
      'marketIndexServicesInitialized': _marketIndexServicesInitialized,
    };
  }

  /// 保存状态快照（用于迁移）
  Future<void> saveStateSnapshot() async {
    debugPrint('💾 GlobalCubitManager: 保存状态快照...');
    try {
      // 这里可以实现具体的状态保存逻辑
      // 例如保存当前Cubit的状态到持久化存储
      debugPrint('✅ GlobalCubitManager: 状态快照保存完成');
    } catch (e) {
      debugPrint('❌ GlobalCubitManager: 状态快照保存失败: $e');
      rethrow;
    }
  }

  /// 释放所有资源
  Future<void> dispose() async {
    debugPrint('🗑️ GlobalCubitManager: 释放资源管理器');

    // 先释放混合数据服务
    await resetHybridDataServices();

    // 再释放实时连接服务
    await resetRealtimeServices();

    // 依赖注入容器负责其他资源的释放
  }
}
