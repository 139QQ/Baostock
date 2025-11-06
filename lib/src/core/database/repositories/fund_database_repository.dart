// import 'dart:developer' as developer;
// import '../sql_server_manager.dart';
// import '../../../features/fund/presentation/fund_exploration/domain/models/fund.dart';
// import '../../../features/fund/presentation/fund_exploration/domain/repositories/cache_repository.dart';
// import '../../../features/fund/presentation/fund_exploration/domain/models/fund_filter.dart';

// /// SQL Server 基金数据库仓库实现
// ///
// /// 负责基金数据的持久化存储，提供CRUD操作和复杂查询功能
// class FundDatabaseRepository implements CacheRepository {
//   final SqlServerManager _dbManager;

//   FundDatabaseRepository({SqlServerManager? dbManager})
//       : _dbManager = dbManager ?? SqlServerManager.instance;

//   /// 初始化数据库表结构
//   Future<void> initializeDatabase() async {
//     try {
//       // 检查表是否存在，不存在则创建
//       await _createTablesIfNotExists();
//       developer.log('数据库表结构初始化完成', name: 'FundDatabaseRepository');
//     } catch (e) {
//       developer.log('数据库初始化失败: $e', name: 'FundDatabaseRepository', error: e);
//       throw Exception('数据库初始化失败: $e');
//     }
//   }

//   /// 创建表结构（如果不存在）
//   Future<void> _createTablesIfNotExists() async {
//     // 基金基础信息表
//     await _dbManager.execute('''
//       IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Fund_Basic_Info' AND xtype='U')
//       CREATE TABLE Fund_Basic_Info (
//         fund_code NVARCHAR(20) PRIMARY KEY,
//         fund_name NVARCHAR(200) NOT NULL,
//         fund_type NVARCHAR(50) NOT NULL,
//         company NVARCHAR(100) NOT NULL,
//         manager NVARCHAR(100),
//         risk_level NVARCHAR(10),
//         status NVARCHAR(20) DEFAULT 'active',
//         scale DECIMAL(18,2),
//         unit_nav DECIMAL(18,4),
//         accumulated_nav DECIMAL(18,4),
//         daily_return DECIMAL(8,4),
//         establish_date DATE,
//         management_fee DECIMAL(5,4),
//         custody_fee DECIMAL(5,4),
//         purchase_fee DECIMAL(5,4),
//         redemption_fee DECIMAL(5,4),
//         minimum_investment DECIMAL(18,2),
//         performance_benchmark NVARCHAR(500),
//         investment_target NVARCHAR(1000),
//         investment_scope NVARCHAR(1000),
//         currency NVARCHAR(10) DEFAULT 'CNY',
//         listing_date DATE,
//         delisting_date DATE,
//         created_at DATETIME2 DEFAULT GETDATE(),
//         updated_at DATETIME2 DEFAULT GETDATE()
//       )
//     ''');

//     // 基金业绩数据表
//     await _dbManager.execute('''
//       IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Fund_Performance' AND xtype='U')
//       CREATE TABLE Fund_Performance (
//         id INT IDENTITY(1,1) PRIMARY KEY,
//         fund_code NVARCHAR(20) NOT NULL,
//         return_1w DECIMAL(8,4),
//         return_1m DECIMAL(8,4),
//         return_3m DECIMAL(8,4),
//         return_6m DECIMAL(8,4),
//         return_1y DECIMAL(8,4),
//         return_3y DECIMAL(8,4),
//         return_ytd DECIMAL(8,4),
//         return_since_inception DECIMAL(8,4),
//         sharpe_ratio DECIMAL(8,4),
//         max_drawdown DECIMAL(8,4),
//         volatility DECIMAL(8,4),
//         performance_date DATE NOT NULL,
//         created_at DATETIME2 DEFAULT GETDATE(),
//         FOREIGN KEY (fund_code) REFERENCES Fund_Basic_Info(fund_code)
//       )
//     ''');

//     // 创建索引
//     await _dbManager.execute('''
//       IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name='IX_Fund_Performance_fund_code')
//       CREATE INDEX IX_Fund_Performance_fund_code ON Fund_Performance(fund_code)
//     ''');
//   }

//   @override
//   Future<List<Fund>?> getCachedFunds(String cacheKey) async {
//     try {
//       final limit = _extractLimitFromCacheKey(cacheKey);
//       final sql = '''
//         SELECT TOP ($limit)
//           f.fund_code, f.fund_name, f.fund_type, f.company, f.manager,
//           f.risk_level, f.status, f.scale, f.unit_nav, f.accumulated_nav,
//           f.daily_return, f.establish_date, f.management_fee, f.custody_fee,
//           f.purchase_fee, f.redemption_fee, f.minimum_investment,
//           f.performance_benchmark, f.investment_target, f.investment_scope,
//           f.currency, f.listing_date, f.delisting_date,
//           p.return_1w, p.return_1m, p.return_3m, p.return_6m,
//           p.return_1y, p.return_3y, p.return_ytd, p.return_since_inception
//         FROM Fund_Basic_Info f
//         LEFT JOIN Fund_Performance p ON f.fund_code = p.fund_code
//         WHERE f.status = 'active'
//         ORDER BY p.performance_date DESC
//       ''';

//       final results = await _dbManager.query(sql);

//       return results
//           .map((row) => Fund(
//                 code: row['fund_code'],
//                 name: row['fund_name'],
//                 type: row['fund_type'],
//                 company: row['company'],
//                 manager: row['manager'] ?? '',
//                 return1W: (row['return_1w'] ?? 0.0).toDouble(),
//                 return1M: (row['return_1m'] ?? 0.0).toDouble(),
//                 return3M: (row['return_3m'] ?? 0.0).toDouble(),
//                 return6M: (row['return_6m'] ?? 0.0).toDouble(),
//                 return1Y: (row['return_1y'] ?? 0.0).toDouble(),
//                 return3Y: (row['return_3y'] ?? 0.0).toDouble(),
//                 returnYTD: (row['return_ytd'] ?? 0.0).toDouble(),
//                 returnSinceInception:
//                     (row['return_since_inception'] ?? 0.0).toDouble(),
//                 scale: (row['scale'] ?? 0.0).toDouble(),
//                 riskLevel: row['risk_level'] ?? 'R3',
//                 status: row['status'] ?? 'active',
//                 unitNav: row['unit_nav']?.toDouble(),
//                 accumulatedNav: row['accumulated_nav']?.toDouble(),
//                 dailyReturn: row['daily_return']?.toDouble(),
//                 establishDate: row['establish_date'] != null
//                     ? DateTime.parse(row['establish_date'])
//                     : null,
//                 managementFee: row['management_fee']?.toDouble(),
//                 custodyFee: row['custody_fee']?.toDouble(),
//                 purchaseFee: row['purchase_fee']?.toDouble(),
//                 redemptionFee: row['redemption_fee']?.toDouble(),
//                 minimumInvestment: row['minimum_investment']?.toDouble(),
//                 performanceBenchmark: row['performance_benchmark'],
//                 investmentTarget: row['investment_target'],
//                 investmentScope: row['investment_scope'],
//                 currency: row['currency'],
//                 listingDate: row['listing_date'] != null
//                     ? DateTime.parse(row['listing_date'])
//                     : null,
//                 delistingDate: row['delisting_date'] != null
//                     ? DateTime.parse(row['delisting_date'])
//                     : null,
//               ))
//           .toList();
//     } catch (e) {
//       developer.log('获取基金缓存数据失败: $e', name: 'FundDatabaseRepository', error: e);
//       return null;
//     }
//   }

//   @override
//   Future<void> cacheFunds(String cacheKey, List<Fund> funds,
//       {Duration? ttl}) async {
//     try {
//       await _dbManager.beginTransaction();

//       for (final fund in funds) {
//         // 插入或更新基金基础信息
//         await _upsertFundBasicInfo(fund);

//         // 插入业绩数据
//         await _insertFundPerformance(fund);
//       }

//       await _dbManager.commitTransaction();
//       developer.log('基金数据缓存成功，共 ${funds.length} 条记录',
//           name: 'FundDatabaseRepository');
//     } catch (e) {
//       await _dbManager.rollbackTransaction();
//       developer.log('基金数据缓存失败: $e', name: 'FundDatabaseRepository', error: e);
//       throw Exception('基金数据缓存失败: $e');
//     }
//   }

//   /// 插入或更新基金基础信息
//   Future<void> _upsertFundBasicInfo(Fund fund) async {
//     const sql = '''
//       MERGE Fund_Basic_Info AS target
//       USING (SELECT @fund_code AS fund_code) AS source
//       ON target.fund_code = source.fund_code
//       WHEN MATCHED THEN
//         UPDATE SET
//           fund_name = @fund_name,
//           fund_type = @fund_type,
//           company = @company,
//           manager = @manager,
//           risk_level = @risk_level,
//           status = @status,
//           scale = @scale,
//           unit_nav = @unit_nav,
//           accumulated_nav = @accumulated_nav,
//           daily_return = @daily_return,
//           establish_date = @establish_date,
//           management_fee = @management_fee,
//           custody_fee = @custody_fee,
//           purchase_fee = @purchase_fee,
//           redemption_fee = @redemption_fee,
//           minimum_investment = @minimum_investment,
//           performance_benchmark = @performance_benchmark,
//           investment_target = @investment_target,
//           investment_scope = @investment_scope,
//           currency = @currency,
//           listing_date = @listing_date,
//           delisting_date = @delisting_date,
//           updated_at = GETDATE()
//       WHEN NOT MATCHED THEN
//         INSERT (fund_code, fund_name, fund_type, company, manager, risk_level, status, scale,
//                 unit_nav, accumulated_nav, daily_return, establish_date, management_fee,
//                 custody_fee, purchase_fee, redemption_fee, minimum_investment,
//                 performance_benchmark, investment_target, investment_scope, currency,
//                 listing_date, delisting_date)
//         VALUES (@fund_code, @fund_name, @fund_type, @company, @manager, @risk_level,
//                 @status, @scale, @unit_nav, @accumulated_nav, @daily_return,
//                 @establish_date, @management_fee, @custody_fee, @purchase_fee,
//                 @redemption_fee, @minimum_investment, @performance_benchmark,
//                 @investment_target, @investment_scope, @currency, @listing_date,
//                 @delisting_date);
//     ''';

//     await _dbManager.execute(sql, [
//       fund.code,
//       fund.name,
//       fund.type,
//       fund.company,
//       fund.manager,
//       fund.riskLevel,
//       fund.status,
//       fund.scale,
//       fund.unitNav,
//       fund.accumulatedNav,
//       fund.dailyReturn,
//       fund.establishDate?.toIso8601String().split('T')[0],
//       fund.managementFee,
//       fund.custodyFee,
//       fund.purchaseFee,
//       fund.redemptionFee,
//       fund.minimumInvestment,
//       fund.performanceBenchmark,
//       fund.investmentTarget,
//       fund.investmentScope,
//       fund.currency,
//       fund.listingDate?.toIso8601String().split('T')[0],
//       fund.delistingDate?.toIso8601String().split('T')[0],
//     ]);
//   }

//   /// 插入基金业绩数据
//   Future<void> _insertFundPerformance(Fund fund) async {
//     const sql = '''
//       INSERT INTO Fund_Performance (
//         fund_code, return_1w, return_1m, return_3m, return_6m,
//         return_1y, return_3y, return_ytd, return_since_inception,
//         performance_date
//       ) VALUES (
//         @fund_code, @return_1w, @return_1m, @return_3m, @return_6m,
//         @return_1y, @return_3y, @return_ytd, @return_since_inception,
//         GETDATE()
//       )
//     ''';

//     await _dbManager.execute(sql, [
//       fund.code,
//       fund.return1W,
//       fund.return1M,
//       fund.return3M,
//       fund.return6M,
//       fund.return1Y,
//       fund.return3Y,
//       fund.returnYTD,
//       fund.returnSinceInception,
//     ]);
//   }

//   @override
//   Future<Fund?> getCachedFundDetail(String fundCode) async {
//     try {
//       const sql = '''
//         SELECT TOP 1
//           f.fund_code, f.fund_name, f.fund_type, f.company, f.manager,
//           f.risk_level, f.status, f.scale, f.unit_nav, f.accumulated_nav,
//           f.daily_return, f.establish_date, f.management_fee, f.custody_fee,
//           f.purchase_fee, f.redemption_fee, f.minimum_investment,
//           f.performance_benchmark, f.investment_target, f.investment_scope,
//           f.currency, f.listing_date, f.delisting_date,
//           p.return_1w, p.return_1m, p.return_3m, p.return_6m,
//           p.return_1y, p.return_3y, p.return_ytd, p.return_since_inception,
//           p.sharpe_ratio, p.max_drawdown, p.volatility
//         FROM Fund_Basic_Info f
//         LEFT JOIN Fund_Performance p ON f.fund_code = p.fund_code
//         WHERE f.fund_code = @fund_code AND f.status = 'active'
//         ORDER BY p.performance_date DESC
//       ''';

//       final results = await _dbManager.query(sql, [fundCode]);

//       if (results.isEmpty) return null;

//       final row = results.first;
//       return Fund(
//         code: row['fund_code'],
//         name: row['fund_name'],
//         type: row['fund_type'],
//         company: row['company'],
//         manager: row['manager'] ?? '',
//         return1W: (row['return_1w'] ?? 0.0).toDouble(),
//         return1M: (row['return_1m'] ?? 0.0).toDouble(),
//         return3M: (row['return_3m'] ?? 0.0).toDouble(),
//         return6M: (row['return_6m'] ?? 0.0).toDouble(),
//         return1Y: (row['return_1y'] ?? 0.0).toDouble(),
//         return3Y: (row['return_3y'] ?? 0.0).toDouble(),
//         returnYTD: (row['return_ytd'] ?? 0.0).toDouble(),
//         returnSinceInception: (row['return_since_inception'] ?? 0.0).toDouble(),
//         scale: (row['scale'] ?? 0.0).toDouble(),
//         riskLevel: row['risk_level'] ?? 'R3',
//         status: row['status'] ?? 'active',
//         unitNav: row['unit_nav']?.toDouble(),
//         accumulatedNav: row['accumulated_nav']?.toDouble(),
//         dailyReturn: row['daily_return']?.toDouble(),
//         establishDate: row['establish_date'] != null
//             ? DateTime.parse(row['establish_date'])
//             : null,
//         managementFee: row['management_fee']?.toDouble(),
//         custodyFee: row['custody_fee']?.toDouble(),
//         purchaseFee: row['purchase_fee']?.toDouble(),
//         redemptionFee: row['redemption_fee']?.toDouble(),
//         minimumInvestment: row['minimum_investment']?.toDouble(),
//         performanceBenchmark: row['performance_benchmark'],
//         investmentTarget: row['investment_target'],
//         investmentScope: row['investment_scope'],
//         currency: row['currency'],
//         listingDate: row['listing_date'] != null
//             ? DateTime.parse(row['listing_date'])
//             : null,
//         delistingDate: row['delisting_date'] != null
//             ? DateTime.parse(row['delisting_date'])
//             : null,
//       );
//     } catch (e) {
//       developer.log('获取基金详情失败: $e', name: 'FundDatabaseRepository', error: e);
//       return null;
//     }
//   }

//   @override
//   Future<void> cacheFundDetail(String fundCode, Fund fund,
//       {Duration? ttl}) async {
//     try {
//       await _upsertFundBasicInfo(fund);
//       await _insertFundPerformance(fund);
//       developer.log('基金详情缓存成功: $fundCode', name: 'FundDatabaseRepository');
//     } catch (e) {
//       developer.log('基金详情缓存失败: $e', name: 'FundDatabaseRepository', error: e);
//       throw Exception('基金详情缓存失败: $e');
//     }
//   }

//   // 其他接口方法的简化实现...
//   @override
//   Future<List<Fund>?> getCachedSearchResults(String query) async {
//     // 实现搜索逻辑
//     return null;
//   }

//   @override
//   Future<void> cacheSearchResults(String query, List<Fund> results,
//       {Duration? ttl}) async {
//     // 实现搜索缓存逻辑
//   }

//   @override
//   Future<List<Fund>?> getCachedFilteredResults(FundFilter filter) async {
//     // 实现筛选逻辑
//     return null;
//   }

//   @override
//   Future<void> cacheFilteredResults(FundFilter filter, List<Fund> results,
//       {Duration? ttl}) async {
//     // 实现筛选缓存逻辑
//   }

//   @override
//   Future<void> clearCache(String cacheKey) async {
//     // 实现清理逻辑
//   }

//   @override
//   Future<void> clearAllCache() async {
//     try {
//       await _dbManager.execute('DELETE FROM Fund_Performance');
//       await _dbManager.execute('DELETE FROM Fund_Basic_Info');
//       developer.log('数据库缓存清理完成', name: 'FundDatabaseRepository');
//     } catch (e) {
//       developer.log('清理数据库缓存失败: $e', name: 'FundDatabaseRepository', error: e);
//     }
//   }

//   @override
//   Future<bool> isCacheExpired(String cacheKey) async {
//     // 实现过期检查逻辑
//     return false;
//   }

//   @override
//   Future<Duration?> getCacheAge(String cacheKey) async {
//     try {
//       // SQL数据库缓存通常没有时间戳信息，返回null表示无法确定年龄
//       // 可以根据实际需求扩展，在表中添加时间戳字段
//       return null;
//     } catch (e) {
//       developer.log('获取数据库缓存年龄失败: $e', name: 'FundDatabaseRepository');
//       return null;
//     }
//   }

//   @override
//   Future<Map<String, dynamic>> getCacheInfo() async {
//     try {
//       final countResult = await _dbManager
//           .query('SELECT COUNT(*) as count FROM Fund_Basic_Info');
//       final performanceCountResult = await _dbManager
//           .query('SELECT COUNT(*) as count FROM Fund_Performance');

//       return {
//         'fund_count': countResult.first['count'] ?? 0,
//         'performance_count': performanceCountResult.first['count'] ?? 0,
//         'database_status': 'connected',
//         'last_updated': DateTime.now().toIso8601String(),
//       };
//     } catch (e) {
//       return {
//         'error': e.toString(),
//         'database_status': 'error',
//       };
//     }
//   }

//   /// 提取缓存键中的限制数量
//   int _extractLimitFromCacheKey(String cacheKey) {
//     final match = RegExp(r'limit_(\d+)').firstMatch(cacheKey);
//     return match != null ? int.tryParse(match.group(1)!) ?? 50 : 50;
//   }

//   @override
//   Future<void> cacheFundRankings(
//       String period, List<Map<String, dynamic>> rankings,
//       {Duration? ttl}) async {
//     // 基金排行榜数据缓存的SQL实现
//     try {
//       // 这里可以根据需要实现排行榜数据的SQL存储
//       developer.log('基金排行榜缓存实现待完成', name: 'FundDatabaseRepository');
//     } catch (e) {
//       developer.log('基金排行榜缓存失败: $e', name: 'FundDatabaseRepository', error: e);
//     }
//   }

//   @override
//   Future<List<Map<String, dynamic>>?> getCachedFundRankings(
//       String period) async {
//     // 基金排行榜数据获取的SQL实现
//     try {
//       // 这里可以根据需要实现排行榜数据的SQL查询
//       developer.log('基金排行榜获取实现待完成', name: 'FundDatabaseRepository');
//       return null;
//     } catch (e) {
//       developer.log('基金排行榜获取失败: $e', name: 'FundDatabaseRepository', error: e);
//       return null;
//     }
//   }

//   @override
//   Future<void> clearExpiredCache() async {
//     try {
//       // SQL数据库清理过期缓存的实现
//       // 可以根据添加的时间戳字段来清理过期数据
//       developer.log('SQL数据库清理过期缓存实现待完成', name: 'FundDatabaseRepository');
//     } catch (e) {
//       developer.log('清理过期缓存失败: $e', name: 'FundDatabaseRepository', error: e);
//     }
//   }

//   @override
//   Future<Map<String, dynamic>> getCacheStats() async {
//     try {
//       // 返回SQL数据库的缓存统计信息
//       return {
//         'type': 'sql_server',
//         'isConnected': _dbManager.isConnected,
//         'timestamp': DateTime.now().toIso8601String(),
//       };
//     } catch (e) {
//       return {
//         'type': 'sql_server',
//         'error': e.toString(),
//         'timestamp': DateTime.now().toIso8601String(),
//       };
//     }
//   }

//   @override
//   Future<dynamic> getCachedData(String cacheKey) async {
//     try {
//       // 尝试解析缓存键，根据键的类型调用相应的方法
//       if (cacheKey.contains('fund_detail_')) {
//         final fundCode = cacheKey.replaceFirst('fund_detail_', '');
//         return await getCachedFundDetail(fundCode);
//       } else if (cacheKey.contains('fund_rankings_')) {
//         final period = cacheKey.replaceFirst('fund_rankings_', '');
//         return await getCachedFundRankings(period);
//       } else if (cacheKey.contains('search_results_')) {
//         final query = cacheKey.replaceFirst('search_results_', '');
//         return await getCachedSearchResults(query);
//       } else {
//         // 默认作为基金列表处理
//         return await getCachedFunds(cacheKey);
//       }
//     } catch (e) {
//       developer.log('获取通用缓存数据失败: $e', name: 'FundDatabaseRepository', error: e);
//       return null;
//     }
//   }

//   @override
//   Future<void> cacheData(String cacheKey, dynamic data,
//       {required Duration ttl}) async {
//     try {
//       // 根据数据类型和缓存键选择合适的存储方法
//       if (data is Fund) {
//         if (cacheKey.contains('fund_detail_')) {
//           final fundCode = cacheKey.replaceFirst('fund_detail_', '');
//           await cacheFundDetail(fundCode, data, ttl: ttl);
//         } else {
//           // 作为单个基金缓存
//           await cacheFunds(cacheKey, [data], ttl: ttl);
//         }
//       } else if (data is List<Fund>) {
//         await cacheFunds(cacheKey, data, ttl: ttl);
//       } else if (data is List<Map<String, dynamic>>) {
//         if (cacheKey.contains('fund_rankings_')) {
//           final period = cacheKey.replaceFirst('fund_rankings_', '');
//           await cacheFundRankings(period, data, ttl: ttl);
//         } else {
//           developer.log('不支持的Map列表缓存类型: $cacheKey',
//               name: 'FundDatabaseRepository');
//         }
//       } else {
//         developer.log('不支持的数据类型缓存: ${data.runtimeType}',
//             name: 'FundDatabaseRepository');
//       }
//     } catch (e) {
//       developer.log('缓存通用数据失败: $e', name: 'FundDatabaseRepository', error: e);
//       throw Exception('缓存通用数据失败: $e');
//     }
//   }
// }
