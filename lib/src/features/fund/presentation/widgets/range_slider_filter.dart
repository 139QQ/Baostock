import 'package:flutter/material.dart';
import '../../domain/entities/fund_filter_criteria.dart';

/// 范围滑块筛选组件
///
/// 用于数值范围筛选，如基金规模、收益率等。
/// 支持自定义范围、标签格式、滑块样式等。
class RangeSliderFilter extends StatefulWidget {
  /// 当前范围值
  final RangeValue? value;

  /// 最小值
  final double min;

  /// 最大值
  final double max;

  /// 分段数
  final int divisions;

  /// 变化回调
  final ValueChanged<RangeValue?> onChanged;

  /// 起始变化回调
  final ValueChanged<double>? onChangeStart;

  /// 结束变化回调
  final ValueChanged<double>? onChangeEnd;

  /// 标签格式化函数
  final String Function(double value)? labelFormatter;

  /// 标题
  final String? title;

  /// 副标题
  final String? subtitle;

  /// 是否显示数值输入框
  final bool showInputs;

  /// 是否显示范围描述
  final bool showDescription;

  /// 是否启用
  final bool enabled;

  /// 滑块主题
  final RangeSliderThemeData? theme;

  /// 输入框样式
  final InputDecoration? inputDecoration;

  /// 是否允许禁用筛选
  final bool canDisable;

  /// 禁用状态回调
  final VoidCallback? onDisabled;

  /// 当前是否禁用
  final bool disabled;

  const RangeSliderFilter({
    super.key,
    this.value,
    required this.min,
    required this.max,
    this.divisions = 20,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.labelFormatter,
    this.title,
    this.subtitle,
    this.showInputs = true,
    this.showDescription = true,
    this.enabled = true,
    this.theme,
    this.inputDecoration,
    this.canDisable = true,
    this.onDisabled,
    this.disabled = false,
  });

  @override
  State<RangeSliderFilter> createState() => _RangeSliderFilterState();

  /// 创建基金规模筛选器
  factory RangeSliderFilter.fundScale({
    RangeValue? value,
    ValueChanged<RangeValue?>? onChanged,
    bool disabled = false,
    VoidCallback? onDisabled,
  }) {
    return RangeSliderFilter(
      title: '基金规模',
      subtitle: '选择基金规模范围（单位：亿元）',
      value: value,
      min: 0,
      max: 1000,
      divisions: 20,
      labelFormatter: (value) => '${value.toStringAsFixed(0)}亿',
      onChanged: onChanged ?? (value) {},
      canDisable: true,
      onDisabled: onDisabled,
      disabled: disabled,
    );
  }

  /// 创建收益率筛选器
  factory RangeSliderFilter.returnRate({
    RangeValue? value,
    ValueChanged<RangeValue?>? onChanged,
    bool disabled = false,
    VoidCallback? onDisabled,
  }) {
    return RangeSliderFilter(
      title: '年化收益率',
      subtitle: '选择基金年化收益率范围（单位：%）',
      value: value,
      min: -50,
      max: 100,
      divisions: 30,
      labelFormatter: (value) => '${value.toStringAsFixed(1)}%',
      onChanged: onChanged ?? (value) {},
      canDisable: true,
      onDisabled: onDisabled,
      disabled: disabled,
    );
  }
}

class _RangeSliderFilterState extends State<RangeSliderFilter> {
  late final TextEditingController _minController;
  late final TextEditingController _maxController;
  late bool _disabled;
  late RangeValue? _currentValue;

  @override
  void initState() {
    super.initState();
    _disabled = widget.disabled;
    _currentValue = widget.value;
    _minController = TextEditingController();
    _maxController = TextEditingController();
    _updateControllers();
  }

  @override
  void didUpdateWidget(RangeSliderFilter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value ||
        widget.disabled != oldWidget.disabled) {
      _currentValue = widget.value;
      _disabled = widget.disabled;
      _updateControllers();
    }
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _updateControllers() {
    if (_currentValue != null && !_disabled) {
      _minController.text = _formatValue(_currentValue!.min);
      _maxController.text = _formatValue(_currentValue!.max);
    } else {
      _minController.clear();
      _maxController.clear();
    }
  }

  String _formatValue(double value) {
    if (widget.labelFormatter != null) {
      return widget.labelFormatter!(value);
    }
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  }

  RangeValues _getRangeValues() {
    if (_currentValue == null || _disabled) {
      return RangeValues(widget.min, widget.max);
    }
    return RangeValues(_currentValue!.min, _currentValue!.max);
  }

  void _onSliderChanged(RangeValues values) {
    if (!widget.enabled) return;

    final newValue = RangeValue(min: values.start, max: values.end);
    setState(() {
      _currentValue = newValue;
    });
    _updateControllers();

    widget.onChanged(newValue);
  }

  void _onMinChanged(String text) {
    if (!widget.enabled || text.isEmpty) return;

    final value = double.tryParse(text);
    if (value != null && value >= widget.min && value <= widget.max) {
      final currentMax = _currentValue?.max ?? widget.max;
      final newMax = value > currentMax ? value : currentMax;
      final newValue = RangeValue(min: value, max: newMax);
      setState(() {
        _currentValue = newValue;
      });
      widget.onChanged(newValue);
    }
  }

  void _onMaxChanged(String text) {
    if (!widget.enabled || text.isEmpty) return;

    final value = double.tryParse(text);
    if (value != null && value >= widget.min && value <= widget.max) {
      final currentMin = _currentValue?.min ?? widget.min;
      final newMin = value < currentMin ? value : currentMin;
      final newValue = RangeValue(min: newMin, max: value);
      setState(() {
        _currentValue = newValue;
      });
      widget.onChanged(newValue);
    }
  }

  void _toggleDisabled() {
    if (!widget.canDisable) return;

    setState(() {
      _disabled = !_disabled;
      if (_disabled) {
        _currentValue = null;
      } else {
        _currentValue = RangeValue(min: widget.min, max: widget.max);
      }
    });
    _updateControllers();

    if (_disabled) {
      widget.onChanged(null);
    } else {
      widget.onChanged(_currentValue);
    }

    widget.onDisabled?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题区域
        if (widget.title != null) ...[
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title!,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.canDisable)
                GestureDetector(
                  onTap: _toggleDisabled,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: _disabled ? colors.error.withOpacity(0.1) : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _disabled
                              ? Icons.radio_button_unchecked
                              : Icons.check_circle,
                          size: 16,
                          color: _disabled ? colors.error : colors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _disabled ? '已禁用' : '启用',
                          style: TextStyle(
                            fontSize: 12,
                            color: _disabled ? colors.error : colors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // 数值输入框
        if (widget.showInputs && !_disabled) ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minController,
                  decoration: widget.inputDecoration?.copyWith(
                        labelText: '最小值',
                        hintText: widget.min.toString(),
                      ) ??
                      InputDecoration(
                        labelText: '最小值',
                        hintText: widget.min.toString(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                  keyboardType: TextInputType.number,
                  enabled: widget.enabled,
                  onChanged: _onMinChanged,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _maxController,
                  decoration: widget.inputDecoration?.copyWith(
                        labelText: '最大值',
                        hintText: widget.max.toString(),
                      ) ??
                      InputDecoration(
                        labelText: '最大值',
                        hintText: widget.max.toString(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                  keyboardType: TextInputType.number,
                  enabled: widget.enabled,
                  onChanged: _onMaxChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // 范围滑块
        Opacity(
          opacity: widget.enabled ? 1.0 : 0.5,
          child: RangeSlider(
            values: _getRangeValues(),
            min: widget.min,
            max: widget.max,
            divisions: widget.divisions,
            labels: RangeLabels(
              _formatValue(_getRangeValues().start),
              _formatValue(_getRangeValues().end),
            ),
            onChanged: widget.enabled ? _onSliderChanged : null,
            onChangeStart: (values) => widget.onChangeStart?.call(values.start),
            onChangeEnd: (values) => widget.onChangeEnd?.call(values.end),
            activeColor: widget.theme?.activeColor ?? colors.primary,
            inactiveColor: widget.theme?.inactiveColor ?? colors.surfaceVariant,
          ),
        ),

        // 范围描述
        if (widget.showDescription) ...[
          const SizedBox(height: 8),
          Text(
            _disabled
                ? '当前筛选已禁用'
                : '已选择范围：${_currentValue != null ? '${_formatValue(_currentValue!.min)} - ${_formatValue(_currentValue!.max)}' : '未设置'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ],
    );
  }
}

/// 范围滑块主题数据
class RangeSliderThemeData {
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? thumbColor;
  final Color? overlayColor;
  final double? trackHeight;

  RangeSliderThemeData({
    this.activeColor,
    this.inactiveColor,
    this.thumbColor,
    this.overlayColor,
    this.trackHeight,
  });
}
