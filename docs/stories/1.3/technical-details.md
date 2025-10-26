# Technical Details

### 组件结构
```
lib/src/features/fund/presentation/fund_exploration/presentation/widgets/
├── recommendation_system/
│   ├── recommendation_section.dart           # 推荐主区域
│   ├── recommendation_card.dart              # 推荐卡片
│   ├── performance_badge.dart                # 收益率徽章
│   ├── recommendation_filters.dart           # 推荐筛选
│   └── recommendation_loading.dart           # 加载状态
├── cubit/
│   ├── recommendation_cubit.dart              # 推荐状态管理
│   └── recommendation_state.dart             # 推荐状态定义
└── services/
    ├── recommendation_service.dart           # 推荐业务逻辑
    └── performance_calculator.dart           # 收益率计算
```

### 推荐算法 (MVP)
```dart
class RecommendationAlgorithm {
  // 基于收益率的推荐逻辑
  List<FundRecommendation> generateRecommendations(List<Fund> funds) {
    return funds
        .where((fund) => fund.return1Y > 0.05) // 1年收益率 > 5%
        .map((fund) => FundRecommendation(
              fund: fund,
              score: _calculateScore(fund),
              reason: _generateReason(fund),
            ))
        .toList()
        ..sort((a, b) => b.score.compareTo(a.score))
        .take(10) // 最多推荐10只
        .toList();
  }

  double _calculateScore(Fund fund) {
    return fund.return1Y * 0.6 +
           fund.return3Y * 0.3 +
           fund.returnYTD * 0.1;
  }
}
```

### API集成设计
```dart
// 新增推荐数据接口
class RecommendationApiService {
  Future<List<FundRecommendation>> getTopPerformers({
    required RecommendationPeriod period,
    required int limit,
  });

  Future<List<FundRecommendation>> getTrendingFunds({
    required TimeFrame timeFrame,
    required int limit,
  });
}
```

### 缓存策略
```dart
class RecommendationCache {
  static const Duration _cacheDuration = Duration(minutes: 30);

  Future<List<FundRecommendation>> getCachedRecommendations(
    String cacheKey
  ) async {
    final cached = await _cache.get(cacheKey);
    if (cached != null && !_isExpired(cached.timestamp)) {
      return cached.data;
    }
    return null;
  }
}
```
