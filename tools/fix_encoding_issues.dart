import 'dart:io';

/// 修复编码问题的快速脚本
void main() async {
// ignore: avoid_print
  print('🔧 开始修复编码问题...');

  final filesWithIssues = [
    'lib/src/core/di/sql_server_injection_container.dart',
    'lib/src/core/services/market_real_service.dart',
    'lib/src/features/home/presentation/widgets/enhanced_market_overview_v2.dart',
    'lib/src/features/home/presentation/widgets/enhanced_market_real.dart',
    'lib/src/features/home/presentation/widgets/market_today_overview.dart',
    'lib/src/features/market/data/services/sector_realtime_service.dart',
  ];

  for (final filePath in filesWithIssues) {
    await _fixFile(filePath);
  }

// ignore: avoid_print
  print('✅ 编码问题修复完成！');
}

Future<void> _fixFile(String filePath) async {
  try {
    final file = File(filePath);
    if (!file.existsSync()) {
// ignore: avoid_print
      print('⚠️ 文件不存在: $filePath');
      return;
    }

// ignore: avoid_print
    print('📄 修复: $filePath');

    String content = await file.readAsString();
    String originalContent = content;

    // 修复特定的编码问题
    content = _fixSpecificIssues(content, filePath);

    if (content != originalContent) {
      await file.writeAsString(content);
// ignore: avoid_print
      print('  ✅ 已修复');
    } else {
// ignore: avoid_print
      print('  ✨ 无需修复');
    }
  } catch (e) {
// ignore: avoid_print
    print('  ❌ 修复失败: $e');
  }
}

String _fixSpecificIssues(String content, String filePath) {
  final fixes = {
    // SQL Server注入容器
    'lib/src/core/di/sql_server_injection_container.dart': [
      ["数据库初始化失败: \$e", "数据库初始化失败: \$e"],
      ["数据库连接测试失败: \$e", "数据库连接测试失败: \$e"],
      ["数据库连接关闭失败: \$e", "数据库连接关闭失败: \$e"],
    ],
    // 市场实时服务
    'lib/src/core/services/market_real_service.dart': [
      ["获取实时指数数据失败: \$e", "获取实时指数数据失败: \$e"],
    ],
    // 其他文件类似处理
  };

  final fileFixes = fixes[filePath];
  if (fileFixes != null) {
    for (final fix in fileFixes) {
      content = content.replaceAll(fix[0], fix[1]);
    }
  }

  // 通用修复：移除多余的中文引号
  content = content.replaceAll("''", "'");

  // 修复AppLogger调用中的转义问题
  content = content.replaceAllMapped(
    RegExp(r"AppLogger\.\w+\(''([^']+)';'\)"),
    (match) {
      final message = match.group(1)!;
      final method = match.group(0)!.split('(')[0];
      return "$method('$message')";
    },
  );

  return content;
}
