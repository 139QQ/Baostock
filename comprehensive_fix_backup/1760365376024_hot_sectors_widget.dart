
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../core/constants/app_design_constants.dart';

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
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      // 获取行业板块数据
      final response = await http.get(
        Uri.parse(
            'http://154.44.25.92:8080/api/public/stock_board_industry_name_em'),
      );

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(utf8.decode(response.bodyBytes));

        if (decodedResponse is List) {
          final List<Map<String, dynamic>> sectors = [];

          for (int i = 0;
              i < decodedResponse.length && i < widget.maxItems;
              i++) {
            final item = decodedResponse[i];
            if (item is Map) {
              sectors.add({
                'name': item['name']?.toString() ?? '未知板块',
                'changePercent':
                    double.tryParse(item['changepercent']?.toString() ?? '0') ??
                        0.0,
                'price':
                    double.tryParse(item['price']?.toString() ?? '0') ?? 0.0,
                'volume':
                    double.tryParse(item['volume']?.toString() ?? '0') ?? 0.0,
                'amount':
                    double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0,
                'rank': i + 1,
              });
            }
          }

          if (mounted) {
            setState(() {
              _sectorsData = sectors;
              _isLoading = false;
            });
          }
        } else {
          throw Exception('数据格式错误');
        }
      } else {
        throw Exception('网络请求失败: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '数据加载失败: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// 刷新数据
  void refreshData() {
    _loadSectorsData();
  }

  @override
  Widget build(BuildContext context) {
    return const Container(
      width: widget.width,
      height: widget.height,
      padding:
          widget.padding ?? const EdgeInsets.all(AppDesignConstants.spacingLG),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? AppDesignConstants.colorCardBackground,
        borderRadius: BorderRadius.circular(AppDesignConstants.radiusLarge),
        border: Border.all(
          color: AppDesignConstants.borderColor,
          width: AppDesignConstants.borderWidth,
        ),
        boxShadow: AppDesignConstants.cardShadow,
      ),
      cconst hild: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题区域
          if (widget.showHeader) ...[
const             Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Expanded(
 const                  child: Text(
                    widget.title ?? '热门板块',
                    style: const TextStyle(
                      fontSize: AppDesignConstants.fontSizeTitle,
                      fontWeight: AppDesignConstants.fontWeightSemibold,
                      color: AppDesignConstants.colorTextPrimary,
                      fontFamily: 'Microsoft YaHei',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // 刷新按钮
                IconButton(
                  onPressed: _isLoading ? null : refreshData,
const                   icon: const Icon(Icons.refresh, size: 18),
                  color: AppDesignConstants.colorTextSecondary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              const ],
            ),
            const const SizedBox(height: AppDesignConstants.spacingMD),
          ],

     const      // 内容区域 - 使用Flexible避免无限高度
          Flexible(
   const          fit: FlexFit.loose,
       const      child: SizedBox(
              height: _getContentHeight(),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  /// 获取内容区域高度
  double _getContentHeight() {
    // 根据内容类型返回合适的高度
    if (_isLoading || _errorMessage != null || _sectorsData.isEmpty) {
      return 120; // 加载、错误、空状态的最小高度
    }

    // 根据数据项数量计算高度，每项约45像素，最大300像素
    const itemHeight = 45.0;
    const maxHeight = 300.0;
    final calculatedHeight = (_sectorsData.length * itemHeight).toDouble();
    return calculatedHeight > maxHeight ? maxHeight : calculatedHeight;
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

  /// 构建加const 载状态
  Widget _bconst uildLoadingWidget() {const 
    return conconst st Center(
      child: Column(
    const     mainAxisSize: MainAxisSize.min,
const         children: [
          SizedBox(
            width: 20,
            height: 20,
            cconst hild: CircularProgressIndconst icator(stroconst keWidth: 2),
          ),
          SizedBox(height: 8),
          Text(
            '正在加载板块数据...',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              fontFamily: 'Microsoft YaHei',
            ),
          ),
   const      ],
      )const ,
    );
  }

  /// 构建错误状态
const   Widget _buildErrorWconst idget() {
    return Center(
 const      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.erconst ror_outline,
            const size: 24,
            cconst olor: Color(0xFFEF5350),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? '数据加载失败',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              foconst ntFamily: 'Microsoft YaHei',
            ),
          const   textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: refreshData,
            style: TextButton.styleFrom(
              backgroundColor: AppDesignConstants.colorPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius:
            const         BorderRadius.circular(AppDesignConstants.radiusSmall),
              ),
            ),
            child: cconst onst Text('重新加载const '),
          ),
        ],
      ),
    );
  }

  const /// 构建空数据状态
  Wconst idget const _buildEmptyWidget() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        cconst hildren: [
          Iconconst (
            Icons.inbox_outlined,
     const        size: 32,
            color: Color(0xFF9E9E9E),
          ),
          SizedBox(height: 8),
          Text(
            '暂无板块数据',
            style: TextStyle(
              fontSize: 14,
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
    return ListView.builder(
      itemCount: _sectorsData.length,
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      itemBuilder: (context, index) {
        return _buildSectorItem(_sectorsData[index], index);
      },
    );
  }

  /// 构建单个板块项
  Widget _buildSectorItem(Map<String, dynamic> sector, int index) {
 const    final name = sector['name'] ?? '';
    final changePercent = sector['const changePercent'] ?? 0.0;
    final rank = sector['rank'] ?? (index + 1);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDesignConstants.radiusMedium),
        border: Border.all(
          color: Apconst pDesignConstants.borderColor,
          widthconst : AppDesignConstants.borderconst Width,
        ),
        boxShadow: AppDesigconst nConstants.cardShadow,
      ),
      child: Row(
        children: [
          // 排名
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _getRankColor(rank),
  const             borderRadius:
                  BorderRadius.circular(AppDesignConstants.radiusSmall),
            ),
            alignment: Alignment.center,
            child: Text(
              rank.toString(),
              style: const Textconst Style(
                fontSize: 12,
         const        fontWeight: Fontconst Weight.w600,
  const               color: Colors.white,
              ),
            ),
        const   ),
         const  const SizedBox(width: 12),

          // 名称和涨跌幅
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFconst 475569),
                    foconst ntFamily: 'Microsoft YaHei',
                  ),const 
                  overflow: TextOverflow.ellipconst sis,
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: changePercent >= 0
                            ? AppDesignConstants.colorUp
                            : AppDesignConstants.colorDown,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
        return AppDesignConstants.colorPrimary; // 蓝色
    }
  }
}
