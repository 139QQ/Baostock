import 'dart:convert';
import 'package:flutter/foundation.dart';

/// 编码辅助工具类
/// 用于处理特殊字符和编码问题
class EncodingHelper {
  /// 安全的JSON解析，处理特殊字符转义问题
  static T? safeJsonDecode<T>(String jsonString, {T? defaultValue}) {
    try {
      // 检查是否包含可能的问题字符
      if (jsonString.isEmpty) {
        debugPrint('⚠️ JSON字符串为空');
        return defaultValue;
      }

      // 检查是否包含Unicode转义序列
      final hasUnicodeEscapes = jsonString.contains('\\u');
      if (hasUnicodeEscapes) {
        debugPrint('🔣 JSON包含Unicode转义序列，将正确解析');
      }

      // 检查是否包含中文字符
      final hasChinese = RegExp(r'[\u4e00-\u9fff]').hasMatch(jsonString);
      if (hasChinese) {
        debugPrint('🈳 JSON包含中文字符，确保UTF-8编码');
      }

      // 检查是否包含可能的编码问题
      final hasEncodingIssues = jsonString.contains('å') ||
          jsonString.contains('ä') ||
          jsonString.contains('ö') ||
          jsonString.contains('é') ||
          jsonString.contains('è') ||
          jsonString.contains('ü') ||
          jsonString.contains('ç');

      if (hasEncodingIssues) {
        debugPrint('⚠️ JSON可能包含编码问题，尝试修复');
        return _fixEncodingIssues(jsonString, defaultValue);
      }

      // 标准JSON解析
      final result = jsonDecode(jsonString);
      debugPrint('✅ JSON解析成功');
      return result as T?;
    } catch (e) {
      debugPrint('❌ JSON解析失败: $e');
      debugPrint(
          '📄 原始JSON: ${jsonString.substring(0, jsonString.length > 200 ? 200 : jsonString.length)}');
      return defaultValue;
    }
  }

  /// 修复编码问题
  static T? _fixEncodingIssues<T>(String jsonString, T? defaultValue) {
    try {
      // 尝试将Latin-1编码的字符串重新编码为UTF-8
      final bytes = latin1.encode(jsonString);
      final fixedString = utf8.decode(bytes);

      debugPrint('🔧 尝试修复编码: ${jsonString.substring(0, 50)}...');
      debugPrint('🔧 修复后: ${fixedString.substring(0, 50)}...');

      return jsonDecode(fixedString) as T?;
    } catch (e) {
      debugPrint('❌ 编码修复失败: $e');
      return defaultValue;
    }
  }

  /// 检查字符串编码质量
  static EncodingQuality checkEncodingQuality(String text) {
    if (text.isEmpty) {
      return EncodingQuality.empty;
    }

    // 检查是否为有效的UTF-8
    try {
      utf8.decode(text.runes.toList());
      return EncodingQuality.validUtf8;
    } catch (e) {
      debugPrint('❌ UTF-8编码验证失败: $e');

      // 检查是否可能是Latin-1编码
      try {
        latin1.decode(text.runes.toList());
        return EncodingQuality.latin1;
      } catch (e2) {
        debugPrint('❌ Latin-1编码验证失败: $e2');
        return EncodingQuality.unknown;
      }
    }
  }

  /// 修复常见的中文字符编码问题
  static String fixChineseEncoding(String text) {
    // 常见的编码问题映射表
    final Map<String, String> encodingFixes = {
      'åºå·': '序号',
      'åéä»£ç ': '基金代码',
      'åéç®ç§°': '基金简称',
      'æ¥æ': '日期',
      'åä½åå¼': '单位净值',
      'ç¯è®¡åå¼': '累计净值',
      'æ¥å¢é¿ç': '日增长率',
      'è¿1å¨': '近1周',
      'è¿1æ': '近1月',
      'è¿3æ': '近3月',
      'è¿6æ': '近6月',
      'è¿1å¹´': '近1年',
      'è¿2å¹´': '近2年',
      'è¿3å¹´': '近3年',
      'ä»å¹´æ¥': '今年来',
      'æç«æ¥': '成立来',
      'æç»è´¹': '手续费',
    };

    String result = text;
    for (final entry in encodingFixes.entries) {
      if (result.contains(entry.key)) {
        result = result.replaceAll(entry.key, entry.value);
        debugPrint('🔧 修复编码: ${entry.key} -> ${entry.value}');
      }
    }

    return result;
  }
}

/// 编码质量枚举
enum EncodingQuality {
  validUtf8,
  latin1,
  unknown,
  empty,
}
