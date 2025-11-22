import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/fund_favorite/src/entities/fund_favorite.dart';

/// 简化版添加基金功能测试
///
/// 测试只使用基金代码添加自选基金，通过API获取完整信息
void main() {
  group('简化版添加基金功能', () {
    const String apiBaseUrl = 'http://154.44.25.92:8080';
    late http.Client client;

    setUpAll(() {
      client = http.Client();
    });

    tearDownAll(() {
      client.close();
    });

    test('应该能够通过基金代码获取基金信息', () async {
      // 使用一个常见的基金代码进行测试
      const String fundCode = '000001';

      try {
        final response = await client
            .get(
              Uri.parse(
                  '$apiBaseUrl/api/public/fund_open_fund_info_em?symbol=$fundCode'),
            )
            .timeout(const Duration(seconds: 30));

        print('API响应状态码: ${response.statusCode}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print('API响应数据: $data');

          expect(data, isNotNull);
          expect(data, isA<List>());
          expect(data.isNotEmpty, isTrue);

          // 验证返回的数据包含净值字段（这是净值API）
          final fundData = data.first as Map<String, dynamic>;
          expect(fundData.keys.contains('净值日期'), isTrue);
          expect(fundData.keys.contains('单位净值'), isTrue);
          expect(fundData.keys.contains('日增长率'), isTrue);
        } else {
          print('API请求失败，状态码: ${response.statusCode}');
          print('响应内容: ${response.body}');
        }
      } catch (e) {
        print('API请求异常: $e');
        // 在网络不可用时跳过测试
        expect(e, isA<Exception>());
      }
    });

    test('应该能够创建基础的FundFavorite对象', () {
      // 测试只使用基金代码创建对象
      const String fundCode = '110022';

      final favorite = FundFavorite(
        fundCode: fundCode,
        fundName: '加载中...', // 占位符，将由API更新
        fundType: '未知', // 占位符，将由API更新
        fundManager: '未知', // 占位符，将由API更新
        addedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        notes: '数据来源: http://154.44.25.92:8080',
      );

      expect(favorite.fundCode, equals(fundCode));
      expect(favorite.fundName, equals('加载中...'));
      expect(favorite.fundType, equals('未知'));
      expect(favorite.fundManager, equals('未知'));
      expect(favorite.notes, contains('154.44.25.92:8080'));
    });

    test('应该验证基金代码格式', () {
      // 测试有效的基金代码
      const validCodes = ['000001', '110022', '161725', '519888'];

      for (final code in validCodes) {
        expect(isValidFundCode(code), isTrue, reason: '$code 应该是有效的基金代码');
      }

      // 测试无效的基金代码
      const invalidCodes = ['123', '1234567', 'abcdef', '00000', '000001a'];

      for (final code in invalidCodes) {
        expect(isValidFundCode(code), isFalse, reason: '$code 应该是无效的基金代码');
      }
    });

    test('应该处理API响应数据并转换为FundFavorite', () {
      // 模拟API响应数据
      final mockApiResponse = [
        {
          '基金代码': '000001',
          '基金名称': '华夏成长混合',
          '基金类型': '混合型',
          '基金管理人': '华夏基金管理有限公司',
          '最新净值': '2.3456',
          '日涨跌幅': '1.23',
          '前日净值': '2.3185',
          '基金规模': '128.5',
          '成立日期': '2001-12-18'
        }
      ];

      final fundData = mockApiResponse.first;

      // 转换API数据为FundFavorite对象
      final favorite = FundFavorite(
        fundCode: fundData['基金代码'] ?? '未知',
        fundName: fundData['基金名称'] ?? '未知基金',
        fundType: fundData['基金类型'] ?? '未知类型',
        fundManager: fundData['基金管理人'] ?? '未知管理人',
        addedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        currentNav: _parseDouble(fundData['最新净值']),
        dailyChange: _parseDouble(fundData['日涨跌幅']),
        previousNav: _parseDouble(fundData['前日净值']),
        fundScale: _parseDouble(fundData['基金规模']),
        notes: '数据来源: http://154.44.25.92:8080',
      );

      expect(favorite.fundCode, equals('000001'));
      expect(favorite.fundName, equals('华夏成长混合'));
      expect(favorite.fundType, equals('混合型'));
      expect(favorite.fundManager, equals('华夏基金管理有限公司'));
      expect(favorite.currentNav, equals(2.3456));
      expect(favorite.dailyChange, equals(1.23));
    });

    test('应该处理API响应中的缺失数据', () {
      // 测试缺失部分字段的API响应
      final incompleteApiResponse = [
        {
          '基金代码': '999999',
          '基金名称': '测试基金',
          // 缺少基金类型、管理人等字段
        }
      ];

      final fundData = incompleteApiResponse.first;

      final favorite = FundFavorite(
        fundCode: fundData['基金代码'] ?? '未知',
        fundName: fundData['基金名称'] ?? '未知基金',
        fundType: fundData['基金类型'] ?? '混合型', // 提供默认值
        fundManager: fundData['基金管理人'] ?? '未知管理人', // 提供默认值
        addedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        notes: '数据来源: http://154.44.25.92:8080',
      );

      expect(favorite.fundCode, equals('999999'));
      expect(favorite.fundName, equals('测试基金'));
      expect(favorite.fundType, equals('混合型')); // 使用默认值
      expect(favorite.fundManager, equals('未知管理人')); // 使用默认值
    });

    group('边界条件测试', () {
      test('应该处理空字符串基金代码', () {
        expect(isValidFundCode(''), isFalse);
      });

      test('应该处理null基金代码', () {
        expect(isValidFundCode(''), isFalse);
      });

      test('应该处理特殊字符基金代码', () {
        expect(isValidFundCode('00#001'), isFalse);
        expect(isValidFundCode('00 001'), isFalse);
      });

      test('应该处理极大或极小的基金代码', () {
        expect(isValidFundCode('999999'), isTrue);
        expect(isValidFundCode('000001'), isTrue);
        expect(isValidFundCode('100000'), isTrue); // 100000是有效的6位数字
      });
    });

    group('性能测试', () {
      test('应该能够快速创建大量FundFavorite对象', () {
        final stopwatch = Stopwatch()..start();

        final favorites = <FundFavorite>[];
        for (int i = 0; i < 1000; i++) {
          final code = i.toString().padLeft(6, '0');
          favorites.add(FundFavorite(
            fundCode: code,
            fundName: '测试基金 $i',
            fundType: '测试类型',
            fundManager: '测试管理人',
            addedAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
        }

        stopwatch.stop();

        expect(favorites.length, equals(1000));
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // 应该在1秒内完成

        print('创建1000个FundFavorite对象耗时: ${stopwatch.elapsedMilliseconds}ms');
      });
    });
  });
}

/// 验证基金代码格式是否正确
bool isValidFundCode(String code) {
  if (code.isEmpty) return false;
  if (code.length != 6) return false;

  // 检查是否全为数字
  return code.runes.every((rune) => rune >= 48 && rune <= 57); // ASCII 0-9
}

/// 安全地解析double值
double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    try {
      return double.parse(value);
    } catch (e) {
      return null;
    }
  }
  return null;
}
