import 'dart:io';

/// 修复导入错误的工具
/// 修复由代码质量修复脚本导致的导入路径错误
class ImportErrorFixer {
  static const String _backupDir = 'import_fix_backup';

  /// 主修复入口
  static void main(List<String> arguments) async {
    final fixer = ImportErrorFixer();

    print('🔧 开始修复导入错误...');
    print('');

    try {
      await fixer.runImportFix();
    } catch (e, stackTrace) {
      print('❌ 修复过程出错: $e');
      print('📍 错误堆栈: $stackTrace');
      exit(1);
    }
  }

  /// 运行导入错误修复
  Future<void> runImportFix() async {
    // 创建备份目录
    await _createBackupDirectory();

    final libDirectory = Directory('lib');
    if (!libDirectory.existsSync()) {
      print('⚠️ lib目录不存在');
      return;
    }

    final dartFiles = await _getDartFiles(libDirectory);
    int totalFilesFixed = 0;
    int totalImportsFixed = 0;

    print('📁 找到${dartFiles.length}个Dart文件');
    print('');

    for (final file in dartFiles) {
      try {
        final importsFixed = await _processFileForImportErrors(file);
        if (importsFixed > 0) {
          totalFilesFixed++;
          totalImportsFixed += importsFixed;
          print('  ✅ 修复文件: ${file.path} (修复$importsFixed个导入)');
        }
      } catch (e) {
        print('⚠️ 处理文件失败 ${file.path}: $e');
      }
    }

    print('');
    print('🎉 导入错误修复完成！');
    print('📊 修复统计:');
    print('   📄 修复文件数: $totalFilesFixed');
    print('   🔗 修复导入数: $totalImportsFixed');
  }

  /// 处理单个文件的导入错误
  Future<int> _processFileForImportErrors(File file) async {
    String content = await file.readAsString();
    String originalContent = content;
    int importsFixed = 0;

    // 1. 修复常见的导入路径错误
    importsFixed += _fixCommonImportErrors(content);

    // 2. 修复缓存相关导入
    importsFixed += _fixCacheImports(content);

    // 3. 修复日志相关导入
    importsFixed += _fixLoggerImports(content);

    // 4. 修复常量相关导入
    importsFixed += _fixConstantsImports(content);

    // 5. 修复类型相关导入
    importsFixed += _fixTypeImports(content);

    // 保存文件
    if (content != originalContent) {
      await _createFileBackup(file, originalContent);
      await file.writeAsString(content);
    }

    return importsFixed;
  }

  /// 修复常见导入错误
  int _fixCommonImportErrors(String content) {
    int fixed = 0;

    // 修复import路径
    final importFixes = {
      // 缓存相关
      "'cache_constants.dart'": "'../utils/cache_constants.dart'",
      "'../logger/app_logger.dart'": "'../utils/logger.dart'",

      // 常量相关
      "'../../constants/app_constants.dart'":
          "'../constants/app_constants.dart'",

      // 数据库相关
      "'../database/database_config.dart'":
          "'../database/sql_server_config.dart'",

      // 服务相关
      "'../services/api_service.dart'": "'../network/fund_api_client.dart'",

      // 网络相关
      "'../network/http_client.dart'": "'../network/fund_api_client.dart'",
    };

    importFixes.forEach((wrong, correct) {
      if (content.contains(wrong)) {
        content = content.replaceAll(wrong, correct);
        fixed++;
      }
    });

    return fixed;
  }

  /// 修复缓存相关导入
  int _fixCacheImports(String content) {
    int fixed = 0;

    // 修复缓存相关的导入路径
    if (content.contains("import 'cache_constants.dart'")) {
      content = content.replaceAll("import 'cache_constants.dart'",
          "import '../utils/cache_constants.dart'");
      fixed++;
    }

    return fixed;
  }

  /// 修复日志相关导入
  int _fixLoggerImports(String content) {
    int fixed = 0;

    // 修复日志相关的导入路径
    if (content.contains("import '../logger/app_logger.dart'")) {
      content = content.replaceAll("import '../logger/app_logger.dart'",
          "import '../utils/logger.dart'");
      fixed++;
    }

    return fixed;
  }

  /// 修复常量相关导入
  int _fixConstantsImports(String content) {
    int fixed = 0;

    // 修复常量相关的导入路径
    if (content.contains("import '../../constants/app_constants.dart'")) {
      content = content.replaceAll(
          "import '../../constants/app_constants.dart'",
          "import '../constants/app_constants.dart'");
      fixed++;
    }

    return fixed;
  }

  /// 修复类型相关导入
  int _fixTypeImports(String content) {
    int fixed = 0;

    // 修复一些常见的类型导入问题
    if (content.contains('_i7.FundFilterCriteria?')) {
      content =
          content.replaceAll('_i7.FundFilterCriteria?', 'FundFilterCriteria?');
      fixed++;
    }

    if (content.contains('_i7.')) {
      content = content.replaceAll(RegExp(r'_i7\.'), '');
      fixed++;
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
  ImportErrorFixer.main(arguments);
}
