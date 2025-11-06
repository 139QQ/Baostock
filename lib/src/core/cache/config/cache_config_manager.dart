/// 缓存配置管理器
///
/// 提供统一的缓存配置管理，包括：
/// - 预定义配置模板
/// - 动态配置调整
/// - 配置验证和约束
/// - 环境感知配置
library cache_config_manager;

import '../interfaces/i_unified_cache_service.dart';

// ============================================================================
// 缓存配置管理器
// ============================================================================

/// 缓存配置管理器
///
/// 负责管理和提供各种缓存配置
class CacheConfigManager {
  // 预定义配置模板
  final Map<String, CacheConfig> _predefinedConfigs = {};

  // 运行时配置覆盖
  final Map<String, CacheConfig> _runtimeOverrides = {};

  // 配置验证器
  final List<ConfigValidator> _validators = [];

  // 当前环境
  final CacheEnvironment _environment;

  CacheConfigManager({
    CacheEnvironment? environment,
  }) : _environment = environment ?? CacheEnvironment.production {
    _initializePredefinedConfigs();
    _initializeValidators();
  }

  /// 获取缓存配置
  CacheConfig getConfig(String configName) {
    // 优先使用运行时覆盖
    if (_runtimeOverrides.containsKey(configName)) {
      return _runtimeOverrides[configName]!;
    }

    // 使用预定义配置
    if (_predefinedConfigs.containsKey(configName)) {
      var config = _predefinedConfigs[configName]!;

      // 根据环境调整配置
      config = _adjustConfigForEnvironment(config);

      return config;
    }

    // 返回默认配置
    return _adjustConfigForEnvironment(CacheConfig.defaultConfig());
  }

  /// 设置运行时配置覆盖
  void setRuntimeOverride(String configName, CacheConfig config) {
    _validateConfig(config);
    _runtimeOverrides[configName] = config;
  }

  /// 移除运行时配置覆盖
  void removeRuntimeOverride(String configName) {
    _runtimeOverrides.remove(configName);
  }

  /// 创建自定义配置
  CacheConfig createCustomConfig({
    Duration? ttl,
    Duration? maxIdleTime,
    int? maxSize,
    int? priority,
    bool? compressible,
    bool? persistent,
    Set<String>? tags,
    String? strategyName,
    Map<String, dynamic>? extensions,
  }) {
    final config = CacheConfig(
      ttl: ttl,
      maxIdleTime: maxIdleTime,
      maxSize: maxSize,
      priority: priority ?? 5,
      compressible: compressible ?? true,
      persistent: persistent ?? true,
      tags: tags ?? {},
      strategyName: strategyName,
      extensions: extensions ?? {},
    );

    _validateConfig(config);
    return _adjustConfigForEnvironment(config);
  }

  /// 根据数据类型创建配置
  CacheConfig createConfigForDataType(
    CacheDataType dataType, {
    Duration? customTtl,
    int? customPriority,
  }) {
    var baseConfig = _getConfigForDataType(dataType);

    // 应用自定义参数
    if (customTtl != null || customPriority != null) {
      baseConfig = baseConfig.copyWith(
        ttl: customTtl,
        priority: customPriority,
      );
    }

    return _adjustConfigForEnvironment(baseConfig);
  }

  /// 获取推荐的配置名称
  String getRecommendedConfig(String key, dynamic data) {
    // 根据键模式推荐配置
    if (key.startsWith('search_')) {
      if (key.contains('results')) {
        return 'search_results';
      } else if (key.contains('suggestions')) {
        return 'search_suggestions';
      } else if (key.contains('history')) {
        return 'search_history';
      }
    } else if (key.startsWith('filter_')) {
      if (key.contains('criteria')) {
        return 'filter_criteria';
      } else if (key.contains('options')) {
        return 'filter_options';
      }
    } else if (key.startsWith('user_')) {
      return 'user_data';
    } else if (key.startsWith('fund_')) {
      if (key.contains('details')) {
        return 'fund_details';
      } else if (key.contains('list')) {
        return 'fund_list';
      }
    } else if (key.startsWith('temp_')) {
      return 'temporary';
    }

    // 默认推荐
    return 'default';
  }

  /// 验证配置
  void _validateConfig(CacheConfig config) {
    for (final validator in _validators) {
      final result = validator.validate(config);
      if (!result.isValid) {
        throw CacheConfigValidationException(
          'Invalid cache configuration: ${result.errors.join(', ')}',
        );
      }
    }
  }

  /// 根据环境调整配置
  CacheConfig _adjustConfigForEnvironment(CacheConfig config) {
    switch (_environment) {
      case CacheEnvironment.development:
        return _adjustForDevelopment(config);
      case CacheEnvironment.testing:
        return _adjustForTesting(config);
      case CacheEnvironment.staging:
        return _adjustForStaging(config);
      case CacheEnvironment.production:
        return _adjustForProduction(config);
    }
  }

  /// 开发环境调整
  CacheConfig _adjustForDevelopment(CacheConfig config) {
    return config.copyWith(
      ttl: config.ttl != null
          ? Duration(minutes: config.ttl!.inMinutes ~/ 2)
          : null,
      maxSize: config.maxSize != null ? config.maxSize! ~/ 2 : null,
      compressible: true, // 开发环境启用压缩以节省空间
    );
  }

  /// 测试环境调整
  CacheConfig _adjustForTesting(CacheConfig config) {
    return config.copyWith(
      ttl: const Duration(seconds: 30), // 测试环境使用短TTL
      maxSize: 1024 * 1024, // 限制最大1MB
      persistent: false, // 测试环境不持久化
    );
  }

  /// 预发布环境调整
  CacheConfig _adjustForStaging(CacheConfig config) {
    return config.copyWith(
      ttl: config.ttl != null
          ? Duration(minutes: config.ttl!.inMinutes ~/ 2)
          : null,
      priority: (config.priority * 0.8).round(),
    );
  }

  /// 生产环境调整
  CacheConfig _adjustForProduction(CacheConfig config) {
    return config.copyWith(
      compressible: true, // 生产环境启用压缩
      persistent: true, // 生产环境启用持久化
    );
  }

  /// 根据数据类型获取基础配置
  CacheConfig _getConfigForDataType(CacheDataType dataType) {
    switch (dataType) {
      case CacheDataType.searchResults:
        return _predefinedConfigs['search_results']!;
      case CacheDataType.searchSuggestions:
        return _predefinedConfigs['search_suggestions']!;
      case CacheDataType.searchHistory:
        return _predefinedConfigs['search_history']!;
      case CacheDataType.filterCriteria:
        return _predefinedConfigs['filter_criteria']!;
      case CacheDataType.filterOptions:
        return _predefinedConfigs['filter_options']!;
      case CacheDataType.userData:
        return _predefinedConfigs['user_data']!;
      case CacheDataType.fundDetails:
        return _predefinedConfigs['fund_details']!;
      case CacheDataType.fundList:
        return _predefinedConfigs['fund_list']!;
      case CacheDataType.temporary:
        return _predefinedConfigs['temporary']!;
      case CacheDataType.systemConfig:
        return _predefinedConfigs['system_config']!;
    }
  }

  /// 初始化预定义配置
  void _initializePredefinedConfigs() {
    // 搜索相关配置
    _predefinedConfigs['search_results'] = const CacheConfig(
      ttl: Duration(minutes: 15),
      priority: 6,
      compressible: true,
      tags: {'search', 'results'},
    );

    _predefinedConfigs['search_suggestions'] = const CacheConfig(
      ttl: Duration(minutes: 30),
      priority: 5,
      compressible: true,
      tags: {'search', 'suggestions'},
    );

    _predefinedConfigs['search_history'] = const CacheConfig(
      ttl: Duration(days: 30), // 搜索历史保留30天
      priority: 3,
      compressible: true,
      tags: {'search', 'history'},
    );

    // 筛选相关配置
    _predefinedConfigs['filter_criteria'] = const CacheConfig(
      ttl: Duration(hours: 2),
      priority: 7,
      compressible: true,
      tags: {'filter', 'criteria'},
    );

    _predefinedConfigs['filter_options'] = const CacheConfig(
      ttl: Duration(hours: 24),
      priority: 4,
      compressible: true,
      tags: {'filter', 'options'},
    );

    // 用户数据配置
    _predefinedConfigs['user_data'] = const CacheConfig(
      ttl: Duration(days: 7),
      priority: 8,
      compressible: true,
      tags: {'user', 'data'},
    );

    // 基金数据配置
    _predefinedConfigs['fund_details'] = const CacheConfig(
      ttl: Duration(hours: 1),
      priority: 7,
      compressible: true,
      tags: {'fund', 'details'},
    );

    _predefinedConfigs['fund_list'] = const CacheConfig(
      ttl: Duration(minutes: 30),
      priority: 6,
      compressible: true,
      maxSize: 10 * 1024 * 1024, // 最大10MB
      tags: {'fund', 'list'},
    );

    // 临时数据配置
    _predefinedConfigs['temporary'] = const CacheConfig(
      ttl: Duration(minutes: 5),
      priority: 2,
      compressible: true,
      persistent: false,
      tags: {'temporary'},
    );

    // 系统配置
    _predefinedConfigs['system_config'] = const CacheConfig(
      ttl: Duration(hours: 24),
      priority: 9,
      compressible: true,
      tags: {'system', 'config'},
    );

    // 默认配置
    _predefinedConfigs['default'] = CacheConfig.defaultConfig();
  }

  /// 初始化验证器
  void _initializeValidators() {
    _validators.addAll([
      TTLValidator(),
      SizeValidator(),
      PriorityValidator(),
      TagValidator(),
    ]);
  }

  /// 获取所有预定义配置名称
  List<String> getAvailableConfigs() {
    return _predefinedConfigs.keys.toList()..sort();
  }

  /// 获取配置统计信息
  Map<String, dynamic> getConfigStatistics() {
    return {
      'predefinedConfigs': _predefinedConfigs.length,
      'runtimeOverrides': _runtimeOverrides.length,
      'validators': _validators.length,
      'environment': _environment.name,
      'availableConfigs': getAvailableConfigs(),
    };
  }

  /// 导出配置
  Map<String, dynamic> exportConfigs() {
    final exported = <String, dynamic>{};

    // 导出预定义配置
    exported['predefined'] = _predefinedConfigs.map(
      (key, config) => MapEntry(key, config.toJson()),
    );

    // 导出运行时覆盖
    exported['runtimeOverrides'] = _runtimeOverrides.map(
      (key, config) => MapEntry(key, config.toJson()),
    );

    // 导出环境信息
    exported['environment'] = _environment.name;

    return exported;
  }

  /// 导入配置
  void importConfigs(Map<String, dynamic> data) {
    // 导入运行时覆盖
    if (data.containsKey('runtimeOverrides')) {
      final overrides = data['runtimeOverrides'] as Map<String, dynamic>;
      for (final entry in overrides.entries) {
        try {
          final config =
              CacheConfig.fromJson(entry.value as Map<String, dynamic>);
          setRuntimeOverride(entry.key, config);
        } catch (e) {
          // 忽略无效配置
          print('Failed to import config for ${entry.key}: $e');
        }
      }
    }
  }

  /// 重置所有运行时覆盖
  void resetRuntimeOverrides() {
    _runtimeOverrides.clear();
  }
}

// ============================================================================
// 数据类型枚举
// ============================================================================

/// 缓存数据类型
enum CacheDataType {
  searchResults,
  searchSuggestions,
  searchHistory,
  filterCriteria,
  filterOptions,
  userData,
  fundDetails,
  fundList,
  temporary,
  systemConfig,
}

// ============================================================================
// 缓存环境
// ============================================================================

/// 缓存环境
enum CacheEnvironment {
  development,
  testing,
  staging,
  production,
}

// ============================================================================
// 配置验证器
// ============================================================================

/// 配置验证器接口
abstract class ConfigValidator {
  ValidationResult validate(CacheConfig config);
}

/// 验证结果
class ValidationResult {
  final bool isValid;
  final List<String> errors;

  const ValidationResult({
    required this.isValid,
    required this.errors,
  });

  factory ValidationResult.success() {
    return const ValidationResult(isValid: true, errors: []);
  }

  factory ValidationResult.failure(List<String> errors) {
    return ValidationResult(isValid: false, errors: errors);
  }
}

/// TTL验证器
class TTLValidator implements ConfigValidator {
  @override
  ValidationResult validate(CacheConfig config) {
    final errors = <String>[];

    if (config.ttl != null) {
      if (config.ttl!.inMilliseconds <= 0) {
        errors.add('TTL must be positive');
      }

      if (config.ttl!.inDays > 365) {
        errors.add('TTL should not exceed 1 year for performance reasons');
      }
    }

    if (config.maxIdleTime != null) {
      if (config.maxIdleTime!.inMilliseconds <= 0) {
        errors.add('Max idle time must be positive');
      }

      if (config.ttl != null && config.maxIdleTime! > config.ttl!) {
        errors.add('Max idle time should not exceed TTL');
      }
    }

    return errors.isEmpty
        ? ValidationResult.success()
        : ValidationResult.failure(errors);
  }
}

/// 大小验证器
class SizeValidator implements ConfigValidator {
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB

  @override
  ValidationResult validate(CacheConfig config) {
    final errors = <String>[];

    if (config.maxSize != null) {
      if (config.maxSize! <= 0) {
        errors.add('Max size must be positive');
      }

      if (config.maxSize! > maxCacheSize) {
        errors.add('Max size should not exceed $maxCacheSize bytes');
      }
    }

    return errors.isEmpty
        ? ValidationResult.success()
        : ValidationResult.failure(errors);
  }
}

/// 优先级验证器
class PriorityValidator implements ConfigValidator {
  @override
  ValidationResult validate(CacheConfig config) {
    final errors = <String>[];

    if (config.priority < 0 || config.priority > 10) {
      errors.add('Priority must be between 0 and 10');
    }

    return errors.isEmpty
        ? ValidationResult.success()
        : ValidationResult.failure(errors);
  }
}

/// 标签验证器
class TagValidator implements ConfigValidator {
  static const int maxTagCount = 10;
  static const int maxTagLength = 50;

  @override
  ValidationResult validate(CacheConfig config) {
    final errors = <String>[];

    if (config.tags.length > maxTagCount) {
      errors.add('Too many tags (max $maxTagCount)');
    }

    for (final tag in config.tags) {
      if (tag.isEmpty) {
        errors.add('Tags cannot be empty');
      }

      if (tag.length > maxTagLength) {
        errors.add('Tag "$tag" is too long (max $maxTagLength characters)');
      }

      if (tag.contains(RegExp(r'[<>:"/\\|?*]'))) {
        errors.add('Tag "$tag" contains invalid characters');
      }
    }

    return errors.isEmpty
        ? ValidationResult.success()
        : ValidationResult.failure(errors);
  }
}

// ============================================================================
// 异常定义
// ============================================================================

/// 缓存配置验证异常
class CacheConfigValidationException implements Exception {
  final String message;

  const CacheConfigValidationException(this.message);

  @override
  String toString() => 'CacheConfigValidationException: $message';
}
