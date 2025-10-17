/// 柱状图组件演示程序
///
/// 演示柱状图组件的基本功能，包括单系列和多系列数据展示
library simple_bar_chart_demo;

import 'package:flutter/material.dart';
import 'package:jisu_fund_analyzer/src/shared/widgets/charts/charts.dart';

void main() {
  runApp(const BarChartDemoApp());
}

class BarChartDemoApp extends StatelessWidget {
  const BarChartDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '柱状图演示',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const BarChartDemoPage(),
    );
  }
}

class BarChartDemoPage extends StatefulWidget {
  const BarChartDemoPage({super.key});

  @override
  State<BarChartDemoPage> createState() => _BarChartDemoPageState();
}

class _BarChartDemoPageState extends State<BarChartDemoPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('柱状图组件演示'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '基础柱状图'),
            Tab(text: '多系列对比'),
            Tab(text: '渐变样式'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _BasicBarChartTab(),
          _MultiSeriesBarChartTab(),
          _GradientBarChartTab(),
        ],
      ),
    );
  }
}

/// 基础柱状图演示
class _BasicBarChartTab extends StatelessWidget {
  const _BasicBarChartTab();

  @override
  Widget build(BuildContext context) {
    final dataSeries = [
      ChartDataSeries(
        name: '基金收益率',
        data: [
          const ChartPoint(x: 1, y: 12.5, label: '1月'),
          const ChartPoint(x: 2, y: 8.3, label: '2月'),
          const ChartPoint(x: 3, y: 15.7, label: '3月'),
          const ChartPoint(x: 4, y: 6.2, label: '4月'),
          const ChartPoint(x: 5, y: 18.9, label: '5月'),
          const ChartPoint(x: 6, y: 9.4, label: '6月'),
        ],
        color: Colors.blue,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            '2024年上半年基金收益率',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: BarChartWidget(
              config: const ChartConfig(
                title: '月度收益率 (%)',
                showGrid: true,
                showTooltip: true,
              ),
              dataSeries: dataSeries,
              showGradient: false,
              barWidth: 24.0,
              borderRadius: 6.0,
              onBarTap: (dataPoint, seriesIndex, barIndex) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${dataPoint.label}: ${dataPoint.y.toStringAsFixed(1)}%',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 多系列柱状图演示
class _MultiSeriesBarChartTab extends StatelessWidget {
  const _MultiSeriesBarChartTab();

  @override
  Widget build(BuildContext context) {
    final dataSeries = [
      ChartDataSeries(
        name: '股票型基金',
        data: [
          const ChartPoint(x: 1, y: 18.5, label: 'Q1'),
          const ChartPoint(x: 2, y: 12.3, label: 'Q2'),
          const ChartPoint(x: 3, y: 22.7, label: 'Q3'),
          const ChartPoint(x: 4, y: 8.9, label: 'Q4'),
        ],
        color: Colors.blue,
      ),
      ChartDataSeries(
        name: '债券型基金',
        data: [
          const ChartPoint(x: 1, y: 6.2, label: 'Q1'),
          const ChartPoint(x: 2, y: 5.8, label: 'Q2'),
          const ChartPoint(x: 3, y: 7.1, label: 'Q3'),
          const ChartPoint(x: 4, y: 6.5, label: 'Q4'),
        ],
        color: Colors.green,
      ),
      ChartDataSeries(
        name: '混合型基金',
        data: [
          const ChartPoint(x: 1, y: 14.3, label: 'Q1'),
          const ChartPoint(x: 2, y: 9.7, label: 'Q2'),
          const ChartPoint(x: 3, y: 16.8, label: 'Q3'),
          const ChartPoint(x: 4, y: 11.2, label: 'Q4'),
        ],
        color: Colors.orange,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            '2024年不同类型基金季度收益率对比',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            '点击柱子查看详细信息',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: BarChartWidget(
              config: const ChartConfig(
                title: '季度收益率 (%)',
                showGrid: true,
                showTooltip: true,
              ),
              dataSeries: dataSeries,
              showGradient: false,
              barWidth: 16.0,
              groupSpacing: 12.0,
              onBarTap: (dataPoint, seriesIndex, barIndex) {
                final seriesName = dataSeries[seriesIndex].name;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '$seriesName - ${dataPoint.label}: ${dataPoint.y.toStringAsFixed(1)}%',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 渐变样式柱状图演示
class _GradientBarChartTab extends StatelessWidget {
  const _GradientBarChartTab();

  @override
  Widget build(BuildContext context) {
    final dataSeries = [
      ChartDataSeries(
        name: '年度收益',
        data: [
          const ChartPoint(x: 1, y: 25.8, label: '2019'),
          const ChartPoint(x: 2, y: 18.3, label: '2020'),
          const ChartPoint(x: 3, y: 32.7, label: '2021'),
          const ChartPoint(x: 4, y: -8.5, label: '2022'),
          const ChartPoint(x: 5, y: 15.9, label: '2023'),
          const ChartPoint(x: 6, y: 22.4, label: '2024'),
        ],
        gradient: const LinearGradient(
          colors: [Colors.purple, Colors.blue],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            '基金年度收益率趋势（渐变样式）',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            '支持正负值显示和渐变色彩',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: BarChartWidget(
              config: const ChartConfig(
                title: '年度收益率 (%)',
                showGrid: true,
                showTooltip: true,
              ),
              dataSeries: dataSeries,
              showGradient: true,
              barWidth: 28.0,
              borderRadius: 8.0,
              animationDuration: const Duration(milliseconds: 1200),
              onBarTap: (dataPoint, seriesIndex, barIndex) {
                final value = dataPoint.y;
                final color = value >= 0 ? Colors.green : Colors.red;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(
                          value >= 0 ? Icons.trending_up : Icons.trending_down,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${dataPoint.label}年: ${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)}%',
                        ),
                      ],
                    ),
                    backgroundColor: color,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
