import 'dart:io';

/// 语法错误修复工具
/// 专门修复const修复过程中产生的语法错误
class SyntaxErrorFixer {
  static const String _backupDir = 'syntax_fix_backup';

  /// 主修复入口
  static void main(List<String> arguments) async {
    final fixer = SyntaxErrorFixer();

    print('🔧 开始修复语法错误...');
    print('');

    try {
      await fixer.runSyntaxFix();
    } catch (e, stackTrace) {
      print('❌ 修复过程出错: $e');
      print('📍 错误堆栈: $stackTrace');
      exit(1);
    }
  }

  /// 运行语法错误修复
  Future<void> runSyntaxFix() async {
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
    print('   🛠️ 修复错误数: $totalErrorsFixed');
  }

  /// 处理单个文件的语法错误
  Future<int> _processFileForSyntaxErrors(File file) async {
    String content = await file.readAsString();
    String originalContent = content;
    int errorsFixed = 0;

    // 1. 修复未终止的字符串
    errorsFixed += _fixUnterminatedStrings(content);

    // 2. 修复括号不匹配
    errorsFixed += _fixMismatchedBrackets(content);

    // 3. 修复未定义的标识符
    errorsFixed += _fixUndefinedIdentifiers(content);

    // 4. 修复变量引用错误
    errorsFixed += _fixVariableReferences(content);

    // 5. 修复缺少的大括号
    errorsFixed += _fixMissingBraces(content);

    // 保存文件
    if (content != originalContent) {
      await _createFileBackup(file, originalContent);
      await file.writeAsString(content);
    }

    return errorsFixed;
  }

  /// 修复未终止的字符串
  int _fixUnterminatedStrings(String content) {
    int fixed = 0;

    // 修复常见的未终止字符串模式
    final patterns = [
      RegExp(r'const\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*"([^"]*)'),
      RegExp(r'"([^"]*)\s*$'),
      RegExp(r"'([^']*)\s*$"),
    ];

    for (final pattern in patterns) {
      content = content.replaceAllMapped(pattern, (match) {
        fixed++;
        if (match.groupCount >= 2) {
          return '${match.group(1)}"${match.group(2)}"';
        } else if (match.groupCount >= 1) {
          return '"${match.group(1)}"';
        }
        return match.group(0)!;
      });
    }

    return fixed;
  }

  /// 修复括号不匹配
  int _fixMismatchedBrackets(String content) {
    int fixed = 0;

    // 修复多余的右括号
    final patterns = [
      RegExp(r'\)\)'),
      RegExp(r'\]\]'),
      RegExp(r'\}\}'),
    ];

    for (final pattern in patterns) {
      content = content.replaceAllMapped(pattern, (match) {
        fixed++;
        return match.group(0)![0]; // 只保留一个
      });
    }

    return fixed;
  }

  /// 修复未定义的标识符
  int _fixUndefinedIdentifiers(String content) {
    int fixed = 0;

    // 修复常见的未定义标识符
    final patterns = [
      RegExp(r'\bkey_\b'),
      RegExp(r'\bkeyage_\b'),
      RegExp(r'\bke\$keya\b'),
      RegExp(r'\bkeye\b'),
      RegExp(r'\b\$keyshardIndex\b'),
    ];

    for (final pattern in patterns) {
      content = content.replaceAllMapped(pattern, (match) {
        fixed++;
        return 'key';
      });
    }

    return fixed;
  }

  /// 修复变量引用错误
  int _fixVariableReferences(String content) {
    int fixed = 0;

    // 修复变量引用错误
    final patterns = [
      RegExp(r'\$_([a-zA-Z_][a-zA-Z0-9_]*)'),
      RegExp(r'\$([a-zA-Z_][a-zA-Z0-9_]*)_([a-zA-Z_][a-zA-Z0-9_]*)'),
    ];

    for (final pattern in patterns) {
      content = content.replaceAllMapped(pattern, (match) {
        fixed++;
        if (match.groupCount >= 2) {
          return '${match.group(1)}_${match.group(2)}';
        } else if (match.groupCount >= 1) {
          return match.group(1)!;
        }
        return match.group(0)!;
      });
    }

    return fixed;
  }

  /// 修复缺少的大括号
  int _fixMissingBraces(String content) {
    int fixed = 0;

    // 修复缺少的大括号
    final lines = content.split('\n');
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // 如果方法或函数声明没有大括号，添加大括号
      if (line.contains(')') && !line.contains('{') && !line.contains(';')) {
        // 检查是否是方法声明
        if (line.contains(
                RegExp(r'\b(void|String|int|double|bool|Future|Widget)\b')) ||
            line.contains('return') ||
            line.contains('await')) {
          lines[i] = '$line {';
          // 下一行添加对应的大括号
          if (i + 1 < lines.length && !lines[i + 1].trim().startsWith('}')) {
            lines.insert(i + 1, '    // TODO: 添加实现');
            lines.insert(i + 2, '  }');
            fixed += 2;
          }
          fixed++;
        }
      }
    }

    content = lines.join('\n');
    return fixed;
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
      'over_const_fix_backup/',
      'simple_const_fix_backup/',
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
