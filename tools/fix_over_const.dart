import 'dart:io';

/// 修复过度添加const问题的工具
/// 移除不合适的const关键字
class OverConstFixer {
  static const String _backupDir = 'over_const_fix_backup';

  /// 主修复入口
  static void main(List<String> arguments) async {
    final fixer = OverConstFixer();

    print('🔧 开始修复过度添加的const问题...');
    print('');

    try {
      await fixer.runOverConstFix();
    } catch (e, stackTrace) {
      print('❌ 修复过程出错: $e');
      print('📍 错误堆栈: $stackTrace');
      exit(1);
    }
  }

  /// 运行过度const修复
  Future<void> runOverConstFix() async {
    // 创建备份目录
    await _createBackupDirectory();

    final libDirectory = Directory('lib');
    if (!libDirectory.existsSync()) {
      print('⚠️ lib目录不存在');
      return;
    }

    final dartFiles = await _getDartFiles(libDirectory);
    int totalFilesFixed = 0;
    int totalConstRemoved = 0;

    print('📁 找到${dartFiles.length}个Dart文件');
    print('');

    for (final file in dartFiles) {
      try {
        final constRemoved = await _processFileForOverConst(file);
        if (constRemoved > 0) {
          totalFilesFixed++;
          totalConstRemoved += constRemoved;
          print('  ✅ 修复文件: ${file.path} (移除$constRemoved个const)');
        }
      } catch (e) {
        print('⚠️ 处理文件失败 ${file.path}: $e');
      }
    }

    print('');
    print('🎉 过度const修复完成！');
    print('📊 修复统计:');
    print('   📄 修复文件数: $totalFilesFixed');
    print('   ❌ 移除const数: $totalConstRemoved');
  }

  /// 处理单个文件的过度const问题
  Future<int> _processFileForOverConst(File file) async {
    String content = await file.readAsString();
    String originalContent = content;
    int constRemoved = 0;

    // 1. 修复方法调用前的const（方法调用不能使用const）
    final methodCallPattern =
        RegExp(r'\bconst\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(');
    content = content.replaceAllMapped(methodCallPattern, (match) {
      constRemoved++;
      return '${match.group(1)!}(';
    });

    // 2. 修复变量赋值前的const（变量应该用final而不是const）
    final variablePattern = RegExp(r'\bconst\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*=');
    content = content.replaceAllMapped(variablePattern, (match) {
      constRemoved++;
      return 'final ${match.group(1)} =';
    });

    // 3. 修复const后的括号不匹配问题
    content = _fixMismatchedBrackets(content, constRemoved);

    // 4. 修复字符串中的const错误
    content = _fixStringConstErrors(content, constRemoved);

    // 5. 修复重复的
    content = content.replaceAll(RegExp(r'\bconst\s+const\s+'), 'const ');

    // 6. 修复const后面直接跟变量名的情况
    content = _fixConstVariableErrors(content, constRemoved);

    // 保存文件
    if (content != originalContent) {
      await _createFileBackup(file, originalContent);
      await file.writeAsString(content);
    }

    return constRemoved;
  }

  /// 修复括号不匹配问题
  String _fixMismatchedBrackets(String content, int constRemoved) {
    // 修复const后面多余的括号
    final extraBracketPattern = RegExp(r'\bconst\s*\(\s*\)');
    content = content.replaceAllMapped(extraBracketPattern, (match) {
      constRemoved++;
      return '';
    });

    // 修复const后面跟的不是构造函数的情况
    final wrongConstructorPattern =
        RegExp(r'\bconst\s+([a-z][a-zA-Z0-9_]*)\s*\(');
    content = content.replaceAllMapped(wrongConstructorPattern, (match) {
      constRemoved++;
      return '${match.group(1)!}(';
    });

    return content;
  }

  /// 修复字符串中的const错误
  String _fixStringConstErrors(String content, int constRemoved) {
    // 修复const在字符串中的错误
    final stringConstPattern = RegExp(r'const\s+["]');
    content = content.replaceAllMapped(stringConstPattern, (match) {
      constRemoved++;
      return match.group(0)!.replaceFirst('const ', '');
    });

    // 修复const在单引号字符串中的错误
    final singleQuoteStringPattern = RegExp(r"const\s+[']");
    content = content.replaceAllMapped(singleQuoteStringPattern, (match) {
      constRemoved++;
      return match.group(0)!.replaceFirst('const ', '');
    });

    return content;
  }

  /// 修复const变量错误
  String _fixConstVariableErrors(String content, int constRemoved) {
    // 修复不完整的const语句
    final incompleteConstPattern =
        RegExp(r'\bconst\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*[^(\s]');
    content = content.replaceAllMapped(incompleteConstPattern, (match) {
      constRemoved++;
      return '${match.group(1)!} ';
    });

    return content;
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
  OverConstFixer.main(arguments);
}
