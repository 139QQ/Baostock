// import 'dart:async';
// import 'dart:convert';
// import 'dart:developer' as developer;
// import 'package:sql_conn/sql_conn.dart';

// import 'sql_server_config.dart';

// /// SQL Server 数据库连接管理器
// ///
// /// 负责管理 SQL Server 数据库连接，提供连接池、错误处理、连接状态监控等功能
// class SqlServerManager {
//   static SqlServerManager? _instance;
//   static SqlServerManager get instance =>
//       _instance ??= SqlServerManager._internal();

//   SqlServerManager._internal();

//   bool _isConnected = false;
//   bool get isConnected => _isConnected;

//   SqlServerConfig? _currentConfig;
//   Timer? _heartbeatTimer;
//   final StreamController<bool> _connectionStatusController =
//       StreamController<bool>.broadcast();

//   /// 连接状态变更流
//   Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

//   /// 初始化数据库连接
//   Future<bool> initialize(SqlServerConfig config) async {
//     try {
//       if (!config.validate()) {
//         developer.log('SQL Server 配置验证失败', name: 'SqlServerManager');
//         return false;
//       }

//       _currentConfig = config;

//       // 测试连接
//       await SqlConn.connect(
//         ip: config.host,
//         port: config.port.toString(),
//         databaseName: config.database,
//         username: config.username,
//         password: config.password,
//       );

//       _isConnected = true;
//       _connectionStatusController.add(true);

//       // 启动心跳检测
//       _startHeartbeat();

//       developer.log(
//           'SQL Server 连接成功: ${config.host}:${config.port}/${config.database}',
//           name: 'SqlServerManager');
//       return true;
//     } catch (e) {
//       _isConnected = false;
//       _connectionStatusController.add(false);
//       developer.log('SQL Server 连接失败: $e', name: 'SqlServerManager', error: e);
//       return false;
//     }
//   }

//   /// 执行查询语句
//   Future<List<Map<String, dynamic>>> query(String sql,
//       [List<dynamic>? params]) async {
//     if (!_isConnected) {
//       throw Exception('数据库未连接');
//     }

//     try {
//       final result = await SqlConn.readData(sql);
//       return _parseQueryResult(result);
//     } catch (e) {
//       developer.log('查询执行失败: $e', name: 'SqlServerManager', error: e);
//       throw Exception('查询失败: $e');
//     }
//   }

//   /// 执行增删改语句
//   Future<int> execute(String sql, [List<dynamic>? params]) async {
//     if (!_isConnected) {
//       throw Exception('数据库未连接');
//     }

//     try {
//       final result = await SqlConn.writeData(sql);
//       return result['rowsAffected'] ?? 0;
//     } catch (e) {
//       developer.log('命令执行失败: $e', name: 'SqlServerManager', error: e);
//       throw Exception('执行失败: $e');
//     }
//   }

//   /// 执行存储过程
//   Future<List<Map<String, dynamic>>> executeProcedure(String procedureName,
//       [Map<String, dynamic>? parameters]) async {
//     if (!_isConnected) {
//       throw Exception('数据库未连接');
//     }

//     try {
//       final paramString =
//           parameters?.entries.map((e) => "@${e.key}='${e.value}'").join(',') ??
//               '';

//       final sql = "EXEC $procedureName $paramString";
//       final result = await SqlConn.readData(sql);
//       return _parseQueryResult(result);
//     } catch (e) {
//       developer.log('存储过程执行失败: $e', name: 'SqlServerManager', error: e);
//       throw Exception('存储过程执行失败: $e');
//     }
//   }

//   /// 开始事务
//   Future<void> beginTransaction() async {
//     if (!_isConnected) {
//       throw Exception('数据库未连接');
//     }

//     try {
//       await SqlConn.writeData('BEGIN TRANSACTION');
//       developer.log('事务开始', name: 'SqlServerManager');
//     } catch (e) {
//       developer.log('事务开始失败: $e', name: 'SqlServerManager', error: e);
//       throw Exception('事务开始失败: $e');
//     }
//   }

//   /// 提交事务
//   Future<void> commitTransaction() async {
//     if (!_isConnected) {
//       throw Exception('数据库未连接');
//     }

//     try {
//       await SqlConn.writeData('COMMIT TRANSACTION');
//       developer.log('事务提交', name: 'SqlServerManager');
//     } catch (e) {
//       developer.log('事务提交失败: $e', name: 'SqlServerManager', error: e);
//       throw Exception('事务提交失败: $e');
//     }
//   }

//   /// 回滚事务
//   Future<void> rollbackTransaction() async {
//     if (!_isConnected) {
//       throw Exception('数据库未连接');
//     }

//     try {
//       await SqlConn.writeData('ROLLBACK TRANSACTION');
//       developer.log('事务回滚', name: 'SqlServerManager');
//     } catch (e) {
//       developer.log('事务回滚失败: $e', name: 'SqlServerManager', error: e);
//       throw Exception('事务回滚失败: $e');
//     }
//   }

//   /// 关闭连接
//   Future<void> disconnect() async {
//     try {
//       _heartbeatTimer?.cancel();
//       await SqlConn.disconnect();
//       _isConnected = false;
//       _connectionStatusController.add(false);
//       developer.log('SQL Server 连接已关闭', name: 'SqlServerManager');
//     } catch (e) {
//       developer.log('断开连接失败: $e', name: 'SqlServerManager', error: e);
//     }
//   }

//   /// 获取数据库信息
//   Future<Map<String, dynamic>> getDatabaseInfo() async {
//     try {
//       final result = await query(
//           'SELECT @@VERSION as version, DB_NAME() as database_name');
//       return result.isNotEmpty ? result.first : {};
//     } catch (e) {
//       developer.log('获取数据库信息失败: $e', name: 'SqlServerManager', error: e);
//       return {};
//     }
//   }

//   /// 获取连接统计信息
//   Map<String, dynamic> getConnectionStats() {
//     return {
//       'isConnected': _isConnected,
//       'config': _currentConfig?.toConnectionString(),
//       'timestamp': DateTime.now().toIso8601String(),
//     };
//   }

//   /// 解析查询结果
//   List<Map<String, dynamic>> _parseQueryResult(dynamic result) {
//     if (result == null) return [];

//     try {
//       if (result is String) {
//         final decoded = jsonDecode(result);
//         if (decoded is List) {
//           return decoded.cast<Map<String, dynamic>>();
//         } else if (decoded is Map) {
//           return [decoded.cast<String, dynamic>()];
//         }
//       } else if (result is List) {
//         return result.cast<Map<String, dynamic>>();
//       } else if (result is Map) {
//         return [result.cast<String, dynamic>()];
//       }
//     } catch (e) {
//       developer.log('解析查询结果失败: $e', name: 'SqlServerManager', error: e);
//     }

//     return [];
//   }

//   /// 启动心跳检测
//   void _startHeartbeat() {
//     _heartbeatTimer?.cancel();
//     _heartbeatTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
//       if (_isConnected) {
//         try {
//           await query('SELECT 1');
//           developer.log('心跳检测成功', name: 'SqlServerManager');
//         } catch (e) {
//           developer.log('心跳检测失败: $e', name: 'SqlServerManager', error: e);
//           _isConnected = false;
//           _connectionStatusController.add(false);
//           timer.cancel();
//         }
//       }
//     });
//   }

//   /// 释放资源
//   void dispose() {
//     _heartbeatTimer?.cancel();
//     _connectionStatusController.close();
//     disconnect();
//     _instance = null;
//   }
// }
