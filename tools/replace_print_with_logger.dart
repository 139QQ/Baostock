import 'dart:io';

/// 批量替换print语句为logger语句的工具脚本
void main() async {
  final file = File('lib/src/core/cache/hive_cache_manager.dart');

  if (!await file.exists()) {
    print('文件不存在: ${file.path}');
    return;
  }

  String content = await file.readAsString();

  // 替换规则映射
  final replacements = {
    "print('缓存编码修复失败: \$e')": "AppLogger.warn('缓存编码修复失败', e)",
    "print('缓存读取失败: \$e')": "AppLogger.error('缓存读取失败', e)",
    "print('分页元数据编码修复失败: \$e')": "AppLogger.warn('分页元数据编码修复失败', e)",
    "print('⚠️ 分页数据缺失: \$pageKey')": "AppLogger.warn('分页数据缺失', pageKey)",
    "print('分页数据编码修复失败: \$e')": "AppLogger.warn('分页数据编码修复失败', e)",
    "print('📖 读取分页缓存: 第\${startPage + 1}-\${endPage + 1}页，返回 \${result.length} 条记录')":
        "AppLogger.database('读取分页缓存', _fundBoxName, '第\${startPage + 1}-\${endPage + 1}页，返回 \${result.length} 条记录')",
    "print('分页缓存读取失败: \$e')": "AppLogger.error('分页缓存读取失败', e)",
    "print('🗑️ 已清理过期的分页缓存: \$key')":
        "AppLogger.database('清理过期分页缓存', _fundBoxName, key)",
    "print('清理分页缓存失败: \$e')": "AppLogger.error('清理分页缓存失败', e)",
    "print('排行榜缓存编码修复失败: \$e')": "AppLogger.warn('排行榜缓存编码修复失败', e)",
    "print('排行榜缓存读取失败: \$e')": "AppLogger.error('排行榜缓存读取失败', e)",
    "print('✅ 所有缓存已清理')": "AppLogger.database('清理所有缓存', 'cache_manager', '完成')",
    "print('🧹 开始清理过期缓存，批次大小: \$batchSize')":
        "AppLogger.database('开始清理过期缓存', 'cache_manager', '批次大小: \$batchSize')",
    "print('📦 \$cacheName: 无数据需要清理')":
        "AppLogger.debug('\$cacheName: 无数据需要清理')",
    "print('📦 \$cacheName: 开始清理 \$totalKeys 条缓存记录')":
        "AppLogger.database('开始清理缓存', cacheName, '\$totalKeys 条记录')",
    "print('🗑️ \$cacheName: 批量删除 \${keysToDelete.length} 条过期记录')":
        "AppLogger.database('批量删除过期记录', cacheName, '\${keysToDelete.length} 条')",
    "print('⏳ \$cacheName: 已处理 \$processedCount/\$totalKeys 条记录')":
        "AppLogger.debug('清理进度', cacheName, '\$processedCount/\$totalKeys 条记录')",
    "print('✅ \$cacheName: 清理完成，共处理 \$processedCount 条记录')":
        "AppLogger.database('清理完成', cacheName, '共处理 \$processedCount 条记录')",
    "print('❌ \$cacheName 清理失败: \$e')":
        "AppLogger.error('\$cacheName 清理失败', e)",
    "print('❌ 批量删除失败: \$e')": "AppLogger.error('批量删除失败', e)",
    "print('❌ 删除键 \$key 失败: \$e')": "AppLogger.error('删除键失败', e, 'key: \$key')",
    "print('统计分页缓存失败: \$e')": "AppLogger.warn('统计分页缓存失败', e)",
  };

  // 应用替换
  for (final entry in replacements.entries) {
    content = content.replaceAll(entry.key, entry.value);
  }

  // 写回文件
  await file.writeAsString(content);
  print('替换完成: ${file.path}');
}
