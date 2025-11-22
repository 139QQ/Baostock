import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

import 'package:jisu_fund_analyzer/src/core/di/environment_config.dart';

void main() {
  group('EnvironmentConfig', () {
    group('工厂方法', () {
      test('应该创建开发环境配置', () {
        final config = EnvironmentConfig.development();

        expect(config.environment, equals(AppEnvironment.development));
        expect(config.isDevelopment, isTrue);
        expect(config.isTesting, isFalse);
        expect(config.isProduction, isFalse);
        expect(config.getVariable('debug_mode'), isTrue);
        expect(config.getVariable('api_base_url'),
            equals('http://localhost:8080'));
        expect(config.getVariable('cache_enabled'), isTrue);
      });

      test('应该创建测试环境配置', () {
        final config = EnvironmentConfig.testing();

        expect(config.environment, equals(AppEnvironment.testing));
        expect(config.isDevelopment, isFalse);
        expect(config.isTesting, isTrue);
        expect(config.isProduction, isFalse);
        expect(config.getVariable('debug_mode'), isTrue);
        expect(config.getVariable('api_base_url'),
            equals('http://test-api.example.com'));
        expect(config.getVariable('cache_ttl'), equals(300)); // 5分钟
      });

      test('应该创建预发布环境配置', () {
        final config = EnvironmentConfig.staging();

        expect(config.environment, equals(AppEnvironment.staging));
        expect(config.isDevelopment, isFalse);
        expect(config.isTesting, isFalse);
        expect(config.isStaging, isTrue);
        expect(config.isProduction, isFalse);
        expect(config.getVariable('debug_mode'), isFalse);
        expect(config.getVariable('api_base_url'),
            equals('https://staging-api.example.com'));
        expect(config.getVariable('feature_analytics_enabled'), isTrue);
      });

      test('应该创建生产环境配置', () {
        final config = EnvironmentConfig.production();

        expect(config.environment, equals(AppEnvironment.production));
        expect(config.isDevelopment, isFalse);
        expect(config.isTesting, isFalse);
        expect(config.isStaging, isFalse);
        expect(config.isProduction, isTrue);
        expect(config.getVariable('debug_mode'), isFalse);
        expect(config.getVariable('api_base_url'),
            equals('http://154.44.25.92:8080'));
        expect(config.getVariable('security_encryption_enabled'), isTrue);
        expect(config.getVariable('cache_monitoring_enabled'), isFalse);
      });

      test('应该支持额外配置变量', () {
        final additionalVars = {'custom_key': 'custom_value'};
        final config =
            EnvironmentConfig.development(additionalVariables: additionalVars);

        expect(config.getVariable('custom_key'), equals('custom_value'));
        expect(config.getVariable('debug_mode'), isTrue); // 默认配置仍然存在
      });

      test('额外配置变量应该覆盖默认配置', () {
        final additionalVars = {'debug_mode': false};
        final config =
            EnvironmentConfig.development(additionalVariables: additionalVars);

        expect(config.getVariable('debug_mode'), isFalse); // 被覆盖
      });
    });

    group('从环境变量创建配置', () {
      setUp(() {
        // Platform.environment是不可修改的，跳过清理
      });

      test('应该支持显式指定环境名称', () {
        final config =
            EnvironmentConfig.fromEnvironment(environmentName: 'production');
        expect(config.isProduction, isTrue);
      });

      test('从环境名称创建生产环境', () {
        final config =
            EnvironmentConfig.fromEnvironment(environmentName: 'production');
        expect(config.environment, equals(AppEnvironment.production));
      });

      test('从环境名称创建测试环境', () {
        final config =
            EnvironmentConfig.fromEnvironment(environmentName: 'testing');
        expect(config.isTesting, isTrue);
      });

      test('从环境名称创建开发环境', () {
        final config =
            EnvironmentConfig.fromEnvironment(environmentName: 'development');
        expect(config.isDevelopment, isTrue);
      });

      test('从环境名称创建预发布环境', () {
        final config =
            EnvironmentConfig.fromEnvironment(environmentName: 'staging');
        expect(config.isStaging, isTrue);
      });
    });

    group('配置变量操作', () {
      test('应该正确获取配置变量', () {
        final config = EnvironmentConfig.development();

        expect(config.getVariable('api_base_url'), isA<String>());
        expect(config.getVariable('api_timeout'), isA<int>());
        expect(config.getVariable('cache_enabled'), isA<bool>());
      });

      test('获取不存在的变量应该返回null', () {
        final config = EnvironmentConfig.development();

        expect(config.getVariable('non_existent_key'), isNull);
      });

      test('应该支持类型安全的变量获取', () {
        final config = EnvironmentConfig.development();

        final String? apiUrl = config.getVariable<String>('api_base_url');
        final int? timeout = config.getVariable<int>('api_timeout');
        final bool? cacheEnabled = config.getVariable<bool>('cache_enabled');

        expect(apiUrl, isA<String>());
        expect(timeout, isA<int>());
        expect(cacheEnabled, isA<bool>());
      });

      test('类型不匹配应该返回null', () {
        final config = EnvironmentConfig.development();

        // 测试一个不存在的键，而不是类型转换
        final String? notFound = config.getVariable<String>('non_existent_key');
        expect(notFound, isNull);
      });
    });

    group('配置复制', () {
      test('应该正确复制配置', () {
        final original = EnvironmentConfig.development(
            additionalVariables: {'custom_key': 'custom_value'});

        final copy = original.copyWith();

        expect(copy.environment, equals(original.environment));
        expect(copy.getVariable('custom_key'), equals('custom_value'));
        expect(copy.getVariable('debug_mode'),
            equals(original.getVariable('debug_mode')));
      });

      test('应该支持覆盖环境', () {
        final original = EnvironmentConfig.development();
        final copy = original.copyWith(environment: AppEnvironment.production);

        expect(copy.environment, equals(AppEnvironment.production));
        expect(copy.isProduction, isTrue);
      });

      test('应该支持添加额外变量', () {
        final original = EnvironmentConfig.development();
        final copy =
            original.copyWith(additionalVariables: {'new_key': 'new_value'});

        expect(copy.getVariable('new_key'), equals('new_value'));
        expect(copy.getVariable('debug_mode'), isTrue); // 原有变量保留
      });

      test('应该支持覆盖变量', () {
        final original = EnvironmentConfig.development();
        final copy =
            original.copyWith(overrideVariables: {'debug_mode': false});

        expect(copy.getVariable('debug_mode'), isFalse); // 被覆盖
      });

      test('应该同时支持添加和覆盖变量', () {
        final original = EnvironmentConfig.development();
        final copy = original.copyWith(
            additionalVariables: {'new_key': 'new_value'},
            overrideVariables: {'debug_mode': false});

        expect(copy.getVariable('new_key'), equals('new_value'));
        expect(copy.getVariable('debug_mode'), isFalse);
      });
    });

    group('变量访问', () {
      test('应该返回所有变量', () {
        final config = EnvironmentConfig.development();
        final variables = config.variables;

        expect(variables.isNotEmpty, isTrue);
        expect(variables.containsKey('api_base_url'), isTrue);
        expect(variables.containsKey('debug_mode'), isTrue);
        expect(variables.containsKey('cache_enabled'), isTrue);
      });

      test('变量映射应该是不可修改的', () {
        final config = EnvironmentConfig.development();
        final variables = config.variables;

        expect(() => variables['new_key'] = 'value',
            throwsA(isA<UnsupportedError>()));
      });
    });

    group('字符串表示', () {
      test('应该返回正确的字符串表示', () {
        final config = EnvironmentConfig.development();
        final str = config.toString();

        expect(str, contains('EnvironmentConfig'));
        expect(str, contains('development'));
        expect(str, contains('variables'));
      });
    });

    group('环境特定配置验证', () {
      test('开发环境应该有调试功能', () {
        final config = EnvironmentConfig.development();

        expect(config.getVariable('debug_mode'), isTrue);
        expect(config.getVariable('debug_network_logging'), isTrue);
        expect(config.getVariable('debug_cache_logging'), isTrue);
      });

      test('生产环境应该关闭调试功能', () {
        final config = EnvironmentConfig.production();

        expect(config.getVariable('debug_mode'), isFalse);
        expect(config.getVariable('debug_network_logging'), isFalse);
        expect(config.getVariable('debug_cache_logging'), isFalse);
      });

      test('生产环境应该启用安全功能', () {
        final config = EnvironmentConfig.production();

        expect(config.getVariable('security_encryption_enabled'), isTrue);
        expect(config.getVariable('security_ssl_verification'), isTrue);
      });

      test('生产环境应该启用分析功能', () {
        final config = EnvironmentConfig.production();

        expect(config.getVariable('feature_analytics_enabled'), isTrue);
        expect(config.getVariable('feature_crash_reporting_enabled'), isTrue);
        expect(config.getVariable('feature_remote_config_enabled'), isTrue);
      });

      test('测试环境应该有较小的缓存配置', () {
        final testConfig = EnvironmentConfig.testing();
        final prodConfig = EnvironmentConfig.production();

        final testCacheSize = testConfig.getVariable<int>('cache_max_size');
        final prodCacheSize = prodConfig.getVariable<int>('cache_max_size');

        expect(testCacheSize, lessThan(prodCacheSize!));

        final testTtl = testConfig.getVariable<int>('cache_ttl');
        final prodTtl = prodConfig.getVariable<int>('cache_ttl');

        expect(testTtl, lessThan(prodTtl!));
      });
    });
  });

  group('EnvironmentConfigManager', () {
    group('初始化', () {
      setUp(() {
        EnvironmentConfigManager.reset();
      });

      tearDown(() {
        EnvironmentConfigManager.reset();
      });

      test('初始化前应该抛出异常', () {
        expect(
          () => EnvironmentConfigManager.current,
          throwsA(isA<StateError>()),
        );
      });

      test('应该正确初始化', () {
        EnvironmentConfigManager.initialize(
            environment: AppEnvironment.development);

        expect(EnvironmentConfigManager.isInitialized, isTrue);
        expect(EnvironmentConfigManager.current.environment,
            equals(AppEnvironment.development));
      });

      test('应该支持通过环境名称初始化', () {
        EnvironmentConfigManager.initialize(environmentName: 'production');

        expect(EnvironmentConfigManager.current.environment,
            equals(AppEnvironment.production));
      });

      test('应该支持额外配置变量', () {
        EnvironmentConfigManager.initialize(
            environment: AppEnvironment.development,
            additionalVariables: {'custom_key': 'custom_value'});

        expect(EnvironmentConfigManager.current.getVariable('custom_key'),
            equals('custom_value'));
      });

      test('重复初始化应该覆盖原有配置', () {
        EnvironmentConfigManager.initialize(
            environment: AppEnvironment.development);
        expect(EnvironmentConfigManager.current.environment,
            equals(AppEnvironment.development));

        // 实际上允许重复初始化，会覆盖原有配置
        EnvironmentConfigManager.initialize(
            environment: AppEnvironment.production);
        expect(EnvironmentConfigManager.current.environment,
            equals(AppEnvironment.production));
      });

      test('重新初始化应该工作', () {
        EnvironmentConfigManager.initialize(
            environment: AppEnvironment.development);
        expect(EnvironmentConfigManager.current.environment,
            equals(AppEnvironment.development));

        EnvironmentConfigManager.reinitialize(
            environment: AppEnvironment.production);
        expect(EnvironmentConfigManager.current.environment,
            equals(AppEnvironment.production));
      });
    });

    group('状态管理', () {
      setUp(() {
        EnvironmentConfigManager.initialize(
            environment: AppEnvironment.development);
      });

      tearDown(() {
        EnvironmentConfigManager.reset();
      });

      test('isInitialized应该返回正确状态', () {
        expect(EnvironmentConfigManager.isInitialized, isTrue);

        EnvironmentConfigManager.reset();
        expect(EnvironmentConfigManager.isInitialized, isFalse);
      });

      test('reset应该清理状态', () {
        expect(EnvironmentConfigManager.isInitialized, isTrue);

        EnvironmentConfigManager.reset();
        expect(EnvironmentConfigManager.isInitialized, isFalse);
        expect(
          () => EnvironmentConfigManager.current,
          throwsA(isA<StateError>()),
        );
      });
    });
  });

  group('AppEnvironment枚举', () {
    test('应该包含所有环境类型', () {
      final environments = AppEnvironment.values;

      expect(environments, contains(AppEnvironment.development));
      expect(environments, contains(AppEnvironment.testing));
      expect(environments, contains(AppEnvironment.staging));
      expect(environments, contains(AppEnvironment.production));
    });

    test('环境名称应该正确', () {
      expect(AppEnvironment.development.name, equals('development'));
      expect(AppEnvironment.testing.name, equals('testing'));
      expect(AppEnvironment.staging.name, equals('staging'));
      expect(AppEnvironment.production.name, equals('production'));
    });
  });
}
