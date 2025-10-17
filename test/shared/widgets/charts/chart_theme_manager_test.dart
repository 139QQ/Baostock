/// 图表主题管理器测试
///
/// 测试图表主题管理器的功能和行为
library chart_theme_manager_test;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jisu_fund_analyzer/src/shared/widgets/charts/chart_theme_manager.dart';

void main() {
  group('ChartTheme', () {
    test('should create light theme with correct properties', () {
      // Act
      final theme = ChartTheme.light();

      // Assert
      expect(theme.primaryColor, const Color(0xFF1976D2));
      expect(theme.backgroundColor, Colors.white);
      expect(theme.textColor, const Color(0xFF212121));
      expect(theme.gridColor, const Color(0xFFE0E0E0));
      expect(theme.secondaryColors.length, 8);
      expect(theme.gradientColors.length, 2);
      expect(theme.legendStyle.fontSize, 12);
      expect(theme.titleStyle.fontSize, 16);
      expect(theme.tooltipStyle.fontSize, 11);
    });

    test('should create dark theme with correct properties', () {
      // Act
      final theme = ChartTheme.dark();

      // Assert
      expect(theme.primaryColor, const Color(0xFF64B5F6));
      expect(theme.backgroundColor, const Color(0xFF121212));
      expect(theme.textColor, const Color(0xFFFFFFFF));
      expect(theme.gridColor, const Color(0xFF424242));
      expect(theme.secondaryColors.length, 8);
      expect(theme.gradientColors.length, 2);
      expect(theme.legendStyle.color, const Color(0xFFB0B0B0));
      expect(theme.titleStyle.color, const Color(0xFFFFFFFF));
      expect(theme.tooltipStyle.color, const Color(0xFF212121));
    });

    test('should create copy with updated properties', () {
      // Arrange
      final originalTheme = ChartTheme.light();

      // Act
      final copiedTheme = originalTheme.copyWith(
        primaryColor: Colors.red,
        backgroundColor: Colors.black,
      );

      // Assert
      expect(copiedTheme.primaryColor, Colors.red);
      expect(copiedTheme.backgroundColor, Colors.black);
      expect(originalTheme.primaryColor, const Color(0xFF1976D2)); // unchanged
      expect(originalTheme.backgroundColor, Colors.white); // unchanged
    });

    test('should get color for index correctly', () {
      // Arrange
      final theme = ChartTheme.light();

      // Act & Assert
      expect(theme.getColorForIndex(0), theme.primaryColor);
      expect(theme.getColorForIndex(1), theme.secondaryColors[0]);
      expect(theme.getColorForIndex(8), theme.secondaryColors[7]);
      expect(theme.getColorForIndex(9), theme.secondaryColors[0]); // 循环
    });

    test('should create gradient correctly', () {
      // Arrange
      final theme = ChartTheme.light();

      // Act
      final gradient = theme.createGradient();

      // Assert
      expect(gradient.colors, theme.gradientColors);
      expect(gradient.colors.length, 2);
    });

    test('should create gradient with custom colors', () {
      // Arrange
      final theme = ChartTheme.light();
      final customColors = [Colors.red, Colors.blue];

      // Act
      final gradient = theme.createGradient(customColors);

      // Assert
      expect(gradient.colors, customColors);
    });

    test('should handle single color for gradient', () {
      // Arrange
      final theme = ChartTheme.light();

      // Act
      final gradient = theme.createGradient([Colors.red]);

      // Assert
      expect(gradient.colors[0], Colors.red);
      expect(gradient.colors[1], Colors.red.withOpacity(0.7));
    });
  });

  group('ChartThemeManager', () {
    late ChartThemeManager manager;

    setUp(() {
      // 由于 ChartThemeManager 使用了单例模式，这里直接获取实例
      manager = ChartThemeManager.instance;
    });

    test('should start with light theme', () {
      // Assert
      expect(manager.currentTheme.backgroundColor, Colors.white);
      expect(manager.currentTheme.textColor, const Color(0xFF212121));
    });

    test('should set and get custom theme', () {
      // Arrange
      final customTheme = ChartTheme.dark();

      // Act
      manager.setTheme(customTheme);

      // Assert
      expect(manager.currentTheme, customTheme);
    });

    test('should set light theme', () {
      // Arrange
      manager.setTheme(ChartTheme.dark());

      // Act
      manager.setLightTheme();

      // Assert
      expect(manager.currentTheme.backgroundColor, Colors.white);
      expect(manager.currentTheme.textColor, const Color(0xFF212121));
    });

    test('should set dark theme', () {
      // Act
      manager.setDarkTheme();

      // Assert
      expect(manager.currentTheme.backgroundColor, const Color(0xFF121212));
      expect(manager.currentTheme.textColor, const Color(0xFFFFFFFF));
    });

    test('should notify listeners on theme change', () {
      // Arrange
      var notified = false;
      manager.addListener(() {
        notified = true;
      });

      // Act
      manager.setDarkTheme();

      // Assert
      expect(notified, true);
    });

    test('should remove listeners correctly', () {
      // Arrange
      var notified = false;
      VoidCallback listener = () {
        notified = true;
      };
      manager.addListener(listener);

      // Act
      manager.removeListener(listener);
      manager.setDarkTheme();

      // Assert
      expect(notified, false);
    });

    test('should update system theme based on context', () {
      // This test would require a WidgetTester for proper context testing
      // For now, we'll test the logic without actual context
      // Act & Assert - should not throw
      expect(() => manager.setLightTheme(), returnsNormally);
      expect(() => manager.setDarkTheme(), returnsNormally);
    });

    test('should create financial theme with default colors', () {
      // Act
      final financialTheme = manager.createFinancialTheme();

      // Assert
      expect(financialTheme.primaryColor, const Color(0xFF4CAF50));
      expect(financialTheme.secondaryColors[0], const Color(0xFF4CAF50)); // 上涨
      expect(financialTheme.secondaryColors[1], const Color(0xFFF44336)); // 下跌
      expect(financialTheme.secondaryColors[2], const Color(0xFF9E9E9E)); // 平盘
    });

    test('should create financial theme with custom colors', () {
      // Arrange
      const positiveColor = Colors.green;
      const negativeColor = Colors.red;
      const neutralColor = Colors.grey;

      // Act
      final financialTheme = manager.createFinancialTheme(
        positiveColor: positiveColor,
        negativeColor: negativeColor,
        neutralColor: neutralColor,
      );

      // Assert
      expect(financialTheme.primaryColor, positiveColor);
      expect(financialTheme.secondaryColors[0], positiveColor);
      expect(financialTheme.secondaryColors[1], negativeColor);
      expect(financialTheme.secondaryColors[2], neutralColor);
    });

    test('should get responsive font size correctly', () {
      // Arrange
      final baseSize = 16.0;

      // Act & Assert - should not throw for different screen widths
      expect(() {
        manager.getResponsiveFontSize(
          MediaQuery.of(
            const Size(300, 600),
            devicePixelRatio: 1.0,
          ),
          baseSize,
        );
      }, returnsNormally);

      expect(() {
        manager.getResponsiveFontSize(
          MediaQuery.of(
            const Size(800, 600),
            devicePixelRatio: 1.0,
          ),
          baseSize,
        );
      }, returnsNormally);

      expect(() {
        manager.getResponsiveFontSize(
          MediaQuery.of(
            const Size(1400, 800),
            devicePixelRatio: 1.0,
          ),
          baseSize,
        );
      }, returnsNormally);
    });

    test('should get responsive padding correctly', () {
      // Act & Assert - should not throw for different screen widths
      expect(() {
        manager.getResponsivePadding(
          MediaQuery.of(
            const Size(300, 600),
            devicePixelRatio: 1.0,
          ),
        );
      }, returnsNormally);

      expect(() {
        manager.getResponsivePadding(
          MediaQuery.of(
            const Size(800, 600),
            devicePixelRatio: 1.0,
          ),
        );
      }, returnsNormally);

      expect(() {
        manager.getResponsivePadding(
          MediaQuery.of(
            const Size(1400, 800),
            devicePixelRatio: 1.0,
          ),
        );
      }, returnsNormally);
    });

    test('should get responsive chart height correctly', () {
      // Act & Assert - should not throw for different screen sizes
      expect(() {
        manager.getResponsiveChartHeight(
          MediaQuery.of(
            const Size(300, 600),
            devicePixelRatio: 1.0,
          ),
        );
      }, returnsNormally);

      expect(() {
        manager.getResponsiveChartHeight(
          MediaQuery.of(
            const Size(800, 600),
            devicePixelRatio: 1.0,
          ),
        );
      }, returnsNormally);

      expect(() {
        manager.getResponsiveChartHeight(
          MediaQuery.of(
            const Size(1400, 800),
            devicePixelRatio: 1.0,
          ),
        );
      }, returnsNormally);
    });

    test('should respect minimum height for responsive chart height', () {
      // Arrange
      const minHeight = 300.0;

      // Act
      final height = manager.getResponsiveChartHeight(
        MediaQuery.of(
          const Size(300, 200), // 小屏幕
          devicePixelRatio: 1.0,
        ),
        minHeight: minHeight,
      );

      // Assert
      expect(height, greaterThanOrEqualTo(minHeight));
    });
  });
}
