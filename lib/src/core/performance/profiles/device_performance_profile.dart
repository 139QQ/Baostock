import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../monitors/device_performance_detector.dart';
import '../../utils/logger.dart';

/// 性能策略枚举
enum PerformanceStrategy {
  conservative, // 保守策略 - 低端设备
  balanced, // 平衡策略 - 中端设备
  aggressive, // 激进策略 - 高端设备
  ultimate, // 终极策略 - 旗舰设备
  custom, // 自定义策略
}

/// 缓存策略
enum CacheStrategy {
  minimal, // 最小缓存
  conservative, // 保守缓存
  balanced, // 平衡缓存
  aggressive, // 激进缓存
}

/// 动画策略
enum AnimationStrategy {
  disabled, // 禁用动画
  reduced, // 简化动画
  normal, // 正常动画
  enhanced, // 增强动画
}

/// 数据加载策略
enum DataLoadingStrategy {
  onDemand, // 按需加载
  prefetch, // 预取加载
  aggressive, // 激进预取
}

/// 设备性能配置文件
class DevicePerformanceProfile {
  final DevicePerformanceTier tier;
  final PerformanceStrategy strategy;
  final String name;
  final String description;
  final Map<String, dynamic> settings;

  const DevicePerformanceProfile({
    required this.tier,
    required this.strategy,
    required this.name,
    required this.description,
    required this.settings,
  });

  /// 缓存配置
  CacheStrategy get cacheStrategy {
    switch (settings['cache_strategy'] as String?) {
      case 'minimal':
        return CacheStrategy.minimal;
      case 'conservative':
        return CacheStrategy.conservative;
      case 'balanced':
        return CacheStrategy.balanced;
      case 'aggressive':
        return CacheStrategy.aggressive;
      default:
        return CacheStrategy.balanced;
    }
  }

  /// 动画配置
  AnimationStrategy get animationStrategy {
    switch (settings['animation_strategy'] as String?) {
      case 'disabled':
        return AnimationStrategy.disabled;
      case 'reduced':
        return AnimationStrategy.reduced;
      case 'normal':
        return AnimationStrategy.normal;
      case 'enhanced':
        return AnimationStrategy.enhanced;
      default:
        return AnimationStrategy.normal;
    }
  }

  /// 数据加载配置
  DataLoadingStrategy get dataLoadingStrategy {
    switch (settings['data_loading_strategy'] as String?) {
      case 'onDemand':
        return DataLoadingStrategy.onDemand;
      case 'prefetch':
        return DataLoadingStrategy.prefetch;
      case 'aggressive':
        return DataLoadingStrategy.aggressive;
      default:
        return DataLoadingStrategy.prefetch;
    }
  }

  /// 最大缓存大小 (MB)
  int get maxCacheSizeMB => settings['max_cache_size_mb'] as int? ?? 100;

  /// 预加载项目数量
  int get preloadCount => settings['preload_count'] as int? ?? 10;

  /// 并发请求限制
  int get maxConcurrentRequests =>
      settings['max_concurrent_requests'] as int? ?? 5;

  /// 动画持续时间倍数
  double get animationDurationMultiplier =>
      settings['animation_duration_multiplier'] as double? ?? 1.0;

  /// 是否启用压缩
  bool get enableCompression => settings['enable_compression'] as bool? ?? true;

  /// 是否启用数据去重
  bool get enableDeduplication =>
      settings['enable_deduplication'] as bool? ?? true;

  /// 创建低端设备配置
  factory DevicePerformanceProfile.lowEnd() {
    return const DevicePerformanceProfile(
      tier: DevicePerformanceTier.low_end,
      strategy: PerformanceStrategy.conservative,
      name: '低端设备配置',
      description: '适用于2GB内存、4核CPU的低端设备',
      settings: {
        'cache_strategy': 'minimal',
        'animation_strategy': 'disabled',
        'data_loading_strategy': 'onDemand',
        'max_cache_size_mb': 50,
        'preload_count': 5,
        'max_concurrent_requests': 3,
        'animation_duration_multiplier': 0.0,
        'enable_compression': true,
        'enable_deduplication': true,
        'enable_background_processing': false,
        'ui_update_interval_ms': 500,
        'batch_size': 10,
      },
    );
  }

  /// 创建中端设备配置
  factory DevicePerformanceProfile.midRange() {
    return const DevicePerformanceProfile(
      tier: DevicePerformanceTier.mid_range,
      strategy: PerformanceStrategy.balanced,
      name: '中端设备配置',
      description: '适用于4GB内存、6核CPU的中端设备',
      settings: {
        'cache_strategy': 'conservative',
        'animation_strategy': 'reduced',
        'data_loading_strategy': 'prefetch',
        'max_cache_size_mb': 100,
        'preload_count': 10,
        'max_concurrent_requests': 5,
        'animation_duration_multiplier': 0.5,
        'enable_compression': true,
        'enable_deduplication': true,
        'enable_background_processing': true,
        'ui_update_interval_ms': 200,
        'batch_size': 20,
      },
    );
  }

  /// 创建高端设备配置
  factory DevicePerformanceProfile.highEnd() {
    return const DevicePerformanceProfile(
      tier: DevicePerformanceTier.high_end,
      strategy: PerformanceStrategy.aggressive,
      name: '高端设备配置',
      description: '适用于8GB内存、8核CPU的高端设备',
      settings: {
        'cache_strategy': 'balanced',
        'animation_strategy': 'normal',
        'data_loading_strategy': 'prefetch',
        'max_cache_size_mb': 200,
        'preload_count': 20,
        'max_concurrent_requests': 8,
        'animation_duration_multiplier': 1.0,
        'enable_compression': true,
        'enable_deduplication': true,
        'enable_background_processing': true,
        'ui_update_interval_ms': 100,
        'batch_size': 50,
      },
    );
  }

  /// 创建旗舰设备配置
  factory DevicePerformanceProfile.ultimate() {
    return const DevicePerformanceProfile(
      tier: DevicePerformanceTier.ultimate,
      strategy: PerformanceStrategy.ultimate,
      name: '旗舰设备配置',
      description: '适用于16GB内存、12核CPU的旗舰设备',
      settings: {
        'cache_strategy': 'aggressive',
        'animation_strategy': 'enhanced',
        'data_loading_strategy': 'aggressive',
        'max_cache_size_mb': 500,
        'preload_count': 50,
        'max_concurrent_requests': 12,
        'animation_duration_multiplier': 1.2,
        'enable_compression': true,
        'enable_deduplication': true,
        'enable_background_processing': true,
        'ui_update_interval_ms': 50,
        'batch_size': 100,
        'enable_advanced_features': true,
        'enable_experimental_features': true,
      },
    );
  }

  /// 创建自定义配置
  factory DevicePerformanceProfile.custom({
    required String name,
    required String description,
    required Map<String, dynamic> settings,
  }) {
    return DevicePerformanceProfile(
      tier: DevicePerformanceTier.mid_range,
      strategy: PerformanceStrategy.custom,
      name: name,
      description: description,
      settings: settings,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'tier': tier.name,
      'strategy': strategy.name,
      'name': name,
      'description': description,
      'settings': settings,
    };
  }

  /// 从JSON创建
  factory DevicePerformanceProfile.fromJson(Map<String, dynamic> json) {
    return DevicePerformanceProfile(
      tier: DevicePerformanceTier.values.firstWhere(
        (tier) => tier.name == json['tier'],
        orElse: () => DevicePerformanceTier.mid_range,
      ),
      strategy: PerformanceStrategy.values.firstWhere(
        (strategy) => strategy.name == json['strategy'],
        orElse: () => PerformanceStrategy.balanced,
      ),
      name: json['name'] as String? ?? 'Unknown Profile',
      description: json['description'] as String? ?? 'No description',
      settings: json['settings'] as Map<String, dynamic>? ?? {},
    );
  }

  /// 复制并修改配置
  DevicePerformanceProfile copyWith({
    String? name,
    String? description,
    Map<String, dynamic>? settings,
  }) {
    return DevicePerformanceProfile(
      tier: tier,
      strategy: strategy,
      name: name ?? this.name,
      description: description ?? this.description,
      settings: settings ?? Map<String, dynamic>.from(this.settings),
    );
  }
}

/// 设备性能配置文件管理器
class DeviceProfileManager {
  static DeviceProfileManager? _instance;
  static DeviceProfileManager get instance =>
      _instance ??= DeviceProfileManager._();

  DeviceProfileManager._();

  SharedPreferences? _prefs;
  DevicePerformanceProfile? _currentProfile;
  DevicePerformanceProfile? _activeProfile;

  /// 初始化
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadCurrentProfile();
      AppLogger.business('DeviceProfileManager初始化完成');
    } catch (e) {
      AppLogger.error('DeviceProfileManager初始化失败', e);
    }
  }

  /// 加载当前配置
  Future<void> _loadCurrentProfile() async {
    if (_prefs == null) return;

    try {
      final profileJson = _prefs!.getString('current_performance_profile');
      if (profileJson != null) {
        final json = jsonDecode(profileJson) as Map<String, dynamic>;
        _currentProfile = DevicePerformanceProfile.fromJson(json);
        AppLogger.debug('已加载性能配置文件', _currentProfile!.name);
      } else {
        // 首次使用，创建默认配置
        await _createDefaultProfile();
      }
      _activeProfile = _currentProfile;
    } catch (e) {
      AppLogger.error('加载性能配置文件失败', e);
      await _createDefaultProfile();
    }
  }

  /// 创建默认配置
  Future<void> _createDefaultProfile() async {
    if (kDebugMode) {
      _currentProfile = DevicePerformanceProfile.highEnd();
    } else {
      // 根据实际设备性能创建配置
      final deviceInfo = await _detectBasicDeviceInfo();
      _currentProfile = _createProfileForDevice(deviceInfo);
    }
    await saveCurrentProfile();
    AppLogger.business('创建了默认性能配置', _currentProfile!.name);
  }

  /// 检测基础设备信息
  Future<Map<String, dynamic>> _detectBasicDeviceInfo() async {
    try {
      final memoryInfo = await _getMemoryInfo();
      return {
        'totalMemoryMB': memoryInfo['totalMB'] as int? ?? 4096,
        'cpuCores': Platform.numberOfProcessors,
      };
    } catch (e) {
      AppLogger.debug('设备信息检测失败，使用默认值');
      return {
        'totalMemoryMB': 4096,
        'cpuCores': Platform.numberOfProcessors,
      };
    }
  }

  /// 获取内存信息
  Future<Map<String, dynamic>> _getMemoryInfo() async {
    // 简化实现，实际应用中需要使用platform specific APIs
    if (Platform.isWindows) {
      return {'totalMB': 8192}; // 8GB默认值
    } else if (Platform.isMacOS || Platform.isLinux) {
      return {'totalMB': 16384}; // 16GB默认值
    } else {
      return {'totalMB': 4096}; // 4GB默认值
    }
  }

  /// 根据设备信息创建配置
  DevicePerformanceProfile _createProfileForDevice(
      Map<String, dynamic> deviceInfo) {
    final totalMemoryMB = deviceInfo['totalMemoryMB'] as int? ?? 4096;
    final cpuCores = deviceInfo['cpuCores'] as int? ?? 4;

    if (totalMemoryMB >= 16384 && cpuCores >= 12) {
      return DevicePerformanceProfile.ultimate();
    } else if (totalMemoryMB >= 8192 && cpuCores >= 8) {
      return DevicePerformanceProfile.highEnd();
    } else if (totalMemoryMB >= 4096 && cpuCores >= 6) {
      return DevicePerformanceProfile.midRange();
    } else {
      return DevicePerformanceProfile.lowEnd();
    }
  }

  /// 获取当前配置
  DevicePerformanceProfile get currentProfile =>
      _currentProfile ?? DevicePerformanceProfile.midRange();

  /// 获取活跃配置
  DevicePerformanceProfile get activeProfile =>
      _activeProfile ?? currentProfile;

  /// 保存当前配置
  Future<void> saveCurrentProfile() async {
    if (_prefs == null || _currentProfile == null) return;

    try {
      final profileJson = jsonEncode(_currentProfile!.toJson());
      await _prefs!.setString('current_performance_profile', profileJson);
      AppLogger.debug('性能配置文件已保存', _currentProfile!.name);
    } catch (e) {
      AppLogger.error('保存性能配置文件失败', e);
    }
  }

  /// 应用配置文件
  Future<void> applyProfile(DevicePerformanceProfile profile) async {
    try {
      _activeProfile = profile;
      AppLogger.business('应用性能配置文件', profile.name);

      // 触发配置变更通知
      await _notifyProfileChange(profile);
    } catch (e) {
      AppLogger.error('应用性能配置文件失败', e);
    }
  }

  /// 通知配置变更
  Future<void> _notifyProfileChange(DevicePerformanceProfile profile) async {
    // 这里可以发送事件通知其他组件配置已变更
    // 例如通过事件总线、状态管理等方式
    AppLogger.debug('性能配置文件变更通知', profile.name);
  }

  /// 获取所有预定义配置
  List<DevicePerformanceProfile> get predefinedProfiles => [
        DevicePerformanceProfile.lowEnd(),
        DevicePerformanceProfile.midRange(),
        DevicePerformanceProfile.highEnd(),
        DevicePerformanceProfile.ultimate(),
      ];

  /// 创建自定义配置
  Future<void> createCustomProfile({
    required String name,
    required String description,
    required Map<String, dynamic> settings,
  }) async {
    final customProfile = DevicePerformanceProfile.custom(
      name: name,
      description: description,
      settings: settings,
    );

    _currentProfile = customProfile;
    await saveCurrentProfile();
    AppLogger.business('创建自定义性能配置', name);
  }

  /// 重置为默认配置
  Future<void> resetToDefault() async {
    await _createDefaultProfile();
    await applyProfile(_currentProfile!);
    AppLogger.business('重置为默认性能配置');
  }

  /// 更新配置设置
  Future<void> updateSettings(Map<String, dynamic> newSettings) async {
    if (_currentProfile == null) return;

    final updatedSettings =
        Map<String, dynamic>.from(_currentProfile!.settings);
    updatedSettings.addAll(newSettings);

    _currentProfile = _currentProfile!.copyWith(settings: updatedSettings);
    await saveCurrentProfile();
    await applyProfile(_currentProfile!);

    AppLogger.debug('性能配置设置已更新');
  }

  /// 获取配置摘要
  Map<String, dynamic> getProfileSummary() {
    final profile = activeProfile;
    return {
      'name': profile.name,
      'tier': profile.tier.name,
      'strategy': profile.strategy.name,
      'cacheStrategy': profile.cacheStrategy.name,
      'animationStrategy': profile.animationStrategy.name,
      'dataLoadingStrategy': profile.dataLoadingStrategy.name,
      'maxCacheSizeMB': profile.maxCacheSizeMB,
      'maxConcurrentRequests': profile.maxConcurrentRequests,
      'animationDurationMultiplier': profile.animationDurationMultiplier,
    };
  }

  /// 导出配置
  String exportProfile() {
    return jsonEncode(_currentProfile?.toJson() ?? {});
  }

  /// 导入配置
  Future<bool> importProfile(String profileJson) async {
    try {
      final json = jsonDecode(profileJson) as Map<String, dynamic>;
      final profile = DevicePerformanceProfile.fromJson(json);

      _currentProfile = profile;
      await saveCurrentProfile();
      await applyProfile(profile);

      AppLogger.business('导入性能配置成功', profile.name);
      return true;
    } catch (e) {
      AppLogger.error('导入性能配置失败', e);
      return false;
    }
  }

  /// 清理资源
  Future<void> dispose() async {
    _prefs = null;
    _currentProfile = null;
    _activeProfile = null;
    AppLogger.business('DeviceProfileManager已清理');
  }
}
