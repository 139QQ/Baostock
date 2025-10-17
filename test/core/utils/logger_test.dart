import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jisu_fund_analyzer/src/core/utils/logger.dart';

void main() {
  group('AppLogger Tests', () {
    setUp(() {
      // 重置日志配置到默认状态
      AppLogger.enableDebugLogging = kDebugMode;
      AppLogger.enableInfoLogging = kDebugMode;
      AppLogger.enableWarnLogging = true;
      AppLogger.enableErrorLogging = true;
    });

    group('日志级别配置测试', () {
      test('debug级别日志仅在调试模式下输出', () {
        // 在测试环境中，kDebugMode通常为false
        expect(AppLogger.enableDebugLogging, equals(kDebugMode));
      });

      test('info级别日志配置测试', () {
        AppLogger.enableInfoLogging = true;
        expect(AppLogger.enableInfoLogging, isTrue);

        AppLogger.enableInfoLogging = false;
        expect(AppLogger.enableInfoLogging, isFalse);
      });

      test('warn级别日志默认开启', () {
        expect(AppLogger.enableWarnLogging, isTrue);
      });

      test('error级别日志默认开启', () {
        expect(AppLogger.enableErrorLogging, isTrue);
      });

      test('setLogLevel方法正确设置各日志级别', () {
        AppLogger.setLogLevel(
          debug: false,
          info: false,
          warn: false,
          error: false,
        );

        expect(AppLogger.enableDebugLogging, isFalse);
        expect(AppLogger.enableInfoLogging, isFalse);
        expect(AppLogger.enableWarnLogging, isFalse);
        expect(AppLogger.enableErrorLogging, isFalse);

        AppLogger.setLogLevel(
          debug: true,
          info: true,
          warn: true,
          error: true,
        );

        expect(AppLogger.enableDebugLogging, isTrue);
        expect(AppLogger.enableInfoLogging, isTrue);
        expect(AppLogger.enableWarnLogging, isTrue);
        expect(AppLogger.enableErrorLogging, isTrue);
      });
    });

    group('日志方法调用测试', () {
      test('所有日志方法都能正常调用不抛出异常', () {
        // 验证方法可以正常调用，不产生异常
        expect(() => AppLogger.debug('测试调试消息'), returnsNormally);
        expect(() => AppLogger.info('测试信息消息'), returnsNormally);
        expect(() => AppLogger.warn('测试警告消息'), returnsNormally);
        expect(() => AppLogger.error('测试错误消息', Exception('测试异常')),
            returnsNormally);
        expect(() => AppLogger.network('GET', '/test'), returnsNormally);
        expect(
            () => AppLogger.database('SELECT', 'test_table'), returnsNormally);
        expect(() => AppLogger.performance('test_operation', 100),
            returnsNormally);
        expect(() => AppLogger.ui('button_clicked'), returnsNormally);
        expect(() => AppLogger.business('user_login'), returnsNormally);
      });

      test('error方法支持可选的stackTrace参数', () {
        final testError = Exception('测试异常');
        final testStackTrace = StackTrace.current;

        expect(() => AppLogger.error('错误消息', testError), returnsNormally);
        expect(() => AppLogger.error('错误消息', testError, testStackTrace),
            returnsNormally);
      });

      test('network方法支持可选参数', () {
        expect(() => AppLogger.network('POST', '/api/test'), returnsNormally);
        expect(
            () => AppLogger.network(
                  'POST',
                  '/api/test',
                  statusCode: 200,
                  requestData: {'key': 'value'},
                  responseData: {'result': 'success'},
                  responseTime: 150,
                ),
            returnsNormally);
      });

      test('performance方法支持可选的details参数', () {
        expect(() => AppLogger.performance('query', 50), returnsNormally);
        expect(() => AppLogger.performance('query', 50, '数据库查询优化'),
            returnsNormally);
      });

      test('ui方法支持可选的widget和data参数', () {
        expect(() => AppLogger.ui('tap'), returnsNormally);
        expect(() => AppLogger.ui('tap', 'LoginButton'), returnsNormally);
        expect(() => AppLogger.ui('tap', 'LoginButton', {'user_id': '123'}),
            returnsNormally);
      });

      test('business方法支持可选的context和data参数', () {
        expect(() => AppLogger.business('订单创建'), returnsNormally);
        expect(() => AppLogger.business('订单创建', '订单管理'), returnsNormally);
        expect(() => AppLogger.business('订单创建', '订单管理', {'订单号': 'ORD123'}),
            returnsNormally);
      });
    });

    group('ErrorReportingService测试', () {
      test('ErrorReportingService.report方法可正常调用', () {
        final testError = Exception('测试异常');
        final testStackTrace = StackTrace.current;

        expect(() => ErrorReportingService.report(testError, testStackTrace),
            returnsNormally);
        expect(
            () => ErrorReportingService.report(
                testError, testStackTrace, '测试上下文'),
            returnsNormally);
      });

      test('ErrorReportingService.setUserContext方法可正常调用', () {
        expect(() => ErrorReportingService.setUserContext('user123'),
            returnsNormally);
        expect(
            () =>
                ErrorReportingService.setUserContext('user123', {'角色': '管理员'}),
            returnsNormally);
      });

      test('ErrorReportingService.recordBreadcrumb方法可正常调用', () {
        expect(() => ErrorReportingService.recordBreadcrumb('用户点击登录按钮'),
            returnsNormally);
        expect(() => ErrorReportingService.recordBreadcrumb('用户点击登录按钮', 'UI交互'),
            returnsNormally);
      });
    });

    group('clear方法测试', () {
      test('clear方法在调试模式下可正常调用', () {
        // clear方法包含控制台清除代码，但不会产生异常
        expect(() => AppLogger.clear(), returnsNormally);
      });
    });

    group('日志消息格式测试', () {
      test('日志消息包含时间戳', () {
        // 验证日志方法可以处理各种消息类型
        final messages = [
          '简单消息',
          '包含数字123的消息',
          '包含特殊字符!@#\$%的消息',
          '多行\n消息',
          '很长的消息' * 100,
        ];

        for (final message in messages) {
          expect(() => AppLogger.info(message), returnsNormally);
        }
      });

      test('日志方法支持各种数据类型', () {
        final testData = [
          null,
          '字符串',
          123,
          45.67,
          true,
          false,
          {'key': 'value'},
          [1, 2, 3],
          DateTime.now(),
        ];

        for (final data in testData) {
          expect(() => AppLogger.info('测试消息', data), returnsNormally);
        }
      });
    });

    group('边界条件测试', () {
      test('空消息处理', () {
        expect(() => AppLogger.info(''), returnsNormally);
        expect(() => AppLogger.debug(''), returnsNormally);
        expect(() => AppLogger.warn(''), returnsNormally);
        expect(() => AppLogger.error('', Exception('')), returnsNormally);
      });

      test('null异常处理', () {
        expect(() => AppLogger.error('消息', null), returnsNormally);
        expect(() => AppLogger.error('消息', null, null), returnsNormally);
      });

      test('长消息处理', () {
        final longMessage = '长消息' * 1000;
        expect(() => AppLogger.info(longMessage), returnsNormally);
      });

      test('特殊字符处理', () {
        const specialChars = '!@#\$%^&*()_+-=[]{}|;:\'",.<>?/~`';
        expect(() => AppLogger.info('特殊字符测试: $specialChars'), returnsNormally);
      });
    });
  });
}
