import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/portfolio_holding.dart';
import '../../domain/entities/portfolio_profit_metrics.dart';
import '../../domain/entities/portfolio_summary.dart';
import '../../domain/entities/fund_corporate_action.dart';
import '../../domain/entities/fund_split_detail.dart';
import '../../domain/repositories/portfolio_profit_repository.dart';
// 适配器已在 injection_container.dart 中统一注册
import '../../../../core/utils/logger.dart';

/// 组合收益缓存服务
///
/// 提供高性能的数据缓存功能，支持多层缓存策略
class PortfolioProfitCacheService {
  static const String _holdingsBoxName = 'portfolio_holdings_cache';
  static const String _navHistoryBoxName = 'nav_history_cache';
  static const String _benchmarkHistoryBoxName = 'benchmark_history_cache';
  static const String _dividendHistoryBoxName = 'dividend_history_cache';
  static const String _splitHistoryBoxName = 'split_history_cache';
  static const String _profitMetricsBoxName = 'profit_metrics_cache';
  static const String _portfolioSummaryBoxName = 'portfolio_summary_cache';

  PortfolioProfitCacheService();

  /// 初始化缓存服务
  Future<void> initialize() async {
    try {
      // 适配器已在 injection_container.dart 中统一注册，这里不再重复注册

      // 强制清理可能损坏的缓存文件（由于typeId冲突修复）
      await _forceClearCorruptedCache();

      // 检查是否有严重的适配器错误，如果有则完全清理缓存
      await _checkAndClearCorruptedCache();

      // 尝试打开缓存盒子，如果遇到适配器错误则清理缓存
      await _openBoxWithErrorHandling(_holdingsBoxName);
      await _openBoxWithErrorHandling(_navHistoryBoxName);
      await _openBoxWithErrorHandling(_benchmarkHistoryBoxName);
      await _openBoxWithErrorHandling(_dividendHistoryBoxName);
      await _openBoxWithErrorHandling(_splitHistoryBoxName);
      // 暂时注释掉复杂类型的缓存，避免适配器问题
      // await Hive.openBox(_profitMetricsBoxName);
      // await Hive.openBox(_portfolioSummaryBoxName);

      AppLogger.info('Portfolio profit cache service initialized');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize cache service', e, stackTrace);
      rethrow;
    }
  }

  /// 强制清理损坏的缓存文件（用于适配器冲突修复后）
  Future<void> _forceClearCorruptedCache() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final hiveDir = '${appDir.path}${Platform.pathSeparator}hive';
      final directory = Directory(hiveDir);

      if (await directory.exists()) {
        AppLogger.info('强制清理可能损坏的缓存文件...');

        // 删除所有 .hive 和 .lock 文件
        await for (final entity in directory.list()) {
          if (entity is File &&
              (entity.path.endsWith('.hive') ||
                  entity.path.endsWith('.lock'))) {
            try {
              await entity.delete();
              AppLogger.info('删除缓存文件: ${entity.path}');
            } catch (e) {
              AppLogger.warn('删除缓存文件失败: ${entity.path}, 错误: $e');
            }
          }
        }

        AppLogger.info('缓存文件强制清理完成');
      }
    } catch (e) {
      AppLogger.warn('强制清理缓存文件失败: $e');
    }
  }

  /// 检查并清理损坏的缓存
  Future<void> _checkAndClearCorruptedCache() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final hiveDir = '${appDir.path}${Platform.pathSeparator}hive';

      // 检查Hive目录是否存在
      final directory = Directory(hiveDir);
      if (!await directory.exists()) {
        return;
      }

      // 检查是否有老的或损坏的缓存文件
      bool hasCorruptedFiles = false;
      await for (final entity in directory.list()) {
        if (entity is File && entity.path.endsWith('.hive')) {
          try {
            // 尝试读取文件头部来判断是否损坏
            final file = File(entity.path);
            final bytes = await file.readAsBytes();
            if (bytes.isNotEmpty && bytes.length > 10) {
              // 简单检查：如果文件很大但数据很少，可能有问题
              if (bytes.length > 100000) {
                // 100KB
                hasCorruptedFiles = true;
                AppLogger.warn('检测到可能损坏的大缓存文件: ${entity.path}');
                break;
              }
            }
          } catch (e) {
            hasCorruptedFiles = true;
            AppLogger.warn('缓存文件读取失败，可能损坏: ${entity.path}, 错误: $e');
            break;
          }
        }
      }

      // 如果有损坏的文件，完全清理Hive目录
      if (hasCorruptedFiles) {
        AppLogger.warn('检测到损坏的缓存文件，正在完全清理Hive缓存');
        await _clearEntireHiveCache(hiveDir);
        // 等待文件系统操作完成
        await Future.delayed(const Duration(milliseconds: 200));
      }
    } catch (e) {
      AppLogger.warn('检查缓存状态失败: $e');
    }
  }

  /// 完全清理Hive缓存目录
  Future<void> _clearEntireHiveCache(String hiveDir) async {
    try {
      final directory = Directory(hiveDir);
      if (await directory.exists()) {
        await directory.delete(recursive: true);
        AppLogger.info('已完全删除Hive缓存目录: $hiveDir');
      }
    } catch (e) {
      AppLogger.warn('清理Hive缓存目录失败: $e');
    }
  }

  /// 安全打开Hive盒子，处理适配器错误
  Future<void> _openBoxWithErrorHandling(String boxName) async {
    try {
      await Hive.openBox(boxName);
    } catch (e) {
      if (e.toString().contains('unknown typeId') ||
          e.toString().contains('adapter')) {
        AppLogger.warn('检测到适配器错误，正在清理缓存盒子: $boxName');
        await _clearCorruptedBox(boxName);

        // 等待一小段时间确保文件完全删除
        await Future.delayed(const Duration(milliseconds: 100));

        try {
          // 再次尝试打开
          await Hive.openBox(boxName);
          AppLogger.info('缓存盒子已清理并重新打开: $boxName');
        } catch (e2) {
          AppLogger.error('清理后仍无法打开盒子，将跳过: $boxName', e2);
          // 不重新抛出错误，跳过这个盒子
        }
      } else {
        rethrow;
      }
    }
  }

  /// 清理损坏的缓存盒子
  Future<void> _clearCorruptedBox(String boxName) async {
    try {
      // 尝试删除损坏的缓存文件
      final appDir = await getApplicationDocumentsDirectory();
      // 使用 path 包确保跨平台兼容性
      final hiveDir = '${appDir.path}${Platform.pathSeparator}hive';
      final boxFile = '$hiveDir${Platform.pathSeparator}$boxName.hive';
      final lockFile = '$hiveDir${Platform.pathSeparator}$boxName.lock';

      final file = File(boxFile);
      final lock = File(lockFile);

      if (await file.exists()) {
        await file.delete();
        AppLogger.info('已删除损坏的缓存文件: $boxFile');
      }

      if (await lock.exists()) {
        await lock.delete();
        AppLogger.info('已删除锁定文件: $lockFile');
      }

      // 如果是特定的缓存盒子，也清理可能的相关文件
      if (boxName.contains('portfolio') || boxName.contains('fund_favorite')) {
        await _clearRelatedCacheFiles(hiveDir, boxName);
      }
    } catch (e) {
      AppLogger.warn('清理缓存盒子失败: $boxName, 错误: $e');
    }
  }

  /// 清理相关的缓存文件
  Future<void> _clearRelatedCacheFiles(String hiveDir, String boxName) async {
    try {
      final directory = Directory(hiveDir);
      if (await directory.exists()) {
        await for (final entity in directory.list()) {
          if (entity is File && entity.path.contains(boxName.split('_')[0])) {
            await entity.delete();
            AppLogger.info('已删除相关缓存文件: ${entity.path}');
          }
        }
      }
    } catch (e) {
      AppLogger.warn('清理相关缓存文件失败: $e');
    }
  }

  /// 关闭缓存服务
  Future<void> dispose() async {
    try {
      // 尝试关闭已打开的盒子
      try {
        await Hive.box(_holdingsBoxName).close();
      } catch (e) {
        // 忽略关闭错误
      }
      try {
        await Hive.box(_navHistoryBoxName).close();
      } catch (e) {
        // 忽略关闭错误
      }
      try {
        await Hive.box(_benchmarkHistoryBoxName).close();
      } catch (e) {
        // 忽略关闭错误
      }
      try {
        await Hive.box(_dividendHistoryBoxName).close();
      } catch (e) {
        // 忽略关闭错误
      }
      try {
        await Hive.box(_splitHistoryBoxName).close();
      } catch (e) {
        // 忽略关闭错误
      }

      AppLogger.info('Portfolio profit cache service disposed');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to dispose cache service', e, stackTrace);
    }
  }

  /// 缓存用户持仓数据
  Future<void> cacheHoldings(String cacheKey, List<PortfolioHolding> holdings,
      Duration expiryDuration) async {
    try {
      // 适配器已在依赖注入时统一注册，无需重复检查

      final box = await Hive.openBox(_holdingsBoxName);
      final cacheItem = CacheItem<List<PortfolioHolding>>(
        data: holdings,
        timestamp: DateTime.now(),
        expiryDate: DateTime.now().add(expiryDuration),
      );

      await box.put(cacheKey, cacheItem.toJson());
      AppLogger.debug('Cached ${holdings.length} holdings with key: $cacheKey');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to cache holdings', e, stackTrace);
    }
  }

  /// 获取缓存的用户持仓数据
  Future<List<PortfolioHolding>?> getCachedHoldings(String cacheKey) async {
    try {
      // 检查适配器是否已注册
      if (!Hive.isAdapterRegistered(0)) {
        AppLogger.warn(
            'PortfolioHolding adapter not registered, skipping cache read');
        return null;
      }

      final box = await Hive.openBox(_holdingsBoxName);
      final jsonData = box.get(cacheKey);

      if (jsonData == null) {
        return null;
      }

      // 使用专门的方法处理 PortfolioHolding 列表转换
      final cacheItem = jsonData is Map<String, dynamic>
          ? CacheItem<List<PortfolioHolding>>.fromJson(jsonData)
          : CacheItem.fromHoldingJson(jsonData);

      // 检查是否过期
      if (DateTime.now().isAfter(cacheItem.expiryDate)) {
        await box.delete(cacheKey);
        AppLogger.debug('Cache expired for holdings with key: $cacheKey');
        return null;
      }

      AppLogger.debug('Retrieved ${cacheItem.data.length} holdings from cache');
      return cacheItem.data;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get cached holdings', e, stackTrace);
      return null;
    }
  }

  /// 缓存净值历史数据
  Future<void> cacheNavHistory(String cacheKey,
      Map<DateTime, double> navHistory, Duration expiryDuration) async {
    try {
      final box = await Hive.openBox(_navHistoryBoxName);
      final serializedData = navHistory
          .map((key, value) => MapEntry(key.millisecondsSinceEpoch, value));

      final cacheItem = CacheItem<Map<int, double>>(
        data: serializedData,
        timestamp: DateTime.now(),
        expiryDate: DateTime.now().add(expiryDuration),
      );

      await box.put(cacheKey, cacheItem.toJson());
      AppLogger.debug(
          'Cached ${navHistory.length} NAV data points with key: $cacheKey');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to cache NAV history', e, stackTrace);
    }
  }

  /// 获取缓存的净值历史数据
  Future<Map<DateTime, double>?> getCachedNavHistory(String cacheKey) async {
    try {
      final box = await Hive.openBox(_navHistoryBoxName);
      final jsonData = box.get(cacheKey);

      if (jsonData == null) {
        return null;
      }

      final cacheItem = CacheItem<Map<int, double>>.fromJson(jsonData);

      // 检查是否过期
      if (DateTime.now().isAfter(cacheItem.expiryDate)) {
        await box.delete(cacheKey);
        AppLogger.debug('Cache expired for NAV history with key: $cacheKey');
        return null;
      }

      final navHistory = cacheItem.data.map((key, value) =>
          MapEntry(DateTime.fromMillisecondsSinceEpoch(key), value));
      AppLogger.debug(
          'Retrieved ${navHistory.length} NAV data points from cache');
      return navHistory;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get cached NAV history', e, stackTrace);
      return null;
    }
  }

  /// 缓存基准指数历史数据
  Future<void> cacheBenchmarkHistory(String cacheKey,
      Map<DateTime, double> benchmarkHistory, Duration expiryDuration) async {
    try {
      final box = await Hive.openBox(_benchmarkHistoryBoxName);
      final serializedData = benchmarkHistory
          .map((key, value) => MapEntry(key.millisecondsSinceEpoch, value));

      final cacheItem = CacheItem<Map<int, double>>(
        data: serializedData,
        timestamp: DateTime.now(),
        expiryDate: DateTime.now().add(expiryDuration),
      );

      await box.put(cacheKey, cacheItem.toJson());
      AppLogger.debug(
          'Cached ${benchmarkHistory.length} benchmark data points with key: $cacheKey');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to cache benchmark history', e, stackTrace);
    }
  }

  /// 获取缓存的基准指数历史数据
  Future<Map<DateTime, double>?> getCachedBenchmarkHistory(
      String cacheKey) async {
    try {
      final box = await Hive.openBox(_benchmarkHistoryBoxName);
      final jsonData = box.get(cacheKey);

      if (jsonData == null) {
        return null;
      }

      final cacheItem = CacheItem<Map<int, double>>.fromJson(jsonData);

      // 检查是否过期
      if (DateTime.now().isAfter(cacheItem.expiryDate)) {
        await box.delete(cacheKey);
        AppLogger.debug(
            'Cache expired for benchmark history with key: $cacheKey');
        return null;
      }

      final benchmarkHistory = cacheItem.data.map((key, value) =>
          MapEntry(DateTime.fromMillisecondsSinceEpoch(key), value));
      AppLogger.debug(
          'Retrieved ${benchmarkHistory.length} benchmark data points from cache');
      return benchmarkHistory;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get cached benchmark history', e, stackTrace);
      return null;
    }
  }

  /// 缓存分红历史数据
  Future<void> cacheDividendHistory(
      String cacheKey,
      List<FundCorporateAction> dividendHistory,
      Duration expiryDuration) async {
    try {
      final box = await Hive.openBox(_dividendHistoryBoxName);
      final cacheItem = CacheItem<List<FundCorporateAction>>(
        data: dividendHistory,
        timestamp: DateTime.now(),
        expiryDate: DateTime.now().add(expiryDuration),
      );

      await box.put(cacheKey, cacheItem.toJson());
      AppLogger.debug(
          'Cached ${dividendHistory.length} dividend records with key: $cacheKey');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to cache dividend history', e, stackTrace);
    }
  }

  /// 获取缓存的分红历史数据
  Future<List<FundCorporateAction>?> getCachedDividendHistory(
      String cacheKey) async {
    try {
      final box = await Hive.openBox(_dividendHistoryBoxName);
      final jsonData = box.get(cacheKey);

      if (jsonData == null) {
        return null;
      }

      final cacheItem = CacheItem<List<FundCorporateAction>>.fromJson(jsonData);

      // 检查是否过期
      if (DateTime.now().isAfter(cacheItem.expiryDate)) {
        await box.delete(cacheKey);
        AppLogger.debug(
            'Cache expired for dividend history with key: $cacheKey');
        return null;
      }

      AppLogger.debug(
          'Retrieved ${cacheItem.data.length} dividend records from cache');
      return cacheItem.data;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get cached dividend history', e, stackTrace);
      return null;
    }
  }

  /// 缓存拆分历史数据
  Future<void> cacheSplitHistory(String cacheKey,
      List<FundSplitDetail> splitHistory, Duration expiryDuration) async {
    try {
      final box = await Hive.openBox(_splitHistoryBoxName);
      final cacheItem = CacheItem<List<FundSplitDetail>>(
        data: splitHistory,
        timestamp: DateTime.now(),
        expiryDate: DateTime.now().add(expiryDuration),
      );

      await box.put(cacheKey, cacheItem.toJson());
      AppLogger.debug(
          'Cached ${splitHistory.length} split records with key: $cacheKey');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to cache split history', e, stackTrace);
    }
  }

  /// 获取缓存的拆分历史数据
  Future<List<FundSplitDetail>?> getCachedSplitHistory(String cacheKey) async {
    try {
      final box = await Hive.openBox(_splitHistoryBoxName);
      final jsonData = box.get(cacheKey);

      if (jsonData == null) {
        return null;
      }

      final cacheItem = CacheItem<List<FundSplitDetail>>.fromJson(jsonData);

      // 检查是否过期
      if (DateTime.now().isAfter(cacheItem.expiryDate)) {
        await box.delete(cacheKey);
        AppLogger.debug('Cache expired for split history with key: $cacheKey');
        return null;
      }

      AppLogger.debug(
          'Retrieved ${cacheItem.data.length} split records from cache');
      return cacheItem.data;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get cached split history', e, stackTrace);
      return null;
    }
  }

  /// 缓存收益指标数据
  Future<void> cacheProfitMetrics({
    required String cacheKey,
    required PortfolioProfitMetrics metrics,
    required Duration expiryDuration,
  }) async {
    try {
      final box = await Hive.openBox(_profitMetricsBoxName);
      final cacheItem = CacheItem<PortfolioProfitMetrics>(
        data: metrics,
        timestamp: DateTime.now(),
        expiryDate: DateTime.now().add(expiryDuration),
      );

      await box.put(cacheKey, cacheItem.toJson());
      AppLogger.debug('Cached profit metrics with key: $cacheKey');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to cache profit metrics', e, stackTrace);
    }
  }

  /// 获取缓存的收益指标数据
  Future<PortfolioProfitMetrics?> getCachedProfitMetrics(
      String cacheKey) async {
    try {
      final box = await Hive.openBox(_profitMetricsBoxName);
      final jsonData = box.get(cacheKey);

      if (jsonData == null) {
        return null;
      }

      final cacheItem = CacheItem<PortfolioProfitMetrics>.fromJson(jsonData);

      // 检查是否过期
      if (DateTime.now().isAfter(cacheItem.expiryDate)) {
        await box.delete(cacheKey);
        AppLogger.debug('Cache expired for profit metrics with key: $cacheKey');
        return null;
      }

      AppLogger.debug('Retrieved profit metrics from cache');
      return cacheItem.data;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get cached profit metrics', e, stackTrace);
      return null;
    }
  }

  /// 缓存组合汇总数据
  Future<void> cachePortfolioSummary({
    required String cacheKey,
    required PortfolioSummary summary,
    required Duration expiryDuration,
  }) async {
    try {
      final box = await Hive.openBox(_portfolioSummaryBoxName);
      final cacheItem = CacheItem<PortfolioSummary>(
        data: summary,
        timestamp: DateTime.now(),
        expiryDate: DateTime.now().add(expiryDuration),
      );

      await box.put(cacheKey, cacheItem.toJson());
      AppLogger.debug('Cached portfolio summary with key: $cacheKey');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to cache portfolio summary', e, stackTrace);
    }
  }

  /// 获取缓存的组合汇总数据
  Future<PortfolioSummary?> getCachedPortfolioSummary(String cacheKey) async {
    try {
      final box = await Hive.openBox(_portfolioSummaryBoxName);
      final jsonData = box.get(cacheKey);

      if (jsonData == null) {
        return null;
      }

      final cacheItem = CacheItem<PortfolioSummary>.fromJson(jsonData);

      // 检查是否过期
      if (DateTime.now().isAfter(cacheItem.expiryDate)) {
        await box.delete(cacheKey);
        AppLogger.debug(
            'Cache expired for portfolio summary with key: $cacheKey');
        return null;
      }

      AppLogger.debug('Retrieved portfolio summary from cache');
      return cacheItem.data;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get cached portfolio summary', e, stackTrace);
      return null;
    }
  }

  /// 清除过期缓存
  Future<void> clearExpiredCache() async {
    try {
      AppLogger.info('Clearing expired cache entries');

      final boxes = [
        await Hive.openBox(_holdingsBoxName),
        await Hive.openBox(_navHistoryBoxName),
        await Hive.openBox(_benchmarkHistoryBoxName),
        await Hive.openBox(_dividendHistoryBoxName),
        await Hive.openBox(_splitHistoryBoxName),
        await Hive.openBox(_profitMetricsBoxName),
        await Hive.openBox(_portfolioSummaryBoxName),
      ];

      int totalCleared = 0;

      for (final box in boxes) {
        final keysToDelete = <String>[];
        final now = DateTime.now();

        for (final key in box.keys) {
          if (key is String) {
            try {
              final jsonData = box.get(key);
              if (jsonData != null) {
                // 尝试解析为通用缓存项格式
                if (jsonData is Map && jsonData.containsKey('expiryDate')) {
                  final expiryDate =
                      DateTime.parse(jsonData['expiryDate'] as String);
                  if (now.isAfter(expiryDate)) {
                    keysToDelete.add(key);
                  }
                }
              }
            } catch (e) {
              // 如果解析失败，也删除这个缓存项
              keysToDelete.add(key);
            }
          }
        }

        for (final key in keysToDelete) {
          await box.delete(key);
          totalCleared++;
        }
      }

      AppLogger.info('Cleared $totalCleared expired cache entries');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to clear expired cache', e, stackTrace);
    }
  }

  /// 清除所有缓存
  Future<void> clearAllCache() async {
    try {
      AppLogger.info('Clearing all cache entries');

      await Hive.box(_holdingsBoxName).clear();
      await Hive.box(_navHistoryBoxName).clear();
      await Hive.box(_benchmarkHistoryBoxName).clear();
      await Hive.box(_dividendHistoryBoxName).clear();
      await Hive.box(_splitHistoryBoxName).clear();
      await Hive.box(_profitMetricsBoxName).clear();
      await Hive.box(_portfolioSummaryBoxName).clear();

      AppLogger.info('All cache entries cleared');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to clear all cache', e, stackTrace);
    }
  }

  /// 缓存基准指数列表
  Future<void> cacheBenchmarkIndices(
      String cacheKey, List<BenchmarkIndex> indices) async {
    try {
      // 基准指数列表相对稳定，缓存时间较长
      final box = await Hive.openBox(_benchmarkHistoryBoxName); // 复用现有的box
      final cacheItem = CacheItem<List<BenchmarkIndex>>(
        data: indices,
        timestamp: DateTime.now(),
        expiryDate: DateTime.now().add(const Duration(days: 7)),
      );

      await box.put(cacheKey, cacheItem.toJson());
      AppLogger.debug(
          'Cached ${indices.length} benchmark indices with key: $cacheKey');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to cache benchmark indices', e, stackTrace);
    }
  }

  /// 获取缓存的基准指数列表
  Future<List<BenchmarkIndex>?> getCachedBenchmarkIndices(
      String cacheKey) async {
    try {
      final box = await Hive.openBox(_benchmarkHistoryBoxName);
      final jsonData = box.get(cacheKey);

      if (jsonData == null) {
        return null;
      }

      final cacheItem = CacheItem<List<BenchmarkIndex>>.fromJson(jsonData);

      // 检查是否过期
      if (DateTime.now().isAfter(cacheItem.expiryDate)) {
        await box.delete(cacheKey);
        AppLogger.debug(
            'Cache expired for benchmark indices with key: $cacheKey');
        return null;
      }

      AppLogger.debug(
          'Retrieved ${cacheItem.data.length} benchmark indices from cache');
      return cacheItem.data;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get cached benchmark indices', e, stackTrace);
      return null;
    }
  }

  /// 缓存数据质量报告
  Future<void> cacheDataQualityReport(
      String cacheKey, DataQualityReport report) async {
    try {
      final box = await Hive.openBox(_navHistoryBoxName); // 复用现有的box
      final cacheItem = CacheItem<DataQualityReport>(
        data: report,
        timestamp: DateTime.now(),
        expiryDate: DateTime.now().add(const Duration(hours: 6)),
      );

      await box.put(cacheKey, cacheItem.toJson());
      AppLogger.debug('Cached data quality report with key: $cacheKey');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to cache data quality report', e, stackTrace);
    }
  }

  /// 获取缓存的数据质量报告
  Future<DataQualityReport?> getCachedDataQualityReport(String cacheKey) async {
    try {
      final box = await Hive.openBox(_navHistoryBoxName);
      final jsonData = box.get(cacheKey);

      if (jsonData == null) {
        return null;
      }

      final cacheItem = CacheItem<DataQualityReport>.fromJson(jsonData);

      // 检查是否过期
      if (DateTime.now().isAfter(cacheItem.expiryDate)) {
        await box.delete(cacheKey);
        AppLogger.debug(
            'Cache expired for data quality report with key: $cacheKey');
        return null;
      }

      AppLogger.debug('Retrieved data quality report from cache');
      return cacheItem.data;
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to get cached data quality report', e, stackTrace);
      return null;
    }
  }

  /// 获取缓存统计信息
  Future<CacheStatistics> getCacheStatistics() async {
    try {
      final holdingsBox = await Hive.openBox(_holdingsBoxName);
      final navHistoryBox = await Hive.openBox(_navHistoryBoxName);
      final benchmarkHistoryBox = await Hive.openBox(_benchmarkHistoryBoxName);
      final dividendHistoryBox = await Hive.openBox(_dividendHistoryBoxName);
      final splitHistoryBox = await Hive.openBox(_splitHistoryBoxName);
      final profitMetricsBox = await Hive.openBox(_profitMetricsBoxName);
      final portfolioSummaryBox = await Hive.openBox(_portfolioSummaryBoxName);

      final now = DateTime.now();
      int totalEntries = 0;
      int expiredEntries = 0;

      final boxes = [
        holdingsBox,
        navHistoryBox,
        benchmarkHistoryBox,
        dividendHistoryBox,
        splitHistoryBox,
        profitMetricsBox,
        portfolioSummaryBox,
      ];

      for (final box in boxes) {
        for (final key in box.keys) {
          if (key is String) {
            totalEntries++;
            try {
              final jsonData = box.get(key);
              if (jsonData is Map && jsonData.containsKey('expiryDate')) {
                final expiryDate =
                    DateTime.parse(jsonData['expiryDate'] as String);
                if (now.isAfter(expiryDate)) {
                  expiredEntries++;
                }
              }
            } catch (e) {
              // 解析失败也算作过期
              expiredEntries++;
            }
          }
        }
      }

      return CacheStatistics(
        totalEntries: totalEntries,
        expiredEntries: expiredEntries,
        validEntries: totalEntries - expiredEntries,
        lastCleanup: DateTime.now(),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get cache statistics', e, stackTrace);
      return CacheStatistics.empty();
    }
  }
}

/// 缓存项通用类
class CacheItem<T> {
  final T data;
  final DateTime timestamp;
  final DateTime expiryDate;

  CacheItem({
    required this.data,
    required this.timestamp,
    required this.expiryDate,
  });

  factory CacheItem.fromJson(Map<String, dynamic> json) {
    return CacheItem<T>(
      data: json['data'] as T,
      timestamp: DateTime.parse(json['timestamp'] as String),
      expiryDate: DateTime.parse(json['expiryDate'] as String),
    );
  }

  /// 从动态Map创建，解决类型转换问题
  factory CacheItem.fromJsonDynamic(Map<dynamic, dynamic> json,
      {T? Function(dynamic)? customConverter}) {
    final stringJson = <String, dynamic>{};
    json.forEach((key, value) {
      if (key is String) {
        stringJson[key] = value;
      }
    });

    final dataValue = json['data'];
    T convertedData;

    if (customConverter != null) {
      convertedData = customConverter(dataValue) as T;
    } else {
      convertedData = dataValue as T;
    }

    return CacheItem<T>(
      data: convertedData,
      timestamp: DateTime.parse(json['timestamp'] as String),
      expiryDate: DateTime.parse(json['expiryDate'] as String),
    );
  }

  /// 专门用于 PortfolioHolding 列表的转换
  static CacheItem<List<PortfolioHolding>> fromHoldingJson(
      Map<dynamic, dynamic> json) {
    final stringJson = <String, dynamic>{};
    json.forEach((key, value) {
      if (key is String) {
        stringJson[key] = value;
      }
    });

    final dataValue = json['data'];
    List<PortfolioHolding> holdings;

    if (dataValue is List) {
      holdings = dataValue.map((item) {
        if (item is PortfolioHolding) {
          return item;
        } else if (item is Map<String, dynamic>) {
          return PortfolioHolding.fromJson(item);
        } else {
          // 尝试将 Map<dynamic, dynamic> 转换为 Map<String, dynamic>
          final itemStringMap = <String, dynamic>{};
          if (item is Map) {
            item.forEach((key, value) {
              if (key is String) {
                itemStringMap[key] = value;
              }
            });
          }
          return PortfolioHolding.fromJson(itemStringMap);
        }
      }).toList();
    } else {
      holdings = [];
    }

    return CacheItem<List<PortfolioHolding>>(
      data: holdings,
      timestamp: DateTime.parse(json['timestamp'] as String),
      expiryDate: DateTime.parse(json['expiryDate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
    };
  }
}

/// 缓存统计信息
class CacheStatistics {
  final int totalEntries;
  final int expiredEntries;
  final int validEntries;
  final DateTime lastCleanup;

  const CacheStatistics({
    required this.totalEntries,
    required this.expiredEntries,
    required this.validEntries,
    required this.lastCleanup,
  });

  factory CacheStatistics.empty() {
    return CacheStatistics(
      totalEntries: 0,
      expiredEntries: 0,
      validEntries: 0,
      lastCleanup: DateTime.now(),
    );
  }

  /// 过期率
  double get expiredRatio =>
      totalEntries > 0 ? expiredEntries / totalEntries : 0.0;

  /// 有效率
  double get validRatio => totalEntries > 0 ? validEntries / totalEntries : 0.0;

  @override
  String toString() {
    return 'CacheStatistics{'
        'total: $totalEntries, '
        'valid: $validEntries, '
        'expired: $expiredEntries, '
        'validRatio: ${(validRatio * 100).toStringAsFixed(1)}%'
        '}';
  }
}
