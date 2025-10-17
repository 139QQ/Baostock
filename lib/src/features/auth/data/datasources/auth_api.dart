import 'package:dio/dio.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../../../core/utils/logger.dart';

part 'auth_api.g.dart';

/// 认证API客户端
///
/// 处理所有与认证相关的API请求
class AuthApi {
  final Dio _dio;
  static String baseUrl = 'http://154.44.25.92:8080';

  AuthApi({Dio? dio}) : _dio = dio ?? Dio() {
    _setupInterceptors();
  }

  /// 设置拦截器
  void _setupInterceptors() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.sendTimeout = const Duration(seconds: 30);

    // 添加日志拦截器
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: false, // 不记录敏感信息
        responseBody: false,
        requestHeader: false,
        responseHeader: false,
        request: false,
        error: true,
        logPrint: (object) {
          AppLogger.info('AuthAPI: $object');
        },
      ),
    );

    // 添加错误处理拦截器
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          AppLogger.error('AuthAPI Error', error.toString());
          handler.next(error);
        },
      ),
    );
  }

  /// 手机号登录
  Future<AuthResponse> loginWithPhone({
    required String phoneNumber,
    required String verificationCode,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login/phone',
        data: {
          'phone_number': phoneNumber,
          'verification_code': verificationCode,
        },
      );

      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(message: '登录请求失败: $e');
    }
  }

  /// 邮箱登录
  Future<AuthResponse> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login/email',
        data: {
          'email': email,
          'password': password,
        },
      );

      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(message: '登录请求失败: $e');
    }
  }

  /// 发送手机验证码
  Future<VerificationCodeResponse> sendPhoneVerificationCode({
    required String phoneNumber,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/verification/send-phone',
        data: {
          'phone_number': phoneNumber,
        },
      );

      return VerificationCodeResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(message: '发送验证码失败: $e');
    }
  }

  /// 发送邮箱验证码
  Future<VerificationCodeResponse> sendEmailVerificationCode({
    required String email,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/verification/send-email',
        data: {
          'email': email,
        },
      );

      return VerificationCodeResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(message: '发送验证码失败: $e');
    }
  }

  /// 刷新访问令牌
  Future<AuthResponse> refreshToken({
    required String refreshToken,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/refresh',
        data: {
          'refresh_token': refreshToken,
        },
      );

      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(message: '刷新令牌失败: $e');
    }
  }

  /// 获取用户信息
  Future<UserInfoResponse> getUserInfo({
    required String userId,
    String? accessToken,
  }) async {
    try {
      final options = Options();
      if (accessToken != null) {
        options.headers = {
          'Authorization': 'Bearer $accessToken',
        };
      }

      final response = await _dio.get(
        '/auth/user/$userId',
        options: options,
      );

      return UserInfoResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(message: '获取用户信息失败: $e');
    }
  }

  /// 用户注册（手机号）
  Future<RegisterResponse> registerWithPhone({
    required String phoneNumber,
    required String verificationCode,
    required String password,
    required String displayName,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register/phone',
        data: {
          'phone_number': phoneNumber,
          'verification_code': verificationCode,
          'password': password,
          'display_name': displayName,
        },
      );

      return RegisterResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(message: '注册失败: $e');
    }
  }

  /// 用户注册（邮箱）
  Future<RegisterResponse> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register/email',
        data: {
          'email': email,
          'password': password,
          'display_name': displayName,
        },
      );

      return RegisterResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(message: '注册失败: $e');
    }
  }

  /// 处理Dio错误
  ApiException _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: '网络连接超时，请检查网络设置',
          code: 'NETWORK_TIMEOUT',
        );

      case DioExceptionType.connectionError:
        return ApiException(
          message: '网络连接失败，请检查网络设置',
          code: 'CONNECTION_ERROR',
        );

      case DioExceptionType.badResponse:
        return _handleHttpError(e.response?.statusCode, e.response?.data);

      case DioExceptionType.cancel:
        return ApiException(
          message: '请求已取消',
          code: 'REQUEST_CANCELLED',
        );

      case DioExceptionType.unknown:
      default:
        return ApiException(
          message: '网络请求失败: ${e.message}',
          code: 'UNKNOWN_ERROR',
        );
    }
  }

  /// 处理HTTP错误
  ApiException _handleHttpError(int? statusCode, dynamic responseData) {
    final message = _extractErrorMessage(responseData);

    switch (statusCode) {
      case 400:
        return ApiException(
          message: message ?? '请求参数错误',
          code: 'BAD_REQUEST',
        );

      case 401:
        return ApiException(
          message: message ?? '认证失败，请重新登录',
          code: 'UNAUTHORIZED',
        );

      case 403:
        return ApiException(
          message: message ?? '访问被拒绝',
          code: 'FORBIDDEN',
        );

      case 404:
        return ApiException(
          message: message ?? '请求的资源不存在',
          code: 'NOT_FOUND',
        );

      case 429:
        return ApiException(
          message: message ?? '请求过于频繁，请稍后重试',
          code: 'RATE_LIMIT_EXCEEDED',
        );

      case 500:
        return ApiException(
          message: message ?? '服务器内部错误',
          code: 'INTERNAL_SERVER_ERROR',
        );

      case 502:
      case 503:
      case 504:
        return ApiException(
          message: message ?? '服务器暂时不可用，请稍后重试',
          code: 'SERVICE_UNAVAILABLE',
        );

      default:
        return ApiException(
          message: message ?? '请求失败，状态码: $statusCode',
          code: 'HTTP_ERROR_$statusCode',
        );
    }
  }

  /// 提取错误消息
  String? _extractErrorMessage(dynamic responseData) {
    if (responseData == null) return null;

    if (responseData is Map<String, dynamic>) {
      // 尝试常见的错误消息字段
      final messageFields = [
        'message',
        'error',
        'detail',
        'description',
        'msg',
      ];

      for (final field in messageFields) {
        if (responseData.containsKey(field) && responseData[field] is String) {
          return responseData[field] as String;
        }
      }

      // 如果是嵌套的错误结构
      if (responseData.containsKey('error') && responseData['error'] is Map) {
        final errorMap = responseData['error'] as Map<String, dynamic>;
        for (final field in messageFields) {
          if (errorMap.containsKey(field) && errorMap[field] is String) {
            return errorMap[field] as String;
          }
        }
      }
    }

    return null;
  }
}

/// 认证响应模型
@JsonSerializable()
class AuthResponse {
  final bool success;
  final String? accessToken;
  final String? refreshToken;
  final int? expiresIn;
  final UserInfoResponse? user;
  final String? message;

  AuthResponse({
    required this.success,
    this.accessToken,
    this.refreshToken,
    this.expiresIn,
    this.user,
    this.message,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}

/// 用户信息响应模型
@JsonSerializable()
class UserInfoResponse {
  final String id;
  final String phoneNumber;
  final String? email;
  final String displayName;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final bool isEmailVerified;
  final bool isPhoneVerified;

  UserInfoResponse({
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

  factory UserInfoResponse.fromJson(Map<String, dynamic> json) =>
      _$UserInfoResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UserInfoResponseToJson(this);
}

/// 验证码响应模型
@JsonSerializable()
class VerificationCodeResponse {
  final bool success;
  final String? messageId;
  final int? cooldownSeconds;
  final String? message;

  VerificationCodeResponse({
    required this.success,
    this.messageId,
    this.cooldownSeconds,
    this.message,
  });

  factory VerificationCodeResponse.fromJson(Map<String, dynamic> json) =>
      _$VerificationCodeResponseFromJson(json);

  Map<String, dynamic> toJson() => _$VerificationCodeResponseToJson(this);
}

/// 注册响应模型
@JsonSerializable()
class RegisterResponse {
  final bool success;
  final UserInfoResponse? user;
  final String? message;

  RegisterResponse({
    required this.success,
    this.user,
    this.message,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) =>
      _$RegisterResponseFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterResponseToJson(this);
}

/// API异常类
class ApiException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  ApiException({
    required this.message,
    this.code,
    this.statusCode,
  });

  @override
  String toString() {
    final buffer = StringBuffer('ApiException: $message');
    if (code != null) buffer.write(' (code: $code)');
    if (statusCode != null) buffer.write(' (status: $statusCode)');
    return buffer.toString();
  }
}
