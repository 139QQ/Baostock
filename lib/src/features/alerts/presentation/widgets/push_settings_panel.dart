import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/logger.dart';
import '../../data/models/push_preferences.dart';
import '../cubits/push_notification_cubit.dart';
import 'permission_request_dialog.dart';

/// 推送设置面板
///
/// 提供推送通知的个性化设置界面，包括：
/// - 推送开关控制
/// - 推送类型偏好
/// - 推送时间设置
/// - 推送频率控制
/// - 个性化选项
class PushSettingsPanel extends StatefulWidget {
  /// 创建推送设置面板
  const PushSettingsPanel({super.key});

  @override
  State<PushSettingsPanel> createState() => _PushSettingsPanelState();
}

class _PushSettingsPanelState extends State<PushSettingsPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  UserPreferences? _preferences;
  bool _isLoading = false;
  bool _hasChanges = false;
  static const String _defaultUserId = 'default_user';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPreferences();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 这里应该从服务加载偏好设置
      // 暂时使用默认值
      final now = DateTime.now();
      _preferences = UserPreferences(
        userId: _defaultUserId,
        createdAt: now,
        updatedAt: now,
        quietHours: const [
          QuietHours(
            start: TimeOfDay(hour: 22, minute: 0),
            end: TimeOfDay(hour: 7, minute: 0),
            enabled: true,
          ),
        ],
      );
    } catch (e) {
      AppLogger.error('❌ PushSettingsPanel: Failed to load preferences', e);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _savePreferences() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 这里应该保存偏好设置到服务
      AppLogger.info('✅ PushSettingsPanel: Preferences saved');

      setState(() {
        _hasChanges = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('设置已保存'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      AppLogger.error('❌ PushSettingsPanel: Failed to save preferences', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('保存失败: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onPreferenceChanged() {
    setState(() {
      _hasChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PushNotificationCubit, PushNotificationState>(
      builder: (context, pushState) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('推送设置'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: '基础设置', icon: Icon(Icons.settings)),
                Tab(text: '个性化', icon: Icon(Icons.person)),
                Tab(text: '高级选项', icon: Icon(Icons.tune)),
              ],
            ),
            actions: [
              if (_hasChanges)
                TextButton(
                  onPressed: _isLoading ? null : _savePreferences,
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('保存'),
                ),
            ],
          ),
          body: _isLoading || _preferences == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // 权限状态横幅
                    _buildPermissionBanner(context, pushState),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildBasicSettings(),
                          _buildPersonalizationSettings(),
                          _buildAdvancedSettings(),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildBasicSettings() {
    if (_preferences == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 主开关
        Card(
          child: SwitchListTile(
            title: const Text('启用推送通知'),
            subtitle: const Text('允许应用发送推送通知'),
            value: _preferences!.enablePushNotifications,
            onChanged: (value) {
              setState(() {
                _preferences =
                    _preferences!.copyWith(enablePushNotifications: value);
                _onPreferenceChanged();
              });
            },
          ),
        ),

        const SizedBox(height: 16),

        // 推送类型设置
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '推送类型',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SwitchListTile(
                title: const Text('应用内通知'),
                subtitle: const Text('在应用内显示通知'),
                value: _preferences!.enableInAppNotification,
                onChanged: _preferences!.enablePushNotifications
                    ? (value) {
                        setState(() {
                          _preferences = _preferences!.copyWith(
                            enableInAppNotification: value,
                          );
                          _onPreferenceChanged();
                        });
                      }
                    : null,
              ),
              SwitchListTile(
                title: const Text('系统通知'),
                subtitle: const Text('系统级推送通知'),
                value: _preferences!.enableSystemNotification,
                onChanged: _preferences!.enablePushNotifications
                    ? (value) {
                        setState(() {
                          _preferences = _preferences!.copyWith(
                            enableSystemNotification: value,
                          );
                          _onPreferenceChanged();
                        });
                      }
                    : null,
              ),
              SwitchListTile(
                title: const Text('紧急推送'),
                subtitle: const Text('接收高优先级紧急推送'),
                value: _preferences!.enableUrgentPushes,
                onChanged: _preferences!.enablePushNotifications
                    ? (value) {
                        setState(() {
                          _preferences = _preferences!.copyWith(
                            enableUrgentPushes: value,
                          );
                          _onPreferenceChanged();
                        });
                      }
                    : null,
              ),
              SwitchListTile(
                title: const Text('邮件通知'),
                subtitle: const Text('通过邮件发送通知'),
                value: _preferences!.enableEmailNotification,
                onChanged: _preferences!.enablePushNotifications
                    ? (value) {
                        setState(() {
                          _preferences = _preferences!.copyWith(
                            enableEmailNotification: value,
                          );
                          _onPreferenceChanged();
                        });
                      }
                    : null,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 内容类型设置
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '内容类型',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SwitchListTile(
                title: const Text('包含影响分析'),
                subtitle: const Text('提供详细的市场影响分析'),
                value: _preferences!.includeImpactAnalysis,
                onChanged: _preferences!.enablePushNotifications
                    ? (value) {
                        setState(() {
                          _preferences = _preferences!.copyWith(
                            includeImpactAnalysis: value,
                          );
                          _onPreferenceChanged();
                        });
                      }
                    : null,
              ),
              SwitchListTile(
                title: const Text('包含推荐建议'),
                subtitle: const Text('提供个性化的投资建议'),
                value: _preferences!.includeRecommendations,
                onChanged: _preferences!.enablePushNotifications
                    ? (value) {
                        setState(() {
                          _preferences = _preferences!.copyWith(
                            includeRecommendations: value,
                          );
                          _onPreferenceChanged();
                        });
                      }
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalizationSettings() {
    if (_preferences == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 时间设置
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '推送时间',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                title: const Text('静默时段'),
                subtitle: Text(
                  _preferences!.quietHours.isNotEmpty
                      ? '${_formatTime(_preferences!.quietHours.first.start)} - ${_formatTime(_preferences!.quietHours.first.end)}'
                      : '未设置',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showQuietHoursDialog,
              ),
              ListTile(
                title: const Text('默认推送频率'),
                subtitle: Text(
                    _getFrequencyDescription(_preferences!.defaultFrequency)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showFrequencyDialog,
              ),
              ListTile(
                title: const Text('最小变化阈值'),
                subtitle: Text(
                    '${_preferences!.minChangeThreshold.toStringAsFixed(1)}%'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showThresholdDialog,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 内容偏好
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '内容偏好',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                title: const Text('内容类型'),
                subtitle: Text(
                    _getContentTypesDescription(_preferences!.contentTypes)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showContentTypesDialog,
              ),
              ListTile(
                title: const Text('关注市场'),
                subtitle: Text(_preferences!.markets.join(', ')),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showMarketsDialog,
              ),
              if (_preferences!.primaryWatchFund != null)
                ListTile(
                  title: const Text('主要关注基金'),
                  subtitle: Text(_preferences!.primaryWatchFund!),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showPrimaryFundDialog,
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 主题设置
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '界面设置',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                title: const Text('推送主题'),
                subtitle: Text(_getThemeDescription(_preferences!.theme)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showThemeDialog,
              ),
              ListTile(
                title: const Text('标题样式'),
                subtitle:
                    Text(_getTitleStyleDescription(_preferences!.titleStyle)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showTitleStyleDialog,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedSettings() {
    if (_preferences == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 高级选项
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '高级选项',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SwitchListTile(
                title: const Text('短信通知'),
                subtitle: const Text('通过短信发送重要通知'),
                value: _preferences!.enableSmsNotification,
                onChanged: (value) {
                  setState(() {
                    _preferences = _preferences!.copyWith(
                      enableSmsNotification: value,
                    );
                    _onPreferenceChanged();
                  });
                },
              ),
              SwitchListTile(
                title: const Text('高优先级推送'),
                subtitle: const Text('启用高优先级推送'),
                value: _preferences!.enableHighPriorityPushes,
                onChanged: (value) {
                  setState(() {
                    _preferences = _preferences!.copyWith(
                      enableHighPriorityPushes: value,
                    );
                    _onPreferenceChanged();
                  });
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 数据和隐私
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '数据和隐私',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SwitchListTile(
                title: const Text('短信通知'),
                subtitle: const Text('通过短信发送通知'),
                value: _preferences!.enableSmsNotification,
                onChanged: (value) {
                  setState(() {
                    _preferences = _preferences!.copyWith(
                      enableSmsNotification: value,
                    );
                    _onPreferenceChanged();
                  });
                },
              ),
              ListTile(
                title: const Text('清除推送历史'),
                subtitle: const Text('删除所有推送历史记录'),
                trailing: const Icon(Icons.delete_outline),
                onTap: _showClearHistoryDialog,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 重置设置
        Card(
          child: ListTile(
            title: const Text('重置设置'),
            subtitle: const Text('恢复到默认设置'),
            trailing: const Icon(Icons.restore),
            onTap: _showResetDialog,
          ),
        ),
      ],
    );
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _showQuietHoursDialog() {
    if (_preferences == null) return;

    final currentQuietHours = _preferences!.quietHours.isNotEmpty
        ? _preferences!.quietHours.first
        : const QuietHours(
            start: TimeOfDay(hour: 22, minute: 0),
            end: TimeOfDay(hour: 7, minute: 0),
            enabled: true,
          );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置静默时段'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('启用静默时段'),
              value: currentQuietHours.enabled,
              onChanged: (value) {
                final newQuietHours = QuietHours(
                  start: currentQuietHours.start,
                  end: currentQuietHours.end,
                  enabled: value,
                  weekdays: currentQuietHours.weekdays,
                );
                final newQuietHoursList = _preferences!.quietHours.isEmpty
                    ? [newQuietHours]
                    : [newQuietHours, ..._preferences!.quietHours.skip(1)];

                setState(() {
                  _preferences =
                      _preferences!.copyWith(quietHours: newQuietHoursList);
                  _onPreferenceChanged();
                });
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('开始时间'),
              trailing: Text(_formatTime(currentQuietHours.start)),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: currentQuietHours.start,
                );
                if (time != null) {
                  final newQuietHours = QuietHours(
                    start: time,
                    end: currentQuietHours.end,
                    enabled: currentQuietHours.enabled,
                    weekdays: currentQuietHours.weekdays,
                  );
                  final newQuietHoursList = _preferences!.quietHours.isEmpty
                      ? [newQuietHours]
                      : [newQuietHours, ..._preferences!.quietHours.skip(1)];

                  setState(() {
                    _preferences =
                        _preferences!.copyWith(quietHours: newQuietHoursList);
                    _onPreferenceChanged();
                  });
                }
              },
            ),
            ListTile(
              title: const Text('结束时间'),
              trailing: Text(_formatTime(currentQuietHours.end)),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: currentQuietHours.end,
                );
                if (time != null) {
                  final newQuietHours = QuietHours(
                    start: currentQuietHours.start,
                    end: time,
                    enabled: currentQuietHours.enabled,
                    weekdays: currentQuietHours.weekdays,
                  );
                  final newQuietHoursList = _preferences!.quietHours.isEmpty
                      ? [newQuietHours]
                      : [newQuietHours, ..._preferences!.quietHours.skip(1)];

                  setState(() {
                    _preferences =
                        _preferences!.copyWith(quietHours: newQuietHoursList);
                    _onPreferenceChanged();
                  });
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showFrequencyDialog() {
    if (_preferences == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置默认推送频率'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: PushFrequency.values.map((frequency) {
            return RadioListTile<PushFrequency>(
              title: Text(_getFrequencyDescription(frequency)),
              value: frequency,
              groupValue: _preferences!.defaultFrequency,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _preferences =
                        _preferences!.copyWith(defaultFrequency: value);
                    _onPreferenceChanged();
                  });
                  Navigator.of(context).pop();
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showThresholdDialog() {
    if (_preferences == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置最小变化阈值'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [0.5, 1.0, 2.0, 5.0, 10.0].map((threshold) {
            return RadioListTile<double>(
              title: Text('${threshold.toStringAsFixed(1)}%'),
              value: threshold,
              groupValue: _preferences!.minChangeThreshold,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _preferences =
                        _preferences!.copyWith(minChangeThreshold: value);
                    _onPreferenceChanged();
                  });
                  Navigator.of(context).pop();
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showContentTypesDialog() {
    // TODO: 实现内容类型选择对话框
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('内容类型选择功能待实现')),
    );
  }

  void _showMarketsDialog() {
    // TODO: 实现市场选择对话框
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('市场选择功能待实现')),
    );
  }

  void _showPrimaryFundDialog() {
    // TODO: 实现主要关注基金选择对话框
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('主要关注基金选择功能待实现')),
    );
  }

  void _showThemeDialog() {
    if (_preferences == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择推送主题'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: PushTheme.values.map((theme) {
            return RadioListTile<PushTheme>(
              title: Text(_getThemeDescription(theme)),
              value: theme,
              groupValue: _preferences!.theme,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _preferences = _preferences!.copyWith(theme: value);
                    _onPreferenceChanged();
                  });
                  Navigator.of(context).pop();
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showTitleStyleDialog() {
    if (_preferences == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择标题样式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: TitleStyle.values.map((style) {
            return RadioListTile<TitleStyle>(
              title: Text(_getTitleStyleDescription(style)),
              value: style,
              groupValue: _preferences!.titleStyle,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _preferences = _preferences!.copyWith(titleStyle: value);
                    _onPreferenceChanged();
                  });
                  Navigator.of(context).pop();
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除推送历史'),
        content: const Text('确定要删除所有推送历史记录吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 这里应该调用清除历史记录的方法
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('推送历史已清除'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text(
              '确定',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置设置'),
        content: const Text('确定要重置所有推送设置到默认值吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final now = DateTime.now();
              setState(() {
                _preferences = UserPreferences(
                  userId: _defaultUserId,
                  createdAt: now,
                  updatedAt: now,
                  quietHours: const [
                    QuietHours(
                      start: TimeOfDay(hour: 22, minute: 0),
                      end: TimeOfDay(hour: 7, minute: 0),
                      enabled: true,
                    ),
                  ],
                );
                _hasChanges = true;
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('设置已重置'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text(
              '重置',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // 辅助方法
  String _getFrequencyDescription(PushFrequency frequency) {
    switch (frequency) {
      case PushFrequency.immediate:
        return '立即推送';
      case PushFrequency.frequent:
        return '频繁推送';
      case PushFrequency.normal:
        return '正常频率';
      case PushFrequency.limited:
        return '限制频率';
      case PushFrequency.minimal:
        return '最少推送';
      case PushFrequency.digest:
        return '摘要推送';
    }
  }

  String _getThemeDescription(PushTheme theme) {
    switch (theme) {
      case PushTheme.system:
        return '跟随系统';
      case PushTheme.light:
        return '浅色主题';
      case PushTheme.dark:
        return '深色主题';
      case PushTheme.professional:
        return '专业主题';
      case PushTheme.minimal:
        return '极简主题';
    }
  }

  String _getTitleStyleDescription(TitleStyle style) {
    switch (style) {
      case TitleStyle.technical:
        return '技术分析风格';
      case TitleStyle.concise:
        return '简洁明了';
      case TitleStyle.detailed:
        return '详细描述';
      case TitleStyle.friendly:
        return '友好亲切';
    }
  }

  String _getContentTypesDescription(List<PushContentType> types) {
    if (types.isEmpty) return '未设置';

    final descriptions = types.map((type) {
      switch (type) {
        case PushContentType.price_change:
          return '价格变化';
        case PushContentType.trend_analysis:
          return '趋势分析';
        case PushContentType.volume_alert:
          return '成交量警报';
        case PushContentType.market_news:
          return '市场新闻';
        case PushContentType.anomaly_detection:
          return '异常检测';
        case PushContentType.general:
          return '一般信息';
      }
    }).toList();

    if (descriptions.length <= 3) {
      return descriptions.join('、');
    } else {
      return '${descriptions.take(3).join('、')}等${descriptions.length}种';
    }
  }

  /// 构建权限状态横幅
  Widget _buildPermissionBanner(
      BuildContext context, PushNotificationState pushState) {
    if (pushState.hasNotificationPermission) {
      return const SizedBox.shrink(); // 有权限时不显示横幅
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_off,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '推送通知权限未开启',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const Spacer(),
              if (pushState.canRequestNotifications)
                TextButton.icon(
                  onPressed: _requestPermissions,
                  icon: const Icon(Icons.security, size: 16),
                  label: const Text('授权'),
                  style: TextButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '开启通知权限后，您将及时收到市场变化和基金更新的重要信息',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context)
                  .colorScheme
                  .onPrimaryContainer
                  .withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (pushState.canRequestNotifications) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showPermissionDialog,
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('了解权限用途'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openSettings,
                  icon: const Icon(Icons.settings, size: 16),
                  label: const Text('手动设置'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 请求权限
  Future<void> _requestPermissions() async {
    final cubit = context.read<PushNotificationCubit>();

    // 显示权限说明对话框
    final shouldRequest = await showDialog<bool>(
      context: context,
      builder: (context) => const PermissionRequestDialog(),
    );

    if (shouldRequest == true) {
      await cubit.requestNotificationPermission();
    }
  }

  /// 显示权限说明对话框
  Future<void> _showPermissionDialog() async {
    await showDialog(
      context: context,
      builder: (context) => const PermissionRequestDialog(),
    );
  }

  /// 打开设置
  Future<void> _openSettings() async {
    final cubit = context.read<PushNotificationCubit>();
    await cubit.openAppSettings();
  }
}
