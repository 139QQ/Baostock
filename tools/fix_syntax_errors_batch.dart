import 'dart:io';

/// 批量修复语法错误工具
/// 主要修复由过度const修复工具导致的语法问题
class SyntaxErrorFixer {
  static const String _backupDir = 'syntax_fix_backup';

  /// 主修复入口
  static void main(List<String> arguments) async {
    final fixer = SyntaxErrorFixer();

    print('🔧 开始批量修复语法错误...');
    print('');

    try {
      await fixer.runBatchFix();
    } catch (e, stackTrace) {
      print('❌ 修复过程出错: $e');
      print('📍 错误堆栈: $stackTrace');
      exit(1);
    }
  }

  /// 运行批量修复
  Future<void> runBatchFix() async {
    // 创建备份目录
    await _createBackupDirectory();

    final libDirectory = Directory('lib');
    if (!libDirectory.existsSync()) {
      print('⚠️ lib目录不存在');
      return;
    }

    final dartFiles = await _getDartFiles(libDirectory);
    int totalFilesFixed = 0;
    int totalErrorsFixed = 0;

    print('📁 找到${dartFiles.length}个Dart文件');
    print('');

    for (final file in dartFiles) {
      try {
        final errorsFixed = await _processFileForSyntaxErrors(file);
        if (errorsFixed > 0) {
          totalFilesFixed++;
          totalErrorsFixed += errorsFixed;
          print('  ✅ 修复文件: ${file.path} (修复$errorsFixed个错误)');
        }
      } catch (e) {
        print('⚠️ 处理文件失败 ${file.path}: $e');
      }
    }

    print('');
    print('🎉 语法错误修复完成！');
    print('📊 修复统计:');
    print('   📄 修复文件数: $totalFilesFixed');
    print('   🔧 修复错误数: $totalErrorsFixed');
  }

  /// 处理单个文件的语法错误
  Future<int> _processFileForSyntaxErrors(File file) async {
    String content = await file.readAsString();
    String originalContent = content;
    int errorsFixed = 0;

    // 1. 修复 SizedBox.shrink() 语法错误
    content = _fixSizedBoxShrink(content);
    errorsFixed += _countChanges(originalContent, content);
    originalContent = content;

    // 2. 修复 EdgeInsets 语法错误
    content = _fixEdgeInsets(content);
    errorsFixed += _countChanges(originalContent, content);
    originalContent = content;

    // 3. 修复 Duration 构造函数语法错误
    content = _fixDuration(content);
    errorsFixed += _countChanges(originalContent, content);
    originalContent = content;

    // 4. 修复 TextStyle 语法错误
    content = _fixTextStyle(content);
    errorsFixed += _countChanges(originalContent, content);
    originalContent = content;

    // 5. 修复 Color 构造函数语法错误
    content = _fixColor(content);
    errorsFixed += _countChanges(originalContent, content);
    originalContent = content;

    // 6. 修复 Container 和其他Widget构造函数语法错误
    content = _fixWidgetConstructors(content);
    errorsFixed += _countChanges(originalContent, content);
    originalContent = content;

    // 7. 修复方法调用语法错误
    content = _fixMethodCalls(content);
    errorsFixed += _countChanges(originalContent, content);
    originalContent = content;

    // 8. 修复类构造函数语法错误
    content = _fixClassConstructors(content);
    errorsFixed += _countChanges(originalContent, content);
    originalContent = content;

    // 保存文件
    if (content != originalContent) {
      await _createFileBackup(file, originalContent);
      await file.writeAsString(content);
    }

    return errorsFixed;
  }

  /// 修复 SizedBox.shrink() 语法错误
  String _fixSizedBoxShrink(String content) {
    // 修复 "SizedBox shrink()" -> "SizedBox.shrink()"
    content = content.replaceAllMapped(
      RegExp(r'\bSizedBox\s+shrink\s*\(\s*\)'),
      (match) => 'SizedBox.shrink()',
    );

    // 修复 "return SizedBox shrink();" -> "return const SizedBox.shrink();"
    content = content.replaceAllMapped(
      RegExp(r'return\s+SizedBox\s+shrink\s*\(\s*\)\s*;'),
      (match) => 'return const SizedBox.shrink();',
    );

    return content;
  }

  /// 修复 EdgeInsets 语法错误
  String _fixEdgeInsets(String content) {
    // 修复 "EdgeInsets all(16)" -> "EdgeInsets.all(16)"
    content = content.replaceAllMapped(
      RegExp(r'\bEdgeInsets\s+all\s*\(\s*([^)]+)\s*\)'),
      (match) => 'EdgeInsets.all(${match.group(1)})',
    );

    // 修复 "EdgeInsets symmetric(horizontal: 16, vertical: 2)" -> "EdgeInsets.symmetric(horizontal: 16, vertical: 2)"
    content = content.replaceAllMapped(
      RegExp(r'\bEdgeInsets\s+symmetric\s*\(\s*([^)]+)\s*\)'),
      (match) => 'EdgeInsets.symmetric(${match.group(1)})',
    );

    // 修复 "EdgeInsets only(left: 16)" -> "EdgeInsets.only(left: 16)"
    content = content.replaceAllMapped(
      RegExp(r'\bEdgeInsets\s+only\s*\(\s*([^)]+)\s*\)'),
      (match) => 'EdgeInsets.only(${match.group(1)})',
    );

    // 修复 "EdgeInsets fromLTRB(16, 8, 16, 8)" -> "EdgeInsets.fromLTRB(16, 8, 16, 8)"
    content = content.replaceAllMapped(
      RegExp(r'\bEdgeInsets\s+fromLTRB\s*\(\s*([^)]+)\s*\)'),
      (match) => 'EdgeInsets.fromLTRB(${match.group(1)})',
    );

    return content;
  }

  /// 修复 Duration 构造函数语法错误
  String _fixDuration(String content) {
    // 修复 "Duration seconds: 1" -> "Duration(seconds: 1)"
    content = content.replaceAllMapped(
      RegExp(r'\bDuration\s+seconds:\s*(\d+)\s*'),
      (match) => 'Duration(seconds: ${match.group(1)})',
    );

    // 修复 "Duration milliseconds: 500" -> "Duration(milliseconds: 500)"
    content = content.replaceAllMapped(
      RegExp(r'\bDuration\s+milliseconds:\s*(\d+)\s*'),
      (match) => 'Duration(milliseconds: ${match.group(1)})',
    );

    // 修复 "Duration minutes: 5" -> "Duration(minutes: 5)"
    content = content.replaceAllMapped(
      RegExp(r'\bDuration\s+minutes:\s*(\d+)\s*'),
      (match) => 'Duration(minutes: ${match.group(1)})',
    );

    // 修复 "Duration hours: 1" -> "Duration(hours: 1)"
    content = content.replaceAllMapped(
      RegExp(r'\bDuration\s+hours:\s*(\d+)\s*'),
      (match) => 'Duration(hours: ${match.group(1)})',
    );

    return content;
  }

  /// 修复 TextStyle 语法错误
  String _fixTextStyle(String content) {
    // 修复 "TextStyle color: Colors.black87" -> "TextStyle(color: Colors.black87)"
    content = content.replaceAllMapped(
      RegExp(r'\bTextStyle\s+color:\s*([^,}]+)\s*([,}])'),
      (match) => 'TextStyle(color: ${match.group(1)}${match.group(2)}',
    );

    // 修复 "TextStyle fontSize: 16" -> "TextStyle(fontSize: 16)"
    content = content.replaceAllMapped(
      RegExp(r'\bTextStyle\s+fontSize:\s*([^,}]+)\s*([,}])'),
      (match) => 'TextStyle(fontSize: ${match.group(1)}${match.group(2)}',
    );

    // 修复 "TextStyle fontWeight: FontWeight.bold" -> "TextStyle(fontWeight: FontWeight.bold)"
    content = content.replaceAllMapped(
      RegExp(r'\bTextStyle\s+fontWeight:\s*([^,}]+)\s*([,}])'),
      (match) => 'TextStyle(fontWeight: ${match.group(1)}${match.group(2)}',
    );

    return content;
  }

  /// 修复 Color 构造函数语法错误
  String _fixColor(String content) {
    // 修复 "Color 0xFFFFEB3B" -> "Color(0xFFFFEB3B)"
    content = content.replaceAllMapped(
      RegExp(r'\bColor\s+([0-9A-Fa-fx]+)\s*([,)}])'),
      (match) => 'Color(${match.group(1)})${match.group(2)}',
    );

    return content;
  }

  /// 修复 Container 和其他Widget构造函数语法错误
  String _fixWidgetConstructors(String content) {
    // 修复 Container margin: EdgeInsets all(16) -> Container(margin: EdgeInsets.all(16))
    content = content.replaceAllMapped(
      RegExp(r'\bContainer\s+margin:\s*([^,}]+)\s*([,}])'),
      (match) => 'Container(margin: ${match.group(1)}${match.group(2)}',
    );

    // 修复 Container padding: EdgeInsets all(12) -> Container(padding: EdgeInsets.all(12))
    content = content.replaceAllMapped(
      RegExp(r'\bContainer\s+padding:\s*([^,}]+)\s*([,}])'),
      (match) => 'Container(padding: ${match.group(1)}${match.group(2)}',
    );

    // 修复 Row children: [...] -> Row(children: [...])
    content = content.replaceAllMapped(
      RegExp(r'\bRow\s+children:\s*(\[.*?\])\s*([,}])'),
      (match) => 'Row(children: ${match.group(1)}${match.group(2)}',
    );

    // 修复 Column children: [...] -> Column(children: [...])
    content = content.replaceAllMapped(
      RegExp(r'\bColumn\s+children:\s*(\[.*?\])\s*([,}])'),
      (match) => 'Column(children: ${match.group(1)}${match.group(2)}',
    );

    return content;
  }

  /// 修复方法调用语法错误
  String _fixMethodCalls(String content) {
    // 修复 "BorderRadius circular 8" -> "BorderRadius.circular(8)"
    content = content.replaceAllMapped(
      RegExp(r'\bBorderRadius\s+circular\s+(\d+)\s*([,)}])'),
      (match) => 'BorderRadius.circular(${match.group(1)})${match.group(2)}',
    );

    // 修复 "BorderRadius only topLeft: Radius.circular 8" -> "BorderRadius.only(topLeft: Radius.circular(8))"
    content = content.replaceAllMapped(
      RegExp(r'\bBorderRadius\s+only\s+([^)]+)\s*([,)}])'),
      (match) => 'BorderRadius.only(${match.group(1)})${match.group(2)}',
    );

    // 修复 "Radius circular 4" -> "Radius.circular(4)"
    content = content.replaceAllMapped(
      RegExp(r'\bRadius\s+circular\s+(\d+)\s*([,)}])'),
      (match) => 'Radius.circular(${match.group(1)})${match.group(2)}',
    );

    return content;
  }

  /// 修复类构造函数语法错误（暂时简化）
  String _fixClassConstructors(String content) {
    // 暂时跳过复杂的Widget类检测，避免冲突
    return content;
  }

  /// 计算变更次数
  int _countChanges(String original, String modified) {
    if (original == modified) return 0;

    // 简单计算：比较行数差异
    final originalLines = original.split('\n').length;
    final modifiedLines = modified.split('\n').length;
    return (originalLines - modifiedLines).abs();
  }

  /// 获取所有Dart文件
  Future<List<File>> _getDartFiles(Directory directory) async {
    final files = <File>[];

    await for (final entity in directory.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        if (!_shouldSkipFile(entity.path)) {
          files.add(entity);
        }
      }
    }

    return files;
  }

  /// 判断是否应该跳过文件
  bool _shouldSkipFile(String filePath) {
    final skipPatterns = [
      '.dart_tool/',
      'build/',
      'generated/',
      '.g.dart',
      '.freezed.dart',
      'backup/',
      'comprehensive_fix_backup/',
      'import_fix_backup/',
    ];

    return skipPatterns.any((pattern) => filePath.contains(pattern));
  }

  /// 创建备份目录
  Future<void> _createBackupDirectory() async {
    final backupDir = Directory(_backupDir);

    if (!backupDir.existsSync()) {
      await backupDir.create(recursive: true);
      print('📁 创建备份目录: $_backupDir');
    }
  }

  /// 创建文件备份
  Future<void> _createFileBackup(
      File originalFile, String originalContent) async {
    final fileName = originalFile.path.split('\\').last;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final backupPath = '$_backupDir\\${timestamp}_$fileName';

    final backupFile = File(backupPath);
    await backupFile.writeAsString(originalContent);
  }
}

/// 顶层main函数
void main(List<String> arguments) {
  SyntaxErrorFixer.main(arguments);
}
