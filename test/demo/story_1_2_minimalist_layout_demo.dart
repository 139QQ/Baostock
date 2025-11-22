import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import 'package:jisu_fund_analyzer/src/features/fund/presentation/fund_exploration/presentation/pages/minimalist_fund_exploration_page.dart';
import 'package:jisu_fund_analyzer/src/bloc/fund_search_bloc.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/fund_exploration/presentation/cubit/fund_exploration_cubit.dart';
import 'package:jisu_fund_analyzer/src/core/di/injection_container.dart' as di;

/// 极简布局演示应用
///
/// 展示Story 1.2极简主界面布局重构的成果
/// 主要特性：
/// - 单栏沉浸式设计
/// - 大量留白，突出核心内容
/// - 顶部优雅搜索框
/// - 折叠面板功能访问
/// - 底部悬浮极简工具栏
/// - 卡片流内容展示
/// - 响应式设计
void main() async {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化依赖注入
  await di.initDependencies();

  runApp(const MinimalistLayoutDemoApp());
}

/// 极简布局演示应用
class MinimalistLayoutDemoApp extends StatelessWidget {
  const MinimalistLayoutDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '极简基金探索界面 - Story 1.2 Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // 现代化的Material Design 3主题
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32), // 基金主题绿色
          brightness: Brightness.light,
        ),
        // 自定义字体
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w300,
            letterSpacing: -1.5,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.5,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
          ),
        ),
        // 卡片主题
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        // 输入框主题
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        // 按钮主题
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.dark,
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.shade800,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      themeMode: ThemeMode.system, // 跟随系统主题
      home: const MinimalistLayoutDemoPage(),
    );
  }
}

/// 极简布局演示页面
class MinimalistLayoutDemoPage extends StatefulWidget {
  const MinimalistLayoutDemoPage({super.key});

  @override
  State<MinimalistLayoutDemoPage> createState() =>
      _MinimalistLayoutDemoPageState();
}

class _MinimalistLayoutDemoPageState extends State<MinimalistLayoutDemoPage> {
  late FundSearchBloc _fundSearchBloc;
  late FundExplorationCubit _fundExplorationCubit;

  @override
  void initState() {
    super.initState();

    // 创建必要的BLoC和Cubit实例
    _fundSearchBloc = di.sl<FundSearchBloc>();
    _fundExplorationCubit = di.sl<FundExplorationCubit>();

    // 初始化数据
    _initializeData();
  }

  @override
  void dispose() {
    // 清理资源
    _fundSearchBloc.close();
    _fundExplorationCubit.close();
    super.dispose();
  }

  /// 初始化数据
  Future<void> _initializeData() async {
    try {
      // 初始化基金探索数据
      await _fundExplorationCubit.initialize();
    } catch (e) {
      // 静默处理初始化错误，确保demo能够正常运行
      debugPrint('初始化数据时出错: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 提供搜索BLoC
        BlocProvider<FundSearchBloc>.value(
          value: _fundSearchBloc,
        ),
        // 提供基金探索Cubit
        BlocProvider<FundExplorationCubit>.value(
          value: _fundExplorationCubit,
        ),
      ],
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        // 顶部应用栏
        appBar: AppBar(
          title: const Text(
            '极简基金探索',
            style: TextStyle(
              fontWeight: FontWeight.w300,
              letterSpacing: 1.0,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          // 主题切换按钮
          actions: [
            IconButton(
              icon: const Icon(Icons.brightness_6),
              onPressed: () {
                // 这里可以添加主题切换逻辑
                debugPrint('切换主题');
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        // 主体内容
        body: const MinimalistFundExplorationPage(),
        // 底部信息栏
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.1),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 8),
              Text(
                'Story 1.2 - 极简主界面布局重构',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 演示功能说明浮窗
class DemoInfoOverlay extends StatelessWidget {
  const DemoInfoOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 100,
      right: 16,
      child: Card(
        child: Container(
          padding: const EdgeInsets.all(16),
          width: 280,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '极简布局特性',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildFeatureItem(context, '✨ 单栏沉浸式设计'),
              _buildFeatureItem(context, '🎨 大量留白，突出核心内容'),
              _buildFeatureItem(context, '🔍 顶部优雅搜索框'),
              _buildFeatureItem(context, '📋 折叠面板功能访问'),
              _buildFeatureItem(context, '🔧 底部悬浮极简工具栏'),
              _buildFeatureItem(context, '📱 卡片流内容展示'),
              _buildFeatureItem(context, '📐 响应式设计'),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  // 关闭信息浮窗
                  Navigator.of(context).pop();
                },
                child: const Text('知道了'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
      ),
    );
  }
}
