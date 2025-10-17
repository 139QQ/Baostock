import 'package:flutter/material.dart';
import '../../domain/models/fund.dart';
import '../../domain/models/fund_filter.dart';

/// 基金高级筛选面板组�?
///
/// 提供多维度筛选条件：
/// - 基金类型选择
/// - 风险等级筛�?
/// - 基金规模范围
/// - 成立时间范围
/// - 基金公司筛�?
/// - 基金经理筛�?
class FundFilterPanel extends StatefulWidget {
  final FundFilter filters;
  final Function(FundFilter) onFiltersChanged;

  const FundFilterPanel({
    super.key,
    required this.filters,
    required this.onFiltersChanged,
  });

  @override
  State<FundFilterPanel> createState() => _FundFilterPanelState();
}

class _FundFilterPanelState extends State<FundFilterPanel> {
  late FundFilter _currentFilters;

  // 基金类型选项
  final List<String> _fundTypes = [
    '股票�?,
    '债券�?,
    '混合�?,
    '货币�?,
    '指数�?,
    'QDII',
    'FOF',
  ];

  // 风险等级选项
  final List<Map<String, dynamic>> _riskLevels = [
    {'level': 'R1', 'name': '低风�?, 'color': const Color(0xFF10B981)},
    {'level': 'R2', 'name': '中低风险', 'color': const Color(0xFF84CC16)},
    {'level': 'R3', 'name': '中等风险', 'color': const Color(0xFFF59E0B)},
    {'level': 'R4', 'name': '中高风险', 'color': const Color(0xFFF97316)},
    {'level': 'R5', 'name': '高风�?, 'color': const Color(0xFFEF4444)},
  ];

  @override
  void initState() {
    super.initState();
    _currentFilters = widget.filters;
  }

  /// 处理基金类型选择
  void _handleFundTypeToggle(String fundType) {
    setState(() {
      final types = List<String>.from(_currentFilters.fundTypes);
      if (types.contains(fundType)) {
        types.remove(fundType);
      } else {
        types.add(fundType);
      }
      _currentFilters = _currentFilters.copyWith(fundTypes: types);
    });
  }

  /// 处理风险等级选择
  void _handleRiskLevelToggle(String riskLevel) {
    setState(() {
      final levels = List<String>.from(_currentFilters.riskLevels);
      if (levels.contains(riskLevel)) {
        levels.remove(riskLevel);
      } else {
        levels.add(riskLevel);
      }
      _currentFilters = _currentFilters.copyWith(riskLevels: levels);
    });
  }

  /// 处理基金规模变化
  void _handleScaleChanged(RangeValues values) {
    setState(() {
      _currentFilters = _currentFilters.copyWith(
        minScale: values.start,
        maxScale: values.end,
      );
    });
  }

  /// 处理成立时间变化
  void _handleEstablishDateChanged(DateTime? start, DateTime? end) {
    setState(() {
      _currentFilters = _currentFilters.copyWith(
        establishStart: start,
        establishEnd: end,
      );
    });
  }

  /// 应用筛选条�?
  void _applyFilters() {
    widget.onFiltersChanged(_currentFilters);
  }

  /// 重置筛选条�?
  void _resetFilters() {
    setState(() {
      _currentFilters = FundFilter();
    });
  }

  /// 获取当前筛选结果数量（模拟�?
  String _getResultCount() {
    // 模拟计算结果数量
    int count = 1200; // 基础数量

    // 根据筛选条件调整数�?
    if (_currentFilters.fundTypes.isNotEmpty) {
      count = (count * 0.3).round();
    }
    if (_currentFilters.riskLevels.isNotEmpty) {
      count = (count * 0.6).round();
    }
    if (_currentFilters.minScale != null || _currentFilters.maxScale != null) {
      count = (count * 0.8).round();
    }
    if (_currentFilters.establishStart != null ||
        _currentFilters.establishEnd != null) {
      count = (count * 0.9).round();
    }

    return '�?$count 只基�?;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题�?
              Row(
                children: [
                  const Icon(
                    Icons.filter_list,
                    color: Color(0xFF1E40AF),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '高级筛�?,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const Spacer(),

                  // 结果预览
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _getResultCount(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 基金类型筛�?
              _buildFilterSection(
                title: '基金类型',
                child: _buildFundTypeSelector(),
              ),

              const SizedBox(height: 20),

              // 风险等级筛�?
              _buildFilterSection(
                title: '风险等级',
                child: _buildRiskLevelSelector(),
              ),

              const SizedBox(height: 20),

              // 基金规模筛�?
              _buildFilterSection(
                title: '基金规模',
                child: _buildScaleRangeSelector(),
              ),

              const SizedBox(height: 20),

              // 成立时间筛�?
              _buildFilterSection(
                title: '成立时间',
                child: _buildDateRangeSelector(),
              ),

              const SizedBox(height: 24),

              // 操作按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // 重置按钮
                  TextButton(
                    onPressed: _resetFilters,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      '重置',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // 应用筛选按�?
                  ElevatedButton.icon(
                    onPressed: _applyFilters,
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('应用筛�?),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E40AF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建筛选区域标�?
  Widget _buildFilterSection({
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const Spacer(),
            if (title == '基金类型' || title == '风险等级')
              TextButton(
                onPressed: () {
                  if (title == '基金类型') {
                    setState(() {
                      _currentFilters = _currentFilters.copyWith(
                        fundTypes: _currentFilters.fundTypes.length ==
                                _fundTypes.length
                            ? []
                            : List.from(_fundTypes),
                      );
                    });
                  } else if (title == '风险等级') {
                    setState(() {
                      _currentFilters = _currentFilters.copyWith(
                        riskLevels: _currentFilters.riskLevels.length ==
                                _riskLevels.length
                            ? []
                            : _riskLevels
                                .map((e) => e['level'] as String)
                                .toList(),
                      );
                    });
                  }
                },
                child: Text(
                  title == '基金类型'
                      ? (_currentFilters.fundTypes.length == _fundTypes.length
                          ? '取消全�?
                          : '全�?)
                      : (_currentFilters.riskLevels.length == _riskLevels.length
                          ? '取消全�?
                          : '全�?),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  /// 构建基金类型选择�?
  Widget _buildFundTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _fundTypes.map((fundType) {
        final isSelected = _currentFilters.fundTypes.contains(fundType);
        final color = Fund.getFundTypeColor(fundType);

        return FilterChip(
          label: Text(fundType),
          selected: isSelected,
          onSelected: (selected) => _handleFundTypeToggle(fundType),
          selectedColor: color.withOpacity(0.2),
          backgroundColor: Colors.grey.shade100,
          labelStyle: TextStyle(
            color: isSelected ? color : Colors.grey.shade700,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(
              color: isSelected ? color.withOpacity(0.5) : Colors.transparent,
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 构建风险等级选择�?
  Widget _buildRiskLevelSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _riskLevels.map((riskLevel) {
        final level = riskLevel['level'] as String;
        final name = riskLevel['name'] as String;
        final color = riskLevel['color'] as Color;
        final isSelected = _currentFilters.riskLevels.contains(level);

        return FilterChip(
          label: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                level,
                style: const TextStyle(fontSize: 10),
              ),
              Text(
                name,
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
          selected: isSelected,
          onSelected: (selected) => _handleRiskLevelToggle(level),
          selectedColor: color.withOpacity(0.2),
          backgroundColor: Colors.grey.shade100,
          labelStyle: TextStyle(
            color: isSelected ? color : Colors.grey.shade700,
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(
              color: isSelected ? color.withOpacity(0.5) : Colors.transparent,
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 构建基金规模范围选择�?
  Widget _buildScaleRangeSelector() {
    final minScale = _currentFilters.minScale ?? 0;
    final maxScale = _currentFilters.maxScale ?? 1000;

    return Column(
      children: [
        Row(
          children: [
            Text(
              '${minScale.toInt()}�?,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const Spacer(),
            Text(
              '${maxScale.toInt()}�?',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        RangeSlider(
          values: RangeValues(minScale, maxScale),
          onChanged: _handleScaleChanged,
          min: 0,
          max: 1000,
          divisions: 20,
          labels: RangeLabels(
            '${minScale.toInt()}�?,
            '${maxScale.toInt()}�?',
          ),
          activeColor: const Color(0xFF1E40AF),
          inactiveColor: Colors.grey.shade300,
        ),
        const SizedBox(height: 4),
        Text(
          '拖动滑块设置基金规模范围',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  /// 构建成立时间范围选择�?
  Widget _buildDateRangeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildDatePicker(
            label: '开始日�?,
            date: _currentFilters.establishStart,
            onDateSelected: (date) {
              _handleEstablishDateChanged(
                date,
                _currentFilters.establishEnd,
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDatePicker(
            label: '结束日期',
            date: _currentFilters.establishEnd,
            onDateSelected: (date) {
              _handleEstablishDateChanged(
                _currentFilters.establishStart,
                date,
              );
            },
          ),
        ),
      ],
    );
  }

  /// 构建日期选择�?
  Widget _buildDatePicker({
    required String label,
    required DateTime? date,
    required Function(DateTime?) onDateSelected,
  }) {
    return InkWell(
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate:
              date ?? DateTime.now().subtract(const Duration(days: 365 * 5)),
          firstDate: DateTime(1990),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme light(
                  primary: const Color(0xFF1E40AF),
                ),
              ),
              child: child!,
            );
          },
        );

        if (selectedDate != null) {
          onDateSelected(selectedDate);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 16,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date != null
                    ? '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
                    : label,
                style: TextStyle(
                  fontSize: 13,
                  color: date != null ? Colors.black87 : Colors.grey.shade600,
                ),
              ),
            ),
            if (date != null)
              IconButton(
                icon: const Icon(Icons.clear, size: 16),
                onPressed: () => onDateSelected(null),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }
}
