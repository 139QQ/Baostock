import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/scheduler.dart';

import 'package:jisu_fund_analyzer/src/features/fund/presentation/widgets/performance_monitor.dart';

void main() {
  group('PerformanceMonitor Tests', () {
    testWidgets('renders with default parameters', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PerformanceMonitor(
              child: const Text('Test Content'),
            ),
          ),
        ),
      );

      expect(find.text('Test Content'), findsOneWidget);
      expect(find.byType(PerformanceMonitor), findsOneWidget);
    });

    testWidgets('renders with performance monitoring',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PerformanceMonitor(
              child: const Text('Test Content'),
            ),
          ),
        ),
      );

      expect(find.text('Test Content'), findsOneWidget);
      expect(find.byType(PerformanceMonitor), findsOneWidget);
    });

    testWidgets('shows debug information when debugMode is true',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PerformanceMonitor(
              debugMode: true,
              child: const Text('Test Content'),
            ),
          ),
        ),
      );

      await tester.pump(); // 等待性能监控初始化

      expect(find.text('Test Content'), findsOneWidget);
      expect(find.byType(PerformanceMonitor), findsOneWidget);
      // 检查是否显示了调试信息（FPS、渲染时间等）
      expect(find.textContaining('FPS:'), findsOneWidget);
      expect(find.textContaining('Render:'), findsOneWidget);
    });

    testWidgets('calls onPerformanceUpdate callback',
        (WidgetTester tester) async {
      bool callbackCalled = false;
      PerformanceMetrics? receivedMetrics;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PerformanceMonitor(
              onPerformanceUpdate: (PerformanceMetrics metrics) {
                callbackCalled = true;
                receivedMetrics = metrics;
              },
              child: const Text('Test Content'),
            ),
          ),
        ),
      );

      await tester.pump(); // 触发性能监控

      expect(callbackCalled, isTrue);
      expect(receivedMetrics, isNotNull);
    });
  });

  group('PerformanceMetrics Tests', () {
    test('creates metrics with default values', () {
      final timestamp = DateTime.now();
      final metrics = PerformanceMetrics(timestamp: timestamp);

      expect(metrics.frameRate, equals(0.0));
      expect(metrics.renderTime, equals(0.0));
      expect(metrics.memoryUsage, equals(0.0));
      expect(metrics.timestamp, equals(timestamp));
    });

    test('evaluates performance correctly', () {
      final timestamp = DateTime.now();

      // 优秀性能
      final excellentMetrics = PerformanceMetrics(
        frameRate: 60.0,
        renderTime: 14000.0,
        timestamp: timestamp,
      );
      expect(excellentMetrics.isGoodPerformance, isTrue);
      expect(excellentMetrics.isPoorPerformance, isFalse);

      // 较差性能
      final poorMetrics = PerformanceMetrics(
        frameRate: 25.0,
        renderTime: 40000.0,
        timestamp: timestamp,
      );
      expect(poorMetrics.isGoodPerformance, isFalse);
      expect(poorMetrics.isPoorPerformance, isTrue);
    });
  });

  group('PerformanceThresholds Tests', () {
    test('has default values', () {
      const thresholds = PerformanceThresholds();

      expect(thresholds.minFrameRate, equals(55.0));
      expect(thresholds.maxRenderTime, equals(16666.0));
      expect(thresholds.maxMemoryUsage, equals(100.0));
    });

    test('provides preset configurations', () {
      expect(PerformanceThresholds.performance.minFrameRate, equals(60.0));
      expect(PerformanceThresholds.balanced.minFrameRate, equals(55.0));
      expect(PerformanceThresholds.compatibility.minFrameRate, equals(30.0));
    });
  });

  group('PerformanceLevel Tests', () {
    test('has correct display names', () {
      expect(PerformanceLevel.excellent.displayName, equals('优秀'));
      expect(PerformanceLevel.good.displayName, equals('良好'));
      expect(PerformanceLevel.fair.displayName, equals('一般'));
      expect(PerformanceLevel.poor.displayName, equals('较差'));
    });

    test('has correct colors', () {
      expect(PerformanceLevel.excellent.color, equals(Colors.green));
      expect(PerformanceLevel.good.color, equals(Colors.blue));
      expect(PerformanceLevel.fair.color, equals(Colors.orange));
      expect(PerformanceLevel.poor.color, equals(Colors.red));
    });
  });

  group('PerformanceUtils Tests', () {
    test('calculates performance levels correctly', () {
      final timestamp = DateTime.now();

      // 优秀性能
      final excellentMetrics = PerformanceMetrics(
        frameRate: 60.0,
        renderTime: 14000.0,
        timestamp: timestamp,
      );
      expect(
        PerformanceUtils.calculatePerformanceLevel(excellentMetrics),
        equals(PerformanceLevel.excellent),
      );

      // 良好性能
      final goodMetrics = PerformanceMetrics(
        frameRate: 57.0,
        renderTime: 16000.0,
        timestamp: timestamp,
      );
      expect(
        PerformanceUtils.calculatePerformanceLevel(goodMetrics),
        equals(PerformanceLevel.good),
      );

      // 一般性能
      final fairMetrics = PerformanceMetrics(
        frameRate: 40.0,
        renderTime: 25000.0,
        timestamp: timestamp,
      );
      expect(
        PerformanceUtils.calculatePerformanceLevel(fairMetrics),
        equals(PerformanceLevel.fair),
      );

      // 较差性能
      final poorMetrics = PerformanceMetrics(
        frameRate: 20.0,
        renderTime: 50000.0,
        timestamp: timestamp,
      );
      expect(
        PerformanceUtils.calculatePerformanceLevel(poorMetrics),
        equals(PerformanceLevel.poor),
      );
    });

    test('suggests appropriate glassmorphism configs', () {
      // 优秀性能 - 强烈效果
      final excellentConfig = PerformanceUtils.suggestGlassmorphismConfig(
        PerformanceLevel.excellent,
        false,
      );
      expect(excellentConfig.blur, equals(15.0));
      expect(excellentConfig.opacity, equals(0.15));

      // 较差性能 - 性能优先
      final poorConfig = PerformanceUtils.suggestGlassmorphismConfig(
        PerformanceLevel.poor,
        false,
      );
      expect(poorConfig.blur, equals(8.0));
      expect(poorConfig.opacity, equals(0.08));
      expect(poorConfig.enablePerformanceOptimization, isTrue);
    });
  });
}
