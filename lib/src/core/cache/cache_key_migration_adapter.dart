/// 缓存键迁移适配器
///
/// 提供旧缓存键到新标准化缓存键的迁移服务，确保向后兼容性
library cache_key_migration_adapter;

import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'cache_key_manager.dart';
import '../utils/logger.dart';

/// 缓存键迁移记录
class CacheMigrationRecord {
  final String oldKey;
  final String newKey;
  final DateTime migratedAt;
  final bool success;

  CacheMigrationRecord({
    required this.oldKey,
    required this.newKey,
    required this.migratedAt,
    required this.success,
  });

  Map<String, dynamic> toJson() {
    return {
      'old_key': oldKey,
      'new_key': newKey,
      'migrated_at': migratedAt.toIso8601String(),
      'success': success,
    };
  }

  factory CacheMigrationRecord.fromJson(Map<String, dynamic> json) {
    return CacheMigrationRecord(
      oldKey: json['old_key'],
      newKey: json['new_key'],
      migratedAt: DateTime.parse(json['migrated_at']),
      success: json['success'],
    );
  }
}

/// 缓存键迁移适配器
///
/// 负责将旧格式的缓存键迁移到新的标准化格式
class CacheKeyMigrationAdapter {
  static CacheKeyMigrationAdapter? _instance;
  static CacheKeyMigrationAdapter get instance {
    _instance ??= CacheKeyMigrationAdapter._();
    return _instance!;
  }

  CacheKeyMigrationAdapter._() {
    AppLogger.info('🔄 CacheKeyMigrationAdapter 初始化');
  }

  // 旧缓存键模式映射
  static const Map<String, CacheKeyType> _oldKeyPatterns = {
    'fund_cache_timestamp': CacheKeyType.metadata,
    'fund_cache_version': CacheKeyType.metadata,
    'cache_timestamp': CacheKeyType.metadata,
    'fund_data_cache': CacheKeyType.fundData,
    'optimized_funds': CacheKeyType.fundData,
    'funds_v3': CacheKeyType.fundData,
    'high_performance_funds': CacheKeyType.fundData,
    'fund_search_index': CacheKeyType.searchIndex,
    'funds_index_v3': CacheKeyType.searchIndex,
    'fund_cache_metadata': CacheKeyType.metadata,
    'unified_fund_cache': CacheKeyType.fundData,
    'unified_fund_metadata': CacheKeyType.metadata,
    'unified_fund_index': CacheKeyType.searchIndex,
  };

  // 迁移记录存储
  final List<CacheMigrationRecord> _migrationRecords = [];
  Box? _migrationBox;

  /// 初始化迁移适配器
  Future<void> initialize() async {
    try {
      // 尝试直接打开盒子，如果失败则降级到内存模式
      _migrationBox = await Hive.openBox('cache_key_migration_records');
      await _loadMigrationRecords();
      AppLogger.info('✅ 缓存键迁移适配器初始化成功');
    } catch (e) {
      AppLogger.error('❌ 缓存键迁移适配器初始化失败，将使用内存模式', e);
      // 降级到内存模式
      _migrationRecords.clear();
    }
  }

  /// 加载迁移记录
  Future<void> _loadMigrationRecords() async {
    if (_migrationBox == null) return;

    try {
      _migrationRecords.clear();
      final records = _migrationBox!.values.cast<Map<String, dynamic>>();
      for (final record in records) {
        _migrationRecords.add(CacheMigrationRecord.fromJson(record));
      }
      AppLogger.debug('📋 加载了 ${_migrationRecords.length} 条迁移记录');
    } catch (e) {
      AppLogger.error('❌ 加载迁移记录失败', e);
    }
  }

  /// 检查是否为旧格式缓存键
  bool isLegacyKey(String key) {
    // 首先检查是否为标准键，如果是标准键则直接返回 false
    if (_isStandardKey(key)) {
      return false;
    }

    // 检查基金代码模式（优先级最高）
    if (_isFundCodePattern(key)) {
      return true;
    }

    // 检查直接模式匹配
    if (_oldKeyPatterns.keys.any((pattern) => key.contains(pattern))) {
      return true;
    }

    // 检查索引模式
    if (_isIndexPattern(key)) {
      return true;
    }

    // 检查元数据模式
    if (_isMetadataPattern(key)) {
      return true;
    }

    return false;
  }

  /// 检查是否为标准格式的缓存键
  bool _isStandardKey(String key) {
    return CacheKeyManager.instance.isValidKey(key);
  }

  /// 迁移单个缓存键
  Future<String?> migrateKey(String oldKey) async {
    try {
      // 检查是否已经迁移过
      if (_hasMigratedBefore(oldKey)) {
        final record = _migrationRecords.firstWhere(
          (r) => r.oldKey == oldKey && r.success,
          orElse: () => CacheMigrationRecord(
            oldKey: oldKey,
            newKey: '',
            migratedAt: DateTime.now(),
            success: false,
          ),
        );
        if (record.success) {
          return record.newKey;
        }
      }

      // 生成新的标准化缓存键
      final newKey = _generateNewKey(oldKey);
      if (newKey == null) {
        AppLogger.warn('⚠️ 无法为旧键生成新键: $oldKey');
        return null;
      }

      // 记录迁移结果
      final record = CacheMigrationRecord(
        oldKey: oldKey,
        newKey: newKey,
        migratedAt: DateTime.now(),
        success: true,
      );
      await _recordMigration(record);

      AppLogger.info('✅ 缓存键迁移成功: $oldKey -> $newKey');
      return newKey;
    } catch (e) {
      // 记录失败的迁移
      final record = CacheMigrationRecord(
        oldKey: oldKey,
        newKey: '',
        migratedAt: DateTime.now(),
        success: false,
      );
      await _recordMigration(record);

      AppLogger.error('❌ 缓存键迁移失败: $oldKey', e);
      return null;
    }
  }

  /// 批量迁移缓存键
  Future<Map<String, String?>> migrateKeys(List<String> oldKeys) async {
    final results = <String, String?>{};

    AppLogger.info('🔄 开始批量迁移 ${oldKeys.length} 个缓存键');

    for (final oldKey in oldKeys) {
      results[oldKey] = await migrateKey(oldKey);
    }

    final successCount = results.values.where((v) => v != null).length;
    AppLogger.info('✅ 批量迁移完成: 成功 $successCount/${oldKeys.length} 个');

    return results;
  }

  /// 为旧键生成新的标准化键
  String? _generateNewKey(String oldKey) {
    // 1. 优先检查基金代码模式（最高优先级）
    if (_isFundCodePattern(oldKey)) {
      return _generateFundDataKey(oldKey);
    }

    // 2. 检查直接模式匹配
    for (final entry in _oldKeyPatterns.entries) {
      if (oldKey.contains(entry.key)) {
        return _generateKeyFromPattern(oldKey, entry.key, entry.value);
      }
    }

    // 3. 检查索引模式 - 提高优先级，在元数据模式之前
    if (_isIndexPattern(oldKey)) {
      return _generateSearchIndexKey(oldKey);
    }

    // 4. 检查元数据模式
    if (_isMetadataPattern(oldKey)) {
      return _generateMetadataKey(oldKey);
    }

    // 5. 默认作为临时数据处理
    return CacheKeyManager.instance.temporaryKey('migrated_${oldKey.hashCode}');
  }

  /// 根据模式生成缓存键
  String _generateKeyFromPattern(
      String oldKey, String pattern, CacheKeyType type) {
    switch (type) {
      case CacheKeyType.fundData:
        return CacheKeyManager.instance.generateKey(type, 'migrated_funds');
      case CacheKeyType.searchIndex:
        return CacheKeyManager.instance.generateKey(type, 'migrated_index');
      case CacheKeyType.metadata:
        return CacheKeyManager.instance.generateKey(type, 'migrated_metadata');
      default:
        return CacheKeyManager.instance.generateKey(type, 'migrated_data');
    }
  }

  /// 检查是否为基金代码模式
  bool _isFundCodePattern(String key) {
    // 基金代码通常是6位数字，可以出现在字符串的任何位置
    final fundCodePattern = RegExp(r'(?<!\d)\d{6}(?!\d)');
    return fundCodePattern.hasMatch(key);
  }

  /// 生成基金数据缓存键
  String _generateFundDataKey(String oldKey) {
    final fundCodePattern = RegExp(r'(?<!\d)(\d{6})(?!\d)');
    final match = fundCodePattern.firstMatch(oldKey);

    if (match != null) {
      final fundCode = match.group(1)!;
      return CacheKeyManager.instance.fundDataKey(fundCode);
    }

    return CacheKeyManager.instance.generateKey(
      CacheKeyType.fundData,
      'unknown_fund_${oldKey.hashCode}',
    );
  }

  /// 检查是否为索引模式
  bool _isIndexPattern(String key) {
    return key.contains('index') ||
        key.contains('search') ||
        key.contains('classification') ||
        key.contains('pinyin') ||
        key.contains('code') ||
        key.contains('name') ||
        key.contains('type');
  }

  /// 生成搜索索引缓存键
  String _generateSearchIndexKey(String oldKey) {
    // 智能解析旧键名称，提取具体的索引类型
    if (oldKey.contains('code_index')) {
      return CacheKeyManager.instance.searchIndexKey('fund_code');
    } else if (oldKey.contains('name_index')) {
      return CacheKeyManager.instance.searchIndexKey('fund_name');
    } else if (oldKey.contains('pinyin_search')) {
      return CacheKeyManager.instance.searchIndexKey('fund_pinyin');
    } else if (oldKey.contains('type_classification')) {
      return CacheKeyManager.instance.searchIndexKey('fund_type');
    } else if (oldKey.contains('code')) {
      return CacheKeyManager.instance.searchIndexKey('fund_code');
    } else if (oldKey.contains('name')) {
      return CacheKeyManager.instance.searchIndexKey('fund_name');
    } else if (oldKey.contains('pinyin')) {
      return CacheKeyManager.instance.searchIndexKey('fund_pinyin');
    } else if (oldKey.contains('type')) {
      return CacheKeyManager.instance.searchIndexKey('fund_type');
    } else {
      // 使用完整的旧键名称作为标识符
      return CacheKeyManager.instance.searchIndexKey(oldKey);
    }
  }

  /// 检查是否为元数据模式
  bool _isMetadataPattern(String key) {
    return key.contains('timestamp') ||
        key.contains('version') ||
        key.contains('metadata') ||
        key.contains('meta');
  }

  /// 生成元数据缓存键
  String _generateMetadataKey(String oldKey) {
    if (oldKey.contains('timestamp')) {
      return CacheKeyManager.instance.metadataKey('cache_timestamp');
    } else if (oldKey.contains('version')) {
      return CacheKeyManager.instance.metadataKey('cache_version');
    } else {
      return CacheKeyManager.instance
          .metadataKey('migrated_meta_${oldKey.hashCode}');
    }
  }

  /// 检查是否已经迁移过
  bool _hasMigratedBefore(String oldKey) {
    return _migrationRecords
        .any((record) => record.oldKey == oldKey && record.success);
  }

  /// 记录迁移结果
  Future<void> _recordMigration(CacheMigrationRecord record) async {
    try {
      _migrationRecords.add(record);

      if (_migrationBox != null) {
        await _migrationBox!.put(
          'migration_${DateTime.now().millisecondsSinceEpoch}_${record.oldKey}',
          record.toJson(),
        );
      }
    } catch (e) {
      AppLogger.error('❌ 记录迁移结果失败', e);
    }
  }

  /// 获取迁移统计信息
  Map<String, dynamic> getMigrationStats() {
    final totalMigrations = _migrationRecords.length;
    final successfulMigrations =
        _migrationRecords.where((r) => r.success).length;
    final failedMigrations = totalMigrations - successfulMigrations;

    final typeStats = <CacheKeyType, int>{};
    for (final record in _migrationRecords) {
      if (record.success) {
        final keyInfo = CacheKeyManager.instance.parseKey(record.newKey);
        if (keyInfo != null) {
          typeStats[keyInfo.type] = (typeStats[keyInfo.type] ?? 0) + 1;
        }
      }
    }

    return {
      'total_migrations': totalMigrations,
      'successful_migrations': successfulMigrations,
      'failed_migrations': failedMigrations,
      'success_rate': totalMigrations > 0
          ? '${(successfulMigrations / totalMigrations * 100).toStringAsFixed(1)}%'
          : '0%',
      'type_distribution': typeStats.map((k, v) => MapEntry(k.name, v)),
      'last_migration_time': _migrationRecords.isNotEmpty
          ? _migrationRecords.last.migratedAt.toIso8601String()
          : null,
    };
  }

  /// 清理迁移记录
  Future<void> clearMigrationRecords() async {
    try {
      _migrationRecords.clear();

      if (_migrationBox != null && _migrationBox!.isOpen) {
        await _migrationBox!.clear();
      }

      AppLogger.info('🗑️ 迁移记录已清理');
    } catch (e) {
      AppLogger.error('❌ 清理迁移记录失败', e);
    }
  }

  /// 扫描并迁移现有缓存
  Future<Map<String, String?>> scanAndMigrateCache(Box cacheBox) async {
    final oldKeys = <String>[];
    final allResults = <String, String?>{};

    // 扫描现有缓存键
    for (final key in cacheBox.keys) {
      if (key is String) {
        if (isLegacyKey(key)) {
          oldKeys.add(key);
        } else {
          // 标准格式的键保持不变
          allResults[key] = key;
        }
      }
    }

    AppLogger.info('🔍 扫描到 ${oldKeys.length} 个旧格式缓存键');

    // 批量迁移旧键
    final migrationResults = await migrateKeys(oldKeys);

    // 合并结果
    allResults.addAll(migrationResults);

    return allResults;
  }

  /// 关闭迁移适配器
  Future<void> dispose() async {
    try {
      if (_migrationBox != null && _migrationBox!.isOpen) {
        await _migrationBox!.close();
      }
      AppLogger.info('🔌 CacheKeyMigrationAdapter 已关闭');
    } catch (e) {
      AppLogger.error('❌ 关闭迁移适配器失败', e);
    }
  }
}
