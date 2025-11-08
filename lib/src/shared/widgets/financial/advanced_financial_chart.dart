import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/performance/performance_detector.dart';
import '../../../core/theme/design_tokens/app_colors.dart';
import '../../../core/theme/design_tokens/app_typography.dart';

/// 金融数据点
class FinancialDataPoint {
  final DateTime timestamp;
  final double value;
  final double? volume;
  final Map<String, dynamic>? metadata;

  const FinancialDataPoint({
    required this.timestamp,
    required this.value,
    this.volume,
    this.metadata,
  });

  /// 转换为图表数据点
  ChartDataPoint toChartDataPoint() {
    return ChartDataPoint(
      x: timestamp.millisecondsSinceEpoch,
      y: value,
      volume: volume,
    );
  }
}

/// 图表数据点
class ChartDataPoint {
  final num x;
  final num y;
  final double? volume;

  const ChartDataPoint({
    required this.x,
    required this.y,
    this.volume,
  });
}

/// 简化的图表控制器
class ChartSeriesController {
  void updateDataSource({
    List<int>? addedDataIndexes,
    List<int>? removedDataIndexes,
  }) {
    // 简化实现
  }
}

/// 图表点详情
class ChartPointDetails {
  final int pointIndex;

  ChartPointDetails({required this.pointIndex});
}

/// 图表类型枚举
enum ChartType {
  line, // 折线图
  area, // 面积图
  candlestick, // K线图
  bar, // 柱状图
  scatter, // 散点图
}

/// 时间范围枚举
enum TimeRange {
  day1, // 1天
  week1, // 1周
  month1, // 1月
  month3, // 3月
  month6, // 6月
  year1, // 1年
  year3, // 3年
  all, // 全部
}

/// 高级金融图表配置
class FinancialChartConfig {
  final ChartType chartType;
  final TimeRange timeRange;
  final bool showVolume;
  final bool showGridLines;
  final bool showTooltip;
  final bool enableZoom;
  final bool enablePan;
  final bool enableCrosshair;
  final Color primaryColor;
  final Color positiveColor;
  final Color negativeColor;
  final double animationDuration;
  final bool adaptiveRendering;

  const FinancialChartConfig({
    this.chartType = ChartType.line,
    this.timeRange = TimeRange.month1,
    this.showVolume = true,
    this.showGridLines = true,
    this.showTooltip = true,
    this.enableZoom = true,
    this.enablePan = true,
    this.enableCrosshair = true,
    this.primaryColor = BaseColors.primary500,
    this.positiveColor = FinancialColors.positive,
    this.negativeColor = FinancialColors.negative,
    this.animationDuration = 300.0,
    this.adaptiveRendering = true,
  });

  FinancialChartConfig copyWith({
    ChartType? chartType,
    TimeRange? timeRange,
    bool? showVolume,
    bool? showGridLines,
    bool? showTooltip,
    bool? enableZoom,
    bool? enablePan,
    bool? enableCrosshair,
    Color? primaryColor,
    Color? positiveColor,
    Color? negativeColor,
    double? animationDuration,
    bool? adaptiveRendering,
  }) {
    return FinancialChartConfig(
      chartType: chartType ?? this.chartType,
      timeRange: timeRange ?? this.timeRange,
      showVolume: showVolume ?? this.showVolume,
      showGridLines: showGridLines ?? this.showGridLines,
      showTooltip: showTooltip ?? this.showTooltip,
      enableZoom: enableZoom ?? this.enableZoom,
      enablePan: enablePan ?? this.enablePan,
      enableCrosshair: enableCrosshair ?? this.enableCrosshair,
      primaryColor: primaryColor ?? this.primaryColor,
      positiveColor: positiveColor ?? this.positiveColor,
      negativeColor: negativeColor ?? this.negativeColor,
      animationDuration: animationDuration ?? this.animationDuration,
      adaptiveRendering: adaptiveRendering ?? this.adaptiveRendering,
    );
  }
}

/// 高级金融图表组件（简化版本）
class AdvancedFinancialChart extends StatefulWidget {
  final List<FinancialDataPoint> data;
  final FinancialChartConfig config;
  final String title;
  final String? subtitle;
  final double height;
  final Function(FinancialDataPoint)? onPointTap;
  final Function(TimeRange)? onTimeRangeChanged;
  final Function(ChartType)? onChartTypeChanged;

  const AdvancedFinancialChart({
    Key? key,
    required this.data,
    this.config = const FinancialChartConfig(),
    this.title = '',
    this.subtitle,
    this.height = 300.0,
    this.onPointTap,
    this.onTimeRangeChanged,
    this.onChartTypeChanged,
  }) : super(key: key);

  @override
  State<AdvancedFinancialChart> createState() => _AdvancedFinancialChartState();
}

class _AdvancedFinancialChartState extends State<AdvancedFinancialChart>
    with TickerProviderStateMixin {
  late FinancialChartConfig _currentConfig;
  late List<FinancialDataPoint> _processedData;
  late AnimationController _animationController;
  late Animation<double> _animation;

  // 性能监控
  late StreamSubscription<PerformanceResult> _performanceSubscription;
  PerformanceLevel _currentPerformanceLevel = PerformanceLevel.good;

  @override
  void initState() {
    super.initState();
    _initializeChart();
    _setupPerformanceMonitoring();
  }

  void _initializeChart() {
    _currentConfig = widget.config;
    _processedData = _processData(widget.data);

    // 初始化动画控制器
    final duration = _getAdaptiveAnimationDuration();
    _animationController = AnimationController(
      duration: Duration(milliseconds: duration),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // 启动动画
    _animationController.forward();
  }

  void _setupPerformanceMonitoring() {
    // 监听性能变化
    _performanceSubscription = SmartPerformanceDetector.instance
        .detectPerformance()
        .asStream()
        .listen((result) {
      if (result.level != _currentPerformanceLevel) {
        setState(() {
          _currentPerformanceLevel = result.level;
          _adaptToPerformanceLevel(result.level);
        });
      }
    });
  }

  void _adaptToPerformanceLevel(PerformanceLevel level) {
    if (!_currentConfig.adaptiveRendering) return;

    setState(() {
      switch (level) {
        case PerformanceLevel.poor:
          _currentConfig = _currentConfig.copyWith(
            showGridLines: false,
            showVolume: false,
            animationDuration: 0,
            enableZoom: false,
          );
          break;
        case PerformanceLevel.fair:
          _currentConfig = _currentConfig.copyWith(
            showGridLines: true,
            showVolume: false,
            animationDuration: 150,
          );
          break;
        case PerformanceLevel.good:
          _currentConfig = _currentConfig.copyWith(
            showGridLines: true,
            showVolume: true,
            animationDuration: 300,
          );
          break;
        case PerformanceLevel.excellent:
          // 保持所有高级功能
          break;
      }
    });
  }

  int _getAdaptiveAnimationDuration() {
    switch (_currentPerformanceLevel) {
      case PerformanceLevel.poor:
        return 0;
      case PerformanceLevel.fair:
        return 150;
      case PerformanceLevel.good:
        return 300;
      case PerformanceLevel.excellent:
        return 500;
    }
  }

  List<FinancialDataPoint> _processData(List<FinancialDataPoint> rawData) {
    if (rawData.isEmpty) return [];

    // 按时间范围过滤数据
    final now = DateTime.now();
    final cutoff =
        now.subtract(_getTimeRangeDuration(_currentConfig.timeRange));

    var filteredData =
        rawData.where((point) => point.timestamp.isAfter(cutoff)).toList();

    // 根据性能级别调整数据点数量
    final maxPoints = _getMaxDataPoints();
    if (filteredData.length > maxPoints) {
      filteredData = _downsampleData(filteredData, maxPoints);
    }

    return filteredData;
  }

  Duration _getTimeRangeDuration(TimeRange range) {
    switch (range) {
      case TimeRange.day1:
        return const Duration(days: 1);
      case TimeRange.week1:
        return const Duration(days: 7);
      case TimeRange.month1:
        return const Duration(days: 30);
      case TimeRange.month3:
        return const Duration(days: 90);
      case TimeRange.month6:
        return const Duration(days: 180);
      case TimeRange.year1:
        return const Duration(days: 365);
      case TimeRange.year3:
        return const Duration(days: 1095);
      case TimeRange.all:
        return const Duration(days: 3650);
    }
  }

  int _getMaxDataPoints() {
    switch (_currentPerformanceLevel) {
      case PerformanceLevel.poor:
        return 50;
      case PerformanceLevel.fair:
        return 100;
      case PerformanceLevel.good:
        return 200;
      case PerformanceLevel.excellent:
        return 500;
    }
  }

  List<FinancialDataPoint> _downsampleData(
    List<FinancialDataPoint> data,
    int maxPoints,
  ) {
    if (data.length <= maxPoints) return data;

    final step = data.length / maxPoints;
    final downsampled = <FinancialDataPoint>[];

    for (int i = 0; i < maxPoints; i++) {
      final index = (i * step).round();
      if (index < data.length) {
        downsampled.add(data[index]);
      }
    }

    return downsampled;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          Expanded(
            child: _buildChart(),
          ),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: AppTextStyles.h5,
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: NeutralColors.neutral600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            _buildPerformanceIndicator(),
          ],
        ),
      ],
    );
  }

  Widget _buildPerformanceIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getPerformanceLevelColor(_currentPerformanceLevel)
            .withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getPerformanceLevelColor(_currentPerformanceLevel)
              .withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getPerformanceIcon(),
            size: 12,
            color: _getPerformanceLevelColor(_currentPerformanceLevel),
          ),
          const SizedBox(width: 4),
          Text(
            _getPerformanceDisplayName(_currentPerformanceLevel),
            style: AppTextStyles.caption.copyWith(
              color: _getPerformanceLevelColor(_currentPerformanceLevel),
              fontWeight: FontWeights.medium,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPerformanceLevelColor(PerformanceLevel level) {
    switch (level) {
      case PerformanceLevel.excellent:
        return SemanticColors.success500;
      case PerformanceLevel.good:
        return BaseColors.primary500;
      case PerformanceLevel.fair:
        return SemanticColors.warning500;
      case PerformanceLevel.poor:
        return SemanticColors.error500;
    }
  }

  String _getPerformanceDisplayName(PerformanceLevel level) {
    switch (level) {
      case PerformanceLevel.excellent:
        return '优秀';
      case PerformanceLevel.good:
        return '良好';
      case PerformanceLevel.fair:
        return '一般';
      case PerformanceLevel.poor:
        return '较差';
    }
  }

  IconData _getPerformanceIcon() {
    switch (_currentPerformanceLevel) {
      case PerformanceLevel.excellent:
        return Icons.speed;
      case PerformanceLevel.good:
        return Icons.check_circle;
      case PerformanceLevel.fair:
        return Icons.info;
      case PerformanceLevel.poor:
        return Icons.warning;
    }
  }

  Widget _buildChart() {
    if (_processedData.isEmpty) {
      return _buildEmptyState();
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: _buildSimplifiedChart(),
        );
      },
    );
  }

  Widget _buildSimplifiedChart() {
    // 简化的图表实现
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NeutralColors.neutral50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: NeutralColors.neutral200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_chart_outlined,
            size: 48,
            color: NeutralColors.neutral400,
          ),
          const SizedBox(height: 16),
          Text(
            '图表 (${_processedData.length} 个数据点)',
            style: AppTextStyles.bodyLarge.copyWith(
              color: NeutralColors.neutral600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '图表类型: ${_getChartTypeName(_currentConfig.chartType)}',
            style: AppTextStyles.bodySmall.copyWith(
              color: NeutralColors.neutral500,
            ),
          ),
        ],
      ),
    );
  }

  String _getChartTypeName(ChartType type) {
    switch (type) {
      case ChartType.line:
        return '折线图';
      case ChartType.area:
        return '面积图';
      case ChartType.candlestick:
        return 'K线图';
      case ChartType.bar:
        return '柱状图';
      case ChartType.scatter:
        return '散点图';
    }
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: NeutralColors.neutral50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: NeutralColors.neutral200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_chart_outlined,
            size: 48,
            color: NeutralColors.neutral400,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无数据',
            style: AppTextStyles.bodyLarge.copyWith(
              color: NeutralColors.neutral600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请稍后重试或联系技术支持',
            style: AppTextStyles.bodySmall.copyWith(
              color: NeutralColors.neutral500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Column(
      children: [
        const SizedBox(height: 16),
        _buildChartTypeSelector(),
        const SizedBox(height: 8),
        _buildTimeRangeSelector(),
      ],
    );
  }

  Widget _buildChartTypeSelector() {
    return Row(
      children: [
        Text(
          '图表类型: ',
          style: AppTextStyles.label.copyWith(
            color: NeutralColors.neutral700,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ChartType.values.map((type) {
                final isSelected = _currentConfig.chartType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_getChartTypeName(type)),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _currentConfig =
                              _currentConfig.copyWith(chartType: type);
                        });
                        widget.onChartTypeChanged?.call(type);
                      }
                    },
                    backgroundColor: NeutralColors.neutral100,
                    selectedColor: _currentConfig.primaryColor.withOpacity(0.2),
                    checkmarkColor: _currentConfig.primaryColor,
                    labelStyle: AppTextStyles.caption.copyWith(
                      color: isSelected
                          ? _currentConfig.primaryColor
                          : NeutralColors.neutral700,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeRangeSelector() {
    return Row(
      children: [
        Text(
          '时间范围: ',
          style: AppTextStyles.label.copyWith(
            color: NeutralColors.neutral700,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: TimeRange.values.map((range) {
                final isSelected = _currentConfig.timeRange == range;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_getTimeRangeName(range)),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _currentConfig =
                              _currentConfig.copyWith(timeRange: range);
                          _processedData = _processData(widget.data);
                        });
                        widget.onTimeRangeChanged?.call(range);
                      }
                    },
                    backgroundColor: NeutralColors.neutral100,
                    selectedColor: _currentConfig.primaryColor.withOpacity(0.2),
                    checkmarkColor: _currentConfig.primaryColor,
                    labelStyle: AppTextStyles.caption.copyWith(
                      color: isSelected
                          ? _currentConfig.primaryColor
                          : NeutralColors.neutral700,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  String _getTimeRangeName(TimeRange range) {
    switch (range) {
      case TimeRange.day1:
        return '1天';
      case TimeRange.week1:
        return '1周';
      case TimeRange.month1:
        return '1月';
      case TimeRange.month3:
        return '3月';
      case TimeRange.month6:
        return '6月';
      case TimeRange.year1:
        return '1年';
      case TimeRange.year3:
        return '3年';
      case TimeRange.all:
        return '全部';
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _performanceSubscription.cancel();
    super.dispose();
  }
}

/// 智能图表工厂
class SmartChartFactory {
  /// 创建性能优化的图表
  static Widget createOptimizedChart({
    required List<FinancialDataPoint> data,
    required String title,
    FinancialChartConfig? config,
    double? height,
    BuildContext? context,
  }) {
    // 根据性能级别自动调整配置
    final performanceLevel = PerformanceAdaptiveManager.instance.currentLevel;
    final adaptiveConfig = _getAdaptiveConfig(
        config ?? const FinancialChartConfig(), performanceLevel);

    return AdvancedFinancialChart(
      data: data,
      config: adaptiveConfig,
      title: title,
      height: height ?? 300.0,
    );
  }

  static FinancialChartConfig _getAdaptiveConfig(
    FinancialChartConfig baseConfig,
    PerformanceLevel level,
  ) {
    switch (level) {
      case PerformanceLevel.poor:
        return baseConfig.copyWith(
          chartType: ChartType.line,
          showVolume: false,
          showGridLines: false,
          animationDuration: 0,
          enableZoom: false,
          enablePan: false,
          enableCrosshair: false,
        );
      case PerformanceLevel.fair:
        return baseConfig.copyWith(
          showVolume: false,
          showGridLines: true,
          animationDuration: 150,
        );
      case PerformanceLevel.good:
        return baseConfig.copyWith(
          animationDuration: 300,
        );
      case PerformanceLevel.excellent:
        return baseConfig;
    }
  }
}
