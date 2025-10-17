import 'dart:io';

/// 修复剩余错误的工具
/// 处理类型引用错误和其他修复脚本导致的问题
class RemainingErrorFixer {
  static const String _backupDir = 'remaining_error_fix_backup';

  /// 主修复入口
  static void main(List<String> arguments) async {
    final fixer = RemainingErrorFixer();

    print('🔧 开始修复剩余错误...');
    print('');

    try {
      await fixer.runRemainingErrorFix();
    } catch (e, stackTrace) {
      print('❌ 修复过程出错: $e');
      print('📍 错误堆栈: $stackTrace');
      exit(1);
    }
  }

  /// 运行剩余错误修复
  Future<void> runRemainingErrorFix() async {
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
        final errorsFixed = await _processFileForRemainingErrors(file);
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
    print('🎉 剩余错误修复完成！');
    print('📊 修复统计:');
    print('   📄 修复文件数: $totalFilesFixed');
    print('   🛠️ 修复错误数: $totalErrorsFixed');
  }

  /// 处理单个文件的剩余错误
  Future<int> _processFileForRemainingErrors(File file) async {
    String content = await file.readAsString();
    String originalContent = content;
    int errorsFixed = 0;

    // 1. 修复类型引用错误
    errorsFixed += _fixTypeReferenceErrors(content);

    // 2. 修复AppLogger调用错误
    errorsFixed += _fixAppLoggerErrors(content);

    // 3. 修复未定义的类引用
    errorsFixed += _fixUndefinedClassErrors(content);

    // 4. 修复导入问题
    errorsFixed += _fixImportIssues(content);

    // 保存文件
    if (content != originalContent) {
      await _createFileBackup(file, originalContent);
      await file.writeAsString(content);
    }

    return errorsFixed;
  }

  /// 修复类型引用错误
  int _fixTypeReferenceErrors(String content) {
    int fixed = 0;

    // 修复常见的类型引用错误
    final typeFixes = {
      '_i7.FundFilterCriteria?': 'FundFilterCriteria?',
      '_i7.': '',
      'const CacheConstants.': 'CacheConstants.',
      'AppLogger.warning': 'AppLogger.warn',
    };

    typeFixes.forEach((wrong, correct) {
      if (content.contains(wrong)) {
        content = content.replaceAll(wrong, correct);
        fixed++;
      }
    });

    return fixed;
  }

  /// 修复AppLogger调用错误
  int _fixAppLoggerErrors(String content) {
    int fixed = 0;

    // 修复AppLogger.error的参数问题
    final errorPattern = RegExp(r'AppLogger\.error\([\'"]([^'"]+)[\'"],?s*([^)]+))')
    content = content.replaceAllMapped(errorPattern, (match) {
      final message = match.group(1)!;
      final error = match.group(2)!;
      fixed++;
      return "AppLogger.error('$message', $error)";
    });

    // 修复AppLogger.warning为AppLogger.warn
    if (content.contains('AppLogger.warning')) {
      content = content.replaceAll('AppLogger.warning', 'AppLogger.warn');
      fixed++;
    }

    return fixed;
  }

  /// 修复未定义的类引用
  int _fixUndefinedClassErrors(String content) {
    int fixed = 0;

    // 修复常见的未定义类引用
    if (content.contains('CacheConstants.') && !content.contains('class CacheConstants')) {
      // 如果使用了CacheConstants但没有定义，添加定义
      if (!content.contains('class CacheConstants')) {
        const cacheConstantsClass = '''
// 缓存常量定义
class CacheConstants {
  static const String cacheBoxName = 'fund_cache';
  static const String metadataBoxName = 'fund_metadata';
}
''';
        content = cacheConstantsClass + content;
        fixed++;
      }
    }

    return fixed;
  }

  /// 修复导入问题
  int _fixImportIssues(String content) {
    int fixed = 0;

    // 修复Hive相关导入
    if (content.contains('Hive.initFlutter') && !content.contains('hive_flutter')) {
      if (content.contains("import 'package:hive/hive.dart'")) {
        content = content.replaceAll(
          "import 'package:hive/hive.dart'",
          "import 'package:hive_flutter/hive_flutter.dart'"
        );
        fixed++;
      } else if (!content.contains("import 'package:hive_flutter/hive_flutter.dart'")) {
        // 在第一个import后添加hive_flutter导入
        final lines = content.split('\n');
        for (int i = 0; i < lines.length; i++) {
          if (lines[i].startsWith('import ')) {
            lines.insert(i + 1, "import 'package:hive_flutter/hive_flutter.dart';");
            content = lines.join('\n');
            fixed++;
            break;
          }
        }
      }
    }

    // 修复logger导入
    if (content.contains('AppLogger.') && !content.contains('logger.dart')) {
      if (!content.contains("import '../utils/logger.dart'")) {
        // 在第一个import后添加logger导入
        final lines = content.split('\n');
        for (int i = 0; i < lines.length; i++) {
          if (lines[i].startsWith('import ')) {
            lines.insert(i + 1, "import '../utils/logger.dart';");
            content = lines.join('\n');
            fixed++;
            break;
          }
        }
      }
    }

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
      'syntax_fix_backup/',
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
  Future<void> _createFileBackup(File originalFile, String originalContent) async {
    final fileName = originalFile.path.split('\\').last;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final backupPath = '$_backupDir\\${timestamp}_$fileName';

    final backupFile = File(backupPath);
    await backupFile.writeAsString(originalContent);
  }
}

/// 顶层main函数
void main(List<String> arguments) {
  RemainingErrorFixer.main(arguments);
}