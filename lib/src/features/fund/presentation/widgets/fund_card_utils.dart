import 'package:flutter/material.dart';

/// 基金卡片工具类
///
/// 提供基金卡片相关的工具方法，包括颜色计算等
class FundCardUtils {
  /// 获取基金类型对应的颜色
  static Color getFundTypeColor(String type) {
    switch (type.toLowerCase()) {
      case '股票型':
        return Colors.red;
      case '混合型':
        return Colors.blue;
      case '债券型':
        return Colors.green;
      case '货币型':
        return Colors.orange;
      case '指数型':
        return Colors.purple;
      case 'QDII':
        return Colors.teal;
      case 'FOF':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  /// 获取收益率对应的颜色
  static Color getReturnColor(double returnRate) {
    if (returnRate > 0) {
      return Colors.red;
    } else if (returnRate < 0) {
      return Colors.green;
    } else {
      return Colors.grey;
    }
  }

  /// 获取风险等级对应的颜色
  static Color getRiskLevelColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case '低风险':
        return Colors.green;
      case '中低风险':
        return Colors.lightGreen;
      case '中等风险':
        return Colors.orange;
      case '中高风险':
        return Colors.deepOrange;
      case '高风险':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// 格式化收益率显示
  static String formatReturnRate(double returnRate) {
    return '${returnRate > 0 ? '+' : ''}${returnRate.toStringAsFixed(2)}%';
  }

  /// 格式化基金规模显示
  static String formatFundScale(double scale) {
    if (scale >= 10000) {
      return '${(scale / 10000).toStringAsFixed(1)}万亿';
    } else if (scale >= 1000) {
      return '${(scale / 1000).toStringAsFixed(1)}千亿';
    } else {
      return '${scale.toStringAsFixed(1)}亿';
    }
  }

  /// 格式化日期显示
  static String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 计算收益率评级
  static String getReturnRating(double returnRate) {
    if (returnRate > 20) {
      return '优秀';
    } else if (returnRate > 10) {
      return '良好';
    } else if (returnRate > 0) {
      return '一般';
    } else if (returnRate > -10) {
      return '较差';
    } else {
      return '很差';
    }
  }

  /// 获取收益率评级颜色
  static Color getReturnRatingColor(String rating) {
    switch (rating) {
      case '优秀':
        return Colors.red;
      case '良好':
        return Colors.orange;
      case '一般':
        return Colors.blue;
      case '较差':
        return Colors.lightGreen;
      case '很差':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
