part of 'cache_bloc.dart';

/// 缓存事件基类
abstract class CacheEvent extends Equatable {
  const CacheEvent();

  @override
  List<Object?> get props => [];
}

/// 初始化缓存事件
class InitializeCache extends CacheEvent {
  const InitializeCache();

  @override
  String toString() => 'InitializeCache';
}

/// 存储缓存数据事件
class StoreCacheData<T> extends CacheEvent {
  /// 缓存键
  final String key;

  /// 缓存值
  final T value;

  /// 过期时间
  final Duration? expiration;

  const StoreCacheData({
    required this.key,
    required this.value,
    this.expiration,
  });

  @override
  List<Object?> get props => [key, value, expiration];

  @override
  String toString() => 'StoreCacheData{key: $key, expiration: $expiration}';
}

/// 获取缓存数据事件
class GetCacheData<T> extends CacheEvent {
  /// 缓存键
  final String key;

  /// 数据类型
  final Type type;

  const GetCacheData({
    required this.key,
    required this.type,
  });

  @override
  List<Object?> get props => [key, type];

  @override
  String toString() => 'GetCacheData{key: $key, type: $type}';
}

/// 移除缓存数据事件
class RemoveCacheData extends CacheEvent {
  /// 缓存键
  final String key;

  const RemoveCacheData(this.key);

  @override
  List<Object?> get props => [key];

  @override
  String toString() => 'RemoveCacheData{key: $key}';
}

/// 清空所有缓存事件
class ClearAllCache extends CacheEvent {
  const ClearAllCache();

  @override
  String toString() => 'ClearAllCache';
}

/// 清理过期缓存事件
class ClearExpiredCache extends CacheEvent {
  const ClearExpiredCache();

  @override
  String toString() => 'ClearExpiredCache';
}

/// 获取缓存统计信息事件
class GetCacheStatistics extends CacheEvent {
  const GetCacheStatistics();

  @override
  String toString() => 'GetCacheStatistics';
}

/// 监控缓存使用情况事件
class MonitorCacheUsage extends CacheEvent {
  const MonitorCacheUsage();

  @override
  String toString() => 'MonitorCacheUsage';
}

/// 设置缓存策略事件
class SetCachePolicy extends CacheEvent {
  /// 缓存策略
  final CachePolicy policy;

  const SetCachePolicy(this.policy);

  @override
  List<Object?> get props => [policy];

  @override
  String toString() => 'SetCachePolicy{policy: $policy}';
}

/// 批量存储缓存数据事件
class BatchStoreCacheData extends CacheEvent {
  /// 缓存数据映射
  final Map<String, dynamic> data;

  /// 默认过期时间
  final Duration? defaultExpiration;

  const BatchStoreCacheData({
    required this.data,
    this.defaultExpiration,
  });

  @override
  List<Object?> get props => [data, defaultExpiration];

  @override
  String toString() => 'BatchStoreCacheData{itemCount: ${data.length}}';
}

/// 预热缓存事件
class WarmupCache extends CacheEvent {
  /// 预热数据键列表
  final List<String> keys;

  const WarmupCache(this.keys);

  @override
  List<Object?> get props => [keys];

  @override
  String toString() => 'WarmupCache{keyCount: ${keys.length}}';
}

/// 缓存压缩事件
class CompressCache extends CacheEvent {
  const CompressCache();

  @override
  String toString() => 'CompressCache';
}

/// 缓存备份事件
class BackupCache extends CacheEvent {
  /// 备份路径
  final String? backupPath;

  const BackupCache({this.backupPath});

  @override
  List<Object?> get props => [backupPath];

  @override
  String toString() => 'BackupCache{backupPath: $backupPath}';
}

/// 缓存恢复事件
class RestoreCache extends CacheEvent {
  /// 备份路径
  final String backupPath;

  const RestoreCache(this.backupPath);

  @override
  List<Object?> get props => [backupPath];

  @override
  String toString() => 'RestoreCache{backupPath: $backupPath}';
}
