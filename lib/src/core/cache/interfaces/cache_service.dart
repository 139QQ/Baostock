/// 统一缓存服务接口
///
/// 定义了项目中所有缓存操作的标准接口，确保缓存实现的统一性和可替换性
/// 所有缓存管理器都应该实现此接口或通过适配器实现此接口
abstract class CacheService {
  /// 获取缓存值
  ///
  /// [key] 缓存键
  /// 返回缓存值，如果不存在则返回null
  Future<T?> get<T>(String key);

  /// 设置缓存值
  ///
  /// [key] 缓存键
  /// [value] 缓存值
  /// [expiration] 过期时间，可选
  Future<void> put<T>(String key, T value, {Duration? expiration});

  /// 删除缓存值
  ///
  /// [key] 缓存键
  Future<void> remove(String key);

  /// 清空所有缓存
  Future<void> clear();

  /// 检查缓存键是否存在
  ///
  /// [key] 缓存键
  /// 返回true如果键存在，否则返回false
  Future<bool> containsKey(String key);

  /// 获取所有缓存键
  ///
  /// 返回所有缓存键的列表
  Future<List<String>> getAllKeys();

  /// 获取缓存统计信息
  ///
  /// 返回包含缓存统计信息的Map
  Future<Map<String, dynamic>> getStats();

  /// 批量获取缓存值
  ///
  /// [keys] 缓存键列表
  /// 返回键值对Map，不存在的键对应的值为null
  Future<Map<String, dynamic?>> getAll(List<String> keys);

  /// 批量设置缓存值
  ///
  /// [keyValuePairs] 键值对Map
  /// [expiration] 过期时间，可选
  Future<void> putAll(Map<String, dynamic> keyValuePairs,
      {Duration? expiration});

  /// 批量删除缓存值
  ///
  /// [keys] 缓存键列表
  Future<void> removeAll(List<String> keys);

  /// 设置缓存过期时间
  ///
  /// [key] 缓存键
  /// [expiration] 过期时间
  Future<void> setExpiration(String key, Duration expiration);

  /// 获取缓存剩余过期时间
  ///
  /// [key] 缓存键
  /// 返回剩余过期时间，如果键不存在或永不过期则返回null
  Future<Duration?> getExpiration(String key);
}

/// 缓存服务异常
class CacheServiceException implements Exception {
  final String message;
  final String? key;
  final dynamic originalError;

  const CacheServiceException(
    this.message, {
    this.key,
    this.originalError,
  });

  @override
  String toString() {
    final buffer = StringBuffer('CacheServiceException: $message');
    if (key != null) {
      buffer.write(', key: $key');
    }
    if (originalError != null) {
      buffer.write(', originalError: $originalError');
    }
    return buffer.toString();
  }
}
