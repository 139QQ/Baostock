import 'package:flutter/material.dart';

import '../../domain/models/fund.dart';

/// 基金经理信息组件
///
/// 展示基金经理的详细信息，包括：
/// - 基本信息和教育背景
/// - 从业经历和管理经验
/// - 管理业绩和投资风格
/// - 当前管理基金情况
class FundManagerInfo extends StatelessWidget {
  final FundManager manager;

  const FundManagerInfo({
    super.key,
    required this.manager,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 基本信息卡片
          _buildBasicInfoCard(),

          const SizedBox(height: 16),

          // 从业经历卡片
          _buildExperienceCard(),

          const SizedBox(height: 16),

          // 管理业绩卡片
          _buildPerformanceCard(),

          const SizedBox(height: 16),

          // 投资风格卡片
          _buildInvestmentStyleCard(),

          const SizedBox(height: 16),

          // 当前管理基金
          _buildCurrentFundsCard(context),
        ],
      ),
    );
  }

  /// 构建基本信息卡片
  Widget _buildBasicInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 头像
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: manager.avatarUrl != null
                      ? ClipOval(
                          child: Image.network(
                            manager.avatarUrl!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: 30,
                          color: Colors.blue.shade600,
                        ),
                ),
                const SizedBox(width: 16),

                // 基本信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        manager.managerName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '从业${manager.totalManageDuration}年',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        manager.educationBackground ?? '暂无教育背景信息',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 关键指标
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricItem(
                  '管理基金',
                  '${manager.currentFundCount}只',
                  Colors.blue,
                ),
                _buildMetricItem(
                  '管理规模',
                  '${manager.totalAssetUnderManagement.toStringAsFixed(0)}亿',
                  Colors.green,
                ),
                _buildMetricItem(
                  '平均年化',
                  '${manager.averageReturnRate.toStringAsFixed(1)}%',
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建从业经历卡片
  Widget _buildExperienceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '从业经历',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // 从业时间线
            _buildTimeline(),

            const SizedBox(height: 16),

            // 专业背景
            _buildInfoSection(
              '教育背景',
              manager.educationBackground ?? '暂无教育背景信息',
              Icons.school,
            ),

            const SizedBox(height: 12),

            // 职业经历
            _buildInfoSection(
              '职业经历',
              manager.professionalExperience ?? '暂无职业经历信息',
              Icons.work,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建时间线
  Widget _buildTimeline() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // 开始时间
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                manager.manageStartDate?.toString().split(' ')[0] ?? '未知日期',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),

          // 时间线
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: Colors.blue,
            ),
          ),

          // 当前时间
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '至今',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建管理业绩卡片
  Widget _buildPerformanceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '管理业绩',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // 业绩指标
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPerformanceMetric(
                  '平均年化收益',
                  '${manager.averageReturnRate.toStringAsFixed(1)}%',
                  Colors.blue,
                ),
                _buildPerformanceMetric(
                  '最佳基金表现',
                  '${manager.bestFundPerformance.toStringAsFixed(1)}%',
                  Colors.green,
                ),
                _buildPerformanceMetric(
                  '风险调整后收益',
                  '${manager.riskAdjustedReturn.toStringAsFixed(1)}%',
                  Colors.orange,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 业绩对比
            _buildPerformanceComparison(),
          ],
        ),
      ),
    );
  }

  /// 构建投资风格卡片
  Widget _buildInvestmentStyleCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '投资风格',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // 风格标签
            _buildStyleTags(),

            const SizedBox(height: 16),

            // 风格描述
            const Text(
              '该基金经理倾向于价值投资，注重企业的长期竞争力和估值安全边际。'
              '在投资决策中，会综合考虑公司的基本面、行业前景和市场情绪等因素。'
              '偏好投资具有稳定现金流、良好治理结构和清晰商业模式的优质企业。',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建当前管理基金卡片
  Widget _buildCurrentFundsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '当前管理基金',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '共${manager.currentFundCount}只',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 基金列表（模拟数据）
            _buildFundList(),

            const SizedBox(height: 12),

            // 查看更多
            TextButton(
              onPressed: () {
                // 导航到基金经理管理的所有基金页面
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('功能开发中...')),
                );
              },
              child: const Text('查看全部管理基金'),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建指标项
  Widget _buildMetricItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
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

  /// 构建信息区域
  Widget _buildInfoSection(String title, String content, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.blue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建业绩指标
  Widget _buildPerformanceMetric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
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
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建业绩对比
  Widget _buildPerformanceComparison() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '业绩对比',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),

          // 对比条形图（简化版）
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '同类平均',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        widthFactor: 0.7,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '12.3%',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '该经理',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        widthFactor: 0.85,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${manager.averageReturnRate.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建风格标签
  Widget _buildStyleTags() {
    final styles = ['价值投资', '长期持有', '稳健收益', '低换手率'];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: styles.map((style) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            style,
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 构建基金列表
  Widget _buildFundList() {
    // 模拟当前管理基金数据
    final funds = [
      {'name': '易方达蓝筹精选混合', 'code': '005827', 'return': 22.3},
      {'name': '易方达优质精选混合', 'code': '110011', 'return': 18.7},
      {'name': '易方达新丝路混合', 'code': '001373', 'return': 15.2},
    ];

    return Column(
      children: funds.map((fund) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fund['name'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      fund['code'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${fund['return']}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    '近1年收益',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
