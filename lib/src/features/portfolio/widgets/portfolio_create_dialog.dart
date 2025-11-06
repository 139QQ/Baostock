import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/portfolio_bloc.dart';
import '../../../services/portfolio_analysis_service.dart';

/// 创建投资组合对话框
class PortfolioCreateDialog extends StatefulWidget {
  final PortfolioStrategy strategy;

  const PortfolioCreateDialog({
    super.key,
    this.strategy = PortfolioStrategy.balanced,
  });

  @override
  State<PortfolioCreateDialog> createState() => _PortfolioCreateDialogState();
}

class _PortfolioCreateDialogState extends State<PortfolioCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  PortfolioStrategy _selectedStrategy = PortfolioStrategy.balanced;
  final List<PortfolioHolding> _holdings = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedStrategy = widget.strategy;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 800),
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBasicInfoSection(),
                      const SizedBox(height: 24),
                      _buildStrategySection(),
                      const SizedBox(height: 24),
                      _buildHoldingsSection(),
                      const SizedBox(height: 24),
                      _buildPreviewSection(),
                    ],
                  ),
                ),
              ),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.add_circle,
            color: Theme.of(context).primaryColor,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '创建投资组合',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '基本信息',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: '组合名称',
            hintText: '请输入投资组合名称',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.account_balance_wallet),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '请输入投资组合名称';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: '组合描述 (可选)',
            hintText: '请输入投资组合描述',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildStrategySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '投资策略',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ...PortfolioStrategy.values.map((strategy) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: RadioListTile<PortfolioStrategy>(
                value: strategy,
                groupValue: _selectedStrategy,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedStrategy = value;
                    });
                  }
                },
                title: Text(strategy.displayName),
                subtitle: Text(_getStrategyDescription(strategy)),
                activeColor: Theme.of(context).primaryColor,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              ),
            )),
      ],
    );
  }

  Widget _buildHoldingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '基金持仓',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _addHolding,
              icon: const Icon(Icons.add),
              label: const Text('添加基金'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_holdings.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.add_chart,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  '暂无持仓',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '点击上方"添加基金"按钮添加基金持仓',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                ),
              ],
            ),
          )
        else
          ..._holdings.asMap().entries.map((entry) {
            final index = entry.key;
            final holding = entry.value;
            return _buildHoldingItem(holding, index);
          }),
        if (_holdings.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '总权重: ${_calculateTotalWeight().toStringAsFixed(1)}% (目标: 100%)',
                    style: TextStyle(
                      color: Colors.blue[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHoldingItem(PortfolioHolding holding, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    holding.fundName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    holding.fundCode,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 100,
              child: TextFormField(
                initialValue: (holding.weight * 100).toStringAsFixed(1),
                decoration: const InputDecoration(
                  labelText: '权重',
                  suffixText: '%',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final weight = double.tryParse(value) ?? 0;
                  _updateHoldingWeight(index, weight / 100);
                },
                validator: (value) {
                  final weight = double.tryParse(value ?? '') ?? 0;
                  if (weight <= 0 || weight > 100) {
                    return '0-100';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _removeHolding(index),
              icon: const Icon(Icons.remove_circle, color: Colors.red),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection() {
    if (_holdings.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '预览',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Container(
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
                '组合名称: ${_nameController.text.isNotEmpty ? _nameController.text : "未命名"}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '投资策略: ${_selectedStrategy.displayName}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '基金数量: ${_holdings.length}只',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (_calculateTotalWeight() != 100.0) ...[
                const SizedBox(height: 8),
                Text(
                  '⚠️ 权重总和不为100%，创建时将自动调整',
                  style: TextStyle(
                    color: Colors.orange[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed:
                  _isLoading || _holdings.isEmpty ? null : _createPortfolio,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('创建组合'),
            ),
          ),
        ],
      ),
    );
  }

  String _getStrategyDescription(PortfolioStrategy strategy) {
    switch (strategy) {
      case PortfolioStrategy.conservative:
        return '低风险，稳健收益，适合保守型投资者';
      case PortfolioStrategy.balanced:
        return '中等风险，均衡配置，适合稳健型投资者';
      case PortfolioStrategy.aggressive:
        return '高风险，高收益，适合进取型投资者';
      case PortfolioStrategy.custom:
        return '自定义配置，完全自主决定';
    }
  }

  void _addHolding() {
    // TODO: 实现基金选择功能
    // 临时添加示例持仓
    setState(() {
      _holdings.add(PortfolioHolding(
        fundCode: '000001',
        fundName: '华夏成长混合',
        weight: 0.0,
      ));
    });
  }

  void _removeHolding(int index) {
    setState(() {
      _holdings.removeAt(index);
    });
  }

  void _updateHoldingWeight(int index, double weight) {
    setState(() {
      _holdings[index] = PortfolioHolding(
        fundCode: _holdings[index].fundCode,
        fundName: _holdings[index].fundName,
        weight: weight,
      );
    });
  }

  double _calculateTotalWeight() {
    return _holdings.fold<double>(0, (sum, holding) => sum + holding.weight) *
        100;
  }

  void _createPortfolio() async {
    if (!_formKey.currentState!.validate()) return;

    if (_holdings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少添加一只基金')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 调整权重使总和为100%
      final totalWeight = _holdings.fold<double>(0, (sum, h) => sum + h.weight);
      final adjustedHoldings = totalWeight > 0
          ? _holdings
              .map((h) => PortfolioHolding(
                    fundCode: h.fundCode,
                    fundName: h.fundName,
                    weight: h.weight / totalWeight,
                  ))
              .toList()
          : _holdings;

      context.read<PortfolioBloc>().add(CreatePortfolio(
            name: _nameController.text,
            description: _descriptionController.text.isNotEmpty
                ? _descriptionController.text
                : null,
            holdings: adjustedHoldings,
            strategy: _selectedStrategy,
          ));

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('投资组合创建成功')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('创建失败：$e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
