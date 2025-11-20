import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yaml/yaml.dart';
import '../base/i_unified_service.dart';
import '../../../core/cache/config/cache_config_manager.dart';
import '../../utils/logger.dart';

/// 统一配置服务
///
/// 整合所有配置相关管理器，提供统一的配置管理功能
/// 支持多层级配置、配置热重载、配置验证、配置版本管理等
///
/// 整合的Manager:
/// - CacheConfigManager: 缓存配置管理
/// - 应用配置管理
/// - 用户偏好配置管理
/// - 环境配置管理
/// - 功能开关配置管理
class UnifiedConfigService implements IUnifiedService {
  // ========== 内部状态 ==========
  @override
  ServiceLifecycleState lifecycleState = ServiceLifecycleState.uninitialized;
  DateTime _startTime = DateTime.now();

  // ========== 服务标识信息 ==========
  @override
  String get serviceName => 'UnifiedConfigService';

  @override
  String get version => '1.0.0';

  @override
  List<String> get dependencies => [];

  @override
  ServiceStats getStats() {
    return ServiceStats(
      serviceName: serviceName,
      version: version,
      uptime: DateTime.now().difference(_startTime),
      memoryUsage:
          _memoryConfig.length + _fileConfig.length + _changeHistory.length,
      customMetrics: {
        'cache_config_manager_initialized': _cacheConfigManager != null,
        'total_listeners':
            _listeners.values.fold(0, (sum, list) => sum + list.length),
        'change_history_size': _changeHistory.length,
        'feature_flags_count': _featureFlags.length,
      },
    );
  }

  @override
  void setLifecycleState(ServiceLifecycleState state) {
    lifecycleState = state;
    if (state == ServiceLifecycleState.initialized) {
      _startTime = DateTime.now();
    }
  }

  // ========== 管理器实例 ==========
  CacheConfigManager? _cacheConfigManager;

  // ========== 服务状态 ==========
  // 注意：lifecycleState 由父类管理，不要在这里重复定义

  // ========== 配置存储 ==========
  SharedPreferences? _sharedPreferences;
  final Map<String, dynamic> _memoryConfig = {};
  final Map<String, dynamic> _fileConfig = {};
  final Map<String, dynamic> _environmentConfig = {};

  // ========== 配置层级 ==========
  static const List<ConfigLevel> _configHierarchy = [
    ConfigLevel.default_,
    ConfigLevel.file,
    ConfigLevel.environment,
    ConfigLevel.user,
    ConfigLevel.memory,
  ];

  // ========== 事件流控制器 ==========
  final StreamController<ConfigEvent> _eventController =
      StreamController<ConfigEvent>.broadcast();

  // ========== 配置监听器 ==========
  final Map<String, List<ConfigListener>> _listeners = {};

  // ========== 配置变更历史 ==========
  final List<ConfigChangeRecord> _changeHistory = [];
  Timer? _historyCleanupTimer;

  // ========== 配置验证规则 ==========
  final Map<String, ConfigValidationRule> _validationRules = {};

  // ========== 配置版本管理 ==========
  ConfigVersion _currentVersion = ConfigVersion(1, 0, 0);
  final Map<String, ConfigMigration> _migrations = {};

  // ========== 配置热重载 ==========
  Timer? _fileWatcherTimer;
  DateTime? _lastFileModified;

  // ========== 功能开关 ==========
  final Map<String, FeatureFlag> _featureFlags = {};

  // ========== 配置 ==========
  final UnifiedConfigServiceConfig _config;

  // ========== 构造函数 ==========
  UnifiedConfigService({
    UnifiedConfigServiceConfig? config,
  }) : _config = config ?? const UnifiedConfigServiceConfig();

  // ========== IUnifiedService 接口实现 ==========
  @override
  Future<void> initialize(ServiceContainer container) async {
    if (lifecycleState == ServiceLifecycleState.initialized) {
      AppLogger.warn('UnifiedConfigService已经初始化');
      return;
    }

    setLifecycleState(ServiceLifecycleState.initializing);
    AppLogger.info('正在初始化UnifiedConfigService...');

    try {
      // 初始化 SharedPreferences
      _sharedPreferences = await SharedPreferences.getInstance();

      // 初始化缓存配置管理器
      await _initializeCacheConfigManager();

      // 加载默认配置
      await _loadDefaultConfig();

      // 加载文件配置
      await _loadFileConfig();

      // 加载环境配置
      await _loadEnvironmentConfig();

      // 加载用户配置
      await _loadUserConfig();

      // 初始化功能开关
      await _initializeFeatureFlags();

      // 初始化配置验证规则
      _initializeValidationRules();

      // 初始化配置迁移
      _initializeMigrations();

      // 启动文件监控（热重载）
      _startFileWatcher();

      // 启动历史清理
      _startHistoryCleanup();

      setLifecycleState(ServiceLifecycleState.initialized);
      AppLogger.info('UnifiedConfigService初始化完成');
      _emitEvent(ConfigEvent.serviceInitialized());
    } catch (e) {
      setLifecycleState(ServiceLifecycleState.error);
      AppLogger.error('UnifiedConfigService初始化失败', e);
      _emitEvent(ConfigEvent.error(e.toString()));
      rethrow;
    }
  }

  @override
  Future<void> dispose() async {
    if (lifecycleState == ServiceLifecycleState.disposed) return;

    setLifecycleState(ServiceLifecycleState.disposing);
    AppLogger.info('正在关闭UnifiedConfigService...');

    try {
      // 停止文件监控
      _fileWatcherTimer?.cancel();

      // 停止历史清理
      _historyCleanupTimer?.cancel();

      // 释放缓存配置管理器
      // CacheConfigManager 没有dispose方法，直接置空
      _cacheConfigManager = null;

      // 关闭事件流
      await _eventController.close();

      // 清理监听器
      _listeners.clear();

      // 清理内存缓存
      _memoryConfig.clear();

      setLifecycleState(ServiceLifecycleState.disposed);
      AppLogger.info('UnifiedConfigService已关闭');
    } catch (e) {
      AppLogger.error('关闭UnifiedConfigService时出错', e);
    }
  }

  @override
  Future<ServiceHealthStatus> checkHealth() async {
    if (lifecycleState != ServiceLifecycleState.initialized) {
      return ServiceHealthStatus(
        isHealthy: false,
        message: 'Service未初始化或已关闭: ${lifecycleState.name}',
        lastCheck: DateTime.now(),
      );
    }

    final healthIssues = <String>[];

    try {
      // 检查 SharedPreferences
      if (_sharedPreferences == null) {
        healthIssues.add('SharedPreferences未初始化');
      }

      // 检查配置文件访问
      if (!await _isConfigFileAccessible()) {
        healthIssues.add('配置文件无法访问');
      }

      // 检查变更历史大小
      if (_changeHistory.length > _config.maxHistorySize) {
        healthIssues.add('配置变更历史过大: ${_changeHistory.length}');
      }

      // 检查监听器数量
      final listenerCount =
          _listeners.values.fold(0, (sum, list) => sum + list.length);
      if (listenerCount > _config.maxListeners) {
        healthIssues.add('配置监听器过多: $listenerCount');
      }

      if (healthIssues.isNotEmpty) {
        return ServiceHealthStatus(
          isHealthy: false,
          message: '配置服务健康检查失败: ${healthIssues.join('; ')}',
          lastCheck: DateTime.now(),
          details: {'issues': healthIssues},
        );
      }

      AppLogger.debug('UnifiedConfigService健康检查通过');
      return ServiceHealthStatus(
        isHealthy: true,
        message: 'Service is healthy',
        lastCheck: DateTime.now(),
      );
    } catch (e) {
      AppLogger.error('UnifiedConfigService健康检查失败', e);
      return ServiceHealthStatus(
        isHealthy: false,
        message: 'Health check failed: $e',
        lastCheck: DateTime.now(),
      );
    }
  }

  // ========== 公共API方法 ==========

  /// 获取配置值
  Future<T?> getConfig<T>(String key, {T? defaultValue}) async {
    _ensureInitialized();

    try {
      // 按照配置层级优先级查找
      for (final level in _configHierarchy) {
        final value = _getConfigFromLevel<T>(key, level);
        if (value != null) {
          // 验证配置值
          if (_validateConfig(key, value)) {
            return value;
          }
        }
      }

      return defaultValue;
    } catch (e) {
      AppLogger.error('获取配置失败', '$key: $e');
      return defaultValue;
    }
  }

  /// 设置配置值
  Future<bool> setConfig<T>(
    String key,
    T value, {
    ConfigLevel level = ConfigLevel.user,
    bool persist = true,
  }) async {
    _ensureInitialized();

    try {
      // 验证配置值
      if (!_validateConfig(key, value)) {
        AppLogger.error('配置值验证失败', '$key: $value');
        return false;
      }

      final oldValue = await getConfig<T>(key);

      // 根据层级存储配置
      switch (level) {
        case ConfigLevel.memory:
          _memoryConfig[key] = value;
          break;
        case ConfigLevel.user:
          if (persist) {
            await _saveUserConfig(key, value);
          } else {
            _memoryConfig[key] = value;
          }
          break;
        case ConfigLevel.file:
          await _saveFileConfig(key, value);
          break;
        case ConfigLevel.environment:
          // 环境配置不允许修改
          AppLogger.warn('环境配置不允许修改', level.toString());
          return false;
        case ConfigLevel.default_:
          // 默认配置不允许修改
          AppLogger.warn('默认配置不允许修改', level.toString());
          return false;
      }

      // 记录变更历史
      _recordConfigChange(key, oldValue, value, level);

      // 通知监听器
      _notifyListeners(key, value, oldValue);

      AppLogger.debug('配置已更新', '$key = $value (${level.toString()})');
      _emitEvent(ConfigEvent.configChanged(key, value, oldValue));

      return true;
    } catch (e) {
      AppLogger.error('设置配置失败', '$key: $e');
      return false;
    }
  }

  /// 删除配置
  Future<bool> removeConfig(String key,
      {ConfigLevel level = ConfigLevel.user}) async {
    _ensureInitialized();

    try {
      final oldValue = await getConfig(key);
      if (oldValue == null) return true;

      bool removed = false;

      switch (level) {
        case ConfigLevel.memory:
          removed = _memoryConfig.remove(key) != null;
          break;
        case ConfigLevel.user:
          removed = await _removeUserConfig(key);
          break;
        case ConfigLevel.file:
          removed = await _removeFileConfig(key);
          break;
        case ConfigLevel.environment:
          // 环境配置不允许删除
          AppLogger.warn('环境配置不允许删除', level.toString());
          return false;
        case ConfigLevel.default_:
          // 默认配置不允许删除
          AppLogger.warn('默认配置不允许删除', level.toString());
          return false;
      }

      if (removed) {
        _recordConfigChange(key, oldValue, null, level);
        _notifyListeners(key, null, oldValue);

        AppLogger.debug('配置已删除', '$key (${level.toString()})');
        _emitEvent(ConfigEvent.configRemoved(key, oldValue));
      }

      return removed;
    } catch (e) {
      AppLogger.error('删除配置失败', '$key: $e');
      return false;
    }
  }

  /// 批量获取配置
  Future<Map<String, dynamic>> getConfigBatch(List<String> keys) async {
    _ensureInitialized();

    final result = <String, dynamic>{};

    for (final key in keys) {
      final value = await getConfig(key);
      if (value != null) {
        result[key] = value;
      }
    }

    return result;
  }

  /// 批量设置配置
  Future<bool> setConfigBatch(
    Map<String, dynamic> configs, {
    ConfigLevel level = ConfigLevel.user,
    bool persist = true,
  }) async {
    _ensureInitialized();

    try {
      for (final entry in configs.entries) {
        final success = await setConfig(
          entry.key,
          entry.value,
          level: level,
          persist: persist,
        );

        if (!success) {
          AppLogger.warn('批量设置配置失败', entry.key);
        }
      }

      return true;
    } catch (e) {
      AppLogger.error('批量设置配置失败', e);
      return false;
    }
  }

  /// 添加配置监听器
  void addConfigListener(String key, ConfigListener listener) {
    _ensureInitialized();

    _listeners.putIfAbsent(key, () => []).add(listener);
    AppLogger.debug('添加配置监听器', key);
  }

  /// 移除配置监听器
  void removeConfigListener(String key, ConfigListener listener) {
    _listeners[key]?.remove(listener);
    if (_listeners[key]?.isEmpty == true) {
      _listeners.remove(key);
    }
    AppLogger.debug('移除配置监听器', key);
  }

  /// 获取功能开关状态
  bool isFeatureEnabled(String featureName) {
    _ensureInitialized();

    final flag = _featureFlags[featureName];
    return flag?.enabled ?? false;
  }

  /// 设置功能开关
  Future<void> setFeatureFlag(String featureName, bool enabled) async {
    _ensureInitialized();

    final oldFlag = _featureFlags[featureName];
    final newFlag = FeatureFlag(
      name: featureName,
      enabled: enabled,
      updatedAt: DateTime.now(),
    );

    _featureFlags[featureName] = newFlag;

    await setConfig('feature_flag_$featureName', enabled);

    AppLogger.info('功能开关已更新', '$featureName: $enabled');
    _emitEvent(
        ConfigEvent.featureFlagChanged(featureName, enabled, oldFlag?.enabled));
  }

  /// 导出配置
  Future<Map<String, dynamic>> exportConfig({
    List<ConfigLevel>? levels,
    List<String>? keys,
  }) async {
    _ensureInitialized();

    final exportLevels = levels ?? _configHierarchy;
    final result = <String, dynamic>{};

    for (final level in exportLevels) {
      final config = await _getAllConfigFromLevel(level);
      result[level.toString()] = config;
    }

    return result;
  }

  /// 导入配置
  Future<bool> importConfig(Map<String, dynamic> configData) async {
    _ensureInitialized();

    try {
      for (final entry in configData.entries) {
        final level = _parseConfigLevel(entry.key);
        if (level != null && entry.value is Map<String, dynamic>) {
          await _setConfigLevel(level, entry.value as Map<String, dynamic>);
        }
      }

      AppLogger.info('配置导入完成');
      _emitEvent(ConfigEvent.configImported());

      return true;
    } catch (e) {
      AppLogger.error('配置导入失败', e);
      return false;
    }
  }

  /// 重置配置到默认值
  Future<bool> resetConfig({String? key}) async {
    _ensureInitialized();

    try {
      if (key != null) {
        final defaultValue = await _getDefaultValue(key);
        return await setConfig(key, defaultValue);
      } else {
        // 重置所有用户配置
        await _resetAllUserConfig();
        AppLogger.info('所有配置已重置到默认值');
        _emitEvent(ConfigEvent.configReset());
        return true;
      }
    } catch (e) {
      AppLogger.error('重置配置失败', e);
      return false;
    }
  }

  /// 获取配置变更历史
  List<ConfigChangeRecord> getChangeHistory({
    String? key,
    DateTime? since,
    int? limit,
  }) {
    var history = _changeHistory;

    if (key != null) {
      history = history.where((record) => record.key == key).toList();
    }

    if (since != null) {
      history =
          history.where((record) => record.timestamp.isAfter(since)).toList();
    }

    if (limit != null && limit > 0) {
      history = history.take(limit).toList();
    }

    return history.reversed.toList();
  }

  /// 获取当前配置版本
  ConfigVersion get currentVersion => _currentVersion;

  /// 执行配置迁移
  Future<bool> migrateConfig(ConfigVersion targetVersion) async {
    _ensureInitialized();

    if (targetVersion <= _currentVersion) {
      AppLogger.warn('目标版本不高于当前版本', targetVersion.toString());
      return true;
    }

    try {
      var currentVersion = _currentVersion;

      while (currentVersion < targetVersion) {
        final nextVersion = currentVersion.nextPatch();
        final migration = _migrations[nextVersion.toString()];

        if (migration != null) {
          AppLogger.info('执行配置迁移', '${currentVersion} -> $nextVersion');
          await migration.migrate(this);
        }

        currentVersion = nextVersion;
      }

      _currentVersion = targetVersion;
      await setConfig('config_version', targetVersion.toString());

      AppLogger.info('配置迁移完成', targetVersion.toString());
      _emitEvent(ConfigEvent.configMigrated(targetVersion));

      return true;
    } catch (e) {
      AppLogger.error('配置迁移失败', e);
      return false;
    }
  }

  // ========== 私有方法 ==========

  void _ensureInitialized() {
    if (lifecycleState != ServiceLifecycleState.initialized) {
      throw StateError('UnifiedConfigService未初始化或已关闭: ${lifecycleState.name}');
    }
  }

  Future<void> _initializeCacheConfigManager() async {
    try {
      _cacheConfigManager = CacheConfigManager();
      // CacheConfigManager 没有initialize方法，构造函数自动初始化

      AppLogger.debug('CacheConfigManager初始化完成');
    } catch (e) {
      AppLogger.error('CacheConfigManager初始化失败', e);
      rethrow;
    }
  }

  Future<void> _loadDefaultConfig() async {
    final defaultConfig = {
      'app_name': '基速基金量化分析平台',
      'version': '1.0.0',
      'debug_mode': false,
      'log_level': 'info',
      'cache_enabled': true,
      'cache_size_mb': 100,
      'request_timeout_seconds': 30,
      'max_retry_attempts': 3,
      'theme_mode': 'system',
      'language': 'zh_CN',
      'auto_update': true,
      'notification_enabled': true,
      'config_version': _currentVersion.toString(),
    };

    _memoryConfig.addAll(defaultConfig);

    AppLogger.debug('默认配置加载完成');
  }

  Future<void> _loadFileConfig() async {
    try {
      final configFile = File(_config.configFilePath);
      if (await configFile.exists()) {
        final content = await configFile.readAsString();
        final yamlData = loadYaml(content);

        if (yamlData is YamlMap) {
          _fileConfig.addAll(_yamlToMap(yamlData));
          AppLogger.debug('文件配置加载完成');
        } else if (yamlData is Map) {
          _fileConfig.addAll(Map<String, dynamic>.from(yamlData));
          AppLogger.debug('文件配置加载完成');
        }
      }
    } catch (e) {
      AppLogger.error('加载文件配置失败', e);
    }
  }

  Future<void> _loadEnvironmentConfig() async {
    try {
      // 这里可以加载环境变量配置
      final envConfig = {
        'api_base_url': Platform.environment['API_BASE_URL'],
        'debug_mode': Platform.environment['DEBUG_MODE'] == 'true',
        'log_level': Platform.environment['LOG_LEVEL'],
      };

      _environmentConfig.addAll(
        Map.fromEntries(
            envConfig.entries.where((entry) => entry.value != null)),
      );

      AppLogger.debug('环境配置加载完成');
    } catch (e) {
      AppLogger.error('加载环境配置失败', e);
    }
  }

  Future<void> _loadUserConfig() async {
    if (_sharedPreferences == null) return;

    try {
      final keys = _sharedPreferences!.getKeys();
      for (final key in keys) {
        if (key.startsWith('config_')) {
          final configKey = key.substring(7); // 移除 'config_' 前缀
          final value = _sharedPreferences!.get(key);
          if (value != null) {
            _memoryConfig[configKey] = value;
          }
        }
      }

      AppLogger.debug('用户配置加载完成');
    } catch (e) {
      AppLogger.error('加载用户配置失败', e);
    }
  }

  Future<void> _initializeFeatureFlags() async {
    final now = DateTime.now();
    final defaultFlags = {
      'advanced_charts':
          FeatureFlag(name: 'advanced_charts', enabled: true, updatedAt: now),
      'real_time_data':
          FeatureFlag(name: 'real_time_data', enabled: true, updatedAt: now),
      'smart_recommendations': FeatureFlag(
          name: 'smart_recommendations', enabled: false, updatedAt: now),
      'beta_features':
          FeatureFlag(name: 'beta_features', enabled: false, updatedAt: now),
      'debug_panel':
          FeatureFlag(name: 'debug_panel', enabled: false, updatedAt: now),
    };

    for (final flag in defaultFlags.values) {
      final enabled =
          await getConfig<bool>('feature_flag_${flag.name}') ?? flag.enabled;
      _featureFlags[flag.name] = flag.copyWith(enabled: enabled);
    }

    AppLogger.debug('功能开关初始化完成');
  }

  void _initializeValidationRules() {
    _validationRules['cache_size_mb'] = ConfigValidationRule(
      type: ConfigValidationType.range,
      min: 10,
      max: 1000,
    );

    _validationRules['request_timeout_seconds'] = ConfigValidationRule(
      type: ConfigValidationType.range,
      min: 5,
      max: 300,
    );

    _validationRules['max_retry_attempts'] = ConfigValidationRule(
      type: ConfigValidationType.range,
      min: 0,
      max: 10,
    );

    _validationRules['theme_mode'] = ConfigValidationRule(
      type: ConfigValidationType.enumeration,
      allowedValues: ['system', 'light', 'dark'],
    );

    _validationRules['language'] = ConfigValidationRule(
      type: ConfigValidationType.pattern,
      pattern: r'^[a-z]{2}_[A-Z]{2}$',
    );

    AppLogger.debug('配置验证规则初始化完成');
  }

  void _initializeMigrations() {
    // 示例迁移
    _migrations['1.1.0'] = ConfigMigration(
      version: ConfigVersion(1, 1, 0),
      description: '添加新的主题配置选项',
      migrate: (service) async {
        await service.setConfig('theme_mode', 'system');
      },
    );

    AppLogger.debug('配置迁移初始化完成');
  }

  T? _getConfigFromLevel<T>(String key, ConfigLevel level) {
    switch (level) {
      case ConfigLevel.memory:
        return _memoryConfig[key] as T?;
      case ConfigLevel.user:
        return _memoryConfig[key] as T?;
      case ConfigLevel.file:
        return _fileConfig[key] as T?;
      case ConfigLevel.environment:
        return _environmentConfig[key] as T?;
      case ConfigLevel.default_:
        return _getDefaultConfigValue<T>(key);
    }
  }

  Future<Map<String, dynamic>> _getAllConfigFromLevel(ConfigLevel level) async {
    switch (level) {
      case ConfigLevel.memory:
      case ConfigLevel.user:
        return Map.from(_memoryConfig);
      case ConfigLevel.file:
        return Map.from(_fileConfig);
      case ConfigLevel.environment:
        return Map.from(_environmentConfig);
      case ConfigLevel.default_:
        return await _getAllDefaultConfig();
    }
  }

  bool _validateConfig(String key, dynamic value) {
    final rule = _validationRules[key];
    if (rule == null) return true;

    return rule.validate(value);
  }

  Future<void> _saveUserConfig<T>(String key, T value) async {
    if (_sharedPreferences == null) return;

    final prefKey = 'config_$key';

    if (value is String) {
      await _sharedPreferences!.setString(prefKey, value);
    } else if (value is int) {
      await _sharedPreferences!.setInt(prefKey, value);
    } else if (value is double) {
      await _sharedPreferences!.setDouble(prefKey, value);
    } else if (value is bool) {
      await _sharedPreferences!.setBool(prefKey, value);
    } else if (value is List) {
      await _sharedPreferences!.setStringList(prefKey, value.cast<String>());
    } else {
      await _sharedPreferences!.setString(prefKey, jsonEncode(value));
    }

    _memoryConfig[key] = value;
  }

  Future<bool> _removeUserConfig(String key) async {
    if (_sharedPreferences == null) return false;

    final prefKey = 'config_$key';
    final removed = await _sharedPreferences!.remove(prefKey);
    _memoryConfig.remove(key);

    return removed;
  }

  Future<void> _saveFileConfig<T>(String key, T value) async {
    _fileConfig[key] = value;
    await _writeConfigToFile();
  }

  Future<bool> _removeFileConfig(String key) async {
    final removed = _fileConfig.remove(key) != null;
    if (removed) {
      await _writeConfigToFile();
    }
    return removed;
  }

  Future<void> _writeConfigToFile() async {
    try {
      final configFile = File(_config.configFilePath);
      final yamlContent = _mapToYaml(_fileConfig);
      await configFile.writeAsString(yamlContent);
    } catch (e) {
      AppLogger.error('写入配置文件失败', e);
    }
  }

  void _recordConfigChange(
      String key, dynamic oldValue, dynamic newValue, ConfigLevel level) {
    final record = ConfigChangeRecord(
      key: key,
      oldValue: oldValue,
      newValue: newValue,
      level: level,
      timestamp: DateTime.now(),
    );

    _changeHistory.add(record);

    // 限制历史记录大小
    if (_changeHistory.length > _config.maxHistorySize) {
      _changeHistory.removeRange(
          0, _changeHistory.length - _config.maxHistorySize);
    }
  }

  void _notifyListeners(String key, dynamic newValue, dynamic oldValue) {
    final listeners = _listeners[key];
    if (listeners != null) {
      for (final listener in listeners) {
        try {
          listener(key, newValue, oldValue);
        } catch (e) {
          AppLogger.error('配置监听器执行失败', '$key: $e');
        }
      }
    }
  }

  void _startFileWatcher() {
    _fileWatcherTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final configFile = File(_config.configFilePath);
        if (await configFile.exists()) {
          final modified = await configFile.lastModified();

          if (_lastFileModified == null ||
              modified.isAfter(_lastFileModified!)) {
            _lastFileModified = modified;
            await _loadFileConfig();
            _emitEvent(ConfigEvent.configReloaded());
          }
        }
      } catch (e) {
        AppLogger.error('文件监控失败', e);
      }
    });
  }

  void _startHistoryCleanup() {
    _historyCleanupTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _cleanupOldHistory();
    });
  }

  void _cleanupOldHistory() {
    final cutoff = DateTime.now().subtract(_config.historyRetentionPeriod);
    final initialCount = _changeHistory.length;

    _changeHistory.removeWhere((record) => record.timestamp.isBefore(cutoff));

    if (_changeHistory.length < initialCount) {
      AppLogger.debug(
          '清理旧配置历史记录', '删除${initialCount - _changeHistory.length}条记录');
    }
  }

  Future<bool> _isConfigFileAccessible() async {
    try {
      final configFile = File(_config.configFilePath);
      return await configFile.exists();
    } catch (e) {
      return false;
    }
  }

  ConfigLevel? _parseConfigLevel(String levelStr) {
    switch (levelStr.toLowerCase()) {
      case 'default_':
        return ConfigLevel.default_;
      case 'file':
        return ConfigLevel.file;
      case 'environment':
        return ConfigLevel.environment;
      case 'user':
        return ConfigLevel.user;
      case 'memory':
        return ConfigLevel.memory;
      default:
        return null;
    }
  }

  Future<void> _setConfigLevel(
      ConfigLevel level, Map<String, dynamic> config) async {
    for (final entry in config.entries) {
      await setConfig(entry.key, entry.value, level: level);
    }
  }

  Future<void> _resetAllUserConfig() async {
    if (_sharedPreferences == null) return;

    final keys = _sharedPreferences!.getKeys();
    for (final key in keys) {
      if (key.startsWith('config_')) {
        await _sharedPreferences!.remove(key);
      }
    }

    _memoryConfig.clear();
    await _loadDefaultConfig();
  }

  T? _getDefaultConfigValue<T>(String key) {
    final defaults = {
      'app_name': '基速基金量化分析平台',
      'version': '1.0.0',
      'debug_mode': false,
      'log_level': 'info',
      'cache_enabled': true,
      'cache_size_mb': 100,
      'request_timeout_seconds': 30,
      'max_retry_attempts': 3,
      'theme_mode': 'system',
      'language': 'zh_CN',
      'auto_update': true,
      'notification_enabled': true,
    };

    return defaults[key] as T?;
  }

  Future<Map<String, dynamic>> _getAllDefaultConfig() async {
    return {
      'app_name': '基速基金量化分析平台',
      'version': '1.0.0',
      'debug_mode': false,
      'log_level': 'info',
      'cache_enabled': true,
      'cache_size_mb': 100,
      'request_timeout_seconds': 30,
      'max_retry_attempts': 3,
      'theme_mode': 'system',
      'language': 'zh_CN',
      'auto_update': true,
      'notification_enabled': true,
    };
  }

  Future<dynamic> _getDefaultValue(String key) async {
    return _getDefaultConfigValue(key);
  }

  Map<String, dynamic> _yamlToMap(YamlMap yamlMap) {
    final result = <String, dynamic>{};

    for (final entry in yamlMap.entries) {
      if (entry.value is YamlMap) {
        result[entry.key.toString()] = _yamlToMap(entry.value as YamlMap);
      } else if (entry.value is YamlList) {
        result[entry.key.toString()] = (entry.value as YamlList).toList();
      } else {
        result[entry.key.toString()] = entry.value;
      }
    }

    return result;
  }

  String _mapToYaml(Map<String, dynamic> map) {
    final buffer = StringBuffer();
    _writeMapToYaml(buffer, map, 0);
    return buffer.toString();
  }

  void _writeMapToYaml(
      StringBuffer buffer, Map<String, dynamic> map, int indent) {
    final spaces = '  ' * indent;

    for (final entry in map.entries) {
      buffer.write('$spaces${entry.key}:');

      if (entry.value is Map) {
        buffer.writeln();
        _writeMapToYaml(
            buffer, entry.value as Map<String, dynamic>, indent + 1);
      } else if (entry.value is List) {
        buffer.writeln();
        for (final item in entry.value as List) {
          buffer.writeln('$spaces  - $item');
        }
      } else if (entry.value is String) {
        buffer.writeln(' ${entry.value}');
      } else {
        buffer.writeln(' ${entry.value}');
      }
    }
  }

  void _emitEvent(ConfigEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  // ========== 事件流 ==========

  /// 配置事件流
  Stream<ConfigEvent> get eventStream => _eventController.stream;
}

// ========== 支持类和枚举 ==========

/// 配置层级
enum ConfigLevel {
  default_, // 默认配置
  file, // 文件配置
  environment, // 环境配置
  user, // 用户配置
  memory, // 内存配置
}

/// 配置事件
class ConfigEvent {
  final String type;
  final String? key;
  final dynamic data;
  final DateTime timestamp;

  ConfigEvent({
    required this.type,
    this.key,
    this.data,
  }) : timestamp = DateTime.now();

  ConfigEvent.withTimestamp({
    required this.type,
    this.key,
    this.data,
    required this.timestamp,
  });

  factory ConfigEvent.serviceInitialized() =>
      ConfigEvent(type: 'service_initialized');
  factory ConfigEvent.configChanged(
          String key, dynamic newValue, dynamic oldValue) =>
      ConfigEvent(
          type: 'config_changed',
          key: key,
          data: {'new': newValue, 'old': oldValue});
  factory ConfigEvent.configRemoved(String key, dynamic oldValue) =>
      ConfigEvent(type: 'config_removed', key: key, data: oldValue);
  factory ConfigEvent.featureFlagChanged(
          String featureName, bool enabled, bool? oldEnabled) =>
      ConfigEvent(
          type: 'feature_flag_changed',
          key: featureName,
          data: {'enabled': enabled, 'old_enabled': oldEnabled});
  factory ConfigEvent.configImported() => ConfigEvent(type: 'config_imported');
  factory ConfigEvent.configReset() => ConfigEvent(type: 'config_reset');
  factory ConfigEvent.configReloaded() => ConfigEvent(type: 'config_reloaded');
  factory ConfigEvent.configMigrated(ConfigVersion version) =>
      ConfigEvent(type: 'config_migrated', data: version.toString());
  factory ConfigEvent.error(String message) =>
      ConfigEvent(type: 'error', data: message);
}

/// 配置监听器
typedef ConfigListener = void Function(
    String key, dynamic newValue, dynamic oldValue);

/// 配置变更记录
class ConfigChangeRecord {
  final String key;
  final dynamic oldValue;
  final dynamic newValue;
  final ConfigLevel level;
  final DateTime timestamp;

  const ConfigChangeRecord({
    required this.key,
    required this.oldValue,
    required this.newValue,
    required this.level,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'key': key,
        'old_value': oldValue,
        'new_value': newValue,
        'level': level.toString(),
        'timestamp': timestamp.toIso8601String(),
      };
}

/// 配置验证类型
enum ConfigValidationType {
  range, // 范围验证
  enumeration, // 枚举验证
  pattern, // 正则表达式验证
  custom, // 自定义验证
}

/// 配置验证规则
class ConfigValidationRule {
  final ConfigValidationType type;
  final dynamic min;
  final dynamic max;
  final List<dynamic>? allowedValues;
  final String? pattern;
  final bool Function(dynamic)? customValidator;

  const ConfigValidationRule({
    required this.type,
    this.min,
    this.max,
    this.allowedValues,
    this.pattern,
    this.customValidator,
  });

  bool validate(dynamic value) {
    switch (type) {
      case ConfigValidationType.range:
        if (value is num) {
          return (min == null || value >= min) && (max == null || value <= max);
        }
        return false;

      case ConfigValidationType.enumeration:
        return allowedValues?.contains(value) ?? false;

      case ConfigValidationType.pattern:
        if (value is String && pattern != null) {
          return RegExp(pattern!).hasMatch(value);
        }
        return false;

      case ConfigValidationType.custom:
        return customValidator?.call(value) ?? true;
    }
  }
}

/// 功能开关
class FeatureFlag {
  final String name;
  final bool enabled;
  final String? description;
  final DateTime updatedAt;

  const FeatureFlag({
    required this.name,
    required this.enabled,
    this.description,
    required this.updatedAt,
  });

  FeatureFlag copyWith({
    bool? enabled,
    String? description,
    DateTime? updatedAt,
  }) {
    return FeatureFlag(
      name: name,
      enabled: enabled ?? this.enabled,
      description: description ?? this.description,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 配置版本
class ConfigVersion {
  final int major;
  final int minor;
  final int patch;

  const ConfigVersion(this.major, this.minor, this.patch);

  @override
  String toString() => '$major.$minor.$patch';

  bool operator <=(ConfigVersion other) {
    if (major != other.major) return major <= other.major;
    if (minor != other.minor) return minor <= other.minor;
    return patch <= other.patch;
  }

  bool operator <(ConfigVersion other) {
    if (major != other.major) return major < other.major;
    if (minor != other.minor) return minor < other.minor;
    return patch < other.patch;
  }

  ConfigVersion nextPatch() => ConfigVersion(major, minor, patch + 1);
}

/// 配置迁移
class ConfigMigration {
  final ConfigVersion version;
  final String description;
  final Future<void> Function(UnifiedConfigService service) migrate;

  const ConfigMigration({
    required this.version,
    required this.description,
    required this.migrate,
  });
}

/// 统一配置服务配置
class UnifiedConfigServiceConfig {
  final String configFilePath;
  final int maxHistorySize;
  final Duration historyRetentionPeriod;
  final int maxListeners;

  const UnifiedConfigServiceConfig({
    this.configFilePath = 'config/app_config.yaml',
    this.maxHistorySize = 1000,
    this.historyRetentionPeriod = const Duration(days: 30),
    this.maxListeners = 100,
  });
}
