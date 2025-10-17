import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_session.g.dart';

/// 用户会话实体类
///
/// 管理用户的认证状态和令牌信息
@JsonSerializable()
class UserSession extends Equatable {
  /// 用户ID
  final String userId;

  /// 访问令牌
  final String accessToken;

  /// 刷新令牌
  final String refreshToken;

  /// 令牌过期时间
  @JsonKey(fromJson: _fromJsonDateTime, toJson: _toJsonDateTime)
  final DateTime expiresAt;

  /// 会话是否有效
  final bool isValid;

  /// 令牌类型（默认Bearer）
  final String tokenType;

  /// 会话创建时间
  @JsonKey(fromJson: _fromJsonDateTime, toJson: _toJsonDateTime)
  final DateTime createdAt;

  /// 最后活跃时间
  @JsonKey(fromJson: _fromJsonDateTime, toJson: _toJsonDateTime)
  final DateTime lastActiveAt;

  const UserSession({
    required this.userId,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.isValid,
    this.tokenType = 'Bearer',
    required this.createdAt,
    required this.lastActiveAt,
  });

  /// 从JSON创建UserSession实例
  factory UserSession.fromJson(Map<String, dynamic> json) =>
      _$UserSessionFromJson(json);

  /// 转换为JSON
  Map<String, dynamic> toJson() => _$UserSessionToJson(this);

  /// 检查令牌是否已过期
  bool get isExpired {
    return DateTime.now().isAfter(expiresAt);
  }

  /// 检查令牌是否即将过期（5分钟内）
  bool get isExpiringSoon {
    final fiveMinutesFromNow = DateTime.now().add(const Duration(minutes: 5));
    return fiveMinutesFromNow.isAfter(expiresAt);
  }

  /// 获取令牌剩余有效时间（秒）
  int get remainingSeconds {
    final remaining = expiresAt.difference(DateTime.now());
    return remaining.inSeconds > 0 ? remaining.inSeconds : 0;
  }

  /// 获取完整的认证头
  String get authorizationHeader {
    return '$tokenType $accessToken';
  }

  /// 创建会话副本
  UserSession copyWith({
    String? userId,
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    bool? isValid,
    String? tokenType,
    DateTime? createdAt,
    DateTime? lastActiveAt,
  }) {
    return UserSession(
      userId: userId ?? this.userId,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
      isValid: isValid ?? this.isValid,
      tokenType: tokenType ?? this.tokenType,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  /// 更新最后活跃时间
  UserSession updateLastActive() {
    return copyWith(lastActiveAt: DateTime.now());
  }

  /// 标记会话为无效
  UserSession invalidate() {
    return copyWith(isValid: false);
  }

  /// 延长会话过期时间
  UserSession extend(Duration duration) {
    return copyWith(expiresAt: expiresAt.add(duration));
  }

  @override
  List<Object?> get props => [
        userId,
        accessToken,
        refreshToken,
        expiresAt,
        isValid,
        tokenType,
        createdAt,
        lastActiveAt,
      ];

  @override
  String toString() {
    return 'UserSession(userId: $userId, isValid: $isValid, expiresAt: $expiresAt)';
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

  /// 创建测试会话
  static UserSession testSession({
    String userId = 'test_user_001',
    Duration expiresIn = const Duration(hours: 1),
  }) {
    final now = DateTime.now();
    return UserSession(
      userId: userId,
      accessToken: 'test_access_token_${now.millisecondsSinceEpoch}',
      refreshToken: 'test_refresh_token_${now.millisecondsSinceEpoch}',
      expiresAt: now.add(expiresIn),
      isValid: true,
      createdAt: now,
      lastActiveAt: now,
    );
  }
}
