import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/logger.dart';

/// 性能偏好设置
class UserPerformancePreferences {
  final String id;
  final String name;
  final String description;
  final bool isCustom;
  final Map<String, dynamic> preferences;
  final DateTime createdAt;
  final DateTime? lastUsedAt;
  final int usageCount;

  const UserPerformancePreferences({
    required this.id,
    required this.name,
    required this.description,
    required this.isCustom,
    required this.preferences,
    required this.createdAt,
    this.lastUsedAt,
    this.usageCount = 0,
  });

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isCustom': isCustom,
      'preferences': preferences,
      'createdAt': createdAt.toIso8601String(),
      'lastUsedAt': lastUsedAt?.toIso8601String(),
      'usageCount': usageCount,
    };
  }

  /// 从JSON创建
  factory UserPerformancePreferences.fromJson(Map<String, dynamic> json) {
    return UserPerformancePreferences(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      isCustom: json['isCustom'] as bool? ?? false,
      preferences: json['preferences'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.parse(json['lastUsedAt'] as String)
          : null,
      usageCount: json['usageCount'] as int? ?? 0,
    );
  }

  /// 创建使用记录
  UserPerformancePreferences withUsage() {
    return UserPerformancePreferences(
      id: id,
      name: name,
      description: description,
      isCustom: isCustom,
      preferences: preferences,
      createdAt: createdAt,
      lastUsedAt: DateTime.now(),
      usageCount: usageCount + 1,
    );
  }

  /// 复制并修改
  UserPerformancePreferences copyWith({
    String? name,
    String? description,
    Map<String, dynamic>? preferences,
  }) {
    return UserPerformancePreferences(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      isCustom: isCustom,
      preferences: preferences ?? Map<String, dynamic>.from(this.preferences),
      createdAt: createdAt,
      lastUsedAt: lastUsedAt,
      usageCount: usageCount,
    );
  }
}

/// 性能偏好分类
enum PerformanceCategory {
  general, // 通用性能
  animation, // 动画效果
  cache, // 缓存策略
  network, // 网络请求
  battery, // 电池优化
  background, // 后台处理
  ui, // 界面响应
  data, // 数据处理
}

/// 预定义性能偏好模板
class PerformancePreferenceTemplates {
  /// 节能模式偏好
  static UserPerformancePreferences get energySaving {
    return UserPerformancePreferences(
      id: 'energy_saving',
      name: '节能模式',
      description: '优化电池使用，延长续航时间',
      isCustom: false,
      createdAt: DateTime.now(),
      preferences: {
        'performance_mode': 'energy_saving',
        'animation_level': 'reduced',
        'cache_strategy': 'minimal',
        'background_processing': false,
        'auto_sync': false,
        'push_notifications': false,
        'ui_update_frequency': 'low',
        'data_compression': true,
        'image_quality': 'medium',
        'video_quality': 'low',
        'max_concurrent_requests': 3,
        'preload_content': false,
        'adaptive_refresh_rate': true,
      },
    );
  }

  /// 性能模式偏好
  static UserPerformancePreferences get performance {
    return UserPerformancePreferences(
      id: 'performance',
      name: '性能模式',
      description: '最大化系统性能，提供流畅体验',
      isCustom: false,
      createdAt: DateTime.now(),
      preferences: {
        'performance_mode': 'high_performance',
        'animation_level': 'enhanced',
        'cache_strategy': 'aggressive',
        'background_processing': true,
        'auto_sync': true,
        'push_notifications': true,
        'ui_update_frequency': 'high',
        'data_compression': false,
        'image_quality': 'high',
        'video_quality': 'high',
        'max_concurrent_requests': 8,
        'preload_content': true,
        'adaptive_refresh_rate': false,
      },
    );
  }

  /// 平衡模式偏好
  static UserPerformancePreferences get balanced {
    return UserPerformancePreferences(
      id: 'balanced',
      name: '平衡模式',
      description: '在性能和功耗之间取得平衡',
      isCustom: false,
      createdAt: DateTime.now(),
      preferences: {
        'performance_mode': 'balanced',
        'animation_level': 'normal',
        'cache_strategy': 'balanced',
        'background_processing': true,
        'auto_sync': true,
        'push_notifications': true,
        'ui_update_frequency': 'normal',
        'data_compression': true,
        'image_quality': 'medium',
        'video_quality': 'medium',
        'max_concurrent_requests': 5,
        'preload_content': true,
        'adaptive_refresh_rate': true,
      },
    );
  }

  /// 游戏模式偏好
  static UserPerformancePreferences get gaming {
    return UserPerformancePreferences(
      id: 'gaming',
      name: '游戏模式',
      description: '针对游戏优化的性能设置',
      isCustom: false,
      createdAt: DateTime.now(),
      preferences: {
        'performance_mode': 'gaming',
        'animation_level': 'enhanced',
        'cache_strategy': 'aggressive',
        'background_processing': false,
        'auto_sync': false,
        'push_notifications': false,
        'ui_update_frequency': 'maximum',
        'data_compression': false,
        'image_quality': 'maximum',
        'video_quality': 'maximum',
        'max_concurrent_requests': 12,
        'preload_content': true,
        'adaptive_refresh_rate': false,
        'touch_response_optimization': true,
        'graphics_acceleration': true,
      },
    );
  }

  /// 工作模式偏好
  static UserPerformancePreferences get productivity {
    return UserPerformancePreferences(
      id: 'productivity',
      name: '工作模式',
      description: '适合办公和生产力应用的设置',
      isCustom: false,
      createdAt: DateTime.now(),
      preferences: {
        'performance_mode': 'productivity',
        'animation_level': 'minimal',
        'cache_strategy': 'conservative',
        'background_processing': true,
        'auto_sync': true,
        'push_notifications': true,
        'ui_update_frequency': 'normal',
        'data_compression': true,
        'image_quality': 'medium',
        'video_quality': 'medium',
        'max_concurrent_requests': 6,
        'preload_content': false,
        'adaptive_refresh_rate': true,
        'focus_mode': true,
        'distraction_free': true,
      },
    );
  }

  /// 获取所有模板
  static List<UserPerformancePreferences> get allTemplates => [
        energySaving,
        performance,
        balanced,
        gaming,
        productivity,
      ];
}

/// 用户性能偏好管理器
class UserPerformancePreferencesManager {
  static UserPerformancePreferencesManager? _instance;
  static UserPerformancePreferencesManager get instance =>
      _instance ??= UserPerformancePreferencesManager._();

  UserPerformancePreferencesManager._();

  SharedPreferences? _prefs;
  UserPerformancePreferences? _currentPreferences;
  final List<UserPerformancePreferences> _customPreferences = [];

  // 事件回调
  final List<void Function(UserPerformancePreferences)>
      _preferenceChangeListeners = [];

  /// 初始化
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadCurrentPreferences();
      await _loadCustomPreferences();
      AppLogger.business('UserPerformancePreferencesManager初始化完成');
    } catch (e) {
      AppLogger.error('UserPerformancePreferencesManager初始化失败', e);
    }
  }

  /// 加载当前偏好
  Future<void> _loadCurrentPreferences() async {
    if (_prefs == null) return;

    try {
      final preferencesJson =
          _prefs!.getString('current_performance_preferences');
      if (preferencesJson != null) {
        final json = jsonDecode(preferencesJson) as Map<String, dynamic>;
        _currentPreferences = UserPerformancePreferences.fromJson(json);
        AppLogger.debug('已加载用户性能偏好', _currentPreferences!.name);
      } else {
        // 首次使用，使用平衡模式
        _currentPreferences = PerformancePreferenceTemplates.balanced;
        await saveCurrentPreferences();
      }
    } catch (e) {
      AppLogger.error('加载用户性能偏好失败', e);
      _currentPreferences = PerformancePreferenceTemplates.balanced;
    }
  }

  /// 加载自定义偏好
  Future<void> _loadCustomPreferences() async {
    if (_prefs == null) return;

    try {
      final customJson =
          _prefs!.getStringList('custom_performance_preferences') ?? [];
      _customPreferences.clear();

      for (final jsonStr in customJson) {
        try {
          final json = jsonDecode(jsonStr) as Map<String, dynamic>;
          final preferences = UserPerformancePreferences.fromJson(json);
          if (preferences.isCustom) {
            _customPreferences.add(preferences);
          }
        } catch (e) {
          AppLogger.debug('跳过无效的自定义偏好配置');
        }
      }

      AppLogger.debug('已加载 ${_customPreferences.length} 个自定义偏好');
    } catch (e) {
      AppLogger.error('加载自定义偏好失败', e);
    }
  }

  /// 获取当前偏好
  UserPerformancePreferences get currentPreferences =>
      _currentPreferences ?? PerformancePreferenceTemplates.balanced;

  /// 获取所有可用偏好
  List<UserPerformancePreferences> getAllPreferences() {
    return [
      ...PerformancePreferenceTemplates.allTemplates,
      ..._customPreferences,
    ];
  }

  /// 获取模板偏好
  List<UserPerformancePreferences> get templatePreferences =>
      PerformancePreferenceTemplates.allTemplates;

  /// 获取自定义偏好
  List<UserPerformancePreferences> get customPreferences =>
      List<UserPerformancePreferences>.from(_customPreferences);

  /// 应用偏好
  Future<void> applyPreferences(UserPerformancePreferences preferences) async {
    try {
      // 更新使用记录
      final updatedPreferences = preferences.withUsage();

      if (preferences.isCustom) {
        // 更新自定义偏好列表中的使用记录
        final index =
            _customPreferences.indexWhere((p) => p.id == preferences.id);
        if (index >= 0) {
          _customPreferences[index] = updatedPreferences;
        }
      }

      _currentPreferences = updatedPreferences;
      await saveCurrentPreferences();

      // 通知监听器
      _notifyPreferenceChangeListeners(updatedPreferences);

      AppLogger.business('用户性能偏好已应用', preferences.name);
    } catch (e) {
      AppLogger.error('应用用户性能偏好失败', e);
    }
  }

  /// 应用模板偏好
  Future<void> applyTemplate(String templateId) async {
    final template = PerformancePreferenceTemplates.allTemplates
        .where((p) => p.id == templateId)
        .firstOrNull;

    if (template != null) {
      await applyPreferences(template);
    } else {
      AppLogger.warn('未找到指定的偏好模板', templateId);
    }
  }

  /// 创建自定义偏好
  Future<void> createCustomPreferences({
    required String name,
    required String description,
    required Map<String, dynamic> preferences,
    String? baseTemplateId,
  }) async {
    try {
      // 如果指定了基础模板，则从模板继承默认设置
      Map<String, dynamic> finalPreferences =
          Map<String, dynamic>.from(preferences);

      if (baseTemplateId != null) {
        final baseTemplate = PerformancePreferenceTemplates.allTemplates
            .where((p) => p.id == baseTemplateId)
            .firstOrNull;

        if (baseTemplate != null) {
          // 合并模板设置和用户设置，用户设置优先
          finalPreferences =
              Map<String, dynamic>.from(baseTemplate.preferences);
          finalPreferences.addAll(preferences);
        }
      }

      final customPreferences = UserPerformancePreferences(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        description: description,
        isCustom: true,
        preferences: finalPreferences,
        createdAt: DateTime.now(),
      );

      _customPreferences.add(customPreferences);
      await _saveCustomPreferences();

      AppLogger.business('自定义性能偏好已创建', name);
    } catch (e) {
      AppLogger.error('创建自定义性能偏好失败', e);
    }
  }

  /// 更新自定义偏好
  Future<void> updateCustomPreferences({
    required String id,
    String? name,
    String? description,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      final index = _customPreferences.indexWhere((p) => p.id == id);
      if (index < 0) {
        AppLogger.warn('未找到指定的自定义偏好', id);
        return;
      }

      final updated = _customPreferences[index].copyWith(
        name: name,
        description: description,
        preferences: preferences,
      );

      _customPreferences[index] = updated;
      await _saveCustomPreferences();

      // 如果更新的是当前偏好，也需要更新当前偏好
      if (_currentPreferences?.id == id) {
        _currentPreferences = updated;
        await saveCurrentPreferences();
        _notifyPreferenceChangeListeners(updated);
      }

      AppLogger.business('自定义性能偏好已更新', updated.name);
    } catch (e) {
      AppLogger.error('更新自定义性能偏好失败', e);
    }
  }

  /// 删除自定义偏好
  Future<void> deleteCustomPreferences(String id) async {
    try {
      final index = _customPreferences.indexWhere((p) => p.id == id);
      if (index < 0) {
        AppLogger.warn('未找到指定的自定义偏好', id);
        return;
      }

      final deleted = _customPreferences.removeAt(index);
      await _saveCustomPreferences();

      // 如果删除的是当前偏好，切换到平衡模式
      if (_currentPreferences?.id == id) {
        await applyPreferences(PerformancePreferenceTemplates.balanced);
      }

      AppLogger.business('自定义性能偏好已删除', deleted.name);
    } catch (e) {
      AppLogger.error('删除自定义性能偏好失败', e);
    }
  }

  /// 保存当前偏好
  Future<void> saveCurrentPreferences() async {
    if (_prefs == null || _currentPreferences == null) return;

    try {
      final preferencesJson = jsonEncode(_currentPreferences!.toJson());
      await _prefs!
          .setString('current_performance_preferences', preferencesJson);
      AppLogger.debug('当前用户性能偏好已保存');
    } catch (e) {
      AppLogger.error('保存当前用户性能偏好失败', e);
    }
  }

  /// 保存自定义偏好
  Future<void> _saveCustomPreferences() async {
    if (_prefs == null) return;

    try {
      final customJsonList =
          _customPreferences.map((p) => jsonEncode(p.toJson())).toList();

      await _prefs!
          .setStringList('custom_performance_preferences', customJsonList);
      AppLogger.debug('自定义性能偏好已保存');
    } catch (e) {
      AppLogger.error('保存自定义性能偏好失败', e);
    }
  }

  /// 重置为默认偏好
  Future<void> resetToDefault() async {
    await applyPreferences(PerformancePreferenceTemplates.balanced);
    AppLogger.business('已重置为默认性能偏好');
  }

  /// 导出偏好配置
  String exportPreferences() {
    return jsonEncode({
      'current': _currentPreferences?.toJson(),
      'custom': _customPreferences.map((p) => p.toJson()).toList(),
    });
  }

  /// 导入偏好配置
  Future<bool> importPreferences(String preferencesJson) async {
    try {
      final json = jsonDecode(preferencesJson) as Map<String, dynamic>;

      // 导入当前偏好
      if (json.containsKey('current')) {
        final currentJson = json['current'] as Map<String, dynamic>;
        final current = UserPerformancePreferences.fromJson(currentJson);
        _currentPreferences = current;
        await saveCurrentPreferences();
      }

      // 导入自定义偏好
      if (json.containsKey('custom')) {
        final customList = json['custom'] as List;
        _customPreferences.clear();

        for (final item in customList) {
          try {
            final preferences = UserPerformancePreferences.fromJson(
                item as Map<String, dynamic>);
            if (preferences.isCustom) {
              _customPreferences.add(preferences);
            }
          } catch (e) {
            AppLogger.debug('跳过无效的自定义偏好配置');
          }
        }

        await _saveCustomPreferences();
      }

      AppLogger.business('偏好配置导入成功');
      return true;
    } catch (e) {
      AppLogger.error('偏好配置导入失败', e);
      return false;
    }
  }

  /// 获取偏好摘要
  Map<String, dynamic> getPreferencesSummary() {
    final current = currentPreferences;
    return {
      'currentName': current.name,
      'currentId': current.id,
      'isCustom': current.isCustom,
      'usageCount': current.usageCount,
      'lastUsedAt': current.lastUsedAt?.toIso8601String(),
      'customPreferencesCount': _customPreferences.length,
      'totalPreferencesCount': getAllPreferences().length,
    };
  }

  /// 搜索偏好
  List<UserPerformancePreferences> searchPreferences(String query) {
    final lowerQuery = query.toLowerCase();
    return getAllPreferences()
        .where((p) =>
            p.name.toLowerCase().contains(lowerQuery) ||
            p.description.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// 按使用次数排序偏好
  List<UserPerformancePreferences> getPreferencesByUsageCount() {
    final preferences =
        List<UserPerformancePreferences>.from(getAllPreferences());
    preferences.sort((a, b) => b.usageCount.compareTo(a.usageCount));
    return preferences;
  }

  /// 按最后使用时间排序偏好
  List<UserPerformancePreferences> getPreferencesByLastUsed() {
    final preferences =
        List<UserPerformancePreferences>.from(getAllPreferences());
    preferences.sort((a, b) {
      if (a.lastUsedAt == null && b.lastUsedAt == null) return 0;
      if (a.lastUsedAt == null) return 1;
      if (b.lastUsedAt == null) return -1;
      return b.lastUsedAt!.compareTo(a.lastUsedAt!);
    });
    return preferences;
  }

  /// 添加偏好变更监听器
  void addPreferenceChangeListener(
      void Function(UserPerformancePreferences) listener) {
    _preferenceChangeListeners.add(listener);
  }

  /// 移除偏好变更监听器
  void removePreferenceChangeListener(
      void Function(UserPerformancePreferences) listener) {
    _preferenceChangeListeners.remove(listener);
  }

  /// 通知偏好变更监听器
  void _notifyPreferenceChangeListeners(
      UserPerformancePreferences preferences) {
    for (final listener in _preferenceChangeListeners) {
      try {
        listener(preferences);
      } catch (e) {
        AppLogger.error('偏好变更监听器回调失败', e);
      }
    }
  }

  /// 清理资源
  Future<void> dispose() async {
    _prefs = null;
    _currentPreferences = null;
    _customPreferences.clear();
    _preferenceChangeListeners.clear();

    AppLogger.business('UserPerformancePreferencesManager已清理');
  }
}
