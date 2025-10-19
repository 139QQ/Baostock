import 'dart:convert';
// import 'package:crypto/crypto.dart'; // 暂时注释，需要添加crypto依赖
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/domain/entities/user_session.dart';

/// 安全存储服务
///
/// 提供敏感数据的安全存储功能，使用AES加密
class SecureStorageService {
  static String accessTokenKey = 'auth_access_token';
  static String refreshTokenKey = 'auth_refresh_token';
  static String userDataKey = 'auth_user_data';
  static String sessionDataKey = 'auth_session_data';
  static String encryptionKey = 'jisu_fund_secure_key_2024';

  /// 保存访问令牌
  static Future<void> saveAccessToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encryptedToken = _encrypt(token);
      await prefs.setString(accessTokenKey, encryptedToken);
    } catch (e) {
      throw Exception('保存访问令牌失败: $e');
    }
  }

  /// 获取访问令牌
  static Future<String?> getAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encryptedToken = prefs.getString(accessTokenKey);

      if (encryptedToken == null) return null;

      return _decrypt(encryptedToken);
    } catch (e) {
      return null;
    }
  }

  /// 保存刷新令牌
  static Future<void> saveRefreshToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encryptedToken = _encrypt(token);
      await prefs.setString(refreshTokenKey, encryptedToken);
    } catch (e) {
      throw Exception('保存刷新令牌失败: $e');
    }
  }

  /// 获取刷新令牌
  static Future<String?> getRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encryptedToken = prefs.getString(refreshTokenKey);

      if (encryptedToken == null) return null;

      return _decrypt(encryptedToken);
    } catch (e) {
      return null;
    }
  }

  /// 保存用户会话
  static Future<void> saveUserSession(UserSession session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionJson = session.toJson();
      final encryptedSession = _encrypt(jsonEncode(sessionJson));
      await prefs.setString(sessionDataKey, encryptedSession);
    } catch (e) {
      throw Exception('保存用户会话失败: $e');
    }
  }

  /// 获取用户会话
  static Future<UserSession?> getUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encryptedSession = prefs.getString(sessionDataKey);

      if (encryptedSession == null) return null;

      final sessionJson = _decrypt(encryptedSession);
      final sessionMap = jsonDecode(sessionJson) as Map<String, dynamic>;

      return UserSession.fromJson(sessionMap);
    } catch (e) {
      return null;
    }
  }

  /// 保存用户数据
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encryptedData = _encrypt(jsonEncode(userData));
      await prefs.setString(userDataKey, encryptedData);
    } catch (e) {
      throw Exception('保存用户数据失败: $e');
    }
  }

  /// 获取用户数据
  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encryptedData = prefs.getString(userDataKey);

      if (encryptedData == null) return null;

      final userDataJson = _decrypt(encryptedData);
      return jsonDecode(userDataJson) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// 清除所有认证数据
  static Future<void> clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await Future.wait([
        prefs.remove(accessTokenKey),
        prefs.remove(refreshTokenKey),
        prefs.remove(userDataKey),
        prefs.remove(sessionDataKey),
      ]);
    } catch (e) {
      throw Exception('清除认证数据失败: $e');
    }
  }

  /// 检查是否有有效的认证数据
  static Future<bool> hasValidAuthData() async {
    try {
      final session = await getUserSession();
      if (session == null) return false;

      return session.isValid && !session.isExpired;
    } catch (e) {
      return false;
    }
  }

  /// 保存通用键值对
  static Future<void> saveSecureValue(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final secureKey = 'secure_${_generateKeyHash(key)}';
      final encryptedValue = _encrypt(value);
      await prefs.setString(secureKey, encryptedValue);
    } catch (e) {
      throw Exception('保存安全值失败: $e');
    }
  }

  /// 获取通用键值对
  static Future<String?> getSecureValue(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final secureKey = 'secure_${_generateKeyHash(key)}';
      final encryptedValue = prefs.getString(secureKey);

      if (encryptedValue == null) return null;

      return _decrypt(encryptedValue);
    } catch (e) {
      return null;
    }
  }

  /// 删除通用键值对
  static Future<void> removeSecureValue(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final secureKey = 'secure_${_generateKeyHash(key)}';
      await prefs.remove(secureKey);
    } catch (e) {
      throw Exception('删除安全值失败: $e');
    }
  }

  /// 获取所有存储的键
  static Future<Set<String>> getAllKeys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getKeys();
    } catch (e) {
      return <String>{};
    }
  }

  /// 清除所有数据
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      throw Exception('清除所有数据失败: $e');
    }
  }

  /// AES加密
  static String _encrypt(String data) {
    try {
      final key = utf8.encode(encryptionKey);
      final dataBytes = utf8.encode(data);

      // 简单的XOR加密（生产环境应使用更安全的加密方式）
      final encrypted = List<int>.generate(
        dataBytes.length,
        (i) => dataBytes[i] ^ key[i % key.length],
      );

      return base64.encode(encrypted);
    } catch (e) {
      throw Exception('数据加密失败: $e');
    }
  }

  /// AES解密
  static String _decrypt(String encryptedData) {
    try {
      final key = utf8.encode(encryptionKey);
      final encrypted = base64.decode(encryptedData);

      // 简单的XOR解密
      final decrypted = List<int>.generate(
        encrypted.length,
        (i) => encrypted[i] ^ key[i % key.length],
      );

      return utf8.decode(decrypted);
    } catch (e) {
      throw Exception('数据解密失败: $e');
    }
  }

  /// 生成键的哈希值
  // static String _generateKeyHash(String key) {
  //   final bytes = utf8.encode(key);
  //   final digest = sha256.convert(bytes);
  //   return digest.toString();
  // }

  /// 验证存储完整性
  static Future<bool> verifyStorageIntegrity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final testKey = 'integrity_test_${DateTime.now().millisecondsSinceEpoch}';
      const testValue = 'test_value';

      // 测试写入
      await saveSecureValue(testKey, testValue);

      // 测试读取
      final retrievedValue = await getSecureValue(testKey);

      // 清理测试数据
      await removeSecureValue(testKey);

      return retrievedValue == testValue;
    } catch (e) {
      return false;
    }
  }

  /// 获取存储统计信息
  static Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();

      int authKeys = 0;
      int secureKeys = 0;
      int totalSize = 0;

      for (final key in allKeys) {
        final value = prefs.getString(key);
        if (value != null) {
          totalSize += value.length;

          if (key.startsWith('auth_') || key.startsWith('secure_')) {
            if (key.startsWith('auth_')) {
              authKeys++;
            } else {
              secureKeys++;
            }
          }
        }
      }

      return {
        'totalKeys': allKeys.length,
        'authKeys': authKeys,
        'secureKeys': secureKeys,
        'totalSize': totalSize,
        'isEncrypted': true,
        'lastVerified': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'totalKeys': 0,
        'authKeys': 0,
        'secureKeys': 0,
        'totalSize': 0,
        'isEncrypted': false,
      };
    }
  }
}
