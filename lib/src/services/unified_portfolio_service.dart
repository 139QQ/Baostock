import 'dart:async';
import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:hive/hive.dart';

import '../core/utils/logger.dart';
import '../core/cache/interfaces/cache_service.dart';
import '../core/cache/unified_hive_cache_manager.dart';
import '../features/portfolio/domain/entities/portfolio_holding.dart';

/// 统一投资组合服务 - 简化版本
///
/// 功能特性：
/// 1. 提供基本的持仓管理功能
/// 2. 支持本地缓存
/// 3. 提供简单的收益计算
class UnifiedPortfolioService {
  static const String _portfolioBoxName = 'unified_portfolio_data';
  static const String _cacheKeyPrefix = 'portfolio_';

  // 核心组件
  late final CacheService _cacheService;

  // 缓存
  Box<PortfolioHolding>? _portfolioBox;
  final Map<String, List<PortfolioHolding>> _memoryCache = {};

  /// 构造函数
  UnifiedPortfolioService({
    CacheService? cacheService,
  }) {
    _initializeServices(cacheService: cacheService);
  }

  /// 初始化服务
  Future<void> _initializeServices({
    CacheService? cacheService,
  }) async {
    try {
      // 初始化缓存服务
      if (cacheService != null) {
        _cacheService = cacheService;
      } else {
        final unifiedManager = UnifiedHiveCacheManager.instance;
        _cacheService = _SimpleCacheService(unifiedManager);
      }

      // 初始化Hive缓存
      await _initializeCache();

      AppLogger.info('✅ UnifiedPortfolioService: 服务初始化成功');
    } catch (e) {
      AppLogger.error('❌ UnifiedPortfolioService: 服务初始化失败', e);
      rethrow;
    }
  }

  /// 初始化Hive缓存
  Future<void> _initializeCache() async {
    try {
      _portfolioBox = await Hive.openBox<PortfolioHolding>(_portfolioBoxName);
      await _loadMemoryCache();
      AppLogger.info('✅ UnifiedPortfolioService: Hive缓存初始化成功');
    } catch (e) {
      AppLogger.error('❌ UnifiedPortfolioService: Hive缓存初始化失败', e);
    }
  }

  /// 加载内存缓存
  Future<void> _loadMemoryCache() async {
    if (_portfolioBox == null) return;

    try {
      final holdings = _portfolioBox!.values.toList();
      _memoryCache.clear();

      // 按状态分组持仓
      for (final holding in holdings) {
        final statusKey = holding.status.toString();
        _memoryCache.putIfAbsent(statusKey, () => []).add(holding);
      }

      AppLogger.info(
          '✅ UnifiedPortfolioService: 内存缓存加载完成 (${holdings.length}条持仓)');
    } catch (e) {
      AppLogger.error('❌ UnifiedPortfolioService: 内存缓存加载失败', e);
    }
  }

  /// 获取用户持仓列表
  Future<List<PortfolioHolding>> getPortfolioHoldings({
    String userId = 'default_user',
    HoldingStatus? status,
  }) async {
    try {
      if (_portfolioBox == null) {
        AppLogger.warn('⚠️ PortfolioBox未初始化，返回空列表');
        return [];
      }

      final holdings = _portfolioBox!.values.where((holding) {
        if (status != null && holding.status != status) {
          return false;
        }
        return true;
      }).toList();

      AppLogger.debug('📋 获取持仓列表: ${holdings.length}条记录');
      return holdings;
    } catch (e) {
      AppLogger.error('❌ 获取持仓列表失败', e);
      return [];
    }
  }

  /// 添加持仓
  Future<bool> addPortfolioHolding(PortfolioHolding holding) async {
    try {
      if (_portfolioBox == null) {
        AppLogger.warn('⚠️ PortfolioBox未初始化，无法添加持仓');
        return false;
      }

      await _portfolioBox!.put(holding.fundCode, holding);
      await _loadMemoryCache(); // 重新加载内存缓存

      AppLogger.info('✅ 添加持仓成功: ${holding.fundCode}');
      return true;
    } catch (e) {
      AppLogger.error('❌ 添加持仓失败: ${holding.fundCode}', e);
      return false;
    }
  }

  /// 更新持仓
  Future<bool> updatePortfolioHolding(PortfolioHolding holding) async {
    return await addPortfolioHolding(holding); // 在Hive中，put会覆盖现有值
  }

  /// 删除持仓
  Future<bool> removePortfolioHolding(String fundCode) async {
    try {
      if (_portfolioBox == null) {
        AppLogger.warn('⚠️ PortfolioBox未初始化，无法删除持仓');
        return false;
      }

      await _portfolioBox!.delete(fundCode);
      await _loadMemoryCache(); // 重新加载内存缓存

      AppLogger.info('✅ 删除持仓成功: $fundCode');
      return true;
    } catch (e) {
      AppLogger.error('❌ 删除持仓失败: $fundCode', e);
      return false;
    }
  }

  /// 计算总市值
  Future<double> calculateTotalMarketValue() async {
    try {
      final holdings = await getPortfolioHoldings();
      double total = 0.0;
      for (final holding in holdings) {
        total += holding.marketValue;
      }
      return total;
    } catch (e) {
      AppLogger.error('❌ 计算总市值失败', e);
      return 0.0;
    }
  }

  /// 计算总收益
  Future<double> calculateTotalProfit() async {
    try {
      final holdings = await getPortfolioHoldings();
      double total = 0.0;
      for (final holding in holdings) {
        total += (holding.marketValue - holding.costValue);
      }
      return total;
    } catch (e) {
      AppLogger.error('❌ 计算总收益失败', e);
      return 0.0;
    }
  }

  /// 计算收益率
  Future<double> calculateReturnRate() async {
    try {
      final totalCost = await _getTotalCostValue();
      if (totalCost <= 0) return 0.0;

      final totalProfit = await calculateTotalProfit();
      return (totalProfit / totalCost) * 100;
    } catch (e) {
      AppLogger.error('❌ 计算收益率失败', e);
      return 0.0;
    }
  }

  /// 获取总成本
  Future<double> _getTotalCostValue() async {
    try {
      final holdings = await getPortfolioHoldings();
      double total = 0.0;
      for (final holding in holdings) {
        total += holding.costValue;
      }
      return total;
    } catch (e) {
      AppLogger.error('❌ 计算总成本失败', e);
      return 0.0;
    }
  }

  /// 获取持仓统计信息
  Future<Map<String, dynamic>> getPortfolioStats() async {
    try {
      final holdings = await getPortfolioHoldings();
      final totalMarketValue = await calculateTotalMarketValue();
      final totalProfit = await calculateTotalProfit();
      final returnRate = await calculateReturnRate();
      final totalCost = await _getTotalCostValue();

      return {
        'totalHoldings': holdings.length,
        'totalMarketValue': totalMarketValue,
        'totalCost': totalCost,
        'totalProfit': totalProfit,
        'returnRate': returnRate,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      AppLogger.error('❌ 获取持仓统计失败', e);
      return {
        'error': e.toString(),
        'totalHoldings': 0,
        'totalMarketValue': 0.0,
        'totalCost': 0.0,
        'totalProfit': 0.0,
        'returnRate': 0.0,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    }
  }

  /// 清空所有持仓
  Future<bool> clearAllHoldings() async {
    try {
      if (_portfolioBox == null) {
        AppLogger.warn('⚠️ PortfolioBox未初始化，无法清空持仓');
        return false;
      }

      await _portfolioBox!.clear();
      _memoryCache.clear();

      AppLogger.info('✅ 清空所有持仓成功');
      return true;
    } catch (e) {
      AppLogger.error('❌ 清空所有持仓失败', e);
      return false;
    }
  }

  /// 清理资源
  Future<void> dispose() async {
    try {
      if (_portfolioBox != null && _portfolioBox!.isOpen) {
        await _portfolioBox!.close();
      }
      _memoryCache.clear();
      AppLogger.info('✅ UnifiedPortfolioService: 资源清理完成');
    } catch (e) {
      AppLogger.error('❌ UnifiedPortfolioService: 资源清理失败', e);
    }
  }
}

/// 简单的缓存服务适配器
class _SimpleCacheService implements CacheService {
  final UnifiedHiveCacheManager _manager;

  _SimpleCacheService(this._manager);

  @override
  Future<T?> get<T>(String key) async {
    return _manager.get<T>(key);
  }

  @override
  Future<void> put<T>(String key, T value, {Duration? expiration}) async {
    await _manager.put(key, value, expiration: expiration);
  }

  @override
  Future<void> remove(String key) async {
    await _manager.remove(key);
  }

  @override
  Future<void> clear() async {
    await _manager.clear();
  }

  @override
  Future<bool> containsKey(String key) async {
    return _manager.containsKey(key);
  }

  @override
  Future<List<String>> getAllKeys() async {
    return await _manager.getAllKeys();
  }

  @override
  Future<Map<String, dynamic>> getStats() async {
    return await _manager.getStats();
  }

  @override
  Future<Map<String, dynamic>> getAll(List<String> keys) async {
    return _manager.getAll(keys);
  }

  @override
  Future<void> putAll(Map<String, dynamic> keyValuePairs,
      {Duration? expiration}) async {
    await _manager.putAll(keyValuePairs, expiration: expiration);
  }

  @override
  Future<void> removeAll(List<String> keys) async {
    for (final key in keys) {
      await _manager.remove(key);
    }
  }

  @override
  Future<void> setExpiration(String key, Duration expiration) async {
    await _manager.setExpiration(key, expiration);
  }

  @override
  Future<Duration?> getExpiration(String key) async {
    return await _manager.getExpiration(key);
  }
}
