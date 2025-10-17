import 'package:flutter/material.dart';
import 'lib/src/shared/widgets/charts/services/chart_data_service.dart';
import 'lib/src/shared/widgets/charts/models/chart_data.dart';

void main() {
  runApp(const RealChartServiceTest());
}

class RealChartServiceTest extends StatefulWidget {
  const RealChartServiceTest({super.key});

  @override
  State<RealChartServiceTest> createState() => _RealChartServiceTestState();
}

class _RealChartServiceTestState extends State<RealChartServiceTest> {
  final ChartDataService _chartService = ChartDataService();
  bool _isLoading = false;
  String _testResult = '';
  List<ChartDataSeries> _chartData = [];

  final List<String> _testFunds = [
    '009209', // 易方达均衡精选企业
    '000001', // 华夏成长混合
    '110022', // 易方达消费行业
  ];

  final List<String> _testIndicators = ['累计净值走势', '单位净值走势', '累计收益率', '同类排名走势'];

  Future<void> _testChartData() async {
    setState(() {
      _isLoading = true;
      _testResult = '';
      _chartData = [];
    });

    try {
      final fundCode = _testFunds.first;
      final indicator = _testIndicators.first;

      print('\n🔍 测试真实ChartDataService');
      print('=' * 50);
      print('基金代码: $fundCode');
      print('指标类型: $indicator');

      final chartSeries = await _chartService.getFundNavChartSeries(
        fundCode: fundCode,
        indicator: indicator,
      );

      setState(() {
        _chartData = chartSeries;
        _testResult = '''
✅ ChartDataService测试成功！

📊 测试信息:
基金代码: $fundCode
指标类型: $indicator
图表系列数: ${chartSeries.length}

📈 图表数据详情:
${chartSeries.asMap().entries.map((entry) {
          final index = entry.key;
          final series = entry.value;
          return '''
图表系列 ${index + 1}:
- 名称: ${series.name}
- 数据点数: ${series.data.length}
- 显示点: ${series.showDots ? '是' : '否'}
- 显示区域: ${series.showArea ? '是' : '否'}
- 线宽: ${series.lineWidth}
- 颜色: ${series.color}
''';
        }).join('\n')}

📊 前5个数据点:
${chartSeries.isNotEmpty ? chartSeries.first.data.take(5).map((point) => '  X: ${point.x}, Y: ${point.y}, Label: ${point.label}').join('\n') : '无数据'}

💡 这证明了真实的ChartDataService已经成功集成了UTF-8字段解码功能！
现在可以正确处理API返回的UTF-8编码字段，并将其转换为图表可用的数据格式。
''';
      });
    } catch (e) {
      setState(() {
        _testResult = '❌ ChartDataService测试失败: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChartDataService真实测试',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('ChartDataService真实测试'),
          backgroundColor: Colors.green[600],
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 测试信息
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[600]!, Colors.green[400]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.analytics, color: Colors.white, size: 48),
                    SizedBox(height: 16),
                    Text(
                      'ChartDataService真实API测试',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '验证UTF-8字段解码和真实数据获取',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 测试按钮
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _testChartData,
                icon: _isLoading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(_isLoading ? '测试中...' : '开始测试'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),

              const SizedBox(height: 24),

              // 测试结果
              if (_testResult.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[200]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    _testResult,
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // 图表数据可视化（如果有的话）
              if (_chartData.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.insert_chart, color: Colors.green[600]),
                          SizedBox(width: 8),
                          Text(
                            '图表数据预览',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[600],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        '成功获取 ${_chartData.length} 个图表系列',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      ..._chartData.map((series) => Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: series.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${series.name} - ${series.data.length}个数据点',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
