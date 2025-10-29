import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';

import '../../../../core/utils/logger.dart';
import '../models/money_fund.dart';
import '../../../../core/network/api_service.dart';

/// 货币基金数据服务
///
/// 专门处理货币型基金的数据获取、解析和管理
class MoneyFundService {
  static const String _baseUrl = 'http://154.44.25.92:8080';
  static const Duration _timeout = Duration(seconds: 30);

  late final ApiService _apiService;

  /// 构造函数
  MoneyFundService({ApiService? apiService}) {
    if (apiService != null) {
      _apiService = apiService;
    } else {
      // 创建默认的ApiService
      final dio = Dio();
      dio.options.baseUrl = _baseUrl;
      _apiService = ApiService(dio);
    }
  }

  /// 获取货币基金列表
  ///
  /// 返回货币基金数据列表，已经过解析和验证
  Future<MoneyFundResult<List<MoneyFund>>> getMoneyFunds() async {
    AppLogger.debug('🔄 MoneyFundService: 开始获取货币基金数据');

    try {
      final rawData = await _apiService.getMoneyFundDaily();

      if (rawData is! List) {
        return MoneyFundResult.failure('API返回数据格式错误，期望List');
      }

      AppLogger.debug('📊 MoneyFundService: 获取到 ${rawData.length} 条原始数据');

      final moneyFunds = <MoneyFund>[];
      int successCount = 0;
      int errorCount = 0;

      for (int i = 0; i < rawData.length; i++) {
        try {
          final fundData = rawData[i] as Map<String, dynamic>;
          final moneyFund = MoneyFund.fromJson(fundData);
          moneyFunds.add(moneyFund);
          successCount++;
        } catch (e) {
          errorCount++;
          AppLogger.debug('⚠️ MoneyFundService: 跳过无效数据项[$i]: $e');
          // 继续处理其他数据项
        }
      }

      AppLogger.info('✅ MoneyFundService: 数据解析完成');
      AppLogger.info('📊 成功解析: $successCount 条，跳过: $errorCount 条');

      if (moneyFunds.isEmpty) {
        return MoneyFundResult.failure('没有有效的货币基金数据');
      }

      // 按7日年化收益率降序排序
      moneyFunds.sort((a, b) => b.sevenDayYield.compareTo(a.sevenDayYield));

      return MoneyFundResult.success(moneyFunds);
    } catch (e) {
      final errorMsg = '获取货币基金数据失败: $e';
      AppLogger.error('❌ MoneyFundService: $errorMsg', e);
      return MoneyFundResult.failure(errorMsg);
    }
  }

  /// 根据基金代码获取货币基金信息
  Future<MoneyFundResult<MoneyFund?>> getMoneyFundByCode(
      String fundCode) async {
    AppLogger.debug('🔍 MoneyFundService: 查询货币基金 $fundCode');

    try {
      final result = await getMoneyFunds();
      if (result.isFailure) {
        return MoneyFundResult.failure(result.errorMessage!);
      }

      final funds = result.data!;
      final fund = funds.firstWhere(
        (f) => f.fundCode == fundCode,
        orElse: () => funds.firstWhere(
          (f) => f.fundCode.contains(fundCode) || fundCode.contains(f.fundCode),
          orElse: () => throw Exception('未找到基金'),
        ),
      );

      AppLogger.debug('✅ MoneyFundService: 找到基金 ${fund.fundName}');
      return MoneyFundResult.success(fund);
    } catch (e) {
      final errorMsg = '查询货币基金失败: $e';
      AppLogger.error('❌ MoneyFundService: $errorMsg', e);
      return MoneyFundResult.failure(errorMsg);
    }
  }

  /// 搜索货币基金
  Future<MoneyFundResult<List<MoneyFund>>> searchMoneyFunds(
    String query, {
    int limit = 20,
  }) async {
    if (query.trim().isEmpty) {
      return MoneyFundResult.success(<MoneyFund>[]);
    }

    AppLogger.debug('🔍 MoneyFundService: 搜索货币基金 "$query"');

    try {
      final result = await getMoneyFunds();
      if (result.isFailure) {
        return MoneyFundResult.failure(result.errorMessage!);
      }

      final funds = result.data!;
      final lowerQuery = query.toLowerCase();

      final filteredFunds = funds
          .where((fund) {
            return fund.fundCode.toLowerCase().contains(lowerQuery) ||
                fund.fundName.toLowerCase().contains(lowerQuery) ||
                fund.fundManager.toLowerCase().contains(lowerQuery);
          })
          .take(limit)
          .toList();

      AppLogger.debug(
          '✅ MoneyFundService: 搜索完成，找到 ${filteredFunds.length} 条结果');
      return MoneyFundResult.success(filteredFunds);
    } catch (e) {
      final errorMsg = '搜索货币基金失败: $e';
      AppLogger.error('❌ MoneyFundService: $errorMsg', e);
      return MoneyFundResult.failure(errorMsg);
    }
  }

  /// 获取收益最高的货币基金
  Future<MoneyFundResult<List<MoneyFund>>> getTopYieldMoneyFunds({
    int count = 10,
  }) async {
    AppLogger.debug('🏆 MoneyFundService: 获取收益最高的 $count 只货币基金');

    try {
      final result = await getMoneyFunds();
      if (result.isFailure) {
        return MoneyFundResult.failure(result.errorMessage!);
      }

      final funds = result.data!;
      final topFunds = funds.take(count).toList();

      AppLogger.debug('✅ MoneyFundService: 获取到 ${topFunds.length} 只高收益货币基金');
      return MoneyFundResult.success(topFunds);
    } catch (e) {
      final errorMsg = '获取高收益货币基金失败: $e';
      AppLogger.error('❌ MoneyFundService: $errorMsg', e);
      return MoneyFundResult.failure(errorMsg);
    }
  }

  /// 获取货币基金统计数据
  Future<MoneyFundResult<Map<String, dynamic>>> getMoneyFundStatistics() async {
    AppLogger.debug('📊 MoneyFundService: 获取货币基金统计数据');

    try {
      final result = await getMoneyFunds();
      if (result.isFailure) {
        return MoneyFundResult.failure(result.errorMessage!);
      }

      final funds = result.data!;

      if (funds.isEmpty) {
        return MoneyFundResult.failure('没有货币基金数据');
      }

      // 计算统计数据
      final totalFunds = funds.length;
      final validYieldFunds = funds.where((f) => f.sevenDayYield > 0).toList();
      final avgYield = validYieldFunds.isEmpty
          ? 0.0
          : validYieldFunds
                  .map((f) => f.sevenDayYield)
                  .reduce((a, b) => a + b) /
              validYieldFunds.length;

      final maxYield = validYieldFunds.isEmpty
          ? 0.0
          : validYieldFunds
              .map((f) => f.sevenDayYield)
              .reduce((a, b) => a > b ? a : b);

      final minYield = validYieldFunds.isEmpty
          ? 0.0
          : validYieldFunds
              .map((f) => f.sevenDayYield)
              .reduce((a, b) => a < b ? a : b);

      final avgIncome = validYieldFunds.isEmpty
          ? 0.0
          : validYieldFunds.map((f) => f.dailyIncome).reduce((a, b) => a + b) /
              validYieldFunds.length;

      final statistics = {
        'totalFunds': totalFunds,
        'validYieldFunds': validYieldFunds.length,
        'avgSevenDayYield': double.parse(avgYield.toStringAsFixed(4)),
        'maxSevenDayYield': double.parse(maxYield.toStringAsFixed(4)),
        'minSevenDayYield': double.parse(minYield.toStringAsFixed(4)),
        'avgDailyIncome': double.parse(avgIncome.toStringAsFixed(4)),
        'topYieldFunds': funds
            .take(5)
            .map((f) => {
                  'code': f.fundCode,
                  'name': f.fundName,
                  'yield': f.sevenDayYield,
                  'income': f.dailyIncome,
                })
            .toList(),
        'dataDate': funds.first.dataDate,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      AppLogger.debug('✅ MoneyFundService: 统计数据计算完成');
      return MoneyFundResult.success(statistics);
    } catch (e) {
      final errorMsg = '获取货币基金统计数据失败: $e';
      AppLogger.error('❌ MoneyFundService: $errorMsg', e);
      return MoneyFundResult.failure(errorMsg);
    }
  }

  /// 比较货币基金收益
  Future<MoneyFundResult<Map<String, dynamic>>> compareMoneyFunds(
    List<String> fundCodes,
  ) async {
    AppLogger.debug('🔍 MoneyFundService: 比较 ${fundCodes.length} 只货币基金');

    try {
      final result = await getMoneyFunds();
      if (result.isFailure) {
        return MoneyFundResult.failure(result.errorMessage!);
      }

      final allFunds = result.data!;
      final compareFunds = <MoneyFund>[];

      for (final code in fundCodes) {
        try {
          final fund = allFunds.firstWhere(
            (f) => f.fundCode == code,
            orElse: () => throw Exception('未找到基金 $code'),
          );
          compareFunds.add(fund);
        } catch (e) {
          AppLogger.warn('⚠️ MoneyFundService: 跳过基金 $code: $e');
        }
      }

      if (compareFunds.isEmpty) {
        return MoneyFundResult.failure('没有找到可比较的基金');
      }

      // 按收益率排序
      compareFunds.sort((a, b) => b.sevenDayYield.compareTo(a.sevenDayYield));

      final comparison = {
        'funds': compareFunds
            .map((f) => {
                  'code': f.fundCode,
                  'name': f.fundName,
                  'dailyIncome': f.dailyIncome,
                  'sevenDayYield': f.sevenDayYield,
                  'formattedDailyIncome': f.formattedDailyIncome,
                  'formattedSevenDayYield': f.formattedSevenDayYield,
                  'dataDate': f.dataDate,
                })
            .toList(),
        'comparison': {
          'highestYield': {
            'code': compareFunds.first.fundCode,
            'name': compareFunds.first.fundName,
            'yield': compareFunds.first.sevenDayYield,
          },
          'lowestYield': {
            'code': compareFunds.last.fundCode,
            'name': compareFunds.last.fundName,
            'yield': compareFunds.last.sevenDayYield,
          },
          'avgYield':
              compareFunds.map((f) => f.sevenDayYield).reduce((a, b) => a + b) /
                  compareFunds.length,
        },
        'compareCount': compareFunds.length,
        'comparedAt': DateTime.now().toIso8601String(),
      };

      AppLogger.debug('✅ MoneyFundService: 基金比较完成');
      return MoneyFundResult.success(comparison);
    } catch (e) {
      final errorMsg = '比较货币基金失败: $e';
      AppLogger.error('❌ MoneyFundService: $errorMsg', e);
      return MoneyFundResult.failure(errorMsg);
    }
  }
}

/// 货币基金操作结果封装
class MoneyFundResult<T> {
  final T? data;
  final String? errorMessage;
  final bool isSuccess;

  const MoneyFundResult._({
    this.data,
    this.errorMessage,
    required this.isSuccess,
  });

  factory MoneyFundResult.success(T data) {
    return MoneyFundResult._(
      data: data,
      isSuccess: true,
    );
  }

  factory MoneyFundResult.failure(String errorMessage) {
    return MoneyFundResult._(
      errorMessage: errorMessage,
      isSuccess: false,
    );
  }

  bool get isFailure => !isSuccess;

  /// 获取数据或抛出异常
  T get dataOrThrow {
    if (isSuccess) {
      return data!;
    } else {
      throw Exception(errorMessage);
    }
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'MoneyFundResult.success(data: $data)';
    } else {
      return 'MoneyFundResult.failure(errorMessage: $errorMessage)';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoneyFundResult &&
          runtimeType == other.runtimeType &&
          isSuccess == other.isSuccess &&
          data == other.data &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode =>
      isSuccess.hashCode ^ data.hashCode ^ errorMessage.hashCode;
}
