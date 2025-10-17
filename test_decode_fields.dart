import 'dart:convert';

void main() {
  // 解码API返回的UTF-8编码字段名
  final encodedFields = [
    'åå¼æ¥æ', // 日期字段
    'ç´¯è®¡åå¼', // 累计净值
    'åä½åå¼', // 单位净值
    'æ¥å¢é¿ç', // 日增长率
    'æ¥åæ¥æ', // 报告日期
    'åç±»åæå-æ¯æ¥è¿ä¸ææå', // 同类排名-每日近一月排名
    'æ»æå-æ¯æ¥è¿ä¸ææå' // 总排名-每日近一月排名
  ];

  print('🔍 UTF-8字段名解码结果:');
  print('=' * 50);

  for (final encoded in encodedFields) {
    try {
      // 尝试UTF-8解码
      final bytes = encoded.codeUnits;
      final decoded = utf8.decode(bytes);
      print('$encoded -> $decoded');
    } catch (e) {
      print('$encoded -> 解码失败: $e');
    }
  }

  print('\n🎯 正确的字段映射:');
  print('=' * 50);
  print('日期字段: 净值日期');
  print('累计净值: 累计净值');
  print('单位净值: 单位净值');
  print('日增长率: 日增长率');
  print('报告日期: 报告日期');
  print('同类排名: 同类排名-每日近一月排名');
  print('总排名: 总排名-每日近一月排名');
}
