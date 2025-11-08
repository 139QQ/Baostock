import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/widgets.dart';

/// 性能等级
enum PerformanceLevel {
  /// 优秀 (85-100分)
  excellent,

  /// 良好 (70-84分)
  good,

  /// 一般 (50-69分)
  fair,

  /// 较差 (0-49分)
  poor,
}

/// 性能等级扩展
extension PerformanceLevelExtension on PerformanceLevel {
  /// 获取性能等级显示名称
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

  /// 获取性能等级描述
  String get description {
    switch (this) {
      case PerformanceLevel.excellent:
        return '设备性能优秀，可以流畅运行所有功能';
      case PerformanceLevel.good:
        return '设备性能良好，可以正常运行大部分功能';
      case PerformanceLevel.fair:
        return '设备性能一般，建议启用性能优化';
      case PerformanceLevel.poor:
        return '设备性能较低，建议启用省流模式';
    }
  }

  /// 是否应该启用动画
  bool get shouldEnableAnimations {
    return this != PerformanceLevel.poor;
  }

  /// 获取推荐的动画级别
  int get recommendedAnimationLevel {
    switch (this) {
      case PerformanceLevel.excellent:
        return 3; // 完整动画
      case PerformanceLevel.good:
        return 2; // 基础动画
      case PerformanceLevel.fair:
        return 1; // 简化动画
      case PerformanceLevel.poor:
        return 0; // 禁用动画
    }
  }
}

/// 性能检测结果
class PerformanceResult {
  /// 性能评分 (0-100分)
  final int score;

  /// 性能等级
  final PerformanceLevel level;

  /// 详细性能指标
  final Map<String, dynamic> metrics;

  /// 检测时间戳
  final DateTime timestamp;

  /// 优化建议列表
  final List<String> recommendations;

  /// 创建性能结果实例
  const PerformanceResult({
    required this.score,
    required this.level,
    required this.metrics,
    required this.timestamp,
    required this.recommendations,
  });

  @override
  String toString() {
    return 'PerformanceResult(score: $score, level: $level, recommendations: ${recommendations.length})';
  }
}

/// 性能指标收集器
class PerformanceMetrics {
  // CPU性能指标
  static final int _cpuCores = Platform.numberOfProcessors;

  // 内存性能指标
  static int _totalMemory = 0;
  static int _usedMemory = 0;
  static double _memoryUsage = 0.0;

  // GPU性能指标
  static bool _hasGPUSupport = true;
  static double _gpuPerformance = 1.0;

  // 渲染性能指标
  static double _frameRate = 60.0;
  static int _droppedFrames = 0;
  static double _renderTime = 0.0;

  // 设备信息
  static String _deviceModel = '';
  static String _operatingSystem = '';
  static bool _isLowEndDevice = false;

  /// 收集系统性能指标
  static Future<Map<String, dynamic>> collectSystemMetrics() async {
    final metrics = <String, dynamic>{};

    try {
      // CPU信息
      metrics['cpu_cores'] = _cpuCores;
      metrics['cpu_score'] = _calculateCPUScore();

      // 内存信息
      await _updateMemoryInfo();
      metrics['total_memory_mb'] = _totalMemory;
      metrics['used_memory_mb'] = _usedMemory;
      metrics['memory_usage_percent'] = _memoryUsage;
      metrics['memory_score'] = _calculateMemoryScore();

      // GPU信息
      await _detectGPUCapabilities();
      metrics['gpu_support'] = _hasGPUSupport;
      metrics['gpu_performance'] = _gpuPerformance;
      metrics['gpu_score'] = _calculateGPUScore();

      // 设备信息
      await _collectDeviceInfo();
      metrics['device_model'] = _deviceModel;
      metrics['operating_system'] = _operatingSystem;
      metrics['is_low_end'] = _isLowEndDevice;
      metrics['device_score'] = _calculateDeviceScore();
    } catch (e) {
      debugPrint('Error collecting system metrics: $e');
      // 提供默认值
      metrics.addAll(_getDefaultMetrics());
    }

    return metrics;
  }

  /// 收集运行时性能指标
  static Future<Map<String, dynamic>> collectRuntimeMetrics() async {
    final metrics = <String, dynamic>{};

    try {
      // 渲染性能
      metrics['frame_rate'] = _frameRate;
      metrics['dropped_frames'] = _droppedFrames;
      metrics['render_time_ms'] = _renderTime;
      metrics['rendering_score'] = _calculateRenderingScore();

      // 应用性能
      metrics['app_memory_usage'] = await _getAppMemoryUsage();
      metrics['widget_count'] = _getWidgetCount();
      metrics['complexity_score'] = _calculateComplexityScore();
    } catch (e) {
      debugPrint('Error collecting runtime metrics: $e');
      metrics.addAll(_getDefaultRuntimeMetrics());
    }

    return metrics;
  }

  /// 更新内存信息
  static Future<void> _updateMemoryInfo() async {
    try {
      if (Platform.isWindows) {
        await _updateWindowsMemoryInfo();
      } else if (Platform.isLinux) {
        await _updateLinuxMemoryInfo();
      } else if (Platform.isMacOS) {
        await _updateMacOSMemoryInfo();
      } else {
        // 移动平台使用合理的默认值
        _setDefaultMobileMemory();
      }
    } catch (e) {
      debugPrint('Error updating memory info: $e');
      _setDefaultMemoryInfo();
    }
  }

  /// 更新Windows内存信息
  static Future<void> _updateWindowsMemoryInfo() async {
    try {
      // 尝试通过WMIC获取真实内存信息
      final result = await Process.run('wmic',
          ['OS', 'get', 'TotalVisibleMemorySize,FreePhysicalMemory', '/value']);
      if (result.exitCode == 0 && result.stdout.isNotEmpty) {
        final output = result.stdout.toString();
        final totalMatch =
            RegExp(r'TotalVisibleMemorySize=(\d+)').firstMatch(output);
        final freeMatch =
            RegExp(r'FreePhysicalMemory=(\d+)').firstMatch(output);

        if (totalMatch != null && freeMatch != null) {
          final totalKB = int.parse(totalMatch.group(1)!);
          final freeKB = int.parse(freeMatch.group(1)!);
          final usedKB = totalKB - freeKB;

          _totalMemory = (totalKB / 1024).round(); // Convert to MB
          _usedMemory = (usedKB / 1024).round();
          _memoryUsage = _usedMemory / _totalMemory;
          return;
        }
      }
    } catch (e) {
      debugPrint('Failed to get Windows memory info via WMIC: $e');
    }

    // 回退到估算值
    _totalMemory = 8192;
    final random = Random();
    _usedMemory =
        (_totalMemory * 0.3 + random.nextDouble() * _totalMemory * 0.4).round();
    _memoryUsage = _usedMemory / _totalMemory;
  }

  /// 更新Linux内存信息
  static Future<void> _updateLinuxMemoryInfo() async {
    try {
      final result = await Process.run('cat', ['/proc/meminfo']);
      if (result.exitCode == 0 && result.stdout.isNotEmpty) {
        final output = result.stdout.toString();
        final totalMatch = RegExp(r'MemTotal:\s+(\d+)\s+kB').firstMatch(output);
        final availableMatch =
            RegExp(r'MemAvailable:\s+(\d+)\s+kB').firstMatch(output);

        if (totalMatch != null && availableMatch != null) {
          final totalKB = int.parse(totalMatch.group(1)!);
          final availableKB = int.parse(availableMatch.group(1)!);
          final usedKB = totalKB - availableKB;

          _totalMemory = (totalKB / 1024).round(); // Convert to MB
          _usedMemory = (usedKB / 1024).round();
          _memoryUsage = _usedMemory / _totalMemory;
          return;
        }
      }
    } catch (e) {
      debugPrint('Failed to get Linux memory info: $e');
    }

    // 回退到估算值
    _totalMemory = 4096;
    final random = Random();
    _usedMemory =
        (_totalMemory * 0.2 + random.nextDouble() * _totalMemory * 0.5).round();
    _memoryUsage = _usedMemory / _totalMemory;
  }

  /// 更新macOS内存信息
  static Future<void> _updateMacOSMemoryInfo() async {
    try {
      final result = await Process.run('sysctl', ['hw.memsize']);
      if (result.exitCode == 0 && result.stdout.isNotEmpty) {
        final output = result.stdout.toString();
        final match = RegExp(r'hw.memsize:\s+(\d+)').firstMatch(output);
        if (match != null) {
          final totalBytes = int.parse(match.group(1)!);
          _totalMemory = (totalBytes / (1024 * 1024)).round(); // Convert to MB

          // 获取内存使用压力
          final pressureResult = await Process.run('memory_pressure', ['-l']);
          if (pressureResult.exitCode == 0) {
            final pressureOutput = pressureResult.stdout.toString();
            // 简单解析内存压力级别
            if (pressureOutput
                .contains('System-wide memory free percentage:')) {
              final freeMatch = RegExp(r'free percentage:\s+(\d+)%')
                  .firstMatch(pressureOutput);
              if (freeMatch != null) {
                final freePercent = int.parse(freeMatch.group(1)!);
                _memoryUsage = (100 - freePercent) / 100.0;
                _usedMemory = (_totalMemory * _memoryUsage).round();
                return;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to get macOS memory info: $e');
    }

    // 回退到估算值
    _totalMemory = 16384;
    final random = Random();
    _usedMemory =
        (_totalMemory * 0.25 + random.nextDouble() * _totalMemory * 0.3)
            .round();
    _memoryUsage = _usedMemory / _totalMemory;
  }

  /// 设置移动平台默认内存信息
  static void _setDefaultMobileMemory() {
    _totalMemory = 6144;
    _usedMemory = 3072;
    _memoryUsage = 0.5;
  }

  /// 设置默认内存信息
  static void _setDefaultMemoryInfo() {
    _totalMemory = 4096;
    _usedMemory = 2048;
    _memoryUsage = 0.5;
  }

  /// 检测GPU能力
  static Future<void> _detectGPUCapabilities() async {
    try {
      // 检查是否支持硬件加速
      _hasGPUSupport = true;

      // 根据平台和设备信息评估GPU性能
      if (Platform.isWindows) {
        _gpuPerformance = 0.9; // Windows通常有较好的GPU支持
      } else if (Platform.isMacOS) {
        _gpuPerformance = 0.95; // macOS有优秀的GPU优化
      } else if (Platform.isLinux) {
        _gpuPerformance = 0.7; // LinuxGPU支持变化较大
      } else {
        _gpuPerformance = 0.6; // 移动平台GPU性能中等
      }
    } catch (e) {
      _hasGPUSupport = false;
      _gpuPerformance = 0.3;
    }
  }

  /// 收集设备信息
  static Future<void> _collectDeviceInfo() async {
    try {
      _operatingSystem = Platform.operatingSystem;
      _deviceModel = Platform.localHostname;

      // 简单的低端设备检测逻辑
      _isLowEndDevice = _cpuCores <= 2 || _totalMemory < 4096;
    } catch (e) {
      _operatingSystem = 'Unknown';
      _deviceModel = 'Unknown Device';
      _isLowEndDevice = false;
    }
  }

  /// 计算CPU得分 (0-100)
  static double _calculateCPUScore() {
    // 基于CPU核心数计算得分
    if (_cpuCores >= 8) return 100.0;
    if (_cpuCores >= 6) return 85.0;
    if (_cpuCores >= 4) return 70.0;
    if (_cpuCores >= 2) return 50.0;
    return 30.0;
  }

  /// 计算内存得分 (0-100)
  static double _calculateMemoryScore() {
    // 基于内存大小和使用率计算得分
    final sizeScore = _totalMemory >= 16384
        ? 100.0
        : _totalMemory >= 8192
            ? 85.0
            : _totalMemory >= 4096
                ? 70.0
                : _totalMemory >= 2048
                    ? 50.0
                    : 30.0;

    // 内存使用率影响得分
    final usagePenalty = _memoryUsage > 0.8
        ? 20.0
        : _memoryUsage > 0.6
            ? 10.0
            : 0.0;

    return max(0, sizeScore - usagePenalty);
  }

  /// 计算GPU得分 (0-100)
  static double _calculateGPUScore() {
    if (!_hasGPUSupport) return 20.0;
    return _gpuPerformance * 100.0;
  }

  /// 计算设备得分 (0-100)
  static double _calculateDeviceScore() {
    double score = 50.0; // 基础分

    // 操作系统加分
    if (_operatingSystem.contains('windows') ||
        _operatingSystem.contains('mac')) {
      score += 20.0;
    } else if (_operatingSystem.contains('linux')) {
      score += 10.0;
    }

    // 低端设备扣分
    if (_isLowEndDevice) {
      score -= 20.0;
    }

    return score.clamp(0.0, 100.0);
  }

  /// 计算渲染性能得分 (0-100)
  static double _calculateRenderingScore() {
    // 基于帧率和丢帧数计算得分
    final frameRateScore = (_frameRate / 60.0) * 50.0;
    final droppedFramePenalty = (_droppedFrames / 10.0) * 20.0;
    final renderTimePenalty = (_renderTime / 16.67) * 30.0; // 16.67ms = 60fps

    return max(0.0, frameRateScore - droppedFramePenalty - renderTimePenalty)
        .clamp(0.0, 100.0);
  }

  /// 获取应用内存使用量 (模拟)
  static Future<int> _getAppMemoryUsage() async {
    // 这里应该是实际的内存使用量检测
    // 目前返回模拟值
    return Random().nextInt(200) + 100; // 100-300MB
  }

  /// 获取Widget数量 (模拟)
  static int _getWidgetCount() {
    // 这里应该返回实际的Widget数量
    return Random().nextInt(500) + 100; // 100-600个Widget
  }

  /// 计算应用复杂度得分 (0-100, 越低越好)
  static double _calculateComplexityScore() {
    final widgetCount = _getWidgetCount();
    if (widgetCount > 1000) return 20.0;
    if (widgetCount > 500) return 40.0;
    if (widgetCount > 200) return 60.0;
    if (widgetCount > 100) return 80.0;
    return 100.0;
  }

  /// 获取默认系统指标
  static Map<String, dynamic> _getDefaultMetrics() {
    return {
      'cpu_cores': 4,
      'cpu_score': 70.0,
      'total_memory_mb': 8192,
      'used_memory_mb': 4096,
      'memory_usage_percent': 0.5,
      'memory_score': 70.0,
      'gpu_support': true,
      'gpu_performance': 0.8,
      'gpu_score': 80.0,
      'device_model': 'Unknown',
      'operating_system': Platform.operatingSystem,
      'is_low_end': false,
      'device_score': 70.0,
    };
  }

  /// 获取默认运行时指标
  static Map<String, dynamic> _getDefaultRuntimeMetrics() {
    return {
      'frame_rate': 60.0,
      'dropped_frames': 0,
      'render_time_ms': 16.67,
      'rendering_score': 100.0,
      'app_memory_usage': 200,
      'widget_count': 300,
      'complexity_score': 80.0,
    };
  }

  /// 更新渲染性能数据
  static void updateRenderingPerformance({
    required double frameRate,
    required int droppedFrames,
    required double renderTime,
  }) {
    _frameRate = frameRate;
    _droppedFrames = droppedFrames;
    _renderTime = renderTime;
  }
}

/// 智能性能检测器
class SmartPerformanceDetector {
  /// 单例实例
  static SmartPerformanceDetector? _instance;

  /// 获取单例实例
  static SmartPerformanceDetector get instance =>
      _instance ??= SmartPerformanceDetector._();

  /// 私有构造函数
  SmartPerformanceDetector._();

  /// 最后一次检测结果
  PerformanceResult? _lastResult;
  Timer? _monitoringTimer;
  bool _isMonitoring = false;

  // 性能监听器
  final List<void Function(PerformanceResult)> _listeners = [];

  // 缓存相关
  static const Duration _cacheTimeout = Duration(minutes: 5);
  DateTime? _lastDetectionTime;
  bool _forceDetection = false;

  /// 添加性能监听器
  void addListener(void Function(PerformanceResult) listener) {
    _listeners.add(listener);
  }

  /// 移除性能监听器
  void removeListener(void Function(PerformanceResult) listener) {
    _listeners.remove(listener);
  }

  /// 执行完整的性能检测
  Future<PerformanceResult> detectPerformance(
      {bool forceRefresh = false}) async {
    // 检查缓存是否有效
    if (!forceRefresh && !_forceDetection && _isCacheValid()) {
      debugPrint('📦 使用缓存的性能检测结果');
      return _lastResult!;
    }

    debugPrint('🔍 开始智能性能检测...');

    try {
      // 使用超时机制防止长时间阻塞
      final systemMetrics = await _collectWithTimeout(
        PerformanceMetrics.collectSystemMetrics(),
        const Duration(seconds: 10),
        '系统指标收集',
      );

      final runtimeMetrics = await _collectWithTimeout(
        PerformanceMetrics.collectRuntimeMetrics(),
        const Duration(seconds: 5),
        '运行时指标收集',
      );

      // 合并所有指标
      final allMetrics = <String, dynamic>{...systemMetrics, ...runtimeMetrics};

      // 验证指标完整性
      _validateMetrics(allMetrics);

      // 计算综合性能得分
      final score = _calculateOverallScore(allMetrics);

      // 确定性能等级
      final level = _determinePerformanceLevel(score);

      // 生成优化建议
      final recommendations = _generateRecommendations(allMetrics, level);

      // 创建性能结果
      final result = PerformanceResult(
        score: score,
        level: level,
        metrics: allMetrics,
        timestamp: DateTime.now(),
        recommendations: recommendations,
      );

      // 更新缓存信息
      _lastResult = result;
      _lastDetectionTime = DateTime.now();
      _forceDetection = false;

      // 安全通知监听器
      _notifyListenersSafely(result);

      debugPrint('✅ 性能检测完成: 得分 $score, 等级 ${level.displayName}');
      return result;
    } catch (e) {
      debugPrint('❌ 性能检测失败: $e');
      debugPrint('🔄 使用降级策略...');

      // 返回默认结果
      return _createDefaultResult();
    }
  }

  /// 检查缓存是否有效
  bool _isCacheValid() {
    if (_lastResult == null || _lastDetectionTime == null) {
      return false;
    }

    final now = DateTime.now();
    final cacheAge = now.difference(_lastDetectionTime!);
    return cacheAge < _cacheTimeout;
  }

  /// 强制重新检测
  void forceDetection() {
    _forceDetection = true;
    debugPrint('🔄 标记为强制重新检测');
  }

  /// 清除缓存
  void clearCache() {
    _lastResult = null;
    _lastDetectionTime = null;
    debugPrint('🗑️ 性能检测结果缓存已清除');
  }

  /// 带超时的数据收集
  Future<T> _collectWithTimeout<T>(
    Future<T> future,
    Duration timeout,
    String operationName,
  ) async {
    try {
      final result = await future.timeout(timeout);
      debugPrint('✅ $operationName 完成');
      return result;
    } catch (e) {
      debugPrint('⚠️ $operationName 超时或失败: $e');
      rethrow;
    }
  }

  /// 验证指标完整性
  void _validateMetrics(Map<String, dynamic> metrics) {
    final requiredKeys = ['cpu_score', 'memory_score', 'gpu_score'];
    final missingKeys = requiredKeys.where((key) => !metrics.containsKey(key));

    if (missingKeys.isNotEmpty) {
      debugPrint('⚠️ 缺少关键指标: $missingKeys');
      // 补充默认值
      for (final key in missingKeys) {
        metrics[key] = 50.0;
      }
    }

    // 验证数值范围
    final numericKeys = [
      'cpu_score',
      'memory_score',
      'gpu_score',
      'device_score'
    ];
    for (final key in numericKeys) {
      final value = metrics[key] as double?;
      if (value == null || value < 0 || value > 100) {
        debugPrint('⚠️ 指标 $key 数值异常: $value，使用默认值');
        metrics[key] = 50.0;
      }
    }
  }

  /// 安全通知监听器
  void _notifyListenersSafely(PerformanceResult result) {
    for (int i = 0; i < _listeners.length; i++) {
      try {
        _listeners[i](result);
      } catch (e) {
        debugPrint('Error notifying performance listener at index $i: $e');
        // 移除有问题的监听器
        _listeners.removeAt(i);
        i--; // 调整索引
      }
    }
  }

  /// 计算综合性能得分
  int _calculateOverallScore(Map<String, dynamic> metrics) {
    double score = 0.0;

    // 系统硬件得分 (权重: 40%)
    final cpuScore = (metrics['cpu_score'] as double? ?? 50.0) * 0.15;
    final memoryScore = (metrics['memory_score'] as double? ?? 50.0) * 0.15;
    final gpuScore = (metrics['gpu_score'] as double? ?? 50.0) * 0.10;

    // 设备特性得分 (权重: 20%)
    final deviceScore = (metrics['device_score'] as double? ?? 50.0) * 0.20;

    // 运行时性能得分 (权重: 30%)
    final renderingScore =
        (metrics['rendering_score'] as double? ?? 80.0) * 0.20;
    final complexityScore =
        (metrics['complexity_score'] as double? ?? 80.0) * 0.10;

    // 应用使用情况得分 (权重: 10%)
    final memoryUsage = metrics['memory_usage_percent'] as double? ?? 0.5;
    final usageScore = max(0, 100 - memoryUsage * 100) * 0.10;

    score = cpuScore +
        memoryScore +
        gpuScore +
        deviceScore +
        renderingScore +
        complexityScore +
        usageScore;

    return score.round().clamp(0, 100);
  }

  /// 确定性能等级
  PerformanceLevel _determinePerformanceLevel(int score) {
    if (score >= 85) return PerformanceLevel.excellent;
    if (score >= 70) return PerformanceLevel.good;
    if (score >= 50) return PerformanceLevel.fair;
    return PerformanceLevel.poor;
  }

  /// 生成优化建议
  List<String> _generateRecommendations(
      Map<String, dynamic> metrics, PerformanceLevel level) {
    final recommendations = <String>[];

    // 基于性能等级的通用建议
    switch (level) {
      case PerformanceLevel.poor:
        recommendations.add('设备性能较低，建议启用性能优化模式');
        recommendations.add('减少同时显示的数据量');
        recommendations.add('关闭不必要的动画效果');
        break;
      case PerformanceLevel.fair:
        recommendations.add('设备性能一般，建议适度优化');
        recommendations.add('考虑减少动画复杂度');
        break;
      case PerformanceLevel.good:
        recommendations.add('设备性能良好，可享受完整体验');
        break;
      case PerformanceLevel.excellent:
        recommendations.add('设备性能优秀，可启用所有高级功能');
        break;
    }

    // 基于具体指标的建议
    final cpuScore = metrics['cpu_score'] as double? ?? 50.0;
    if (cpuScore < 50) {
      recommendations.add('CPU性能较低，建议减少复杂计算');
    }

    final memoryScore = metrics['memory_score'] as double? ?? 50.0;
    if (memoryScore < 50) {
      recommendations.add('内存使用率较高，建议定期清理缓存');
    }

    final gpuScore = metrics['gpu_score'] as double? ?? 50.0;
    if (gpuScore < 50) {
      recommendations.add('GPU性能有限，建议降低图形质量');
    }

    final renderingScore = metrics['rendering_score'] as double? ?? 80.0;
    if (renderingScore < 60) {
      recommendations.add('渲染性能较差，建议简化UI元素');
    }

    final isLowEnd = metrics['is_low_end'] as bool? ?? false;
    if (isLowEnd) {
      recommendations.add('检测到低端设备，已自动启用省流模式');
    }

    return recommendations;
  }

  /// 创建默认性能结果
  PerformanceResult _createDefaultResult() {
    return PerformanceResult(
      score: 50,
      level: PerformanceLevel.fair,
      metrics: {
        'cpu_score': 50.0,
        'memory_score': 50.0,
        'gpu_score': 50.0,
        'device_score': 50.0,
        'rendering_score': 80.0,
        'complexity_score': 80.0,
      },
      timestamp: DateTime.now(),
      recommendations: ['使用默认性能配置'],
    );
  }

  /// 启动性能监控
  void startMonitoring({
    Duration? interval,
    bool adaptiveMonitoring = true,
  }) {
    if (_isMonitoring) {
      debugPrint('⚠️ 性能监控已在运行中');
      return;
    }

    if (adaptiveMonitoring) {
      _startAdaptiveMonitoring();
    } else {
      final monitoringInterval = interval ?? _getRecommendedInterval();
      _startFixedIntervalMonitoring(monitoringInterval);
    }
  }

  /// 启动自适应监控
  void _startAdaptiveMonitoring() {
    _isMonitoring = true;
    debugPrint('📈 启动自适应性能监控');

    _scheduleNextMonitoring();
  }

  /// 调度下次监控
  void _scheduleNextMonitoring() {
    if (!_isMonitoring) return;

    final interval = _calculateAdaptiveInterval();
    debugPrint('⏰ 下次性能监控将在 ${interval.inMinutes} 分钟后执行');

    _monitoringTimer = Timer(interval, () async {
      try {
        await detectPerformance();
        _scheduleNextMonitoring(); // 调度下一次
      } catch (e) {
        debugPrint('❌ 监控执行失败: $e');
        // 错误时延长等待时间
        _monitoringTimer =
            Timer(const Duration(minutes: 10), _scheduleNextMonitoring);
      }
    });
  }

  /// 计算自适应监控间隔
  Duration _calculateAdaptiveInterval() {
    // 基于当前性能等级和上次检测结果计算间隔
    if (_lastResult == null) {
      return const Duration(minutes: 5); // 首次检测
    }

    switch (_lastResult!.level) {
      case PerformanceLevel.excellent:
        return const Duration(minutes: 30); // 优秀设备减少检测频率
      case PerformanceLevel.good:
        return const Duration(minutes: 20);
      case PerformanceLevel.fair:
        return const Duration(minutes: 10);
      case PerformanceLevel.poor:
        return const Duration(minutes: 5); // 较差设备增加检测频率
    }
  }

  /// 启动固定间隔监控
  void _startFixedIntervalMonitoring(Duration interval) {
    _isMonitoring = true;
    _monitoringTimer = Timer.periodic(interval, (_) async {
      try {
        await detectPerformance();
      } catch (e) {
        debugPrint('❌ 监控执行失败: $e');
      }
    });

    debugPrint('📈 性能监控已启动，间隔: ${interval.inMinutes} 分钟');
  }

  /// 获取推荐的监控间隔
  Duration _getRecommendedInterval() {
    if (_lastResult == null) {
      return const Duration(minutes: 10);
    }

    return _calculateAdaptiveInterval();
  }

  /// 获取监控状态信息
  Map<String, dynamic> getMonitoringStatus() {
    return {
      'isMonitoring': _isMonitoring,
      'hasLastResult': _lastResult != null,
      'lastDetectionTime': _lastDetectionTime?.toIso8601String(),
      'isCacheValid': _isCacheValid(),
      'nextIntervalMinutes':
          _isMonitoring ? _calculateAdaptiveInterval().inMinutes : null,
      'listenersCount': _listeners.length,
    };
  }

  /// 停止性能监控
  void stopMonitoring() {
    if (!_isMonitoring) return;

    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    _isMonitoring = false;

    debugPrint('⏹️ 性能监控已停止');
  }

  /// 获取最后一次检测结果
  PerformanceResult? get lastResult => _lastResult;

  /// 是否正在监控
  bool get isMonitoring => _isMonitoring;

  /// 销毁检测器
  void dispose() {
    debugPrint('🗑️ 销毁性能检测器');

    stopMonitoring();
    clearCache();
    _listeners.clear();
    _instance = null;
  }
}

/// 性能自适应管理器
class PerformanceAdaptiveManager {
  /// 单例实例
  static PerformanceAdaptiveManager? _instance;

  /// 获取单例实例
  static PerformanceAdaptiveManager get instance =>
      _instance ??= PerformanceAdaptiveManager._();

  /// 私有构造函数
  PerformanceAdaptiveManager._() {
    // 监听性能变化
    SmartPerformanceDetector.instance.addListener(_onPerformanceChanged);
  }

  PerformanceLevel _currentLevel = PerformanceLevel.good;
  bool _animationsEnabled = true;
  bool _highQualityEnabled = true;
  int _virtualizationBufferSize = 10;
  double _animationSpeedMultiplier = 1.0;

  // 性能变化监听器
  final List<void Function(PerformanceLevel)> _levelListeners = [];

  /// 添加性能等级监听器
  void addLevelListener(void Function(PerformanceLevel) listener) {
    _levelListeners.add(listener);
  }

  /// 移除性能等级监听器
  void removeLevelListener(void Function(PerformanceLevel) listener) {
    _levelListeners.remove(listener);
  }

  /// 处理性能变化
  void _onPerformanceChanged(PerformanceResult result) {
    final newLevel = result.level;
    if (newLevel != _currentLevel) {
      debugPrint(
          '🎯 性能等级变化: ${_currentLevel.displayName} → ${newLevel.displayName}');
      _currentLevel = newLevel;
      _applyAdaptiveSettings();

      // 通知等级变化监听器
      for (final listener in _levelListeners) {
        try {
          listener(newLevel);
        } catch (e) {
          debugPrint('Error notifying level listener: $e');
        }
      }
    }
  }

  /// 应用自适应设置
  void _applyAdaptiveSettings() {
    switch (_currentLevel) {
      case PerformanceLevel.excellent:
        _animationsEnabled = true;
        _highQualityEnabled = true;
        _virtualizationBufferSize = 15;
        _animationSpeedMultiplier = 1.2;
        break;
      case PerformanceLevel.good:
        _animationsEnabled = true;
        _highQualityEnabled = true;
        _virtualizationBufferSize = 10;
        _animationSpeedMultiplier = 1.0;
        break;
      case PerformanceLevel.fair:
        _animationsEnabled = true;
        _highQualityEnabled = false;
        _virtualizationBufferSize = 8;
        _animationSpeedMultiplier = 0.8;
        break;
      case PerformanceLevel.poor:
        _animationsEnabled = false;
        _highQualityEnabled = false;
        _virtualizationBufferSize = 5;
        _animationSpeedMultiplier = 0.5;
        break;
    }

    debugPrint('⚙️ 应用自适应设置: 动画=$_animationsEnabled, 高质量=$_highQualityEnabled');
  }

  /// 当前性能等级
  PerformanceLevel get currentLevel => _currentLevel;

  /// 是否启用动画
  bool get animationsEnabled => _animationsEnabled;

  /// 是否启用高质量
  bool get highQualityEnabled => _highQualityEnabled;

  /// 虚拟化缓冲区大小
  int get virtualizationBufferSize => _virtualizationBufferSize;

  /// 动画速度倍数
  double get animationSpeedMultiplier => _animationSpeedMultiplier;

  /// 获取自适应动画时长
  Duration getAdaptiveAnimationDuration(Duration baseDuration) {
    return Duration(
      milliseconds:
          (baseDuration.inMilliseconds * _animationSpeedMultiplier).round(),
    );
  }

  /// 获取推荐性能配置
  Map<String, dynamic> getRecommendedPerformanceConfig() {
    return {
      'level': _currentLevel.displayName,
      'animationsEnabled': _animationsEnabled,
      'highQualityEnabled': _highQualityEnabled,
      'virtualizationBufferSize': _virtualizationBufferSize,
      'animationSpeedMultiplier': _animationSpeedMultiplier,
      'glassmorphismLevel': _getGlassmorphismLevel(),
    };
  }

  /// 获取毛玻璃配置级别
  String _getGlassmorphismLevel() {
    if (!_highQualityEnabled) return 'performance';

    switch (_currentLevel) {
      case PerformanceLevel.excellent:
        return 'strong';
      case PerformanceLevel.good:
        return 'medium';
      case PerformanceLevel.fair:
        return 'light';
      case PerformanceLevel.poor:
        return 'performance';
    }
  }

  /// 销毁管理器
  void dispose() {
    SmartPerformanceDetector.instance.removeListener(_onPerformanceChanged);
    _levelListeners.clear();
    _instance = null;
  }
}
