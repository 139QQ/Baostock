import 'dart:io';

/// 简化版过度const修复工具
class SimpleConstFixer {
  static const String _backupDir = 'simple_const_fix_backup';

  /// 主修复入口
  static void main(List<String> arguments) async {
    final fixer = SimpleConstFixer();

    print('🔧 开始修复过度添加的const问题...');
    print('');

    try {
      await fixer.runSimpleConstFix();
    } catch (e, stackTrace) {
      print('❌ 修复过程出错: $e');
      print('📍 错误堆栈: $stackTrace');
      exit(1);
    }
  }

  /// 运行简单const修复
  Future<void> runSimpleConstFix() async {
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

    // 1. 移除方法调用前的
    constRemoved += _removeConstFromMethodCalls(content);

    // 2. 移除变量赋值前的const，改为final
    constRemoved += _fixConstVariables(content);

    // 3. 修复重复的
    constRemoved += _fixDuplicateConst(content);

    // 4. 修复不完整的const语句
    constRemoved += _fixIncompleteConst(content);

    // 保存文件
    if (content != originalContent) {
      await _createFileBackup(file, originalContent);
      await file.writeAsString(content);
    }

    return constRemoved;
  }

  /// 移除方法调用前的
  int _removeConstFromMethodCalls(String content) {
    int removed = 0;

    // 修复const方法调用
    final patterns = [
      RegExp(
          r'\bconst\s+(setState|notifyListeners|build|createState|initState|dispose|didChangeDependencies|didUpdateWidget|setState)\s*\('),
      RegExp(
          r'\bconst\s+(print|debugPrint|log|Future|async|await|return|if|for|while|switch)\s*[^(\s]'),
      RegExp(r'\bconst\s+([a-z][a-zA-Z0-9_]*)\s*\('),
    ];

    for (final pattern in patterns) {
      content = content.replaceAllMapped(pattern, (match) {
        removed++;
        return match.group(1)! +
            match.group(0)!.substring(match.group(1)!.length);
      });
    }

    return removed;
  }

  /// 修复const变量
  int _fixConstVariables(String content) {
    int removed = 0;

    // 修复const变量为final
    final pattern = RegExp(r'\bconst\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*=');
    content = content.replaceAllMapped(pattern, (match) {
      removed++;
      return 'final ${match.group(1)} =';
    });

    return removed;
  }

  /// 修复重复的
  int _fixDuplicateConst(String content) {
    int removed = 0;

    // 修复
    final pattern = RegExp(r'\bconst\s+const\s+');
    content = content.replaceAllMapped(pattern, (match) {
      removed++;
      return 'const ';
    });

    return removed;
  }

  /// 修复不完整的const语句
  int _fixIncompleteConst(String content) {
    int removed = 0;

    // 修复不完整的
    final patterns = [
      RegExp(r'\bconst\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*[^(\s=]'),
      RegExp(r'\bconst\s*\(\s*\)'),
    ];

    for (final pattern in patterns) {
      content = content.replaceAllMapped(pattern, (match) {
        removed++;
        // 根据不同情况处理
        if (match.group(0)!.contains('()')) {
          return '';
        } else {
          return '${match.group(1)!} ';
        }
      });
    }

    return removed;
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
  SimpleConstFixer.main(arguments);
}
