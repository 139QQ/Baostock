import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/entities/portfolio_holding.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/presentation/cubit/portfolio_analysis_cubit.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/presentation/cubit/portfolio_analysis_state.dart';
import 'package:jisu_fund_analyzer/src/core/di/injection_container.dart';

/// 持仓管理组件
///
/// 提供添加、删除、修改持仓的功能
class PortfolioManager extends StatefulWidget {
  const PortfolioManager({super.key});

  @override
  State<PortfolioManager> createState() => _PortfolioManagerState();
}

class _PortfolioManagerState extends State<PortfolioManager> {
  @override
  void initState() {
    super.initState();
    // 确保初始化 cubit 状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        context.read<PortfolioAnalysisCubit>().initializeAnalysis();
      } catch (e) {
        // 忽略初始化错误，可能会与现有状态冲突
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 使用Builder包装BlocBuilder，以便在Provider缺失时提供更好的错误处理
    return Scaffold(
      appBar: AppBar(
        title: const Text('持仓管理'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showAddHoldingDialog,
            icon: const Icon(Icons.add),
            tooltip: '添加持仓',
          ),
        ],
      ),
      body: BlocBuilder<PortfolioAnalysisCubit, PortfolioAnalysisState>(
        builder: (context, state) {
          return state.when(
            initial: (_) => _buildInitialView(),
            loading: (_) => _buildLoadingView(),
            loaded: (state) {
              return Column(
                children: [
                  if (state.error != null) _buildErrorView(state.error!),
                  Expanded(
                    child: state.holdings.isEmpty
                        ? _buildEmptyView()
                        : _buildHoldingsList(state.holdings),
                  ),
                ],
              );
            },
            noData: (_) => _buildEmptyView(),
            error: (state) => _buildErrorView(state.error!),
          );
        },
      ),
    );
  }

  Widget _buildInitialView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('初始化中...'),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('加载持仓数据中...'),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '暂无持仓',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '添加您的第一只基金开始分析',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddHoldingDialog,
            icon: const Icon(Icons.add),
            label: const Text('添加持仓'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<PortfolioAnalysisCubit>().refreshData();
            },
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderErrorView(dynamic error) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber, size: 48, color: Colors.orange[700]),
            const SizedBox(height: 16),
            Text(
              '状态管理器未找到',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'PortfolioAnalysisCubit 不可用',
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('返回'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHoldingsList(List<PortfolioHolding> holdings) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<PortfolioAnalysisCubit>().refreshData();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: holdings.length,
        itemBuilder: (context, index) {
          final holding = holdings[index];
          return _buildHoldingCard(holding, index);
        },
      ),
    );
  }

  Widget _buildHoldingCard(PortfolioHolding holding, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        holding.fundName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${holding.fundCode} | ${holding.fundType}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (action) {
                    switch (action) {
                      case 'edit':
                        _showEditHoldingDialog(holding, index);
                        break;
                      case 'delete':
                        _showDeleteConfirmation(holding, index);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16),
                          SizedBox(width: 8),
                          Text('编辑'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('删除', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildMetricItem(
                    '持有份额', '${holding.holdingAmount.toStringAsFixed(2)}份'),
                const SizedBox(width: 24),
                _buildMetricItem(
                    '成本价', '¥${holding.costNav.toStringAsFixed(4)}'),
                const SizedBox(width: 24),
                _buildMetricItem(
                    '现价', '¥${holding.currentNav.toStringAsFixed(4)}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildMetricItem(
                    '成本金额', '¥${holding.costValue.toStringAsFixed(2)}'),
                const SizedBox(width: 24),
                _buildMetricItem(
                    '市值', '¥${holding.marketValue.toStringAsFixed(2)}'),
                const SizedBox(width: 24),
                _buildMetricItem(
                  '收益',
                  holding.returnDescription,
                  valueColor: holding.isProfitable ? Colors.green : Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  void _showAddHoldingDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AddHoldingDialog(
        onAdd: (holding) async {
          final success = await context
              .read<PortfolioAnalysisCubit>()
              .addDefaultUserHolding(holding);
          if (dialogContext.mounted) {
            if (success) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(
                  content: Text('已添加持仓: ${holding.fundName}'),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(
                  content: Text('添加持仓失败: ${holding.fundName}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showEditHoldingDialog(PortfolioHolding holding, int index) {
    showDialog(
      context: context,
      builder: (dialogContext) => EditHoldingDialog(
        holding: holding,
        onEdit: (updatedHolding) async {
          final success = await context
              .read<PortfolioAnalysisCubit>()
              .updateDefaultUserHolding(updatedHolding);
          if (dialogContext.mounted) {
            if (success) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(
                  content: Text('已更新持仓: ${updatedHolding.fundName}'),
                  backgroundColor: Colors.blue,
                ),
              );
            } else {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(
                  content: Text('更新持仓失败: ${updatedHolding.fundName}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showDeleteConfirmation(PortfolioHolding holding, int index) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除持仓"${holding.fundName}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final success = await context
                  .read<PortfolioAnalysisCubit>()
                  .deleteDefaultUserHolding(holding.fundCode);
              if (success) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('已删除持仓: ${holding.fundName}'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('删除持仓失败: ${holding.fundName}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

/// 添加持仓对话框
class AddHoldingDialog extends StatefulWidget {
  final Function(PortfolioHolding) onAdd;

  const AddHoldingDialog({super.key, required this.onAdd});

  @override
  State<AddHoldingDialog> createState() => _AddHoldingDialogState();
}

class _AddHoldingDialogState extends State<AddHoldingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _fundCodeController = TextEditingController();
  final _fundNameController = TextEditingController();
  final _holdingAmountController = TextEditingController();
  final _costNavController = TextEditingController();

  String _fundType = '混合型';
  bool _dividendReinvestment = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加持仓'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _fundCodeController,
                decoration: const InputDecoration(
                  labelText: '基金代码',
                  hintText: '例如: 000001',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入基金代码';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fundNameController,
                decoration: const InputDecoration(
                  labelText: '基金名称',
                  hintText: '例如: 华夏成长混合',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入基金名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _fundType,
                decoration: const InputDecoration(labelText: '基金类型'),
                items: ['股票型', '混合型', '债券型', '货币型', '指数型', 'QDII']
                    .map((type) =>
                        DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _fundType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _holdingAmountController,
                decoration: const InputDecoration(
                  labelText: '持有份额',
                  hintText: '例如: 1000.00',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入持有份额';
                  }
                  if (double.tryParse(value) == null ||
                      double.parse(value) <= 0) {
                    return '请输入有效的份额数量';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _costNavController,
                decoration: const InputDecoration(
                  labelText: '成本净值',
                  hintText: '例如: 1.2500',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入成本净值';
                  }
                  if (double.tryParse(value) == null ||
                      double.parse(value) <= 0) {
                    return '请输入有效的净值';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('分红再投资'),
                value: _dividendReinvestment,
                onChanged: (value) {
                  setState(() {
                    _dividendReinvestment = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _addHolding,
          child: const Text('添加'),
        ),
      ],
    );
  }

  void _addHolding() {
    if (_formKey.currentState!.validate()) {
      final holding = PortfolioHolding(
        fundCode: _fundCodeController.text,
        fundName: _fundNameController.text,
        fundType: _fundType,
        holdingAmount: double.parse(_holdingAmountController.text),
        costNav: double.parse(_costNavController.text),
        costValue: double.parse(_holdingAmountController.text) *
            double.parse(_costNavController.text),
        marketValue: 0.0, // 将通过API获取当前净值计算
        currentNav: double.parse(_costNavController.text), // 临时使用成本净值
        accumulatedNav: 0.0, // 将通过API获取
        holdingStartDate: DateTime.now(),
        lastUpdatedDate: DateTime.now(),
        dividendReinvestment: _dividendReinvestment,
        status: HoldingStatus.active,
      );

      widget.onAdd(holding);
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _fundCodeController.dispose();
    _fundNameController.dispose();
    _holdingAmountController.dispose();
    _costNavController.dispose();
    super.dispose();
  }
}

/// 编辑持仓对话框
class EditHoldingDialog extends StatefulWidget {
  final PortfolioHolding holding;
  final Function(PortfolioHolding) onEdit;

  const EditHoldingDialog(
      {super.key, required this.holding, required this.onEdit});

  @override
  State<EditHoldingDialog> createState() => _EditHoldingDialogState();
}

class _EditHoldingDialogState extends State<EditHoldingDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _holdingAmountController;
  late final TextEditingController _costNavController;
  late bool _dividendReinvestment;

  @override
  void initState() {
    super.initState();
    _holdingAmountController =
        TextEditingController(text: widget.holding.holdingAmount.toString());
    _costNavController =
        TextEditingController(text: widget.holding.costNav.toString());
    _dividendReinvestment = widget.holding.dividendReinvestment;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑持仓'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${widget.holding.fundName} (${widget.holding.fundCode})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _holdingAmountController,
                decoration: const InputDecoration(
                  labelText: '持有份额',
                  hintText: '例如: 1000.00',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入持有份额';
                  }
                  if (double.tryParse(value) == null ||
                      double.parse(value) <= 0) {
                    return '请输入有效的份额数量';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _costNavController,
                decoration: const InputDecoration(
                  labelText: '成本净值',
                  hintText: '例如: 1.2500',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入成本净值';
                  }
                  if (double.tryParse(value) == null ||
                      double.parse(value) <= 0) {
                    return '请输入有效的净值';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('分红再投资'),
                value: _dividendReinvestment,
                onChanged: (value) {
                  setState(() {
                    _dividendReinvestment = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _updateHolding,
          child: const Text('更新'),
        ),
      ],
    );
  }

  void _updateHolding() {
    if (_formKey.currentState!.validate()) {
      final updatedHolding = PortfolioHolding(
        fundCode: widget.holding.fundCode,
        fundName: widget.holding.fundName,
        fundType: widget.holding.fundType,
        holdingAmount: double.parse(_holdingAmountController.text),
        costNav: double.parse(_costNavController.text),
        costValue: double.parse(_holdingAmountController.text) *
            double.parse(_costNavController.text),
        marketValue: widget.holding.marketValue,
        currentNav: widget.holding.currentNav,
        accumulatedNav: widget.holding.accumulatedNav,
        holdingStartDate: widget.holding.holdingStartDate,
        lastUpdatedDate: DateTime.now(),
        dividendReinvestment: _dividendReinvestment,
        status: widget.holding.status,
      );

      widget.onEdit(updatedHolding);
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _holdingAmountController.dispose();
    _costNavController.dispose();
    super.dispose();
  }
}
