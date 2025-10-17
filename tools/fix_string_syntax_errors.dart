import 'dart:io';

/// 修复字符串语法错误
/// 专门处理未终止的字符串字面量和字符串插值问题
void main() async {
// ignore: avoid_print
  print('🔧 开始修复字符串语法错误...');
// ignore: avoid_print
  print('');

  final filesWithStringErrors = [
    'lib/src/features/home/presentation/widgets/enhanced_market_overview_v2.dart',
    'lib/src/features/home/presentation/widgets/enhanced_market_real.dart',
    'lib/src/features/home/presentation/widgets/market_today_overview.dart',
    'lib/src/features/market/data/services/sector_realtime_service.dart',
  ];

  // 确保变量初始化
  int totalFilesFixed = 0;
  int totalErrorsFixed = 0;

  for (final filePath in filesWithStringErrors) {
    try {
      // 明确指定返回类型为Map<String, dynamic>，确保类型安全
      final Map<String, dynamic> result = await fixFile(filePath);

      // 处理可能的null值，确保计数安全
      final fixedCount = (result['fixed'] ?? 0) as int;

      if (fixedCount > 0) {
        totalFilesFixed++;
        totalErrorsFixed += fixedCount;
// ignore: avoid_print
        print('✅ $fixedCount 个错误已修复: $filePath');
      } else {
// ignore: avoid_print
        print('✨ 无需修复: $filePath');
      }
    } catch (e) {
      // 更详细的错误信息，包括堆栈跟踪（可选）
// ignore: avoid_print
      print('❌ 修复失败: $filePath - 错误详情: $e');
      // 如需调试可添加堆栈打印
      // debugPrintStack(stackTrace: StackTrace.current);
    }
  }

// ignore: avoid_print
  print('');
// ignore: avoid_print
  print('🎉 字符串语法错误修复完成！');
// ignore: avoid_print
  print(
      '📊 修复统计: 共处理 ${filesWithStringErrors.length} 个文件，成功修复 $totalFilesFixed 个文件，总计修复 $totalErrorsFixed 个错误');
}

Future<Map<String, dynamic>> fixFile(String filePath) async {
  final file = File(filePath);
  if (!file.existsSync()) {
    return {'fixed': 0, 'status': 'file_not_found'};
  }

  String content = await file.readAsString();

  int fixCount = 0;

  // 修复常见的字符串语法错误
  fixCount += fixUnterminatedStrings(content);
  fixCount += fixStringInterpolation(content);
  fixCount += fixMissingQuotes(content);

  if (fixCount > 0) {
    await file.writeAsString(content);
    return {'fixed': fixCount, 'status': 'fixed'};
  }

  return {'fixed': 0, 'status': 'no_changes'};
}

int fixUnterminatedStrings(String content) {
  // 简单的修复逻辑 - 查找明显的未终止字符串
  final unterminatedPattern =
      RegExp(r"AppLogger\.[a-zA-Z]+\('[^']*$", multiLine: true);
  final matches = unterminatedPattern.allMatches(content);

  int fixCount = 0;
  for (final match in matches) {
    // 添加缺失的引号和括号
    final fixedLine = "${match.group(0)!}');";
    content = content.replaceRange(match.start, match.end, fixedLine);
    fixCount++;
  }

  return fixCount;
}

int fixStringInterpolation(String content) {
  // 修复字符串插值中的多余引号
  // 例如: '${index.changePercent >= 0 ? '+' : ''}${index.changePercent.toStringAsFixed(2)}%'
  final interpolationPattern = RegExp(r"'\$\{[^}]+\}'\$\{[^}]+\}'");
  final matches = interpolationPattern.allMatches(content);

  int fixCount = 0;
  for (final match in matches) {
    String problematicText = match.group(0)!;
    // 移除多余的引号
    String fixedText = problematicText.replaceAll("'}'", "}");
    content = content.replaceRange(match.start, match.end, fixedText);
    fixCount++;
  }

  return fixCount;
}

int fixMissingQuotes(String content) {
  // 修复缺失的引号
  final missingQuotePattern =
      RegExp(r"AppLogger\.[a-zA-Z]+\([^)]*$", multiLine: true);
  final matches = missingQuotePattern.allMatches(content);

  int fixCount = 0;
  for (final match in matches) {
    final line = match.group(0)!;
    if (line.contains('AppLogger.') && !line.contains("'")) {
      // 添加缺失的引号和括号
      final fixedLine = "$line'');";
      content = content.replaceRange(match.start, match.end, fixedLine);
      fixCount++;
    }
  }

  return fixCount;
}

/// 手动修复特定文件的已知问题
Future<void> manualFixKnownIssues() async {
  // 修复已知的特定问题
  final knownIssues = {
    'lib/src/features/home/presentation/widgets/enhanced_market_overview_v2.dart':
        [
      // 第167行: 字符串插值语法
      (
        line: 167,
        fix: (content) {
          return content.replaceAll(
              "'\${index.changeAmount >= 0 ? '+' : ''}\${index.changeAmount.toStringAsFixed(2)}'",
              "'\${index.changeAmount >= 0 ? '+' : ''}\${index.changeAmount.toStringAsFixed(2)}'");
        }
      ),
    ],
  };

  for (final entry in knownIssues.entries) {
    final filePath = entry.key;
    final fixes = entry.value;

    try {
      final file = File(filePath);
      if (!file.existsSync()) continue;

      String content = await file.readAsString();
      String originalContent = content;

      for (final fix in fixes) {
        content = fix.fix(content);
      }

      if (content != originalContent) {
        await file.writeAsString(content);
// ignore: avoid_print
        print('🔧 手动修复完成: $filePath');
      }
    } catch (e) {
// ignore: avoid_print
      print('⚠️ 手动修复失败: $filePath - $e');
    }
  }
}
