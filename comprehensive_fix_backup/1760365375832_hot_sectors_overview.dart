import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// 热门板块组件
/// 独立展示热门板块数据的组件，支持自定义样式和交互
class HotSectorsWidget extends StatefulWidget {
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final int maxItems;
  final bool showHeader;
  final String? title;

  const HotSectorsWidget({
    super.key,
    this.width,
    this.height,
    this.padding,
    this.backgroundColor,
    this.maxItems = 10,
    this.showHeader = true,
    this.title,
  });

  @override
  State<HotSectorsWidget> createState() => _HotSectorsWidgetState();
}

class _HotSectorsWidgetState extends State<HotSectorsWidget> {
  /// 热门板块数据
  List<Map<String, dynamic>> _sectorsData = [];

  /// 加载状态
  bool _isLoading = true;

  /// 错误信息
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSectorsData();
  }

  /// 加载热门板块数据
  Future<void> _loadSectorsData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // 获取板块数据
      final response = await http.get(
        Uri.parse(
            'http://154.44.25.92:8080/api/public/stock_board_industry_name_em'),
      );

      if (response.statusCode == 200) {
        final rawData = utf8.decode(response.bodyBytes);
        final data = json.decode(rawData) as List;

        // 处理板块数据
        final sectors = <Map<String, dynamic>>[];
        for (int i = 0; i < data.length && i < widget.maxItems; i++) {
          final sector = data[i] as Map<String, dynamic>;
          final values = sector.values.toList();

          if (values.length >= 6) {
            String name = values[1].toString();
            double changePercent = _parseDouble(values[5]);
            double price = _parseDouble(values[2]);
            double volume = _parseDouble(values[4]);

            sectors.add({
              'name': name,
              'changePercent': changePercent,
              'price': price,
              'volume': volume,
              'rank': i + 1,
            });
          }
        }

        setState(() {
          _sectorsData = sectors;
          _isLoading = false;
        });
      } else {
        throw Exception('API返回错误状态码: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = '数据加载失败: $e';
        _isLoading = false;
      });
      debugPrint('热门板块数据加载失败: $e');
    }
  }

  /// 刷新数据
  Future<void> refreshData() async {
    await _loadSectorsData();
  }

  /// 解析数字
  double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.toString()) ?? 0.0;
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    // 使用容器包装，支持自定义尺寸和样式
    return Container(
      width: widget.width,
      height: widget.height ?? 400, // 默认高度400
      padding: widget.padding ?? EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 头部标题（可选）
          if (widget.showHeader) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      widget.title ?? '热门板块',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                        fontFamily: 'Microsoft YaHei',
                      ),
                    ),
                  ],
                ),
                // 刷新按钮
                IconButton(
                  onPressed: _isLoading ? null : refreshData,
                  icon: Icon(Icons.refresh, size: 18),
                  color: Color(0xFF64748B),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
            ),
            SizedBox(height: 12),
          ],

          // 内容区域 - 使用Flexible避免无限高度问题
          Flexible(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  /// 构建内容区域
  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_errorMessage != null) {
      return _buildErrorWidget();
    }

    if (_sectorsData.isEmpty) {
      return _buildEmptyWidget();
    }

    return _buildSectorsList();
  }

  /// 构建加载状态
  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(height: 8),
          Text(
            '正在加载板块数据...',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontFamily: 'Microsoft YaHei',
            ),
          ),
        ],
      ),
    );
  }

  /// 构建错误状态
  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            size: 24,
            color: Color(0xFFEF5350),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? '数据加载失败',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontFamily: 'Microsoft YaHei',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: refreshData,
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text('重新加载'),
          ),
        ],
      ),
    );
  }

  /// 构建空数据状态
  Widget _buildEmptyWidget() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 24,
            color: Color(0xFF9E9E9E),
          ),
          SizedBox(height: 8),
          Text(
            '暂无板块数据',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontFamily: 'Microsoft YaHei',
            ),
          ),
        ],
      ),
    );
  }

  /// 构建板块列表
  Widget _buildSectorsList() {
    return ListView.separated(
      itemCount: _sectorsData.length,
      separatorBuilder: (context, index) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final sector = _sectorsData[index];
        return _buildSectorItem(sector, index);
      },
    );
  }

  /// 构建单个板块项
  Widget _buildSectorItem(Map<String, dynamic> sector, int index) {
    final name = sector['name'] ?? '';
    final changePercent = sector['changePercent'] ?? 0.0;
    final price = sector['price'] ?? 0.0;
    final rank = sector['rank'] ?? (index + 1);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          // 点击事件 - 可以展开详细信息或导航到详情页
          _showSectorDetails(sector);
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Color(0xFFE0E0E0),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // 排名
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _getRankColor(rank),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  rank.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 12),

              // 名称和涨跌幅
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1E293B),
                        fontFamily: 'Microsoft YaHei',
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    SizedBox(height: 2),
                    Text(
                      '价格: ${price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B).withOpacity(0.8),
                        fontFamily: 'Microsoft YaHei',
                      ),
                    ),
                  ],
                ),
              ),

              // 涨跌幅
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: changePercent >= 0
                          ? Color(0xFFEF5350)
                          : Color(0xFF4CAF50),
                    ),
                  ),
                  SizedBox(height: 2),
                  Icon(
                    changePercent >= 0
                        ? Icons.trending_up
                        : Icons.trending_down,
                    size: 14,
                    color: changePercent >= 0
                        ? Color(0xFFEF5350)
                        : Color(0xFF4CAF50),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 获取排名颜色
  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFF9800); // 金色
      case 2:
        return const Color(0xFF9E9E9E); // 银色
      case 3:
        return const Color(0xFF795548); // 铜色
      default:
        return const Color(0xFF2563EB); // 蓝色
    }
  }

  /// 显示板块详情
  void _showSectorDetails(Map<String, dynamic> sector) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            sector['name'] ?? '板块详情',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Microsoft YaHei',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('涨跌幅',
                  '${sector['changePercent']?.toStringAsFixed(2) ?? '0.00'}%'),
              const SizedBox(height: 8),
              _buildDetailRow(
                  '价格', sector['price']?.toStringAsFixed(2) ?? '0.00'),
              const SizedBox(height: 8),
              _buildDetailRow('成交量',
                  '${(sector['volume'] / 100000000).toStringAsFixed(1)}亿'),
              const SizedBox(height: 8),
              _buildDetailRow('排名', '#${sector['rank']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  /// 构建详情行
  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
            fontFamily: 'Microsoft YaHei',
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1E293B),
            fontFamily: 'Microsoft YaHei',
          ),
        ),
      ],
    );
  }
}
