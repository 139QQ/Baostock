import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jisu_fund_analyzer/src/widgets/smart_recommendation_carousel.dart';
import 'package:jisu_fund_analyzer/src/services/smart_recommendation_service.dart';
import 'package:jisu_fund_analyzer/src/features/fund/shared/models/fund_ranking.dart';

void main() {
  group('智能推荐系统性能基准测试', () {
    late List<FundRanking> largeDataset;
    late List<RecommendationItem> largeRecommendations;

    setUpAll(() {
      // 创建大数据集用于性能测试
      largeDataset = List.generate(
          100,
          (index) => _createTestFund(
                index.toString().padLeft(4, '0'),
                '性能测试基金$index',
                dailyReturn: -10.0 + (index % 20), // -10% 到 +9%
                oneYearReturn: -50.0 + (index % 100), // -50% 到 +49%
                fundSize: 100000000 + (index * 1000000), // 1亿到11亿
              ));

      // 创建大量推荐项
      largeRecommendations = List.generate(
          20,
          (index) => RecommendationItem(
                fund: largeDataset[index % largeDataset.length],
                score: 5.0 + (index % 5),
                reason: '性能测试推荐项$index',
                strategy: RecommendationStrategy
                    .values[index % RecommendationStrategy.values.length],
              ));
    });

    group('UI组件性能测试', () {
      testWidgets('大量推荐项渲染性能基准', (WidgetTester tester) async {
        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SmartRecommendationCarousel(
                recommendations: largeRecommendations,
                strategy: RecommendationStrategy.balanced,
                autoPlay: false, // 测试时禁用自动播放
                height: 200.0,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        stopwatch.stop();

        // 渲染性能断言
        expect(stopwatch.elapsedMilliseconds, lessThan(300)); // 目标: ≤300ms
        expect(find.byType(SmartRecommendationCarousel), findsOneWidget);
        expect(find.byType(PageView), findsOneWidget);

        print('🎨 UI渲染性能:');
        print('   推荐项数量: ${largeRecommendations.length}');
        print('   渲染时间: ${stopwatch.elapsedMilliseconds}ms');
        print(
            '   平均每项渲染时间: ${(stopwatch.elapsedMilliseconds / largeRecommendations.length).toStringAsFixed(2)}ms');
      });

      testWidgets('轮播切换动画性能测试', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SmartRecommendationCarousel(
                recommendations: largeRecommendations.take(5).toList(),
                strategy: RecommendationStrategy.balanced,
                autoPlay: false,
                height: 200.0,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 测试快速滑动性能
        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 10; i++) {
          await tester.fling(
            find.byType(PageView),
            const Offset(-300, 0),
            1000,
          );
          await tester.pumpAndSettle();
        }

        stopwatch.stop();

        // 滑动性能断言
        expect(stopwatch.elapsedMilliseconds, lessThan(2000)); // 10次滑动≤2秒
        expect(find.byType(SmartRecommendationCarousel), findsOneWidget);

        print('🎠 轮播滑动性能:');
        print('   滑动次数: 10次');
        print('   总时间: ${stopwatch.elapsedMilliseconds}ms');
        print(
            '   平均每次滑动: ${(stopwatch.elapsedMilliseconds / 10).toStringAsFixed(1)}ms');
      });

      testWidgets('频繁重建性能测试', (WidgetTester tester) async {
        int buildCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            buildCount++;
                          });
                        },
                        child: Text('重建 #$buildCount'),
                      ),
                      Expanded(
                        child: SmartRecommendationCarousel(
                          recommendations:
                              largeRecommendations.take(10).toList(),
                          strategy: RecommendationStrategy.values[buildCount %
                              RecommendationStrategy.values.length],
                          autoPlay: false,
                          height: 200.0,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        final stopwatch = Stopwatch()..start();

        // 执行多次重建
        for (int i = 0; i < 20; i++) {
          await tester.tap(find.byType(ElevatedButton));
          await tester.pumpAndSettle();
        }

        stopwatch.stop();

        // 重建性能断言
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // 20次重建≤1秒

        print('🔧 组件重建性能:');
        print('   重建次数: 20次');
        print('   总时间: ${stopwatch.elapsedMilliseconds}ms');
        print(
            '   平均每次重建: ${(stopwatch.elapsedMilliseconds / 20).toStringAsFixed(1)}ms');
      });

      testWidgets('内存使用模拟测试', (WidgetTester tester) async {
        // 记录初始状态
        final initialWidgetCount = tester.allWidgets.length;

        // 创建多个轮播组件模拟内存压力
        for (int i = 0; i < 5; i++) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Column(
                  children: List.generate(
                      3,
                      (index) => SizedBox(
                            height: 150,
                            child: SmartRecommendationCarousel(
                              recommendations:
                                  largeRecommendations.take(5).toList(),
                              strategy: RecommendationStrategy.values[
                                  index % RecommendationStrategy.values.length],
                              autoPlay: false,
                              height: 150.0,
                            ),
                          )),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
        }

        final finalWidgetCount = tester.allWidgets.length;

        // 内存模拟检查
        expect(finalWidgetCount, greaterThan(initialWidgetCount));
        expect(find.byType(SmartRecommendationCarousel), findsWidgets);

        print('🧠 内存使用模拟:');
        print('   初始组件数: $initialWidgetCount');
        print('   最终组件数: $finalWidgetCount');
        print(
            '   轮播组件数: ${find.byType(SmartRecommendationCarousel).evaluate().length}');
      });

      testWidgets('极端条件性能测试', (WidgetTester tester) async {
        // 创建极端数量的推荐项
        final extremeRecommendations = List.generate(
            100,
            (index) => RecommendationItem(
                  fund: _createTestFund(
                    index.toString().padLeft(5, '0'),
                    '极端测试基金$index',
                    dailyReturn: -50.0 + (index % 100),
                    oneYearReturn: -80.0 + (index % 160),
                    fundSize: 1000000 + (index * 10000000),
                  ),
                  score: 1.0 + (index % 9),
                  reason: '极端性能测试推荐项$index',
                  strategy: RecommendationStrategy
                      .values[index % RecommendationStrategy.values.length],
                ));

        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SmartRecommendationCarousel(
                recommendations: extremeRecommendations,
                strategy: RecommendationStrategy.balanced,
                autoPlay: false,
                height: 200.0,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        stopwatch.stop();

        // 极端条件性能断言
        expect(stopwatch.elapsedMilliseconds, lessThan(500)); // 极端数据≤500ms
        expect(find.byType(SmartRecommendationCarousel), findsOneWidget);

        print('🎯 极端条件性能测试:');
        print('   推荐项数量: ${extremeRecommendations.length}');
        print('   渲染时间: ${stopwatch.elapsedMilliseconds}ms');
        print(
            '   性能评级: ${stopwatch.elapsedMilliseconds < 300 ? "优秀" : stopwatch.elapsedMilliseconds < 400 ? "良好" : "需优化"}');
      });

      testWidgets('响应式性能测试', (WidgetTester tester) async {
        // 测试不同屏幕尺寸下的性能
        final screenSizes = [
          const Size(400, 800), // 小屏幕
          const Size(800, 600), // 中等屏幕
          const Size(1200, 900), // 大屏幕
        ];

        final performanceResults = <String, int>{};

        for (int i = 0; i < screenSizes.length; i++) {
          await tester.binding.setSurfaceSize(screenSizes[i]);

          final stopwatch = Stopwatch()..start();

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SmartRecommendationCarousel(
                  recommendations: largeRecommendations.take(8).toList(),
                  strategy: RecommendationStrategy.balanced,
                  autoPlay: false,
                  height: 200.0,
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();
          stopwatch.stop();

          final sizeName = ['小屏幕', '中等屏幕', '大屏幕'][i];
          performanceResults[sizeName] = stopwatch.elapsedMilliseconds;

          expect(stopwatch.elapsedMilliseconds, lessThan(400)); // 所有屏幕≤400ms
          expect(find.byType(SmartRecommendationCarousel), findsOneWidget);
        }

        print('📱 响应式性能测试:');
        performanceResults.forEach((size, time) {
          print('   $size: ${time}ms');
        });

        // 恢复默认屏幕尺寸
        await tester.binding.setSurfaceSize(null);
      });

      testWidgets('长时间运行稳定性测试', (WidgetTester tester) async {
        final performanceSnapshots = <int>[];

        // 执行50轮渲染测试
        for (int round = 0; round < 50; round++) {
          final stopwatch = Stopwatch()..start();

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SmartRecommendationCarousel(
                  recommendations: largeRecommendations.take(5).toList(),
                  strategy: RecommendationStrategy
                      .values[round % RecommendationStrategy.values.length],
                  autoPlay: false,
                  height: 200.0,
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();
          stopwatch.stop();

          performanceSnapshots.add(stopwatch.elapsedMilliseconds);

          // 偶尔进行交互测试
          if (round % 10 == 0) {
            await tester.fling(
              find.byType(PageView),
              const Offset(-200, 0),
              800,
            );
            await tester.pumpAndSettle();
          }
        }

        // 分析性能稳定性
        final avgPerformance = performanceSnapshots.reduce((a, b) => a + b) /
            performanceSnapshots.length;
        final maxPerformance =
            performanceSnapshots.reduce((a, b) => a > b ? a : b);
        final minPerformance =
            performanceSnapshots.reduce((a, b) => a < b ? a : b);

        // 稳定性断言
        expect(avgPerformance, lessThan(200)); // 平均性能≤200ms
        expect(maxPerformance - minPerformance, lessThan(150)); // 性能波动≤150ms

        print('🏋️ 长时间运行稳定性:');
        print('   测试轮数: 50轮');
        print('   平均性能: ${avgPerformance.toStringAsFixed(1)}ms');
        print('   性能范围: ${minPerformance}ms - ${maxPerformance}ms');
        print('   性能波动: ${(maxPerformance - minPerformance)}ms');
        print(
            '   稳定性评级: ${maxPerformance - minPerformance < 100 ? "优秀" : maxPerformance - minPerformance < 150 ? "良好" : "需关注"}');
      });

      testWidgets('性能基准线建立测试', (WidgetTester tester) async {
        final benchmarks = <String, dynamic>{};

        // UI渲染基准
        final uiStopwatch = Stopwatch()..start();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SmartRecommendationCarousel(
                recommendations: largeRecommendations.take(10).toList(),
                strategy: RecommendationStrategy.balanced,
                autoPlay: false,
                height: 200.0,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        uiStopwatch.stop();
        benchmarks['ui_render_10items'] = uiStopwatch.elapsedMilliseconds;

        // 交互基准
        final interactionStopwatch = Stopwatch()..start();
        for (int i = 0; i < 5; i++) {
          await tester.fling(find.byType(PageView), const Offset(-250, 0), 900);
          await tester.pumpAndSettle();
        }
        interactionStopwatch.stop();
        benchmarks['interaction_5swipes'] =
            interactionStopwatch.elapsedMilliseconds;

        // 基准验证
        expect(uiStopwatch.elapsedMilliseconds, lessThan(300));
        expect(interactionStopwatch.elapsedMilliseconds, lessThan(1000));

        print('📊 性能基准线建立:');
        benchmarks.forEach((key, value) {
          print('   $key: ${value}ms');
        });

        // 性能评级
        final uiGrade =
            _getPerformanceGrade(uiStopwatch.elapsedMilliseconds, 300);
        final interactionGrade = _getPerformanceGrade(
            interactionStopwatch.elapsedMilliseconds, 1000);

        print('\n🏆 性能评级:');
        print('   UI渲染: $uiGrade');
        print('   交互性能: $interactionGrade');

        // 保存基准数据供后续回归测试使用
        print('\n✅ 性能基准线已建立，可用于后续回归测试');
      });
    });
  });
}

// 性能评级辅助函数
String _getPerformanceGrade(int milliseconds, int target) {
  if (milliseconds <= target * 0.5) return 'A+ (优秀)';
  if (milliseconds <= target * 0.7) return 'A (良好)';
  if (milliseconds <= target) return 'B (达标)';
  if (milliseconds <= target * 1.5) return 'C (需优化)';
  return 'D (不合格)';
}

// 创建测试基金数据
FundRanking _createTestFund(
  String code,
  String name, {
  double dailyReturn = 0.0,
  double oneYearReturn = 0.0,
  double fundSize = 1000000000,
  RiskLevel riskLevel = RiskLevel.medium,
  bool isMockData = true,
}) {
  return FundRanking.fromJson({
    'fundCode': code,
    'fundName': name,
    'fundType': '混合型',
    'fundManager': '性能测试经理',
    'establishDate': '2020-01-01',
    'fundSize': fundSize,
    'dailyReturn': dailyReturn,
    'weeklyReturn': dailyReturn * 5,
    'monthlyReturn': dailyReturn * 20,
    'threeMonthReturn': dailyReturn * 60,
    'sixMonthReturn': dailyReturn * 120,
    'oneYearReturn': oneYearReturn,
    'threeYearReturn': oneYearReturn * 3,
    'sinceEstablishReturn': oneYearReturn * 4,
    'riskLevel': riskLevel.name,
    'isMockData': isMockData,
    'rank': 1,
  }, 0);
}
