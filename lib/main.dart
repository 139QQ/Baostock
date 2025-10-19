import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'src/core/di/injection_container.dart';
import 'src/core/di/hive_injection_container.dart';
import 'src/features/app/app.dart';
import 'src/core/utils/logger.dart';
import 'src/core/state/global_cubit_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppLogger.debug('应用启动中...');

  try {
    // 检测平台并初始化Hive缓存依赖注入
    if (kIsWeb) {
      AppLogger.debug('Web平台检测，跳过Hive初始化');
      // Web平台使用内存缓存，跳过Hive
    } else {
      AppLogger.debug('桌面平台，尝试初始化Hive缓存');
      await HiveInjectionContainer.init().catchError((e) {
        AppLogger.debug('Hive缓存初始化失败，使用内存缓存: $e');
        // 失败时继续运行，使用内存缓存
      });
    }

    // 初始化依赖注入
    await initDependencies();
    AppLogger.debug('依赖注入初始化完成');

    // 初始化全局Cubit管理器，确保状态持久化
    AppLogger.debug('初始化全局Cubit管理器');
    final globalManager = GlobalCubitManager.instance;
    AppLogger.debug(
        '全局Cubit管理器初始化完成: ${globalManager.getFundRankingStatusInfo()}');

    runApp(const JisuFundAnalyzerApp());
    AppLogger.debug('应用启动成功');
  } catch (e, stack) {
    AppLogger.debug('应用启动失败: $e');
    AppLogger.debug('堆栈: $stack');

    // 优雅降级：启动简化版应用
    AppLogger.debug('启动简化版应用');
    runApp(const FallbackApp());
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

/// 降级应用
/// 当主应用启动失败时使用的简化版应用
class FallbackApp extends StatelessWidget {
  const FallbackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '基金分析器',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E40AF)),
        useMaterial3: true,
      ),
      home: const FallbackPage(),
    );
  }
}

class FallbackPage extends StatelessWidget {
  const FallbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('基金分析器'),
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.orange),
            SizedBox(height: 16),
            Text(
              '缓存系统初始化失败',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('正在使用简化模式运行'),
            SizedBox(height: 32),
            Text('核心功能正常可用'),
          ],
        ),
      ),
    );
  }
}
