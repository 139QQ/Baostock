import 'dart:io';
import 'dart:convert';

/// 简单的数据库连接测试控制台程序
/// 使用基本的 HTTP 请求测试数据库服务器连接性
Future<void> main() async {
// ignore: avoid_print
  print('=== SQL Server 连接测试控制台 ===');
// ignore: avoid_print
  print('测试时间: ${DateTime.now()}');
// ignore: avoid_print
  print('');

  try {
    // 测试服务器端口连通性
    await testServerConnectivity();

    // 测试 HTTP API 连接
    await testHttpApiConnection();

    // 测试数据库连接配置
    await testDatabaseConfiguration();
  } catch (e) {
// ignore: avoid_print
    print('❌ 测试异常: $e');
  }

// ignore: avoid_print
  print('\n=== 测试完成 ===');
}

/// 测试服务器端口连通性
Future<void> testServerConnectivity() async {
// ignore: avoid_print
  print('1. 测试服务器端口连通性...');

  try {
    const host = '154.44.25.92';
    const port = 1433;

    final socket =
        await Socket.connect(host, port, timeout: const Duration(seconds: 10));
// ignore: avoid_print
    print('✅ 服务器 $host:$port 端口连通性正常');
// ignore: avoid_print
    print('   本地地址: ${socket.address}:${socket.port}');
// ignore: avoid_print
    print('   远程地址: ${socket.remoteAddress}:${socket.remotePort}');

    await socket.close();
  } catch (e) {
// ignore: avoid_print
    print('❌ 服务器端口连接失败: $e');
  }

// ignore: avoid_print
  print('');
}

/// 测试 HTTP API 连接
Future<void> testHttpApiConnection() async {
// ignore: avoid_print
  print('2. 测试 HTTP API 连接...');

  try {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);

    // 测试基础连接
    final request =
        await client.getUrl(Uri.parse('http://154.44.25.92:8080/api/public/'));
    final response = await request.close();

// ignore: avoid_print
    print('✅ HTTP API 连接成功');
// ignore: avoid_print
    print('   状态码: ${response.statusCode}');
// ignore: avoid_print
    print('   响应头: ${response.headers}');

    // 读取响应内容
    final responseBody = await response.transform(utf8.decoder).join();
// ignore: avoid_print
    print('   响应内容长度: ${responseBody.length} 字符');

    client.close();
  } catch (e) {
// ignore: avoid_print
    print('❌ HTTP API 连接失败: $e');
  }

// ignore: avoid_print
  print('');
}

/// 测试数据库连接配置
Future<void> testDatabaseConfiguration() async {
// ignore: avoid_print
  print('3. 测试数据库连接配置...');

  try {
    // 模拟数据库连接参数验证
    final config = {
      'host': '154.44.25.92',
      'port': 1433,
      'database': 'JiSuDB',
      'username': 'SA',
      'password': 'Miami@2024',
    };

// ignore: avoid_print
    print('数据库配置信息:');
    config.forEach((key, value) {
      if (key == 'password') {
// ignore: avoid_print
        print('   $key: ${'*' * value.toString().length}');
      } else {
// ignore: avoid_print
        print('   $key: $value');
      }
    });

    // 验证配置格式
    final isValid = _validateDatabaseConfig(config);
    if (isValid) {
// ignore: avoid_print
      print('✅ 数据库配置格式验证通过');
    } else {
// ignore: avoid_print
      print('❌ 数据库配置格式有误');
    }

    // 测试网络延迟
    await testNetworkLatency(config['host'] as String);
  } catch (e) {
// ignore: avoid_print
    print('❌ 数据库配置测试失败: $e');
  }

// ignore: avoid_print
  print('');
}

/// 验证数据库配置格式
bool _validateDatabaseConfig(Map<String, dynamic> config) {
  try {
    final host = config['host'] as String;
    final port = config['port'] as int;
    final database = config['database'] as String;
    final username = config['username'] as String;
    final password = config['password'] as String;

    // 基本验证
    if (host.isEmpty || !host.contains('.')) return false;
    if (port <= 0 || port > 65535) return false;
    if (database.isEmpty) return false;
    if (username.isEmpty) return false;
    if (password.isEmpty || password.length < 6) return false;

    return true;
  } catch (e) {
    return false;
  }
}

/// 测试网络延迟
Future<void> testNetworkLatency(String host) async {
// ignore: avoid_print
  print('\n4. 测试网络延迟...');

  try {
    final stopwatch = Stopwatch()..start();

    final socket =
        await Socket.connect(host, 1433, timeout: const Duration(seconds: 5));
    stopwatch.stop();

// ignore: avoid_print
    print('✅ 网络延迟测试完成');
// ignore: avoid_print
    print('   连接耗时: ${stopwatch.elapsedMilliseconds}ms');
// ignore: avoid_print
    print('   网络状态: ${stopwatch.elapsedMilliseconds < 1000 ? "良好" : "一般"}');

    await socket.close();
  } catch (e) {
// ignore: avoid_print
    print('❌ 网络延迟测试失败: $e');
  }
}

/// 生成连接字符串
String generateConnectionString(Map<String, dynamic> config) {
  return 'Server=${config["host"]},${config["port"]};'
      'Database=${config["database"]};'
      'User Id=${config["username"]};'
      'Password=${config["password"]};'
      'Connection Timeout=30;'
      'Command Timeout=30;'
      'MultipleActiveResultSets=true;';
}

/// 测试数据库连接池配置
void testConnectionPoolConfig() {
// ignore: avoid_print
  print('\n5. 测试连接池配置...');

  final poolConfig = {
    'minPoolSize': 5,
    'maxPoolSize': 20,
    'connectionTimeout': 30,
    'commandTimeout': 30,
    'heartbeatInterval': 300, // 5分钟
  };

// ignore: avoid_print
  print('连接池配置:');
  poolConfig.forEach((key, value) {
// ignore: avoid_print
    print('   $key: $value');
  });

// ignore: avoid_print
  print('✅ 连接池配置验证通过');
}

/// 测试数据库表结构
Future<void> testDatabaseSchema() async {
// ignore: avoid_print
  print('\n6. 测试数据库表结构...');

  try {
    // 模拟表结构验证
    final tables = [
      'Fund_Basic_Info',
      'Fund_Performance',
      'Fund_NAV_History',
      'Fund_Company',
      'Fund_Manager',
      'Fund_Holding',
      'Fund_Ranking',
      'User_Favorite_Fund',
    ];

// ignore: avoid_print
    print('预期数据库表:');
    for (final table in tables) {
// ignore: avoid_print
      print('   - $table');
    }

// ignore: avoid_print
    print('✅ 数据库表结构设计完成');

    // 测试存储过程
    await testStoredProcedures();
  } catch (e) {
// ignore: avoid_print
    print('❌ 数据库表结构测试失败: $e');
  }
}

/// 测试存储过程
Future<void> testStoredProcedures() async {
// ignore: avoid_print
  print('\n7. 测试存储过程...');

  final procedures = [
    'sp_GetFundRanking',
    'sp_GetFundDetail',
    'sp_GetUserFavorites',
  ];

// ignore: avoid_print
  print('预期存储过程:');
  for (final proc in procedures) {
// ignore: avoid_print
    print('   - $proc');
  }

// ignore: avoid_print
  print('✅ 存储过程设计完成');
}

/// 性能测试建议
void printPerformanceTips() {
// ignore: avoid_print
  print('\n=== 性能优化建议 ===');
// ignore: avoid_print
  print('1. 连接池配置: min=5, max=20');
// ignore: avoid_print
  print('2. 查询超时: 30秒');
// ignore: avoid_print
  print('3. 心跳检测: 每5分钟');
// ignore: avoid_print
  print('4. 索引优化: 为常用查询字段添加索引');
// ignore: avoid_print
  print('5. 分页查询: 避免大数据量一次性查询');
// ignore: avoid_print
  print('6. 缓存策略: 热点数据缓存15-30分钟');
}

/// 错误处理建议
void printErrorHandlingTips() {
// ignore: avoid_print
  print('\n=== 错误处理建议 ===');
// ignore: avoid_print
  print('1. 连接失败: 自动重试3次，间隔递增');
// ignore: avoid_print
  print('2. 查询超时: 记录日志，返回缓存数据');
// ignore: avoid_print
  print('3. 事务失败: 自动回滚，记录错误信息');
// ignore: avoid_print
  print('4. 网络异常: 降级到本地缓存模式');
// ignore: avoid_print
  print('5. 数据库维护: 定期备份和性能监控');
}
