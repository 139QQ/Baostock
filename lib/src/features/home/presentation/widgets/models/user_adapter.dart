import 'package:jisu_fund_analyzer/src/features/auth/domain/entities/user.dart';

/// 用户适配器
///
/// 将现有的认证用户实体适配为多平台导航组件所需的格式
/// 避免重复定义用户模型，确保数据一致性
class UserAdapter {
  /// 将认证用户转换为导航用户
  static NavigationUser fromAuthUser(User authUser) {
    return NavigationUser(
      displayText: authUser.displayText,
      avatarUrl: authUser.avatarUrl,
      id: authUser.id,
      email: authUser.email,
      phone: authUser.phoneNumber,
      level: _getUserLevel(authUser),
      status: _getUserStatus(authUser),
    );
  }

  /// 将导航用户转换为认证用户（如果需要）
  static User toAuthUser(NavigationUser navUser) {
    final now = DateTime.now();
    return User(
      id: navUser.id ?? 'unknown',
      phoneNumber: navUser.phone ?? '00000000000',
      displayName: navUser.displayText,
      avatarUrl: navUser.avatarUrl,
      email: navUser.email,
      createdAt: now.subtract(const Duration(days: 30)),
      lastLoginAt: now,
      isEmailVerified: navUser.email != null,
      isPhoneVerified: navUser.phone != null,
    );
  }

  /// 获取用户等级
  static String _getUserLevel(User user) {
    // 根据用户的注册时间和其他因素确定等级
    final daysSinceCreation = DateTime.now().difference(user.createdAt).inDays;

    if (daysSinceCreation >= 365) {
      return 'VIP';
    } else if (daysSinceCreation >= 180) {
      return '高级';
    } else if (daysSinceCreation >= 30) {
      return '标准';
    } else {
      return '新用户';
    }
  }

  /// 获取用户状态
  static UserStatus _getUserStatus(User user) {
    // 检查用户的验证状态
    if (user.isEmailVerified && user.isPhoneVerified) {
      return UserStatus.active;
    } else if (user.isPhoneVerified) {
      return UserStatus.pending;
    } else {
      return UserStatus.inactive;
    }
  }

  /// 创建演示用户
  static NavigationUser createDemoUser() {
    return fromAuthUser(User.testUser(
      id: 'demo_user_001',
      phoneNumber: '13800138000',
      email: 'demo@jisu-fund.com',
      displayName: '演示用户',
    ));
  }
}

/// 导航用户实体
///
/// 多平台导航组件使用的简化用户模型
/// 通过适配器与现有认证系统集成
class NavigationUser {
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

  const NavigationUser({
    required this.displayText,
    this.avatarUrl,
    this.id,
    this.email,
    this.phone,
    this.level,
    this.status,
  });

  /// 从JSON创建导航用户实例
  factory NavigationUser.fromJson(Map<String, dynamic> json) {
    return NavigationUser(
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
  NavigationUser copyWith({
    String? displayText,
    String? avatarUrl,
    String? id,
    String? email,
    String? phone,
    String? level,
    UserStatus? status,
  }) {
    return NavigationUser(
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
    return other is NavigationUser &&
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
    return 'NavigationUser(displayText: $displayText, id: $id, level: $level)';
  }
}

/// 用户状态枚举（与user_model.dart保持一致）
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

/// 用户状态扩展方法（与user_model.dart保持一致）
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
