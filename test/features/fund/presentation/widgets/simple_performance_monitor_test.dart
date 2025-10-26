import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

    testWidgets('renders with auto downgrade disabled',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PerformanceMonitor(
              enableAutoDowngrade: false,
              child: const Text('Test Content'),
            ),
          ),
        ),
      );

      expect(find.text('Test Content'), findsOneWidget);
      expect(find.byType(PerformanceMonitor), findsOneWidget);
    });

    testWidgets('renders with debug mode enabled', (WidgetTester tester) async {
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

      expect(find.text('Test Content'), findsOneWidget);
      expect(find.byType(PerformanceMonitor), findsOneWidget);
    });

    testWidgets('renders with default thresholds', (WidgetTester tester) async {
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
      await tester.pump(const Duration(seconds: 1)); // 等待一个监控周期

      expect(callbackCalled, isTrue);
      expect(receivedMetrics, isNotNull);
    });
  });
}
