// 基金卡片组件库统一导出
//
// 这个文件提供了基金卡片组件库的统一访问入口。
// 所有基金相关的卡片组件都应该在这里导出，以简化导入语句。
//
// 使用方法：
// import 'package:your_app/src/features/fund/presentation/widgets/cards/fund_cards.dart';
//
// 然后就可以直接使用：AdaptiveFundCard, MicrointeractiveFundCard, FundCardFactory 等

import '../../../../../core/performance/performance_detector.dart';
import 'fund_card_factory.dart';

// 导出所有组件
export 'adaptive_fund_card.dart';
export 'base_fund_card.dart';
export 'fund_card_factory.dart';
export 'microinteractive_fund_card.dart';

// 为了向后兼容，重新导出旧组件（标记为废弃）
// @Deprecated('使用 FundCardFactory.createFundCard 替代')
// export '../fund_ranking_card.dart';
// @Deprecated('使用 FundCardFactory.createFundCard 替代')
// export '../enhanced_fund_ranking_card.dart';
// @Deprecated('使用 FundCardFactory.createFundCard 替代')
// export '../optimized_fund_ranking_card.dart';
// @Deprecated('使用 AdaptiveFundCard 替代')
// export '../unified_fund_card.dart';

// 组件库常量和配置
/// 基金卡片组件库管理类
///
/// 提供组件库的初始化、清理和配置管理功能。
/// 包含版本信息、性能检测器预热和缓存管理。
class FundCardsLibrary {
  /// 版本号
  static const String version = '1.0.0';

  /// 库初始化
  static Future<void> initialize() async {
    // 预热性能检测器
    final performanceDetector = SmartPerformanceDetector.instance;
    await performanceDetector.detectPerformance();

    // 预热工厂缓存
    FundCardFactory.warmupCache(popularFunds: []);
  }

  /// 库清理
  static void dispose() {
    FundCardFactory.clearCache();
  }
}
