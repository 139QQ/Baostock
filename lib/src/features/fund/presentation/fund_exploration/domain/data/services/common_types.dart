/// 队列实现
class Queue<T> {
  final List<T> _items = [];

  void add(T item) => _items.add(item);

  T? removeFirst() {
    if (_items.isEmpty) return null;
    return _items.removeAt(0);
  }

  void clear() => _items.clear();

  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;
  int get length => _items.length;
}

/// 同步状态枚举
enum SyncStatus {
  idle, // 空闲
  syncing, // 同步中
  failed, // 失败
  paused, // 暂停
}

/// 同步状态
class SyncState {
  final String dataType;
  SyncStatus status;
  DateTime lastSyncTime;
  DateTime? nextSyncTime;
  int failedAttempts;
  String? lastError;

  SyncState({
    required this.dataType,
    this.status = SyncStatus.idle,
    DateTime? lastSyncTime,
    this.nextSyncTime,
    this.failedAttempts = 0,
    this.lastError,
  }) : lastSyncTime = lastSyncTime ?? DateTime.now();

  bool get canSync => status == SyncStatus.idle;
  bool get hasError => failedAttempts > 0;
  Duration get timeSinceLastSync => DateTime.now().difference(lastSyncTime);
}

/// 数据版本信息
class DataVersion {
  final String dataType;
  final String version;
  final DateTime timestamp;
  final String checksum;

  DataVersion({
    required this.dataType,
    required this.version,
    required this.timestamp,
    required this.checksum,
  });

  Map<String, dynamic> toJson() => {
        'dataType': dataType,
        'version': version,
        'timestamp': timestamp.toIso8601String(),
        'checksum': checksum,
      };

  factory DataVersion.fromJson(Map<String, dynamic> json) {
    return DataVersion(
      dataType: json['dataType'],
      version: json['version'],
      timestamp: DateTime.parse(json['timestamp']),
      checksum: json['checksum'],
    );
  }
}

/// 冲突解决策略
enum ConflictResolutionStrategy {
  timestamp, // 基于时间戳
  server, // 服务器优先
  client, // 客户端优先
  merge, // 合并策略
}
