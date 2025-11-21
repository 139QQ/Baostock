import '../../../../../core/performance/performance_detector.dart';

/// 性能检测器适配器
///
/// 为基金卡片组件提供简化的性能检测接口
class PerformanceDetector {
  /// 创建性能检测器适配器实例
  PerformanceDetector() : _detector = SmartPerformanceDetector.instance;

  late final SmartPerformanceDetector _detector;
  PerformanceLevel? _cachedLevel;

  /// 获取性能级别
  PerformanceLevel getPerformanceLevel() {
    if (_cachedLevel != null) {
      return _cachedLevel!;
    }

    // 使用简单的检测逻辑
    _cachedLevel = _detectPerformanceLevel();
    return _cachedLevel!;
  }

  /// 检测性能级别（简化版）
  PerformanceLevel _detectPerformanceLevel() {
    try {
      // 尝试使用SmartPerformanceDetector的结果
      final result = _detector.lastResult;
      if (result != null) {
        return result.level;
      }
    } catch (e) {
      // 如果检测失败，使用默认值
    }

    // 默认返回良好性能
    return PerformanceLevel.good;
  }

  /// 启动性能监控
  void startMonitoring() {
    // 可以在这里启动性能监控
  }

  /// 停止性能监控
  void stopMonitoring() {
    // 可以在这里停止性能监控
  }

  /// 销毁实例
  void dispose() {
    _cachedLevel = null;
  }

  /// 获取实例
  static PerformanceDetector get instance => PerformanceDetector();
}

/// 扩展PerformanceLevel以支持我们的组件
extension PerformanceLevelMapping on PerformanceLevel {
  /// 映射到我们的简化级别
  PerformanceLevelSimple toSimple() {
    switch (this) {
      case PerformanceLevel.excellent:
        return PerformanceLevelSimple.high;
      case PerformanceLevel.good:
        return PerformanceLevelSimple.medium;
      case PerformanceLevel.fair:
        return PerformanceLevelSimple.medium;
      case PerformanceLevel.poor:
        return PerformanceLevelSimple.low;
    }
  }
}

/// 简化的性能级别
enum PerformanceLevelSimple {
  /// 低性能设备 - 禁用复杂动画，启用基础功能
  low,

  /// 中等性能设备 - 启用基础动画，正常功能
  medium,

  /// 高性能设备 - 启用完整动画和所有高级功能
  high,
}