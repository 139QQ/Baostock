import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../utils/logger.dart';
import '../performance/monitors/memory_leak_detector.dart';
import '../performance/processors/improved_isolate_manager.dart';
import '../performance/processors/stream_lifecycle_manager.dart';
import '../performance/processors/hybrid_data_parser.dart';
import '../performance/processors/memory_mapped_file_handler.dart';
import '../performance/processors/isolate_communication_optimizer.dart';

/// 性能管理服务
///
/// 整合Story 2.5中的所有性能优化组件，提供统一的性能管理接口
/// 这个服务作为现有架构和新性能组件之间的适配器
class PerformanceManagerService {
  static final PerformanceManagerService _instance =
      PerformanceManagerService._internal();
  factory PerformanceManagerService() => _instance;
  PerformanceManagerService._internal();

  bool _isInitialized = false;
  bool _isMonitoring = false;

  // 组件实例
  late final MemoryLeakDetector _memoryLeakDetector;
  late final ImprovedIsolateManager _isolateManager;
  late final StreamLifecycleManager _streamManager;
  late final HybridDataParser _dataParser;
  // 未使用的组件暂时注释掉
  // late final MemoryMappedFileHandler _fileHandler;
  // late final IsolateCommunicationOptimizer _communicationOptimizer;

  /// 初始化性能管理服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    AppLogger.info('初始化性能管理服务');

    try {
      // 初始化各个组件
      _memoryLeakDetector = MemoryLeakDetector();
      _isolateManager = ImprovedIsolateManager();
      _streamManager = StreamLifecycleManager();
      _dataParser = HybridDataParser();
      // _fileHandler = MemoryMappedFileHandler();
      // _communicationOptimizer = IsolateCommunicationOptimizer();

      // 配置组件
      await _configureComponents();

      _isInitialized = true;
      AppLogger.info('性能管理服务初始化完成');
    } catch (e) {
      AppLogger.error('性能管理服务初始化失败', e);
      rethrow;
    }
  }

  /// 启动性能监控
  Future<void> startMonitoring() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isMonitoring) return;

    AppLogger.info('启动性能监控');

    try {
      // 启动内存泄漏检测
      _memoryLeakDetector.start();

      // 启动Stream生命周期管理
      _streamManager.start();

      _isMonitoring = true;
      AppLogger.info('性能监控已启动');
    } catch (e) {
      AppLogger.error('启动性能监控失败', e);
      rethrow;
    }
  }

  /// 停止性能监控
  Future<void> stopMonitoring() async {
    if (!_isMonitoring) return;

    AppLogger.info('停止性能监控');

    try {
      // 停止内存泄漏检测
      await _memoryLeakDetector.stop();

      // 停止Stream生命周期管理
      await _streamManager.stop();

      _isMonitoring = false;
      AppLogger.info('性能监控已停止');
    } catch (e) {
      AppLogger.error('停止性能监控失败', e);
    }
  }

  /// 手动执行内存泄漏检测
  Future<Map<String, dynamic>> detectMemoryLeaks() async {
    if (!_isInitialized) await initialize();

    try {
      final result = await _memoryLeakDetector.detectLeak();
      return {
        'hasLeak': result.hasLeak,
        'leakScore': result.leakScore,
        'description': result.description,
        'recommendations': result.recommendations,
        'timestamp': result.detectionTime.toIso8601String(),
      };
    } catch (e) {
      AppLogger.error('内存泄漏检测失败', e);
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// 获取当前性能状态
  Future<Map<String, dynamic>> getPerformanceStatus() async {
    if (!_isInitialized) await initialize();

    try {
      final memorySnapshot = await _memoryLeakDetector.getCurrentSnapshot();
      final streamStatus = _streamManager.getStatistics();

      return {
        'memory': {
          'usedMemoryMB': memorySnapshot.usedMemoryMB,
          'totalMemoryMB': memorySnapshot.totalMemoryMB,
          'usagePercentage':
              (memorySnapshot.memoryUsagePercentage * 100).toStringAsFixed(2),
        },
        'streams': {
          'total': streamStatus['totalSubscriptions'],
          'active': streamStatus['activeSubscriptions'],
          'healthy': streamStatus['healthySubscriptions'],
        },
        'isMonitoring': _isMonitoring,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      AppLogger.error('获取性能状态失败', e);
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// 解析数据（使用混合策略）
  Future<List<dynamic>> parseData(dynamic rawData, int itemCount) async {
    if (!_isInitialized) await initialize();

    try {
      // 简化的数据解析，直接返回JSON解析结果
      // 实际应用中可以根据数据大小选择不同的解析策略
      if (rawData is List) {
        return rawData.cast<dynamic>();
      } else if (rawData is String) {
        // 简单的JSON解析
        final data = await compute(_parseJsonString, rawData);
        return data is List ? data.cast<dynamic>() : [data];
      }
      return [rawData];
    } catch (e) {
      AppLogger.error('数据解析失败', e);
      rethrow;
    }
  }

  /// JSON解析辅助函数
  static List<dynamic> _parseJsonString(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      return decoded is List ? decoded.cast<dynamic>() : [decoded];
    } catch (e) {
      return [jsonString];
    }
  }

  /// 强制垃圾回收
  Future<void> forceGarbageCollection() async {
    if (!_isInitialized) await initialize();

    try {
      await _memoryLeakDetector.forceGarbageCollection();
      AppLogger.info('强制垃圾回收完成');
    } catch (e) {
      AppLogger.error('强制垃圾回收失败', e);
    }
  }

  /// 配置各个组件
  Future<void> _configureComponents() async {
    // 配置内存泄漏检测器
    final memoryConfig = MemoryLeakDetectorConfig(
      detectionInterval: const Duration(minutes: 5),
      snapshotHistorySize: 24,
      leakThresholdScore: 70.0,
      consecutiveLeakDetections: 3,
      enableDetailedTracking: true,
      enableAutoGc: false,
      autoGcInterval: const Duration(minutes: 15),
    );
    _memoryLeakDetector.configure(memoryConfig);

    // 简化的Stream配置，使用现有方法
    // _streamManager.configure(streamConfig);

    AppLogger.info('性能组件配置完成');
  }

  /// 清理资源
  Future<void> dispose() async {
    if (_isMonitoring) {
      await stopMonitoring();
    }

    try {
      // 清理各个组件
      await _memoryLeakDetector.stop();
      await _streamManager.stop();

      _isInitialized = false;
      AppLogger.info('性能管理服务已清理');
    } catch (e) {
      AppLogger.error('性能管理服务清理失败', e);
    }
  }
}
