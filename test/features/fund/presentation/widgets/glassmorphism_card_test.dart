import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jisu_fund_analyzer/src/features/fund/presentation/widgets/glassmorphism_card.dart';
import 'package:jisu_fund_analyzer/src/core/theme/app_theme.dart';

void main() {
  group('GlassmorphismCard Tests', () {
    testWidgets('renders with default parameters', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassmorphismCard(
              child: const Text('Test Content'),
            ),
          ),
        ),
      );

      expect(find.text('Test Content'), findsOneWidget);
      expect(find.byType(GlassmorphismCard), findsOneWidget);
    });

    testWidgets('renders with custom parameters', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassmorphismCard(
              child: const Text('Test Content'),
              blur: 15.0,
              opacity: 0.2,
              borderRadius: 20.0,
              width: 200,
              height: 100,
            ),
          ),
        ),
      );

      expect(find.text('Test Content'), findsOneWidget);
      expect(find.byType(GlassmorphismCard), findsOneWidget);
    });

    testWidgets('renders with performance optimization enabled',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassmorphismCard(
              child: const Text('Test Content'),
              enablePerformanceOptimization: true,
            ),
          ),
        ),
      );

      expect(find.text('Test Content'), findsOneWidget);
      expect(find.byType(GlassmorphismCard), findsOneWidget);
    });

    testWidgets('validates parameters and shows error card for invalid params',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassmorphismCard(
              child: const Text('Test Content'),
              blur: 25.0, // Invalid: > 20.0
              opacity: 1.5, // Invalid: > 1.0
            ),
          ),
        ),
      );

      expect(find.text('Invalid glassmorphism parameters'), findsOneWidget);
    });

    testWidgets('handles edge cases - zero values',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassmorphismCard(
              child: const Text('Test Content'),
              blur: 0.0,
              opacity: 0.0,
              borderWidth: 0.0,
            ),
          ),
        ),
      );

      expect(find.text('Test Content'), findsOneWidget);
      expect(find.byType(GlassmorphismCard), findsOneWidget);
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
      expect(find.byType(GlassmorphismCard), findsOneWidget);
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
      expect(find.byType(GlassmorphismCard), findsOneWidget);
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
      expect(find.byType(GlassmorphismCard), findsOneWidget);
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
      expect(find.byType(GlassmorphismCard), findsOneWidget);
    });
  });
}
