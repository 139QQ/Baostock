/// 缓存键标准化服务
///
/// 提供统一的缓存键命名规范和管理机制，解决缓存键不一致、硬编码等问题
library cache_key_manager;

import '../utils/logger.dart';

/// 缓存键类型枚举
enum CacheKeyType {
  /// 基金数据
  fundData,

  /// 搜索索引
  searchIndex,

  /// 用户偏好
  userPreference,

  /// 元数据
  metadata,

  /// 临时数据
  temporary,

  /// 系统配置
  systemConfig,
}

/// 缓存键版本管理
enum CacheKeyVersion {
  v1('1.0'),
  v2('2.0'),
  v3('3.0'),
  latest('latest');

  const CacheKeyVersion(this.version);
  final String version;
}

/// 统一缓存键管理器
///
/// 提供类型安全、版本化、标准化的缓存键生成和管理
class CacheKeyManager {
  static CacheKeyManager? _instance;
  static CacheKeyManager get instance {
    _instance ??= CacheKeyManager._();
    return _instance!;
  }

  CacheKeyManager._() {
    AppLogger.info('🔑 CacheKeyManager 初始化');
  }

  // 缓存键前缀常量
  static const String _prefix = 'jisu';
  static const String _separator = '_';
  static const String _versionSeparator = '@';
  static const String _fundPrefix = 'fund';

  /// 生成标准化缓存键
  ///
  /// [type] 缓存键类型
  /// [identifier] 具体标识符
  /// [version] 缓存键版本
  /// [params] 额外参数（可选）
  ///
  /// 返回格式：`jisu_fund_{type}_{identifier}@{version}_{params...}`
  String generateKey(
    CacheKeyType type,
    String identifier, {
    CacheKeyVersion version = CacheKeyVersion.latest,
    List<String>? params,
  }) {
    // 验证参数
    if (identifier.isEmpty) {
      throw ArgumentError('标识符不能为空');
    }

    // 验证标识符中不包含无效字符
    if (identifier.contains('@') || identifier.contains(_versionSeparator)) {
      throw ArgumentError('标识符不能包含版本分隔符字符 @');
    }

    // 构建基础键
    final keyParts = <String>[
      _prefix,
      _fundPrefix,
      type.name,
      identifier,
    ];

    // 构建基础键
    String baseKey = keyParts.join(_separator);

    // 添加版本信息
    baseKey += '$_versionSeparator${version.version}';

    // 添加额外参数
    if (params != null && params.isNotEmpty) {
      baseKey += '$_separator${params.join(_separator)}';
    }

    final finalKey = baseKey;

    AppLogger.debug('🔑 生成缓存键: $finalKey');
    return finalKey;
  }

  /// 生成基金数据缓存键
  String fundDataKey(String fundCode,
      {CacheKeyVersion version = CacheKeyVersion.latest}) {
    return generateKey(CacheKeyType.fundData, fundCode, version: version);
  }

  /// 生成基金列表缓存键
  String fundListKey(String listType, {Map<String, String>? filters}) {
    final params = <String>[];
    if (filters != null && filters.isNotEmpty) {
      filters.forEach((key, value) {
        params.add('${key}_$value');
      });
    }
    return generateKey(CacheKeyType.fundData, 'list_$listType', params: params);
  }

  /// 生成搜索索引缓存键
  String searchIndexKey(String indexType) {
    return generateKey(CacheKeyType.searchIndex, indexType);
  }

  /// 生成用户偏好缓存键
  String userPreferenceKey(String preferenceName) {
    return generateKey(CacheKeyType.userPreference, preferenceName);
  }

  /// 生成元数据缓存键
  String metadataKey(String metadataType, {String? specificId}) {
    final identifier =
        specificId != null ? '${metadataType}_$specificId' : metadataType;
    return generateKey(CacheKeyType.metadata, identifier);
  }

  /// 生成临时数据缓存键
  String temporaryKey(String dataType, {String? sessionId}) {
    final identifier = sessionId != null ? '${dataType}_$sessionId' : dataType;
    return generateKey(CacheKeyType.temporary, identifier);
  }

  /// 生成系统配置缓存键
  String systemConfigKey(String configName) {
    return generateKey(CacheKeyType.systemConfig, configName);
  }

  /// 解析缓存键（用于调试和监控）
  ///
  /// 返回解析后的键信息，如果格式无效则返回null
  CacheKeyInfo? parseKey(String cacheKey) {
    try {
      AppLogger.debug('开始解析缓存键: $cacheKey');

      // 首先找到版本分隔符的位置
      final versionIndex = cacheKey.indexOf(_versionSeparator);
      AppLogger.debug('版本分隔符位置: $versionIndex, 分隔符: $_versionSeparator');
      if (versionIndex == -1) {
        AppLogger.debug('解析缓存键失败: 找不到版本分隔符 - $cacheKey');
        return null;
      }

      // 分离基础部分和版本+参数部分
      final basePart = cacheKey.substring(0, versionIndex);
      final versionAndParamsPart = cacheKey.substring(versionIndex + 1);
      AppLogger.debug('基础部分: "$basePart", 版本部分: "$versionAndParamsPart"');

      // 解析基础部分
      final baseParts = basePart.split(_separator);
      AppLogger.debug('基础部分分割结果: $baseParts, 分隔符: $_separator');
      if (baseParts.length < 3) {
        AppLogger.debug('解析缓存键失败: 基础部分长度不足 - $baseParts');
        return null;
      }

      // 验证前缀
      final prefix = baseParts[0];
      AppLogger.debug('检查前缀: "$prefix" == "$_prefix"? ${prefix == _prefix}');
      if (prefix != _prefix) {
        AppLogger.debug('解析缓存键失败: 前缀不匹配 - $prefix != $_prefix');
        return null;
      }

      // 验证fund前缀
      if (baseParts.length < 2 || baseParts[1] != _fundPrefix) {
        AppLogger.debug(
            '解析缓存键失败: fund前缀不匹配 - ${baseParts.length > 2 ? baseParts[1] : "missing"} != $_fundPrefix');
        return null;
      }

      // 验证类型
      final typeName = baseParts[2];
      AppLogger.debug('检查类型: "$typeName"');
      AppLogger.debug(
          '可用类型: ${CacheKeyType.values.map((e) => e.name).join(', ')}');
      final type =
          CacheKeyType.values.where((e) => e.name == typeName).firstOrNull;
      AppLogger.debug('类型查找结果: $type');
      if (type == null) {
        AppLogger.debug('解析缓存键失败: 类型未找到 - $typeName');
        return null;
      }

      // 提取标识符（可能包含下划线）
      final identifier =
          baseParts.length > 3 ? baseParts.sublist(3).join(_separator) : '';

      // 解析版本和参数
      final versionAndParamsParts = versionAndParamsPart.split(_separator);
      if (versionAndParamsParts.isEmpty || versionAndParamsParts[0].isEmpty) {
        AppLogger.debug('解析缓存键失败: 版本部分为空 - $cacheKey');
        return null;
      }
      final version = versionAndParamsParts[0];
      final params = versionAndParamsParts.length > 1
          ? versionAndParamsParts.sublist(1)
          : <String>[];

      // 额外验证：如果标识符为空，验证版本不是看起来像标识符的情况
      if (identifier.isEmpty && !isValidVersionFormat(version)) {
        AppLogger.debug('解析缓存键失败: 空标识符且版本格式无效 - $cacheKey');
        return null;
      }

      return CacheKeyInfo(
        type: type,
        identifier: identifier,
        version: version,
        params: params,
        originalKey: cacheKey,
      );
    } catch (e) {
      AppLogger.debug('解析缓存键失败: $cacheKey, 错误: $e');
      return null;
    }
  }

  /// 检查版本格式是否有效
  bool isValidVersionFormat(String version) {
    // 有效的版本格式包括：
    // - latest
    // - v1, v2, v3 等版本号
    // - 1.0, 2.0, 3.0 等版本号
    // - 纯数字版本号
    final validVersionPatterns = [
      'latest',
      RegExp(r'^v\d+$'), // v1, v2, v3
      RegExp(r'^\d+\.\d+$'), // 1.0, 2.0, 3.0
      RegExp(r'^\d+$'), // 1, 2, 3
    ];

    return validVersionPatterns.any((pattern) {
      if (pattern is RegExp) {
        return pattern.hasMatch(version);
      } else {
        return version == pattern;
      }
    });
  }

  /// 检查缓存键是否符合标准格式
  bool isValidKey(String cacheKey) {
    return parseKey(cacheKey) != null;
  }

  /// 迁移旧格式缓存键到新格式
  ///
  /// [oldKey] 旧格式缓存键
  /// [newType] 新的缓存键类型
  /// [newIdentifier] 新的标识符
  String migrateKey(String oldKey, CacheKeyType newType, String newIdentifier) {
    AppLogger.info('🔄 迁移缓存键: $oldKey -> 新格式');
    return generateKey(newType, newIdentifier);
  }

  /// 批量生成缓存键
  List<String> generateBatchKeys(
    CacheKeyType type,
    List<String> identifiers, {
    CacheKeyVersion version = CacheKeyVersion.latest,
  }) {
    return identifiers
        .map((id) => generateKey(type, id, version: version))
        .toList();
  }

  /// 获取所有标准化的盒子名称
  List<String> getStandardBoxNames() {
    return [
      '$_prefix$_separator$_fundPrefix$_separator${CacheKeyType.fundData.name}',
      '$_prefix$_separator$_fundPrefix$_separator${CacheKeyType.searchIndex.name}',
      '$_prefix$_separator$_fundPrefix$_separator${CacheKeyType.userPreference.name}',
      '$_prefix$_separator$_fundPrefix$_separator${CacheKeyType.metadata.name}',
      '$_prefix$_separator$_fundPrefix$_separator${CacheKeyType.temporary.name}',
      '$_prefix$_separator$_fundPrefix$_separator${CacheKeyType.systemConfig.name}',
    ];
  }
}

/// 缓存键信息数据类
///
/// 用于存储解析后的缓存键信息
class CacheKeyInfo {
  final CacheKeyType type;
  final String identifier;
  final String version;
  final List<String> params;
  final String originalKey;

  const CacheKeyInfo({
    required this.type,
    required this.identifier,
    required this.version,
    required this.params,
    required this.originalKey,
  });

  @override
  String toString() {
    return 'CacheKeyInfo(type: $type, identifier: $identifier, version: $version, params: $params)';
  }

  /// 获取缓存键的描述信息
  String get description {
    final buffer = StringBuffer();
    buffer.write('[${type.name}] $identifier@$version');
    if (params.isNotEmpty) {
      buffer.write(' (${params.join(', ')})');
    }
    return buffer.toString();
  }
}

/// 缓存键构建器
///
/// 提供流式API来构建复杂的缓存键
class CacheKeyBuilder {
  CacheKeyType? _type;
  String? _identifier;
  CacheKeyVersion _version = CacheKeyVersion.latest;
  final List<String> _params = [];

  /// 设置缓存键类型
  CacheKeyBuilder setType(CacheKeyType type) {
    _type = type;
    return this;
  }

  /// 设置标识符
  CacheKeyBuilder setIdentifier(String identifier) {
    _identifier = identifier;
    return this;
  }

  /// 设置版本
  CacheKeyBuilder setVersion(CacheKeyVersion version) {
    _version = version;
    return this;
  }

  /// 添加参数
  CacheKeyBuilder addParam(String param) {
    _params.add(param);
    return this;
  }

  /// 添加多个参数
  CacheKeyBuilder addParams(List<String> params) {
    _params.addAll(params);
    return this;
  }

  /// 构建缓存键
  String build() {
    if (_type == null || _identifier == null) {
      throw StateError('类型和标识符必须设置');
    }

    return CacheKeyManager.instance.generateKey(
      _type!,
      _identifier!,
      version: _version,
      params: _params.isEmpty ? null : _params,
    );
  }
}

/// 扩展方法，提供便捷的缓存键生成
extension CacheKeyExtensions on String {
  /// 转换为基金数据缓存键
  String toFundDataKey({CacheKeyVersion version = CacheKeyVersion.latest}) {
    return CacheKeyManager.instance.fundDataKey(this, version: version);
  }

  /// 转换为搜索索引缓存键
  String toSearchIndexKey() {
    return CacheKeyManager.instance.searchIndexKey(this);
  }

  /// 转换为用户偏好缓存键
  String toUserPreferenceKey() {
    return CacheKeyManager.instance.userPreferenceKey(this);
  }

  /// 转换为元数据缓存键
  String toMetadataKey({String? specificId}) {
    return CacheKeyManager.instance.metadataKey(this, specificId: specificId);
  }
}
