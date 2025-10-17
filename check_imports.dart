import 'dart:io';

/// 检查项目中的导入问题
void main() {
// ignore: avoid_print
  print('=== 检查项目导入问题 ===');

  final projectRoot = Directory.current.path;
// ignore: avoid_print
  print('项目根目录: $projectRoot');

  // 获取所有dart文件
  final dartFiles = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList();

// ignore: avoid_print
  print('找到 ${dartFiles.length} 个Dart文件');

  // 检查每个文件的导入
  int importErrorCount = 0;

  for (final file in dartFiles) {
    try {
      final content = file.readAsStringSync();
      final lines = content.split('\n');

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.startsWith('import ') && trimmed.contains("'")) {
          final importPath = trimmed.substring(
              trimmed.indexOf("'") + 1, trimmed.lastIndexOf("'"));

          // 检查包导入
          if (importPath.startsWith('package:')) {
            // 跳过包导入检查
            continue;
          }

          // 检查相对路径导入
          if (importPath.startsWith('../') || importPath.startsWith('./')) {
            final fullPath = '${file.parent.path}/$importPath';
            final targetFile = File(fullPath);
            final targetDir = Directory(fullPath);

            if (!targetFile.existsSync() && !targetDir.existsSync()) {
// ignore: avoid_print
              print('❌ 文件不存在: ${file.path} 导入: $importPath');
              importErrorCount++;
            }
          }
        }
      }
    } catch (e) {
// ignore: avoid_print
      print('读取文件失败: ${file.path} - $e');
    }
  }

  if (importErrorCount == 0) {
// ignore: avoid_print
    print('✅ 未发现导入错误');
  } else {
// ignore: avoid_print
    print('发现 $importErrorCount 个导入错误');
  }

  // 检查缺失的文件
  checkMissingFiles();
}

void checkMissingFiles() {
// ignore: avoid_print
  print('\n=== 检查缺失的关键文件 ===');

  final requiredFiles = [
    'lib/main.dart',
    'lib/src/features/app/app.dart',
    'lib/src/features/navigation/presentation/pages/navigation_shell.dart',
    'lib/src/features/home/presentation/pages/dashboard_page.dart',
    'lib/src/features/fund/presentation/pages/fund_explorer_page.dart',
    'lib/src/features/fund/presentation/pages/watchlist_page.dart',
    'lib/src/features/settings/presentation/pages/settings_page.dart',
  ];

  for (final filePath in requiredFiles) {
    final file = File(filePath);
    if (file.existsSync()) {
// ignore: avoid_print
      print('✅ $filePath');
    } else {
// ignore: avoid_print
      print('❌ 缺失: $filePath');
    }
  }
}
