import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:jisu_fund_analyzer/src/core/theme/app_theme.dart';
import 'package:jisu_fund_analyzer/src/bloc/fund_search_bloc.dart';
import 'package:jisu_fund_analyzer/src/bloc/portfolio_bloc.dart';
import 'package:jisu_fund_analyzer/src/services/fund_analysis_service.dart';
import 'package:jisu_fund_analyzer/src/services/portfolio_analysis_service.dart';
import 'package:jisu_fund_analyzer/src/services/high_performance_fund_service.dart';
import 'week6_demo_dashboard.dart';

/// Week 6 Demo 应用入口
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化Hive
  try {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);
  } catch (e) {
    print('Hive初始化警告: $e');
  }

  runApp(const Week6DemoApp());
}

class Week6DemoApp extends StatelessWidget {
  const Week6DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => FundSearchBloc(
            fundService: HighPerformanceFundService(),
            analysisService: FundAnalysisService(),
          ),
        ),
        BlocProvider(
          create: (context) => PortfolioBloc(
            portfolioService: PortfolioAnalysisService(),
            analysisService: FundAnalysisService(),
            fundService: HighPerformanceFundService(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Week 6 Demo - 基速基金量化分析平台',
        debugShowCheckedModeBanner: false,
        theme: _buildDemoTheme(),
        home: const Week6DemoDashboard(),
      ),
    );
  }

  ThemeData _buildDemoTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppTheme.primaryColor,
      scaffoldBackgroundColor: AppTheme.backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppTheme.primaryColor,
        brightness: Brightness.light,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
        titleTextStyle: AppTheme.headlineMedium.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: AppTheme.headlineLarge,
        headlineMedium: AppTheme.headlineMedium,
        bodyLarge: AppTheme.bodyLarge,
        bodyMedium: AppTheme.bodyMedium,
        bodySmall: AppTheme.bodySmall,
      ),
      tabBarTheme: TabBarTheme(
        indicatorColor: AppTheme.primaryColor,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: Colors.grey,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey[200],
        selectedColor: AppTheme.primaryColor.withOpacity(0.2),
        labelStyle: const TextStyle(color: Colors.black87),
        side: BorderSide(color: Colors.grey[300]!),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
