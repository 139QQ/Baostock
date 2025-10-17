import 'package:flutter/material.dart';
import 'package:jisu_fund_analyzer/src/shared/widgets/charts/pie_chart_widget.dart';
import 'package:jisu_fund_analyzer/src/shared/widgets/charts/models/chart_data.dart';
import 'package:jisu_fund_analyzer/src/shared/widgets/charts/chart_theme_manager.dart';

void main() {
  runApp(const PieChartDemoApp());
}

class PieChartDemoApp extends StatelessWidget {
  const PieChartDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '饼图组件演示',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const PieChartDemoPage(),
    );
  }
}

class PieChartDemoPage extends StatefulWidget {
  const PieChartDemoPage({super.key});

  @override
  State<PieChartDemoPage> createState() => _PieChartDemoPageState();
}

class _PieChartDemoPageState extends State<PieChartDemoPage> {
  int? _selectedSectorIndex;
  int? _hoveredSectorIndex;

  // 示例数据1：基金资产配置
  final List<PieChartDataItem> _assetAllocationData = [
    PieChartDataItem(
      value: 35.0,
      label: '股票',
      color: Colors.blue,
      description: 'A股、港股等股票资产',
    ),
    PieChartDataItem(
      value: 25.0,
      label: '债券',
      color: Colors.green,
      description: '国债、企业债等债券资产',
    ),
    PieChartDataItem(
      value: 20.0,
      label: '货币基金',
      color: Colors.orange,
      description: '现金类资产',
    ),
    PieChartDataItem(
      value: 15.0,
      label: '另类投资',
      color: Colors.purple,
      description: 'REITs、商品等',
    ),
    PieChartDataItem(
      value: 5.0,
      label: '其他',
      color: Colors.grey,
      description: '其他资产',
    ),
  ];

  // 示例数据2：行业分布
  final List<PieChartDataItem> _industryDistributionData = [
    PieChartDataItem(
      value: 28.5,
      label: '制造业',
      color: const Color(0xFF1976D2),
    ),
    PieChartDataItem(
      value: 22.3,
      label: '金融业',
      color: const Color(0xFF4CAF50),
    ),
    PieChartDataItem(
      value: 18.7,
      label: '科技业',
      color: const Color(0xFFFF9800),
    ),
    PieChartDataItem(
      value: 15.2,
      label: '消费业',
      color: const Color(0xFF9C27B0),
    ),
    PieChartDataItem(
      value: 8.9,
      label: '医药业',
      color: const Color(0xFFF44336),
    ),
    PieChartDataItem(
      value: 6.4,
      label: '其他',
      color: const Color(0xFF9E9E9E),
    ),
  ];

  // 示例数据3：地理分布
  final List<PieChartDataItem> _geographicalData = [
    PieChartDataItem(
      value: 45.0,
      label: '国内市场',
      color: Colors.red,
      description: 'A股、港股等国内市场投资',
    ),
    PieChartDataItem(
      value: 35.0,
      label: '亚太地区',
      color: Colors.green,
      description: '日本、韩国、新加坡等亚太市场',
    ),
    PieChartDataItem(
      value: 20.0,
      label: '欧美市场',
      color: Colors.blue,
      description: '美国、欧洲等发达市场',
    ),
  ];

  // 示例数据4：基金规模分布
  final List<PieChartDataItem> _fundSizeData = [
    PieChartDataItem(
      value: 28.5,
      label: '大型基金(>100亿)',
      color: Colors.deepPurple,
    ),
    PieChartDataItem(
      value: 42.3,
      label: '中型基金(10-100亿)',
      color: Colors.indigo,
    ),
    PieChartDataItem(
      value: 22.7,
      label: '小型基金(<10亿)',
      color: Colors.blue,
    ),
    PieChartDataItem(
      value: 6.5,
      label: '其他',
      color: Colors.grey,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('饼图组件演示'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '饼图组件功能演示',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '支持交互式扇区选择、百分比标签、图例显示等功能',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // 第一个饼图：资产配置（右侧图例）
            _buildChartSection(
              title: '基金资产配置分布',
              subtitle: '点击扇区或图例进行选择',
              child: _buildAssetAllocationChart(),
            ),

            const SizedBox(height: 32),

            // 第二个饼图：行业分布（底部图例）
            _buildChartSection(
              title: '基金行业分布',
              subtitle: '悬停扇区查看高亮效果',
              child: _buildIndustryDistributionChart(),
            ),

            const SizedBox(height: 32),

            // 第三个饼图：地理分布（环形图）
            _buildChartSection(
              title: '基金地理分布（环形图）',
              subtitle: '内半径设置为0.3的环形图效果',
              child: _buildGeographicalChart(),
            ),

            const SizedBox(height: 32),

            // 第四个饼图：基金规模分布（顶部图例）
            _buildChartSection(
              title: '基金规模分布',
              subtitle: '顶部图例布局演示',
              child: _buildFundSizeChart(),
            ),

            const SizedBox(height: 32),

            // 当前选择信息
            if (_selectedSectorIndex != null) ...[
              _buildSelectedInfo(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: child,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetAllocationChart() {
    return PieChartWidget(
      data: _assetAllocationData,
      config: const ChartConfig(
        title: '资产配置',
        showTooltip: true,
        animationDuration: Duration(milliseconds: 800),
      ),
      onSectorSelected: (index, item) {
        setState(() {
          _selectedSectorIndex = index;
        });
        _showSelectionDialog('资产配置', item);
      },
      onSectorHovered: (index, item) {
        setState(() {
          _hoveredSectorIndex = index;
        });
      },
      legendPosition: LegendPosition.right,
      selectedSectorIndex: _selectedSectorIndex,
    );
  }

  Widget _buildIndustryDistributionChart() {
    return PieChartWidget(
      data: _industryDistributionData,
      config: const ChartConfig(
        title: '行业分布',
        showTooltip: true,
        animationDuration: Duration(milliseconds: 800),
      ),
      onSectorSelected: (index, item) {
        setState(() {
          _selectedSectorIndex = index;
        });
        _showSelectionDialog('行业分布', item);
      },
      onSectorHovered: (index, item) {
        setState(() {
          _hoveredSectorIndex = index;
        });
      },
      legendPosition: LegendPosition.right, // 改为右侧避免遮挡
      selectedSectorIndex: _selectedSectorIndex,
    );
  }

  Widget _buildGeographicalChart() {
    return PieChartWidget(
      data: _geographicalData,
      config: const ChartConfig(
        title: '地理分布',
        showTooltip: true,
        animationDuration: Duration(milliseconds: 800),
      ),
      onSectorSelected: (index, item) {
        setState(() {
          _selectedSectorIndex = index;
        });
        _showSelectionDialog('地理分布', item);
      },
      onSectorHovered: (index, item) {
        setState(() {
          _hoveredSectorIndex = index;
        });
      },
      innerRadius: 0.3, // 环形图，内半径为30%
      legendPosition: LegendPosition.right,
      selectedSectorIndex: _selectedSectorIndex,
      showPercentageLabels: true,
      sectorSpacing: 3.0, // 增加扇区间距让环形图更清晰
    );
  }

  Widget _buildFundSizeChart() {
    return PieChartWidget(
      data: _fundSizeData,
      config: const ChartConfig(
        title: '基金规模分布',
        showTooltip: true,
        animationDuration: Duration(milliseconds: 1000),
      ),
      onSectorSelected: (index, item) {
        setState(() {
          _selectedSectorIndex = index;
        });
        _showSelectionDialog('基金规模分布', item);
      },
      onSectorHovered: (index, item) {
        setState(() {
          _hoveredSectorIndex = index;
        });
      },
      legendPosition: LegendPosition.top, // 顶部图例
      selectedSectorIndex: _selectedSectorIndex,
      showPercentageLabels: true,
      sectorSpacing: 2.0,
      enableInteraction: true,
    );
  }

  Widget _buildSelectedInfo() {
    if (_selectedSectorIndex == null) return const SizedBox.shrink();

    // 确定是哪个数据集被选中
    List<PieChartDataItem> currentData = _assetAllocationData;
    String dataTitle = '资产配置';

    // 这里简化处理，实际应用中需要根据当前显示的图表来确定
    final selectedItem =
        currentData[_selectedSectorIndex! % currentData.length];

    return Card(
      elevation: 4,
      color: Colors.blue.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  '当前选择：$dataTitle',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('项目：${selectedItem.label}'),
            Text('数值：${selectedItem.value}'),
            Text(
                '百分比：${selectedItem.calculatePercentage(_calculateTotal(currentData)).toStringAsFixed(1)}%'),
            if (selectedItem.description != null)
              Text('描述：${selectedItem.description}'),
          ],
        ),
      ),
    );
  }

  double _calculateTotal(List<PieChartDataItem> data) {
    return data.fold(0.0, (sum, item) => sum + item.value);
  }

  void _showSelectionDialog(String chartType, PieChartDataItem item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$chartType - 选择详情'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('项目：${item.label}'),
              Text('数值：${item.value}'),
              if (item.description != null) Text('描述：${item.description}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }
}
