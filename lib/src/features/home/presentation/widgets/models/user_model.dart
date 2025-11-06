/// 用户模型
///
/// 统一的用户数据模型，避免在不同文件中重复定义
class User {
  /// 用户显示名称
  final String displayText;

  /// 用户头像URL（可选）
  final String? avatarUrl;

  /// 用户ID（可选）
  final String? id;

  /// 用户邮箱（可选）
  final String? email;

  /// 用户手机号（可选）
  final String? phone;

  /// 用户等级（可选）
  final String? level;

  /// 用户状态（可选）
  final UserStatus? status;

  const User({
    required this.displayText,
    this.avatarUrl,
    this.id,
    this.email,
    this.phone,
    this.level,
    this.status,
  });

  /// 从JSON创建用户实例
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      displayText: json['displayText'] ?? json['name'] ?? '未知用户',
      avatarUrl: json['avatarUrl'],
      id: json['id'],
      email: json['email'],
      phone: json['phone'],
      level: json['level'],
      status: json['status'] != null
          ? UserStatus.values.firstWhere(
              (e) => e.toString() == 'UserStatus.${json['status']}',
              orElse: () => UserStatus.active,
            )
          : UserStatus.active,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'displayText': displayText,
      'avatarUrl': avatarUrl,
      'id': id,
      'email': email,
      'phone': phone,
      'level': level,
      'status': status?.toString().split('.').last,
    };
  }

  /// 创建副本
  User copyWith({
    String? displayText,
    String? avatarUrl,
    String? id,
    String? email,
    String? phone,
    String? level,
    UserStatus? status,
  }) {
    return User(
      displayText: displayText ?? this.displayText,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      level: level ?? this.level,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.displayText == displayText &&
        other.avatarUrl == avatarUrl &&
        other.id == id;
  }

  @override
  int get hashCode {
    return displayText.hashCode ^ avatarUrl.hashCode ^ id.hashCode;
  }

  @override
  String toString() {
    return 'User(displayText: $displayText, id: $id)';
  }
}

/// 用户状态枚举
enum UserStatus {
  /// 活跃状态
  active,

  /// 未激活
  inactive,

  /// 已封禁
  banned,

  /// 待验证
  pending,

  /// 已过期
  expired,
}

/// 用户状态扩展方法
extension UserStatusExtension on UserStatus {
  /// 获取状态显示文本
  String get displayName {
    switch (this) {
      case UserStatus.active:
        return '活跃';
      case UserStatus.inactive:
        return '未激活';
      case UserStatus.banned:
        return '已封禁';
      case UserStatus.pending:
        return '待验证';
      case UserStatus.expired:
        return '已过期';
    }
  }

  /// 获取状态颜色
  String get color {
    switch (this) {
      case UserStatus.active:
        return '#4CAF50'; // 绿色
      case UserStatus.inactive:
        return '#9E9E9E'; // 灰色
      case UserStatus.banned:
        return '#F44336'; // 红色
      case UserStatus.pending:
        return '#FF9800'; // 橙色
      case UserStatus.expired:
        return '#795548'; // 棕色
    }
  }
}
