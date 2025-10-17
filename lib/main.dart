import 'package:flutter/material.dart';
import 'src/core/di/injection_container.dart';
import 'src/core/di/hive_injection_container.dart';
import 'src/features/app/app.dart';
import 'src/core/utils/logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppLogger.debug('应用启动中...');

  try {
    // 初始化Hive缓存依赖注入
    await HiveInjectionContainer.init();
    AppLogger.debug('Hive缓存初始化完成');

    // 初始化依赖注入
    await initDependencies();
    AppLogger.debug('依赖注入初始化完成');

    runApp(const JisuFundAnalyzerApp());
    AppLogger.debug('应用启动成功');
  } catch (e, stack) {
    AppLogger.debug('应用启动失败: $e');
    AppLogger.debug('堆栈: $stack');
    rethrow;
  }
}

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
        HiveInjectionContainer.clearExpiredCache();
        break;
      case AppLifecycleState.detached:
        // 应用被关闭，清理资源
        HiveInjectionContainer.dispose();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
