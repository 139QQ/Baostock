import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// 今日行情概览组件
/// 展示A股市场今日行情数据，包括涨跌统计、分布图、热门榜等
class TodayMarketOverview extends StatefulWidget {
  const TodayMarketOverview({super.key});

  @override
  State<TodayMarketOverview> createState() => _TodayMarketOverviewState();
}

class _TodayMarketOverviewState extends State<TodayMarketOverview> {
  /// 基金数据（模拟）
  final List<Map<String, dynamic>> _fundData = [];

  /// 当前市场类型：'stock' 或 'fund'
  String _marketType = 'stock';

  /// 市场统计信息
  int _upCount = 0;
  int _downCount = 0;
  int _limitUpCount = 0;
  int _limitDownCount = 0;
  int _flatCount = 0;
  double _totalAmount = 0.0;
  final double _northBoundFlow = 0.0;

  /// 热门板块数据
  List<Map<String, dynamic>> _hotSectors = [];

  /// 数据更新时间
  String _updateTime = '';

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMarketData();
  }

  Future<void> _loadMarketData() async {
    try {
      // 并行加载股票历史数据和热门板块数据
      await Future.wait([
        _loadStockHistoryData(),
        _loadHotSectorsData(),
      ]);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadStockHistoryData() async {
    try {
      // 使用stock_market_activity_legu接口获取市场活跃度数据
      final stockResponse = await http.get(
        Uri.parse(
            'http://154.44.25.92:8080/api/public/stock_market_activity_legu'),
      );

      if (stockResponse.statusCode == 200) {
        final stockRaw = utf8.decode(stockResponse.bodyBytes);
        final responseData = json.decode(stockRaw);

        // 调试：打印原始响应数据
        debugPrint('=== stock_market_activity_legu 接口响应数据 ===');
        debugPrint('响应数据类型: ${responseData.runtimeType}');
        debugPrint('响应数据内容: $responseData');

        // 记录数据更新时间
        final updateTime = DateTime.now();
        final formattedTime =
            '${updateTime.hour.toString().padLeft(2, '0')}:${updateTime.minute.toString().padLeft(2, '0')}:${updateTime.second.toString().padLeft(2, '0')}';

        if (mounted) {
          setState(() {
            _updateTime = formattedTime;

            // 根据实际数据结构获取数据 - stock_market_activity_legu返回数组格式
            if (responseData is List && responseData.isNotEmpty) {
              // 将数组转换为Map，方便按键值获取
              final dataMap = <String, dynamic>{};
              for (final item in responseData) {
                if (item is Map &&
                    item.containsKey('item') &&
                    item.containsKey('value')) {
                  final key = item['item'].toString();
                  final value = item['value'];
                  dataMap[key] = value;
                }
              }

              debugPrint('转换后的数据Map: $dataMap');

              // 从转换后的Map中获取数据
              _upCount = (dataMap['上涨'] ?? 0).toInt();
              _downCount = (dataMap['下跌'] ?? 0).toInt();
              _limitUpCount = (dataMap['涨停'] ?? 0).toInt();
              _limitDownCount = (dataMap['跌停'] ?? 0).toInt();
              _flatCount = (dataMap['平盘'] ?? 0).toInt();

              // 成交额数据这个接口没有提供，设为0
              _totalAmount = 0.0;

              debugPrint(
                  '解析结果 - 上涨: $_upCount, 下跌: $_downCount, 涨停: $_limitUpCount, 跌停: $_limitDownCount, 平盘: $_flatCount');
            } else {
              debugPrint('未知的数据格式或空数据: ${responseData.runtimeType}');
            }

            _isLoading = false;
          });
        }
      } else {
        // 如果接口不可用，回退到市场指数数据
        debugPrint('stock_market_activity_legu接口不可用，使用市场指数数据作为回退');
        await _loadIndexDataAsFallback();
      }
    } catch (e) {
      debugPrint('stock_market_activity_legu接口数据加载失败，尝试回退方案: $e');
      if (mounted) {
        await _loadIndexDataAsFallback();
      }
    }
  }

  /// 回退方案：使用市场指数数据
  Future<void> _loadIndexDataAsFallback() async {
    try {
      final indexResponse = await http.get(
        Uri.parse(
            'http://154.44.25.92:8080/api/public/stock_market_activity_legu'),
      );

      if (indexResponse.statusCode == 200) {
        final indexRaw = utf8.decode(indexResponse.bodyBytes);
        final responseData = json.decode(indexRaw);

        // 调试：打印回退响应数据
        debugPrint('=== 回退方案响应数据 ===');
        debugPrint('回退数据类型: ${responseData.runtimeType}');
        debugPrint('回退数据内容: $responseData');

        // 记录数据更新时间
        final updateTime = DateTime.now();
        final formattedTime =
            '${updateTime.hour.toString().padLeft(2, '0')}:${updateTime.minute.toString().padLeft(2, '0')}:${updateTime.second.toString().padLeft(2, '0')}';

        if (mounted) {
          setState(() {
            _updateTime = formattedTime;

            // 根据实际数据结构获取数据 - stock_market_activity_legu返回数组格式
            if (responseData is List && responseData.isNotEmpty) {
              // 将数组转换为Map，方便按键值获取
              final dataMap = <String, dynamic>{};
              for (final item in responseData) {
                if (item is Map &&
                    item.containsKey('item') &&
                    item.containsKey('value')) {
                  final key = item['item'].toString();
                  final value = item['value'];
                  dataMap[key] = value;
                }
              }

              // 从转换后的Map中获取数据
              _upCount = (dataMap['上涨'] ?? 0).toInt();
              _downCount = (dataMap['下跌'] ?? 0).toInt();
              _limitUpCount = (dataMap['涨停'] ?? 0).toInt();
              _limitDownCount = (dataMap['跌停'] ?? 0).toInt();
              _flatCount = (dataMap['平盘'] ?? 0).toInt();

              // 成交额数据这个接口没有提供，设为0
              _totalAmount = 0.0;
            } else {
              debugPrint('回退方案 - 未知的数据格式或空数据: ${responseData.runtimeType}');
            }

            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('回退数据加载失败: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadHotSectorsData() async {
    try {
      // 获取热门板块数据
      final industryResponse = await http.get(
        Uri.parse(
            'http://154.44.25.92:8080/api/public/stock_board_industry_name_em'),
      );

      if (industryResponse.statusCode == 200) {
        final industryRaw = utf8.decode(industryResponse.bodyBytes);
        final industryData = json.decode(industryRaw) as List;

        // 处理前5个热门板块
        final hotSectors = <Map<String, dynamic>>[];
        for (int i = 0; i < 5 && i < industryData.length; i++) {
          final sector = industryData[i] as Map<String, dynamic>;
          final values = sector.values.toList();

          String name = values.length > 1 ? values[1].toString() : '';
          double changePercent =
              values.length > 5 ? _parseDouble(values[5]) : 0.0;

          hotSectors.add({
            'name': name,
            'changePercent': changePercent,
          });
        }

        if (mounted) {
          setState(() {
            _hotSectors = hotSectors;
          });
        }
      }
    } catch (e) {
      debugPrint('热门板块数据加载失败: $e');
    }
  }

  void _calculateMarketStats() {
    // stock_market_activity_legu接口已经返回统计好的数据，不需要再计算
    // 这个方法现在只是空实现，保留为了兼容现有代码结构
  }

  double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.toString()) ?? 0.0;
    }
    return 0.0;
  }

  void _toggleMarketType(String type) {
    setState(() {
      _marketType = type;
      // 重新计算统计数据
      _calculateMarketStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 今日行情标题和切换按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '今日行情',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                      fontFamily: 'Microsoft YaHei',
                    ),
                  ),
                  if (_updateTime.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Text(
                      '更新时间: $_updateTime',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF64748B).withOpacity(0.8),
                        fontFamily: 'Microsoft YaHei',
                      ),
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  _buildMarketTypeButton('股票', 'stock'),
                  const SizedBox(width: 8),
                  _buildMarketTypeButton('基金', 'fund'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 市场统计卡片（5张）
          _buildMarketStatsCards(),
          const SizedBox(height: 16),

          // 涨跌分布和热门榜
          _buildMarketDistributionAndHotList(),
          const SizedBox(height: 16),

          // 市场总览条带
          _buildMarketOverviewBar(),
        ],
      ),
    );
  }

  Widget _buildMarketTypeButton(String label, String type) {
    final bool isActive = _marketType == type;
    return TextButton(
      onPressed: () => _toggleMarketType(type),
      style: TextButton.styleFrom(
        backgroundColor:
            isActive ? const Color(0xFF2563EB) : const Color(0xFFF8FAFC),
        foregroundColor: isActive ? Colors.white : const Color(0xFF64748B),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isActive ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          fontFamily: 'Microsoft YaHei',
        ),
      ),
      child: Text(label),
    );
  }

  Widget _buildMarketStatsCards() {
    final total = _upCount + _downCount + _flatCount;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildMarketStatCard('上涨', _upCount, const Color(0xFFFFEBEE),
            const Color(0xFFDC2626), Icons.trending_up, total),
        _buildMarketStatCard('下跌', _downCount, const Color(0xFFE8F5E8),
            const Color(0xFF16A34A), Icons.trending_down, total),
        _buildMarketStatCard('涨停', _limitUpCount, const Color(0xFFFFF3E0),
            const Color(0xFFFF9800), Icons.arrow_upward, total),
        _buildMarketStatCard('跌停', _limitDownCount, const Color(0xFFE0F2F1),
            const Color(0xFF00695C), Icons.arrow_downward, total),
        _buildMarketStatCard('平盘', _flatCount, const Color(0xFFF5F5F5),
            const Color(0xFF6B7280), Icons.remove, total),
      ],
    );
  }

  Widget _buildMarketStatCard(String label, int count, Color bgColor,
      Color textColor, IconData icon, int total) {
    final percentage =
        total > 0 ? (count / total * 100).toStringAsFixed(1) : '0.0';

    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: GestureDetector(
            onTap: () {
              // 点击卡片可以展开详细信息
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: 120,
              padding: const EdgeInsets.all(12),
              transform: isHovered
                  ? (Matrix4.identity()..scale(1.02))
                  : Matrix4.identity(),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isHovered
                      ? const Color(0xFF2563EB).withOpacity(0.3)
                      : const Color(0xFFE2E8F0),
                  width: 1,
                ),
                boxShadow: isHovered
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: textColor, size: 20),
                  const SizedBox(height: 4),
                  Text('$label：$count只'),
                  const SizedBox(height: 2),
                  Text(
                    '($percentage%)',
                    style: TextStyle(
                      fontSize: 11,
                      color: textColor.withOpacity(0.8),
                      fontFamily: 'Microsoft YaHei',
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建市场分布和热门榜 - 响应式布局
  Widget _buildMarketDistributionAndHotList() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 根据可用宽度决定布局方式
        if (constraints.maxWidth < 600) {
          // 移动端：垂直堆叠，更紧凑的布局
          return Column(
            children: [
              // 涨跌分布 - 移动端优化
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '涨跌家数分布',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                            fontFamily: 'Microsoft YaHei',
                          ),
                        ),
                        Text(
                          '更新时间: $_updateTime',
                          style: TextStyle(
                            fontSize: 11,
                            color: const Color(0xFF64748B).withOpacity(0.8),
                            fontFamily: 'Microsoft YaHei',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildDistributionBar(),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMobileDistributionItem(
                            '上涨', _upCount, const Color(0xFFDC2626)),
                        _buildMobileDistributionItem(
                            '下跌', _downCount, const Color(0xFF16A34A)),
                        _buildMobileDistributionItem(
                            '平盘', _flatCount, const Color(0xFF6B7280)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // 热门榜 - 移动端优化
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _marketType == 'stock' ? '热门领涨榜' : '基金领涨榜',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                            fontFamily: 'Microsoft YaHei',
                          ),
                        ),
                        IconButton(
                          onPressed: _loadHotSectorsData,
                          icon: const Icon(Icons.refresh, size: 18),
                          color: const Color(0xFF64748B),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 220, // 移动端固定高度 - 增加20像素避免溢出
                      child: _buildHotList(),
                    ),
                  ],
                ),
              ),
            ],
          );
        } else {
          // 桌面端：水平并排（优化版）
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 左侧60%：涨跌分布条形图
              Expanded(
                flex: 6,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '涨跌家数分布',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                              fontFamily: 'Microsoft YaHei',
                            ),
                          ),
                          Text(
                            '更新时间: $_updateTime',
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFF64748B).withOpacity(0.8),
                              fontFamily: 'Microsoft YaHei',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDistributionBar(),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildDistributionItem(
                              '上涨', _upCount, const Color(0xFFDC2626)),
                          _buildDistributionItem(
                              '下跌', _downCount, const Color(0xFF16A34A)),
                          _buildDistributionItem(
                              '平盘', _flatCount, const Color(0xFF6B7280)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // 右侧40%：热门领涨榜
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _marketType == 'stock' ? '热门领涨榜' : '基金领涨榜',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                              fontFamily: 'Microsoft YaHei',
                            ),
                          ),
                          IconButton(
                            onPressed: _loadHotSectorsData,
                            icon: const Icon(Icons.refresh, size: 20),
                            color: const Color(0xFF64748B),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: _getHotListHeight(),
                        child: _buildHotList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildDistributionBar() {
    final total = _upCount + _downCount + _flatCount;
    if (total == 0) return const SizedBox.shrink();

    final upPercent = _upCount / total;
    final downPercent = _downCount / total;
    final flatPercent = _flatCount / total;

    return Container(
      height: 20,
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            flex: (upPercent * 100).round(),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFDC2626),
                borderRadius:
                    BorderRadius.horizontal(left: Radius.circular(10)),
              ),
            ),
          ),
          Expanded(
            flex: (flatPercent * 100).round(),
            child: Container(
              color: const Color(0xFF9E9E9E),
            ),
          ),
          Expanded(
            flex: (downPercent * 100).round(),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF16A34A),
                borderRadius:
                    BorderRadius.horizontal(right: Radius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.withOpacity(0.8),
            fontFamily: 'Microsoft YaHei',
          ),
        ),
      ],
    );
  }

  /// 获取热门列表高度
  double _getHotListHeight() {
    // 根据热门板块数据数量计算高度，每项约34像素（优化后的紧凑高度）
    const itemHeight = 34.0; // 优化后的更紧凑高度
    final itemCount = _hotSectors.take(5).length; // 只计算前5项
    final calculatedHeight =
        (itemCount * itemHeight + 16).toDouble(); // +16给间距留余量
    return calculatedHeight;
  }

  /// 移动端专用的分布项组件 - 更紧凑的布局
  Widget _buildMobileDistributionItem(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.8),
              fontFamily: 'Microsoft YaHei',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotList() {
    final data = _marketType == 'stock' ? _hotSectors : _fundData;
    final items = data.take(5).toList();

    return ListView.builder(
      itemCount: items.length,
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildHotItem(
            item['name'] ?? '', _parseDouble(item['changePercent']));
      },
    );
  }

  Widget _buildHotItem(String name, double changePercent) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 400; // 根据宽度判断是否为移动端

        return Container(
          margin: const EdgeInsets.only(bottom: 6), // 减少底部间距
          padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 10 : 12,
              vertical: isMobile ? 4 : 6 // 减少垂直内边距
              ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 13,
                    color: const Color(0xFF1E293B),
                    fontFamily: 'Microsoft YaHei',
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 6 : 8,
                    vertical: isMobile ? 2 : 3 // 减少垂直内边距
                    ),
                decoration: BoxDecoration(
                  color: changePercent >= 0
                      ? const Color(0xFFDC2626).withOpacity(0.1)
                      : const Color(0xFF16A34A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 12, // 稍微减小字体
                    fontWeight: FontWeight.w600,
                    color: changePercent >= 0
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMarketOverviewBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2563EB).withOpacity(0.05),
            const Color(0xFF2563EB).withOpacity(0.02),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF2563EB).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildOverviewItem(
              '市场总成交额', '${(_totalAmount / 100000000).toStringAsFixed(1)}亿'),
          _buildOverviewItem(
              '北向资金',
              _northBoundFlow >= 0
                  ? '+${_northBoundFlow.toStringAsFixed(1)}亿'
                  : '${_northBoundFlow.toStringAsFixed(1)}亿'),
          _buildOverviewItem('市场类型', _marketType == 'stock' ? 'A股市场' : '基金市场'),
        ],
      ),
    );
  }

  Widget _buildOverviewItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2563EB),
            fontFamily: 'Microsoft YaHei',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: const Color(0xFF64748B).withOpacity(0.8),
            fontFamily: 'Microsoft YaHei',
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(height: 12),
            Text(
              '正在加载行情数据...',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                fontFamily: 'Microsoft YaHei',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
