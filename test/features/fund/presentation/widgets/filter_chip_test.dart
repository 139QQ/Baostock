import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/widgets/filter_chip.dart';

void main() {
  group('FundFilterChip Tests', () {
    testWidgets('FundFilterChip renders correctly with basic props',
        (tester) async {
      const filterChip = FundFilterChip(
        label: 'Test Chip',
        selected: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: filterChip,
          ),
        ),
      );

      expect(find.text('Test Chip'), findsOneWidget);
      expect(find.byType(FundFilterChip), findsOneWidget);
    });

    testWidgets('FundFilterChip shows selected state', (tester) async {
      const filterChip = FundFilterChip(
        label: 'Selected Chip',
        selected: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: filterChip,
          ),
        ),
      );

      expect(find.text('Selected Chip'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('FundFilterChip calls onSelected when tapped', (tester) async {
      bool selected = false;
      late bool newSelectedValue;

      filterChip() => FundFilterChip(
            label: 'Tappable Chip',
            selected: selected,
            onSelected: (value) {
              newSelectedValue = value;
              selected = value;
            },
          );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: filterChip(),
          ),
        ),
      );

      await tester.tap(find.byType(FundFilterChip));
      await tester.pump();

      expect(newSelectedValue, isTrue);
      expect(selected, isTrue);
    });

    testWidgets('FundFilterChip.fundType creates fund type chip',
        (tester) async {
      final fundTypeChip = FundFilterChip.fundType(
        fundType: '股票型',
        selected: true,
        color: Colors.blue,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: fundTypeChip,
          ),
        ),
      );

      expect(find.text('股票型'), findsOneWidget);
      expect(find.byType(FundFilterChip), findsOneWidget);
    });

    testWidgets('FundFilterChip.riskLevel creates risk level chip',
        (tester) async {
      final riskLevelChip = FundFilterChip.riskLevel(
        level: 'R1',
        name: '低风险',
        selected: false,
        color: Colors.green,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: riskLevelChip,
          ),
        ),
      );

      expect(find.text('R1 低风险'), findsOneWidget);
      expect(find.byType(FundFilterChip), findsOneWidget);
    });

    testWidgets(
        'FundFilterChip.selectedTag creates tag chip with delete button',
        (tester) async {
      bool deleteCalled = false;

      final selectedTagChip = FundFilterChip.selectedTag(
        label: 'Filter Tag',
        onDelete: () => deleteCalled = true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: selectedTagChip,
          ),
        ),
      );

      expect(find.text('Filter Tag'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(deleteCalled, isTrue);
    });

    testWidgets('FundFilterChip respects disabled state', (tester) async {
      bool selected = false;

      filterChip() => FundFilterChip(
            label: 'Disabled Chip',
            selected: selected,
            onSelected: (value) => selected = value,
            disabled: true,
          );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: filterChip(),
          ),
        ),
      );

      await tester.tap(find.byType(FundFilterChip));
      await tester.pump();

      expect(selected, isFalse);
    });

    testWidgets('FundFilterChip shows prefix and suffix icons', (tester) async {
      const filterChip = FundFilterChip(
        label: 'Icon Chip',
        selected: false,
        prefixIcon: Icon(Icons.star),
        suffixIcon: Icon(Icons.arrow_forward),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: filterChip,
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('FundFilterChip with outline style', (tester) async {
      const filterChip = FundFilterChip(
        label: 'Outline Chip',
        selected: false,
        style: FilterChipStyle.outline,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: filterChip,
          ),
        ),
      );

      expect(find.text('Outline Chip'), findsOneWidget);
      expect(find.byType(FundFilterChip), findsOneWidget);
    });
  });

  group('FundFilterChipColors Tests', () {
    test('FundFilterChipColors has correct values', () {
      expect(FundFilterChipColors.stockType, equals(const Color(0xFF3B82F6)));
      expect(FundFilterChipColors.bondType, equals(const Color(0xFF10B981)));
      expect(FundFilterChipColors.hybridType, equals(const Color(0xFFF59E0B)));
      expect(FundFilterChipColors.moneyType, equals(const Color(0xFF8B5CF6)));
      expect(FundFilterChipColors.indexType, equals(const Color(0xFF06B6D4)));
      expect(FundFilterChipColors.qdiiType, equals(const Color(0xFFEC4899)));
      expect(FundFilterChipColors.fofType, equals(const Color(0xFF84CC16)));
      expect(FundFilterChipColors.riskLevel1, equals(const Color(0xFF10B981)));
      expect(FundFilterChipColors.riskLevel2, equals(const Color(0xFF84CC16)));
      expect(FundFilterChipColors.riskLevel3, equals(const Color(0xFFF59E0B)));
      expect(FundFilterChipColors.riskLevel4, equals(const Color(0xFFF97316)));
      expect(FundFilterChipColors.riskLevel5, equals(const Color(0xFFEF4444)));
    });
  });
}
