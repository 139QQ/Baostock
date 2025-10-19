import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import '../../../../../../core/utils/logger.dart';

/// 简化版基金排行Cubit - 直接API调用
/// 去除复杂的依赖注入，像测试文件一样工作
class SimpleFundRankingCubit extends Cubit<FundRankingState> {
  // 缓存完整的API响应数据，避免重复请求
  List<dynamic>? _cachedApiData;

  SimpleFundRankingCubit() : super(const FundRankingState.initial()) {
    // 自动初始化数据
    _initializeData();
  }

  /// 自动初始化数据
  Future<void> _initializeData() async {
    AppLogger.debug('🔄 SimpleFundRankingCubit: 开始初始化数据');
    await _loadFromAPI(forceRefresh: false);
  }

  /// 直接从API加载数据
  Future<void> _loadFromAPI({bool forceRefresh = false}) async {
    // 如果不是强制刷新且当前正在加载，则跳过
    if (!forceRefresh && state.isLoading) {
      AppLogger.debug('⏭️ SimpleFundRankingCubit: 正在加载中，跳过重复请求');
      return;
    }

    AppLogger.debug(
        '🔄 SimpleFundRankingCubit: 开始从API加载数据 (forceRefresh: $forceRefresh)');

    emit(state.copyWith(
      isLoading: true,
      error: '',
      rankings: [],
    ));

    try {
      const baseUrl = 'http://154.44.25.92:8080';
      const symbol = '%E5%85%A8%E9%83%A8';

      final uri = Uri.parse(
          '$baseUrl/api/public/fund_open_fund_rank_em?symbol=$symbol');

      AppLogger.debug('📡 SimpleFundRankingCubit: 请求URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json; charset=utf-8',
          'Accept-Charset': 'utf-8',
          'User-Agent': 'SimpleFundRankingCubit/1.0.0',
          'Connection': 'keep-alive',
          if (forceRefresh) 'Cache-Control': 'no-cache',
        },
      ).timeout(const Duration(seconds: 60));

      AppLogger.debug(
          '📊 SimpleFundRankingCubit: 响应状态: ${response.statusCode}');
      AppLogger.debug(
          '📊 SimpleFundRankingCubit: 响应长度: ${response.body.length}');

      if (response.statusCode == 200) {
        // 确保正确处理UTF-8编码
        String responseData;
        try {
          // 先尝试直接解码，如果失败则使用备用方案
          responseData =
              utf8.decode(response.body.codeUnits, allowMalformed: true);
        } catch (e) {
          AppLogger.debug('❌ UTF-8解码失败，尝试其他方式: $e');
          responseData = response.body;
        }

        final data = json.decode(responseData);
        AppLogger.debug(
            '📊 SimpleFundRankingCubit: API返回数据解析成功，数据类型: ${data.runtimeType}，数据长度: ${data.length}');

        // 检查第一条数据的内容
        if (data.isNotEmpty) {
          AppLogger.debug('📊 SimpleFundRankingCubit: 第一条原始数据: ${data[0]}');
          AppLogger.debug(
              '📊 SimpleFundRankingCubit: 第一条数据类型: ${data[0].runtimeType}');
        }

        // 缓存完整的API响应数据
        _cachedApiData = data;

        // 转换为FundRanking对象（简单转换）
        final rankings = _convertToFundRankings(data.take(50).toList());

        AppLogger.debug(
            '✅ SimpleFundRankingCubit: 数据加载成功: ${data.length}条记录，显示${rankings.length}条');
        AppLogger.debug(
            '💾 SimpleFundRankingCubit: 已缓存完整API数据，共${data.length}条记录');

        if (isClosed) {
          AppLogger.debug('❌ SimpleFundRankingCubit: Cubit已关闭，无法发射状态');
          return;
        }

        emit(state.copyWith(
          isLoading: false,
          rankings: rankings,
          error: '',
          lastUpdateTime: DateTime.now(),
          totalCount: data.length,
          hasMoreData: data.length > 50,
        ));
      } else {
        final errorMsg =
            'API错误: ${response.statusCode} ${response.reasonPhrase}';
        AppLogger.debug('❌ SimpleFundRankingCubit: $errorMsg');
        if (!isClosed) {
          emit(state.copyWith(
            isLoading: false,
            error: errorMsg,
          ));
        }
      }
    } on TimeoutException {
      final errorMsg = '请求超时: API服务器响应时间过长';
      AppLogger.debug('❌ SimpleFundRankingCubit: $errorMsg');
      if (!isClosed) {
        emit(state.copyWith(
          isLoading: false,
          error: errorMsg,
        ));
      }
    } on SocketException catch (e) {
      final errorMsg = '网络连接错误: ${e.message}';
      AppLogger.debug('❌ SimpleFundRankingCubit: $errorMsg');
      if (!isClosed) {
        emit(state.copyWith(
          isLoading: false,
          error: errorMsg,
        ));
      }
    } catch (e) {
      final errorMsg = '加载失败: $e';
      AppLogger.debug('❌ SimpleFundRankingCubit: $errorMsg');
      if (!isClosed) {
        emit(state.copyWith(
          isLoading: false,
          error: errorMsg,
        ));
      }
    }
  }

  /// 转换API数据为FundRanking对象
  List<FundRanking> _convertToFundRankings(List<dynamic> data) {
    AppLogger.debug('🔄 SimpleFundRankingCubit: 开始转换${data.length}条API数据');

    final rankings = <FundRanking>[];

    for (int i = 0; i < data.length; i++) {
      final item = data[i] as Map<String, dynamic>;

      // 添加详细调试信息
      AppLogger.debug('🔍 处理API项目 $i:');
      AppLogger.debug('  原始数据: $item');
      AppLogger.debug('  序号字段存在: ${item.containsKey('序号')}');
      AppLogger.debug('  基金代码字段存在: ${item.containsKey('基金代码')}');
      AppLogger.debug('  基金简称字段存在: ${item.containsKey('基金简称')}');
      AppLogger.debug('  基金代码值: "${item['基金代码']}"');
      AppLogger.debug('  基金简称值: "${item['基金简称']}"');
      AppLogger.debug('  单位净值值: "${item['单位净值']}"');
      AppLogger.debug('  日增长率值: "${item['日增长率']}"');
      AppLogger.debug('  近1年值: "${item['近1年']}"');

      // 安全地获取每个字段 - 使用实际的API字段名
      final fundCode = item['基金代码']?.toString() ?? '';
      final fundName = item['基金简称']?.toString() ?? '';
      final navValue = item['单位净值']?.toString() ?? '0.0';
      final dailyReturn = item['日增长率']?.toString() ?? '0.0';
      final oneYearReturn = item['近1年']?.toString() ?? '0.0';
      final threeYearReturn = item['近3年']?.toString() ?? '0.0';

      AppLogger.debug('  解析后 - 基金代码: "$fundCode"');
      AppLogger.debug('  解析后 - 基金简称: "$fundName"');
      // 只有当基金代码和名称都不为空时才创建对象
      if (fundCode.isNotEmpty && fundName.isNotEmpty) {
        final ranking = FundRanking(
          id: fundCode,
          rank: i + 1, // 使用实际排名
          fundCode: fundCode,
          fundName: fundName,
          fundType: '', // API没有返回基金类型字段，留空
          nav: double.tryParse(navValue) ?? 0.0,
          dailyReturn: double.tryParse(dailyReturn) ?? 0.0,
          oneYearReturn: double.tryParse(oneYearReturn) ?? 0.0,
          threeYearReturn: double.tryParse(threeYearReturn) ?? 0.0,
          updateDate: DateTime.now(),
        );

        rankings.add(ranking);
        AppLogger.debug('  ✅ 成功创建FundRanking对象: ${ranking.fundName}');
      } else {
        AppLogger.debug('  ❌ 跳过无效数据: 基金代码="$fundCode", 基金名称="$fundName"');
      }
    }

    AppLogger.debug(
        '✅ SimpleFundRankingCubit: 转换完成，生成${rankings.length}条FundRanking对象');
    if (rankings.isNotEmpty) {
      AppLogger.debug(
          '📊 SimpleFundRankingCubit: 第一条数据示例 - ${rankings.first.fundName} (${rankings.first.fundCode})');
      AppLogger.debug(
          '📊 SimpleFundRankingCubit: 第二条数据示例 - ${rankings[1].fundName} (${rankings[1].fundCode})');
    }
    return rankings;
  }

  /// 刷新数据 - 智能刷新：如果有缓存则清除缓存重新请求
  void refreshRankings() {
    AppLogger.debug('🔄 SimpleFundRankingCubit: 用户点击刷新按钮 - 清除缓存并重新请求');
    _cachedApiData = null; // 清除缓存，获取最新数据
    _loadFromAPI(forceRefresh: true);
  }

  /// 强制重载 - 清除缓存并重新请求API
  void forceReload() {
    AppLogger.debug('🔄 SimpleFundRankingCubit: 用户点击强制重载 - 清除缓存');
    AppLogger.debug(
        '📊 SimpleFundRankingCubit: 当前状态 - isLoading: ${state.isLoading}, 数据量: ${state.rankings.length}');
    _cachedApiData = null; // 清除缓存
    AppLogger.debug('🗑️ SimpleFundRankingCubit: 已清除缓存数据');
    _loadFromAPI(forceRefresh: true);
    AppLogger.debug('🚀 SimpleFundRankingCubit: 已触发API重新加载');
  }

  /// 初始化 - 直接API调用
  Future<void> initialize() async {
    AppLogger.debug('🔄 SimpleFundRankingCubit: 手动初始化');
    await _loadFromAPI(forceRefresh: false);
  }

  /// 清除错误
  void clearError() {
    if (state.error.isNotEmpty) {
      emit(state.copyWith(error: ''));
    }
  }

  /// 加载更多数据 - 使用缓存数据，避免重复API请求
  Future<void> loadMoreRankings() async {
    if (state.isLoading || !state.hasMoreData || isClosed) {
      AppLogger.debug(
          '📄 SimpleFundRankingCubit: 跳过加载更多 - isLoading:${state.isLoading}, hasMoreData:${state.hasMoreData}, isClosed:$isClosed');
      return;
    }

    // 检查是否有缓存数据
    if (_cachedApiData == null) {
      AppLogger.debug('❌ SimpleFundRankingCubit: 没有缓存数据，无法加载更多');
      return;
    }

    AppLogger.debug('📄 SimpleFundRankingCubit: 开始从缓存加载更多数据');

    try {
      final currentLength = state.rankings.length;
      final moreData = _cachedApiData!.skip(currentLength).take(20).toList();

      if (moreData.isNotEmpty) {
        // 设置加载状态
        if (!isClosed) {
          emit(state.copyWith(isLoading: true));
        }

        final moreRankings = _convertToFundRankings(moreData);
        final allRankings = [...state.rankings, ...moreRankings];

        if (!isClosed) {
          emit(state.copyWith(
            isLoading: false,
            rankings: allRankings,
            hasMoreData: allRankings.length < _cachedApiData!.length,
          ));
          AppLogger.debug(
              '✅ SimpleFundRankingCubit: 从缓存加载更多成功: 新增${moreRankings.length}条，总计${allRankings.length}条');
          AppLogger.debug(
              '💾 SimpleFundRankingCubit: 缓存数据使用情况: ${allRankings.length}/${_cachedApiData!.length}');
        } else {
          AppLogger.debug('❌ SimpleFundRankingCubit: Cubit已关闭，无法发射加载更多状态');
        }
      } else {
        AppLogger.debug('📄 SimpleFundRankingCubit: 缓存中没有更多数据了');
        if (!isClosed) {
          emit(state.copyWith(hasMoreData: false));
        }
      }
    } catch (e) {
      AppLogger.debug('❌ SimpleFundRankingCubit: 从缓存加载更多失败: $e');
      if (!isClosed) {
        emit(state.copyWith(isLoading: false));
      }
    }
  }

  /// 搜索基金
  void searchFunds(String query) {
    // 简化实现：直接在现有数据中搜索
    if (query.isEmpty) {
      // 清空搜索，重新加载
      _loadFromAPI(forceRefresh: false);
    } else {
      // 在现有数据中筛选
      final filteredRankings = state.rankings.where((ranking) {
        return ranking.fundName.toLowerCase().contains(query.toLowerCase()) ||
            ranking.fundCode.toLowerCase().contains(query.toLowerCase());
      }).toList();

      emit(state.copyWith(rankings: filteredRankings));
    }
  }

  /// 清除搜索
  void clearSearch() {
    _loadFromAPI(forceRefresh: false);
  }
}

/// 简化版基金排行状态
class FundRankingState {
  final bool isLoading;
  final List<FundRanking> rankings;
  final String error;
  final DateTime? lastUpdateTime;
  final int totalCount;
  final bool hasMoreData;

  const FundRankingState({
    this.isLoading = false,
    this.rankings = const [],
    this.error = '',
    this.lastUpdateTime,
    this.totalCount = 0,
    this.hasMoreData = false,
  });

  const FundRankingState.initial()
      : isLoading = false,
        rankings = const [],
        error = '',
        lastUpdateTime = null,
        totalCount = 0,
        hasMoreData = false;

  FundRankingState copyWith({
    bool? isLoading,
    List<FundRanking>? rankings,
    String? error,
    DateTime? lastUpdateTime,
    int? totalCount,
    bool? hasMoreData,
  }) {
    return FundRankingState(
      isLoading: isLoading ?? this.isLoading,
      rankings: rankings ?? this.rankings,
      error: error ?? this.error,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      totalCount: totalCount ?? this.totalCount,
      hasMoreData: hasMoreData ?? this.hasMoreData,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FundRankingState &&
          runtimeType == other.runtimeType &&
          isLoading == other.isLoading &&
          rankings == other.rankings &&
          error == other.error &&
          lastUpdateTime == other.lastUpdateTime &&
          totalCount == other.totalCount &&
          hasMoreData == other.hasMoreData;

  @override
  int get hashCode =>
      isLoading.hashCode ^
      rankings.hashCode ^
      error.hashCode ^
      lastUpdateTime.hashCode ^
      totalCount.hashCode ^
      hasMoreData.hashCode;
}

/// 简化版基金排行实体
class FundRanking {
  final String id;
  final int rank;
  final String fundCode;
  final String fundName;
  final String fundType;
  final double nav;
  final double dailyReturn;
  final double oneYearReturn;
  final double threeYearReturn;
  final DateTime updateDate;

  const FundRanking({
    required this.id,
    required this.rank,
    required this.fundCode,
    required this.fundName,
    required this.fundType,
    required this.nav,
    required this.dailyReturn,
    required this.oneYearReturn,
    required this.threeYearReturn,
    required this.updateDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FundRanking &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          fundCode == other.fundCode;

  @override
  int get hashCode => id.hashCode ^ fundCode.hashCode;
}
