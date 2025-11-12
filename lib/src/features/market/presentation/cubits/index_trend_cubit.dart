import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:decimal/decimal.dart';

import '../../models/market_index_data.dart';
import '../../models/index_change_data.dart';
import '../../data/processors/market_index_data_manager.dart';

/// 指数趋势状态
@immutable
class IndexTrendState extends Equatable {
  final String indexCode;
  final List<MarketIndexData> historicalData;
  final List<IndexChangeData> changeHistory;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final DateTime lastUpdated;
  final TrendAnalysis? trendAnalysis;
  final TrendSettings settings;

  // 兼容页面使用的属性
  String? get selectedIndexCode => indexCode.isEmpty ? null : indexCode;

  const IndexTrendState({
    required this.indexCode,
    this.historicalData = const [],
    this.changeHistory = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    required this.lastUpdated,
    this.trendAnalysis,
    this.settings = const TrendSettings(),
  });

  IndexTrendState copyWith({
    String? indexCode,
    List<MarketIndexData>? historicalData,
    List<IndexChangeData>? changeHistory,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    DateTime? lastUpdated,
    TrendAnalysis? trendAnalysis,
    TrendSettings? settings,
  }) {
    return IndexTrendState(
      indexCode: indexCode ?? this.indexCode,
      historicalData: historicalData ?? this.historicalData,
      changeHistory: changeHistory ?? this.changeHistory,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: error ?? this.error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      trendAnalysis: trendAnalysis ?? this.trendAnalysis,
      settings: settings ?? this.settings,
    );
  }

  @override
  List<Object?> get props => [
        indexCode,
        historicalData,
        changeHistory,
        isLoading,
        isRefreshing,
        error,
        lastUpdated,
        trendAnalysis,
        settings,
      ];
}

/// 趋势分析结果
@immutable
class TrendAnalysis extends Equatable {
  final TrendDirection direction;
  final TrendStrength strength;
  final double priceChange;
  final double percentageChange;
  final double volatility;
  final List<TrendPoint> keyPoints;
  final List<TrendSignal> signals;
  final DateTime analysisTime;

  const TrendAnalysis({
    required this.direction,
    required this.strength,
    required this.priceChange,
    required this.percentageChange,
    required this.volatility,
    required this.keyPoints,
    required this.signals,
    required this.analysisTime,
  });

  @override
  List<Object?> get props => [
        direction,
        strength,
        priceChange,
        percentageChange,
        volatility,
        keyPoints,
        signals,
        analysisTime,
      ];
}

/// 趋势点
@immutable
class TrendPoint extends Equatable {
  final DateTime timestamp;
  final double price;
  final TrendPointType type;
  final String? description;

  const TrendPoint({
    required this.timestamp,
    required this.price,
    required this.type,
    this.description,
  });

  @override
  List<Object?> get props => [timestamp, price, type, description];
}

/// 趋势点类型
enum TrendPointType {
  support,
  resistance,
  peak,
  trough,
  breakout,
}

/// 趋势信号
@immutable
class TrendSignal extends Equatable {
  final TrendSignalType type;
  final TrendSignalStrength strength;
  final String description;
  final DateTime timestamp;
  final double? targetPrice;

  const TrendSignal({
    required this.type,
    required this.strength,
    required this.description,
    required this.timestamp,
    this.targetPrice,
  });

  @override
  List<Object?> get props =>
      [type, strength, description, timestamp, targetPrice];
}

/// 趋势方向
enum TrendDirection {
  up,
  down,
  sideways,
  unknown;

  String get description {
    switch (this) {
      case TrendDirection.up:
        return '上升趋势';
      case TrendDirection.down:
        return '下降趋势';
      case TrendDirection.sideways:
        return '横盘整理';
      case TrendDirection.unknown:
        return '趋势不明';
    }
  }
}

/// 趋势强度
enum TrendStrength {
  weak,
  moderate,
  strong;

  String get description {
    switch (this) {
      case TrendStrength.weak:
        return '弱';
      case TrendStrength.moderate:
        return '中等';
      case TrendStrength.strong:
        return '强';
    }
  }
}

/// 趋势信号类型
enum TrendSignalType {
  buy,
  sell,
  hold,
  watch;

  String get description {
    switch (this) {
      case TrendSignalType.buy:
        return '买入';
      case TrendSignalType.sell:
        return '卖出';
      case TrendSignalType.hold:
        return '持有';
      case TrendSignalType.watch:
        return '观察';
    }
  }
}

/// 趋势信号强度
enum TrendSignalStrength {
  weak,
  moderate,
  strong;

  String get description {
    switch (this) {
      case TrendSignalStrength.weak:
        return '弱';
      case TrendSignalStrength.moderate:
        return '中等';
      case TrendSignalStrength.strong:
        return '强';
    }
  }
}

/// 趋势设置
@immutable
class TrendSettings extends Equatable {
  final Duration analysisPeriod;
  final int minDataPoints;
  final double volatilityThreshold;
  final bool enableTechnicalSignals;
  final bool enableVolumeAnalysis;
  final List<TrendIndicator> enabledIndicators;

  const TrendSettings({
    this.analysisPeriod = const Duration(days: 7),
    this.minDataPoints = 20,
    this.volatilityThreshold = 0.02,
    this.enableTechnicalSignals = true,
    this.enableVolumeAnalysis = true,
    this.enabledIndicators = const [
      TrendIndicator.ma,
      TrendIndicator.rsi,
      TrendIndicator.macd,
    ],
  });

  TrendSettings copyWith({
    Duration? analysisPeriod,
    int? minDataPoints,
    double? volatilityThreshold,
    bool? enableTechnicalSignals,
    bool? enableVolumeAnalysis,
    List<TrendIndicator>? enabledIndicators,
  }) {
    return TrendSettings(
      analysisPeriod: analysisPeriod ?? this.analysisPeriod,
      minDataPoints: minDataPoints ?? this.minDataPoints,
      volatilityThreshold: volatilityThreshold ?? this.volatilityThreshold,
      enableTechnicalSignals:
          enableTechnicalSignals ?? this.enableTechnicalSignals,
      enableVolumeAnalysis: enableVolumeAnalysis ?? this.enableVolumeAnalysis,
      enabledIndicators: enabledIndicators ?? this.enabledIndicators,
    );
  }

  @override
  List<Object?> get props => [
        analysisPeriod,
        minDataPoints,
        volatilityThreshold,
        enableTechnicalSignals,
        enableVolumeAnalysis,
        enabledIndicators,
      ];
}

/// 趋势指标
enum TrendIndicator {
  ma, // 移动平均线
  rsi, // 相对强弱指数
  macd, // MACD
  bollinger, // 布林带
  volume, // 成交量
}

/// 指数趋势Cubit事件
abstract class IndexTrendEvent extends Equatable {
  const IndexTrendEvent();
}

/// 加载趋势数据
class LoadTrendData extends IndexTrendEvent {
  final String indexCode;
  final Duration? period;

  const LoadTrendData({
    required this.indexCode,
    this.period,
  });

  @override
  List<Object?> get props => [indexCode, period];
}

/// 刷新趋势数据
class RefreshTrendData extends IndexTrendEvent {
  final String indexCode;

  const RefreshTrendData({required this.indexCode});

  @override
  List<Object?> get props => [indexCode];
}

/// 更新趋势设置
class UpdateTrendSettings extends IndexTrendEvent {
  final TrendSettings settings;

  const UpdateTrendSettings(this.settings);

  @override
  List<Object?> get props => [settings];
}

/// 分析趋势
class AnalyzeTrend extends IndexTrendEvent {
  final String indexCode;

  const AnalyzeTrend({required this.indexCode});

  @override
  List<Object?> get props => [indexCode];
}

/// 添加数据点
class AddDataPoint extends IndexTrendEvent {
  final MarketIndexData dataPoint;

  const AddDataPoint(this.dataPoint);

  @override
  List<Object?> get props => [dataPoint];
}

/// 清除错误
class ClearTrendError extends IndexTrendEvent {
  @override
  List<Object?> get props => [];
}

/// 指数趋势Cubit
class IndexTrendCubit extends Cubit<IndexTrendState> {
  final MarketIndexDataManager _dataManager;
  StreamSubscription? _dataSubscription;

  IndexTrendCubit({
    MarketIndexDataManager? dataManager,
  })  : _dataManager = dataManager ?? MarketIndexDataManager(),
        super(IndexTrendState(
          indexCode: '',
          lastUpdated: DateTime.now(),
        )) {
    _setupListener();
  }

  /// 设置监听器
  void _setupListener() {
    _dataSubscription = _dataManager.updateStream.listen((event) {
      if (state.indexCode == event.indexCode) {
        _onAddDataPoint(AddDataPoint(event.indexData));
      }
    });
  }

  @override
  Future<void> close() {
    _dataSubscription?.cancel();
    return super.close();
  }

  /// 事件处理
  Future<void> onEvent(IndexTrendEvent event) async {
    switch (event.runtimeType) {
      case LoadTrendData:
        await _onLoadTrendData(event as LoadTrendData);
        break;
      case RefreshTrendData:
        await _onRefreshTrendData(event as RefreshTrendData);
        break;
      case UpdateTrendSettings:
        await _onUpdateTrendSettings(event as UpdateTrendSettings);
        break;
      case AnalyzeTrend:
        await _onAnalyzeTrend(event as AnalyzeTrend);
        break;
      case AddDataPoint:
        _onAddDataPoint(event as AddDataPoint);
        break;
      case ClearTrendError:
        _onClearError();
        break;
    }
  }

  /// 加载趋势数据
  Future<void> _onLoadTrendData(LoadTrendData event) async {
    try {
      emit(state.copyWith(
        indexCode: event.indexCode,
        isLoading: true,
        error: null,
      ));

      // 获取历史数据 (这里简化处理，实际应该从数据库或API获取)
      final historicalData = <MarketIndexData>[];
      final changeHistory = <IndexChangeData>[];

      // 模拟生成一些历史数据
      final now = DateTime.now();
      final period = event.period ?? state.settings.analysisPeriod;

      for (int i = 0; i < 50; i++) {
        final time = now.subtract(Duration(
          hours: (i * period.inHours / 50).round(),
        ));

        final price = 3000.0 +
            (math.sin(i * 0.2) * 200) +
            (math.Random().nextDouble() * 50 - 25);
        final previousPrice = i > 0
            ? 3000.0 +
                (math.sin((i - 1) * 0.2) * 200) +
                (math.Random().nextDouble() * 50 - 25)
            : price;

        final data = MarketIndexData(
          code: event.indexCode,
          name: _getIndexName(event.indexCode),
          currentValue: Decimal.parse(price.toString()),
          previousClose: Decimal.parse(previousPrice.toString()),
          openPrice: Decimal.parse(
              (price + (math.Random().nextDouble() * 20 - 10)).toString()),
          highPrice: Decimal.parse(
              (price + math.Random().nextDouble() * 30).toString()),
          lowPrice: Decimal.parse(
              (price - math.Random().nextDouble() * 30).toString()),
          changeAmount: Decimal.parse((price - previousPrice).toString()),
          changePercentage: Decimal.parse(
              (((price - previousPrice) / previousPrice) * 100).toString()),
          volume: 1000000 + math.Random().nextInt(5000000),
          turnover: Decimal.parse(
              (3000000000.0 + math.Random().nextInt(1000000000)).toString()),
          updateTime: time,
          marketStatus: _determineMarketStatus(time),
          qualityLevel: _determineQualityLevel(math.Random().nextDouble()),
          dataSource: 'simulation',
        );

        historicalData.add(data);

        if (i > 0) {
          final changeData = IndexChangeData.calculateChange(
            currentData: data,
            previousData: historicalData[i - 1],
          );
          changeHistory.add(changeData);
        }
      }

      // 按时间排序
      historicalData.sort((a, b) => a.updateTime.compareTo(b.updateTime));
      changeHistory.sort((a, b) => a.changeTime.compareTo(b.changeTime));

      // 分析趋势
      final trendAnalysis =
          _performTrendAnalysis(historicalData, changeHistory);

      emit(state.copyWith(
        historicalData: historicalData,
        changeHistory: changeHistory,
        trendAnalysis: trendAnalysis,
        isLoading: false,
        lastUpdated: DateTime.now(),
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: '加载趋势数据失败: $e',
      ));
    }
  }

  /// 刷新趋势数据
  Future<void> _onRefreshTrendData(RefreshTrendData event) async {
    try {
      emit(state.copyWith(isRefreshing: true));

      // 触发数据刷新 - 暂时跳过，等待MarketIndexDataManager提供公共接口
      // await _dataManager.refreshIndexData(event.indexCode);

      emit(state.copyWith(isRefreshing: false));
    } catch (e) {
      emit(state.copyWith(
        isRefreshing: false,
        error: '刷新趋势数据失败: $e',
      ));
    }
  }

  /// 更新趋势设置
  Future<void> _onUpdateTrendSettings(UpdateTrendSettings event) async {
    try {
      emit(state.copyWith(settings: event.settings));

      // 重新分析趋势
      if (state.historicalData.isNotEmpty) {
        final trendAnalysis = _performTrendAnalysis(
          state.historicalData,
          state.changeHistory,
        );
        emit(state.copyWith(trendAnalysis: trendAnalysis));
      }
    } catch (e) {
      emit(state.copyWith(error: '更新趋势设置失败: $e'));
    }
  }

  /// 分析趋势
  Future<void> _onAnalyzeTrend(AnalyzeTrend event) async {
    try {
      if (state.historicalData.length < state.settings.minDataPoints) {
        emit(state.copyWith(
          error: '数据点不足，无法进行趋势分析',
        ));
        return;
      }

      final trendAnalysis = _performTrendAnalysis(
        state.historicalData,
        state.changeHistory,
      );

      emit(state.copyWith(trendAnalysis: trendAnalysis));
    } catch (e) {
      emit(state.copyWith(error: '趋势分析失败: $e'));
    }
  }

  /// 添加数据点
  void _onAddDataPoint(AddDataPoint event) {
    final newData = List<MarketIndexData>.from(state.historicalData)
      ..add(event.dataPoint);

    // 保持数据点数量在合理范围内
    final maxDataPoints = 200;
    if (newData.length > maxDataPoints) {
      newData.removeRange(0, newData.length - maxDataPoints);
    }

    // 如果有前一个数据点，添加变化记录
    final newChangeHistory = List<IndexChangeData>.from(state.changeHistory);
    if (state.historicalData.isNotEmpty) {
      final previousData = state.historicalData.last;
      final changeData = IndexChangeData.calculateChange(
        currentData: event.dataPoint,
        previousData: previousData,
      );
      newChangeHistory.add(changeData);

      // 保持变化记录数量
      if (newChangeHistory.length > maxDataPoints - 1) {
        newChangeHistory.removeRange(
            0, newChangeHistory.length - (maxDataPoints - 1));
      }
    }

    emit(state.copyWith(
      historicalData: newData,
      changeHistory: newChangeHistory,
      lastUpdated: DateTime.now(),
    ));

    // 自动重新分析趋势
    if (newData.length >= state.settings.minDataPoints) {
      _onAnalyzeTrend(AnalyzeTrend(indexCode: event.dataPoint.code));
    }
  }

  /// 清除错误
  void _onClearError() {
    emit(state.copyWith(error: null));
  }

  /// 执行趋势分析
  TrendAnalysis _performTrendAnalysis(
    List<MarketIndexData> historicalData,
    List<IndexChangeData> changeHistory,
  ) {
    // 计算基本趋势
    final direction = _calculateTrendDirection(historicalData);
    final strength = _calculateTrendStrength(historicalData);
    final priceChange = _calculatePriceChange(historicalData);
    final percentageChange = _calculatePercentageChange(historicalData);
    final volatility = _calculateVolatility(historicalData);

    // 识别关键点
    final keyPoints = _identifyKeyPoints(historicalData);

    // 生成信号
    final signals =
        _generateSignals(historicalData, changeHistory, direction, strength);

    return TrendAnalysis(
      direction: direction,
      strength: strength,
      priceChange: priceChange,
      percentageChange: percentageChange,
      volatility: volatility,
      keyPoints: keyPoints,
      signals: signals,
      analysisTime: DateTime.now(),
    );
  }

  /// 计算趋势方向
  TrendDirection _calculateTrendDirection(List<MarketIndexData> data) {
    if (data.length < 2) return TrendDirection.unknown;

    // 使用线性回归计算趋势
    final n = data.length.toDouble();
    double sumX = 0;
    double sumY = 0;
    double sumXY = 0;
    double sumX2 = 0;

    for (int i = 0; i < data.length; i++) {
      final x = i.toDouble();
      final y = data[i].currentValue.toDouble();
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }

    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);

    if (slope > 0.5) {
      return TrendDirection.up;
    } else if (slope < -0.5) {
      return TrendDirection.down;
    } else {
      return TrendDirection.sideways;
    }
  }

  /// 计算趋势强度
  TrendStrength _calculateTrendStrength(List<MarketIndexData> data) {
    if (data.length < 3) return TrendStrength.weak;

    final changes = <double>[];
    for (int i = 1; i < data.length; i++) {
      final change = (data[i].currentValue.toDouble() -
              data[i - 1].currentValue.toDouble()) /
          data[i - 1].currentValue.toDouble();
      changes.add(change);
    }

    final positiveChanges = changes.where((c) => c > 0).length;
    final negativeChanges = changes.where((c) => c < 0).length;
    final totalChanges = changes.length;

    final consistency = (positiveChanges + negativeChanges) / totalChanges;

    if (consistency > 0.8) {
      return TrendStrength.strong;
    } else if (consistency > 0.6) {
      return TrendStrength.moderate;
    } else {
      return TrendStrength.weak;
    }
  }

  /// 计算价格变化
  double _calculatePriceChange(List<MarketIndexData> data) {
    if (data.length < 2) return 0.0;
    return data.last.currentValue.toDouble() -
        data.first.currentValue.toDouble();
  }

  /// 计算百分比变化
  double _calculatePercentageChange(List<MarketIndexData> data) {
    if (data.length < 2) return 0.0;
    final firstPrice = data.first.currentValue.toDouble();
    final lastPrice = data.last.currentValue.toDouble();
    return ((lastPrice - firstPrice) / firstPrice) * 100;
  }

  /// 计算波动率
  double _calculateVolatility(List<MarketIndexData> data) {
    if (data.length < 2) return 0.0;

    final returns = <double>[];
    for (int i = 1; i < data.length; i++) {
      final returnRate = (data[i].currentValue.toDouble() -
              data[i - 1].currentValue.toDouble()) /
          data[i - 1].currentValue.toDouble();
      returns.add(returnRate);
    }

    final mean = returns.reduce((a, b) => a + b) / returns.length;
    final variance = returns.map((r) {
          final diff = r - mean;
          return diff * diff;
        }).reduce((a, b) => a + b) /
        returns.length;

    return math.sqrt(variance);
  }

  /// 识别关键点
  List<TrendPoint> _identifyKeyPoints(List<MarketIndexData> data) {
    final keyPoints = <TrendPoint>[];

    if (data.length < 3) return keyPoints;

    // 简单的峰值和谷值检测
    for (int i = 1; i < data.length - 1; i++) {
      final prev = data[i - 1].currentValue.toDouble();
      final current = data[i].currentValue.toDouble();
      final next = data[i + 1].currentValue.toDouble();

      // 峰值
      if (current > prev && current > next) {
        keyPoints.add(TrendPoint(
          timestamp: data[i].updateTime,
          price: current,
          type: TrendPointType.peak,
          description: '峰值: ${current.toStringAsFixed(2)}',
        ));
      }
      // 谷值
      else if (current < prev && current < next) {
        keyPoints.add(TrendPoint(
          timestamp: data[i].updateTime,
          price: current,
          type: TrendPointType.trough,
          description: '谷值: ${current.toStringAsFixed(2)}',
        ));
      }
    }

    return keyPoints;
  }

  /// 生成信号
  List<TrendSignal> _generateSignals(
    List<MarketIndexData> data,
    List<IndexChangeData> changeHistory,
    TrendDirection direction,
    TrendStrength strength,
  ) {
    final signals = <TrendSignal>[];

    if (!state.settings.enableTechnicalSignals) return signals;

    // 基于趋势方向生成信号
    switch (direction) {
      case TrendDirection.up:
        if (strength == TrendStrength.strong) {
          signals.add(TrendSignal(
            type: TrendSignalType.buy,
            strength: TrendSignalStrength.strong,
            description: '强势上升趋势，建议买入',
            timestamp: DateTime.now(),
          ));
        } else {
          signals.add(TrendSignal(
            type: TrendSignalType.hold,
            strength: TrendSignalStrength.moderate,
            description: '上升趋势，建议持有',
            timestamp: DateTime.now(),
          ));
        }
        break;
      case TrendDirection.down:
        if (strength == TrendStrength.strong) {
          signals.add(TrendSignal(
            type: TrendSignalType.sell,
            strength: TrendSignalStrength.strong,
            description: '强势下降趋势，建议卖出',
            timestamp: DateTime.now(),
          ));
        } else {
          signals.add(TrendSignal(
            type: TrendSignalType.watch,
            strength: TrendSignalStrength.moderate,
            description: '下降趋势，建议观望',
            timestamp: DateTime.now(),
          ));
        }
        break;
      case TrendDirection.sideways:
        signals.add(TrendSignal(
          type: TrendSignalType.watch,
          strength: TrendSignalStrength.weak,
          description: '横盘整理，建议观望',
          timestamp: DateTime.now(),
        ));
        break;
      case TrendDirection.unknown:
        break;
    }

    return signals;
  }

  /// 获取指数名称
  String _getIndexName(String code) {
    final nameMap = {
      '000001': '上证指数',
      '399001': '深证成指',
      '399006': '创业板指',
      '000300': '沪深300',
      '000016': '上证50',
      '000905': '中证500',
      '000852': '中证1000',
      '000688': '科创50',
    };
    return nameMap[code] ?? code;
  }

  /// 确定市场状态
  MarketStatus _determineMarketStatus(DateTime time) {
    final hour = time.hour;
    final weekday = time.weekday;

    if (weekday == DateTime.saturday || weekday == DateTime.sunday) {
      return MarketStatus.holiday;
    }

    if ((hour == 9 && time.minute >= 30) ||
        (hour >= 10 && hour < 12) ||
        (hour >= 13 && hour < 15)) {
      return MarketStatus.trading;
    } else if (hour < 9) {
      return MarketStatus.preMarket;
    } else if (hour >= 15 && hour < 18) {
      return MarketStatus.postMarket;
    } else {
      return MarketStatus.closed;
    }
  }

  /// 确定数据质量级别
  DataQualityLevel _determineQualityLevel(double random) {
    if (random > 0.9) return DataQualityLevel.excellent;
    if (random > 0.7) return DataQualityLevel.good;
    if (random > 0.4) return DataQualityLevel.fair;
    return DataQualityLevel.poor;
  }

  /// 获取指定时间范围的数据
  List<MarketIndexData> getDataForPeriod(Duration period) {
    final cutoffTime = DateTime.now().subtract(period);
    return state.historicalData
        .where((data) => data.updateTime.isAfter(cutoffTime))
        .toList();
  }

  /// 获取最新价格
  double? getLatestPrice() {
    if (state.historicalData.isEmpty) return null;
    return state.historicalData.last.currentValue.toDouble();
  }

  /// 获取价格变化
  double getPriceChange() {
    if (state.historicalData.length < 2) return 0.0;
    final latest = state.historicalData.last.currentValue.toDouble();
    final previous = state
        .historicalData[state.historicalData.length - 2].currentValue
        .toDouble();
    return latest - previous;
  }

  /// 获取价格变化百分比
  double getPriceChangePercentage() {
    if (state.historicalData.length < 2) return 0.0;
    final latest = state.historicalData.last.currentValue.toDouble();
    final previous = state
        .historicalData[state.historicalData.length - 2].currentValue
        .toDouble();
    return ((latest - previous) / previous) * 100;
  }

  // 页面期望的方法和属性
  /// 获取当前选择的指数代码
  String? get selectedIndexCode =>
      state.indexCode.isEmpty ? null : state.indexCode;

  /// 选择指数
  Future<void> selectIndex(String indexCode) async {
    if (indexCode != state.indexCode) {
      await onEvent(LoadTrendData(indexCode: indexCode));
    }
  }
}
