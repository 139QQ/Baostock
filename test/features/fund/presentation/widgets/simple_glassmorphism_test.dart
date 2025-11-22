import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jisu_fund_analyzer/src/features/fund/presentation/widgets/glassmorphism_card.dart';
import 'package:jisu_fund_analyzer/src/core/theme/app_theme.dart';

void main() {
  group('GlassmorphismCard Simple Tests', () {
    testWidgets('renders with default parameters', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassmorphismCard(
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('renders with custom blur and opacity',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassmorphismCard(
              blur: 15.0,
              opacity: 0.2,
              borderRadius: 20.0,
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('validates parameters and shows error card for invalid params',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassmorphismCard(
              blur: 25.0, // Invalid: > 20.0
              opacity: 1.5,
              child: Text('Test Content'), // Invalid: > 1.0
            ),
          ),
        ),
      );

      expect(find.text('Invalid glassmorphism parameters'), findsOneWidget);
    });

    testWidgets('handles edge cases - zero values',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassmorphismCard(
              blur: 0.0,
              opacity: 0.0,
              borderWidth: 0.0,
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('performance optimization works', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassmorphismCard(
              enablePerformanceOptimization: true,
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      expect(find.text('Test Content'), findsOneWidget);
    });
  });

  group('GlassmorphismPresets Tests', () {
    testWidgets('light preset renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassmorphismPresets.light(
              child: const Text('Light Preset'),
            ),
          ),
        ),
      );

      expect(find.text('Light Preset'), findsOneWidget);
    });

    testWidgets('medium preset renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassmorphismPresets.medium(
              child: const Text('Medium Preset'),
            ),
          ),
        ),
      );

      expect(find.text('Medium Preset'), findsOneWidget);
    });

    testWidgets('strong preset renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassmorphismPresets.strong(
              child: const Text('Strong Preset'),
            ),
          ),
        ),
      );

      expect(find.text('Strong Preset'), findsOneWidget);
    });

    testWidgets('dark preset renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassmorphismPresets.dark(
              child: const Text('Dark Preset'),
            ),
          ),
        ),
      );

      expect(find.text('Dark Preset'), findsOneWidget);
    });
  });

  group('Theme Integration Tests', () {
    testWidgets('light theme config exists', (WidgetTester tester) async {
      expect(FluentAppTheme.lightGlassmorphismConfig.blur, equals(5.0));
      expect(FluentAppTheme.lightGlassmorphismConfig.opacity, equals(0.05));
    });

    testWidgets('dark theme config exists', (WidgetTester tester) async {
      expect(FluentAppTheme.darkGlassmorphismConfig.blur, equals(8.0));
      expect(FluentAppTheme.darkGlassmorphismConfig.opacity, equals(0.08));
    });

    testWidgets('performance config exists', (WidgetTester tester) async {
      expect(
          FluentAppTheme
              .performanceGlassmorphismConfig.enablePerformanceOptimization,
          isTrue);
      expect(FluentAppTheme.performanceGlassmorphismConfig.blur, equals(8.0));
    });
  });
}
