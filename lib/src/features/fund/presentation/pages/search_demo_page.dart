import 'package:flutter/material.dart';

import 'simple_fund_search_page.dart';

/// 搜索功能演示页面
///
/// 用于测试新的统一搜索架构
class SearchDemoPage extends StatelessWidget {
  const SearchDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('搜索功能演示'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '统一搜索架构演示',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '功能特点：',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildFeatureList(),
            const SizedBox(height: 24),
            const Text(
              '快速测试：',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildQuickTests(context),
            const SizedBox(height: 24),
            _buildFullSearchButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureList() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FeatureItem(
          icon: Icons.search,
          title: '智能搜索',
          description: '支持基金代码、名称模糊搜索',
        ),
        _FeatureItem(
          icon: Icons.speed,
          title: '高性能',
          description: '内存索引，毫秒级响应',
        ),
        _FeatureItem(
          icon: Icons.history,
          title: '搜索历史',
          description: '自动记录搜索历史',
        ),
        _FeatureItem(
          icon: Icons.filter_list,
          title: '灵活筛选',
          description: '多种筛选条件组合',
        ),
        _FeatureItem(
          icon: Icons.refresh,
          title: '实时数据',
          description: '自动刷新最新数据',
        ),
      ],
    );
  }

  Widget _buildQuickTests(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _navigateToSearch(context, '易方达'),
                icon: const Icon(Icons.search),
                label: const Text('搜索"易方达"'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _navigateToSearch(context, '110022'),
                icon: const Icon(Icons.search),
                label: const Text('搜索"110022"'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _navigateToSearch(context, '消费'),
                icon: const Icon(Icons.search),
                label: const Text('搜索"消费"'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _navigateToSearch(context, '沪深300'),
                icon: const Icon(Icons.search),
                label: const Text('搜索"沪深300"'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFullSearchButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _navigateToSearch(context, ''),
        icon: const Icon(Icons.fullscreen),
        label: const Text('完整搜索页面'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  void _navigateToSearch(BuildContext context, String query) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SimpleFundSearchPage(
          title: '基金搜索',
          initialQuery: query.isEmpty ? null : query,
          showFilterPanel: true,
          onFundSelected: (fundCode, fundName) {
            // 显示选择结果
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('已选择：$fundCode - $fundName'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 功能项目组件
class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
