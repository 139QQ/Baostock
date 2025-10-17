/// 图表主题管理器简化测试
///
/// 测试图表主题管理器的核心功能
library chart_theme_manager_simple_test;

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
  });

  group('ChartThemeManager', () {
    test('should start with light theme', () {
      // Act
      final manager = ChartThemeManager.instance;

      // Assert
      expect(manager.currentTheme.backgroundColor, Colors.white);
      expect(manager.currentTheme.textColor, const Color(0xFF212121));
    });

    test('should set and get custom theme', () {
      // Arrange
      final manager = ChartThemeManager.instance;
      final customTheme = ChartTheme.dark();

      // Act
      manager.setTheme(customTheme);

      // Assert
      expect(manager.currentTheme, customTheme);
    });

    test('should set light theme', () {
      // Arrange
      final manager = ChartThemeManager.instance;
      manager.setTheme(ChartTheme.dark());

      // Act
      manager.setLightTheme();

      // Assert
      expect(manager.currentTheme.backgroundColor, Colors.white);
      expect(manager.currentTheme.textColor, const Color(0xFF212121));
    });

    test('should set dark theme', () {
      // Arrange
      final manager = ChartThemeManager.instance;

      // Act
      manager.setDarkTheme();

      // Assert
      expect(manager.currentTheme.backgroundColor, const Color(0xFF121212));
      expect(manager.currentTheme.textColor, const Color(0xFFFFFFFF));
    });

    test('should create financial theme with default colors', () {
      // Arrange
      final manager = ChartThemeManager.instance;

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
      final manager = ChartThemeManager.instance;
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

    test('should notify listeners on theme change', () {
      // Arrange
      final manager = ChartThemeManager.instance;
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
      final manager = ChartThemeManager.instance;
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
  });
}
