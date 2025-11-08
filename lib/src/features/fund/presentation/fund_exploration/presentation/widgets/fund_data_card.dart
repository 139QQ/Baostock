import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../features/fund/domain/entities/fund.dart';

/// 基金数据卡片 - 符合卡片式现代设计的核心组件
/// 支持三种显示模式：标准、紧凑、详细
/// 基于Fluent Design System + Modern Light主题
class FundDataCard extends StatelessWidget {
  final Fund fund;
  final FundCardMode mode;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onCompare;
  final bool isFavorite;
  final bool isComparing;
  final bool showPerformanceMetrics;
  final EdgeInsets? margin;

  const FundDataCard({
    Key? key,
    required this.fund,
    this.mode = FundCardMode.standard,
    this.onTap,
    this.onFavorite,
    this.onCompare,
    this.isFavorite = false,
    this.isComparing = false,
    this.showPerformanceMetrics = true,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.all(8),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        shadowColor: Colors.black.withOpacity(0.08),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: _getPadding(),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isComparing
                    ? const Color(0xFF007bff).withOpacity(0.5)
                    : Colors.grey.withOpacity(0.2),
                width: isComparing ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                _buildCoreMetrics(),
                if (showPerformanceMetrics && mode != FundCardMode.compact) ...[
                  const SizedBox(height: 12),
                  _buildPerformanceMetrics(),
                ],
                if (mode == FundCardMode.detailed) ...[
                  const SizedBox(height: 12),
                  _buildDetailedInfo(),
                ],
                const SizedBox(height: 12),
                _buildActions(),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
      ),
    );
  }

  EdgeInsets _getPadding() {
    switch (mode) {
      case FundCardMode.compact:
        return const EdgeInsets.all(12);
      case FundCardMode.standard:
        return const EdgeInsets.all(16);
      case FundCardMode.detailed:
        return const EdgeInsets.all(20);
    }
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fund.name,
                style: GoogleFonts.inter(
                  fontSize: mode == FundCardMode.compact ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1a1a1a),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                fund.code,
                style: GoogleFonts.inter(
                  fontSize: mode == FundCardMode.compact ? 12 : 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF666666),
                ),
              ),
            ],
          ),
        ),
        if (mode != FundCardMode.compact) ...[
          RiskLevelBadge(riskLevel: fund.riskLevel),
        ] else ...[
          _buildCompactRiskIndicator(),
        ],
      ],
    );
  }

  Widget _buildCompactRiskIndicator() {
    final colors = {
      '低': Colors.green,
      '中低': Colors.lightGreen,
      '中': Colors.orange,
      '中高': Colors.deepOrange,
      '高': Colors.red,
    };

    final color = colors[fund.riskLevel] ?? Colors.grey;

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildCoreMetrics() {
    return Row(
      children: [
        Expanded(
          child: _buildMetric(
            '最新净值',
            fund.unitNav.toStringAsFixed(4),
            showTrend: false,
          ),
        ),
        if (mode != FundCardMode.compact) ...[
          Expanded(
            child: _buildMetric(
              '日涨跌幅',
              '${fund.dailyReturn >= 0 ? '+' : ''}${fund.dailyReturn.toStringAsFixed(2)}%',
              isPositive: fund.dailyReturn >= 0,
              showTrend: true,
            ),
          ),
        ],
        Expanded(
          child: _buildMetric(
            mode == FundCardMode.compact ? '日收益' : '累计收益',
            '${fund.returnSinceInception >= 0 ? '+' : ''}${fund.returnSinceInception.toStringAsFixed(2)}%',
            isPositive: fund.returnSinceInception >= 0,
            showTrend: mode != FundCardMode.compact,
          ),
        ),
      ],
    );
  }

  Widget _buildMetric(
    String label,
    String value, {
    bool isPositive = true,
    bool showTrend = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: const Color(0xFF666666),
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: mode == FundCardMode.compact ? 13 : 15,
                fontWeight: FontWeight.w600,
                color: isPositive
                    ? const Color(0xFF00a86b)
                    : const Color(0xFFd32f2f),
              ),
            ),
            if (showTrend) ...[
              const SizedBox(width: 2),
              Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                size: 14,
                color: isPositive
                    ? const Color(0xFF00a86b)
                    : const Color(0xFFd32f2f),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildPerformanceMetrics() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFf8f9fa),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildPerformanceRow('近1周', '${fund.return1W.toStringAsFixed(2)}%'),
          const SizedBox(height: 6),
          _buildPerformanceRow('近1月', '${fund.return1M.toStringAsFixed(2)}%'),
          const SizedBox(height: 6),
          _buildPerformanceRow('近3月', '${fund.return3M.toStringAsFixed(2)}%'),
          if (mode == FundCardMode.detailed) ...[
            const SizedBox(height: 6),
            _buildPerformanceRow('近1年', '${fund.return1Y.toStringAsFixed(2)}%'),
          ],
        ],
      ),
    );
  }

  Widget _buildPerformanceRow(String period, String returnPercent) {
    final isPositive =
        returnPercent.startsWith('+') || !returnPercent.startsWith('-');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          period,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF666666),
          ),
        ),
        Text(
          returnPercent,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color:
                isPositive ? const Color(0xFF00a86b) : const Color(0xFFd32f2f),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedInfo() {
    return Column(
      children: [
        _buildDetailRow('基金规模', '${fund.scale.toStringAsFixed(2)}亿元'),
        _buildDetailRow('更新日期', fund.date),
        _buildDetailRow('基金经理', fund.manager),
        _buildDetailRow('基金类型', fund.type),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF666666),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1a1a1a),
              ),
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: isFavorite ? Icons.favorite : Icons.favorite_border,
            label: '收藏',
            onTap: onFavorite,
            isActive: isFavorite,
            isPrimary: false,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: isComparing ? Icons.compare_arrows : Icons.add_chart,
            label: isComparing ? '移除对比' : '加入对比',
            onTap: onCompare,
            isActive: isComparing,
            isPrimary: true,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required bool isActive,
    required bool isPrimary,
  }) {
    return Material(
      color: isActive
          ? (isPrimary ? const Color(0xFF007bff) : const Color(0xFFe3f2fd))
          : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive
                    ? (isPrimary ? Colors.white : const Color(0xFF007bff))
                    : const Color(0xFF666666),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isActive
                      ? (isPrimary ? Colors.white : const Color(0xFF007bff))
                      : const Color(0xFF666666),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 风险等级标签组件
class RiskLevelBadge extends StatelessWidget {
  final String riskLevel;

  const RiskLevelBadge({Key? key, required this.riskLevel}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final config = _getRiskConfig(riskLevel);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [config.color.withOpacity(0.8), config.color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        riskLevel,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  _RiskConfig _getRiskConfig(String level) {
    switch (level) {
      case '低':
        return _RiskConfig(Colors.green, '低风险');
      case '中低':
        return _RiskConfig(Colors.lightGreen, '中低风险');
      case '中':
        return _RiskConfig(Colors.orange, '中风险');
      case '中高':
        return _RiskConfig(Colors.deepOrange, '中高风险');
      case '高':
        return _RiskConfig(Colors.red, '高风险');
      default:
        return _RiskConfig(Colors.grey, '未知风险');
    }
  }
}

class _RiskConfig {
  final Color color;
  final String description;

  _RiskConfig(this.color, this.description);
}

/// 基金卡片显示模式
enum FundCardMode {
  compact, // 紧凑模式 - 用于列表展示
  standard, // 标准模式 - 默认展示
  detailed, // 详细模式 - 展示完整信息
}
