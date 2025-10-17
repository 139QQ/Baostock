#!/usr/bin/env dart

import 'dart:io';

/// 删除项目中多余的const关键字的脚本
/// 主要处理以下问题：
/// 1. const ->
/// 2. const关键字插入到变量名中的问题 (如: height -> height)
/// 3. 修复其他常见的const语法错误

void main() async {
  print('🔧 开始清理项目中的多余const关键字...');

  final projectDir = Directory.current.path;
  final libDir = Directory('$projectDir/lib');
  final toolsDir = Directory('$projectDir/tools');

  if (!libDir.existsSync()) {
    print('❌ 错误: 找不到lib目录');
    return;
  }

  int totalFilesProcessed = 0;
  int totalFilesFixed = 0;
  int totalConstsRemoved = 0;

  // 处理lib目录下的所有dart文件
  await processDirectory(libDir, (filesProcessed, filesFixed, constsRemoved) {
    totalFilesProcessed += filesProcessed;
    totalFilesFixed += filesFixed;
    totalConstsRemoved += constsRemoved;
  });

  // 处理tools目录下的dart文件
  if (toolsDir.existsSync()) {
    await processDirectory(toolsDir,
        (filesProcessed, filesFixed, constsRemoved) {
      totalFilesProcessed += filesProcessed;
      totalFilesFixed += filesFixed;
      totalConstsRemoved += constsRemoved;
    });
  }

  print('\n✅ 清理完成!');
  print('📊 统计结果:');
  print('   - 处理文件数: $totalFilesProcessed');
  print('   - 修复文件数: $totalFilesFixed');
  print('   - 删除const数: $totalConstsRemoved');

  if (totalFilesFixed > 0) {
    print('\n🔍 建议运行以下命令验证修复结果:');
    print('   flutter analyze');
    print('   flutter test');
  }
}

Future<void> processDirectory(
    Directory dir, Function(int, int, int) onProgress) async {
  int filesProcessed = 0;
  int filesFixed = 0;
  int constsRemoved = 0;

  await for (final entity in dir.list(recursive: true, followLinks: false)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      filesProcessed++;

      final result = await fixDuplicateConsts(entity);
      if (result.fixed) {
        filesFixed++;
        constsRemoved += result.constsRemoved;
        print(
            '✓ 修复: ${entity.path.split('Baostock${Platform.pathSeparator}').last} (删除${result.constsRemoved}个const)');
      }
    }
  }

  onProgress(filesProcessed, filesFixed, constsRemoved);
}

Future<ConstFixResult> fixDuplicateConsts(File file) async {
  final content = await file.readAsString();
  String fixedContent = content;
  int constsRemoved = 0;

  // 1. 修复 "const" -> "const"
  final constConstPattern = RegExp(r'\bconst\s+const\b');
  final constConstMatches = constConstPattern.allMatches(fixedContent);
  constsRemoved += constConstMatches.length;
  fixedContent = fixedContent.replaceAll(constConstPattern, 'const');

  // 2. 修复变量名中的const插入问题
  // 例如: height -> height, width -> width
  final variableConstPatterns = [
    RegExp(r'\bheighconst\s+t\b'),
    RegExp(r'\bwidconst\s+th\b'),
    RegExp(r'\bsizconst\s+edBox\b'),
    RegExp(r'\bsizconst\s+dBox\b'),
    RegExp(r'\biconconst\s+s\b'),
    RegExp(r'\bhistoconst\s+ry\b'),
    RegExp(r'\bsyconst\s+metric\b'),
    RegExp(r'\bconst\s+(\w+const\b)', caseSensitive: false), // 捕获各种包含const的变量名
  ];

  for (final pattern in variableConstPatterns) {
    final matches = pattern.allMatches(fixedContent);
    if (matches.isNotEmpty) {
      constsRemoved += matches.length;
      // 应用相应的修复
      if (pattern.pattern.contains('heighconst')) {
        fixedContent = fixedContent.replaceAll(pattern, 'height');
      } else if (pattern.pattern.contains('widconst')) {
        fixedContent = fixedContent.replaceAll(pattern, 'width');
      } else if (pattern.pattern.contains('sizconst')) {
        fixedContent = fixedContent.replaceAll(pattern, 'sizedBox');
      } else if (pattern.pattern.contains('iconconst')) {
        fixedContent = fixedContent.replaceAll(pattern, 'icons');
      } else if (pattern.pattern.contains('histoconst')) {
        fixedContent = fixedContent.replaceAll(pattern, 'history');
      } else if (pattern.pattern.contains('syconst')) {
        fixedContent = fixedContent.replaceAll(pattern, 'symmetric');
      }
    }
  }

  // 3. 修复其他常见的const语法问题
  final otherPatterns = [
    // 修复: const SizedBox(height: 16) -> const SizedBox(height: 16)
    RegExp(r'SizedBox\(heighconst\s+t:'),
    RegExp(r'SizedBox\(widconst\s+th:'),
    // 修复: _getErrorMessage() -> _getErrorMessage()
    RegExp(r'_getconst\s+const\s+ErrorMessage\(\)'),
    // 修复: Siconst zedBox -> SizedBox
    RegExp(r'Siconst\s+zedBox'),
    // 修复: Sizeconst dBox -> SizedBox
    RegExp(r'Sizeconst\s+dBox'),
  ];

  for (final pattern in otherPatterns) {
    final matches = pattern.allMatches(fixedContent);
    if (matches.isNotEmpty) {
      constsRemoved += matches.length;

      if (pattern.pattern.contains('height:')) {
        fixedContent = fixedContent.replaceAll(pattern, 'SizedBox(height:');
      } else if (pattern.pattern.contains('width:')) {
        fixedContent = fixedContent.replaceAll(pattern, 'SizedBox(width:');
      } else if (pattern.pattern.contains('_getconst')) {
        fixedContent = fixedContent.replaceAll(pattern, '_getErrorMessage()');
      } else if (pattern.pattern.contains('Siconst zedBox')) {
        fixedContent = fixedContent.replaceAll(pattern, 'SizedBox');
      } else if (pattern.pattern.contains('Sizeconst dBox')) {
        fixedContent = fixedContent.replaceAll(pattern, 'SizedBox');
      }
    }
  }

  // 4. 修复行尾的多余
  final lineEndConstPattern = RegExp(r'const\s*$\n', multiLine: true);
  final lineEndMatches = lineEndConstPattern.allMatches(fixedContent);
  if (lineEndMatches.isNotEmpty) {
    constsRemoved += lineEndMatches.length;
    fixedContent = fixedContent.replaceAll(lineEndConstPattern, '\n');
  }

  // 5. 修复空的BoxConstraints()调用
  final emptyBoxConstraintsPattern = RegExp(r'const\s+BoxConstraints\(\)');
  final boxConstraintsMatches =
      emptyBoxConstraintsPattern.allMatches(fixedContent);
  if (boxConstraintsMatches.isNotEmpty) {
    constsRemoved += boxConstraintsMatches.length;
    fixedContent =
        fixedContent.replaceAll(emptyBoxConstraintsPattern, 'BoxConstraints()');
  }

  // 如果内容有变化，写回文件
  if (fixedContent != content) {
    await file.writeAsString(fixedContent);
    return ConstFixResult(true, constsRemoved);
  }

  return ConstFixResult(false, 0);
}

class ConstFixResult {
  final bool fixed;
  final int constsRemoved;

  ConstFixResult(this.fixed, this.constsRemoved);
}
