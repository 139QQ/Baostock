import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:decimal/decimal.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/utils/logger.dart';
import '../../models/fund_nav_data.dart';

/// NAV数据压缩和批量处理优化器
///
/// 提供数据压缩、批量处理优化和性能监控功能
/// 支持多种压缩算法和智能批量处理策略
class NavDataCompressionOptimizer {
  /// 单例实例
  static final NavDataCompressionOptimizer _instance =
      NavDataCompressionOptimizer._internal();

  factory NavDataCompressionOptimizer() => _instance;

  NavDataCompressionOptimizer._internal() {
    _initialize();
  }

  /// 压缩配置
  final CompressionConfig _config = CompressionConfig();

  /// 批量处理配置
  final BatchConfig _batchConfig = BatchConfig();

  /// 性能统计
  final PerformanceStatistics _statistics = PerformanceStatistics();

  /// 压缩缓存
  final Map<String, CompressedData> _compressionCache = {};

  /// 批量处理队列
  final Queue<BatchOperation> _batchQueue = Queue<BatchOperation>();

  /// 批量处理定时器
  Timer? _batchTimer;

  /// 正在处理的批量操作
  final Set<String> _processingBatches = {};

  /// 初始化优化器
  Future<void> _initialize() async {
    try {
      // 启动批量处理定时器
      _startBatchProcessor();

      AppLogger.info('NavDataCompressionOptimizer initialized successfully');
    } catch (e) {
      AppLogger.error('Failed to initialize NavDataCompressionOptimizer', e);
    }
  }

  /// 压缩NAV数据
  Future<CompressedData> compressNavData(List<FundNavData> navDataList) async {
    try {
      final stopwatch = Stopwatch()..start();

      // 1. 序列化数据
      final jsonData = jsonEncode({
        'data': navDataList.map((data) => data.toJson()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
        'count': navDataList.length,
      });

      // 2. 压缩数据
      final compressedBytes = _compressBytes(utf8.encode(jsonData));

      // 3. 创建压缩数据对象
      final compressedData = CompressedData(
        originalSize: jsonData.length,
        compressedSize: compressedBytes.length,
        algorithm: _config.algorithm,
        data: compressedBytes,
        checksum: _calculateChecksum(compressedBytes),
        timestamp: DateTime.now(),
      );

      // 4. 更新统计信息
      final compressionTime = stopwatch.elapsed;
      _statistics.recordCompression(
        originalSize: jsonData.length,
        compressedSize: compressedBytes.length,
        duration: compressionTime,
      );

      AppLogger.debug(
          '压缩NAV数据: ${navDataList.length}项, ${(jsonData.length / 1024).toStringAsFixed(1)}KB -> ${(compressedBytes.length / 1024).toStringAsFixed(1)}KB (${compressionTime.inMilliseconds}ms)');

      return compressedData;
    } catch (e) {
      AppLogger.error('压缩NAV数据失败', e);
      rethrow;
    }
  }

  /// 解压缩NAV数据
  Future<List<FundNavData>> decompressNavData(
      CompressedData compressedData) async {
    try {
      final stopwatch = Stopwatch()..start();

      // 1. 验证校验和
      if (!_verifyChecksum(compressedData.data, compressedData.checksum)) {
        throw Exception('数据校验失败，可能已损坏');
      }

      // 2. 解压缩数据
      final decompressedBytes = _decompressBytes(compressedData.data);

      // 3. 反序列化数据
      final jsonData = utf8.decode(decompressedBytes);
      final jsonMap = jsonDecode(jsonData) as Map<String, dynamic>;

      // 4. 解析NAV数据
      final dataList = (jsonMap['data'] as List<dynamic>)
          .map((item) => FundNavData.fromJson(item as Map<String, dynamic>))
          .toList();

      // 5. 更新统计信息
      final decompressionTime = stopwatch.elapsed;
      _statistics.recordDecompression(
        compressedSize: compressedData.compressedSize,
        originalSize: compressedData.originalSize,
        duration: decompressionTime,
      );

      AppLogger.debug(
          '解压缩NAV数据: ${dataList.length}项, ${(compressedData.compressedSize / 1024).toStringAsFixed(1)}KB -> ${(compressedData.originalSize / 1024).toStringAsFixed(1)}KB (${decompressionTime.inMilliseconds}ms)');

      return dataList;
    } catch (e) {
      AppLogger.error('解压缩NAV数据失败', e);
      rethrow;
    }
  }

  /// 批量处理NAV数据
  Future<BatchOperationResult> processBatchNavData(
    String batchId,
    List<FundNavData> navDataList, {
    bool enableCompression = true,
    bool enableValidation = true,
  }) async {
    try {
      final stopwatch = Stopwatch()..start();

      // 防止重复处理
      if (_processingBatches.contains(batchId)) {
        throw Exception('批次 $batchId 正在处理中');
      }

      _processingBatches.add(batchId);

      AppLogger.debug('开始批量处理NAV数据: $batchId (${navDataList.length}项)');

      // 1. 数据验证（可选）
      if (enableValidation) {
        final validationResult = _validateBatchData(navDataList);
        if (!validationResult.isValid) {
          throw Exception('数据验证失败: ${validationResult.errors.join(', ')}');
        }
      }

      // 2. 数据压缩（可选）
      CompressedData? compressedData;
      if (enableCompression &&
          navDataList.length >= _config.compressionThreshold) {
        compressedData = await compressNavData(navDataList);
      }

      // 3. 创建批量结果
      final result = BatchOperationResult(
        batchId: batchId,
        itemCount: navDataList.length,
        compressedData: compressedData,
        processingTime: stopwatch.elapsed,
        success: true,
        timestamp: DateTime.now(),
      );

      // 4. 更新统计信息
      _statistics.recordBatchProcessing(
        itemCount: navDataList.length,
        duration: result.processingTime,
        compressionEnabled: enableCompression,
      );

      AppLogger.info(
          '批量处理完成: $batchId, ${navDataList.length}项, 耗时${result.processingTime.inMilliseconds}ms');

      return result;
    } catch (e) {
      AppLogger.error('批量处理NAV数据失败: $batchId', e);

      final errorStopwatch = Stopwatch()..start();
      errorStopwatch.stop();

      final result = BatchOperationResult(
        batchId: batchId,
        itemCount: navDataList.length,
        processingTime: errorStopwatch.elapsed,
        success: false,
        error: e.toString(),
        timestamp: DateTime.now(),
      );

      _statistics.recordBatchProcessing(
        itemCount: navDataList.length,
        duration: result.processingTime,
        compressionEnabled: enableCompression,
        success: false,
      );

      return result;
    } finally {
      _processingBatches.remove(batchId);
    }
  }

  /// 添加批量操作到队列
  void enqueueBatchOperation({
    required String batchId,
    required List<FundNavData> navDataList,
    bool enableCompression = true,
    bool enableValidation = true,
    Function(BatchOperationResult)? onComplete,
  }) {
    final operation = BatchOperation(
      batchId: batchId,
      navDataList: navDataList,
      enableCompression: enableCompression,
      enableValidation: enableValidation,
      onComplete: onComplete,
      timestamp: DateTime.now(),
    );

    _batchQueue.add(operation);

    // 如果队列过长，立即处理
    if (_batchQueue.length >= _batchConfig.maxQueueSize) {
      _processBatchQueue();
    }

    AppLogger.debug('批量操作已入队: $batchId (队列长度: ${_batchQueue.length})');
  }

  /// 处理批量队列
  Future<void> _processBatchQueue() async {
    if (_batchQueue.isEmpty ||
        _processingBatches.length >= _batchConfig.maxConcurrentBatches) {
      return;
    }

    final operations = <BatchOperation>[];
    final batchSize = math.min(_batchConfig.batchSize, _batchQueue.length);

    // 取出一批操作
    for (int i = 0; i < batchSize; i++) {
      if (_batchQueue.isNotEmpty) {
        operations.add(_batchQueue.removeFirst());
      }
    }

    if (operations.isEmpty) return;

    AppLogger.debug('开始处理批量队列: ${operations.length}个操作');

    // 并发处理操作
    final futures = operations.map((operation) async {
      try {
        final result = await processBatchNavData(
          operation.batchId,
          operation.navDataList,
          enableCompression: operation.enableCompression,
          enableValidation: operation.enableValidation,
        );

        // 调用完成回调
        operation.onComplete?.call(result);

        return result;
      } catch (e) {
        AppLogger.error('批量队列操作失败: ${operation.batchId}', e);
        return null;
      }
    });

    await Future.wait(futures);
  }

  /// 启动批量处理器
  void _startBatchProcessor() {
    _batchTimer?.cancel();
    _batchTimer = Timer.periodic(_batchConfig.processingInterval, (_) {
      _processBatchQueue();
    });
  }

  /// 压缩字节数据 (临时简化实现，实际需要添加archive包)
  List<int> _compressBytes(List<int> data) {
    try {
      switch (_config.algorithm) {
        case CompressionAlgorithm.gzip:
          // 暂时返回原数据，需要添加 archive 包
          return data;
        case CompressionAlgorithm.zlib:
          // 暂时返回原数据，需要添加 archive 包
          return data;
        case CompressionAlgorithm.bzip2:
          // 暂时返回原数据，需要添加 archive 包
          return data;
      }
    } catch (e) {
      AppLogger.warn('压缩失败，返回原数据', e);
      return data;
    }
  }

  /// 解压缩字节数据 (临时简化实现，实际需要添加archive包)
  List<int> _decompressBytes(List<int> compressedData) {
    try {
      switch (_config.algorithm) {
        case CompressionAlgorithm.gzip:
          // 暂时返回原数据，需要添加 archive 包
          return compressedData;
        case CompressionAlgorithm.zlib:
          // 暂时返回原数据，需要添加 archive 包
          return compressedData;
        case CompressionAlgorithm.bzip2:
          // 暂时返回原数据，需要添加 archive 包
          return compressedData;
      }
    } catch (e) {
      AppLogger.warn('解压缩失败，返回原数据', e);
      return compressedData;
    }
  }

  /// 计算校验和
  String _calculateChecksum(List<int> data) {
    // 简单的校验和算法
    int sum = 0;
    for (final byte in data) {
      sum = (sum + byte) & 0xFFFFFFFF;
    }
    return sum.toRadixString(16).padLeft(8, '0');
  }

  /// 验证校验和
  bool _verifyChecksum(List<int> data, String expectedChecksum) {
    final actualChecksum = _calculateChecksum(data);
    return actualChecksum == expectedChecksum;
  }

  /// 验证批量数据
  BatchValidationResult _validateBatchData(List<FundNavData> navDataList) {
    final errors = <String>[];
    final warnings = <String>[];

    if (navDataList.isEmpty) {
      errors.add('数据列表为空');
      return BatchValidationResult(
          isValid: false, errors: errors, warnings: warnings);
    }

    // 检查数据完整性
    for (int i = 0; i < navDataList.length; i++) {
      final navData = navDataList[i];

      // 检查必要字段
      if (navData.fundCode.isEmpty) {
        errors.add('第${i + 1}项数据缺少基金代码');
      }

      if (navData.navDate
          .isAfter(DateTime.now().add(const Duration(days: 1)))) {
        warnings.add('第${i + 1}项数据日期异常: ${navData.navDate}');
      }

      if (navData.nav < Decimal.zero) {
        warnings.add('第${i + 1}项净值异常: ${navData.nav}');
      }
    }

    // 检查重复数据
    final uniqueCodes = navDataList.map((data) => data.fundCode).toSet();
    if (uniqueCodes.length != navDataList.length) {
      warnings.add('发现重复的基金代码');
    }

    return BatchValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// 优化缓存存储
  Future<void> optimizeCacheStorage() async {
    try {
      AppLogger.debug('开始优化缓存存储...');

      // 清理过期的压缩缓存
      final expiredKeys = <String>[];
      final now = DateTime.now();

      for (final entry in _compressionCache.entries) {
        if (now.difference(entry.value.timestamp) > _config.cacheExpiration) {
          expiredKeys.add(entry.key);
        }
      }

      for (final key in expiredKeys) {
        _compressionCache.remove(key);
      }

      // 如果缓存过大，清理最旧的数据
      if (_compressionCache.length > _config.maxCacheSize) {
        final entries = _compressionCache.entries.toList()
          ..sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));

        final removeCount = _compressionCache.length - _config.maxCacheSize;
        for (int i = 0; i < removeCount; i++) {
          _compressionCache.remove(entries[i].key);
        }
      }

      AppLogger.debug('缓存存储优化完成: 清理了${expiredKeys.length}个过期项');
    } catch (e) {
      AppLogger.error('优化缓存存储失败', e);
    }
  }

  /// 获取性能统计
  PerformanceStatistics get statistics => _statistics;

  /// 获取队列状态
  Map<String, dynamic> getQueueStatus() {
    return {
      'queueLength': _batchQueue.length,
      'processingBatches': _processingBatches.length,
      'maxQueueSize': _batchConfig.maxQueueSize,
      'maxConcurrentBatches': _batchConfig.maxConcurrentBatches,
      'compressionCacheSize': _compressionCache.length,
    };
  }

  /// 更新配置
  void updateConfig({
    CompressionConfig? compressionConfig,
    BatchConfig? batchConfig,
  }) {
    if (compressionConfig != null) {
      _config.updateFrom(compressionConfig);
    }
    if (batchConfig != null) {
      _batchConfig.updateFrom(batchConfig);
      _startBatchProcessor(); // 重启批量处理器
    }

    AppLogger.info('压缩优化器配置已更新');
  }

  /// 释放资源
  Future<void> dispose() async {
    _batchTimer?.cancel();
    _batchTimer = null;

    _batchQueue.clear();
    _processingBatches.clear();
    _compressionCache.clear();

    AppLogger.info('NavDataCompressionOptimizer disposed');
  }
}

/// 压缩数据
class CompressedData {
  final int originalSize;
  final int compressedSize;
  final CompressionAlgorithm algorithm;
  final List<int> data;
  final String checksum;
  final DateTime timestamp;

  CompressedData({
    required this.originalSize,
    required this.compressedSize,
    required this.algorithm,
    required this.data,
    required this.checksum,
    required this.timestamp,
  });

  /// 获取压缩比
  double get compressionRatio =>
      originalSize > 0 ? compressedSize / originalSize : 1.0;

  /// 获取空间节省百分比
  double get spaceSavedPercentage => (1.0 - compressionRatio) * 100;

  Map<String, dynamic> toJson() {
    return {
      'originalSize': originalSize,
      'compressedSize': compressedSize,
      'algorithm': algorithm.name,
      'checksum': checksum,
      'timestamp': timestamp.toIso8601String(),
      // 注意：实际数据不序列化，只在内存中使用
    };
  }
}

/// 批量操作
class BatchOperation {
  final String batchId;
  final List<FundNavData> navDataList;
  final bool enableCompression;
  final bool enableValidation;
  final Function(BatchOperationResult)? onComplete;
  final DateTime timestamp;

  BatchOperation({
    required this.batchId,
    required this.navDataList,
    this.enableCompression = true,
    this.enableValidation = true,
    this.onComplete,
    required this.timestamp,
  });
}

/// 批量操作结果
class BatchOperationResult {
  final String batchId;
  final int itemCount;
  final CompressedData? compressedData;
  final Duration processingTime;
  final bool success;
  final String? error;
  final DateTime timestamp;

  BatchOperationResult({
    required this.batchId,
    required this.itemCount,
    this.compressedData,
    required this.processingTime,
    required this.success,
    this.error,
    required this.timestamp,
  });

  /// 获取压缩统计
  Map<String, dynamic>? get compressionStats => compressedData != null
      ? {
          'originalSize': compressedData!.originalSize,
          'compressedSize': compressedData!.compressedSize,
          'compressionRatio': compressedData!.compressionRatio,
          'spaceSavedPercentage': compressedData!.spaceSavedPercentage,
        }
      : null;

  Map<String, dynamic> toJson() {
    return {
      'batchId': batchId,
      'itemCount': itemCount,
      'processingTimeMs': processingTime.inMilliseconds,
      'success': success,
      'error': error,
      'timestamp': timestamp.toIso8601String(),
      'compressionStats': compressionStats,
    };
  }
}

/// 批量验证结果
class BatchValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  BatchValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });
}

/// 压缩算法
enum CompressionAlgorithm {
  gzip,
  zlib,
  bzip2,
}

/// 压缩配置
class CompressionConfig {
  CompressionAlgorithm algorithm;
  int compressionThreshold;
  Duration cacheExpiration;
  int maxCacheSize;

  CompressionConfig({
    this.algorithm = CompressionAlgorithm.gzip,
    this.compressionThreshold = 10,
    this.cacheExpiration = const Duration(hours: 1),
    this.maxCacheSize = 100,
  });

  void updateFrom(CompressionConfig other) {
    algorithm = other.algorithm;
    compressionThreshold = other.compressionThreshold;
    cacheExpiration = other.cacheExpiration;
    maxCacheSize = other.maxCacheSize;
  }
}

/// 批量处理配置
class BatchConfig {
  int batchSize;
  int maxQueueSize;
  int maxConcurrentBatches;
  Duration processingInterval;

  BatchConfig({
    this.batchSize = 10,
    this.maxQueueSize = 100,
    this.maxConcurrentBatches = 5,
    this.processingInterval = const Duration(milliseconds: 100),
  });

  void updateFrom(BatchConfig other) {
    batchSize = other.batchSize;
    maxQueueSize = other.maxQueueSize;
    maxConcurrentBatches = other.maxConcurrentBatches;
    processingInterval = other.processingInterval;
  }
}

/// 性能统计
class PerformanceStatistics {
  int totalCompressions = 0;
  int totalDecompressions = 0;
  int totalBatchOperations = 0;
  int successfulBatchOperations = 0;

  int totalOriginalSize = 0;
  int totalCompressedSize = 0;
  int totalCompressionTime = 0; // 毫秒
  int totalDecompressionTime = 0; // 毫秒
  int totalBatchProcessingTime = 0; // 毫秒

  /// 记录压缩操作
  void recordCompression({
    required int originalSize,
    required int compressedSize,
    required Duration duration,
  }) {
    totalCompressions++;
    totalOriginalSize += originalSize;
    totalCompressedSize += compressedSize;
    totalCompressionTime += duration.inMilliseconds;
  }

  /// 记录解压缩操作
  void recordDecompression({
    required int compressedSize,
    required int originalSize,
    required Duration duration,
  }) {
    totalDecompressions++;
    totalOriginalSize += originalSize;
    totalCompressedSize += compressedSize;
    totalDecompressionTime += duration.inMilliseconds;
  }

  /// 记录批量处理操作
  void recordBatchProcessing({
    required int itemCount,
    required Duration duration,
    required bool compressionEnabled,
    bool success = true,
  }) {
    totalBatchOperations++;
    if (success) {
      successfulBatchOperations++;
    }
    totalBatchProcessingTime += duration.inMilliseconds;
  }

  /// 获取平均压缩比
  double get averageCompressionRatio {
    if (totalOriginalSize == 0) return 1.0;
    return totalCompressedSize / totalOriginalSize;
  }

  /// 获取空间节省百分比
  double get spaceSavedPercentage {
    return (1.0 - averageCompressionRatio) * 100;
  }

  /// 获取平均压缩时间
  double get averageCompressionTime {
    if (totalCompressions == 0) return 0.0;
    return totalCompressionTime / totalCompressions;
  }

  /// 获取平均解压缩时间
  double get averageDecompressionTime {
    if (totalDecompressions == 0) return 0.0;
    return totalDecompressionTime / totalDecompressions;
  }

  /// 获取批量操作成功率
  double get batchOperationSuccessRate {
    if (totalBatchOperations == 0) return 0.0;
    return successfulBatchOperations / totalBatchOperations;
  }

  /// 重置统计信息
  void reset() {
    totalCompressions = 0;
    totalDecompressions = 0;
    totalBatchOperations = 0;
    successfulBatchOperations = 0;
    totalOriginalSize = 0;
    totalCompressedSize = 0;
    totalCompressionTime = 0;
    totalDecompressionTime = 0;
    totalBatchProcessingTime = 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'totalCompressions': totalCompressions,
      'totalDecompressions': totalDecompressions,
      'totalBatchOperations': totalBatchOperations,
      'successfulBatchOperations': successfulBatchOperations,
      'averageCompressionRatio': averageCompressionRatio,
      'spaceSavedPercentage': spaceSavedPercentage,
      'averageCompressionTime': averageCompressionTime.round(),
      'averageDecompressionTime': averageDecompressionTime.round(),
      'batchOperationSuccessRate': batchOperationSuccessRate,
      'totalOriginalSizeMB':
          (totalOriginalSize / (1024 * 1024)).toStringAsFixed(2),
      'totalCompressedSizeMB':
          (totalCompressedSize / (1024 * 1024)).toStringAsFixed(2),
    };
  }

  @override
  String toString() {
    return 'PerformanceStatistics(compressions: $totalCompressions, decompressions: $totalDecompressions, '
        'spaceSaved: ${spaceSavedPercentage.toStringAsFixed(1)}%, batchSuccessRate: ${(batchOperationSuccessRate * 100).toStringAsFixed(1)}%)';
  }
}
