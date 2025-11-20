/// 简化版市场数据UI演示
/// 命令行版本，模拟UI界面展示

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class SimpleUIDemo {
  static const String baseUrl = 'http://154.44.25.92:8080';

  /// 模拟UI界面
  static Future<void> showUIDemo() async {
    print('🎨 基速基金 - 市场历史数据UI演示');
    print('=' * 70);
    print('');

    // 显示控制面板
    _showControlPanel();

    // 显示实时数据面板
    await _showRealtimePanel();

    print('\n' + '-' * 70);

    // 显示历史数据面板
    await _showHistoryPanel();

    print('\n' + '-' * 70);

    // 显示分时数据面板
    await _showIntradayPanel();

    print('\n' + '=' * 70);
    print('✅ UI演示完成！');
  }

  /// 显示控制面板
  static void _showControlPanel() {
    print('📱 控制面板');
    print(
        '┌─────────────────────────────────────────────────────────────────────────┐');
    print('│  [选择指数] [上证指数 ▼] [数据源] [东方财富 ▼] [刷新数据] [🔄]           │');
    print('│  [交易状态] 🟢 尾盘交易中 (15:00前) [数据更新] 2025-11-14 15:00             │');
    print(
        '└─────────────────────────────────────────────────────────────────────────┘');
    print('');

    // 显示股票指数选项
    print('📊 支持的指数:');
    print('   ✅ 000001 - 上证指数');
    print('   ✅ 399001 - 深证成指');
    print('   ✅ 399006 - 创业板指');
    print('   ✅ 000300 - 沪深300');
    print('   ✅ 000688 - 科创50');
    print('   ✅ 399005 - 中小板指');
    print('');

    // 显示数据源选项
    print('📡 可用的数据源:');
    print('   🏢 东方财富 - 实时+历史+分时数据');
    print('   🌐 新浪财经 - 实时+历史数据');
    print('   📹 腾讯财经 - 实时+历史数据');
    print('');
  }

  /// 显示实时数据面板
  static Future<void> _showRealtimePanel() async {
    print('📈 实时数据面板');
    print(
        '┌─────────────────────────────────────────────────────────────────────────┐');

    // 检查交易时间
    final now = DateTime.now();
    final isTradingTime = _isTradingTime(now);

    if (!isTradingTime) {
      print('│  ⚠️  当前时间: ${_formatTime(now)} - A股市场休市中                    │');
      print('│  💡  实时数据仅在交易时段可用 (工作日 9:30-11:30, 13:00-15:00)        │');
      print('│  🔧  建议使用历史数据查看最新行情                                     │');
    }

    print(
        '└─────────────────────────────────────────────────────────────────────────┘');

    // 获取并显示实时数据
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/public/stock_zh_index_spot_em'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        print('🟢 实时指数数据 (${data.length}条):');

        // 模拟表格显示
        print(
            '┌─────────────────────────────────────────────────────────────────────────┐');
        print('│ 序号  代码      名称          最新价      涨跌幅      成交额     │');
        print(
            '├─────────────────────────────────────────────────────────────────────────┤');

        int count = 0;
        for (final item in data.take(10)) {
          count++;
          final code = item['代码']?.toString() ?? 'N/A';
          final name = item['名称']?.toString() ?? 'N/A';
          final price = item['最新价']?.toString() ?? '0.00';
          final change = item['涨跌幅']?.toString() ?? '0.00';
          final amount = item['成交额']?.toString() ?? '0';

          // 格式化输出
          print(
              '│ ${count.toString().padLeft(2)} ${code.padLeft(8)} ${name.padLeft(8)} ${price.padLeft(8)} ${change.padRight(6)} ${_formatAmount(amount).padRight(8)} │');
        }

        print(
            '└─────────────────────────────────────────────────────────────────────────┘');
        print('💡 显示前10条数据，完整数据请参考控制面板选择');
      } else {
        print('❌ HTTP ${response.statusCode}: 实时数据获取失败');
      }
    } catch (e) {
      print('❌ 获取实时数据失败: $e');
    }
  }

  /// 显示历史数据面板
  static Future<void> _showHistoryPanel() async {
    print('📊 历史数据面板');
    print(
        '┌─────────────────────────────────────────────────────────────────────────┐');

    // 测试不同数据源
    const dataSources = [
      {
        'name': '东方财富',
        'api': '/api/public/stock_zh_index_daily_em',
        'symbol': 'sz399812'
      },
      {
        'name': '新浪财经',
        'api': '/api/public/stock_zh_index_daily',
        'symbol': 'sz399552'
      },
      {
        'name': '腾讯财经',
        'api': '/api/public/stock_zh_index_daily_tx',
        'symbol': 'sh000919'
      },
    ];

    for (final source in dataSources) {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl${source['api']}?symbol=${source['symbol']}'),
          headers: {'Accept': 'application/json'},
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as List;
          print('│ 🟢 ${source['name']}: ${data.length}条历史数据');

          if (data.isNotEmpty) {
            final first = data.first;
            final last = data.last;

            print(
                '│    📅 数据范围: ${first['date'].toString().split('T')[0]} -> ${last['date'].toString().split('T')[0]}');
            print('│    💰 价格区间: ${first['close']} -> ${last['close']}');

            // 显示最近几条数据
            print('│    📈 最新数据:');
            for (int i = (data.length > 3 ? data.length - 3 : 0);
                i < data.length;
                i++) {
              final item = data[i];
              final date = item['date'].toString().split('T')[0];
              final open = item['open']?.toString() ?? '0.00';
              final close = item['close']?.toString() ?? '0.00';
              print('│      ${date}: 开盘=${open} 收盘=${close}');
            }
          }
        } else {
          print('│ ❌ ${source['name']}: HTTP ${response.statusCode}');
        }
      } catch (e) {
        print('│ ❌ ${source['name']}: 获取失败 - $e');
      }
    }

    print(
        '└─────────────────────────────────────────────────────────────────────────┘');
  }

  /// 显示分时数据面板
  static Future<void> _showIntradayPanel() async {
    print('⏰ 分时数据面板');
    print(
        '┌─────────────────────────────────────────────────────────────────────────┐');

    final now = DateTime.now();
    final isTradingTime = _isTradingTime(now);

    if (!isTradingTime) {
      print('│ ⚠️ 当前时间: ${_formatTime(now)} - 非交易时段                        │');
      print('│ 💡 分时数据仅在交易时段可用                                   │');
    }

    try {
      // 使用历史日期确保有数据
      final targetDate = DateTime(2024, 12, 13);
      final startTime =
          "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')} 10:00:00";
      final endTime =
          "${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')} 15:00:00";

      final response = await http.get(
        Uri.parse(
            '$baseUrl/api/public/index_zh_a_hist_min_em?symbol=000001&period=5&start_date=$startTime&end_date=$endTime'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        print('│ 🟢 5分钟分时数据: ${data.length}条');

        if (data.isNotEmpty) {
          print('│ 📅 时间范围: ${data.first['时间']} -> ${data.last['时间']}');
          print('│ 💰 价格区间: ${data.first['收盘']} -> ${data.last['收盘']}');

          print('│ 📈 分时详情 (最后5条):');
          final startIndex = (data.length > 5) ? data.length - 5 : 0;
          for (int i = startIndex; i < data.length; i++) {
            final item = data[i];
            final time = item['时间']?.toString() ?? 'N/A';
            final open = item['开盘']?.toString() ?? '0.00';
            final close = item['收盘']?.toString() ?? '0.00';
            final volume = item['成交量']?.toString() ?? '0';

            print('│      ${time}: ${open} -> ${close} 成交量=${volume}');
          }
        } else {
          print('│ ⚠️ 分时数据为空（可能选择的日期无交易数据）');
        }
      } else {
        print('│ ❌ HTTP ${response.statusCode}: 分时数据获取失败');
      }
    } catch (e) {
      print('│ ❌ 获取分时数据失败: $e');
    }

    print(
        '└─────────────────────────────────────────────────────────────────────────┘');
  }

  /// 检查是否为交易时间
  static bool _isTradingTime(DateTime date) {
    if (date.weekday < 1 || date.weekday > 5) return false; // 周末

    final hour = date.hour;
    final minute = date.minute;

    // 早盘: 9:30-11:30
    if ((hour == 9 && minute >= 30) ||
        (hour == 10) ||
        (hour == 11 && minute <= 30)) {
      return true;
    }

    // 尾盘: 13:00-15:00
    if ((hour == 13 && minute > 0) ||
        (hour == 14) ||
        (hour == 15 && minute == 0)) {
      return true;
    }

    return false;
  }

  /// 格式化时间
  static String _formatTime(DateTime date) {
    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final weekday = weekdays[date.weekday - 1];
    final timeStr =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return '$weekday $timeStr';
  }

  /// 格式化金额
  static String _formatAmount(String amount) {
    final num = double.tryParse(amount) ?? 0;
    if (num >= 1e12) {
      return '${(num / 1e12).toStringAsFixed(1)}万亿';
    } else if (num >= 1e8) {
      return '${(num / 1e8).toStringAsFixed(1)}亿';
    } else if (num >= 1e4) {
      return '${(num / 1e4).toStringAsFixed(1)}万';
    } else {
      return num.toStringAsFixed(2);
    }
  }
}

Future<void> main() async {
  await SimpleUIDemo.showUIDemo();
}
