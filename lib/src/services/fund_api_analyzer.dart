import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

/// 基金API分析服务
/// 用于获取基金API的详细信息和统计数据
class FundApiAnalyzer {
  static final FundApiAnalyzer _instance = FundApiAnalyzer._internal();
  factory FundApiAnalyzer() => _instance;
  FundApiAnalyzer._internal();

  static const String _apiUrl =
      'http://154.44.25.92:8080/api/public/fund_name_em';
  final Dio _dio = Dio();
  final Logger _logger = Logger();

  /// 获取基金API统计信息
  Future<Map<String, dynamic>> getApiStatistics() async {
    try {
      _logger.i('🔍 开始获取基金API统计信息...');

      final stopwatch = Stopwatch()..start();
      final response = await _dio.get(_apiUrl);
      stopwatch.stop();

      if (response.statusCode == 200) {
        final responseData = response.data;
        Map<String, dynamic> statistics = {};

        // 分析响应结构
        if (responseData is List) {
          statistics = {
            'totalFunds': responseData.length,
            'responseType': 'direct_array',
            'responseTime': stopwatch.elapsedMilliseconds,
            'dataSize': response.data.toString().length,
            'apiUrl': _apiUrl,
            'status': 'success',
            'timestamp': DateTime.now().toIso8601String(),
          };

          // 分析基金类型分布
          final fundTypeDistribution =
              _analyzeFundTypeDistribution(responseData);
          statistics['fundTypeDistribution'] = fundTypeDistribution;

          // 分析基金代码分布
          final codeDistribution = _analyzeCodeDistribution(responseData);
          statistics['codeDistribution'] = codeDistribution;
        } else if (responseData is Map) {
          statistics = {
            'responseType': 'object',
            'responseTime': stopwatch.elapsedMilliseconds,
            'dataSize': response.data.toString().length,
            'apiUrl': _apiUrl,
            'status': 'success',
            'timestamp': DateTime.now().toIso8601String(),
            'keys': responseData.keys.toList(),
          };

          // 查找总数字段
          final totalFields = ['total', 'count', 'totalCount', 'total_count'];
          for (final field in totalFields) {
            if (responseData.containsKey(field)) {
              statistics['totalFunds'] = responseData[field];
              break;
            }
          }

          // 检查data字段
          if (responseData.containsKey('data')) {
            final data = responseData['data'];
            if (data is List) {
              statistics['totalFunds'] = data.length;
              final fundTypeDistribution = _analyzeFundTypeDistribution(data);
              statistics['fundTypeDistribution'] = fundTypeDistribution;
            }
          }
        }

        _logger.i('✅ API统计信息获取完成');
        _logger.i('📊 总基金数量: ${statistics['totalFunds']} 只');
        _logger.i('⏱️ 响应时间: ${statistics['responseTime']}ms');

        return statistics;
      } else {
        throw Exception(
            'HTTP ${response.statusCode}: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('❌ 获取API统计信息失败: $e');
      return {
        'status': 'error',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// 分析基金类型分布
  Map<String, int> _analyzeFundTypeDistribution(List<dynamic> fundData) {
    final Map<String, int> distribution = {};

    for (final fund in fundData) {
      if (fund is Map<String, dynamic>) {
        String fundType = fund['基金类型'] ?? '未知类型';

        // 简化类型名称
        String simplifiedType = _simplifyFundType(fundType);

        distribution[simplifiedType] = (distribution[simplifiedType] ?? 0) + 1;
      }
    }

    return distribution;
  }

  /// 分析基金代码分布
  Map<String, int> _analyzeCodeDistribution(List<dynamic> fundData) {
    final Map<String, int> distribution = {
      '以0开头': 0,
      '以1开头': 0,
      '以5开头': 0,
      '以9开头': 0,
      '其他': 0,
    };

    for (final fund in fundData) {
      if (fund is Map<String, dynamic>) {
        String? code = fund['基金代码'];
        if (code != null && code.isNotEmpty) {
          String firstChar = code[0];
          switch (firstChar) {
            case '0':
              distribution['以0开头'] = (distribution['以0开头'] ?? 0) + 1;
              break;
            case '1':
              distribution['以1开头'] = (distribution['以1开头'] ?? 0) + 1;
              break;
            case '5':
              distribution['以5开头'] = (distribution['以5开头'] ?? 0) + 1;
              break;
            case '9':
              distribution['以9开头'] = (distribution['以9开头'] ?? 0) + 1;
              break;
            default:
              distribution['其他'] = (distribution['其他'] ?? 0) + 1;
          }
        }
      }
    }

    return distribution;
  }

  /// 简化基金类型名称
  String _simplifyFundType(String fundType) {
    // 移除后缀信息
    String simplified = fundType.split('-')[0];

    // 映射常见类型
    final typeMapping = {
      '混合型': '混合型',
      '债券型': '债券型',
      '股票型': '股票型',
      '货币型': '货币型',
      '指数型': '指数型',
      'QDII': 'QDII',
      'FOF': 'FOF',
    };

    for (final key in typeMapping.keys) {
      if (simplified.contains(key)) {
        return typeMapping[key]!;
      }
    }

    return simplified.isEmpty ? '其他类型' : simplified;
  }

  /// 验证API连通性
  Future<bool> validateApiConnection() async {
    try {
      _logger.d('🔍 验证API连通性...');

      final response = await _dio.get(
        _apiUrl,
        options: Options(
          receiveTimeout: const Duration(seconds: 120),
        ),
      );

      bool isConnected = response.statusCode == 200;
      _logger.d('API连通性: ${isConnected ? "✅ 正常" : "❌ 异常"}');

      return isConnected;
    } catch (e) {
      _logger.e('❌ API连通性验证失败: $e');
      return false;
    }
  }

  /// 获取API健康状态
  Future<Map<String, dynamic>> getApiHealthStatus() async {
    final stopwatch = Stopwatch()..start();

    try {
      final isConnected = await validateApiConnection();
      stopwatch.stop();

      if (isConnected) {
        final statistics = await getApiStatistics();
        return {
          'status': 'healthy',
          'connectionTime': stopwatch.elapsedMilliseconds,
          'totalFunds': statistics['totalFunds'],
          'lastChecked': DateTime.now().toIso8601String(),
          'apiUrl': _apiUrl,
        };
      } else {
        return {
          'status': 'unhealthy',
          'connectionTime': stopwatch.elapsedMilliseconds,
          'error': 'API连接失败',
          'lastChecked': DateTime.now().toIso8601String(),
          'apiUrl': _apiUrl,
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
        'lastChecked': DateTime.now().toIso8601String(),
        'apiUrl': _apiUrl,
      };
    }
  }

  /// 通过基金代码获取基金基本信息
  Future<Map<String, String>?> getFundBasicInfo(String fundCode) async {
    try {
      _logger.i('🔍 正在查询基金基本信息: $fundCode');

      final stopwatch = Stopwatch()..start();

      // 获取所有基金列表
      final response = await _dio.get(
        _apiUrl,
        options: Options(
          receiveTimeout: const Duration(seconds: 120),
          headers: {
            'Accept': 'application/json; charset=utf-8',
            'Content-Type': 'application/json; charset=utf-8',
          },
        ),
      );
      stopwatch.stop();

      if (response.statusCode == 200) {
        final List<dynamic> fundData = response.data;
        _logger.d('基金列表API返回数据量: ${fundData.length}条');

        // 在基金列表中查找目标基金
        for (final fund in fundData) {
          if (fund is Map<String, dynamic>) {
            final code = fund['基金代码']?.toString();
            if (code == fundCode) {
              final result = {
                'fund_code': fund['基金代码']?.toString() ?? '',
                'fund_name': fund['基金简称']?.toString() ?? '',
                'fund_type': fund['基金类型']?.toString() ?? '未知类型',
                'fund_manager': fund['基金经理']?.toString() ?? '未知经理',
                'fund_company': fund['基金管理人']?.toString() ?? '',
                'fund_custodian': fund['基金托管人']?.toString() ?? '',
                'establish_date': fund['成立日期']?.toString() ?? '',
                'management_fee': fund['管理费率']?.toString() ?? '',
                'custody_fee': fund['托管费率']?.toString() ?? '',
              };

              _logger.i('✅ 找到基金信息: ${result['fund_name']}');
              _logger.d('⏱️ 查询耗时: ${stopwatch.elapsedMilliseconds}ms');

              return result;
            }
          }
        }

        _logger.w('❌ 未找到基金代码: $fundCode');
        return null;
      } else {
        throw Exception(
            'HTTP ${response.statusCode}: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('❌ 查询基金基本信息失败: $e');
      return null;
    }
  }

  /// 批量获取基金基本信息
  Future<Map<String, Map<String, String>>> getBatchFundBasicInfo(
      List<String> fundCodes) async {
    try {
      _logger.i('🔍 正在批量查询基金基本信息: ${fundCodes.length}个基金');

      final stopwatch = Stopwatch()..start();

      // 获取所有基金列表
      final response = await _dio.get(
        _apiUrl,
        options: Options(
          receiveTimeout: const Duration(seconds: 120),
          headers: {
            'Accept': 'application/json; charset=utf-8',
            'Content-Type': 'application/json; charset=utf-8',
          },
        ),
      );
      stopwatch.stop();

      if (response.statusCode == 200) {
        final List<dynamic> fundData = response.data;
        final Map<String, Map<String, String>> results = {};

        // 构建基金代码到基金信息的映射
        for (final fund in fundData) {
          if (fund is Map<String, dynamic>) {
            final code = fund['基金代码']?.toString();
            if (code != null && fundCodes.contains(code)) {
              results[code] = {
                'fund_code': fund['基金代码']?.toString() ?? '',
                'fund_name': fund['基金简称']?.toString() ?? '',
                'fund_type': fund['基金类型']?.toString() ?? '未知类型',
                'fund_manager': fund['基金经理']?.toString() ?? '未知经理',
                'fund_company': fund['基金管理人']?.toString() ?? '',
                'fund_custodian': fund['基金托管人']?.toString() ?? '',
                'establish_date': fund['成立日期']?.toString() ?? '',
                'management_fee': fund['管理费率']?.toString() ?? '',
                'custody_fee': fund['托管费率']?.toString() ?? '',
              };
            }
          }
        }

        _logger.i('✅ 批量查询完成，找到 ${results.length}/${fundCodes.length} 个基金');
        _logger.d('⏱️ 查询耗时: ${stopwatch.elapsedMilliseconds}ms');

        return results;
      } else {
        throw Exception(
            'HTTP ${response.statusCode}: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('❌ 批量查询基金基本信息失败: $e');
      return {};
    }
  }

  /// 搜索基金（通过基金代码或名称）
  Future<List<Map<String, String>>> searchFunds(String keyword,
      {int limit = 20}) async {
    try {
      _logger.i('🔍 正在搜索基金: "$keyword"');

      if (keyword.trim().isEmpty) {
        return [];
      }

      final stopwatch = Stopwatch()..start();

      // 获取所有基金列表
      final response = await _dio.get(
        _apiUrl,
        options: Options(
          receiveTimeout: const Duration(seconds: 120),
          headers: {
            'Accept': 'application/json; charset=utf-8',
            'Content-Type': 'application/json; charset=utf-8',
          },
        ),
      );
      stopwatch.stop();

      if (response.statusCode == 200) {
        final List<dynamic> fundData = response.data;
        final List<Map<String, String>> results = [];

        // 搜索匹配的基金
        for (final fund in fundData) {
          if (fund is Map<String, dynamic>) {
            final code = fund['基金代码']?.toString() ?? '';
            final name = fund['基金简称']?.toString() ?? '';
            final type = fund['基金类型']?.toString() ?? '未知类型';

            // 检查是否匹配基金代码或基金名称
            if (code.contains(keyword) || name.contains(keyword)) {
              results.add({
                'fund_code': code,
                'fund_name': name,
                'fund_type': type,
                'fund_manager': fund['基金经理']?.toString() ?? '未知经理',
                'fund_company': fund['基金管理人']?.toString() ?? '',
              });

              // 限制结果数量
              if (results.length >= limit) {
                break;
              }
            }
          }
        }

        _logger.i('✅ 搜索完成，找到 ${results.length} 个匹配基金');
        _logger.d('⏱️ 搜索耗时: ${stopwatch.elapsedMilliseconds}ms');

        return results;
      } else {
        throw Exception(
            'HTTP ${response.statusCode}: ${response.statusMessage}');
      }
    } catch (e) {
      _logger.e('❌ 搜索基金失败: $e');
      return [];
    }
  }

  /// 格式化统计信息为可读字符串
  String formatStatisticsForDisplay(Map<String, dynamic> statistics) {
    if (statistics['status'] != 'success') {
      return '❌ API状态异常: ${statistics['error'] ?? '未知错误'}';
    }

    final buffer = StringBuffer();
    buffer.writeln('📊 基金API统计信息');
    buffer.writeln('=' * 30);
    buffer.writeln('🔗 API地址: ${statistics['apiUrl']}');
    buffer.writeln('📈 总基金数量: ${statistics['totalFunds']} 只');
    buffer.writeln('⏱️ 响应时间: ${statistics['responseTime']}ms');
    buffer.writeln(
        '📦 数据大小: ${((statistics['dataSize'] as int) / 1024).toStringAsFixed(2)} KB');
    buffer.writeln('🕐 检查时间: ${statistics['timestamp']}');

    // 基金类型分布
    if (statistics.containsKey('fundTypeDistribution')) {
      final distribution =
          statistics['fundTypeDistribution'] as Map<String, int>;
      buffer.writeln('\n🏷️ 基金类型分布:');
      distribution.forEach((type, count) {
        buffer.writeln('  • $type: $count 只');
      });
    }

    // 基金代码分布
    if (statistics.containsKey('codeDistribution')) {
      final distribution = statistics['codeDistribution'] as Map<String, int>;
      buffer.writeln('\n🔢 基金代码分布:');
      distribution.forEach((prefix, count) {
        buffer.writeln('  • $prefix: $count 只');
      });
    }

    return buffer.toString();
  }
}
