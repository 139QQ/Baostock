/// 缓存相关的数据模型和枚举
library;

/// 缓存条目
class CacheEntry {
  final dynamic data;
  DateTime createdAt;
  final DateTime? expiresAt;
  final int accessCount;
  final String dataType; // 'fund', 'ranking', 'search'等

  CacheEntry({
    required this.data,
    required this.dataType,
    DateTime? expiresAt,
    this.accessCount = 0,
    DateTime? createdAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        expiresAt = expiresAt ?? DateTime.now().add(const Duration(hours: 1));

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  Duration get age => DateTime.now().difference(createdAt);
}

/// 预加载类型
enum PreloadType {
  critical, // 关键数据 - 立即加载
  important, // 重要数据 - 优先加载
  normal, // 普通数据 - 正常加载
  background, // 背景数据 - 空闲时加载
}

/// 预加载任务
class PreloadTask implements Comparable<PreloadTask> {
  final String id;
  final PreloadType type;
  final int priority;
  final Map<String, dynamic> params;
  final Function() task;
  final DateTime createdAt;

  PreloadTask({
    required this.id,
    required this.type,
    required this.priority,
    required this.params,
    required this.task,
  }) : createdAt = DateTime.now();

  @override
  int compareTo(PreloadTask other) {
    // 优先级高的先执行，优先级相同时创建时间早的先执行
    int priorityComparison = other.priority.compareTo(priority);
    if (priorityComparison != 0) return priorityComparison;
    return createdAt.compareTo(other.createdAt);
  }
}

/// 分页状态
class PaginationState {
  int currentPage;
  final int pageSize;
  bool hasMore;
  bool isLoading;
  final List<String> loadedItems;

  PaginationState({
    this.currentPage = 0,
    this.pageSize = 20,
    this.hasMore = true,
    this.isLoading = false,
    this.loadedItems = const [],
  });

  int get nextPage => currentPage + 1;
}
