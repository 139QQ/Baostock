import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 热门板块预览组件
///
/// 展示当前热门投资板块，支持横向滚动和微动交互
class HotSectorsPreview extends StatefulWidget {
  final int maxItems;
  final bool showTitle;
  final Axis scrollDirection;

  const HotSectorsPreview({
    super.key,
    this.maxItems = 5,
    this.showTitle = true,
    this.scrollDirection = Axis.horizontal,
  });

  @override
  State<HotSectorsPreview> createState() => _HotSectorsPreviewState();
}

class _HotSectorsPreviewState extends State<HotSectorsPreview>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _bounceController;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _shimmerAnimation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));

    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sectors = _getHotSectors();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTitle) ...[
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.orange[600],
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '热门板块',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // TODO: 导航到完整板块列表
                },
                child: Text(
                  '查看全部',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        _buildSectorsList(sectors),
      ],
    );
  }

  Widget _buildSectorsList(List<SectorData> sectors) {
    if (widget.scrollDirection == Axis.horizontal) {
      return SizedBox(
        height: 120,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: sectors.length,
          itemBuilder: (context, index) {
            return _buildSectorCard(sectors[index], index);
          },
        ),
      );
    } else {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.5,
        ),
        itemCount: sectors.length,
        itemBuilder: (context, index) {
          return _buildSectorCard(sectors[index], index);
        },
      );
    }
  }

  Widget _buildSectorCard(SectorData sector, int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + index * 100),
      curve: Curves.easeOut,
      margin: EdgeInsets.only(
        right: widget.scrollDirection == Axis.horizontal ? 12 : 0,
        bottom: widget.scrollDirection == Axis.vertical ? 0 : 0,
      ),
      child: AnimatedBuilder(
        animation: _bounceAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0,
            child: child,
          );
        },
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              HapticFeedback.lightImpact();
              _bounceController.forward().then((_) {
                _bounceController.reverse();
              });
              _showSectorDetails(sector);
            },
            child: Container(
              width: widget.scrollDirection == Axis.horizontal ? 140 : null,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getSectorColor(sector.name).withOpacity(0.1),
                    _getSectorColor(sector.name).withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _getSectorColor(sector.name).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  // 闪光效果
                  AnimatedBuilder(
                    animation: _shimmerAnimation,
                    builder: (context, child) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment(
                                  -1.0 + _shimmerAnimation.value, 0.0),
                              end: Alignment(_shimmerAnimation.value, 0.0),
                              colors: [
                                Colors.transparent,
                                Colors.white.withOpacity(0.2),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  // 内容
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color:
                                  _getSectorColor(sector.name).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              _getSectorIcon(sector.name),
                              color: _getSectorColor(sector.name),
                              size: 16,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: sector.changePercent >= 0
                                  ? Colors.green[600]
                                  : Colors.red[600],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${sector.changePercent >= 0 ? '+' : ''}${sector.changePercent.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        sector.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${sector.stockCount}只股票',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        sector.leaderStock,
                        style: TextStyle(
                          fontSize: 11,
                          color: _getSectorColor(sector.name),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<SectorData> _getHotSectors() {
    return [
      SectorData(
        name: '新能源汽车',
        changePercent: 3.2,
        stockCount: 45,
        leaderStock: '比亚迪',
        hotnessScore: 95,
      ),
      SectorData(
        name: '人工智能',
        changePercent: 2.8,
        stockCount: 38,
        leaderStock: '科大讯飞',
        hotnessScore: 92,
      ),
      SectorData(
        name: '半导体',
        changePercent: 1.5,
        stockCount: 67,
        leaderStock: '中芯国际',
        hotnessScore: 88,
      ),
      SectorData(
        name: '生物医药',
        changePercent: -0.8,
        stockCount: 52,
        leaderStock: '恒瑞医药',
        hotnessScore: 85,
      ),
      SectorData(
        name: '5G通信',
        changePercent: 1.2,
        stockCount: 31,
        leaderStock: '中兴通讯',
        hotnessScore: 82,
      ),
    ];
  }

  Color _getSectorColor(String sectorName) {
    final colors = {
      '新能源汽车': Colors.green,
      '人工智能': Colors.blue,
      '半导体': Colors.purple,
      '生物医药': Colors.red,
      '5G通信': Colors.orange,
      '光伏': Colors.yellow[700]!,
      '锂电池': Colors.cyan,
      '军工': Colors.indigo,
    };
    return colors[sectorName] ?? Colors.grey[600]!;
  }

  IconData _getSectorIcon(String sectorName) {
    final icons = {
      '新能源汽车': Icons.electric_car_rounded,
      '人工智能': Icons.psychology_rounded,
      '半导体': Icons.memory_rounded,
      '生物医药': Icons.healing_rounded,
      '5G通信': Icons.wifi_rounded,
      '光伏': Icons.solar_power_rounded,
      '锂电池': Icons.battery_charging_full_rounded,
      '军工': Icons.security_rounded,
    };
    return icons[sectorName] ?? Icons.trending_up_rounded;
  }

  void _showSectorDetails(SectorData sector) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSectorDetailsSheet(sector),
    );
  }

  Widget _buildSectorDetailsSheet(SectorData sector) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖拽指示器
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getSectorColor(sector.name).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getSectorIcon(sector.name),
                        color: _getSectorColor(sector.name),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sector.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          '今日涨跌幅 ${sector.changePercent >= 0 ? '+' : ''}${sector.changePercent.toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 14,
                            color: sector.changePercent >= 0
                                ? Colors.green[600]
                                : Colors.red[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard('股票数量', '${sector.stockCount}'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard('热度评分', '${sector.hotnessScore}'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  '领涨股票',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                _buildLeaderStocks(sector),
                const SizedBox(height: 20),
                const Text(
                  '相关基金推荐',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                _buildRelatedFunds(sector),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
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
      ),
    );
  }

  Widget _buildLeaderStocks(SectorData sector) {
    // 模拟领涨股票
    final stocks = [
      {'name': sector.leaderStock, 'change': '+5.2%'},
      {'name': '龙头股份B', 'change': '+4.8%'},
      {'name': '先锋股份C', 'change': '+4.1%'},
    ];

    return Column(
      children: stocks.map((stock) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Text(
                stock['name']!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  stock['change']!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRelatedFunds(SectorData sector) {
    // 模拟相关基金
    final funds = [
      '${sector.name}主题基金A',
      '${sector.name}精选混合B',
      '${sector.name}成长股票C',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: funds.map((fund) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _getSectorColor(sector.name).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _getSectorColor(sector.name).withOpacity(0.3),
            ),
          ),
          child: Text(
            fund,
            style: TextStyle(
              fontSize: 13,
              color: _getSectorColor(sector.name),
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class SectorData {
  final String name;
  final double changePercent;
  final int stockCount;
  final String leaderStock;
  final int hotnessScore;

  SectorData({
    required this.name,
    required this.changePercent,
    required this.stockCount,
    required this.leaderStock,
    required this.hotnessScore,
  });
}
