import 'package:flutter/material.dart';
import '../../domain/entities/fund_search_criteria.dart';

/// 高级搜索筛选器
///
/// 提供多条件组合筛选功能，包括：
/// - 基金类型筛选
/// - 基金公司筛选
/// - 收益率范围筛选
/// - 净值范围筛选
/// - 成立时间筛选
class AdvancedSearchFilter extends StatefulWidget {
  final FundSearchCriteria initialCriteria;
  final Function(FundSearchCriteria) onFilterChanged;

  const AdvancedSearchFilter({
    super.key,
    required this.initialCriteria,
    required this.onFilterChanged,
  });

  @override
  State<AdvancedSearchFilter> createState() => _AdvancedSearchFilterState();
}

class _AdvancedSearchFilterState extends State<AdvancedSearchFilter> {
  late FundSearchCriteria _criteria;

  // 基金类型选项
  final List<String> _fundTypes = [
    '全部',
    '股票型',
    '债券型',
    '混合型',
    '货币型',
    '指数型',
    'QDII',
    'FOF',
  ];

  // 基金公司选项（热门公司）
  final List<String> _fundCompanies = [
    '全部',
    '华夏基金',
    '易方达基金',
    '南方基金',
    '嘉实基金',
    '博时基金',
    '广发基金',
    '汇添富基金',
    '富国基金',
    '招商基金',
  ];

  // 收益率范围选项
  final List<String> _returnRanges = [
    '不限',
    '近1年 > 10%',
    '近1年 > 15%',
    '近1年 > 20%',
    '近1年 > 30%',
    '近3年 > 30%',
    '近3年 > 50%',
    '近3年 > 100%',
  ];

  // 净值范围选项
  final List<String> _navRanges = [
    '不限',
    '1.0元以下',
    '1.0-1.5元',
    '1.5-2.0元',
    '2.0-3.0元',
    '3.0元以上',
  ];

  @override
  void initState() {
    super.initState();
    _criteria = widget.initialCriteria;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              Icon(
                Icons.tune,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '高级筛选',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _resetFilters,
                child: const Text('重置'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 基金类型筛选
          _buildFilterSection(
            '基金类型',
            Icons.category,
            _fundTypes
                .map((type) => {
                      'label': type,
                      'value': type,
                      'selected': _criteria.fundType == type ||
                          (type == '全部' && _criteria.fundType.isEmpty),
                    })
                .toList(),
            (value) => _updateFilter('fundType', value == '全部' ? '' : value),
          ),

          const SizedBox(height: 16),

          // 基金公司筛选
          _buildFilterSection(
            '基金公司',
            Icons.business,
            _fundCompanies
                .map((company) => {
                      'label': company,
                      'value': company,
                      'selected': _criteria.fundCompany == company ||
                          (company == '全部' && _criteria.fundCompany.isEmpty),
                    })
                .toList(),
            (value) => _updateFilter('fundCompany', value == '全部' ? '' : value),
          ),

          const SizedBox(height: 16),

          // 收益率范围筛选
          _buildFilterSection(
            '收益率要求',
            Icons.trending_up,
            _returnRanges
                .map((range) => {
                      'label': range,
                      'value': range,
                      'selected': _criteria.returnRange == range ||
                          (range == '不限' && _criteria.returnRange.isEmpty),
                    })
                .toList(),
            (value) => _updateFilter('returnRange', value == '不限' ? '' : value),
          ),

          const SizedBox(height: 16),

          // 净值范围筛选
          _buildFilterSection(
            '净值范围',
            Icons.monetization_on,
            _navRanges
                .map((range) => {
                      'label': range,
                      'value': range,
                      'selected': _criteria.navRange == range ||
                          (range == '不限' && _criteria.navRange.isEmpty),
                    })
                .toList(),
            (value) => _updateFilter('navRange', value == '不限' ? '' : value),
          ),

          const SizedBox(height: 16),

          // 自定义范围输入
          _buildCustomRangeSection(),

          const SizedBox(height: 16),

          // 应用筛选按钮
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _applyFilters,
              icon: const Icon(Icons.search),
              label: const Text('应用筛选'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建筛选区域
  Widget _buildFilterSection(
    String title,
    IconData icon,
    List<Map<String, dynamic>> options,
    Function(String) onTap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: options.map((option) {
            return FilterChip(
              label: Text(
                option['label'],
                style: const TextStyle(fontSize: 12),
              ),
              selected: option['selected'],
              onSelected: (_) => onTap(option['value']),
              backgroundColor: Colors.grey[100],
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              checkmarkColor: Theme.of(context).primaryColor,
              side: BorderSide(
                color: option['selected']
                    ? Theme.of(context).primaryColor
                    : Colors.grey[300]!,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 构建自定义范围输入区域
  Widget _buildCustomRangeSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                '自定义范围',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: '最小净值',
                    hintText: '如: 1.0',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => _updateFilter('minNav', value),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: '最大净值',
                    hintText: '如: 2.0',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => _updateFilter('maxNav', value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: '最小收益率(%)',
                    hintText: '如: 15',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => _updateFilter('minReturn', value),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: '成立年限(年)',
                    hintText: '如: 5',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => _updateFilter('minYears', value),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 更新筛选条件
  void _updateFilter(String key, String value) {
    setState(() {
      switch (key) {
        case 'fundType':
          _criteria = _criteria.copyWith(fundType: value);
          break;
        case 'fundCompany':
          _criteria = _criteria.copyWith(fundCompany: value);
          break;
        case 'returnRange':
          _criteria = _criteria.copyWith(returnRange: value);
          break;
        case 'navRange':
          _criteria = _criteria.copyWith(navRange: value);
          break;
        case 'minNav':
          _criteria = _criteria.copyWith(minNav: double.tryParse(value));
          break;
        case 'maxNav':
          _criteria = _criteria.copyWith(maxNav: double.tryParse(value));
          break;
        case 'minReturn':
          _criteria = _criteria.copyWith(minReturn: double.tryParse(value));
          break;
        case 'minYears':
          _criteria = _criteria.copyWith(minYears: int.tryParse(value));
          break;
      }
    });
  }

  /// 重置筛选条件
  void _resetFilters() {
    setState(() {
      _criteria = FundSearchCriteria.empty();
    });
    widget.onFilterChanged(_criteria);
  }

  /// 应用筛选条件
  void _applyFilters() {
    widget.onFilterChanged(_criteria);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('已应用筛选条件'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: '查看结果',
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}
