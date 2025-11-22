import 'package:flutter_test/flutter_test.dart';
import 'package:crypto/crypto.dart';
import 'package:jisu_fund_analyzer/src/services/security/security_utils.dart';

void main() {
  group('SecurityUtils - Story R.2 安全组件测试套件', () {
    group('API签名生成和验证测试', () {
      test('应该生成一致的API签名', () {
        final method = 'GET';
        final path = '/api/fund';
        final params = {'fund_code': '000001', 'page': '1'};
        final timestamp = DateTime.now().toIso8601String();
        final requestId = 'test-request-123';

        final signature1 = SecurityUtils.generateSignature(
          method: method,
          path: path,
          params: params,
          timestamp: timestamp,
          requestId: requestId,
        );

        final signature2 = SecurityUtils.generateSignature(
          method: method,
          path: path,
          params: params,
          timestamp: timestamp,
          requestId: requestId,
        );

        expect(signature1, equals(signature2));
        expect(signature1.length, equals(64)); // SHA256 hex length
      });

      test('不同参数应该生成不同的签名', () {
        final method = 'GET';
        final path = '/api/fund';
        final timestamp = DateTime.now().toIso8601String();
        final requestId = 'test-request-123';

        final signature1 = SecurityUtils.generateSignature(
          method: method,
          path: path,
          params: {'fund_code': '000001'},
          timestamp: timestamp,
          requestId: requestId,
        );

        final signature2 = SecurityUtils.generateSignature(
          method: method,
          path: path,
          params: {'fund_code': '000002'},
          timestamp: timestamp,
          requestId: requestId,
        );

        expect(signature1, isNot(equals(signature2)));
      });

      test('应该验证有效的签名', () {
        final method = 'POST';
        final path = '/api/portfolio';
        final params = {'user_id': 'test-user', 'action': 'update'};
        final timestamp = DateTime.now().toIso8601String();
        final requestId = 'test-request-456';

        final signature = SecurityUtils.generateSignature(
          method: method,
          path: path,
          params: params,
          timestamp: timestamp,
          requestId: requestId,
        );

        final isValid = SecurityUtils.verifySignature(
          method: method,
          path: path,
          params: params,
          timestamp: timestamp,
          requestId: requestId,
          receivedSignature: signature,
        );

        expect(isValid, isTrue);
      });

      test('应该拒绝无效的签名', () {
        final method = 'GET';
        final path = '/api/fund';
        final params = {'fund_code': '000001'};
        final timestamp = DateTime.now().toIso8601String();
        final requestId = 'test-request-789';
        final invalidSignature = 'invalid-signature';

        final isValid = SecurityUtils.verifySignature(
          method: method,
          path: path,
          params: params,
          timestamp: timestamp,
          requestId: requestId,
          receivedSignature: invalidSignature,
        );

        expect(isValid, isFalse);
      });

      test('应该拒绝过期的签名', () {
        final method = 'GET';
        final path = '/api/fund';
        final params = {'fund_code': '000001'};
        final expiredTimestamp =
            DateTime.now().subtract(Duration(minutes: 10)).toIso8601String();
        final requestId = 'test-request-999';

        final signature = SecurityUtils.generateSignature(
          method: method,
          path: path,
          params: params,
          timestamp: expiredTimestamp,
          requestId: requestId,
        );

        final isValid = SecurityUtils.verifySignature(
          method: method,
          path: path,
          params: params,
          timestamp: expiredTimestamp,
          requestId: requestId,
          receivedSignature: signature,
        );

        expect(isValid, isFalse); // 时间戳过期
      });
    });

    group('请求ID和时间戳生成测试', () {
      test('应该生成唯一的请求ID', () {
        final requestId1 = SecurityUtils.generateRequestId();
        final requestId2 = SecurityUtils.generateRequestId();

        expect(requestId1, isNot(equals(requestId2)));
        expect(requestId1.length, equals(36)); // UUID v4 length
        expect(requestId2.length, equals(36));
      });

      test('应该生成有效的时间戳', () {
        final timestamp = SecurityUtils.generateTimestamp();
        final parsedTime = DateTime.parse(timestamp);

        expect(parsedTime, isA<DateTime>());
        expect(DateTime.now().difference(parsedTime).inSeconds, lessThan(1));
      });
    });

    group('输入验证测试', () {
      test('应该验证有效的基金代码', () {
        expect(SecurityUtils.isValidFundCode('000001'), isTrue);
        expect(SecurityUtils.isValidFundCode('123456'), isTrue);
        expect(SecurityUtils.isValidFundCode('519888'), isTrue);
      });

      test('应该拒绝无效的基金代码', () {
        expect(SecurityUtils.isValidFundCode('abcdef'), isFalse);
        expect(SecurityUtils.isValidFundCode('12345'), isFalse); // 太短
        expect(SecurityUtils.isValidFundCode('1234567'), isFalse); // 太长
        expect(SecurityUtils.isValidFundCode('000001a'), isFalse); // 包含字母
        expect(SecurityUtils.isValidFundCode(''), isFalse); // 空
        expect(SecurityUtils.isValidFundCode(null), isFalse); // null
      });

      test('应该验证有效的用户ID', () {
        expect(SecurityUtils.isValidUserId('test_user'), isTrue);
        expect(SecurityUtils.isValidUserId('user123'), isTrue);
        expect(SecurityUtils.isValidUserId('Test_User_123'), isTrue);
      });

      test('应该拒绝无效的用户ID', () {
        expect(SecurityUtils.isValidUserId(''), isFalse); // 空
        expect(SecurityUtils.isValidUserId('ab'), isFalse); // 太短
        expect(SecurityUtils.isValidUserId('a' * 51), isFalse); // 太长
        expect(SecurityUtils.isValidUserId('user@domain'), isFalse); // 包含特殊字符
        expect(SecurityUtils.isValidUserId(null), isFalse); // null
      });

      test('应该验证有效的金额', () {
        expect(SecurityUtils.isValidAmount(100.0), isTrue);
        expect(SecurityUtils.isValidAmount(0.01), isTrue);
        expect(SecurityUtils.isValidAmount(999999999.99), isTrue);
        expect(SecurityUtils.isValidAmount('100.50'), isTrue);
        expect(SecurityUtils.isValidAmount('0'), isTrue);
      });

      test('应该拒绝无效的金额', () {
        expect(SecurityUtils.isValidAmount(-1.0), isFalse); // 负数
        expect(SecurityUtils.isValidAmount(0.0), isFalse); // 零
        expect(SecurityUtils.isValidAmount(1000000000.0), isFalse); // 超过上限
        expect(SecurityUtils.isValidAmount('abc'), isFalse); // 非数字
        expect(SecurityUtils.isValidAmount(''), isFalse); // 空
        expect(SecurityUtils.isValidAmount(null), isFalse); // null
      });

      test('应该验证有效的分页参数', () {
        expect(SecurityUtils.isValidPagination(page: 1, limit: 20), isTrue);
        expect(SecurityUtils.isValidPagination(page: 100, limit: 100), isTrue);
        expect(SecurityUtils.isValidPagination(page: 1, limit: 50), isTrue);
      });

      test('应该拒绝无效的分页参数', () {
        expect(SecurityUtils.isValidPagination(page: 0, limit: 20),
            isFalse); // 页码从1开始
        expect(SecurityUtils.isValidPagination(page: -1, limit: 20),
            isFalse); // 负页码
        expect(
            SecurityUtils.isValidPagination(page: 1, limit: 0), isFalse); // 零限制
        expect(SecurityUtils.isValidPagination(page: 1, limit: -1),
            isFalse); // 负限制
        expect(SecurityUtils.isValidPagination(page: 10001, limit: 20),
            isFalse); // 页码过大
        expect(SecurityUtils.isValidPagination(page: 1, limit: 101),
            isFalse); // 限制过大
      });
    });

    group('安全检测测试', () {
      test('应该检测SQL注入攻击', () {
        final sqlInjectionInputs = [
          "'; DROP TABLE users; --",
          "1' OR '1'='1",
          "admin'--",
          "1' UNION SELECT * FROM users--",
          "'; DELETE FROM funds; --",
          "1'; INSERT INTO users VALUES('hacker', 'password'); --",
        ];

        for (final input in sqlInjectionInputs) {
          expect(SecurityUtils.containsSqlInjection(input), isTrue,
              reason: 'Should detect SQL injection in: $input');
        }
      });

      test('应该允许正常的SQL查询', () {
        final normalInputs = [
          'fund_name like "华夏%"',
          'price > 100 and price < 200',
          'status = "active"',
          'created_at >= "2024-01-01"',
        ];

        for (final input in normalInputs) {
          expect(SecurityUtils.containsSqlInjection(input), isFalse,
              reason: 'Should not false positive for normal input: $input');
        }
      });

      test('应该检测XSS攻击', () {
        final xssInputs = [
          '<script>alert("xss")</script>',
          '<img src="x" onerror="alert(1)">',
          'javascript:alert(1)',
          '<iframe src="javascript:alert(1)"></iframe>',
          '"><script>alert(document.cookie)</script>',
          'onload="alert(1)"',
        ];

        for (final input in xssInputs) {
          expect(SecurityUtils.containsXss(input), isTrue,
              reason: 'Should detect XSS in: $input');
        }
      });

      test('应该允许正常的HTML内容', () {
        final normalHtmlInputs = [
          '这是一个普通的文本',
          '基金名称：华夏成长',
          '收益率：15.6%',
          '价格范围：100-200元',
          'Email: user@example.com',
        ];

        for (final input in normalHtmlInputs) {
          expect(SecurityUtils.containsXss(input), isFalse,
              reason: 'Should not false positive for normal text: $input');
        }
      });
    });

    group('综合安全验证测试', () {
      test('应该验证安全的输入', () {
        final result = SecurityUtils.validateInput(
          input: '000001',
          type: 'fund_code',
          maxLength: 10,
        );

        expect(result.isValid, isTrue);
        expect(result.errorMessage, isNull);
      });

      test('应该拒绝包含SQL注入的输入', () {
        final result = SecurityUtils.validateInput(
          input: "'; DROP TABLE funds; --",
          maxLength: 100,
        );

        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('SQL注入'));
      });

      test('应该拒绝包含XSS的输入', () {
        final result = SecurityUtils.validateInput(
          input: '<script>alert("xss")</script>',
          maxLength: 100,
        );

        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('XSS'));
      });

      test('应该拒绝过长的输入', () {
        final result = SecurityUtils.validateInput(
          input: 'a' * 101,
          maxLength: 100,
        );

        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('长度超过限制'));
      });

      test('应该拒绝空值输入（当不允许空值时）', () {
        final result = SecurityUtils.validateInput(
          input: '',
          maxLength: 100,
          allowNull: false,
        );

        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('不能为空'));
      });

      test('应该允许空值输入（当允许空值时）', () {
        final result = SecurityUtils.validateInput(
          input: '',
          maxLength: 100,
          allowNull: true,
        );

        expect(result.isValid, isTrue);
      });
    });

    group('敏感信息过滤测试', () {
      test('应该过滤敏感数据字段', () {
        final sensitiveData = {
          'username': 'testuser',
          'password': 'secretpassword',
          'token': 'secret_token_123',
          'api_key': 'secret_api_key_456',
          'normal_field': 'normal_value',
          'user_session': 'session_data',
        };

        final filteredData = SecurityUtils.filterSensitiveData(sensitiveData);

        expect(filteredData['username'], equals('testuser'));
        expect(filteredData['normal_field'], equals('normal_value'));
        expect(filteredData['password'], equals('***FILTERED***'));
        expect(filteredData['token'], equals('***FILTERED***'));
        expect(filteredData['api_key'], equals('***FILTERED***'));
        expect(filteredData['user_session'], equals('***FILTERED***'));
      });

      test('应该过滤日志中的敏感信息', () {
        final sensitiveLog =
            'User: test@example.com, Password: secret123, Token: abc123def456';
        final filteredLog = SecurityUtils.filterSensitiveLog(sensitiveLog);

        expect(filteredLog, contains('***EMAIL***'));
        expect(filteredLog, contains('***KEY***'));
        expect(filteredLog, isNot(contains('secret123')));
        expect(filteredLog, isNot(contains('abc123def456')));
      });

      test('应该过滤手机号和身份证号', () {
        final sensitiveLog = '用户：张三，手机：13812345678，身份证：110101199001011234';
        final filteredLog = SecurityUtils.filterSensitiveLog(sensitiveLog);

        expect(filteredLog, contains('***PHONE***'));
        expect(filteredLog, contains('***ID***'));
        expect(filteredLog, isNot(contains('13812345678')));
        expect(filteredLog, isNot(contains('110101199001011234')));
      });
    });

    group('安全工具函数测试', () {
      test('应该生成安全的随机字符串', () {
        final randomString1 = SecurityUtils.generateSecureRandomString(32);
        final randomString2 = SecurityUtils.generateSecureRandomString(32);

        expect(randomString1.length, equals(32));
        expect(randomString2.length, equals(32));
        expect(randomString1, isNot(equals(randomString2)));

        // 验证字符集
        final validChars = RegExp(r'^[a-zA-Z0-9]+$');
        expect(validString1.hasMatch(randomString1), isTrue);
        expect(validString1.hasMatch(randomString2), isTrue);
      });

      test('应该验证HTTP方法', () {
        expect(SecurityUtils.isValidHttpMethod('GET'), isTrue);
        expect(SecurityUtils.isValidHttpMethod('POST'), isTrue);
        expect(SecurityUtils.isValidHttpMethod('PUT'), isTrue);
        expect(SecurityUtils.isValidHttpMethod('DELETE'), isTrue);
        expect(SecurityUtils.isValidHttpMethod('PATCH'), isTrue);
        expect(SecurityUtils.isValidHttpMethod('HEAD'), isTrue);
        expect(SecurityUtils.isValidHttpMethod('OPTIONS'), isTrue);

        expect(SecurityUtils.isValidHttpMethod('INVALID'), isFalse);
        expect(SecurityUtils.isValidHttpMethod(''), isFalse);
        expect(SecurityUtils.isValidHttpMethod(null), isFalse);
      });

      test('应该验证URL路径', () {
        expect(SecurityUtils.isValidPath('/api/funds'), isTrue);
        expect(SecurityUtils.isValidPath('/user/123/profile'), isTrue);
        expect(SecurityUtils.isValidPath('/'), isTrue);

        expect(SecurityUtils.isValidPath('api/funds'), isFalse); // 不以/开头
        expect(SecurityUtils.isValidPath('/../etc/passwd'), isFalse); // 路径遍历
        expect(SecurityUtils.isValidPath('/api/<script>alert(1)</script>'),
            isFalse); // XSS
        expect(SecurityUtils.isValidPath('/api/"test"'), isFalse); // 包含引号
        expect(SecurityUtils.isValidPath('/api\x00test'), isFalse); // 空字节
        expect(SecurityUtils.isValidPath(''), isFalse);
        expect(SecurityUtils.isValidPath(null), isFalse);
      });

      test('应该生成和验证CSRF令牌', () {
        final token = SecurityUtils.generateCsrfToken();

        expect(token.length, greaterThanOrEqualTo(32));
        expect(SecurityUtils.isValidCsrfToken(token), isTrue);

        // 验证无效令牌
        expect(SecurityUtils.isValidCsrfToken(''), isFalse);
        expect(SecurityUtils.isValidCsrfToken('short'), isFalse);
        expect(SecurityUtils.isValidCsrfToken('invalid@token'), isFalse);
        expect(SecurityUtils.isValidCsrfToken(null), isFalse);
      });
    });

    group('加密和解密测试', () {
      test('应该能加密和解密敏感数据', () {
        final originalData = 'sensitive_information_123';
        final encryptedData = SecurityUtils.encryptSensitiveData(originalData);
        final decryptedData = SecurityUtils.decryptSensitiveData(encryptedData);

        expect(encryptedData, isNot(equals(originalData)));
        expect(encryptedData, isNotEmpty);
        expect(decryptedData, equals(originalData));
      });

      test('应该处理加密错误', () {
        // 测试空数据
        final encryptedEmpty = SecurityUtils.encryptSensitiveData('');
        expect(encryptedEmpty, isEmpty);

        final decryptedEmpty = SecurityUtils.decryptSensitiveData('');
        expect(decryptedEmpty, isEmpty);

        // 测试无效数据
        final decryptedInvalid =
            SecurityUtils.decryptSensitiveData('invalid_encrypted_data');
        expect(decryptedInvalid, isEmpty);
      });
    });

    group('安全响应头测试', () {
      test('应该生成完整的安全响应头', () {
        final securityHeaders = SecurityUtils.getSecurityHeaders();

        expect(securityHeaders['X-Content-Type-Options'], equals('nosniff'));
        expect(securityHeaders['X-Frame-Options'], equals('DENY'));
        expect(securityHeaders['X-XSS-Protection'], equals('1; mode=block'));
        expect(securityHeaders['Strict-Transport-Security'],
            contains('max-age=31536000'));
        expect(securityHeaders['Content-Security-Policy'],
            contains('default-src'));
        expect(securityHeaders['Referrer-Policy'],
            equals('strict-origin-when-cross-origin'));
      });
    });

    group('性能测试', () {
      test('签名生成性能测试', () {
        final method = 'POST';
        final path = '/api/test';
        final params = {'param1': 'value1', 'param2': 'value2'};
        final timestamp = DateTime.now().toIso8601String();
        final requestId = SecurityUtils.generateRequestId();

        final stopwatch = Stopwatch()..start();

        // 生成1000个签名
        for (int i = 0; i < 1000; i++) {
          SecurityUtils.generateSignature(
            method: method,
            path: path,
            params: params,
            timestamp: timestamp,
            requestId: requestId,
          );
        }

        stopwatch.stop();

        expect(
            stopwatch.elapsedMilliseconds, lessThan(1000)); // 1000个签名应该在1秒内完成
      });

      test('输入验证性能测试', () {
        final testInputs = List.generate(1000, (index) => 'test_input_$index');
        final stopwatch = Stopwatch()..start();

        for (final input in testInputs) {
          SecurityUtils.validateInput(input: input, maxLength: 50);
        }

        stopwatch.stop();

        expect(
            stopwatch.elapsedMilliseconds, lessThan(500)); // 1000次验证应该在0.5秒内完成
      });

      test('XSS/SQL注入检测性能测试', () {
        final testInputs = [
          'normal text',
          '<script>alert("xss")</script>',
          "'; DROP TABLE users; --",
          'another normal input',
        ];
        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < 1000; i++) {
          final input = testInputs[i % testInputs.length];
          SecurityUtils.containsSqlInjection(input);
          SecurityUtils.containsXss(input);
        }

        stopwatch.stop();

        expect(
            stopwatch.elapsedMilliseconds, lessThan(200)); // 2000次检测应该在0.2秒内完成
      });
    });

    group('边界条件测试', () {
      test('应该处理极端长度的输入', () {
        final veryLongInput = 'a' * 10000;

        final result = SecurityUtils.validateInput(
          input: veryLongInput,
          maxLength: 100,
        );

        expect(result.isValid, isFalse);
        expect(result.errorMessage, contains('长度超过限制'));
      });

      test('应该处理特殊字符组合', () {
        final specialInputs = [
          '\x00\x01\x02', // 空字节和控制字符
          '\u0000\u0001\u0002', // Unicode控制字符
          '!@#\$%^&*()_+-=[]{}|;:,.<>?', // 特殊符号
          '🚀🔒🔐', // Emoji
        ];

        for (final input in specialInputs) {
          final result =
              SecurityUtils.validateInput(input: input, maxLength: 100);

          // 应该能处理而不崩溃
          expect(result, isA<SecurityValidationResult>());
        }
      });

      test('应该处理并发访问', () async {
        final futures = List.generate(100, (index) async {
          final method = 'GET';
          final path = '/api/test';
          final params = {'id': index.toString()};
          final timestamp = DateTime.now().toIso8601String();
          final requestId = SecurityUtils.generateRequestId();

          final signature = SecurityUtils.generateSignature(
            method: method,
            path: path,
            params: params,
            timestamp: timestamp,
            requestId: requestId,
          );

          return SecurityUtils.verifySignature(
            method: method,
            path: path,
            params: params,
            timestamp: timestamp,
            requestId: requestId,
            receivedSignature: signature,
          );
        });

        final results = await Future.wait(futures);

        expect(results.length, equals(100));
        expect(results.every((isValid) => isValid), isTrue);
      });
    });
  });
}
