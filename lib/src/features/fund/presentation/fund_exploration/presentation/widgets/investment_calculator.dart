import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

/// 投资计算器组件
///
/// 提供基金投资收益计算功能，包括：
/// - 投资金额输入和参数设置
/// - 收益预测和风险计算
/// - 投资建议和结果展示
/// - 响应式布局适配
class InvestmentCalculator extends StatefulWidget {
  const InvestmentCalculator({super.key});

  @override
  State<InvestmentCalculator> createState() => _InvestmentCalculatorState();
}

class _InvestmentCalculatorState extends State<InvestmentCalculator>
    with TickerProviderStateMixin {
  // 控制器
  final TextEditingController _amountController =
      TextEditingController(text: '1000');
  final TextEditingController _periodController =
      TextEditingController(text: '12');
  final TextEditingController _expectedReturnController =
      TextEditingController(text: '8');

  // 计算参数
  String _frequency = 'monthly'; // monthly, weekly, daily
  String _riskLevel = 'medium'; // low, medium, high

  // 计算结果
  Map<String, dynamic>? _calculationResult;
  bool _isCalculating = false;

  // 动画控制器
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // 响应式布局
  bool _isCompactLayout = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _performCalculation();

    // 监听布局变化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLayout();
    });
  }

  /// 初始化动画
  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  /// 检查布局状态
  void _checkLayout() {
    if (mounted) {
      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final width = renderBox.size.width;
        setState(() {
          _isCompactLayout = width < 320;
        });
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _periodController.dispose();
    _expectedReturnController.dispose();
    _animationController.dispose();
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
          elevation: 4,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
                _buildCalculateButton(),
                const SizedBox(height: 16),

                // 计算结果区域
                if (_calculationResult != null) ...[
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildResultSection(),
                  ),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E40AF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.calculate,
                      color: Color(0xFF1E40AF),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '投资计算器',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: _showCalculationInfo,
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('说明', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ],
          )
        : Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E40AF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calculate,
                  color: Color(0xFF1E40AF),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '投资计算器',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      '计算投资收益和风险评估',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _showCalculationInfo,
                icon: const Icon(Icons.info_outline),
                tooltip: '计算说明',
              ),
            ],
          );
  }

  /// 构建参数设置区域
  Widget _buildParameterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '投资参数',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),

          // 投资金额
          _buildInputField(
            controller: _amountController,
            label: '投资金额',
            hintText: '请输入投资金额',
            prefixText: '¥',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => _onParameterChanged(),
          ),
          const SizedBox(height: 12),

          // 投资时长和频率
          _isCompactLayout
              ? Column(
                  children: [
                    _buildInputField(
                      controller: _periodController,
                      label: '投资时长',
                      hintText: '投资时长',
                      suffixText: '个月',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => _onParameterChanged(),
                    ),
                    const SizedBox(height: 12),
                    _buildFrequencyDropdown(),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildInputField(
                        controller: _periodController,
                        label: '投资时长',
                        hintText: '投资时长',
                        suffixText: '个月',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        onChanged: (_) => _onParameterChanged(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _buildFrequencyDropdown(),
                    ),
                  ],
                ),
          const SizedBox(height: 12),

          // 预期收益率
          _buildInputField(
            controller: _expectedReturnController,
            label: '预期年化收益率',
            hintText: '请输入预期年化收益率',
            suffixText: '%',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            onChanged: (_) => _onParameterChanged(),
          ),
          const SizedBox(height: 12),

          // 风险等级选择
          _buildRiskLevelSelector(),
        ],
      ),
    );
  }

  /// 构建输入字段
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    String? prefixText,
    String? suffixText,
    required TextInputType keyboardType,
    required List<TextInputFormatter> inputFormatters,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixText: prefixText,
        suffixText: suffixText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
    );
  }

  /// 构建频率下拉选择器
  Widget _buildFrequencyDropdown() {
    return DropdownButtonFormField<String>(
      value: _frequency,
      decoration: InputDecoration(
        labelText: '投资频率',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
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
          _onParameterChanged();
        }
      },
    );
  }

  /// 构建风险等级选择器
  Widget _buildRiskLevelSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '风险等级',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildRiskOption('low', '低风险', Colors.green),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildRiskOption('medium', '中风险', Colors.orange),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildRiskOption('high', '高风险', Colors.red),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建风险选项
  Widget _buildRiskOption(String value, String label, Color color) {
    final isSelected = _riskLevel == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _riskLevel = value;
        });
        _onParameterChanged();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? color : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  /// 构建计算按钮
  Widget _buildCalculateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isCalculating ? null : _performCalculation,
        icon: _isCalculating
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              )
            : const Icon(Icons.calculate),
        label: Text(_isCalculating ? '计算中...' : '开始计算'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E40AF),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  /// 构建结果区域
  Widget _buildResultSection() {
    final result = _calculationResult!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E40AF).withOpacity(0.05),
            const Color(0xFF3B82F6).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E40AF).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 结果标题
          _buildResultHeader(),
          const SizedBox(height: 16),

          // 主要结果
          _buildMainResults(result),
          const SizedBox(height: 16),

          // 详细信息
          _buildDetailedResults(result),
          const SizedBox(height: 16),

          // 投资建议
          _buildInvestmentAdvice(result),
        ],
      ),
    );
  }

  /// 构建结果标题
  Widget _buildResultHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E40AF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.show_chart,
            color: Color(0xFF1E40AF),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            '计算结果',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E40AF),
            ),
          ),
        ),
        IconButton(
          onPressed: _shareResult,
          icon: const Icon(Icons.share, size: 20),
          tooltip: '分享结果',
          constraints: const BoxConstraints(),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }

  /// 构建主要结果
  Widget _buildMainResults(Map<String, dynamic> result) {
    return _isCompactLayout
        ? Column(
            children: [
              _buildResultItem(
                '投入本金',
                '¥${result['totalPrincipal']?.toStringAsFixed(0) ?? "0"}',
                Colors.blue,
              ),
              const SizedBox(height: 12),
              _buildResultItem(
                '预期收益',
                '¥${result['totalReturn']?.toStringAsFixed(0) ?? "0"}',
                _getReturnColor(result['totalReturn'] ?? 0),
              ),
              const SizedBox(height: 12),
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
                _getReturnColor(result['totalReturn'] ?? 0),
              ),
              _buildResultItem(
                '总资产',
                '¥${result['totalValue']?.toStringAsFixed(0) ?? "0"}',
                Colors.green,
              ),
            ],
          );
  }

  /// 构建结果项
  Widget _buildResultItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: _isCompactLayout ? 16 : 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// 构建详细结果
  Widget _buildDetailedResults(Map<String, dynamic> result) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildDetailRow('投资次数', '${result['totalInvestments'] ?? 0} 次'),
          _buildDetailRow('平均成本',
              '¥${result['averageCost']?.toStringAsFixed(4) ?? "0.0000"}'),
          _buildDetailRow('收益率',
              '${result['totalReturnRate']?.toStringAsFixed(2) ?? "0.00"}%'),
          _buildDetailRow('年化收益率',
              '${result['annualizedReturn']?.toStringAsFixed(2) ?? "0.00"}%'),
          if (result['maxDrawdown'] != null)
            _buildDetailRow(
                '最大回撤', '${result['maxDrawdown'].toStringAsFixed(2)}%'),
          if (result['riskScore'] != null)
            _buildDetailRow(
                '风险评分', '${result['riskScore'].toStringAsFixed(1)}/10'),
        ],
      ),
    );
  }

  /// 构建详情行
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建投资建议
  Widget _buildInvestmentAdvice(Map<String, dynamic> result) {
    final advice = _generateAdvice(result);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getAdviceColor(advice['level']).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getAdviceColor(advice['level']).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: _getAdviceColor(advice['level']),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                '投资建议',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _getAdviceColor(advice['level']),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...advice['suggestions']
              .map<Widget>((suggestion) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '•',
                          style: TextStyle(
                            fontSize: 12,
                            color: _getAdviceColor(advice['level']),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            suggestion,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  /// 参数变化时自动重新计算
  void _onParameterChanged() {
    // 延迟计算，避免频繁计算
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _performCalculation();
      }
    });
  }

  /// 执行计算
  Future<void> _performCalculation() async {
    if (_isCalculating) return;

    setState(() {
      _isCalculating = true;
    });

    try {
      // 模拟计算过程
      await Future.delayed(const Duration(milliseconds: 800));

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

        // 重新播放动画
        _animationController.reset();
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCalculating = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('计算失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 计算投资收益
  Map<String, dynamic> _calculateInvestment(
      double amount, int period, double expectedReturn) {
    // 根据频率调整计算
    int frequencyFactor = _getFrequencyFactor();
    int totalInvestments = period * frequencyFactor;
    double periodReturn = expectedReturn / 100 / frequencyFactor;

    final totalPrincipal = amount * totalInvestments;

    // 复利计算
    double totalValue = 0;
    for (int i = 0; i < totalInvestments; i++) {
      totalValue += amount * math.pow(1 + periodReturn, totalInvestments - i);
    }

    final totalReturn = totalValue - totalPrincipal;
    final totalReturnRate = (totalReturn / totalPrincipal) * 100;
    final annualizedReturn =
        math.pow(totalValue / totalPrincipal, frequencyFactor / 12.0) - 1;

    // 风险计算
    final riskScore = _calculateRiskScore(expectedReturn, _riskLevel);
    final maxDrawdown = _calculateMaxDrawdown(_riskLevel, expectedReturn);

    return {
      'totalPrincipal': totalPrincipal,
      'totalValue': totalValue,
      'totalReturn': totalReturn,
      'totalReturnRate': totalReturnRate,
      'annualizedReturn': annualizedReturn * 100,
      'totalInvestments': totalInvestments,
      'averageCost': totalPrincipal / totalValue,
      'maxDrawdown': maxDrawdown,
      'riskScore': riskScore,
      'frequency': _frequency,
      'riskLevel': _riskLevel,
    };
  }

  /// 获取频率系数
  int _getFrequencyFactor() {
    switch (_frequency) {
      case 'daily':
        return 30; // 假设每月30天
      case 'weekly':
        return 4; // 假设每月4周
      case 'monthly':
      default:
        return 1;
    }
  }

  /// 计算风险评分
  double _calculateRiskScore(double expectedReturn, String riskLevel) {
    double baseScore = expectedReturn / 10; // 基础评分

    switch (riskLevel) {
      case 'low':
        return math.max(1.0, math.min(4.0, baseScore));
      case 'medium':
        return math.max(3.0, math.min(7.0, baseScore + 2));
      case 'high':
        return math.max(6.0, math.min(10.0, baseScore + 4));
      default:
        return 5.0;
    }
  }

  /// 计算最大回撤
  double _calculateMaxDrawdown(String riskLevel, double expectedReturn) {
    switch (riskLevel) {
      case 'low':
        return -2.0 - (expectedReturn * 0.1);
      case 'medium':
        return -5.0 - (expectedReturn * 0.2);
      case 'high':
        return -10.0 - (expectedReturn * 0.3);
      default:
        return -5.0;
    }
  }

  /// 生成投资建议
  Map<String, dynamic> _generateAdvice(Map<String, dynamic> result) {
    final returnRate = result['totalReturnRate'] ?? 0.0;
    final riskScore = result['riskScore'] ?? 5.0;
    final riskLevel = result['riskLevel'] ?? 'medium';

    List<String> suggestions = [];
    String level = 'medium';

    if (returnRate > 20) {
      level = 'high';
      suggestions.add('预期收益率较高，建议注意风险控制');
      suggestions.add('可考虑分批投入，降低市场波动影响');
    } else if (returnRate > 10) {
      level = 'medium';
      suggestions.add('收益率预期合理，适合稳健投资');
      suggestions.add('建议定期评估投资组合表现');
    } else {
      level = 'low';
      suggestions.add('收益率预期较低，可考虑优化投资策略');
      suggestions.add('建议适当增加投资金额以提高收益');
    }

    if (riskLevel == 'high') {
      suggestions.add('高风险投资，建议配置部分稳健资产');
    } else if (riskLevel == 'low') {
      suggestions.add('低风险策略，适合保守型投资者');
    }

    if (riskScore > 7) {
      suggestions.add('风险评分较高，建议做好资金管理');
    }

    return {
      'level': level,
      'suggestions': suggestions,
    };
  }

  /// 获取收益颜色
  Color _getReturnColor(double returnValue) {
    if (returnValue > 0) {
      return Colors.green;
    } else if (returnValue < 0) {
      return Colors.red;
    } else {
      return Colors.grey;
    }
  }

  /// 获取建议颜色
  Color _getAdviceColor(String level) {
    switch (level) {
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// 显示计算说明
  void _showCalculationInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('计算说明'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '投资收益计算器使用说明：',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Text(
                '1. 投资金额：每次投资的金额\n'
                '2. 投资时长：投资的时间长度（月）\n'
                '3. 投资频率：投资的频率（月/周/日）\n'
                '4. 预期年化收益率：预期的年化收益率\n'
                '5. 风险等级：投资的风险偏好\n\n'
                '计算方式：\n'
                '• 采用复利计算方式，考虑资金时间价值\n'
                '• 根据不同频率调整计算周期\n'
                '• 风险评分基于收益率和风险等级\n'
                '• 最大回撤根据风险等级模拟计算\n\n'
                '重要提示：\n'
                '• 计算结果仅供参考，实际收益可能存在差异\n'
                '• 投资有风险，入市需谨慎\n'
                '• 建议结合个人风险承受能力进行投资决策',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
            ],
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('计算结果已生成，可复制分享'),
        duration: Duration(seconds: 2),
      ),
    );

    // 这里可以集成实际的分享功能
    // final shareText = _generateShareText(_calculationResult!);
    // Clipboard.setData(ClipboardData(text: shareText));
  }
}
