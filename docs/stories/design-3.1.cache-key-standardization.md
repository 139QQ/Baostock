# Story 3.1 缓存键标准化 - 技术设计文档

## 📋 文档概述

**文档版本**: 1.0
**创建日期**: 2025-10-29
**作者**: 系统架构师
**项目**: Baostock 基金管理系统
**关联故事**: docs/stories/3.1.cache-key-standardization.md

## 🎯 设计目标

### 主要目标
1. **统一命名规范**: 实现全项目统一的 `module:type:identifier` 缓存键命名规范
2. **自动迁移**: 开发自动化迁移工具，无缝转换现有缓存数据
3. **冲突管理**: 建立完善的冲突检测和解决机制
4. **向后兼容**: 确保迁移过程中系统的稳定性和可用性

### 性能目标
- 缓存键查找效率提升 ≥ 20%
- 迁移过程零数据丢失
- 迁移后性能不低于原有水平
- 内存使用优化 ≥ 15%

## 🏗️ 核心架构设计

### 1. 整体架构图

```
┌─────────────────────────────────────────────────────────────────┐
│                        缓存键管理系统                              │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │   缓存键管理器    │  │   迁移引擎       │  │   冲突检测器     │  │
│  │ CacheKeyManager │  │ MigrationEngine │  │ConflictDetector │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │   键验证器       │  │   进度跟踪器     │  │   回滚管理器     │  │
│  │  KeyValidator   │  │ ProgressTracker │  │RollbackManager  │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
├─────────────────────────────────────────────────────────────────┤
│                      现有缓存系统                                │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │ UnifiedHiveCache│  │ HiveCacheManager│  │ SharedPreferences│  │
│  │     Manager     │  │                 │  │                 │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### 2. 分层架构设计

#### 2.1 表现层 (Presentation Layer)
```dart
abstract class CacheKeyManager {
  // 生成标准格式缓存键
  String generateKey(String module, String type, String identifier, {String version = 'v1'});

  // 验证缓存键格式
  bool validateKey(String key);

  // 解析缓存键组件
  KeyComponents parseKey(String key);

  // 检测键冲突
  Future<List<KeyConflict>> detectConflicts(List<String> keys);

  // 批量生成键
  List<String> generateBatchKeys(String module, String type, List<String> identifiers);
}
```

#### 2.2 业务逻辑层 (Business Logic Layer)
```dart
class CacheKeyManagerImpl implements CacheKeyManager {
  final KeyValidator _validator;
  final ConflictDetector _conflictDetector;
  final KeyParser _parser;

  @override
  String generateKey(String module, String type, String identifier, {String version = 'v1'}) {
    // 验证输入参数
    _validateInputs(module, type, identifier);

    // 生成标准键
    final key = '$module:$type:$identifier:$version';

    // 验证生成的键
    if (!_validator.validate(key)) {
      throw CacheKeyException('Invalid cache key generated: $key');
    }

    return key;
  }

  @override
  KeyComponents parseKey(String key) {
    if (!_validator.validate(key)) {
      throw CacheKeyException('Invalid cache key format: $key');
    }

    return _parser.parse(key);
  }
}
```

#### 2.3 数据访问层 (Data Access Layer)
```dart
abstract class CacheKeyRepository {
  // 保存键映射关系
  Future<void> saveKeyMapping(Map<String, String> mapping);

  // 获取键映射关系
  Future<Map<String, String>> getKeyMapping();

  // 保存迁移记录
  Future<void> saveMigrationRecord(MigrationRecord record);

  // 获取迁移历史
  Future<List<MigrationRecord>> getMigrationHistory();
}
```

## 📦 核心组件设计

### 1. 缓存键管理器 (CacheKeyManager)

#### 1.1 接口定义
```dart
class CacheKeyConstants {
  // 模块常量
  static const String MODULE_FUND = 'fund';
  static const String MODULE_PORTFOLIO = 'portfolio';
  static const String MODULE_SEARCH = 'search';
  static const String MODULE_USER = 'user';
  static const String MODULE_MARKET = 'market';

  // 类型常量
  static const String TYPE_DETAIL = 'detail';
  static const String TYPE_RANKING = 'ranking';
  static const String TYPE_COMPARISON = 'comparison';
  static const String TYPE_HOLDINGS = 'holdings';
  static const String TYPE_RESULTS = 'results';
  static const String TYPE_HISTORY = 'history';
  static const String TYPE_FAVORITES = 'favorites';
  static const String TYPE_PREFERENCES = 'preferences';

  // 版本常量
  static const String VERSION_V1 = 'v1';
  static const String VERSION_V2 = 'v2';
}

class KeyComponents {
  final String module;
  final String type;
  final String identifier;
  final String version;

  const KeyComponents({
    required this.module,
    required this.type,
    required this.identifier,
    this.version = CacheKeyConstants.VERSION_V1,
  });

  @override
  String toString() => '$module:$type:$identifier:$version';
}
```

#### 1.2 实现类
```dart
class CacheKeyManagerImpl implements CacheKeyManager {
  final KeyValidator _validator;
  final ConflictDetector _conflictDetector;
  final KeyParser _parser;
  final CacheKeyRepository _repository;

  CacheKeyManagerImpl({
    required KeyValidator validator,
    required ConflictDetector conflictDetector,
    required KeyParser parser,
    required CacheKeyRepository repository,
  }) : _validator = validator,
       _conflictDetector = conflictDetector,
       _parser = parser,
       _repository = repository;

  @override
  String generateKey(String module, String type, String identifier, {String version = 'v1'}) {
    // 输入验证
    _validateInputs(module, type, identifier);

    // 格式标准化
    final normalizedModule = _normalizeModule(module);
    final normalizedType = _normalizeType(type);
    final normalizedIdentifier = _normalizeIdentifier(identifier);
    final normalizedVersion = _normalizeVersion(version);

    // 生成键
    final key = '$normalizedModule:$normalizedType:$normalizedIdentifier:$normalizedVersion';

    // 验证生成的键
    if (!_validator.validate(key)) {
      throw CacheKeyException('Invalid cache key generated: $key');
    }

    return key;
  }

  @override
  bool validateKey(String key) {
    return _validator.validate(key);
  }

  @override
  KeyComponents parseKey(String key) {
    if (!_validator.validate(key)) {
      throw CacheKeyException('Invalid cache key format: $key');
    }

    return _parser.parse(key);
  }

  @override
  Future<List<KeyConflict>> detectConflicts(List<String> keys) async {
    return _conflictDetector.detect(keys);
  }

  @override
  List<String> generateBatchKeys(String module, String type, List<String> identifiers) {
    return identifiers
        .map((id) => generateKey(module, type, id))
        .toList();
  }

  // 私有辅助方法
  void _validateInputs(String module, String type, String identifier) {
    if (module.isEmpty) throw ArgumentError('Module cannot be empty');
    if (type.isEmpty) throw ArgumentError('Type cannot be empty');
    if (identifier.isEmpty) throw ArgumentError('Identifier cannot be empty');

    if (module.contains(':') || type.contains(':') || identifier.contains(':')) {
      throw ArgumentError('Inputs cannot contain colon character');
    }
  }

  String _normalizeModule(String module) {
    // 标准化模块名称
    final normalizedModules = {
      'fund': CacheKeyConstants.MODULE_FUND,
      'portfolio': CacheKeyConstants.MODULE_PORTFOLIO,
      'search': CacheKeyConstants.MODULE_SEARCH,
      'user': CacheKeyConstants.MODULE_USER,
      'market': CacheKeyConstants.MODULE_MARKET,
    };

    return normalizedModules[module.toLowerCase()] ?? module.toLowerCase();
  }

  String _normalizeType(String type) {
    // 标准化类型名称
    final normalizedTypes = {
      'detail': CacheKeyConstants.TYPE_DETAIL,
      'ranking': CacheKeyConstants.TYPE_RANKING,
      'comparison': CacheKeyConstants.TYPE_COMPARISON,
      'holdings': CacheKeyConstants.TYPE_HOLDINGS,
      'results': CacheKeyConstants.TYPE_RESULTS,
      'history': CacheKeyConstants.TYPE_HISTORY,
      'favorites': CacheKeyConstants.TYPE_FAVORITES,
      'preferences': CacheKeyConstants.TYPE_PREFERENCES,
    };

    return normalizedTypes[type.toLowerCase()] ?? type.toLowerCase();
  }

  String _normalizeIdentifier(String identifier) {
    // 清理和标准化标识符
    return identifier
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_-]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  String _normalizeVersion(String version) {
    // 标准化版本号
    if (version.isEmpty) return CacheKeyConstants.VERSION_V1;
    return version.toLowerCase().startsWith('v') ? version : 'v$version';
  }
}
```

### 2. 键验证器 (KeyValidator)

#### 2.1 验证规则
```dart
class KeyValidator {
  static final RegExp _keyPattern = RegExp(r'^[a-z]+:[a-z]+:[a-z0-9_-]+:v[0-9]+$');
  static final int _maxKeyLength = 255;
  static final int _maxIdentifierLength = 100;

  bool validate(String key) {
    if (key.isEmpty) return false;
    if (key.length > _maxKeyLength) return false;

    // 格式验证
    if (!_keyPattern.hasMatch(key)) return false;

    // 组件验证
    final components = key.split(':');
    if (components.length != 4) return false;

    final module = components[0];
    final type = components[1];
    final identifier = components[2];
    final version = components[3];

    return _validateModule(module) &&
           _validateType(type) &&
           _validateIdentifier(identifier) &&
           _validateVersion(version);
  }

  bool _validateModule(String module) {
    const validModules = [
      CacheKeyConstants.MODULE_FUND,
      CacheKeyConstants.MODULE_PORTFOLIO,
      CacheKeyConstants.MODULE_SEARCH,
      CacheKeyConstants.MODULE_USER,
      CacheKeyConstants.MODULE_MARKET,
    ];

    return validModules.contains(module);
  }

  bool _validateType(String type) {
    const validTypes = [
      CacheKeyConstants.TYPE_DETAIL,
      CacheKeyConstants.TYPE_RANKING,
      CacheKeyConstants.TYPE_COMPARISON,
      CacheKeyConstants.TYPE_HOLDINGS,
      CacheKeyConstants.TYPE_RESULTS,
      CacheKeyConstants.TYPE_HISTORY,
      CacheKeyConstants.TYPE_FAVORITES,
      CacheKeyConstants.TYPE_PREFERENCES,
    ];

    return validTypes.contains(type);
  }

  bool _validateIdentifier(String identifier) {
    if (identifier.isEmpty) return false;
    if (identifier.length > _maxIdentifierLength) return false;

    // 标识符只能包含字母、数字、下划线和连字符
    return RegExp(r'^[a-z0-9_-]+$').hasMatch(identifier);
  }

  bool _validateVersion(String version) {
    return RegExp(r'^v[0-9]+$').hasMatch(version);
  }

  ValidationResult getValidationDetails(String key) {
    if (key.isEmpty) {
      return ValidationResult(false, 'Key cannot be empty');
    }

    if (key.length > _maxKeyLength) {
      return ValidationResult(false, 'Key length exceeds maximum limit of $_maxKeyLength');
    }

    if (!_keyPattern.hasMatch(key)) {
      return ValidationResult(false, 'Key format does not match required pattern: module:type:identifier:version');
    }

    final components = key.split(':');
    if (components.length != 4) {
      return ValidationResult(false, 'Key must have exactly 4 components separated by colons');
    }

    final module = components[0];
    final type = components[1];
    final identifier = components[2];
    final version = components[3];

    if (!_validateModule(module)) {
      return ValidationResult(false, 'Invalid module: $module');
    }

    if (!_validateType(type)) {
      return ValidationResult(false, 'Invalid type: $type');
    }

    if (!_validateIdentifier(identifier)) {
      return ValidationResult(false, 'Invalid identifier: $identifier');
    }

    if (!_validateVersion(version)) {
      return ValidationResult(false, 'Invalid version: $version');
    }

    return ValidationResult(true, 'Key is valid');
  }
}

class ValidationResult {
  final bool isValid;
  final String message;

  const ValidationResult(this.isValid, this.message);
}
```

### 3. 键解析器 (KeyParser)

```dart
class KeyParser {
  KeyComponents parse(String key) {
    final components = key.split(':');

    if (components.length != 4) {
      throw CacheKeyException('Invalid key format: expected 4 components, got ${components.length}');
    }

    return KeyComponents(
      module: components[0],
      type: components[1],
      identifier: components[2],
      version: components[3],
    );
  }

  Map<String, String> parseToMap(String key) {
    final components = parse(key);

    return {
      'module': components.module,
      'type': components.type,
      'identifier': components.identifier,
      'version': components.version,
      'full_key': key,
    };
  }

  String buildFromComponents(KeyComponents components) {
    return components.toString();
  }
}
```

## 🔄 迁移工具设计

### 1. 迁移引擎 (MigrationEngine)

#### 1.1 接口定义
```dart
abstract class MigrationEngine {
  // 执行键迁移
  Future<MigrationResult> migrateKeys(
    Map<String, String> keyMapping,
    {ProgressCallback? onProgress}
  );

  // 验证迁移结果
  Future<ValidationResult> validateMigration();

  // 回滚迁移
  Future<void> rollbackMigration();

  // 获取迁移状态
  Future<MigrationStatus> getMigrationStatus();

  // 暂停/恢复迁移
  Future<void> pauseMigration();
  Future<void> resumeMigration();
}

class MigrationResult {
  final bool success;
  final int totalKeys;
  final int migratedKeys;
  final int failedKeys;
  final List<MigrationError> errors;
  final Duration duration;

  const MigrationResult({
    required this.success,
    required this.totalKeys,
    required this.migratedKeys,
    required this.failedKeys,
    required this.errors,
    required this.duration,
  });

  double get successRate => totalKeys > 0 ? migratedKeys / totalKeys : 0.0;
}

class MigrationError {
  final String oldKey;
  final String newKey;
  final String error;
  final StackTrace? stackTrace;

  const MigrationError({
    required this.oldKey,
    required this.newKey,
    required this.error,
    this.stackTrace,
  });
}

enum MigrationStatus {
  notStarted,
  inProgress,
  paused,
  completed,
  failed,
  rolledBack,
}
```

#### 1.2 实现类
```dart
class MigrationEngineImpl implements MigrationEngine {
  final CacheKeyRepository _repository;
  final UnifiedHiveCacheManager _cacheManager;
  final ProgressTracker _progressTracker;
  final RollbackManager _rollbackManager;
  final Logger _logger;

  MigrationStatus _status = MigrationStatus.notStarted;
  bool _isPaused = false;

  MigrationEngineImpl({
    required CacheKeyRepository repository,
    required UnifiedHiveCacheManager cacheManager,
    required ProgressTracker progressTracker,
    required RollbackManager rollbackManager,
    required Logger logger,
  }) : _repository = repository,
       _cacheManager = cacheManager,
       _progressTracker = progressTracker,
       _rollbackManager = rollbackManager,
       _logger = logger;

  @override
  Future<MigrationResult> migrateKeys(
    Map<String, String> keyMapping,
    {ProgressCallback? onProgress}
  ) async {
    final stopwatch = Stopwatch()..start();
    _status = MigrationStatus.inProgress;

    try {
      _logger.info('Starting cache key migration with ${keyMapping.length} mappings');

      // 初始化进度跟踪
      await _progressTracker.initialize(keyMapping.length);

      // 创建回滚备份
      await _rollbackManager.createBackup(keyMapping.keys.toList());

      final totalKeys = keyMapping.length;
      int migratedKeys = 0;
      int failedKeys = 0;
      final errors = <MigrationError>[];

      // 批量迁移策略
      const batchSize = 50;
      final batches = _createBatches(keyMapping, batchSize);

      for (int i = 0; i < batches.length; i++) {
        if (_isPaused) {
          _logger.info('Migration paused at batch ${i + 1}/${batches.length}');
          await _waitForResume();
        }

        final batch = batches[i];
        _logger.info('Processing batch ${i + 1}/${batches.length} with ${batch.length} keys');

        // 执行批量迁移
        final batchResult = await _migrateBatch(batch);

        migratedKeys += batchResult.migratedKeys;
        failedKeys += batchResult.failedKeys;
        errors.addAll(batchResult.errors);

        // 更新进度
        await _progressTracker.updateProgress(migratedKeys);
        onProgress?.call(migratedKeys, totalKeys);

        // 批次间短暂休息，避免系统压力
        if (i < batches.length - 1) {
          await Future.delayed(Duration(milliseconds: 100));
        }
      }

      stopwatch.stop();

      final result = MigrationResult(
        success: failedKeys == 0,
        totalKeys: totalKeys,
        migratedKeys: migratedKeys,
        failedKeys: failedKeys,
        errors: errors,
        duration: stopwatch.elapsed,
      );

      if (result.success) {
        _status = MigrationStatus.completed;
        _logger.info('Migration completed successfully in ${stopwatch.elapsed}');

        // 保存迁移记录
        await _saveMigrationRecord(result);
      } else {
        _status = MigrationStatus.failed;
        _logger.warning('Migration completed with $failedKeys failures');
      }

      return result;

    } catch (e, stackTrace) {
      stopwatch.stop();
      _status = MigrationStatus.failed;
      _logger.error('Migration failed: $e', stackTrace);

      // 尝试回滚
      await _rollbackManager.rollback();

      rethrow;
    }
  }

  Future<BatchResult> _migrateBatch(Map<String, String> batch) async {
    int migratedKeys = 0;
    int failedKeys = 0;
    final errors = <MigrationError>[];

    for (final entry in batch.entries) {
      try {
        final oldKey = entry.key;
        final newKey = entry.value;

        // 检查旧键是否存在
        final exists = await _cacheManager.containsKey(oldKey);
        if (!exists) {
          _logger.fine('Old key does not exist: $oldKey');
          migratedKeys++; // 视为成功（无需迁移）
          continue;
        }

        // 检查新键是否已存在（冲突检测）
        final newKeyExists = await _cacheManager.containsKey(newKey);
        if (newKeyExists) {
          _logger.warning('New key already exists: $newKey');
          errors.add(MigrationError(
            oldKey: oldKey,
            newKey: newKey,
            error: 'Target key already exists',
          ));
          failedKeys++;
          continue;
        }

        // 获取数据
        final data = await _cacheManager.get(oldKey);
        if (data == null) {
          _logger.fine('No data found for key: $oldKey');
          migratedKeys++; // 视为成功
          continue;
        }

        // 获取元数据
        final metadata = await _cacheManager.getMetadata(oldKey);

        // 存储到新键
        await _cacheManager.put(newKey, data, metadata: metadata);

        // 验证迁移结果
        final migratedData = await _cacheManager.get(newKey);
        if (migratedData == null) {
          throw CacheMigrationException('Failed to verify migrated data for key: $newKey');
        }

        // 删除旧键（延迟删除，确保迁移成功）
        await _cacheManager.delete(oldKey);

        migratedKeys++;
        _logger.fine('Successfully migrated key: $oldKey -> $newKey');

      } catch (e, stackTrace) {
        _logger.error('Failed to migrate key: ${entry.key}', stackTrace);
        errors.add(MigrationError(
          oldKey: entry.key,
          newKey: entry.value,
          error: e.toString(),
          stackTrace: stackTrace,
        ));
        failedKeys++;
      }
    }

    return BatchResult(
      migratedKeys: migratedKeys,
      failedKeys: failedKeys,
      errors: errors,
    );
  }

  List<Map<String, String>> _createBatches(Map<String, String> keyMapping, int batchSize) {
    final entries = keyMapping.entries.toList();
    final batches = <Map<String, String>>[];

    for (int i = 0; i < entries.length; i += batchSize) {
      final end = (i + batchSize < entries.length) ? i + batchSize : entries.length;
      final batch = Map<String, String>.fromEntries(
        entries.sublist(i, end)
      );
      batches.add(batch);
    }

    return batches;
  }

  Future<void> _waitForResume() async {
    while (_isPaused) {
      await Future.delayed(Duration(milliseconds: 100));
    }
  }

  Future<void> _saveMigrationRecord(MigrationResult result) async {
    final record = MigrationRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      result: result,
      status: _status,
    );

    await _repository.saveMigrationRecord(record);
  }

  @override
  Future<ValidationResult> validateMigration() async {
    // 实现迁移验证逻辑
    // 比较迁移前后的数据完整性
    return ValidationResult(true, 'Migration validation completed successfully');
  }

  @override
  Future<void> rollbackMigration() async {
    _logger.info('Starting migration rollback');
    await _rollbackManager.rollback();
    _status = MigrationStatus.rolledBack;
    _logger.info('Migration rollback completed');
  }

  @override
  Future<MigrationStatus> getMigrationStatus() async {
    return _status;
  }

  @override
  Future<void> pauseMigration() async {
    _isPaused = true;
    _logger.info('Migration paused');
  }

  @override
  Future<void> resumeMigration() async {
    _isPaused = false;
    _logger.info('Migration resumed');
  }
}

class BatchResult {
  final int migratedKeys;
  final int failedKeys;
  final List<MigrationError> errors;

  const BatchResult({
    required this.migratedKeys,
    required this.failedKeys,
    required this.errors,
  });
}

typedef ProgressCallback = void Function(int completed, int total);
```

### 2. 键映射器 (KeyMapper)

```dart
class KeyMapper {
  static const Map<String, String> _predefinedMappings = {
    // 基金相关
    'fund_favorites': 'user:favorites:default',
    'fund_search_history': 'search:history:user',
    'fund_last_viewed': 'user:history:recently_viewed',
    'fund_detail_': 'fund:detail:',
    'fund_rankings_': 'fund:ranking:',
    'fund_comparison_': 'fund:comparison:',
    'filtered_results_': 'fund:filter:results:',

    // 搜索相关
    'search_results_': 'search:results:',
    'search_history_': 'search:history:',
    'search_suggestions_': 'search:suggestions:',
    'popular_searches': 'search:popular:default',

    // 投资组合相关
    'portfolio_holdings_': 'portfolio:holdings:',
    'nav_history_': 'portfolio:nav:history:',
    'profit_metrics_': 'portfolio:profit:metrics:',
    'benchmark_history_': 'portfolio:benchmark:history:',

    // 用户偏好相关
    'fund_display_preferences': 'user:preferences:display',
    'fund_display_preferences_': 'user:preferences:display:',
    'theme_preferences': 'user:preferences:theme',
    'notification_settings': 'user:preferences:notifications',
  };

  Future<Map<String, String>> generateMigrationMapping() async {
    final mapping = <String, String>{};

    // 添加预定义映射
    mapping.addAll(_predefinedMappings);

    // 扫描现有缓存键，生成动态映射
    final existingKeys = await _scanExistingKeys();
    final dynamicMappings = _generateDynamicMappings(existingKeys);
    mapping.addAll(dynamicMappings);

    return mapping;
  }

  Future<List<String>> _scanExistingKeys() async {
    // 扫描所有缓存系统的键
    final allKeys = <String>[];

    // 扫描 UnifiedHiveCacheManager
    final unifiedKeys = await _scanUnifiedCache();
    allKeys.addAll(unifiedKeys);

    // 扫描 SharedPreferences
    final prefKeys = await _scanSharedPreferences();
    allKeys.addAll(prefKeys);

    // 扫描其他缓存系统
    final otherKeys = await _scanOtherCaches();
    allKeys.addAll(otherKeys);

    return allKeys.toSet().toList();
  }

  Future<List<String>> _scanUnifiedCache() async {
    // 实现统一缓存扫描逻辑
    return []; // 占位符实现
  }

  Future<List<String>> _scanSharedPreferences() async {
    // 实现 SharedPreferences 扫描逻辑
    return []; // 占位符实现
  }

  Future<List<String>> _scanOtherCaches() async {
    // 实现其他缓存系统扫描逻辑
    return []; // 占位符实现
  }

  Map<String, String> _generateDynamicMappings(List<String> existingKeys) {
    final mappings = <String, String>{};

    for (final key in existingKeys) {
      final newKey = _generateNewKey(key);
      if (newKey != null && newKey != key) {
        mappings[key] = newKey;
      }
    }

    return mappings;
  }

  String? _generateNewKey(String oldKey) {
    // 基于旧键生成新键的逻辑
    if (oldKey.startsWith('fund_detail_')) {
      final fundCode = oldKey.substring(12); // 移除 'fund_detail_' 前缀
      return 'fund:detail:$fundCode';
    }

    if (oldKey.startsWith('fund_rankings_')) {
      final identifier = oldKey.substring(13); // 移除 'fund_rankings_' 前缀
      return 'fund:ranking:$identifier';
    }

    if (oldKey.startsWith('search_results_')) {
      final query = oldKey.substring(14); // 移除 'search_results_' 前缀
      return 'search:results:$query';
    }

    // 更多映射规则...

    return null; // 无法映射的键保持不变
  }

  Future<String?> findConflictingKey(String newKey) async {
    // 检查新键是否与现有键冲突
    final existingKeys = await _scanExistingKeys();
    return existingKeys.firstWhereOrNull((key) => key == newKey);
  }
}
```

## 🔍 冲突检测和解决机制

### 1. 冲突检测器 (ConflictDetector)

```dart
class ConflictDetector {
  final CacheKeyRepository _repository;
  final Logger _logger;

  ConflictDetector({
    required CacheKeyRepository repository,
    required Logger logger,
  }) : _repository = repository,
       _logger = logger;

  Future<List<KeyConflict>> detect(List<String> keys) async {
    final conflicts = <KeyConflict>[];

    _logger.info('Starting conflict detection for ${keys.length} keys');

    // 检查格式冲突
    final formatConflicts = await _detectFormatConflicts(keys);
    conflicts.addAll(formatConflicts);

    // 检查语义冲突
    final semanticConflicts = await _detectSemanticConflicts(keys);
    conflicts.addAll(semanticConflicts);

    // 检查命名冲突
    final namingConflicts = await _detectNamingConflicts(keys);
    conflicts.addAll(namingConflicts);

    _logger.info('Conflict detection completed: ${conflicts.length} conflicts found');

    return conflicts;
  }

  Future<List<KeyConflict>> _detectFormatConflicts(List<String> keys) async {
    final conflicts = <KeyConflict>[];
    final validator = KeyValidator();

    for (final key in keys) {
      final validation = validator.getValidationDetails(key);
      if (!validation.isValid) {
        conflicts.add(KeyConflict(
          type: ConflictType.format,
          key: key,
          description: validation.message,
          severity: ConflictSeverity.high,
        ));
      }
    }

    return conflicts;
  }

  Future<List<KeyConflict>> _detectSemanticConflicts(List<String> keys) async {
    final conflicts = <KeyConflict>[];
    final parser = KeyParser();

    // 检查相同标识符的不同版本
    final identifierMap = <String, List<String>>{};

    for (final key in keys) {
      try {
        final components = parser.parse(key);
        final identifier = '${components.module}:${components.type}:${components.identifier}';

        identifierMap.putIfAbsent(identifier, () => []).add(key);
      } catch (e) {
        // 忽略解析失败的键，这些已经被格式检测捕获
      }
    }

    // 查找具有多个版本的标识符
    for (final entry in identifierMap.entries) {
      if (entry.value.length > 1) {
        conflicts.add(KeyConflict(
          type: ConflictType.version,
          key: entry.value.join(', '),
          description: 'Multiple versions found for identifier: ${entry.key}',
          severity: ConflictSeverity.medium,
          suggestions: _generateVersionResolutionSuggestions(entry.value),
        ));
      }
    }

    return conflicts;
  }

  Future<List<KeyConflict>> _detectNamingConflicts(List<String> keys) async {
    final conflicts = <KeyConflict>[];

    // 检查重复键
    final keySet = <String>{};
    for (final key in keys) {
      if (keySet.contains(key)) {
        conflicts.add(KeyConflict(
          type: ConflictType.duplicate,
          key: key,
          description: 'Duplicate key found',
          severity: ConflictSeverity.high,
        ));
      } else {
        keySet.add(key);
      }
    }

    // 检查相似的键（可能的拼写错误）
    final similarKeys = _findSimilarKeys(keys);
    for (final pair in similarKeys) {
      conflicts.add(KeyConflict(
        type: ConflictType.similarity,
        key: '${pair.item1} / ${pair.item2}',
        description: 'Similar keys detected, possible typo',
        severity: ConflictSeverity.low,
      ));
    }

    return conflicts;
  }

  List<Tuple2<String, String>> _findSimilarKeys(List<String> keys) {
    final similarKeys = <Tuple2<String, String>>[];
    const similarityThreshold = 0.8;

    for (int i = 0; i < keys.length; i++) {
      for (int j = i + 1; j < keys.length; j++) {
        final similarity = _calculateSimilarity(keys[i], keys[j]);
        if (similarity >= similarityThreshold) {
          similarKeys.add(Tuple2(keys[i], keys[j]));
        }
      }
    }

    return similarKeys;
  }

  double _calculateSimilarity(String s1, String s2) {
    // 使用 Levenshtein 距离计算相似度
    final distance = _levenshteinDistance(s1, s2);
    final maxLength = math.max(s1.length, s2.length);
    return 1.0 - (distance / maxLength);
  }

  int _levenshteinDistance(String s1, String s2) {
    final matrix = List<List<int>>.generate(
      s1.length + 1,
      (i) => List<int>.generate(s2.length + 1, (j) => j),
    );

    for (int i = 1; i <= s1.length; i++) {
      matrix[i][0] = i;
      for (int j = 1; j <= s2.length; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = math.min(
          math.min(matrix[i - 1][j] + 1, matrix[i][j - 1] + 1),
          matrix[i - 1][j - 1] + cost,
        );
      }
    }

    return matrix[s1.length][s2.length];
  }

  List<String> _generateVersionResolutionSuggestions(List<String> conflictingKeys) {
    final suggestions = <String>[];

    // 建议1：保留最新版本
    suggestions.add('Keep the latest version and remove older versions');

    // 建议2：合并版本数据
    suggestions.add('Merge data from all versions into the latest version');

    // 建议3：保留所有版本但添加时间戳
    suggestions.add('Keep all versions but add timestamps to differentiate');

    return suggestions;
  }
}

class KeyConflict {
  final ConflictType type;
  final String key;
  final String description;
  final ConflictSeverity severity;
  final List<String> suggestions;

  const KeyConflict({
    required this.type,
    required this.key,
    required this.description,
    required this.severity,
    this.suggestions = const [],
  });

  @override
  String toString() {
    return 'KeyConflict(type: $type, key: $key, description: $description, severity: $severity)';
  }
}

enum ConflictType {
  format,      // 格式错误
  duplicate,   // 重复键
  version,     // 版本冲突
  similarity,  // 相似键
}

enum ConflictSeverity {
  low,         // 低优先级
  medium,      // 中等优先级
  high,        // 高优先级
  critical,    // 严重冲突
}
```

## 📊 进度跟踪和回滚机制

### 1. 进度跟踪器 (ProgressTracker)

```dart
class ProgressTracker {
  final CacheKeyRepository _repository;
  final Logger _logger;

  int _totalItems = 0;
  int _completedItems = 0;
  int _failedItems = 0;
  DateTime? _startTime;
  DateTime? _endTime;
  List<ProgressSnapshot> _snapshots = [];

  ProgressTracker({
    required CacheKeyRepository repository,
    required Logger logger,
  }) : _repository = repository,
       _logger = logger;

  Future<void> initialize(int totalItems) async {
    _totalItems = totalItems;
    _completedItems = 0;
    _failedItems = 0;
    _startTime = DateTime.now();
    _endTime = null;
    _snapshots.clear();

    _logger.info('Progress tracker initialized with $totalItems items');

    // 保存初始状态
    await _saveProgress();
  }

  Future<void> updateProgress(int completedItems) async {
    _completedItems = completedItems;
    _failedItems = _calculateFailedItems();

    // 创建进度快照
    final snapshot = ProgressSnapshot(
      timestamp: DateTime.now(),
      completedItems: _completedItems,
      failedItems: _failedItems,
      totalItems: _totalItems,
      percentage: _calculatePercentage(),
      estimatedTimeRemaining: _estimateTimeRemaining(),
    );

    _snapshots.add(snapshot);

    // 定期保存进度
    if (_snapshots.length % 10 == 0) {
      await _saveProgress();
    }

    _logger.fine('Progress updated: ${snapshot.percentage.toStringAsFixed(1)}%');
  }

  ProgressReport getCurrentProgress() {
    return ProgressReport(
      totalItems: _totalItems,
      completedItems: _completedItems,
      failedItems: _failedItems,
      percentage: _calculatePercentage(),
      startTime: _startTime,
      endTime: _endTime,
      estimatedTimeRemaining: _estimateTimeRemaining(),
      isCompleted: _completedItems >= _totalItems,
      snapshots: List.unmodifiable(_snapshots),
    );
  }

  double _calculatePercentage() {
    if (_totalItems == 0) return 0.0;
    return (_completedItems / _totalItems) * 100;
  }

  int _calculateFailedItems() {
    // 基于错误日志或失败计数器计算失败项目数
    return 0; // 占位符实现
  }

  Duration? _estimateTimeRemaining() {
    if (_startTime == null || _completedItems == 0) return null;

    final elapsed = DateTime.now().difference(_startTime!);
    final itemsPerSecond = _completedItems / elapsed.inSeconds;
    final remainingItems = _totalItems - _completedItems;

    if (itemsPerSecond <= 0) return null;

    final remainingSeconds = remainingItems / itemsPerSecond;
    return Duration(seconds: remainingSeconds.round());
  }

  Future<void> complete() async {
    _endTime = DateTime.now();
    await _saveProgress();
    _logger.info('Progress tracking completed');
  }

  Future<void> _saveProgress() async {
    final progress = getCurrentProgress();
    await _repository.saveMigrationProgress(progress);
  }

  Future<void> loadProgress() async {
    final savedProgress = await _repository.getMigrationProgress();
    if (savedProgress != null) {
      _totalItems = savedProgress.totalItems;
      _completedItems = savedProgress.completedItems;
      _failedItems = savedProgress.failedItems;
      _startTime = savedProgress.startTime;
      _endTime = savedProgress.endTime;
      _snapshots = List.from(savedProgress.snapshots);
    }
  }
}

class ProgressSnapshot {
  final DateTime timestamp;
  final int completedItems;
  final int failedItems;
  final int totalItems;
  final double percentage;
  final Duration? estimatedTimeRemaining;

  const ProgressSnapshot({
    required this.timestamp,
    required this.completedItems,
    required this.failedItems,
    required this.totalItems,
    required this.percentage,
    this.estimatedTimeRemaining,
  });
}

class ProgressReport {
  final int totalItems;
  final int completedItems;
  final int failedItems;
  final double percentage;
  final DateTime? startTime;
  final DateTime? endTime;
  final Duration? estimatedTimeRemaining;
  final bool isCompleted;
  final List<ProgressSnapshot> snapshots;

  const ProgressReport({
    required this.totalItems,
    required this.completedItems,
    required this.failedItems,
    required this.percentage,
    this.startTime,
    this.endTime,
    this.estimatedTimeRemaining,
    required this.isCompleted,
    required this.snapshots,
  });

  Duration? get totalDuration {
    if (startTime == null) return null;
    final end = endTime ?? DateTime.now();
    return end.difference(startTime!);
  }
}
```

### 2. 回滚管理器 (RollbackManager)

```dart
class RollbackManager {
  final CacheKeyRepository _repository;
  final UnifiedHiveCacheManager _cacheManager;
  final Logger _logger;

  BackupData? _currentBackup;

  RollbackManager({
    required CacheKeyRepository repository,
    required UnifiedHiveCacheManager cacheManager,
    required Logger logger,
  }) : _repository = repository,
       _cacheManager = cacheManager,
       _logger = logger;

  Future<void> createBackup(List<String> keysToMigrate) async {
    _logger.info('Creating backup for ${keysToMigrate.length} keys');

    final backupData = <String, BackupItem>{};
    final startTime = DateTime.now();

    for (final key in keysToMigrate) {
      try {
        // 备份原始数据
        final data = await _cacheManager.get(key);
        final metadata = await _cacheManager.getMetadata(key);

        if (data != null) {
          backupData[key] = BackupItem(
            originalKey: key,
            data: data,
            metadata: metadata,
            timestamp: DateTime.now(),
          );
        }

      } catch (e, stackTrace) {
        _logger.warning('Failed to backup key: $key', stackTrace);
        // 继续处理其他键，不让单个备份失败影响整个过程
      }
    }

    _currentBackup = BackupData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: startTime,
      keys: keysToMigrate,
      backupItems: backupData,
      duration: DateTime.now().difference(startTime),
    );

    // 保存备份到持久化存储
    await _saveBackup();

    _logger.info('Backup created successfully: ${backupData.length} items backed up');
  }

  Future<void> rollback() async {
    if (_currentBackup == null) {
      throw CacheMigrationException('No backup available for rollback');
    }

    _logger.info('Starting rollback process for backup: ${_currentBackup!.id}');

    try {
      await _loadBackup(); // 确保使用最新的备份数据

      final backup = _currentBackup!;
      int restoredKeys = 0;
      int failedRestores = 0;

      // 恢复数据
      for (final entry in backup.backupItems.entries) {
        try {
          final key = entry.key;
          final backupItem = entry.value;

          // 检查是否需要删除迁移后的键
          await _cleanupMigratedKeys(key);

          // 恢复原始数据
          await _cacheManager.put(
            key,
            backupItem.data,
            metadata: backupItem.metadata,
          );

          restoredKeys++;

        } catch (e, stackTrace) {
          _logger.error('Failed to restore key: ${entry.key}', stackTrace);
          failedRestores++;
        }
      }

      _logger.info('Rollback completed: $restoredKeys restored, $failedRestores failed');

      if (failedRestores > 0) {
        _logger.warning('Rollback completed with $failedRestores failures');
      }

    } catch (e, stackTrace) {
      _logger.error('Rollback failed: $e', stackTrace);
      rethrow;
    }
  }

  Future<void> _cleanupMigratedKeys(String originalKey) async {
    // 查找并删除可能已迁移的键
    final mapper = KeyMapper();
    final migrationMapping = await mapper.generateMigrationMapping();

    final migratedKey = migrationMapping[originalKey];
    if (migratedKey != null && migratedKey != originalKey) {
      try {
        final exists = await _cacheManager.containsKey(migratedKey);
        if (exists) {
          await _cacheManager.delete(migratedKey);
          _logger.fine('Deleted migrated key: $migratedKey');
        }
      } catch (e) {
        _logger.warning('Failed to delete migrated key: $migratedKey', e);
      }
    }
  }

  Future<void> _saveBackup() async {
    if (_currentBackup != null) {
      await _repository.saveBackupData(_currentBackup!);
    }
  }

  Future<void> _loadBackup() async {
    final latestBackup = await _repository.getLatestBackupData();
    if (latestBackup != null) {
      _currentBackup = latestBackup;
    }
  }

  Future<void> cleanupBackup() async {
    if (_currentBackup != null) {
      await _repository.deleteBackupData(_currentBackup!.id);
      _currentBackup = null;
      _logger.info('Backup cleaned up successfully');
    }
  }

  BackupInfo? getBackupInfo() {
    if (_currentBackup == null) return null;

    return BackupInfo(
      id: _currentBackup!.id,
      timestamp: _currentBackup!.timestamp,
      keyCount: _currentBackup!.keys.length,
      itemCount: _currentBackup!.backupItems.length,
      duration: _currentBackup!.duration,
    );
  }
}

class BackupData {
  final String id;
  final DateTime timestamp;
  final List<String> keys;
  final Map<String, BackupItem> backupItems;
  final Duration duration;

  const BackupData({
    required this.id,
    required this.timestamp,
    required this.keys,
    required this.backupItems,
    required this.duration,
  });
}

class BackupItem {
  final String originalKey;
  final dynamic data;
  final CacheMetadata? metadata;
  final DateTime timestamp;

  const BackupItem({
    required this.originalKey,
    required this.data,
    this.metadata,
    required this.timestamp,
  });
}

class BackupInfo {
  final String id;
  final DateTime timestamp;
  final int keyCount;
  final int itemCount;
  final Duration duration;

  const BackupInfo({
    required this.id,
    required this.timestamp,
    required this.keyCount,
    required this.itemCount,
    required this.duration,
  });
}
```

## 🧪 测试策略

### 1. 单元测试

#### 1.1 缓存键管理器测试
```dart
// test/unit/core/cache/key_management/cache_key_manager_test.dart
void main() {
  group('CacheKeyManager', () {
    late CacheKeyManager manager;
    late MockKeyValidator mockValidator;
    late MockConflictDetector mockConflictDetector;
    late MockKeyParser mockParser;
    late MockCacheKeyRepository mockRepository;

    setUp(() {
      mockValidator = MockKeyValidator();
      mockConflictDetector = MockConflictDetector();
      mockParser = MockKeyParser();
      mockRepository = MockCacheKeyRepository();

      manager = CacheKeyManagerImpl(
        validator: mockValidator,
        conflictDetector: mockConflictDetector,
        parser: mockParser,
        repository: mockRepository,
      );
    });

    test('should generate valid cache key', () {
      // Arrange
      when(mockValidator.validate(any)).thenReturn(true);

      // Act
      final key = manager.generateKey('fund', 'detail', '000001');

      // Assert
      expect(key, equals('fund:detail:000001:v1'));
      verify(mockValidator.validate(key)).called(1);
    });

    test('should throw exception for invalid inputs', () {
      // Act & Assert
      expect(
        () => manager.generateKey('', 'detail', '000001'),
        throwsArgumentError,
      );

      expect(
        () => manager.generateKey('fund', '', '000001'),
        throwsArgumentError,
      );

      expect(
        () => manager.generateKey('fund', 'detail', ''),
        throwsArgumentError,
      );
    });

    test('should validate cache key format', () {
      // Arrange
      const validKey = 'fund:detail:000001:v1';
      const invalidKey = 'invalid_key';

      when(mockValidator.validate(validKey)).thenReturn(true);
      when(mockValidator.validate(invalidKey)).thenReturn(false);

      // Act & Assert
      expect(manager.validateKey(validKey), isTrue);
      expect(manager.validateKey(invalidKey), isFalse);
    });

    test('should parse cache key components', () {
      // Arrange
      const key = 'fund:detail:000001:v1';
      final expectedComponents = KeyComponents(
        module: 'fund',
        type: 'detail',
        identifier: '000001',
        version: 'v1',
      );

      when(mockValidator.validate(key)).thenReturn(true);
      when(mockParser.parse(key)).thenReturn(expectedComponents);

      // Act
      final components = manager.parseKey(key);

      // Assert
      expect(components, equals(expectedComponents));
      verify(mockValidator.validate(key)).called(1);
      verify(mockParser.parse(key)).called(1);
    });

    test('should generate batch keys', () {
      // Arrange
      when(mockValidator.validate(any)).thenReturn(true);
      final identifiers = ['000001', '000002', '000003'];

      // Act
      final keys = manager.generateBatchKeys('fund', 'detail', identifiers);

      // Assert
      expect(keys, hasLength(3));
      expect(keys[0], equals('fund:detail:000001:v1'));
      expect(keys[1], equals('fund:detail:000002:v1'));
      expect(keys[2], equals('fund:detail:000003:v1'));
    });
  });
}
```

#### 1.2 键验证器测试
```dart
// test/unit/core/cache/key_management/key_validator_test.dart
void main() {
  group('KeyValidator', () {
    late KeyValidator validator;

    setUp(() {
      validator = KeyValidator();
    });

    test('should validate correct key format', () {
      const validKeys = [
        'fund:detail:000001:v1',
        'user:favorites:default:v1',
        'search:results:tech_funds:v2',
        'portfolio:holdings:user123:v1',
      ];

      for (final key in validKeys) {
        expect(validator.validate(key), isTrue, reason: 'Key should be valid: $key');
      }
    });

    test('should reject invalid key format', () {
      const invalidKeys = [
        '',                           // 空键
        'invalid_key',               // 无格式
        'fund:detail:000001',        // 缺少版本
        'fund:detail:v1',            // 缺少标识符
        'fund:v1',                   // 缺少类型和标识符
        'Fund:Detail:000001:v1',     // 大写字母
        'fund:detail:000001:V1',     // 版本号大写
        'fund:detail:Invalid:Name:v1', // 包含无效字符
        'a:detail:identifier:v1',    // 模块名太短
      ];

      for (final key in invalidKeys) {
        expect(validator.validate(key), isFalse, reason: 'Key should be invalid: $key');
      }
    });

    test('should provide detailed validation feedback', () {
      // Test empty key
      var result = validator.getValidationDetails('');
      expect(result.isValid, isFalse);
      expect(result.message, contains('empty'));

      // Test key that exceeds maximum length
      final longKey = 'fund:detail:${'a' * 300}:v1';
      result = validator.getValidationDetails(longKey);
      expect(result.isValid, isFalse);
      expect(result.message, contains('length'));

      // Test valid key
      const validKey = 'fund:detail:000001:v1';
      result = validator.getValidationDetails(validKey);
      expect(result.isValid, isTrue);
      expect(result.message, contains('valid'));
    });

    test('should validate module names', () {
      const validModules = ['fund', 'portfolio', 'search', 'user', 'market'];
      const invalidModules = ['invalid', 'test', 'module'];

      for (final module in validModules) {
        final key = '$module:detail:000001:v1';
        expect(validator.validate(key), isTrue, reason: 'Module should be valid: $module');
      }

      for (final module in invalidModules) {
        final key = '$module:detail:000001:v1';
        expect(validator.validate(key), isFalse, reason: 'Module should be invalid: $module');
      }
    });
  });
}
```

### 2. 集成测试

```dart
// test/integration/cache_migration_integration_test.dart
void main() {
  group('Cache Migration Integration Tests', () {
    late CacheKeyManager keyManager;
    late MigrationEngine migrationEngine;
    late KeyMapper keyMapper;
    late ConflictDetector conflictDetector;
    late TestHiveHelper hiveHelper;

    setUp(() async {
      // 初始化测试环境
      hiveHelper = TestHiveHelper();
      await hiveHelper.setUp();

      // 初始化组件
      final repository = MockCacheKeyRepository();
      final cacheManager = UnifiedHiveCacheManager();
      final progressTracker = ProgressTracker(
        repository: repository,
        logger: MockLogger(),
      );
      final rollbackManager = RollbackManager(
        repository: repository,
        cacheManager: cacheManager,
        logger: MockLogger(),
      );

      keyManager = CacheKeyManagerImpl(
        validator: KeyValidator(),
        conflictDetector: ConflictDetector(
          repository: repository,
          logger: MockLogger(),
        ),
        parser: KeyParser(),
        repository: repository,
      );

      migrationEngine = MigrationEngineImpl(
        repository: repository,
        cacheManager: cacheManager,
        progressTracker: progressTracker,
        rollbackManager: rollbackManager,
        logger: MockLogger(),
      );

      keyMapper = KeyMapper();
      conflictDetector = ConflictDetector(
        repository: repository,
        logger: MockLogger(),
      );
    });

    tearDown(() async {
      await hiveHelper.tearDown();
    });

    test('should perform complete migration workflow', () async {
      // Arrange - 创建测试数据
      final testData = {
        'fund_favorites': ['000001', '000002', '000003'],
        'fund_detail_000001': {'name': 'Test Fund 1', 'code': '000001'},
        'fund_detail_000002': {'name': 'Test Fund 2', 'code': '000002'},
        'search_results_tech': ['000001', '000002'],
      };

      await _createTestData(testData);

      // Act - 执行迁移
      final migrationMapping = await keyMapper.generateMigrationMapping();
      final result = await migrationEngine.migrateKeys(migrationMapping);

      // Assert - 验证迁移结果
      expect(result.success, isTrue);
      expect(result.migratedKeys, greaterThan(0));
      expect(result.failedKeys, equals(0));

      // 验证新键存在
      expect(await cacheManager.containsKey('user:favorites:default'), isTrue);
      expect(await cacheManager.containsKey('fund:detail:000001'), isTrue);
      expect(await cacheManager.containsKey('search:results:tech'), isTrue);

      // 验证旧键不存在
      expect(await cacheManager.containsKey('fund_favorites'), isFalse);
      expect(await cacheManager.containsKey('fund_detail_000001'), isFalse);

      // 验证数据完整性
      final favorites = await cacheManager.get('user:favorites:default');
      expect(favorites, equals(['000001', '000002', '000003']));

      final fundDetail = await cacheManager.get('fund:detail:000001');
      expect(fundDetail['name'], equals('Test Fund 1'));
    });

    test('should detect and handle conflicts', () async {
      // Arrange - 创建冲突数据
      await cacheManager.put('user:favorites:default', ['000001']);
      await cacheManager.put('fund_favorites', ['000002']);

      final keys = ['user:favorites:default', 'fund_favorites'];

      // Act - 检测冲突
      final conflicts = await conflictDetector.detect(keys);

      // Assert - 验证冲突检测
      expect(conflicts, isNotEmpty);
      final conflict = conflicts.firstWhere(
        (c) => c.type == ConflictType.duplicate,
        orElse: () => throw Exception('Expected duplicate conflict not found'),
      );

      expect(conflict.severity, equals(ConflictSeverity.high));
    });

    test('should rollback on migration failure', () async {
      // Arrange - 创建测试数据
      await cacheManager.put('fund_favorites', ['000001']);

      // 模拟迁移失败
      final migrationMapping = {'fund_favorites': 'user:favorites:default'};

      // Act & Assert - 执行迁移并验证回滚
      expect(
        () => migrationEngine.migrateKeys(migrationMapping),
        throwsA(isA<CacheMigrationException>()),
      );

      // 验证数据已回滚
      expect(await cacheManager.containsKey('fund_favorites'), isTrue);
      expect(await cacheManager.containsKey('user:favorites:default'), isFalse);
    });

    test('should maintain data integrity during migration', () async {
      // Arrange - 创建复杂数据结构
      final complexData = {
        'portfolio_holdings_user1': {
          'funds': [
            {'code': '000001', 'shares': 1000, 'cost': 1.23},
            {'code': '000002', 'shares': 500, 'cost': 2.45},
          ],
          'timestamp': DateTime.now().toIso8601String(),
          'version': '1.0',
        }
      };

      await _createTestData(complexData);

      // Act - 执行迁移
      final migrationMapping = await keyMapper.generateMigrationMapping();
      final result = await migrationEngine.migrateKeys(migrationMapping);

      // Assert - 验证数据完整性
      expect(result.success, isTrue);

      final migratedData = await cacheManager.get('portfolio:holdings:user1');
      expect(migratedData, isNotNull);
      expect(migratedData['funds'], hasLength(2));
      expect(migratedData['funds'][0]['code'], equals('000001'));
      expect(migratedData['funds'][0]['shares'], equals(1000));
    });
  });

  Future<void> _createTestData(Map<String, dynamic> data) async {
    for (final entry in data.entries) {
      await cacheManager.put(entry.key, entry.value);
    }
  }
}
```

### 3. 性能测试

```dart
// test/performance/cache_migration_performance_test.dart
void main() {
  group('Cache Migration Performance Tests', () {
    late CacheKeyManager keyManager;
    late MigrationEngine migrationEngine;

    setUp(() async {
      // 初始化性能测试环境
      await _setupPerformanceTestEnvironment();
    });

    test('should migrate 10,000 keys within acceptable time', () async {
      // Arrange - 创建大量测试数据
      const keyCount = 10000;
      final testData = _generateLargeTestData(keyCount);
      await _createTestData(testData);

      // Act - 执行迁移并测量性能
      final stopwatch = Stopwatch()..start();

      final migrationMapping = await keyMapper.generateMigrationMapping();
      final mappingTime = stopwatch.elapsed;

      stopwatch.reset();
      final result = await migrationEngine.migrateKeys(migrationMapping);
      final migrationTime = stopwatch.elapsed;

      // Assert - 验证性能指标
      expect(result.success, isTrue);
      expect(result.migratedKeys, equals(keyCount));

      // 性能断言
      expect(mappingTime.inSeconds, lessThan(5)); // 映射生成 < 5秒
      expect(migrationTime.inSeconds, lessThan(30)); // 迁移执行 < 30秒

      // 计算吞吐量
      final throughput = keyCount / migrationTime.inSeconds;
      expect(throughput, greaterThan(300)); // > 300 键/秒

      print('Performance Results:');
      print('  Key Count: $keyCount');
      print('  Mapping Time: ${mappingTime.inMilliseconds}ms');
      print('  Migration Time: ${migrationTime.inMilliseconds}ms');
      print('  Throughput: ${throughput.toStringAsFixed(2)} keys/second');
    });

    test('should handle memory efficiently during migration', () async {
      // Arrange - 创建内存密集型测试数据
      final largeData = _generateMemoryIntensiveData();
      await _createTestData(largeData);

      // Act - 监控内存使用
      final initialMemory = _getCurrentMemoryUsage();

      final migrationMapping = await keyMapper.generateMigrationMapping();
      final afterMappingMemory = _getCurrentMemoryUsage();

      final result = await migrationEngine.migrateKeys(migrationMapping);
      final finalMemory = _getCurrentMemoryUsage();

      // Assert - 验证内存使用效率
      final memoryIncreaseDuringMapping = afterMappingMemory - initialMemory;
      final memoryIncreaseDuringMigration = finalMemory - afterMappingMemory;

      // 内存增长应该在合理范围内
      expect(memoryIncreaseDuringMapping, lessThan(100 * 1024 * 1024)); // < 100MB
      expect(memoryIncreaseDuringMigration, lessThan(200 * 1024 * 1024)); // < 200MB

      print('Memory Usage Results:');
      print('  Initial Memory: ${(initialMemory / 1024 / 1024).toStringAsFixed(2)} MB');
      print('  After Mapping: ${(afterMappingMemory / 1024 / 1024).toStringAsFixed(2)} MB');
      print('  Final Memory: ${(finalMemory / 1024 / 1024).toStringAsFixed(2)} MB');
    });

    test('should maintain performance under concurrent load', () async {
      // Arrange - 创建并发测试
      const concurrentOperations = 10;
      final futures = <Future<MigrationResult>>[];

      // Act - 执行并发迁移
      for (int i = 0; i < concurrentOperations; i++) {
        final testData = _generateTestDataForConcurrency(i);
        await _createTestData(testData);

        futures.add(migrationEngine.migrateKeys(
          await keyMapper.generateMigrationMapping(),
        ));
      }

      final results = await Future.wait(futures);

      // Assert - 验证并发性能
      expect(results, hasLength(concurrentOperations));
      expect(results.every((r) => r.success), isTrue);

      final totalMigrated = results.fold<int>(0, (sum, r) => sum + r.migratedKeys);
      expect(totalMigrated, greaterThan(0));

      print('Concurrency Results:');
      print('  Concurrent Operations: $concurrentOperations');
      print('  Total Keys Migrated: $totalMigrated');
      print('  Average per Operation: ${totalMigrated / concurrentOperations}');
    });
  });
}
```

## 📈 性能优化策略

### 1. 批处理优化

```dart
class BatchOptimizationStrategy {
  static const int DEFAULT_BATCH_SIZE = 50;
  static const int MAX_BATCH_SIZE = 200;
  static const int MIN_BATCH_SIZE = 10;

  static int calculateOptimalBatchSize(
    int totalItems,
    int availableMemoryMB,
    int processingCores,
  ) {
    // 基于内存容量计算批次大小
    int memoryBasedSize = (availableMemoryMB * 0.1).round();
    memoryBasedSize = memoryBasedSize.clamp(MIN_BATCH_SIZE, MAX_BATCH_SIZE);

    // 基于CPU核心数计算批次大小
    int cpuBasedSize = processingCores * 25;
    cpuBasedSize = cpuBasedSize.clamp(MIN_BATCH_SIZE, MAX_BATCH_SIZE);

    // 基于总数据量调整
    int dataBasedSize = totalItems < 1000 ? MIN_BATCH_SIZE :
                       totalItems < 10000 ? DEFAULT_BATCH_SIZE :
                       MAX_BATCH_SIZE;

    // 综合考虑所有因素
    final optimalSize = [memoryBasedSize, cpuBasedSize, dataBasedSize].reduce((a, b) => math.min(a, b));

    return optimalSize.clamp(MIN_BATCH_SIZE, MAX_BATCH_SIZE);
  }

  static Duration calculateOptimalDelay(int batchSize, int processingTimeMs) {
    // 基于处理时间计算批次间延迟
    if (processingTimeMs < 100) return Duration.zero; // 快速处理无需延迟
    if (processingTimeMs < 500) return Duration(milliseconds: 10); // 中等处理短暂延迟
    return Duration(milliseconds: 50); // 慢速处理较长延迟
  }
}
```

### 2. 内存优化

```dart
class MemoryOptimizationManager {
  static const int MEMORY_THRESHOLD_MB = 512;
  static const int CRITICAL_MEMORY_THRESHOLD_MB = 768;

  Timer? _memoryMonitorTimer;
  final List<MemoryPressureCallback> _callbacks = [];

  void startMonitoring() {
    _memoryMonitorTimer = Timer.periodic(Duration(seconds: 5), (_) {
      _checkMemoryPressure();
    });
  }

  void stopMonitoring() {
    _memoryMonitorTimer?.cancel();
    _memoryMonitorTimer = null;
  }

  void addMemoryPressureCallback(MemoryPressureCallback callback) {
    _callbacks.add(callback);
  }

  void _checkMemoryPressure() {
    final currentMemory = _getCurrentMemoryUsage();
    final memoryMB = currentMemory / 1024 / 1024;

    if (memoryMB > CRITICAL_MEMORY_THRESHOLD_MB) {
      _handleCriticalMemoryPressure();
    } else if (memoryMB > MEMORY_THRESHOLD_MB) {
      _handleModerateMemoryPressure();
    }
  }

  void _handleCriticalMemoryPressure() {
    _logger.warning('Critical memory pressure detected');

    // 触发垃圾回收
    _triggerGarbageCollection();

    // 通知所有回调
    for (final callback in _callbacks) {
      callback(MemoryPressureLevel.critical);
    }

    // 强制清理缓存
    _clearNonEssentialCaches();
  }

  void _handleModerateMemoryPressure() {
    _logger.info('Moderate memory pressure detected');

    // 通知所有回调
    for (final callback in _callbacks) {
      callback(MemoryPressureLevel.moderate);
    }

    // 轻度清理
    _clearOldCacheData();
  }

  void _triggerGarbageCollection() {
    // 在 Dart 中调用垃圾回收
    // 注意：这不是一个推荐的实践，仅用于极端情况
  }

  void _clearNonEssentialCaches() {
    // 清理非必要缓存
  }

  void _clearOldCacheData() {
    // 清理过期缓存数据
  }

  int _getCurrentMemoryUsage() {
    // 获取当前内存使用量
    return 0; // 占位符实现
  }
}

typedef MemoryPressureCallback = void Function(MemoryPressureLevel level);

enum MemoryPressureLevel {
  normal,
  moderate,
  critical,
}
```

## 📋 部署和监控

### 1. 部署检查清单

```dart
class DeploymentValidator {
  final List<ValidationCheck> _preDeploymentChecks = [
    ValidationCheck(
      name: 'Cache Backup Verification',
      description: 'Verify that all cache data is properly backed up',
      validator: _verifyCacheBackup,
      severity: CheckSeverity.critical,
    ),
    ValidationCheck(
      name: 'Memory Availability Check',
      description: 'Ensure sufficient memory is available for migration',
      validator: _checkMemoryAvailability,
      severity: CheckSeverity.high,
    ),
    ValidationCheck(
      name: 'Disk Space Verification',
      description: 'Verify sufficient disk space for migration data',
      validator: _checkDiskSpace,
      severity: CheckSeverity.high,
    ),
    ValidationCheck(
      name: 'Dependency Compatibility',
      description: 'Check all dependencies are compatible with new cache system',
      validator: _checkDependencyCompatibility,
      severity: CheckSeverity.medium,
    ),
  ];

  Future<DeploymentValidationResult> validateDeployment() async {
    final results = <ValidationResult>[];

    for (final check in _preDeploymentChecks) {
      try {
        final result = await check.validator();
        results.add(result);

        if (!result.passed && check.severity == CheckSeverity.critical) {
          return DeploymentValidationResult(
            canDeploy: false,
            results: results,
            blockingIssue: 'Critical check failed: ${check.name}',
          );
        }
      } catch (e, stackTrace) {
        _logger.error('Validation check failed: ${check.name}', stackTrace);
        results.add(ValidationResult(
          checkName: check.name,
          passed: false,
          message: 'Check execution failed: $e',
        ));
      }
    }

    final canDeploy = results.every((r) => r.passed) ||
                     results.where((r) => !r.passed).every((r) =>
                        _preDeploymentChecks.firstWhere((c) => c.name == r.checkName).severity != CheckSeverity.critical);

    return DeploymentValidationResult(
      canDeploy: canDeploy,
      results: results,
    );
  }

  static Future<ValidationResult> _verifyCacheBackup() async {
    // 实现缓存备份验证逻辑
    return ValidationResult(checkName: 'Cache Backup Verification', passed: true);
  }

  static Future<ValidationResult> _checkMemoryAvailability() async {
    // 实现内存可用性检查
    return ValidationResult(checkName: 'Memory Availability Check', passed: true);
  }

  static Future<ValidationResult> _checkDiskSpace() async {
    // 实现磁盘空间检查
    return ValidationResult(checkName: 'Disk Space Verification', passed: true);
  }

  static Future<ValidationResult> _checkDependencyCompatibility() async {
    // 实现依赖兼容性检查
    return ValidationResult(checkName: 'Dependency Compatibility', passed: true);
  }
}

class ValidationCheck {
  final String name;
  final String description;
  final Future<ValidationResult> Function() validator;
  final CheckSeverity severity;

  const ValidationCheck({
    required this.name,
    required this.description,
    required this.validator,
    required this.severity,
  });
}

class ValidationResult {
  final String checkName;
  final bool passed;
  final String? message;

  const ValidationResult({
    required this.checkName,
    required this.passed,
    this.message,
  });
}

class DeploymentValidationResult {
  final bool canDeploy;
  final List<ValidationResult> results;
  final String? blockingIssue;

  const DeploymentValidationResult({
    required this.canDeploy,
    required this.results,
    this.blockingIssue,
  });
}

enum CheckSeverity {
  low,
  medium,
  high,
  critical,
}
```

### 2. 监控和告警

```dart
class CacheMigrationMonitor {
  final MetricsCollector _metricsCollector;
  final AlertManager _alertManager;
  final Logger _logger;

  CacheMigrationMonitor({
    required MetricsCollector metricsCollector,
    required AlertManager alertManager,
    required Logger logger,
  }) : _metricsCollector = metricsCollector,
       _alertManager = alertManager,
       _logger = logger;

  void startMonitoring() {
    // 监控迁移进度
    _monitorProgress();

    // 监控性能指标
    _monitorPerformance();

    // 监控错误率
    _monitorErrorRate();

    // 监控系统资源
    _monitorSystemResources();
  }

  void _monitorProgress() {
    Timer.periodic(Duration(seconds: 10), (_) {
      final progress = _getCurrentProgress();
      _metricsCollector.recordMetric('migration_progress_percentage', progress.percentage);

      // 检查进度停滞
      if (_isProgressStalled(progress)) {
        _alertManager.sendAlert(
          AlertType.progressStalled,
          'Migration progress appears to be stalled',
          severity: AlertSeverity.warning,
        );
      }
    });
  }

  void _monitorPerformance() {
    Timer.periodic(Duration(seconds: 30), (_) {
      final metrics = _collectPerformanceMetrics();

      _metricsCollector.recordMetric('migration_throughput', metrics.throughput);
      _metricsCollector.recordMetric('memory_usage_mb', metrics.memoryUsageMB);
      _metricsCollector.recordMetric('cpu_usage_percentage', metrics.cpuUsagePercentage);

      // 检查性能异常
      if (metrics.throughput < _getExpectedThroughput() * 0.5) {
        _alertManager.sendAlert(
          AlertType.performanceDegradation,
          'Migration throughput is below expected threshold',
          severity: AlertSeverity.warning,
        );
      }

      if (metrics.memoryUsageMB > MEMORY_THRESHOLD_MB) {
        _alertManager.sendAlert(
          AlertType.highMemoryUsage,
          'Memory usage is above threshold',
          severity: AlertSeverity.critical,
        );
      }
    });
  }

  void _monitorErrorRate() {
    Timer.periodic(Duration(seconds: 15), (_) {
      final errorRate = _calculateErrorRate();
      _metricsCollector.recordMetric('error_rate_percentage', errorRate);

      if (errorRate > ERROR_RATE_THRESHOLD) {
        _alertManager.sendAlert(
          AlertType.highErrorRate,
          'Error rate is above threshold: ${errorRate.toStringAsFixed(2)}%',
          severity: AlertSeverity.critical,
        );
      }
    });
  }

  void _monitorSystemResources() {
    Timer.periodic(Duration(minutes: 1), (_) {
      final systemMetrics = _collectSystemMetrics();

      _metricsCollector.recordMetric('disk_usage_percentage', systemMetrics.diskUsagePercentage);
      _metricsCollector.recordMetric('network_io_bytes', systemMetrics.networkIOBytes);

      if (systemMetrics.diskUsagePercentage > DISK_USAGE_THRESHOLD) {
        _alertManager.sendAlert(
          AlertType.lowDiskSpace,
          'Disk usage is above threshold',
          severity: AlertSeverity.warning,
        );
      }
    });
  }

  ProgressReport _getCurrentProgress() {
    // 获取当前迁移进度
    return ProgressReport(
      totalItems: 0,
      completedItems: 0,
      failedItems: 0,
      percentage: 0.0,
      isCompleted: false,
      snapshots: [],
    );
  }

  bool _isProgressStalled(ProgressReport progress) {
    // 检查进度是否停滞
    return false; // 占位符实现
  }

  PerformanceMetrics _collectPerformanceMetrics() {
    // 收集性能指标
    return PerformanceMetrics(
      throughput: 0.0,
      memoryUsageMB: 0,
      cpuUsagePercentage: 0.0,
    );
  }

  double _getExpectedThroughput() {
    // 获取预期吞吐量
    return 300.0; // 键/秒
  }

  double _calculateErrorRate() {
    // 计算错误率
    return 0.0;
  }

  SystemMetrics _collectSystemMetrics() {
    // 收集系统指标
    return SystemMetrics(
      diskUsagePercentage: 0.0,
      networkIOBytes: 0,
    );
  }
}

class PerformanceMetrics {
  final double throughput; // 键/秒
  final int memoryUsageMB;
  final double cpuUsagePercentage;

  const PerformanceMetrics({
    required this.throughput,
    required this.memoryUsageMB,
    required this.cpuUsagePercentage,
  });
}

class SystemMetrics {
  final double diskUsagePercentage;
  final int networkIOBytes;

  const SystemMetrics({
    required this.diskUsagePercentage,
    required this.networkIOBytes,
  });
}

enum AlertType {
  progressStalled,
  performanceDegradation,
  highMemoryUsage,
  highErrorRate,
  lowDiskSpace,
}

enum AlertSeverity {
  info,
  warning,
  critical,
}
```

## 📚 文档和维护

### 1. API 文档

```dart
/// 缓存键管理器
///
/// 提供统一的缓存键生成、验证、解析和管理功能。
///
/// 使用示例：
/// ```dart
/// final manager = CacheKeyManagerImpl();
///
/// // 生成缓存键
/// final key = manager.generateKey('fund', 'detail', '000001');
/// print(key); // 输出: fund:detail:000001:v1
///
/// // 验证缓存键
/// final isValid = manager.validateKey('fund:detail:000001:v1');
///
/// // 解析缓存键
/// final components = manager.parseKey('fund:detail:000001:v1');
/// print(components.module); // 输出: fund
/// ```
///
/// 注意事项：
/// - 所有组件参数都应该是小写字母
/// - 标识符只能包含小写字母、数字、下划线和连字符
/// - 版本号格式为 'v' + 数字，例如 'v1', 'v2'
class CacheKeyManager {
  /// 生成标准格式的缓存键
  ///
  /// [module] 模块名称，必须是预定义的模块常量之一
  /// [type] 类型名称，必须是预定义的类型常量之一
  /// [identifier] 标识符，用于唯一标识缓存项
  /// [version] 版本号，默认为 'v1'
  ///
  /// 返回格式为 `module:type:identifier:version` 的缓存键
  ///
  /// 抛出 [ArgumentError] 当输入参数无效时
  /// 抛出 [CacheKeyException] 当生成的键格式无效时
  String generateKey(String module, String type, String identifier, {String version = 'v1'});

  /// 验证缓存键格式是否正确
  ///
  /// [key] 要验证的缓存键
  ///
  /// 返回 `true` 如果键格式正确，否则返回 `false`
  bool validateKey(String key);

  /// 解析缓存键的各个组件
  ///
  /// [key] 要解析的缓存键
  ///
  /// 返回包含模块、类型、标识符和版本信息的 [KeyComponents] 对象
  ///
  /// 抛出 [CacheKeyException] 当键格式无效时
  KeyComponents parseKey(String key);

  /// 检测一组键中的冲突
  ///
  /// [keys] 要检测冲突的键列表
  ///
  /// 返回检测到的冲突列表
  Future<List<KeyConflict>> detectConflicts(List<String> keys);

  /// 批量生成缓存键
  ///
  /// [module] 模块名称
  /// [type] 类型名称
  /// [identifiers] 标识符列表
  ///
  /// 返回生成的缓存键列表
  List<String> generateBatchKeys(String module, String type, List<String> identifiers);
}
```

### 2. 故障排除指南

```markdown
# 缓存键迁移故障排除指南

## 常见问题

### 1. 迁移过程中出现内存不足错误

**症状**: 迁移过程中收到 `OutOfMemoryError` 或系统变得非常缓慢

**解决方案**:
1. 减小批次大小：将 `DEFAULT_BATCH_SIZE` 从 50 减小到 20
2. 增加批次间延迟：设置 `batchDelay` 为 `Duration(milliseconds: 200)`
3. 启用内存监控：确保 `MemoryOptimizationManager` 正在运行
4. 关闭其他应用程序释放内存

**预防措施**:
- 在迁移前评估数据量大小
- 确保系统有足够的可用内存（建议至少 2GB 可用内存）

### 2. 迁移速度过慢

**症状**: 迁移进度缓慢，吞吐量低于预期

**诊断步骤**:
1. 检查 CPU 使用率
2. 监控磁盘 I/O
3. 检查网络连接（如果涉及远程缓存）
4. 查看错误日志

**解决方案**:
1. 增加批次大小（如果内存允许）
2. 减少批次间延迟
3. 启用并行处理
4. 检查存储性能

### 3. 迁移后数据不一致

**症状**: 迁移完成后的数据与原始数据不匹配

**诊断步骤**:
1. 检查迁移日志中的错误记录
2. 运行数据完整性验证
3. 比对迁移前后的数据哈希值
4. 检查是否有数据截断或格式转换问题

**解决方案**:
1. 使用备份进行回滚
2. 重新运行迁移，这次启用详细日志
3. 手动修复不一致的数据
4. 更新迁移映射规则

### 4. 冲突检测报告过多问题

**症状**: 冲突检测返回大量冲突，阻止迁移进行

**解决方案**:
1. 优先处理高严重性冲突
2. 检查是否是误报
3. 更新冲突检测规则
4. 手动解决复杂冲突

## 调试工具

### 1. 迁移调试模式

```dart
// 启用详细日志
Logger.root.level = Level.FINE;

// 启用调试模式
final migrationEngine = MigrationEngineImpl(
  // ... 其他参数
  debugMode: true,
);

// 运行小批量测试
final testKeys = ['fund_favorites', 'fund_detail_000001'];
final testResult = await migrationEngine.migrateKeys(
  testMapping,
  onProgress: (completed, total) {
    print('Progress: $completed/$total');
  },
);
```

### 2. 数据验证工具

```dart
// 验证数据完整性
final validator = DataIntegrityValidator();
final report = await validator.validateMigration();
print(report.summary);

// 生成数据哈希
final hasher = DataHasher();
final beforeHash = await hasher.calculateHash('old_key');
final afterHash = await hasher.calculateHash('new_key');
print('Hash match: ${beforeHash == afterHash}');
```

## 性能调优

### 1. 批次大小优化

| 数据量 | 推荐批次大小 | 批次间延迟 |
|--------|-------------|-----------|
| < 1,000 键 | 50 | 50ms |
| 1,000-10,000 键 | 100 | 100ms |
| > 10,000 键 | 200 | 200ms |

### 2. 内存优化建议

- 确保至少 1GB 可用内存
- 启用内存压力监控
- 定期触发垃圾回收
- 使用流式处理大数据集

## 监控指标

### 关键指标

1. **迁移吞吐量**: 键/秒，应该 > 300
2. **内存使用率**: 应该 < 80%
3. **错误率**: 应该 < 1%
4. **CPU 使用率**: 应该 < 90%

### 告警阈值

- 吞吐量 < 100 键/秒：警告
- 内存使用率 > 90%：严重
- 错误率 > 5%：严重
- 迁移停滞 > 5 分钟：警告
```

## 📋 实施时间表

### 第一阶段：基础设施 (3-4 天)
- [x] 设计缓存键管理器接口
- [x] 实现键验证器和解析器
- [x] 创建核心数据模型
- [ ] 编写单元测试框架
- [ ] 设置 CI/CD 集成

### 第二阶段：迁移工具 (4-5 天)
- [ ] 实现迁移引擎核心逻辑
- [ ] 开发键映射器
- [ ] 创建冲突检测器
- [ ] 实现进度跟踪器
- [ ] 建立回滚机制

### 第三阶段：集成和测试 (3-4 天)
- [ ] 集成到现有缓存系统
- [ ] 执行集成测试
- [ ] 性能测试和优化
- [ ] 编写集成文档

### 第四阶段：部署和监控 (2-3 天)
- [ ] 创建部署脚本
- [ ] 设置监控和告警
- [ ] 编写操作手册
- [ ] 执行生产环境迁移

**总计**: 12-16 天

## 🎯 成功标准

### 功能性标准
- ✅ 所有现有缓存键成功迁移
- ✅ 零数据丢失
- ✅ 新键命名规范 100% 遵循
- ✅ 冲突检测和解决机制正常工作

### 性能标准
- ✅ 缓存键查找效率提升 ≥ 20%
- ✅ 迁移吞吐量 ≥ 300 键/秒
- ✅ 内存使用优化 ≥ 15%
- ✅ 迁移完成后性能不低于原有水平

### 质量标准
- ✅ 单元测试覆盖率 ≥ 90%
- ✅ 集成测试通过率 100%
- ✅ 代码审查通过
- ✅ 文档完整性检查通过

---

**文档版本**: 1.0
**最后更新**: 2025-10-29
**审核状态**: 待审核
**实施负责人**: 系统架构师
**技术负责人**: 缓存系统团队