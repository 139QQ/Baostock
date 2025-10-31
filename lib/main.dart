import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';
import 'src/core/di/injection_container.dart';
import 'src/features/app/app.dart';
import 'src/core/utils/logger.dart';
import 'src/core/state/global_cubit_manager.dart';
import 'src/core/cache/unified_hive_cache_manager.dart';
import 'src/models/fund_info.dart';
import 'src/features/portfolio/data/adapters/fund_favorite_adapter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppLogger.debug('应用启动中...');

  try {
    // 检测平台并初始化Hive缓存依赖注入（增强错误处理）
    if (kIsWeb) {
      AppLogger.debug('Web平台检测，跳过Hive初始化');
      // Web平台使用内存缓存，跳过Hive
    } else {
      AppLogger.debug('桌面平台，尝试初始化Hive缓存');
      try {
        // 首先初始化Hive
        await Hive.initFlutter();

        // 注册Hive适配器（关键修复）
        if (!Hive.isAdapterRegistered(20)) {
          Hive.registerAdapter(FundInfoAdapter());
          AppLogger.debug('FundInfo适配器注册成功');
        }

        // 注册自选基金适配器
        if (!Hive.isAdapterRegistered(10)) {
          Hive.registerAdapter(FundFavoriteAdapter());
          AppLogger.debug('FundFavorite适配器注册成功');
        }
        if (!Hive.isAdapterRegistered(11)) {
          Hive.registerAdapter(PriceAlertSettingsAdapter());
          AppLogger.debug('PriceAlertSettings适配器注册成功');
        }
        if (!Hive.isAdapterRegistered(12)) {
          Hive.registerAdapter(TargetPriceAlertAdapter());
          AppLogger.debug('TargetPriceAlert适配器注册成功');
        }
        // 先注册基础适配器（被其他适配器依赖的）
        if (!Hive.isAdapterRegistered(14)) {
          Hive.registerAdapter(SortConfigurationAdapter());
          AppLogger.debug('SortConfiguration适配器注册成功');
        }
        if (!Hive.isAdapterRegistered(15)) {
          Hive.registerAdapter(FilterConfigurationAdapter());
          AppLogger.debug('FilterConfiguration适配器注册成功');
        }
        if (!Hive.isAdapterRegistered(17)) {
          Hive.registerAdapter(SyncConfigurationAdapter());
          AppLogger.debug('SyncConfiguration适配器注册成功');
        }
        if (!Hive.isAdapterRegistered(18)) {
          Hive.registerAdapter(ListStatisticsAdapter());
          AppLogger.debug('ListStatistics适配器注册成功');
        }
        // 再注册依赖其他适配器的适配器
        if (!Hive.isAdapterRegistered(13)) {
          Hive.registerAdapter(FundFavoriteListAdapter());
          AppLogger.debug('FundFavoriteList适配器注册成功');
        }

        // 特殊处理：注册一个兼容性适配器来处理旧版本的typeId 230
        // 暂时注释掉，测试其他适配器是否正常
        // if (!Hive.isAdapterRegistered(230)) {
        //   Hive.registerAdapter(LegacyType230Adapter());
        //   AppLogger.debug('LegacyType230兼容性适配器注册成功');
        // }

        // Hive缓存适配器注册已完成，将在initDependencies中初始化缓存管理器
        AppLogger.debug('Hive适配器注册完成');
      } catch (e, stack) {
        AppLogger.debug('Hive缓存初始化失败，使用内存缓存: $e');
        AppLogger.debug('Hive错误堆栈: $stack');
        // 失败时继续运行，使用内存缓存
        // 不重新抛出异常，确保应用能正常启动
      }
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

/// 兼容性适配器：处理旧版本的typeId 230对象
/// 这个适配器用于读取损坏或过期的缓存数据，避免应用崩溃
class LegacyType230Adapter extends TypeAdapter<dynamic> {
  @override
  final int typeId = 230;

  @override
  dynamic read(BinaryReader reader) {
    // 尝试读取旧数据，但不实际使用它
    // 只是为了避免Hive错误而跳过这个对象
    try {
      final numberOfFields = reader.readByte();
      final fields = <int, dynamic>{};
      for (int i = 0; i < numberOfFields; i++) {
        fields[i] = reader.read();
      }
      AppLogger.debug('跳过过期的typeId 230对象，字段数: $numberOfFields');
      return null; // 返回null，表示数据已过期
    } catch (e) {
      AppLogger.warn('读取typeId 230对象时出错: $e');
      return null;
    }
  }

  @override
  void write(BinaryWriter writer, dynamic obj) {
    // 不支持写入新数据，这个适配器只用于读取旧数据
    throw UnsupportedError('LegacyType230Adapter不支持写入操作');
  }
}
