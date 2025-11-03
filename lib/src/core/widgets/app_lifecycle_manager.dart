import 'package:flutter/material.dart';
import '../../core/cache/unified_hive_cache_manager.dart';
import '../../core/utils/logger.dart';

/// 应用生命周期管理
class AppLifecycleManager extends StatefulWidget {
  final Widget child;

  const AppLifecycleManager({super.key, required this.child});

  @override
  State<AppLifecycleManager> createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends State<AppLifecycleManager>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        // 应用进入后台，清理过期缓存
        // 通过GetIt获取缓存管理器清理过期缓存
        _clearCacheInBackground();
        break;
      case AppLifecycleState.detached:
        // 应用被关闭，清理资源
        // 应用退出时Hive会自动清理
        break;
      default:
        break;
    }
  }

  /// 在后台清理缓存
  void _clearCacheInBackground() async {
    try {
      final cacheManager = UnifiedHiveCacheManager.instance;
      await cacheManager.clearExpiredCache();
    } catch (e) {
      AppLogger.debug('清理缓存时出错: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
