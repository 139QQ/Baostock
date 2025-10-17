import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'dart:convert';

/// 基金排行API专项测试
/// 测试网络请求、超时设置、分页加载等功能
void main() {
  group('基金排行API专项测试', () {
    late Dio dio;

    setUp(() {
      // 创建Dio客户端，配置超时参数
      dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 30);
      dio.options.receiveTimeout = const Duration(seconds: 90);
      dio.options.sendTimeout = const Duration(seconds: 30);

      // 添加拦截器用于调试
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
// ignore: avoid_print
        logPrint: (log) => print('📝 Dio: $log'),
      ));
    });

    test('测试基金排行API连接和响应时间', () async {
// ignore: avoid_print
      print('🔄 开始测试基金排行API连接...');

      final stopwatch = Stopwatch()..start();

      try {
        // 测试小批量数据请求
        final response = await dio.get(
          'http://154.44.25.92:8080/api/public/fund_open_fund_rank_em',
          queryParameters: {
            'symbol': '全部',
            'page': 1,
            'pageSize': 50, // 小批量测试
          },
        );

        stopwatch.stop();

// ignore: avoid_print
        print('✅ API连接成功！');
// ignore: avoid_print
        print('⏱️  响应时间: ${stopwatch.elapsedMilliseconds}ms');
// ignore: avoid_print
        print('📊 状态码: ${response.statusCode}');
// ignore: avoid_print
        print('📦 数据大小: ${response.data.toString().length} 字符');

        // 验证响应数据
        expect(response.statusCode, equals(200));
        expect(response.data, isNotNull);

        // 尝试解析JSON
        final data = response.data;
        if (data is String) {
          final parsed = jsonDecode(data);
// ignore: avoid_print
          print('🔍 解析后的数据类型: ${parsed.runtimeType}');
          if (parsed is List) {
// ignore: avoid_print
            print('📋 数据条数: ${parsed.length}');
            if (parsed.isNotEmpty) {
// ignore: avoid_print
              print('📝 第一条数据示例: ${parsed[0]}');
            }
          }
        } else if (data is List) {
// ignore: avoid_print
          print('📋 数据条数: ${data.length}');
          if (data.isNotEmpty) {
// ignore: avoid_print
            print('📝 第一条数据示例: ${data[0]}');
          }
        }
      } catch (e) {
// ignore: avoid_print
        print('❌ API连接失败: $e');
// ignore: avoid_print
        print('⏱️  失败时间: ${stopwatch.elapsedMilliseconds}ms');
        fail('基金排行API连接失败: $e');
      }
    });

    test('测试大批量数据请求超时处理', () async {
// ignore: avoid_print
      print('🔄 开始测试大批量数据请求...');

      final stopwatch = Stopwatch()..start();

      try {
        // 测试大批量数据请求（可能导致超时）
        final response = await dio.get(
          'http://154.44.25.92:8080/api/public/fund_open_fund_rank_em',
          queryParameters: {
            'symbol': '全部',
            'page': 1,
            'pageSize': 2000, // 大批量测试
          },
        );

        stopwatch.stop();

// ignore: avoid_print
        print('✅ 大批量数据请求成功！');
// ignore: avoid_print
        print('⏱️  响应时间: ${stopwatch.elapsedMilliseconds}ms');
// ignore: avoid_print
        print('📦 数据大小: ${response.data.toString().length} 字符');

        expect(response.statusCode, equals(200));
      } catch (e) {
        stopwatch.stop();
// ignore: avoid_print
        print('⚠️ 大批量数据请求失败（预期内）: $e');
// ignore: avoid_print
        print('⏱️  失败时间: ${stopwatch.elapsedMilliseconds}ms');

        // 如果是超时错误，这是可以接受的
        if (e.toString().contains('timeout') ||
            e.toString().contains('Timeout') ||
            e.toString().contains('connection')) {
// ignore: avoid_print
          print('⏰ 检测到超时或连接问题，这是预期的测试结果');
        } else {
          fail('意外的错误类型: $e');
        }
      }
    });

    test('测试分页加载策略', () async {
// ignore: avoid_print
      print('🔄 开始测试分页加载策略...');

      final pageSizes = [50, 100, 500, 1000];
      final results = <Map<String, dynamic>>[];

      for (final pageSize in pageSizes) {
// ignore: avoid_print
        print('📄 测试每页 $pageSize 条数据...');

        final stopwatch = Stopwatch()..start();

        try {
          final response = await dio.get(
            'http://154.44.25.92:8080/api/public/fund_open_fund_rank_em',
            queryParameters: {
              'symbol': '全部',
              'page': 1,
              'pageSize': pageSize,
            },
          );

          stopwatch.stop();

          final success = response.statusCode == 200;
          final responseTime = stopwatch.elapsedMilliseconds;

          results.add({
            'pageSize': pageSize,
            'success': success,
            'responseTime': responseTime,
            'dataSize': response.data?.toString().length ?? 0,
          });

// ignore: avoid_print
          print('✅ 页面大小: $pageSize, 响应时间: ${responseTime}ms, 成功: $success');
        } catch (e) {
          stopwatch.stop();

          results.add({
            'pageSize': pageSize,
            'success': false,
            'responseTime': stopwatch.elapsedMilliseconds,
            'error': e.toString(),
          });

// ignore: avoid_print
          print(
              '❌ 页面大小: $pageSize, 响应时间: ${stopwatch.elapsedMilliseconds}ms, 错误: $e');
        }
      }

      // 分析最佳页面大小
// ignore: avoid_print
      print('\n📊 分页测试结果分析:');
      for (final result in results) {
        final status = result['success'] ? '✅' : '❌';
        final pageSize = result['pageSize'];
        final time = result['responseTime'];
// ignore: avoid_print
        print('$status 页面大小: $pageSize, 响应时间: ${time}ms');
      }

      // 推荐最佳页面大小
      final successfulResults = results.where((r) => r['success']).toList();
      if (successfulResults.isNotEmpty) {
        successfulResults
            .sort((a, b) => a['responseTime'].compareTo(b['responseTime']));
        final best = successfulResults.first;
// ignore: avoid_print
        print(
            '\n🏆 推荐页面大小: ${best['pageSize']} (响应时间: ${best['responseTime']}ms)');
      }
    });

    test('测试网络超时配置', () async {
// ignore: avoid_print
      print('🔄 开始测试网络超时配置...');

      // 创建短超时的Dio客户端
      final shortTimeoutDio = Dio();
      shortTimeoutDio.options.connectTimeout = const Duration(seconds: 1);
      shortTimeoutDio.options.receiveTimeout = const Duration(seconds: 2);

      final stopwatch = Stopwatch()..start();

      try {
        final response = await shortTimeoutDio.get(
          'http://154.44.25.92:8080/api/public/fund_open_fund_rank_em',
          queryParameters: {
            'symbol': '全部',
            'pageSize': 1000,
          },
        );

        stopwatch.stop();
// ignore: avoid_print
        print('⚠️ 短超时测试意外成功，响应时间: ${stopwatch.elapsedMilliseconds}ms');
      } catch (e) {
        stopwatch.stop();
// ignore: avoid_print
        print('✅ 短超时测试成功触发超时: ${stopwatch.elapsedMilliseconds}ms');
// ignore: avoid_print
        print('📝 错误类型: $e');

        expect(e.toString(), contains('timeout'));
      }

      // 对比正常超时配置
      final normalStopwatch = Stopwatch()..start();

      try {
        final response = await dio.get(
          'http://154.44.25.92:8080/api/public/fund_open_fund_rank_em',
          queryParameters: {
            'symbol': '全部',
            'pageSize': 100,
          },
        );

        normalStopwatch.stop();
// ignore: avoid_print
        print('✅ 正常超时配置测试成功，响应时间: ${normalStopwatch.elapsedMilliseconds}ms');
      } catch (e) {
        normalStopwatch.stop();
// ignore: avoid_print
        print('❌ 正常超时配置测试失败，响应时间: ${normalStopwatch.elapsedMilliseconds}ms');
// ignore: avoid_print
        print('📝 错误: $e');
      }
    });
  });
}
