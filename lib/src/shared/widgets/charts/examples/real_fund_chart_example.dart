/// 真实基金图表示例页面
///
/// 展示如何使用ChartDataService获取真实基金数据并显示在图表中
library real_fund_chart_example;

import 'package:flutter/material.dart';

import '../line_chart_widget.dart';
import '../models/chart_data.dart';
import '../services/chart_data_service.dart';
import '../chart_theme_manager.dart';

/// 真实基金图表示例页面
class RealFundChartExample extends StatefulWidget {
  const RealFundChartExample({super.key});

  @override
  State<RealFundChartExample> createState() => _RealFundChartExampleState();
}

class _RealFundChartExampleState extends State<RealFundChartExample> {
  final ChartDataService _chartDataService = ChartDataService();
  List<ChartDataSeries> _chartData = [];
  bool _isLoading = false;
  String _selectedFundCode = '000001'; // 华夏成长混合
  String _selectedIndicator = '单位净值走势';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadFundData();
  }

  @override
  void dispose() {
    _chartDataService.dispose();
    super.dispose();
  }

  Future<void> _loadFundData() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final chartSeries = await _chartDataService.getFundNavChartSeries(
        fundCode: _selectedFundCode,
        indicator: _selectedIndicator,
      );

      setState(() {
        _chartData = chartSeries;
        _isLoading = false;
      });

      if (chartSeries.isEmpty) {
        setState(() {
          _errorMessage = '未获取到数据，请检查基金代码或网络连接';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '加载数据失败: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('真实基金数据图表示例'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildControlPanel(),
          Expanded(
            child: _buildChartArea(),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '图表控制面板',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '基金代码:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildFundCodeSelector(),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '指标类型:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildIndicatorSelector(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _loadFundData,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: Text(_isLoading ? '加载中...' : '刷新数据'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _showComparisonChart,
                icon: const Icon(Icons.compare_arrows),
                label: const Text('对比图表'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _showRankingChart,
                icon: const Icon(Icons.leaderboard),
                label: const Text('排行榜'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[600],
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFundCodeSelector() {
    final fundCodes = [
      '000001', // 华夏成长混合
      '110022', // 易方达消费行业
      '161725', // 招商中证白酒
      '510300', // 沪深300ETF
      '510500', // 中证500ETF
      '000002', // 华夏成长混合
    ];

    return DropdownButtonFormField<String>(
      value: _selectedFundCode,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: fundCodes.map((code) {
        return DropdownMenuItem<String>(
          value: code,
          child: Row(
            children: [
              const Icon(Icons.account_balance, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              Text(code),
              const SizedBox(width: 8),
              Text(
                _getFundName(code),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedFundCode = value;
          });
          _loadFundData();
        }
      },
    );
  }

  Widget _buildIndicatorSelector() {
    final indicators = [
      '单位净值走势',
      '累计净值走势',
    ];

    return DropdownButtonFormField<String>(
      value: _selectedIndicator,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: indicators.map((indicator) {
        return DropdownMenuItem<String>(
          value: indicator,
          child: Row(
            children: [
              const Icon(Icons.show_chart, size: 16, color: Colors.green),
              const SizedBox(width: 8),
              Text(indicator),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedIndicator = value;
          });
          _loadFundData();
        }
      },
    );
  }

  Widget _buildChartArea() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              '正在加载基金数据...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: TextStyle(
                fontSize: 16,
                color: Colors.red[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadFundData,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_chartData.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              '暂无图表数据',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$_selectedFundCode - $_selectedIndicator',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '数据来源: 154.44.25.92:8080 API',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChartWidget(
              config: const ChartConfig(
                title: '基金净值走势图',
                showTooltip: true,
                showGrid: true,
              ),
              enableAnimation: true,
              dataSeries: _chartData,
              showGradient: true,
              isCurved: true,
              showDots: _chartData.first.data.length <= 60,
              customTheme: ChartTheme.light(),
            ),
          ),
          const SizedBox(height: 16),
          _buildChartInfo(),
        ],
      ),
    );
  }

  Widget _buildChartInfo() {
    if (_chartData.isEmpty) return const SizedBox.shrink();

    final series = _chartData.first;
    final dataPoints = series.data;
    if (dataPoints.isEmpty) return const SizedBox.shrink();

    final firstValue = dataPoints.first.y;
    final lastValue = dataPoints.last.y;
    final change = lastValue - firstValue;
    final changePercent = firstValue > 0 ? (change / firstValue * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem('起始净值', firstValue.toStringAsFixed(4)),
          _buildInfoItem('最新净值', lastValue.toStringAsFixed(4)),
          _buildInfoItem('涨跌幅', '${changePercent.toStringAsFixed(2)}%'),
          _buildInfoItem('数据点数', '${dataPoints.length}'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  String _getFundName(String fundCode) {
    final fundNames = {
      '000001': '华夏成长混合',
      '110022': '易方达消费行业',
      '161725': '招商中证白酒',
      '510300': '沪深300ETF',
      '510500': '中证500ETF',
      '000002': '华夏成长混合',
    };
    return fundNames[fundCode] ?? '未知基金';
  }

  void _showComparisonChart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FundComparisonExample(
          fundCodes: ['000001', '110022', '161725'],
        ),
      ),
    );
  }

  void _showRankingChart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FundRankingExample(),
      ),
    );
  }
}

/// 基金对比示例页面
class FundComparisonExample extends StatefulWidget {
  final List<String> fundCodes;

  const FundComparisonExample({super.key, required this.fundCodes});

  @override
  State<FundComparisonExample> createState() => _FundComparisonExampleState();
}

class _FundComparisonExampleState extends State<FundComparisonExample> {
  final ChartDataService _chartDataService = ChartDataService();
  List<ChartDataSeries> _chartData = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadComparisonData();
  }

  @override
  void dispose() {
    _chartDataService.dispose();
    super.dispose();
  }

  Future<void> _loadComparisonData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final chartSeries = await _chartDataService.getFundsComparisonChartSeries(
        fundCodes: widget.fundCodes,
      );

      setState(() {
        _chartData = chartSeries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载对比数据失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('基金净值对比'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chartData.isEmpty
              ? const Center(child: Text('无对比数据'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: LineChartWidget(
                    config: const ChartConfig(
                      title: '多基金净值对比',
                      showTooltip: true,
                      showGrid: true,
                    ),
                    enableAnimation: true,
                    dataSeries: _chartData,
                    showGradient: true,
                    isCurved: true,
                    showDots: false,
                  ),
                ),
    );
  }
}

/// 基金排行榜示例页面
class FundRankingExample extends StatefulWidget {
  const FundRankingExample({super.key});

  @override
  State<FundRankingExample> createState() => _FundRankingExampleState();
}

class _FundRankingExampleState extends State<FundRankingExample> {
  final ChartDataService _chartDataService = ChartDataService();
  List<ChartDataSeries> _chartData = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRankingData();
  }

  @override
  void dispose() {
    _chartDataService.dispose();
    super.dispose();
  }

  Future<void> _loadRankingData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final chartSeries = await _chartDataService.getFundRankingChartSeries(
        symbol: '股票型',
        topN: 10,
        indicator: '近1年',
      );

      setState(() {
        _chartData = chartSeries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载排行榜数据失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('基金排行榜'),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chartData.isEmpty
              ? const Center(child: Text('无排行榜数据'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: LineChartWidget(
                    config: const ChartConfig(
                      title: '股票型基金收益排行',
                      showTooltip: true,
                      showGrid: true,
                    ),
                    enableAnimation: true,
                    dataSeries: _chartData,
                    showGradient: false,
                    isCurved: false,
                    showDots: true,
                  ),
                ),
    );
  }
}
