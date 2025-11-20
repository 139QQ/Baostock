import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';

import '../../utils/logger.dart';

/// 设备性能等级
enum DevicePerformanceTier {
  low_end, // 低端设备 (0-39分)
  mid_range, // 中端设备 (40-69分)
  high_end, // 高端设备 (70-89分)
  ultimate, // 旗舰设备 (90-100分)
}

/// 设备性能信息
class DevicePerformanceInfo {
  final String deviceModel;
  final String operatingSystem;
  final String operatingSystemVersion;
  final int cpuCores;
  final int totalMemoryMB;
  final int availableMemoryMB;
  final double cpuFrequencyGHz;
  final int performanceScore;
  final DevicePerformanceTier tier;
  final DateTime timestamp;

  DevicePerformanceInfo({
    required this.deviceModel,
    required this.operatingSystem,
    required this.operatingSystemVersion,
    required this.cpuCores,
    required this.totalMemoryMB,
    required this.availableMemoryMB,
    required this.cpuFrequencyGHz,
    required this.performanceScore,
    required this.tier,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'deviceModel': deviceModel,
      'operatingSystem': operatingSystem,
      'operatingSystemVersion': operatingSystemVersion,
      'cpuCores': cpuCores,
      'totalMemoryMB': totalMemoryMB,
      'availableMemoryMB': availableMemoryMB,
      'cpuFrequencyGHz': cpuFrequencyGHz,
      'performanceScore': performanceScore,
      'tier': tier.toString(),
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// 设备性能检测器配置
class DevicePerformanceDetectorConfig {
  /// 性能检测间隔
  final Duration detectionInterval;

  /// 内存检测重试次数
  final int memoryDetectionRetries;

  /// CPU基准测试样本数
  final int cpuBenchmarkSamples;

  /// 设备信息缓存时间
  final Duration deviceInfoCacheTime;

  const DevicePerformanceDetectorConfig({
    this.detectionInterval = const Duration(minutes: 5),
    this.memoryDetectionRetries = 3,
    this.cpuBenchmarkSamples = 100,
    this.deviceInfoCacheTime = const Duration(hours: 1),
  });
}

/// 设备性能检测器
///
/// 实现多维度设备性能检测
class DeviceCapabilityDetector {
  final DevicePerformanceDetectorConfig _config;
  final DeviceInfoPlugin _deviceInfo;

  DevicePerformanceInfo? _cachedInfo;
  DateTime? _lastDetectionTime;

  Timer? _detectionTimer;

  // 性能基准权重
  static const double _memoryWeight = 0.35;
  static const double _cpuWeight = 0.30;
  static const double _storageWeight = 0.20;
  static const double _gpuWeight = 0.15;

  DeviceCapabilityDetector({
    DevicePerformanceDetectorConfig? config,
    DeviceInfoPlugin? deviceInfo,
  })  : _config = config ?? DevicePerformanceDetectorConfig(),
        _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  /// 启动性能检测
  Future<void> start() async {
    AppLogger.business('启动DeviceCapabilityDetector');

    // 初始检测
    await _performDetection();

    // 定期检测
    _detectionTimer = Timer.periodic(
      _config.detectionInterval,
      (_) => _performDetection(),
    );
  }

  /// 停止性能检测
  Future<void> stop() async {
    AppLogger.business('停止DeviceCapabilityDetector');

    _detectionTimer?.cancel();
    _detectionTimer = null;
  }

  /// 获取设备性能信息
  Future<DevicePerformanceInfo> getDevicePerformanceInfo() async {
    if (_cachedInfo != null &&
        _lastDetectionTime != null &&
        DateTime.now().difference(_lastDetectionTime!) <
            _config.deviceInfoCacheTime) {
      return _cachedInfo!;
    }

    await _performDetection();
    return _cachedInfo!;
  }

  /// 强制重新检测
  Future<DevicePerformanceInfo> forceDetection() async {
    _cachedInfo = null;
    _lastDetectionTime = null;
    return await getDevicePerformanceInfo();
  }

  /// 检测设备是否为低端设备
  Future<bool> isLowEndDevice() async {
    final info = await getDevicePerformanceInfo();
    return info.tier == DevicePerformanceTier.low_end;
  }

  /// 检测设备是否支持高级功能
  Future<bool> supportsAdvancedFeatures() async {
    final info = await getDevicePerformanceInfo();
    return info.tier.index >= DevicePerformanceTier.high_end.index;
  }

  /// 获取推荐的功能配置
  Future<Map<String, dynamic>> getRecommendedConfiguration() async {
    final info = await getDevicePerformanceInfo();

    switch (info.tier) {
      case DevicePerformanceTier.low_end:
        return {
          'maxConcurrentTasks': 2,
          'cacheSizeMB': 32,
          'animationLevel': 'disabled',
          'backgroundProcessing': false,
          'imageQuality': 'low',
        };

      case DevicePerformanceTier.mid_range:
        return {
          'maxConcurrentTasks': 4,
          'cacheSizeMB': 128,
          'animationLevel': 'basic',
          'backgroundProcessing': true,
          'imageQuality': 'medium',
        };

      case DevicePerformanceTier.high_end:
        return {
          'maxConcurrentTasks': 8,
          'cacheSizeMB': 512,
          'animationLevel': 'full',
          'backgroundProcessing': true,
          'imageQuality': 'high',
        };

      case DevicePerformanceTier.ultimate:
        return {
          'maxConcurrentTasks': 16,
          'cacheSizeMB': 1024,
          'animationLevel': 'enhanced',
          'backgroundProcessing': true,
          'imageQuality': 'ultra',
        };
    }
  }

  /// 执行性能检测
  Future<void> _performDetection() async {
    try {
      final stopwatch = Stopwatch()..start();

      // 收集设备信息
      final deviceInfo = await _collectDeviceInfo();

      // 执行性能基准测试
      final memoryScore = await _runMemoryBenchmark();
      final cpuScore = await _runCPUBenchmark();
      final storageScore = await _runStorageBenchmark();
      final gpuScore = await _runGPUBenchmark();

      // 计算综合性能分数
      final performanceScore = _calculatePerformanceScore(
        memoryScore,
        cpuScore,
        storageScore,
        gpuScore,
      );

      // 确定性能等级
      final tier = _determinePerformanceTier(performanceScore);

      // 创建设备性能信息
      final info = DevicePerformanceInfo(
        deviceModel: deviceInfo['model'],
        operatingSystem: deviceInfo['os'],
        operatingSystemVersion: deviceInfo['version'],
        cpuCores: deviceInfo['cpuCores'],
        totalMemoryMB: deviceInfo['totalMemoryMB'],
        availableMemoryMB: deviceInfo['availableMemoryMB'],
        cpuFrequencyGHz: deviceInfo['cpuFrequency'],
        performanceScore: performanceScore,
        tier: tier,
        timestamp: DateTime.now(),
      );

      stopwatch.stop();

      // 更新缓存
      _cachedInfo = info;
      _lastDetectionTime = DateTime.now();

      AppLogger.business(
          '设备性能检测完成',
          '设备: ${info.deviceModel}, 性能分数: ${info.performanceScore}, '
              '等级: ${info.tier}, 耗时: ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      AppLogger.error('设备性能检测失败', e);

      // 使用默认值
      _cachedInfo = _createDefaultDeviceInfo();
      _lastDetectionTime = DateTime.now();
    }
  }

  /// 收集设备信息
  Future<Map<String, dynamic>> _collectDeviceInfo() async {
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      return {
        'model': androidInfo.model,
        'os': 'Android',
        'version': androidInfo.version.release,
        'cpuCores': androidInfo.supportedAbis.length,
        'cpuFrequency': _estimateCPUFrequency(androidInfo.hardware),
        'totalMemoryMB': _getTotalMemoryMB(),
        'availableMemoryMB': await _getAvailableMemoryMB(),
      };
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      return {
        'model': iosInfo.model,
        'os': 'iOS',
        'version': iosInfo.systemVersion,
        'cpuCores': _getIOSCpuCores(iosInfo.model),
        'cpuFrequency': _estimateIOSCPUFrequency(iosInfo.model),
        'totalMemoryMB': _getTotalMemoryMB(),
        'availableMemoryMB': await _getAvailableMemoryMB(),
      };
    } else {
      return {
        'model': Platform.localHostname,
        'os': Platform.operatingSystem,
        'version': Platform.operatingSystemVersion,
        'cpuCores': Platform.numberOfProcessors,
        'cpuFrequency': 2.0, // 默认值
        'totalMemoryMB': 4096, // 默认值
        'availableMemoryMB': 2048, // 默认值
      };
    }
  }

  /// 运行内存基准测试
  Future<double> _runMemoryBenchmark() async {
    final stopwatch = Stopwatch()..start();
    final memoryOperations = <List<int>>[];

    try {
      // 内存分配测试
      for (int i = 0; i < 1000; i++) {
        final list = List.generate(1000, (index) => index);
        memoryOperations.add(list);
      }

      // 内存访问测试
      int sum = 0;
      for (final list in memoryOperations) {
        for (final value in list) {
          sum += value;
        }
      }

      stopwatch.stop();

      // 计算分数（时间越短分数越高）
      final elapsedMs = stopwatch.elapsedMilliseconds;
      return max(0, 100 - (elapsedMs / 10));
    } catch (e) {
      AppLogger.error('内存基准测试失败', e);
      return 30.0; // 默认分数
    } finally {
      memoryOperations.clear();
    }
  }

  /// 运行CPU基准测试
  Future<double> _runCPUBenchmark() async {
    final stopwatch = Stopwatch()..start();

    try {
      // CPU密集型计算测试
      int result = 0;
      for (int i = 0; i < _config.cpuBenchmarkSamples; i++) {
        result += _computeFibonacci(30);
      }

      stopwatch.stop();

      // 计算分数
      final elapsedMs = stopwatch.elapsedMilliseconds;
      return max(0, 100 - (elapsedMs / 20));
    } catch (e) {
      AppLogger.error('CPU基准测试失败', e);
      return 30.0; // 默认分数
    }
  }

  /// 运行存储基准测试
  Future<double> _runStorageBenchmark() async {
    final stopwatch = Stopwatch()..start();

    try {
      final testData = List.generate(10000, (i) => 'test_data_$i');

      // 存储写入测试
      for (int i = 0; i < 100; i++) {
        // 模拟存储操作
        testData.join(',');
      }

      stopwatch.stop();

      // 计算分数
      final elapsedMs = stopwatch.elapsedMilliseconds;
      return max(0, 100 - (elapsedMs / 15));
    } catch (e) {
      AppLogger.error('存储基准测试失败', e);
      return 30.0; // 默认分数
    }
  }

  /// 运行GPU基准测试
  Future<double> _runGPUBenchmark() async {
    // 在实际应用中，这里可以运行简单的图形渲染测试
    // 目前返回基于设备类型的估算分数

    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return _estimateAndroidGPUScore(androidInfo.model);
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return _estimateIOSGPUScore(iosInfo.model);
      } else {
        return 50.0; // 桌面平台默认分数
      }
    } catch (e) {
      AppLogger.error('GPU基准测试失败', e);
      return 30.0; // 默认分数
    }
  }

  /// 计算综合性能分数
  int _calculatePerformanceScore(
    double memoryScore,
    double cpuScore,
    double storageScore,
    double gpuScore,
  ) {
    final totalScore = (memoryScore * _memoryWeight) +
        (cpuScore * _cpuWeight) +
        (storageScore * _storageWeight) +
        (gpuScore * _gpuWeight);

    return totalScore.round().clamp(0, 100);
  }

  /// 确定性能等级
  DevicePerformanceTier _determinePerformanceTier(int score) {
    if (score >= 90) return DevicePerformanceTier.ultimate;
    if (score >= 70) return DevicePerformanceTier.high_end;
    if (score >= 40) return DevicePerformanceTier.mid_range;
    return DevicePerformanceTier.low_end;
  }

  /// 创建默认设备信息
  DevicePerformanceInfo _createDefaultDeviceInfo() {
    return DevicePerformanceInfo(
      deviceModel: 'Unknown',
      operatingSystem: Platform.operatingSystem,
      operatingSystemVersion: Platform.operatingSystemVersion,
      cpuCores: Platform.numberOfProcessors,
      totalMemoryMB: 2048,
      availableMemoryMB: 1024,
      cpuFrequencyGHz: 2.0,
      performanceScore: 50,
      tier: DevicePerformanceTier.mid_range,
      timestamp: DateTime.now(),
    );
  }

  /// 辅助方法
  int _computeFibonacci(int n) {
    if (n <= 1) return n;
    return _computeFibonacci(n - 1) + _computeFibonacci(n - 2);
  }

  double _estimateCPUFrequency(String hardware) {
    // 基于硬件信息估算CPU频率
    if (hardware.contains('arm') || hardware.contains('ARM')) {
      if (hardware.contains('v8') || hardware.contains('V8')) {
        return 2.8;
      } else if (hardware.contains('v7') || hardware.contains('V7')) {
        return 1.8;
      }
    }
    return 2.0; // 默认频率
  }

  int _getIOSCpuCores(String model) {
    // 基于iOS设备型号估算CPU核心数
    if (model.contains('iPhone13') ||
        model.contains('iPhone14') ||
        model.contains('iPhone15')) {
      return 6;
    } else if (model.contains('iPhone11') ||
        model.contains('iPhone12') ||
        model.contains('iPhone X')) {
      return 6;
    } else if (model.contains('iPhone8') || model.contains('iPhone9')) {
      return 4;
    }
    return 4; // 默认值
  }

  double _estimateIOSCPUFrequency(String model) {
    // 基于iOS设备型号估算CPU频率
    if (model.contains('iPhone13') ||
        model.contains('iPhone14') ||
        model.contains('iPhone15')) {
      return 3.2;
    } else if (model.contains('iPhone11') ||
        model.contains('iPhone12') ||
        model.contains('iPhone X')) {
      return 2.5;
    } else if (model.contains('iPhone8') || model.contains('iPhone9')) {
      return 2.4;
    }
    return 2.0; // 默认值
  }

  double _estimateAndroidGPUScore(String model) {
    // 基于Android设备型号估算GPU分数
    if (model.toLowerCase().contains('snapdragon') ||
        model.toLowerCase().contains('qualcomm')) {
      if (model.contains('888') ||
          model.contains('8 Gen 1') ||
          model.contains('8 Gen 2')) {
        return 85.0;
      } else if (model.contains('865') || model.contains('870')) {
        return 75.0;
      } else if (model.contains('855') || model.contains('860')) {
        return 65.0;
      }
    }
    return 40.0; // 默认GPU分数
  }

  double _estimateIOSGPUScore(String model) {
    // 基于iOS设备型号估算GPU分数
    if (model.contains('iPhone13') ||
        model.contains('iPhone14') ||
        model.contains('iPhone15')) {
      return 90.0;
    } else if (model.contains('iPhone11') ||
        model.contains('iPhone12') ||
        model.contains('iPhone X')) {
      return 80.0;
    } else if (model.contains('iPhone8') || model.contains('iPhone9')) {
      return 70.0;
    }
    return 50.0; // 默认GPU分数
  }

  int _getTotalMemoryMB() {
    // 获取总内存的简化实现
    // 在实际应用中，应该使用平台特定的API
    if (Platform.isAndroid) {
      return 4096; // 默认值
    } else if (Platform.isIOS) {
      return 3072; // 默认值
    } else {
      return 8192; // 桌面默认值
    }
  }

  Future<int> _getAvailableMemoryMB() async {
    // 获取可用内存的简化实现
    for (int i = 0; i < _config.memoryDetectionRetries; i++) {
      try {
        final result = await SystemChannels.platform.invokeMethod('System.gc');
        final memoryBytes = result['memory'] ?? 1073741824; // 1GB 默认值
        return (memoryBytes / (1024 * 1024)).ceil();
      } catch (e) {
        if (i == _config.memoryDetectionRetries - 1) {
          return 1024; // 默认值
        }
        await Future.delayed(Duration(milliseconds: 100));
      }
    }
    return 1024; // 默认值
  }
}
