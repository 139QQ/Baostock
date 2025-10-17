import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:jisu_fund_analyzer/src/features/fund/presentation/bloc/search_bloc.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/bloc/search_state.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/widgets/fund_search_bar.dart';

import 'fund_search_bar_test.mocks.dart';

@GenerateMocks([SearchBloc])
void main() {
  group('FundSearchBar', () {
    late MockSearchBloc mockSearchBloc;

    setUp(() {
      mockSearchBloc = MockSearchBloc();
    });

    Widget createWidgetUnderTest(
        {VoidCallback? onSearch, VoidCallback? onClear}) {
      return MaterialApp(
        home: Scaffold(
          body: BlocProvider<SearchBloc>.value(
            value: mockSearchBloc,
            child: FundSearchBar(
              onSearch: onSearch ?? (_) {},
              onClear: onClear ?? () {},
            ),
          ),
        ),
      );
    }

    testWidgets('应该正确渲染搜索栏组件', (WidgetTester tester) async {
      // Arrange
      when(mockSearchBloc.state).thenReturn(const SearchLoadSuccess());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.clear), findsNothing);
    });

    testWidgets('应该显示清除按钮当有文本时', (WidgetTester tester) async {
      // Arrange
      when(mockSearchBloc.state).thenReturn(
        const SearchLoadSuccess(currentKeyword: 'test'),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.clear), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('输入文本时应该触发UpdateSearchKeyword事件', (WidgetTester tester) async {
      // Arrange
      when(mockSearchBloc.state).thenReturn(const SearchLoadSuccess());
      whenListen(mockSearchBloc, Stream.fromIterable([]));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '华夏基金');
      await tester.pump();

      // Assert
      verify(mockSearchBloc.add(const UpdateSearchKeyword(keyword: '华夏基金')))
          .called(1);
    });

    testWidgets('按回车键应该触发搜索', (WidgetTester tester) async {
      // Arrange
      bool searchCalled = false;
      when(mockSearchBloc.state).thenReturn(const SearchLoadSuccess());

      // Act
      await tester.pumpWidget(createWidgetUnderTest(
        onSearch: (keyword) {
          searchCalled = true;
        },
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '华夏基金');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Assert
      expect(searchCalled, true);
    });

    testWidgets('点击清除按钮应该触发清空操作', (WidgetTester tester) async {
      // Arrange
      bool clearCalled = false;
      when(mockSearchBloc.state).thenReturn(
        const SearchLoadSuccess(currentKeyword: 'test'),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest(
        onClear: () {
          clearCalled = true;
        },
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      // Assert
      expect(clearCalled, true);
    });

    testWidgets('点击搜索按钮应该触发搜索', (WidgetTester tester) async {
      // Arrange
      bool searchCalled = false;
      when(mockSearchBloc.state).thenReturn(
        const SearchLoadSuccess(currentKeyword: '华夏基金'),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest(
        onSearch: (keyword) {
          searchCalled = true;
        },
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();

      // Assert
      expect(searchCalled, true);
    });

    testWidgets('应该根据自动聚焦属性正确设置焦点', (WidgetTester tester) async {
      // Arrange
      when(mockSearchBloc.state).thenReturn(const SearchLoadSuccess());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(focusNode.primaryFocus, isNotNull);
    });

    testWidgets('应该根据禁用属性正确设置状态', (WidgetTester tester) async {
      // Arrange
      when(mockSearchBloc.state).thenReturn(const SearchLoadSuccess());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, true);
    });

    testWidgets('应该显示加载状态指示器', (WidgetTester tester) async {
      // Arrange
      when(mockSearchBloc.state).thenReturn(const SearchLoadInProgress());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('应该显示错误状态', (WidgetTester tester) async {
      // Arrange
      when(mockSearchBloc.state).thenReturn(
        const SearchLoadFailure(errorMessage: '搜索失败'),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('搜索失败'), findsOneWidget);
    });

    testWidgets('应该显示建议下拉列表', (WidgetTester tester) async {
      // Arrange
      when(mockSearchBloc.state).thenReturn(
        const SearchLoadSuccess(
          currentKeyword: '华夏',
          suggestions: ['华夏基金', '华夏成长', '华夏回报'],
        ),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('华夏基金'), findsOneWidget);
      expect(find.text('华夏成长'), findsOneWidget);
      expect(find.text('华夏回报'), findsOneWidget);
    });

    testWidgets('点击建议应该填充搜索框', (WidgetTester tester) async {
      // Arrange
      when(mockSearchBloc.state).thenReturn(
        const SearchLoadSuccess(
          currentKeyword: '华夏',
          suggestions: ['华夏基金', '华夏成长', '华夏回报'],
        ),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('华夏基金'));
      await tester.pump();

      // Assert
      verify(mockSearchBloc
              .add(const SelectSearchSuggestion(suggestion: '华夏基金')))
          .called(1);
    });

    testWidgets('应该正确处理自动聚焦参数', (WidgetTester tester) async {
      // Arrange
      when(mockSearchBloc.state).thenReturn(const SearchLoadSuccess());

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<SearchBloc>.value(
              value: mockSearchBloc,
              child: FundSearchBar(
                autoFocus: false,
                onSearch: (_) {},
                onClear: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      // 验证没有自动聚焦
      expect(focusNode.primaryFocus, isNull);
    });

    testWidgets('应该正确处理高级选项显示', (WidgetTester tester) async {
      // Arrange
      when(mockSearchBloc.state).thenReturn(const SearchLoadSuccess());

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<SearchBloc>.value(
              value: mockSearchBloc,
              child: FundSearchBar(
                showAdvancedOptions: true,
                onSearch: (_) {},
                onClear: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.tune), findsOneWidget);
    });

    testWidgets('点击高级选项应该显示高级搜索面板', (WidgetTester tester) async {
      // Arrange
      when(mockSearchBloc.state).thenReturn(const SearchLoadSuccess());

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<SearchBloc>.value(
              value: mockSearchBloc,
              child: FundSearchBar(
                showAdvancedOptions: true,
                onSearch: (_) {},
                onClear: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('搜索选项'), findsOneWidget);
      expect(find.text('搜索类型'), findsOneWidget);
      expect(find.text('搜索字段'), findsOneWidget);
    });

    testWidgets('应该正确处理占位符文本', (WidgetTester tester) async {
      // Arrange
      when(mockSearchBloc.state).thenReturn(const SearchLoadSuccess());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField));

      // Assert
      expect(textField.decoration?.hintText, contains('基金代码或名称'));
    });

    testWidgets('应该正确处理文本样式', (WidgetTester tester) async {
      // Arrange
      when(mockSearchBloc.state).thenReturn(const SearchLoadSuccess());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField));

      // Assert
      expect(textField.style?.fontSize, 16.0);
      expect(textField.style?.fontWeight, FontWeight.normal);
    });

    testWidgets('应该正确处理边框样式', (WidgetTester tester) async {
      // Arrange
      when(mockSearchBloc.state).thenReturn(const SearchLoadSuccess());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final inputDecoration =
          tester.widget<TextField>(find.byType(TextField)).decoration;

      // Assert
      expect(inputDecoration?.border, isA<OutlineInputBorder>());
      expect(inputDecoration?.contentPadding, const EdgeInsets.all(16.0));
    });

    testWidgets('应该正确处理主题变化', (WidgetTester tester) async {
      // Arrange
      when(mockSearchBloc.state).thenReturn(const SearchLoadSuccess());

      // Act
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            primaryColor: Colors.blue,
            inputDecorationTheme: const InputDecorationTheme(
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
              ),
            ),
          ),
          home: Scaffold(
            body: BlocProvider<SearchBloc>.value(
              value: mockSearchBloc,
              child: FundSearchBar(
                onSearch: (_) {},
                onClear: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(OutlineInputBorder), findsOneWidget);
    });
  });
}
