import 'dart:io';
import 'package:path/path.dart' as path;

/// 代码质量修复工具
/// 用于批量修复代码质量问题，特别是生产环境的print语句
class CodeQualityFixer {
  static const String _backupDir = 'code_fix_backup';
  static const String _reportFile = 'code_fix_report.md';
  // 替换为实际项目的logger导入路径
  static const String _loggerImportPath =
      "package:your_app/src/core/utils/logger.dart";

  // 修复统计
  int _totalFilesScanned = 0;
  int _totalPrintStatements = 0;
  int _totalFixedPrintStatements = 0;
  int _totalUnusedImports = 0;
  int _totalFixedUnusedImports = 0;

  // 文件模式匹配
  static final RegExp _printPattern = RegExp(
    r'(?<!\/)\bprint\s*\(',
    multiLine: true,
  );

  static final RegExp _importPattern = RegExp(
    r'^import\s+[^;]+;\s*$',
    multiLine: true,
  );

  /// 主入口函数
  static void main(List<String> arguments) async {
    final fixer = CodeQualityFixer();

// ignore: avoid_print
    print('🚀 代码质量修复工具启动...');
// ignore: avoid_print
    print('📋 参数: $arguments');

    // 解析命令行参数
    final config = _parseArguments(arguments);

    if (config['help'] == true) {
      _printHelp();
      return;
    }

    try {
      await fixer.run(config);
    } catch (e, stackTrace) {
// ignore: avoid_print
      print('❌ 修复过程出错: $e');
// ignore: avoid_print
      print('📍 错误堆栈: $stackTrace');
      exit(1);
    }
  }

  /// 运行修复流程
  Future<void> run(Map<String, dynamic> config) async {
    final dryRun = config['dry-run'] == true;
    final fixLevel = config['fix'] ?? 'all';
    final createBackup = config['backup'] != false; // 默认创建备份
    final generateReport = config['report'] != false; // 默认生成报告

// ignore: avoid_print
    print('🔧 修复配置:');
// ignore: avoid_print
    print('   试运行模式: $dryRun');
// ignore: avoid_print
    print('   修复级别: $fixLevel');
// ignore: avoid_print
    print('   创建备份: $createBackup');
// ignore: avoid_print
    print('   生成报告: $generateReport');
// ignore: avoid_print
    print('');

    // 创建备份目录
    if (createBackup && !dryRun) {
      await _createBackupDirectory();
    }

    // 开始修复流程
    final stopwatch = Stopwatch()..start();

    try {
      // 扫描并修复代码
      await _scanAndFixCode(fixLevel, dryRun, createBackup);

      stopwatch.stop();

      // 打印修复结果
      _printFixResults(stopwatch.elapsed);

      // 生成修复报告
      if (generateReport) {
        await _generateFixReport(dryRun);
      }

      // 提供后续建议
      _provideNextSteps(fixLevel);
    } catch (e) {
      stopwatch.stop();
// ignore: avoid_print
      print('❌ 修复过程失败: $e');
      rethrow;
    }
  }

  /// 扫描并修复代码
  Future<void> _scanAndFixCode(
      String fixLevel, bool dryRun, bool createBackup) async {
    final libDirectory = Directory('lib');

    if (!libDirectory.existsSync()) {
      throw Exception('lib目录不存在，请确保在项目根目录运行此工具');
    }

// ignore: avoid_print
    print('🔍 开始扫描lib目录...');

    // 获取所有Dart文件
    final dartFiles = await _getDartFiles(libDirectory);
    _totalFilesScanned = dartFiles.length;

// ignore: avoid_print
    print('📊 发现 $_totalFilesScanned 个Dart文件');
// ignore: avoid_print
    print('');

    // 根据修复级别执行不同的修复策略
    for (final file in dartFiles) {
      try {
        await _processFile(file, fixLevel, dryRun, createBackup);
      } catch (e) {
// ignore: avoid_print
        print('⚠️  处理文件失败 ${file.path}: $e');
      }
    }
  }

  /// 处理单个文件
  Future<void> _processFile(
      File file, String fixLevel, bool dryRun, bool createBackup) async {
    final relativePath = path.relative(file.path, from: Directory.current.path);
// ignore: avoid_print
    print('📄 处理文件: $relativePath');

    String content = await file.readAsString();
    String originalContent = content;

    bool fileModified = false;

    // 根据修复级别应用不同的修复
    if (fixLevel == 'all' || fixLevel == 'p0' || fixLevel == 'print') {
      final printFixed = _fixPrintStatements(content);
      if (printFixed != content) {
        content = printFixed;
        fileModified = true;
      }
    }

    if (fixLevel == 'all' || fixLevel == 'p1' || fixLevel == 'import') {
      final importFixed = _fixUnusedImports(content);
      if (importFixed != content) {
        content = importFixed;
        fileModified = true;
      }
    }

    if (fixLevel == 'all' || fixLevel == 'p2' || fixLevel == 'const') {
      final constFixed = _fixConstConstructors(content);
      if (constFixed != content) {
        content = constFixed;
        fileModified = true;
      }
    }

    // 如果文件被修改，保存更改
    if (fileModified) {
      if (dryRun) {
// ignore: avoid_print
        print('📝 试运行模式 - 文件将被修改: $relativePath');
      } else {
        // 创建备份
        if (createBackup) {
          await _createFileBackup(file, originalContent);
        }

        // 保存修改后的内容
        await file.writeAsString(content);
// ignore: avoid_print
        print('✅ 文件已修复: $relativePath');
      }
    } else {
// ignore: avoid_print
      print('✨ 文件无需修改: $relativePath');
    }
  }

  /// 修复print语句
  String _fixPrintStatements(String content) {
    // 统计print语句数量
    final printMatches = _printPattern.allMatches(content);
    _totalPrintStatements += printMatches.length;

    if (printMatches.isEmpty) {
      return content;
    }

// ignore: avoid_print
    print('  🔍 发现 ${printMatches.length} 个print语句');

    // 替换print语句为AppLogger调用
    String result = content;

    // 简单的print替换策略
    result = result.replaceAllMapped(_printPattern, (match) {
      _totalFixedPrintStatements++;
      return 'AppLogger.debug(';
    });

    // 添加导入语句（如果需要）
    if (result != content && !result.contains(_loggerImportPath)) {
      const importStatement =
          "import 'package:your_app/src/core/utils/logger.dart';\n";

      // 找到合适的位置插入导入（在其他导入之后）
      final packageImports =
          RegExp(r'^import\s+.*package:.*;$', multiLine: true);
      final allMatches = packageImports.allMatches(result).toList();

      if (allMatches.isNotEmpty) {
        final lastPackageImport = allMatches.last;
        final insertPosition = lastPackageImport.end;
        result =
            '${result.substring(0, insertPosition)}\n$importStatement${result.substring(insertPosition)}';
      } else {
        // 如果没有包导入，添加到文件开头
        result = importStatement + result;
      }
    }

    return result;
  }

  /// 修复未使用导入
  String _fixUnusedImports(String content) {
    // 注意：这里需要更复杂的静态分析来准确识别未使用导入
    // 当前实现仅作为示例，实际应该使用dart analyze的结果

// ignore: avoid_print
    print('  🔍 分析未使用导入...');

    // 简单的启发式规则：检查导入的包是否在文件中使用
    final imports = _importPattern.allMatches(content).toList();
    String result = content;

    // 从后往前移除，避免索引偏移问题
    for (var i = imports.length - 1; i >= 0; i--) {
      final import = imports[i];
      final importStatement = import.group(0)!;
      final packageName = _extractPackageName(importStatement);

      if (packageName != null) {
        // 检查包是否在文件内容中使用（除了导入语句本身）
        final contentWithoutImports = result.replaceAll(_importPattern, '');

        // 简单的使用检查
        final isUsed = _isPackageUsed(packageName, contentWithoutImports);

        if (!isUsed) {
          // 移除未使用的导入
          result = result.replaceFirst(importStatement, '');
          _totalUnusedImports++;
          _totalFixedUnusedImports++;
// ignore: avoid_print
          print('    🗑️ 移除未使用导入: $packageName');
        }
      }
    }

    // 清理可能产生的空行
    result = result.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return result;
  }

  /// 修复const构造函数
  String _fixConstConstructors(String content) {
// ignore: avoid_print
    print('  🔍 分析const构造函数优化...');

    // 简单的const优化规则
    // 注意：实际实现需要更复杂的静态分析

    String result = content;

    // 示例：将new Constructor()替换为const Constructor()
    result = result.replaceAllMapped(
      RegExp(r'\bnew\s+([A-Z][a-zA-Z0-9]*)\s*\('),
      (match) => 'const ${match.group(1)}(',
    );

    // 示例：优化容器构造函数（仅当参数看起来是常量时）
    result = result.replaceAllMapped(
      RegExp(r'\b(Container|Padding|Center|Align)\s*\((?!\s*const)'),
      (match) {
        final widgetName = match.group(1)!;
        // 简单检查是否有非常量参数的迹象
        final nextPart = content.substring(match.end, content.length);
        if (!nextPart.contains(RegExp(r'\bnew\b|\bDateTime\b|\bDuration\b'))) {
          return 'const $widgetName(';
        }
        return '${match.group(1)}(';
      },
    );

    return result;
  }

  /// 辅助方法：提取包名
  String? _extractPackageName(String importStatement) {
    final packageMatch = RegExp(r"package:([^/]+)").firstMatch(importStatement);
    return packageMatch?.group(1);
  }

  /// 辅助方法：检查包是否被使用
  bool _isPackageUsed(String packageName, String content) {
    // 简单的使用检查逻辑
    // 实际应该使用更复杂的静态分析

    final normalizedPackage = packageName.replaceAll(RegExp(r'[-_]'), '');
    final patterns = [
      RegExp(r'\b' + RegExp.escape(packageName) + r'\b'),
      RegExp(r'\b' + RegExp.escape(normalizedPackage) + r'\b'),
    ];

    for (final pattern in patterns) {
      if (pattern.hasMatch(content)) {
        return true;
      }
    }

    return false;
  }

  /// 获取所有Dart文件
  Future<List<File>> _getDartFiles(Directory directory) async {
    final files = <File>[];

    await for (final entity in directory.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        // 跳过生成的文件和测试文件（根据配置）
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
      '.g.dart', // 生成的文件
      '.freezed.dart', // 生成的文件
      'test/', // 测试文件
    ];

    return skipPatterns.any((pattern) => filePath.contains(pattern));
  }

  /// 创建备份目录
  Future<void> _createBackupDirectory() async {
    final backupDir = Directory(_backupDir);

    if (!backupDir.existsSync()) {
      await backupDir.create(recursive: true);
// ignore: avoid_print
      print('📁 创建备份目录: $_backupDir');
    }
  }

  /// 创建文件备份
  Future<void> _createFileBackup(
      File originalFile, String originalContent) async {
    // 创建与原文件相同的目录结构
    final relativePath =
        path.relative(originalFile.parent.path, from: Directory.current.path);
    final backupDirWithStructure =
        Directory(path.join(_backupDir, relativePath));
    await backupDirWithStructure.create(recursive: true);

    final fileName = path.basename(originalFile.path);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final backupPath =
        path.join(backupDirWithStructure.path, '${timestamp}_$fileName');

    final backupFile = File(backupPath);
    await backupFile.writeAsString(originalContent);

// ignore: avoid_print
    print('💾 备份文件创建: $backupPath');
  }

  /// 打印修复结果
  void _printFixResults(Duration elapsed) {
// ignore: avoid_print
    print('');
// ignore: avoid_print
    print('🎉 代码质量修复完成！');
// ignore: avoid_print
    print('⏱️  耗时: ${elapsed.inMinutes}分${elapsed.inSeconds % 60}秒');
// ignore: avoid_print
    print('');
// ignore: avoid_print
    print('📊 修复统计:');
// ignore: avoid_print
    print('   📄 扫描文件数: $_totalFilesScanned');
// ignore: avoid_print
    print('   🔍 发现print语句: $_totalPrintStatements');
// ignore: avoid_print
    print('   ✅ 修复print语句: $_totalFixedPrintStatements');
// ignore: avoid_print
    print('   📦 发现未使用导入: $_totalUnusedImports');
// ignore: avoid_print
    print('   🗑️ 移除未使用导入: $_totalFixedUnusedImports');
// ignore: avoid_print
    print('');
  }

  /// 生成修复报告
  Future<void> _generateFixReport(bool dryRun) async {
    final reportFile = File(_reportFile);
    final timestamp = DateTime.now().toIso8601String();

    final reportContent = '''# 代码质量修复报告

**生成时间**: $timestamp
**运行模式**: ${dryRun ? '试运行' : '实际修复'}

## 修复统计

| 指标 | 数量 |
|------|------|
| 扫描文件数 | $_totalFilesScanned |
| 发现print语句 | $_totalPrintStatements |
| 修复print语句 | $_totalFixedPrintStatements |
| 发现未使用导入 | $_totalUnusedImports |
| 移除未使用导入 | $_totalFixedUnusedImports |

## 修复建议

### 下一步操作
1. 运行 `flutter analyze` 检查剩余的代码质量问题
2. 手动验证关键业务逻辑的正确性
3. 运行完整的测试套件确保没有回归
4. 提交代码更改到版本控制系统

### 注意事项
- 本工具自动修复了基本的代码质量问题
- 部分复杂问题仍需手动审查和修复
- 建议在生产环境部署前进行充分测试

### 备份信息
- 备份文件保存在 `$_backupDir` 目录中
- 如需回滚，请手动恢复备份文件

---
*此报告由代码质量修复工具自动生成*
''';

    await reportFile.writeAsString(reportContent);
// ignore: avoid_print
    print('📝 修复报告已生成: $_reportFile');
  }

  /// 提供后续建议
  void _provideNextSteps(String fixLevel) {
// ignore: avoid_print
    print('');
// ignore: avoid_print
    print('💡 后续建议:');
// ignore: avoid_print
    print('   1. 运行 flutter analyze 检查剩余问题');
// ignore: avoid_print
    print('   2. 运行 flutter test 确保测试通过');
// ignore: avoid_print
    print('   3. 手动验证关键业务逻辑');
// ignore: avoid_print
    print('   4. 提交更改到版本控制系统');
// ignore: avoid_print
    print('');

    if (fixLevel != 'all') {
// ignore: avoid_print
      print('🔄 建议下次运行: dart run tools/code_fixer.dart --fix=all');
    }
  }

  /// 解析命令行参数
  static Map<String, dynamic> _parseArguments(List<String> arguments) {
    final config = <String, dynamic>{};

    for (int i = 0; i < arguments.length; i++) {
      final arg = arguments[i];

      switch (arg) {
        case '--help':
        case '-h':
          config['help'] = true;
          break;
        case '--dry-run':
        case '-d':
          config['dry-run'] = true;
          break;
        case '--backup':
        case '-b':
          config['backup'] = true;
          break;
        case '--no-backup':
          config['backup'] = false;
          break;
        case '--report':
        case '-r':
          config['report'] = true;
          break;
        case '--no-report':
          config['report'] = false;
          break;
        case '--fix':
        case '-f':
          if (i + 1 < arguments.length) {
            config['fix'] = arguments[++i];
          }
          break;
      }
    }

    return config;
  }

  /// 打印帮助信息
  static void _printHelp() {
// ignore: avoid_print
    print('''
🔧 代码质量修复工具

使用方法: dart run tools/code_fixer.dart [选项]

选项:
  -h, --help              显示此帮助信息
  -d, --dry-run           试运行模式（不实际修改文件）
  -b, --backup            创建备份文件（默认开启）
  --no-backup             不创建备份文件
  -r, --report            生成修复报告（默认开启）
  --no-report             不生成修复报告
  -f, --fix <级别>        指定修复级别:
                          all   - 修复所有问题（默认）
                          p0    - 仅修复P0级问题（print语句）
                          p1    - 修复P0+P1级问题
                          p2    - 修复P0+P1+P2级问题
                          print - 仅修复print语句
                          import- 仅修复导入问题
                          const - 仅修复const问题

示例:
  dart run tools/code_fixer.dart                    # 修复所有问题
  dart run tools/code_fixer.dart --dry-run         # 试运行，查看将要修复的内容
  dart run tools/code_fixer.dart --fix=p0 --backup # 仅修复P0问题并创建备份
  dart run tools/code_fixer.dart --fix=print --no-report  # 仅修复print语句，不生成报告

注意事项:
  - 运行前请确保已提交当前更改到版本控制
  - 建议在试运行模式下先查看修复效果
  - 修复后请运行 flutter analyze 和 flutter test 验证结果
  - 请先将工具中的logger导入路径修改为项目实际路径
''');
  }
}

/// 扩展入口点
void main(List<String> arguments) {
  CodeQualityFixer.main(arguments);
}
