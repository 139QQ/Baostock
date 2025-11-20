import 'dart:async';
import 'dart:math';

import '../monitors/device_performance_detector.dart';
import '../managers/advanced_memory_manager.dart';
import '../../utils/logger.dart';

/// 缓存配置文件
class CacheProfile {
  final String name;
  final int maxCacheSizeMB;
  final Duration ttl;
  final int maxItemCount;
  final double evictionThreshold;
  final bool enableCompression;

  const CacheProfile({
    required this.name,
    required this.maxCacheSizeMB,
    required this.ttl,
    required this.maxItemCount,
    required this.evictionThreshold,
    this.enableCompression = false,
  });
}

/// 动态缓存调整器
///
/// 根据设备性能和内存压力动态调整缓存策略
class DynamicCacheAdjuster {
  static const Map<String, CacheProfile> _cacheProfiles = {
    'low_end': CacheProfile(
      name: 'low_end',
      maxCacheSizeMB: 32,
      ttl: Duration(minutes: 10),
      maxItemCount: 100,
      evictionThreshold: 0.6,
      enableCompression: true,
    ),
    'mid_range': CacheProfile(
      name: 'mid_range',
      maxCacheSizeMB: 128,
      ttl: Duration(minutes: 30),
      maxItemCount: 500,
      evictionThreshold: 0.75,
      enableCompression: false,
    ),
    'high_end': CacheProfile(
      name: 'high_end',
      maxCacheSizeMB: 512,
      ttl: Duration(hours: 2),
      maxItemCount: 2000,
      evictionThreshold: 0.85,
      enableCompression: false,
    ),
    'ultimate': CacheProfile(
      name: 'ultimate',
      maxCacheSizeMB: 1024,
      ttl: Duration(hours: 6),
      maxItemCount: 5000,
      evictionThreshold: 0.9,
      enableCompression: false,
    ),
  };

  final DeviceCapabilityDetector _deviceDetector;
  final AdvancedMemoryManager _memoryManager;
  final Map<String, CacheProfile> _activeProfiles = {};

  Timer? _adjustmentTimer;
  DevicePerformanceInfo? _lastDeviceInfo;
  MemoryPressureLevel? _lastPressureLevel;

  DynamicCacheAdjuster({
    required DeviceCapabilityDetector deviceDetector,
    required AdvancedMemoryManager memoryManager,
  })  : _deviceDetector = deviceDetector,
        _memoryManager = memoryManager;

  /// 启动动态调整
  Future<void> start() async {
    AppLogger.business('启动DynamicCacheAdjuster');

    // 初始调整
    await _performAdjustment();

    // 定期调整（每30秒检查一次）
    _adjustmentTimer = Timer.periodic(Duration(seconds: 30), (_) {
      _performAdjustment();
    });
  }

  /// 停止动态调整
  Future<void> stop() async {
    AppLogger.business('停止DynamicCacheAdjuster');

    _adjustmentTimer?.cancel();
    _adjustmentTimer = null;
  }

  /// 手动触发调整
  Future<void> triggerAdjustment() async {
    await _performAdjustment();
  }

  /// 获取缓存配置
  CacheProfile? getCacheProfile(String cacheName) {
    return _activeProfiles[cacheName];
  }

  /// 注册缓存类型
  void registerCacheType(String cacheName, String deviceCategory) {
    final profile = _cacheProfiles[deviceCategory];
    if (profile != null) {
      _activeProfiles[cacheName] = profile;
      AppLogger.debug('缓存类型已注册: $cacheName -> $deviceCategory');
    }
  }

  /// 执行调整
  Future<void> _performAdjustment() async {
    try {
      // 获取当前设备信息
      final deviceInfo = await _deviceDetector.getDevicePerformanceInfo();
      final currentPressureLevel = _memoryManager.currentPressureLevel;

      // 检查是否需要调整
      if (_shouldAdjust(deviceInfo, currentPressureLevel)) {
        await _adjustCacheProfiles(deviceInfo, currentPressureLevel);

        _lastDeviceInfo = deviceInfo;
        _lastPressureLevel = currentPressureLevel;
      }
    } catch (e) {
      AppLogger.error('动态缓存调整失败', e);
    }
  }

  /// 判断是否需要调整
  bool _shouldAdjust(
      DevicePerformanceInfo deviceInfo, MemoryPressureLevel pressureLevel) {
    // 第一次运行时需要调整
    if (_lastDeviceInfo == null || _lastPressureLevel == null) {
      return true;
    }

    // 设备性能等级变化
    if (_lastDeviceInfo!.performanceScore != deviceInfo.performanceScore) {
      return true;
    }

    // 内存压力级别变化
    if (_lastPressureLevel != pressureLevel) {
      return true;
    }

    // 可用内存变化超过20%
    final lastAvailableMB = _lastDeviceInfo!.availableMemoryMB;
    final currentAvailableMB = deviceInfo.availableMemoryMB;
    if (lastAvailableMB > 0) {
      final changeRatio =
          (currentAvailableMB - lastAvailableMB).abs() / lastAvailableMB;
      if (changeRatio > 0.2) {
        return true;
      }
    }

    return false;
  }

  /// 调整缓存配置
  Future<void> _adjustCacheProfiles(
    DevicePerformanceInfo deviceInfo,
    MemoryPressureLevel pressureLevel,
  ) async {
    final deviceCategory = _getDeviceCategory(deviceInfo);
    final adjustedProfile =
        _createAdjustedProfile(deviceCategory, pressureLevel);

    // 应用调整到所有活跃的缓存
    for (final cacheName in _activeProfiles.keys) {
      _activeProfiles[cacheName] = adjustedProfile;
    }

    AppLogger.business(
        '缓存配置已调整',
        '设备类别: $deviceCategory, 压力级别: $pressureLevel, '
            '缓存大小: ${adjustedProfile.maxCacheSizeMB}MB');
  }

  /// 获取设备类别
  String _getDeviceCategory(DevicePerformanceInfo deviceInfo) {
    final score = deviceInfo.performanceScore;

    if (score >= 80) return 'ultimate';
    if (score >= 60) return 'high_end';
    if (score >= 40) return 'mid_range';
    return 'low_end';
  }

  /// 创建调整后的配置
  CacheProfile _createAdjustedProfile(
      String baseCategory, MemoryPressureLevel pressureLevel) {
    final baseProfile = _cacheProfiles[baseCategory]!;

    // 根据内存压力调整参数
    late final int adjustedCacheSize;
    late final double adjustedEvictionThreshold;
    late final Duration adjustedTTL;

    switch (pressureLevel) {
      case MemoryPressureLevel.normal:
        adjustedCacheSize = baseProfile.maxCacheSizeMB;
        adjustedEvictionThreshold = baseProfile.evictionThreshold;
        adjustedTTL = baseProfile.ttl;
        break;

      case MemoryPressureLevel.warning:
        adjustedCacheSize = (baseProfile.maxCacheSizeMB * 0.8).toInt();
        adjustedEvictionThreshold = baseProfile.evictionThreshold * 0.9;
        adjustedTTL = Duration(
            milliseconds: (baseProfile.ttl.inMilliseconds * 0.7).toInt());
        break;

      case MemoryPressureLevel.critical:
        adjustedCacheSize = (baseProfile.maxCacheSizeMB * 0.6).toInt();
        adjustedEvictionThreshold = baseProfile.evictionThreshold * 0.8;
        adjustedTTL = Duration(
            milliseconds: (baseProfile.ttl.inMilliseconds * 0.5).toInt());
        break;

      case MemoryPressureLevel.emergency:
        adjustedCacheSize = (baseProfile.maxCacheSizeMB * 0.4).toInt();
        adjustedEvictionThreshold = baseProfile.evictionThreshold * 0.7;
        adjustedTTL = Duration(
            milliseconds: (baseProfile.ttl.inMilliseconds * 0.3).toInt());
        break;
    }

    return CacheProfile(
      name: '${baseProfile.name}_${pressureLevel.toString().split('.').last}',
      maxCacheSizeMB: max(16, adjustedCacheSize), // 最小16MB
      ttl: adjustedTTL,
      maxItemCount: (baseProfile.maxItemCount *
              (adjustedCacheSize / baseProfile.maxCacheSizeMB))
          .toInt(),
      evictionThreshold: max(0.5, adjustedEvictionThreshold), // 最小50%
      enableCompression:
          pressureLevel.index >= MemoryPressureLevel.warning.index,
    );
  }

  /// 获取当前调整统计
  Map<String, dynamic> getAdjustmentStats() {
    return {
      'lastDeviceInfo': _lastDeviceInfo?.toJson(),
      'lastPressureLevel': _lastPressureLevel?.toString(),
      'activeProfileCount': _activeProfiles.length,
      'registeredCaches': _activeProfiles.keys.toList(),
    };
  }
}
