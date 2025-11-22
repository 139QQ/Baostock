import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:jisu_fund_analyzer/src/features/fund/presentation/fund_exploration/presentation/widgets/fund_card.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/fund_exploration/presentation/widgets/enhanced_fund_card.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/fund_exploration/presentation/widgets/modern_fund_card.dart';
import 'package:jisu_fund_analyzer/src/features/fund/presentation/fund_exploration/domain/models/fund.dart';

/// Story 1.3 微交互验证演示
///
/// 验证基金卡片的微交互设计是否按照故事需求实现：
/// - AC1: 卡片采用极简设计，突出基金名称和关键收益率
/// - AC2: 悬停时卡片轻微上浮，阴影渐变效果
/// - AC3: 收益率数字滚动动画，支持正负值颜色变化
/// - AC4: 新卡片组件完全替代旧组件，功能无缺失
/// - AC5: 卡片状态与BLoC状态管理同步
/// - AC6: 在低端设备上动画流畅，性能达标
/// - AC7: 点击卡片时涟漪扩散效果，提供触觉反馈
/// - AC8: 收藏/对比按钮微动画，状态切换清晰可见
/// - AC9: 支持快速操作手势：左滑收藏，右滑对比
void main() {
  runApp(const Story13MicrointeractionVerificationApp());
}

class Story13MicrointeractionVerificationApp extends StatelessWidget {
  const Story13MicrointeractionVerificationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Story 1.3 微交互验证',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.light,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      home: const MicrointeractionVerificationPage(),
    );
  }
}

class MicrointeractionVerificationPage extends StatefulWidget {
  const MicrointeractionVerificationPage({super.key});

  @override
  State<MicrointeractionVerificationPage> createState() =>
      _MicrointeractionVerificationPageState();
}

class _MicrointeractionVerificationPageState
    extends State<MicrointeractionVerificationPage> {
  final ScrollController _scrollController = ScrollController();
  final List<Fund> _testFunds = _generateTestFunds();
  final Set<String> _favoriteFunds = <String>{};
  final Set<String> _comparisonFunds = <String>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Story 1.3 微交互验证',
          style: TextStyle(fontWeight: FontWeight.w300),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showVerificationCriteria(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // 验证状态概览
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.verified,
                      color: Colors.green.shade600,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '验证状态',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '进行中',
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildVerificationProgress(context),
              ],
            ),
          ),

          // 卡片类型选择标签
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabChip(
                    context,
                    '标准卡片',
                    FundCardType.standard,
                    FundCardType.standard,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTabChip(
                    context,
                    '增强卡片',
                    FundCardType.enhanced,
                    FundCardType.standard,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTabChip(
                    context,
                    '现代卡片',
                    FundCardType.modern,
                    FundCardType.standard,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 基金卡片列表
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: _testFunds.length,
              itemBuilder: (context, index) {
                final fund = _testFunds[index];
                return _buildFundCard(context, fund, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationProgress(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '验收标准检查进度',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: 0.6, // 模拟60%完成度
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.green.shade600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '6/9 AC',
              style: TextStyle(
                color: Colors.green.shade600,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _buildStatusChip('AC1: 极简设计', true),
            _buildStatusChip('AC2: 悬停效果', true),
            _buildStatusChip('AC3: 数字动画', true),
            _buildStatusChip('AC4: 功能完整', true),
            _buildStatusChip('AC5: 状态同步', true),
            _buildStatusChip('AC6: 性能达标', false),
            _buildStatusChip('AC7: 点击反馈', true),
            _buildStatusChip('AC8: 按钮动画', false),
            _buildStatusChip('AC9: 手势操作', false),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip(String label, bool completed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: completed ? Colors.green.shade100 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: completed ? Colors.green.shade300 : Colors.grey.shade300,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: completed ? Colors.green.shade800 : Colors.grey.shade600,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTabChip(
    BuildContext context,
    String label,
    FundCardType type,
    FundCardType selectedType,
  ) {
    final isSelected = type == selectedType;
    return GestureDetector(
      onTap: () {
        setState(() {
          // 切换卡片类型逻辑
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade600 : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.green.shade600 : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildFundCard(BuildContext context, Fund fund, int index) {
    final isSelected = _comparisonFunds.contains(fund.code);
    final isFavorite = _favoriteFunds.contains(fund.code);

    return Column(
      children: [
        // 标准卡片
        _buildStandardCard(context, fund, isSelected, isFavorite, index),

        // 增强卡片
        if (index % 3 == 1)
          _buildEnhancedCard(context, fund, isSelected, isFavorite, index),

        // 现代卡片
        if (index % 3 == 2)
          _buildModernCard(context, fund, isSelected, isFavorite, index),
      ],
    );
  }

  Widget _buildStandardCard(
    BuildContext context,
    Fund fund,
    bool isSelected,
    bool isFavorite,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: FundCard(
        fund: fund,
        showComparisonCheckbox: true,
        showQuickActions: true,
        isSelected: isSelected,
        compactMode: false,
        onTap: () {
          _showCardTapFeedback(context, '标准卡片', fund.name);
        },
        onSelectionChanged: (selected) {
          setState(() {
            if (selected) {
              _comparisonFunds.add(fund.code);
            } else {
              _comparisonFunds.remove(fund.code);
            }
          });
        },
        onAddToWatchlist: () {
          setState(() {
            if (isFavorite) {
              _favoriteFunds.remove(fund.code);
            } else {
              _favoriteFunds.add(fund.code);
            }
          });
          _showActionFeedback(context, '收藏', fund.name, !isFavorite);
        },
        onCompare: () {
          _showActionFeedback(context, '对比', fund.name, isSelected);
        },
        onShare: () {
          _showActionFeedback(context, '分享', fund.name, true);
        },
      )
          .animate()
          .slideY(
            begin: 0.1,
            end: 0,
            duration: 300.ms,
            curve: Curves.easeOut,
          )
          .fadeIn(
            duration: 300.ms,
            delay: (index * 50).ms,
          ),
    );
  }

  Widget _buildEnhancedCard(
    BuildContext context,
    Fund fund,
    bool isSelected,
    bool isFavorite,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: EnhancedFundCard(
        fund: fund,
        showComparisonCheckbox: true,
        showQuickActions: true,
        isSelected: isSelected,
        compactMode: false,
        onTap: () {
          _showCardTapFeedback(context, '增强卡片', fund.name);
        },
        onSelectionChanged: (selected) {
          setState(() {
            if (selected) {
              _comparisonFunds.add(fund.code);
            } else {
              _comparisonFunds.remove(fund.code);
            }
          });
        },
        onAddToWatchlist: () {
          setState(() {
            if (isFavorite) {
              _favoriteFunds.remove(fund.code);
            } else {
              _favoriteFunds.add(fund.code);
            }
          });
          _showActionFeedback(context, '收藏', fund.name, !isFavorite);
        },
        onCompare: () {
          _showActionFeedback(context, '对比', fund.name, isSelected);
        },
        onShare: () {
          _showActionFeedback(context, '分享', fund.name, true);
        },
      )
          .animate()
          .slideY(
            begin: 0.1,
            end: 0,
            duration: 300.ms,
            curve: Curves.easeOut,
          )
          .fadeIn(
            duration: 300.ms,
            delay: (index * 50).ms,
          ),
    );
  }

  Widget _buildModernCard(
    BuildContext context,
    Fund fund,
    bool isSelected,
    bool isFavorite,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ModernFundCard(
        fund: FundRanking.fromFund(fund, index + 1),
        ranking: index + 1,
        selectedPeriod: '近1年',
        onTap: () {
          _showCardTapFeedback(context, '现代卡片', fund.name);
        },
        onFavorite: () {
          setState(() {
            if (isFavorite) {
              _favoriteFunds.remove(fund.code);
            } else {
              _favoriteFunds.add(fund.code);
            }
          });
          _showActionFeedback(context, '收藏', fund.name, !isFavorite);
        },
        onDetails: () {
          _showActionFeedback(context, '详情', fund.name, true);
        },
        isFavorite: isFavorite,
        displayMode: CardDisplayMode.compact,
      )
          .animate()
          .slideY(
            begin: 0.1,
            end: 0,
            duration: 300.ms,
            curve: Curves.easeOut,
          )
          .fadeIn(
            duration: 300.ms,
            delay: (index * 50).ms,
          ),
    );
  }

  void _showCardTapFeedback(
      BuildContext context, String cardType, String fundName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$cardType点击: $fundName'),
        duration: const Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showActionFeedback(
    BuildContext context,
    String action,
    String fundName,
    bool success,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action${success ? '成功' : '取消'}: $fundName'),
        duration: const Duration(milliseconds: 1000),
        backgroundColor: success ? Colors.green.shade600 : Colors.grey.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showVerificationCriteria(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Story 1.3 验收标准'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCriteriaSection('功能需求', [
                'AC1: 卡片采用极简设计，突出基金名称和关键收益率',
                'AC2: 悬停时卡片轻微上浮，阴影渐变效果',
                'AC3: 收益率数字滚动动画，支持正负值颜色变化',
              ]),
              const SizedBox(height: 16),
              _buildCriteriaSection('集成需求', [
                'AC4: 新卡片组件完全替代旧组件，功能无缺失',
                'AC5: 卡片状态与BLoC状态管理同步',
                'AC6: 在低端设备上动画流畅，性能达标',
              ]),
              const SizedBox(height: 16),
              _buildCriteriaSection('质量需求', [
                'AC7: 点击卡片时涟漪扩散效果，提供触觉反馈',
                'AC8: 收藏/对比按钮微动画，状态切换清晰可见',
                'AC9: 支持快速操作手势：左滑收藏，右滑对比',
              ]),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Text(
                '• $item',
                style: const TextStyle(fontSize: 14),
              ),
            )),
      ],
    );
  }

  static List<Fund> _generateTestFunds() {
    return [
      Fund(
        code: '110022',
        name: '易方达消费行业',
        type: '股票型',
        manager: '萧楠',
        scale: 68.9,
        return1Y: 15.23,
        return3Y: 48.56,
        return5Y: 126.78,
        returnYTD: 8.92,
        dailyReturn: 0.45,
        navDate: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Fund(
        code: '161725',
        name: '招商中证白酒',
        type: '指数型',
        manager: '侯昊',
        scale: 156.78,
        return1Y: -8.45,
        return3Y: 65.23,
        return5Y: 198.45,
        returnYTD: -12.34,
        dailyReturn: -0.89,
        navDate: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Fund(
        code: '005827',
        name: '易方达蓝筹精选',
        type: '混合型',
        manager: '张坤',
        scale: 89.12,
        return1Y: -12.67,
        return3Y: 89.34,
        return5Y: 245.67,
        returnYTD: -15.23,
        dailyReturn: 1.23,
        navDate: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Fund(
        code: '000001',
        name: '华夏成长',
        type: '混合型',
        manager: '张帆',
        scale: 45.67,
        return1Y: 22.34,
        return3Y: 56.78,
        return5Y: 167.89,
        returnYTD: 18.45,
        dailyReturn: 0.67,
        navDate: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Fund(
        code: '519008',
        name: '汇添富优势',
        type: '混合型',
        manager: '劳杰男',
        scale: 78.34,
        return1Y: 8.91,
        return3Y: 42.13,
        return5Y: 134.56,
        returnYTD: 6.78,
        dailyReturn: -0.23,
        navDate: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }
}

enum FundCardType {
  standard,
  enhanced,
  modern,
}

// 扩展 FundRanking 类以支持从 Fund 创建
extension FundRankingExtension on FundRanking {
  static FundRanking fromFund(Fund fund, int ranking) {
    return FundRanking(
      fundCode: fund.code,
      fundName: fund.name,
      fundType: fund.type,
      unitNav: 1.2345, // 模拟数据
      dailyReturn: fund.dailyReturn,
      return1W: 2.34, // 模拟数据
      return1M: 3.45, // 模拟数据
      return3M: 5.67, // 模拟数据
      return6M: 7.89, // 模拟数据
      return1Y: fund.return1Y,
      return2Y: 12.34, // 模拟数据
      return3Y: fund.return3Y,
      returnYTD: fund.returnYTD,
      returnSinceInception: fund.return5Y, // 使用5年收益作为成立来收益
      manager: fund.manager,
      scale: fund.scale,
      establishDate: '2015-01-01', // 模拟数据
      trackingIndex: '', // 模拟数据
      feeRate: 0.15, // 模拟数据
      minInvestAmount: 1.0, // 模拟数据
      riskLevel: '中等', // 模拟数据
      investmentStyle: '成长型', // 模拟数据
      navUpdateDate: fund.navDate,
      ranking: ranking,
      rankingChange: 2, // 模拟数据
      isRecommended: ranking <= 3, // 前三名推荐
      popularity: 85.5, // 模拟数据
    );
  }
}
