/// 自动修复print语句的工具脚本
///
/// 使用方法:
/// dart run tools/scripts/fix_print_statements.dart
///
/// 该脚本会:
/// 1. 查找所有包含print语句的文件
/// 2. 根据上下文将print语句替换为适当的AppLogger调用
/// 3. 或者在适当的情况下添加ignore注释
library;

import 'dart:io';

void main() async {
  print('🔧 开始修复print语句...\n');

  try {
    // 查找所有dart文件
    final dartFiles = await _findDartFiles('lib/src');

    int totalFixes = 0;

    for (final file in dartFiles) {
      final fixes = await _fixFile(file);
      totalFixes += fixes;

      if (fixes > 0) {
        print('✅ 修复 $file: $fixes 处修改');
      }
    }

    print('\n🎉 修复完成! 总共修复了 $totalFixes 处print语句');
    print('\n建议运行以下命令验证修复效果:');
    print('flutter analyze | grep "avoid_print"');
  } catch (e) {
    print('❌ 修复过程中出现错误: $e');
  }
}

/// 查找所有dart文件
Future<List<String>> _findDartFiles(String directory) async {
  final files = <String>[];
  await for (final entity in Directory(directory).list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      // 排除一些不需要修复的文件
      if (!_shouldSkipFile(entity.path)) {
        files.add(entity.path);
      }
    }
  }
  return files;
}

/// 判断是否应该跳过文件
bool _shouldSkipFile(String filePath) {
  final skipPatterns = [
    'test/',
    'generated/',
    '.g.dart',
    'logger.dart', // logger文件中的print已经手动处理
  ];

  return skipPatterns.any((pattern) => filePath.contains(pattern));
}

/// 修复单个文件
Future<int> _fixFile(String filePath) async {
  final file = File(filePath);
  final content = await file.readAsString();
  final lines = content.split('\n');

  int fixes = 0;
  final newLines = <String>[];

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];

    if (line.contains('print(') && !line.contains('// ignore: avoid_print')) {
      final fixedLine = _fixPrintStatement(line, filePath, i + 1);
      if (fixedLine != line) {
        fixes++;
        newLines.add(fixedLine);
      } else {
        newLines.add(line);
      }
    } else {
      newLines.add(line);
    }
  }

  if (fixes > 0) {
    await file.writeAsString(newLines.join('\n'));
  }

  return fixes;
}

/// 修复单个print语句
String _fixPrintStatement(String line, String filePath, int lineNumber) {
  // 提取print语句的内容
  final match = RegExp(r'print\((.*)\)').firstMatch(line);
  if (match == null) return line;

  final printContent = match.group(1) ?? '';
  final indent = line.substring(0, line.indexOf('print('));

  // 根据文件路径和内容判断适当的日志级别
  final loggerCall = _determineLoggerCall(printContent, filePath);

  return '$indent$loggerCall';
}

/// 确定适当的logger调用
String _determineLoggerCall(String printContent, String filePath) {
  // 如果包含错误关键词，使用error级别
  if (_containsKeywords(
      printContent, ['error', 'Error', 'ERROR', '异常', '失败', 'exception'])) {
    return 'AppLogger.error(${_convertToLoggerFormat(printContent)});';
  }

  // 如果包含警告关键词，使用warn级别
  if (_containsKeywords(
      printContent, ['warn', 'warning', 'Warning', '警告', '注意'])) {
    return 'AppLogger.warn(${_convertToLoggerFormat(printContent)});';
  }

  // 如果包含调试关键词，使用debug级别
  if (_containsKeywords(
      printContent, ['debug', 'Debug', 'DEBUG', '调试', 'Debug'])) {
    return 'AppLogger.debug(${_convertToLoggerFormat(printContent)});';
  }

  // 如果文件路径包含service，通常是info级别
  if (filePath.contains('/services/')) {
    return 'AppLogger.info(${_convertToLoggerFormat(printContent)});';
  }

  // 默认使用info级别
  return 'AppLogger.info(${_convertToLoggerFormat(printContent)});';
}

/// 检查是否包含关键词
bool _containsKeywords(String content, List<String> keywords) {
  return keywords.any((keyword) => content.contains(keyword));
}

/// 将print内容转换为logger格式
String _convertToLoggerFormat(String printContent) {
  // 简单的字符串插值检测
  if (printContent.contains('\$')) {
    // 尝试解析消息和参数
    final parts = printContent.split(RegExp(r'\$(?!\{)'));
    if (parts.length > 1) {
      final message = parts[0].replaceAll(RegExp(r"^['']|['']$"), '').trim();
      final paramName = parts[1].replaceAll(RegExp(r"['')\s;]"), '').trim();

      return "'$message', {'param': $paramName}";
    }
  }

  // 移除引号并返回
  return printContent.replaceAll(RegExp(r"^['']|['']$"), '');
}
