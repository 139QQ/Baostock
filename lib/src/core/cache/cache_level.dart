/// 缓存级别枚举
enum CacheLevel {
  /// L1 内存缓存
  L1,

  /// L2 Hive缓存
  L2,

  /// L3 网络缓存
  L3,

  /// 全部层级
  ALL;
}

/// 缓存操作结果
class CacheResult<T> {
  final T? data;
  final CacheLevel hitLevel;
  final bool success;
  final String? error;
  final Duration? latency;

  CacheResult({
    this.data,
    required this.hitLevel,
    required this.success,
    this.error,
    this.latency,
  });

  factory CacheResult.success(T data, CacheLevel level, Duration latency) {
    return CacheResult(
      data: data,
      hitLevel: level,
      success: true,
      latency: latency,
    );
  }

  factory CacheResult.failure(String error,
      {CacheLevel level = CacheLevel.L1}) {
    return CacheResult(
      hitLevel: level,
      success: false,
      error: error,
    );
  }

  bool get isHit => success && data != null;
}
