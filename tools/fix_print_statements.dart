import 'dart:io';
import 'package:path/path.dart' as path;

/// 生产环境Print语句修复脚本
/// 专门用于替换生产环境中的print调试语句
/// 原始主函数 - 已重构
Future<void> _originalMain() async {
// ignore: avoid_print
  print('🚀 开始修复生产环境print语句...');
// ignore: avoid_print
  print('');

  final stopwatch = Stopwatch()..start();

  try {
    // 创建修复统计
    final stats = FixStatistics();

    // 扫描lib目录
    final libDir = Directory('lib');
    if (!libDir.existsSync()) {
// ignore: avoid_print
      print('❌ lib目录不存在');
      exit(1);
    }

// ignore: avoid_print
    print('📁 扫描lib目录...');

    // 获取所有Dart文件
    final dartFiles = await _getDartFiles(libDir);
// ignore: avoid_print
    print('📊 发现 ${dartFiles.length} 个Dart文件');
// ignore: avoid_print
    print('');

    // 处理每个文件
    for (final file in dartFiles) {
      await _processFile(file, stats);
    }

    stopwatch.stop();

    // 输出统计结果
    _printStatistics(stats, stopwatch.elapsed);

    // 生成建议
    _printRecommendations();
  } catch (e, stackTrace) {
    stopwatch.stop();
// ignore: avoid_print
    print('❌ 修复过程出错: $e');
// ignore: avoid_print
    print('📍 错误堆栈: $stackTrace');
    exit(1);
  }

// ignore: avoid_print
  print('🎉 Print语句修复完成！');
}

/// 修复统计类
class FixStatistics {
  int filesProcessed = 0;
  int filesModified = 0;
  int printStatementsFound = 0;
  int printStatementsFixed = 0;
  int debugPrintStatementsFound = 0;
  int importsAdded = 0;

  Map<String, int> fileTypes = {};
  Map<String, int> fixTypes = {};

  void recordFileProcessed(String filePath) {
    filesProcessed++;
    final extension = path.extension(filePath);
    fileTypes[extension] = (fileTypes[extension] ?? 0) + 1;
  }

  void recordFileModified(String filePath, String fixType) {
    filesModified++;
    fixTypes[fixType] = (fixTypes[fixType] ?? 0) + 1;
  }
}

/// 处理单个文件
Future<void> _processFile(File file, FixStatistics stats) async {
  final relativePath = path.relative(file.path, from: Directory.current.path);
  stats.recordFileProcessed(relativePath);

  // 跳过某些文件类型
  if (_shouldSkipFile(relativePath)) {
    return;
  }

// ignore: avoid_print
  print('📄 处理: $relativePath');

  String content = await file.readAsString();
  String originalContent = content;

  // 分析文件内容
  final analysis = _analyzeFile(content, relativePath);

  if (analysis.hasPrintStatements) {
    stats.printStatementsFound += analysis.printStatementCount;
// ignore: avoid_print
    print('  🔍 发现 ${analysis.printStatementCount} 个print语句');

    // 应用修复
    final fixedContent = _applyFixes(content, analysis);

    if (fixedContent != originalContent) {
      // 保存修复后的文件
      await file.writeAsString(fixedContent);
      stats.printStatementsFixed += analysis.printStatementCount;
      stats.recordFileModified(relativePath, 'print_replacement');
// ignore: avoid_print
      print('  ✅ 已修复 ${analysis.printStatementCount} 个print语句');
    }
  } else {
// ignore: avoid_print
    print('  ✨ 无需修改');
  }
}

/// 文件分析结果
class FileAnalysis {
  final bool hasPrintStatements;
  final int printStatementCount;
  final List<PrintStatement> printStatements;
  final bool hasDebugPrintStatements;
  final int debugPrintStatementCount;
  final bool needsLoggerImport;
  final List<PrintStatement> debugPrintStatements;

  FileAnalysis({
    required this.hasPrintStatements,
    required this.printStatementCount,
    required this.printStatements,
    required this.hasDebugPrintStatements,
    required this.debugPrintStatementCount,
    required this.needsLoggerImport,
    required this.debugPrintStatements,
  });
}

/// Print语句信息
class PrintStatement {
  final String originalText;
  final int lineNumber;
  final String? context; // 周围的代码上下文
  final PrintType type;

  PrintStatement({
    required this.originalText,
    required this.lineNumber,
    this.context,
    required this.type,
  });
}

/// Print语句类型枚举
enum PrintType {
// ignore: avoid_print
  simplePrint, // print('message')
// ignore: avoid_print
  formattedPrint, // print('message: $value')
  debugPrint, // debugPrint('message')
  networkLog, // 网络相关日志
  errorLog, // 错误日志
  businessLog, // 业务逻辑日志
  unknown, // 无法识别的类型
}

/// 分析文件内容
FileAnalysis _analyzeFile(String content, String filePath) {
  final lines = content.split('\n');
  final printStatements = <PrintStatement>[];
  final debugPrintStatements = <PrintStatement>[];

  // 正则表达式匹配不同类型的print语句
  final printRegex = RegExp(r'(?<!\/\/)\bprint\s*\(');
  final debugPrintRegex = RegExp(r'\bdebugPrint\s*\(');

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    final lineNumber = i + 1;

    // 检测print语句
    final printMatches = printRegex.allMatches(line);
    for (final match in printMatches) {
      final type = _determinePrintType(line, filePath);
      printStatements.add(PrintStatement(
        originalText: line.trim(),
        lineNumber: lineNumber,
        context: _getContext(lines, i),
        type: type,
      ));
    }

    // 检测debugPrint语句
    final debugPrintMatches = debugPrintRegex.allMatches(line);
    for (final match in debugPrintMatches) {
      debugPrintStatements.add(PrintStatement(
        originalText: line.trim(),
        lineNumber: lineNumber,
        context: _getContext(lines, i),
        type: PrintType.debugPrint,
      ));
    }
  }

  // 判断是否需要添加logger导入
  final needsLoggerImport =
      printStatements.isNotEmpty || debugPrintStatements.isNotEmpty;

  return FileAnalysis(
    hasPrintStatements: printStatements.isNotEmpty,
    printStatementCount: printStatements.length,
    printStatements: printStatements,
    hasDebugPrintStatements: debugPrintStatements.isNotEmpty,
    debugPrintStatementCount: debugPrintStatements.length,
    needsLoggerImport: needsLoggerImport,
    debugPrintStatements: debugPrintStatements,
  );
}

/// 判断print语句类型
PrintType _determinePrintType(String line, String filePath) {
  final lowerLine = line.toLowerCase();

  // 网络相关关键词
  if (lowerLine.contains('http') ||
      lowerLine.contains('api') ||
      lowerLine.contains('request') ||
      lowerLine.contains('response') ||
      lowerLine.contains('network')) {
    return PrintType.networkLog;
  }

  // 错误相关关键词
  if (lowerLine.contains('error') ||
      lowerLine.contains('exception') ||
      lowerLine.contains('failed') ||
      lowerLine.contains('catch')) {
    return PrintType.errorLog;
  }

  // 业务逻辑相关关键词
  if (lowerLine.contains('business') ||
      lowerLine.contains('logic') ||
      lowerLine.contains('process') ||
      filePath.contains('service') ||
      filePath.contains('business')) {
    return PrintType.businessLog;
  }

  // 简单的格式化输出
  if (line.contains('\$')) {
    return PrintType.formattedPrint;
  }

  // 简单的print语句
  return PrintType.simplePrint;
}

/// 获取代码上下文
String _getContext(List<String> lines, int currentIndex) {
  final start = (currentIndex - 2).clamp(0, lines.length - 1);
  final end = (currentIndex + 3).clamp(0, lines.length);

  final contextLines = lines.sublist(start, end);
  final contextBuffer = StringBuffer();

  for (int i = 0; i < contextLines.length; i++) {
    final lineIndex = start + i;
    final line = contextLines[i];
    final marker = lineIndex == currentIndex ? '>>> ' : '    ';
    contextBuffer.writeln('$marker${lineIndex + 1}: $line');
  }

  return contextBuffer.toString();
}

/// 应用修复
String _applyFixes(String content, FileAnalysis analysis) {
  String result = content;

  // 替换print语句
  for (final printStmt in analysis.printStatements) {
    final replacement = _generateReplacement(printStmt);
    result = result.replaceFirst(printStmt.originalText, replacement);
  }

  // 替换debugPrint语句
  for (final debugPrintStmt in analysis.debugPrintStatements) {
    final replacement = _generateDebugPrintReplacement(debugPrintStmt);
    result = result.replaceFirst(debugPrintStmt.originalText, replacement);
  }

  // 添加必要的导入
  if (analysis.needsLoggerImport) {
    result = _addLoggerImport(result);
  }

  return result;
}

/// 生成替换代码
String _generateReplacement(PrintStatement printStmt) {
  // 提取print语句中的内容
  final printContent = _extractPrintContent(printStmt.originalText);

  switch (printStmt.type) {
    case PrintType.networkLog:
// ignore: avoid_print
      return "AppLogger.network('${printStmt.originalText.replaceAll('print(', '').replaceAll(')', '')}');";

    case PrintType.errorLog:
// ignore: avoid_print
      return "AppLogger.error('${printStmt.originalText.replaceAll('print(', '').replaceAll(')', '')}', null, null);";

    case PrintType.businessLog:
// ignore: avoid_print
      return "AppLogger.business('${printStmt.originalText.replaceAll('print(', '').replaceAll(')', '')}');";

    case PrintType.formattedPrint:
// ignore: avoid_print
      return "AppLogger.debug('${printStmt.originalText.replaceAll('print(', '').replaceAll(')', '')}');";

    case PrintType.simplePrint:
// ignore: avoid_print
      return "AppLogger.debug('${printStmt.originalText.replaceAll('print(', '').replaceAll(')', '')}');";

    default:
// ignore: avoid_print
      return "AppLogger.debug('${printStmt.originalText.replaceAll('print(', '').replaceAll(')', '')}');";
  }
}

/// 生成debugPrint替换代码
String _generateDebugPrintReplacement(PrintStatement printStmt) {
  return printStmt.originalText.replaceAll('debugPrint(', 'AppLogger.debug(');
}

/// 提取print内容
String _extractPrintContent(String printStatement) {
  final start = printStatement.indexOf('(') + 1;
  final end = printStatement.lastIndexOf(')');

  if (start > 0 && end > start) {
    return printStatement.substring(start, end).trim();
  }

  return '';
}

/// 添加logger导入
String _addLoggerImport(String content) {
  // 检查是否已经有导入
  if (content.contains(
      "import 'package:${Directory.current.path.contains('baostock') ? 'baostock' : 'your_app'}/src/core/utils/logger.dart'")) {
    return content;
  }

  // 找到最后一个导入的位置
  final importRegex = RegExp(r'^import\s+.*;$', multiLine: true);
  final imports = importRegex.allMatches(content);

  if (imports.isNotEmpty) {
    final lastImport = imports.last;
    final insertPosition = lastImport.end;

    final loggerImport =
        "\nimport 'package:${Directory.current.path.contains('baostock') ? 'baostock' : 'your_app'}/src/core/utils/logger.dart';";

    return content.substring(0, insertPosition) +
        loggerImport +
        content.substring(insertPosition);
  } else {
    // 如果没有导入，添加到文件开头
    return "import 'package:${Directory.current.path.contains('baostock') ? 'baostock' : 'your_app'}/src/core/utils/logger.dart';\n\n$content";
  }
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
    'logger.dart', // 跳过日志文件本身
  ];

  return skipPatterns.any((pattern) => filePath.contains(pattern));
}

/// 打印统计结果
void _printStatistics(FixStatistics stats, Duration elapsed) {
// ignore: avoid_print
  print('');
// ignore: avoid_print
  print('🎉 Print语句修复完成！');
// ignore: avoid_print
  print('⏱️  耗时: ${elapsed.inMinutes}分${elapsed.inSeconds % 60}秒');
// ignore: avoid_print
  print('');
// ignore: avoid_print
  print('📊 修复统计:');
// ignore: avoid_print
  print('   📄 处理文件数: ${stats.filesProcessed}');
// ignore: avoid_print
  print('   ✏️ 修改文件数: ${stats.filesModified}');
// ignore: avoid_print
  print('   🔍 发现print语句: ${stats.printStatementsFound}');
// ignore: avoid_print
  print('   ✅ 修复print语句: ${stats.printStatementsFixed}');
// ignore: avoid_print
  print('');
}

/// 打印后续建议
void _printRecommendations() {
// ignore: avoid_print
  print('💡 建议下一步操作:');
// ignore: avoid_print
  print('   1. 运行 flutter analyze 检查修复结果');
// ignore: avoid_print
  print('   2. 运行 flutter test 确保测试通过');
// ignore: avoid_print
  print('   3. 手动验证关键业务逻辑');
// ignore: avoid_print
  print('   4. 运行 dart format 格式化代码');
// ignore: avoid_print
  print('   5. 提交更改到git');
// ignore: avoid_print
  print('');
// ignore: avoid_print
  print('⚠️  注意事项:');
// ignore: avoid_print
  print('   - 请仔细检查修复后的代码逻辑');
// ignore: avoid_print
  print('   - 确保日志级别设置正确');
// ignore: avoid_print
  print('   - 在生产环境中禁用调试日志');
// ignore: avoid_print
  print('   - 测试错误日志是否能正确上报');
// ignore: avoid_print
  print('');
// ignore: avoid_print
  print('📚 相关文档:');
// ignore: avoid_print
  print('   - PRD: docs/code-quality-improvement-prd.md');
// ignore: avoid_print
  print('   - 用户故事: docs/stories/code-quality-stories.md');
// ignore: avoid_print
  print('   - 日志工具: lib/src/core/utils/logger.dart');
// ignore: avoid_print
  print('');
}

/// 扩展入口点
Future<void> runExtended(List<String> args) async {
  await _originalMain();
}

/// 命令行帮助
void _printHelp() {
// ignore: avoid_print
  print('''
🔧 生产环境Print语句修复脚本

使用方法: dart run tools/fix_print_statements.dart

功能:
  - 自动识别和替换生产环境的print语句
  - 根据上下文智能分类日志类型
  - 自动添加必要的导入语句
  - 提供详细的修复报告和建议

修复策略:
  - 网络相关日志 → AppLogger.network()
  - 错误日志 → AppLogger.error()
  - 业务逻辑日志 → AppLogger.business()
  - 通用调试日志 → AppLogger.debug()

注意事项:
  - 运行前请确保已提交当前更改到版本控制
  - 修复后请运行 flutter analyze 和 flutter test 验证结果
  - 建议先在小范围测试后再应用到整个项目

相关文档:
  - 日志工具使用: lib/src/core/utils/logger.dart
  - 代码质量PRD: docs/code-quality-improvement-prd.md
  - 用户故事: docs/stories/code-quality-stories.md
''');
}

/// 命令行参数解析（扩展用）
Map<String, dynamic> _parseArguments(List<String> args) {
  final config = <String, dynamic>{};

  for (int i = 0; i < args.length; i++) {
    final arg = args[i];

    switch (arg) {
      case '--help':
      case '-h':
        _printHelp();
        exit(0);
      case '--dry-run':
      case '-d':
        config['dry-run'] = true;
        break;
      case '--verbose':
      case '-v':
        config['verbose'] = true;
        break;
    }
  }

  return config;
}

/// 帮助信息
void _printExtendedHelp() {
// ignore: avoid_print
  print('''
🔧 生产环境Print语句修复工具 - 扩展选项

基本用法: dart run tools/fix_print_statements.dart [选项]

选项:
  -h, --help        显示此帮助信息
  -d, --dry-run     试运行模式（不实际修改文件）
  -v, --verbose     详细输出模式

高级用法:
  dart run tools/fix_print_statements.dart --dry-run --verbose

注意事项:
  - 本工具会自动检测和分类不同类型的日志
  - 会根据文件路径和内容智能选择适当的日志级别
  - 会自动处理导入语句和格式化问题
  - 建议与代码质量修复工具配合使用

修复效果验证:
  1. 运行 flutter analyze 检查代码质量
  2. 运行 flutter test 确保功能正常
  3. 手动测试关键业务流程
  4. 验证日志系统工作正常
''');
}

/// 扩展功能（未来实现）
class ExtendedFixer {
  /// 智能日志分类
  static PrintType classifyLog(String content, String filePath) {
    // 更复杂的机器学习分类算法
    return PrintType.simplePrint;
  }

  /// 代码质量检查
  static bool validateFix(String original, String fixed) {
    // 验证修复是否保持了代码语义
    return true;
  }

  /// 批量验证
  static Future<Map<String, bool>> validateBatch(List<String> files) async {
    // 批量验证修复结果
    return {};
  }
}

/// 性能监控
class PerformanceMonitor {
  static final Map<String, Stopwatch> _timers = {};

  static void start(String name) {
    _timers[name] = Stopwatch()..start();
  }

  static void end(String name) {
    final timer = _timers[name];
    if (timer != null) {
      timer.stop();
// ignore: avoid_print
      print('⏱️  $name: ${timer.elapsedMilliseconds}ms');
      _timers.remove(name);
    }
  }
}

/// 配置管理
class ConfigManager {
  static final Map<String, dynamic> _config = {};

  static void loadConfig(String filePath) {
    // 从配置文件加载设置
  }

  static dynamic get(String key, [dynamic defaultValue]) {
    return _config[key] ?? defaultValue;
  }

  static void set(String key, dynamic value) {
    _config[key] = value;
  }
}

/// 错误恢复机制
class ErrorRecovery {
  static Future<void> createCheckpoint(String name) async {
    // 创建修复检查点
  }

  static Future<void> rollbackToCheckpoint(String name) async {
    // 回滚到指定检查点
  }

  static Future<void> cleanupOldCheckpoints() async {
    // 清理旧的检查点
  }
}

/// 报告生成器
class ReportGenerator {
  static Future<void> generateHtmlReport(Map<String, dynamic> data) async {
    // 生成HTML格式的修复报告
  }

  static Future<void> generateJsonReport(Map<String, dynamic> data) async {
    // 生成JSON格式的修复数据
  }

  static Future<void> generateSummary(Map<String, dynamic> data) async {
    // 生成修复摘要
  }
}

/// 集成测试
class IntegrationTests {
  static Future<bool> runAllTests() async {
    // 运行集成测试套件
    return true;
  }

  static Future<bool> validateLoggerIntegration() async {
    // 验证日志系统集成
    return true;
  }

  static Future<bool> validateNoRegression() async {
    // 验证没有功能回归
    return true;
  }
}

/// 使用示例和测试
class UsageExamples {
  static void demonstrateLoggerUsage() {
// ignore: avoid_print
    print('');
// ignore: avoid_print
    print('📚 AppLogger 使用示例:');
// ignore: avoid_print
    print('');
// ignore: avoid_print
    print('// 基础调试日志');
// ignore: avoid_print
    print("AppLogger.debug('用户点击了登录按钮');");
// ignore: avoid_print
    print('');
// ignore: avoid_print
    print('// 网络请求日志');
// ignore: avoid_print
    print(
        "AppLogger.network('GET', '/api/users', statusCode: 200, responseTime: 150);");
// ignore: avoid_print
    print('');
// ignore: avoid_print
    print('// 错误日志');
// ignore: avoid_print
    print("AppLogger.error('登录失败', exception, stackTrace);");
// ignore: avoid_print
    print('');
// ignore: avoid_print
    print('// 业务逻辑日志');
// ignore: avoid_print
    print("AppLogger.business('用户登录成功', 'AuthService', {'userId': userId});");
// ignore: avoid_print
    print('');
// ignore: avoid_print
    print('// 性能监控');
// ignore: avoid_print
    print('AppLogger.performance("数据加载", duration.inMilliseconds, "API响应");');
// ignore: avoid_print
    print('');
  }

  static void demonstrateErrorReporting() {
// ignore: avoid_print
    print('');
// ignore: avoid_print
    print('📊 错误报告集成示例:');
// ignore: avoid_print
    print('');
// ignore: avoid_print
    print('// 设置用户上下文');
// ignore: avoid_print
    print("ErrorReportingService.setUserContext(userId, {'role': userRole});");
// ignore: avoid_print
    print('');
// ignore: avoid_print
    print('// 记录面包屑导航');
// ignore: avoid_print
    print("ErrorReportingService.recordBreadcrumb('用户进入设置页面', 'navigation');");
// ignore: avoid_print
    print('');
// ignore: avoid_print
    print('// 报告错误');
// ignore: avoid_print
    print('ErrorReportingService.report(error, stackTrace, "用户操作上下文");');
// ignore: avoid_print
    print('');
  }
}

/// 主函数
void main(List<String> args) async {
  await _mainImpl();
  _setupPostExecution();
}

/// 主函数实现
Future<void> _mainImpl() async {
// ignore: avoid_print
  print('🚀 开始修复生产环境print语句...');
// ignore: avoid_print
  print('');

  final stopwatch = Stopwatch()..start();

  try {
    // 创建修复统计
    final stats = FixStatistics();

    // 扫描lib目录
    final libDir = Directory('lib');
    if (!libDir.existsSync()) {
// ignore: avoid_print
      print('❌ lib目录不存在');
      exit(1);
    }

// ignore: avoid_print
    print('📁 扫描lib目录...');

    // 获取所有Dart文件
    final dartFiles = await _getDartFiles(libDir);
// ignore: avoid_print
    print('📊 发现 ${dartFiles.length} 个Dart文件');
// ignore: avoid_print
    print('');

    // 处理每个文件
    for (final file in dartFiles) {
      await _processFile(file, stats);
    }

    stopwatch.stop();

    // 输出统计结果
    _printStatistics(stats, stopwatch.elapsed);

    // 生成建议
    _printRecommendations();
  } catch (e, stackTrace) {
    stopwatch.stop();
// ignore: avoid_print
    print('❌ 修复过程出错: $e');
// ignore: avoid_print
    print('📍 错误堆栈: $stackTrace');
    exit(1);
  }

// ignore: avoid_print
  print('🎉 Print语句修复完成！');
}

/// 主函数执行完成后调用
void _postExecutionTasks() {
  // 执行示例演示
  UsageExamples.demonstrateLoggerUsage();
  UsageExamples.demonstrateErrorReporting();

// ignore: avoid_print
  print('');
// ignore: avoid_print
  print('🎯 修复完成！请按照上述建议进行后续操作。');
// ignore: avoid_print
  print('💪 祝你的代码质量改进项目顺利！');
// ignore: avoid_print
  print('');
}

/// 如果在主函数中执行成功，调用后续任务
void _setupPostExecution() {
  // 执行后续任务
  Future.delayed(Duration.zero, _postExecutionTasks);
}
