import 'package:equatable/equatable.dart';
import 'package:permission_handler/permission_handler.dart';

/// 权限请求记录模型
///
/// 用于记录每次权限请求的详细信息，包括：
/// - 请求时间和权限类型
/// - 请求结果和状态
/// - 请求上下文（哪个功能触发的）
/// - 用户响应情况
/// - 重试次数统计
class PermissionRequestRecord extends Equatable {
  /// 唯一标识符
  final String id;

  /// 权限类型
  final Permission permission;

  /// 权限名称（便于显示）
  final String permissionName;

  /// 请求时间
  final DateTime requestTime;

  /// 请求结果状态
  final PermissionStatus status;

  /// 触发请求的功能模块
  final String featureModule;

  /// 请求上下文描述
  final String context;

  /// 是否是首次请求
  final bool isFirstRequest;

  /// 重试次数
  final int retryCount;

  /// 是否显示了权限说明
  final bool showedRationale;

  /// 请求耗时（毫秒）
  final int durationMs;

  /// 设备信息
  final Map<String, String>? deviceInfo;

  /// 应用版本信息
  final String? appVersion;

  const PermissionRequestRecord({
    required this.id,
    required this.permission,
    required this.permissionName,
    required this.requestTime,
    required this.status,
    required this.featureModule,
    required this.context,
    this.isFirstRequest = true,
    this.retryCount = 0,
    this.showedRationale = false,
    this.durationMs = 0,
    this.deviceInfo,
    this.appVersion,
  });

  /// 从JSON创建实例
  factory PermissionRequestRecord.fromJson(Map<String, dynamic> json) {
    return PermissionRequestRecord(
      id: json['id'] as String,
      permission: _parsePermission(json['permission'] as String),
      permissionName: json['permissionName'] as String,
      requestTime: DateTime.parse(json['requestTime'] as String),
      status: _parsePermissionStatus(json['status'] as String),
      featureModule: json['featureModule'] as String,
      context: json['context'] as String,
      isFirstRequest: json['isFirstRequest'] as bool? ?? true,
      retryCount: json['retryCount'] as int? ?? 0,
      showedRationale: json['showedRationale'] as bool? ?? false,
      durationMs: json['durationMs'] as int? ?? 0,
      deviceInfo:
          (json['deviceInfo'] as Map<String, dynamic>?)?.cast<String, String>(),
      appVersion: json['appVersion'] as String?,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'permission': permission.toString(),
      'permissionName': permissionName,
      'requestTime': requestTime.toIso8601String(),
      'status': status.toString(),
      'featureModule': featureModule,
      'context': context,
      'isFirstRequest': isFirstRequest,
      'retryCount': retryCount,
      'showedRationale': showedRationale,
      'durationMs': durationMs,
      'deviceInfo': deviceInfo,
      'appVersion': appVersion,
    };
  }

  /// 解析权限类型
  static Permission _parsePermission(String permissionStr) {
    switch (permissionStr) {
      case 'Permission.notification':
        return Permission.notification;
      case 'Permission.camera':
        return Permission.camera;
      case 'Permission.photos':
        return Permission.photos;
      case 'Permission.storage':
        return Permission.storage;
      case 'Permission.microphone':
        return Permission.microphone;
      case 'Permission.location':
        return Permission.location;
      case 'Permission.systemAlertWindow':
        return Permission.systemAlertWindow;
      case 'Permission.ignoreBatteryOptimizations':
        return Permission.ignoreBatteryOptimizations;
      default:
        return Permission.unknown;
    }
  }

  /// 解析权限状态
  static PermissionStatus _parsePermissionStatus(String statusStr) {
    switch (statusStr) {
      case 'PermissionStatus.granted':
        return PermissionStatus.granted;
      case 'PermissionStatus.denied':
        return PermissionStatus.denied;
      case 'PermissionStatus.restricted':
        return PermissionStatus.restricted;
      case 'PermissionStatus.limited':
        return PermissionStatus.limited;
      case 'PermissionStatus.permanentlyDenied':
        return PermissionStatus.permanentlyDenied;
      case 'PermissionStatus.provisional':
        return PermissionStatus.provisional;
      default:
        return PermissionStatus.denied;
    }
  }

  /// 创建副本
  PermissionRequestRecord copyWith({
    String? id,
    Permission? permission,
    String? permissionName,
    DateTime? requestTime,
    PermissionStatus? status,
    String? featureModule,
    String? context,
    bool? isFirstRequest,
    int? retryCount,
    bool? showedRationale,
    int? durationMs,
    Map<String, String>? deviceInfo,
    String? appVersion,
  }) {
    return PermissionRequestRecord(
      id: id ?? this.id,
      permission: permission ?? this.permission,
      permissionName: permissionName ?? this.permissionName,
      requestTime: requestTime ?? this.requestTime,
      status: status ?? this.status,
      featureModule: featureModule ?? this.featureModule,
      context: context ?? this.context,
      isFirstRequest: isFirstRequest ?? this.isFirstRequest,
      retryCount: retryCount ?? this.retryCount,
      showedRationale: showedRationale ?? this.showedRationale,
      durationMs: durationMs ?? this.durationMs,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      appVersion: appVersion ?? this.appVersion,
    );
  }

  /// 是否请求成功
  bool get isGranted => status.isGranted;

  /// 是否被拒绝
  bool get isDenied => status.isDenied;

  /// 是否被永久拒绝
  bool get isPermanentlyDenied => status.isPermanentlyDenied;

  /// 是否被限制
  bool get isLimited => status.isLimited;

  /// 是否需要用户手动设置
  bool get requiresManualAction => isPermanentlyDenied || isLimited;

  /// 获取状态描述
  String get statusDescription {
    switch (status) {
      case PermissionStatus.granted:
        return '已授权';
      case PermissionStatus.denied:
        return '被拒绝';
      case PermissionStatus.restricted:
        return '受限制';
      case PermissionStatus.limited:
        return '部分授权';
      case PermissionStatus.permanentlyDenied:
        return '永久拒绝';
      case PermissionStatus.provisional:
        return '临时授权';
    }
  }

  /// 获取权限类型描述
  String get permissionTypeDescription {
    switch (permission) {
      case Permission.notification:
        return '通知权限';
      case Permission.camera:
        return '相机权限';
      case Permission.photos:
        return '照片权限';
      case Permission.storage:
        return '存储权限';
      case Permission.microphone:
        return '麦克风权限';
      case Permission.location:
        return '位置权限';
      case Permission.locationWhenInUse:
        return '使用期间位置权限';
      case Permission.locationAlways:
        return '始终位置权限';
      case Permission.phone:
        return '电话权限';
      case Permission.contacts:
        return '联系人权限';
      case Permission.calendarReadOnly:
        return '日历只读权限';
      case Permission.calendarFullAccess:
        return '日历完全访问权限';
      case Permission.reminders:
        return '提醒权限';
      case Permission.mediaLibrary:
        return '媒体库权限';
      case Permission.photosAddOnly:
        return '照片添加权限';
      case Permission.criticalAlerts:
        return '关键警报权限';
      case Permission.unknown:
        return '未知权限';
      case Permission.systemAlertWindow:
        return '悬浮窗权限';
      case Permission.manageExternalStorage:
        return '外部存储管理权限';
      case Permission.accessNotificationPolicy:
        return '通知策略权限';
      case Permission.ignoreBatteryOptimizations:
        return '忽略电池优化权限';
      case Permission.requestInstallPackages:
        return '安装应用权限';
      case Permission.bluetooth:
        return '蓝牙权限';
      case Permission.bluetoothAdvertise:
        return '蓝牙广播权限';
      case Permission.bluetoothConnect:
        return '蓝牙连接权限';
      case Permission.bluetoothScan:
        return '蓝牙扫描权限';
      case Permission.nearbyWifiDevices:
        return '附近WiFi设备权限';
      case Permission.videos:
        return '视频权限';
      case Permission.audio:
        return '音频权限';
      case Permission.scheduleExactAlarm:
        return '精确闹钟权限';
      case Permission.sensors:
        return '传感器权限';
      case Permission.activityRecognition:
        return '活动识别权限';
      case Permission.unknown:
      default:
        return '未知权限';
    }
  }

  @override
  List<Object?> get props => [
        id,
        permission,
        permissionName,
        requestTime,
        status,
        featureModule,
        context,
        isFirstRequest,
        retryCount,
        showedRationale,
        durationMs,
        deviceInfo,
        appVersion,
      ];

  @override
  String toString() {
    return 'PermissionRequestRecord('
        'id: $id, '
        'permission: ${permissionTypeDescription}, '
        'status: $statusDescription, '
        'feature: $featureModule, '
        'time: $requestTime'
        ')';
  }
}

/// 权限请求上下文枚举
enum PermissionRequestContext {
  startup('应用启动'),
  featureFirstUse('功能首次使用'),
  manualRequest('用户手动请求'),
  systemTriggered('系统触发'),
  retry('重试请求');

  const PermissionRequestContext(this.description);
  final String description;
}

/// 权限请求优先级枚举
enum PermissionRequestPriority {
  low('低优先级'),
  normal('普通优先级'),
  high('高优先级'),
  critical('关键优先级');

  const PermissionRequestPriority(this.description);
  final String description;
}
