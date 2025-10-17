import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/models/fund_holding.dart';

/// 基金持仓分析组件
///
/// 展示基金的持仓结构，包括�?
/// - 前十大重仓股
/// - 行业分布饼图
/// - 股票/债券/现金比例
/// - 持仓变化趋势
class FundHoldingAnalysis extends StatefulWidget {
  final List<FundHolding> holdings;
  final String? reportDate;

  const FundHoldingAnalysis({
    super.key,
    required this.holdings,
    this.reportDate,
  });

  @override
  State<FundHoldingAnalysis> createState() => _FundHoldingAnalysisState();
}

class _FundHoldingAnalysisState extends State<FundHoldingAnalysis> {
  String _selectedView = '十大重仓';
  int _touchedIndex = -1;

  // 视图选项
  final List<String> _viewOptions = ['十大重仓', '行业分布', '资产结构'];

  @override
  Widget build(BuildContext context) {
    if (widget.holdings.isEmpty) {
      return _buildEmptyWidget();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题和视图切�?
            Row(
              children: [
                const Text(
                  '持仓分析',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),

                // 视图选择�?
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedView,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.arrow_drop_down, size: 16),
                    items: _viewOptions.map((view) {
                      return DropdownMenuItem<String>(
                        value: view,
                        child: Text(view, style: const TextStyle(fontSize: 12)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedView = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 报告日期
            if (widget.reportDate != null)
              Text(
                '报告日期�?{widget.reportDate}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),

            const SizedBox(height: 16),

            // 内容区域
            _buildContent(),

            const SizedBox(height: 16),

            // 说明文字
            Text(
              _getDescription(),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建内容
  Widget _buildContent() {
    switch (_selectedView) {
      case '十大重仓':
        return _buildTopHoldings();
      case '行业分布':
        return _buildIndustryDistribution();
      case '资产结构':
        return _buildAssetStructure();
      default:
        return _buildTopHoldings();
    }
  }

  /// 构建前十大重仓股
  Widget _buildTopHoldings() {
    final topHoldings = widget.holdings
        .where((holding) => holding.holdingType == 'stock')
        .toList()
      ..sort((a, b) =>
          (b.holdingPercentage ?? 0).compareTo(a.holdingPercentage ?? 0));

    // 只显示前10大重仓股，处理空�?
    final displayHoldings = topHoldings
        .where((holding) => holding.holdingPercentage != null)
        .take(10)
        .toList();

    return Column(
      children: [
        // 表头
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  '股票名称',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  '持仓比例',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                child: Text(
                  '持仓市�?,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                child: Text(
                  '所属行�?,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // 持仓列表
        ...displayHoldings.map((holding) => _buildHoldingRow(holding)),

        const SizedBox(height: 12),

        // 统计信息
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                '股票持仓',
                '${displayHoldings.fold(0.0, (sum, h) => sum + (h.holdingPercentage ?? 0)).toStringAsFixed(1)}%',
                Colors.blue,
              ),
              _buildStatItem(
                '持仓股票',
                '${displayHoldings.length}�?,
                Colors.green,
              ),
              _buildStatItem(
                '总市�?,
                '${(displayHoldings.fold(0.0, (sum, h) => sum + (h.holdingValue ?? 0)) / 100000000).toStringAsFixed(1)}�?,
                Colors.orange,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建持仓�?
  Widget _buildHoldingRow(FundHolding holding) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  holding.stockName ?? '未知股票',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  holding.stockCode ?? '未知代码',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              '${(holding.holdingPercentage ?? 0).toStringAsFixed(2)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _getPercentageColor(holding.holdingPercentage ?? 0),
              ),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            child: Text(
              '${((holding.holdingValue ?? 0) / 100000000).toStringAsFixed(1)}�?,
              style: const TextStyle(
                fontSize: 14,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            child: Text(
              holding.sector ?? '未知行业',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建行业分布饼图
  Widget _buildIndustryDistribution() {
    final industryData = _calculateIndustryDistribution();

    return Column(
      children: [
        // 饼图
        SizedBox(
          height: 250,
          child: PieChart(
            PieChartData(
              sections: _createPieSections(industryData),
              centerSpaceRadius: 40,
              sectionsSpace: 2,
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      _touchedIndex = -1;
                      return;
                    }
                    _touchedIndex =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 行业列表
        _buildIndustryList(industryData),
      ],
    );
  }

  /// 构建行业列表
  Widget _buildIndustryList(Map<String, double> industryData) {
    final industries = industryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: industries.map((entry) {
        final index = industries.indexOf(entry);
        final isTouched = index == _touchedIndex;
        final color = _getIndustryColor(index);

        return Container(
          margin: EdgeInsets only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isTouched ? color.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isTouched ? color : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.key,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '${entry.value.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// 构建资产结构
  Widget _buildAssetStructure() {
    final assetData = _calculateAssetStructure();

    return Column(
      children: [
        // 资产饼图
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: _createAssetPieSections(assetData),
              centerSpaceRadius: 50,
              sectionsSpace: 2,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 资产详情
        _buildAssetDetails(assetData),
      ],
    );
  }

  /// 构建资产详情
  Widget _buildAssetDetails(Map<String, double> assetData) {
    final assets = assetData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: assets.map((entry) {
        final color = _getAssetColor(entry.key);

        return Container(
          margin: EdgeInsets only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${entry.value.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                _getAssetIcon(entry.key),
                color: color,
                size: 24,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// 构建统计�?
  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  /// 构建空状�?
  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pie_chart_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无持仓数据',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '等待基金公司披露最新持仓信�?,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  /// 计算行业分布
  Map<String, double> _calculateIndustryDistribution() {
    final industryMap = <String, double>{};

    for (final holding in widget.holdings) {
      if (holding.sector?.isNotEmpty == true) {
        industryMap[holding.sector!] = (industryMap[holding.sector!] ?? 0) +
            (holding.holdingPercentage ?? 0);
      }
    }

    return industryMap;
  }

  /// 计算资产结构
  Map<String, double> _calculateAssetStructure() {
    final assetMap = <String, double>{};

    for (final holding in widget.holdings) {
      final assetType = _getAssetType(holding.holdingType);
      assetMap[assetType] =
          (assetMap[assetType] ?? 0) + (holding.holdingPercentage ?? 0);
    }

    return assetMap;
  }

  /// 创建饼图扇区
  List<PieChartSectionData> _createPieSections(
      Map<String, double> industryData) {
    final sections = <PieChartSectionData>[];
    final industries = industryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (int i = 0; i < industries.length; i++) {
      final entry = industries[i];
      final color = _getIndustryColor(i);
      final isTouched = i == _touchedIndex;
      final fontSize = isTouched ? 14.0 : 12.0;
      final radius = isTouched ? 60.0 : 50.0;

      sections.add(PieChartSectionData(
        color: color,
        value: entry.value,
        title: '${entry.value.toStringAsFixed(1)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ));
    }

    return sections;
  }

  /// 创建资产饼图扇区
  List<PieChartSectionData> _createAssetPieSections(
      Map<String, double> assetData) {
    final sections = <PieChartSectionData>[];
    final assets = assetData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (int i = 0; i < assets.length; i++) {
      final entry = assets[i];
      final color = _getAssetColor(entry.key);

      sections.add(PieChartSectionData(
        color: color,
        value: entry.value,
        title: '${entry.value.toStringAsFixed(1)}%',
        radius: 40,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ));
    }

    return sections;
  }

  /// 获取说明文字
  String _getDescription() {
    switch (_selectedView) {
      case '十大重仓':
        return '展示基金前十大重仓股信息，包括持仓比例、市值和行业分类';
      case '行业分布':
        return '按行业分类统计基金持仓分布，帮助了解基金的行业配置偏�?;
      case '资产结构':
        return '展示基金在不同资产类别上的配置比例，包括股票、债券、现金等';
      default:
        return '基金持仓分析';
    }
  }

  /// 获取持仓比例颜色
  Color _getPercentageColor(double percentage) {
    if (percentage >= 8) return Colors.red;
    if (percentage >= 5) return Colors.orange;
    if (percentage >= 3) return Colors.blue;
    return Colors.green;
  }

  /// 获取行业颜色
  Color _getIndustryColor(int index) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.amber,
      Colors.pink,
      Colors.cyan,
    ];
    return colors[index % colors.length];
  }

  /// 获取资产类型
  String _getAssetType(String holdingType) {
    switch (holdingType.toLowerCase()) {
      case 'stock':
        return '股票';
      case 'bond':
        return '债券';
      case 'cash':
        return '现金';
      default:
        return '其他';
    }
  }

  /// 获取资产颜色
  Color _getAssetColor(String assetType) {
    switch (assetType) {
      case '股票':
        return Colors.red;
      case '债券':
        return Colors.green;
      case '现金':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  /// 获取资产图标
  IconData _getAssetIcon(String assetType) {
    switch (assetType) {
      case '股票':
        return Icons.trending_up;
      case '债券':
        return Icons.account_balance;
      case '现金':
        return Icons.attach_money;
      default:
        return Icons.help_outline;
    }
  }
}
