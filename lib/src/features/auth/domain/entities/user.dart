import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

/// 用户实体类
///
/// 包含用户的基本信息和认证状态，支持手机号和邮箱两种认证方式
@JsonSerializable()
class User extends Equatable {
  /// 用户唯一标识
  final String id;

  /// 手机号码
  final String phoneNumber;

  /// 邮箱地址（可选）
  final String? email;

  /// 显示名称
  final String displayName;

  /// 头像URL（可选）
  final String? avatarUrl;

  /// 账户创建时间
  @JsonKey(fromJson: _fromJsonDateTime, toJson: _toJsonDateTime)
  final DateTime createdAt;

  /// 最后登录时间
  @JsonKey(fromJson: _fromJsonDateTime, toJson: _toJsonDateTime)
  final DateTime lastLoginAt;

  /// 邮箱是否已验证
  final bool isEmailVerified;

  /// 手机号是否已验证
  final bool isPhoneVerified;

  const User({
    required this.id,
    required this.phoneNumber,
    this.email,
    required this.displayName,
    this.avatarUrl,
    required this.createdAt,
    required this.lastLoginAt,
    required this.isEmailVerified,
    required this.isPhoneVerified,
  });

  /// 从JSON创建User实例
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  /// 转换为JSON
  Map<String, dynamic> toJson() => _$UserToJson(this);

  /// 创建User副本
  User copyWith({
    String? id,
    String? phoneNumber,
    String? email,
    String? displayName,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isEmailVerified,
    bool? isPhoneVerified,
  }) {
    return User(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
    );
  }

  /// 验证手机号格式
  bool get isPhoneNumberValid {
    return RegExp(r'^1[3-9]\d{9}$').hasMatch(phoneNumber);
  }

  /// 验证邮箱格式
  bool get isEmailValid {
    if (email == null || email!.isEmpty) return false;
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email!);
  }

  /// 获取用户显示名称（优先使用displayName，其次使用脱敏手机号）
  String get displayText {
    if (displayName.isNotEmpty) return displayName;

    // 手机号脱敏显示：138****1234
    if (phoneNumber.length >= 11) {
      return '${phoneNumber.substring(0, 3)}****${phoneNumber.substring(7)}';
    }

    return phoneNumber;
  }

  @override
  List<Object?> get props => [
        id,
        phoneNumber,
        email,
        displayName,
        avatarUrl,
        createdAt,
        lastLoginAt,
        isEmailVerified,
        isPhoneVerified,
      ];

  @override
  String toString() {
    return 'User(id: $id, displayName: $displayName, phoneNumber: $phoneNumber, email: $email)';
  }

  /// DateTime JSON序列化辅助方法
  static DateTime _fromJsonDateTime(dynamic json) {
    if (json == null) return DateTime.now();
    if (json is String) return DateTime.parse(json);
    if (json is int) return DateTime.fromMillisecondsSinceEpoch(json);
    return DateTime.now();
  }

  static dynamic _toJsonDateTime(DateTime dateTime) {
    return dateTime.toIso8601String();
  }

  /// 创建测试用户
  static User testUser({
    String id = 'test_user_001',
    String phoneNumber = '13812345678',
    String? email = 'test@example.com',
    String displayName = '测试用户',
  }) {
    final now = DateTime.now();
    return User(
      id: id,
      phoneNumber: phoneNumber,
      email: email,
      displayName: displayName,
      createdAt: now.subtract(const Duration(days: 30)),
      lastLoginAt: now,
      isEmailVerified: email != null,
      isPhoneVerified: true,
    );
  }
}
