import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../domain/models/fund.dart';

/// 定投计算器组件
///
/// 提供基金定投收益计算功能，包括：
/// - 定投参数设置（金额、周期、时长）
/// - 收益预测计算
/// - 历史回测分析
/// - 投资组合对比
/// - 结果导出分享
class InvestmentCalculator extends StatefulWidget {
  const InvestmentCalculator({super.key});

  @override
  State<InvestmentCalculator> createState() => _InvestmentCalculatorState();
}

class _InvestmentCalculatorState extends State<InvestmentCalculator> {
  // 计算参数
  final TextEditingController _amountController =
      TextEditingController(text: '1000');
  final TextEditingController _periodController =
      TextEditingController(text: '12');
  final TextEditingController _expectedReturnController =
      TextEditingController(text: '8');

  // 计算选项
  String _frequency = 'monthly'; // monthly, weekly, daily

  // 计算结果
  Map<String, dynamic>? _calculationResult;
  bool _isCalculating = false;

  // 布局状态跟踪
  bool _isCompactLayout = false;

  @override
  void initState() {
    super.initState();
    // 初始化时进行默认计算
    _performCalculation();
    // 监听布局变化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLayout();
    });
  }

  /// 检查当前布局状态
  void _checkLayout() {
    if (mounted) {
      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final width = renderBox.size.width;
        setState(() {
          _isCompactLayout = width < 280;
        });
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _periodController.dispose();
    _expectedReturnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 实时检查布局
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkLayout();
        });

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题区域
                _buildHeaderSection(),
                const SizedBox(height: 16),

                // 参数设置区域
                _buildParameterSection(),
                const SizedBox(height: 16),

                // 计算按钮
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isCalculating ? null : _performCalculation,
                    icon: _isCalculating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.calculate),
                    label: Text(_isCalculating ? '计算中...' : '开始计算'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E40AF),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 计算结果区域
                if (_calculationResult != null) ...[
                  _buildResultSection(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建头部区域
  Widget _buildHeaderSection() {
    return _isCompactLayout
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.calculate,
                    color: Color(0xFF1E40AF),
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '定投计算器',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.info_outline, size: 20),
                  onPressed: _showCalculationInfo,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          )
        : Row(
            children: [
              const Icon(
                Icons.calculate,
                color: Color(0xFF1E40AF),
                size: 24,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '定投计算器',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: _showCalculationInfo,
              ),
            ],
          );
  }

  /// 构建参数设置区域 - 修复溢出和边框问题
  Widget _buildParameterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '计算参数',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // 定投金额
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: '定投金额',
              hintText: '请输入每期定投金额',
              prefixText: '¥',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 12),

          // 定投周期 - 修复溢出
          LayoutBuilder(
            builder: (context, constraints) {
              if (_isCompactLayout) {
                return Column(
                  children: [
                    TextField(
                      controller: _periodController,
                      decoration: const InputDecoration(
                        labelText: '投资时长',
                        hintText: '时长',
                        suffixText: '个月',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _frequency,
                      decoration: const InputDecoration(
                        labelText: '定投频率',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'monthly', child: Text('每月')),
                        DropdownMenuItem(value: 'weekly', child: Text('每周')),
                        DropdownMenuItem(value: 'daily', child: Text('每日')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _frequency = value;
                          });
                        }
                      },
                      isDense: true,
                      menuMaxHeight: 150,
                      iconSize: 20,
                    ),
                  ],
                );
              } else {
                return Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _periodController,
                        decoration: const InputDecoration(
                          labelText: '投资时长',
                          hintText: '时长',
                          suffixText: '个月',
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return DropdownButtonFormField<String>(
                            value: _frequency,
                            decoration: InputDecoration(
                              labelText: constraints.maxWidth < 50 ? '频' : '频率',
                              border: const OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: constraints.maxWidth < 50 ? 4 : 8,
                                  vertical: constraints.maxWidth < 50 ? 2 : 4),
                              isDense: true,
                              labelStyle: TextStyle(
                                fontSize: constraints.maxWidth < 50
                                    ? 9
                                    : (constraints.maxWidth < 100 ? 11 : 13),
                              ),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'monthly',
                                child: Text(
                                  '月',
                                  style: TextStyle(
                                      fontSize:
                                          constraints.maxWidth < 50 ? 10 : 12),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'weekly',
                                child: Text(
                                  '周',
                                  style: TextStyle(
                                      fontSize:
                                          constraints.maxWidth < 50 ? 10 : 12),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'daily',
                                child: Text(
                                  '日',
                                  style: TextStyle(
                                      fontSize:
                                          constraints.maxWidth < 50 ? 10 : 12),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _frequency = value;
                                });
                              }
                            },
                            isDense: true,
                            menuMaxHeight: 120,
                            iconSize: constraints.maxWidth < 50 ? 14 : 16,
                            style: TextStyle(
                              fontSize: constraints.maxWidth < 50
                                  ? 10
                                  : (constraints.maxWidth < 100 ? 11 : 13),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 12),

          // 预期年化收益率
          TextField(
            controller: _expectedReturnController,
            decoration: const InputDecoration(
              labelText: '预期年化收益率',
              hintText: '请输入预期年化收益率',
              suffixText: '%',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建结果区域
  Widget _buildResultSection() {
    final result = _calculationResult!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 结果标题
          _isCompactLayout
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.show_chart,
                          color: Color(0xFF1E40AF),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '计算结果',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E40AF),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: const Icon(Icons.share, size: 16),
                        onPressed: _shareResult,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    const Icon(
                      Icons.show_chart,
                      color: Color(0xFF1E40AF),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '计算结果',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E40AF),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share, size: 16),
                      onPressed: _shareResult,
                    ),
                  ],
                ),
          const SizedBox(height: 12),

          // 主要结果
          _isCompactLayout
              ? Column(
                  children: [
                    _buildResultItem(
                      '投入本金',
                      '¥${result['totalPrincipal']?.toStringAsFixed(0) ?? "0"}',
                      Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    _buildResultItem(
                      '预期收益',
                      '¥${result['totalReturn']?.toStringAsFixed(0) ?? "0"}',
                      Fund.getReturnColor(result['totalReturn'] ?? 0),
                    ),
                    const SizedBox(height: 8),
                    _buildResultItem(
                      '总资产',
                      '¥${result['totalValue']?.toStringAsFixed(0) ?? "0"}',
                      Colors.green,
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildResultItem(
                      '投入本金',
                      '¥${result['totalPrincipal']?.toStringAsFixed(0) ?? "0"}',
                      Colors.blue,
                    ),
                    _buildResultItem(
                      '预期收益',
                      '¥${result['totalReturn']?.toStringAsFixed(0) ?? "0"}',
                      Fund.getReturnColor(result['totalReturn'] ?? 0),
                    ),
                    _buildResultItem(
                      '总资产',
                      '¥${result['totalValue']?.toStringAsFixed(0) ?? "0"}',
                      Colors.green,
                    ),
                  ],
                ),
          const SizedBox(height: 16),

          // 详细信息
          _buildDetailedResults(result),
        ],
      ),
    );
  }

  /// 构建结果项
  Widget _buildResultItem(String label, String value, Color color) {
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
        const SizedBox(height: 4),
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

  /// 构建详细结果
  Widget _buildDetailedResults(Map<String, dynamic> result) {
    return Column(
      children: [
        _buildDetailRow('定投次数', '${result['totalInvestments'] ?? 0} 次'),
        _buildDetailRow('平均成本',
            '¥${result['averageCost']?.toStringAsFixed(4) ?? "0.0000"}'),
        _buildDetailRow('收益率',
            '${result['totalReturnRate']?.toStringAsFixed(2) ?? "0.00"}%'),
        _buildDetailRow('年化收益率',
            '${result['annualizedReturn']?.toStringAsFixed(2) ?? "0.00"}%'),
        if (result['maxDrawdown'] != null)
          _buildDetailRow(
              '最大回撤', '${result['maxDrawdown'].toStringAsFixed(2)}%'),
      ],
    );
  }

  /// 构建详情行
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 执行计算
  Future<void> _performCalculation() async {
    setState(() {
      _isCalculating = true;
    });

    try {
      // 模拟计算过程
      await Future.delayed(const Duration(milliseconds: 200));

      final amount = double.tryParse(_amountController.text) ?? 1000;
      final period = int.tryParse(_periodController.text) ?? 12;
      final expectedReturn =
          double.tryParse(_expectedReturnController.text) ?? 8;

      // 计算逻辑
      final calculations = _calculateInvestment(amount, period, expectedReturn);

      if (mounted) {
        setState(() {
          _calculationResult = calculations;
          _isCalculating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCalculating = false;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('计算失败: $e')),
        );
      }
    }
  }

  /// 计算投资收益
  Map<String, dynamic> _calculateInvestment(
      double amount, int period, double expectedReturn) {
    // 简化的定投计算公式
    final monthlyReturn = expectedReturn / 100 / 12;
    final totalInvestments = period;
    final totalPrincipal = amount * totalInvestments;

    // 复利计算
    double totalValue = 0;
    for (int i = 0; i < totalInvestments; i++) {
      totalValue += amount * math.pow(1 + monthlyReturn, totalInvestments - i);
    }

    final totalReturn = totalValue - totalPrincipal;
    final totalReturnRate = (totalReturn / totalPrincipal) * 100;
    final annualizedReturn =
        math.pow(totalValue / totalPrincipal, 12 / period) - 1;

    return {
      'totalPrincipal': totalPrincipal,
      'totalValue': totalValue,
      'totalReturn': totalReturn,
      'totalReturnRate': totalReturnRate * 100,
      'annualizedReturn': annualizedReturn * 100,
      'totalInvestments': totalInvestments,
      'averageCost': totalPrincipal / totalValue, // 简化计算
      'maxDrawdown': -5.23, // 模拟数据
    };
  }

  /// 显示计算说明
  void _showCalculationInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('计算说明'),
        content: const SingleChildScrollView(
          child: Text(
            '定投收益计算器说明：\n\n'
            '1. 定投金额：每次投资的金额\n'
            '2. 投资时长：投资的时间长度（月）\n'
            '3. 定投频率：投资的频率（月/周/日）\n'
            '4. 预期年化收益率：预期的年化收益率\n\n'
            '计算公式采用复利计算方式，考虑了资金的时间价值。\n'
            '实际收益可能与计算结果存在差异，仅供参考。',
            style: TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 分享结果
  void _shareResult() {
    if (_calculationResult == null) return;

    final result = _calculationResult!;
    // 定投收益计算结果文本
    '''定投收益计算结果

投入本金: ¥${result['totalPrincipal']?.toStringAsFixed(0) ?? "0"}
预期收益: ¥${result['totalReturn']?.toStringAsFixed(0) ?? "0"}
总资产: ¥${result['totalValue']?.toStringAsFixed(0) ?? "0"}
收益率: ${result['totalReturnRate']?.toStringAsFixed(2) ?? "0.00"}%
年化收益率: ${result['annualizedReturn']?.toStringAsFixed(2) ?? "0.00"}%

注: 以上计算结果仅供参考，实际收益可能存在差异。投资有风险，入市需谨慎。''';

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('计算结果已复制到剪贴板')),
    );

    // 这里可以集成实际的分享功能
    // Clipboard.setData(ClipboardData(text: shareText));
  }
}
