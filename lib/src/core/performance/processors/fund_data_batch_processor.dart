import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../../utils/logger.dart';
import 'smart_batch_processor.dart';
import 'hybrid_data_parser.dart';
import '../managers/advanced_memory_manager.dart';
import '../monitors/memory_pressure_monitor.dart';
import '../optimizers/adaptive_compression_strategy.dart';
import '../optimizers/data_deduplication_manager.dart';

/// 基金数据批次处理结果
class FundDataBatchResult {
  final int processedCount;
  final int successCount;
  final int errorCount;
  final Duration processingTime;
  final int memoryFreedBytes;
  final int compressionSavedBytes;
  final List<String> errors;

  const FundDataBatchResult({
    required this.processedCount,
    required this.successCount,
    required this.errorCount,
    required this.processingTime,
    this.memoryFreedBytes = 0,
    this.compressionSavedBytes = 0,
    this.errors = const [],
  });

  double get successRate =>
      processedCount > 0 ? successCount / processedCount : 0.0;
  double get throughputItemsPerSecond => processingTime.inMilliseconds > 0
      ? processedCount * 1000 / processingTime.inMilliseconds
      : 0;

  Map<String, dynamic> toJson() {
    return {
      'processedCount': processedCount,
      'successCount': successCount,
      'errorCount': errorCount,
      'successRate': successRate,
      'processingTimeMs': processingTime.inMilliseconds,
      'throughputItemsPerSecond': throughputItemsPerSecond,
      'memoryFreedBytes': memoryFreedBytes,
      'compressionSavedBytes': compressionSavedBytes,
      'errors': errors,
    };
  }
}

/// 基金数据批次处理器
///
/// 专门处理基金数据的批次操作，包括：
/// - 批量数据解析和验证
/// - 数据压缩和解压缩
/// - 内存优化管理
/// - 错误处理和重试机制
class FundDataBatchProcessor {
  final SmartBatchProcessor _batchProcessor;
  final HybridDataParser _dataParser;
  final AdvancedMemoryManager _memoryManager;
  final AdaptiveCompressionStrategy _compressionStrategy;
  final DataDeduplicationManager _deduplicationManager;

  // 处理器配置
  final int maxBatchSize;
  final Duration maxProcessingTime;
  final int maxRetries;
  final bool enableCompression;
  final bool enableDeduplication;

  FundDataBatchProcessor({
    SmartBatchProcessor? batchProcessor,
    HybridDataParser? dataParser,
    AdvancedMemoryManager? memoryManager,
    AdaptiveCompressionStrategy? compressionStrategy,
    DataDeduplicationManager? deduplicationManager,
    this.maxBatchSize = 500,
    this.maxProcessingTime = const Duration(seconds: 30),
    this.maxRetries = 3,
    this.enableCompression = true,
    this.enableDeduplication = true,
  })  : _batchProcessor = batchProcessor ?? SmartBatchProcessor(),
        _dataParser = dataParser ?? HybridDataParser(),
        _memoryManager = memoryManager ?? AdvancedMemoryManager.instance,
        _compressionStrategy =
            compressionStrategy ?? AdaptiveCompressionStrategy(),
        _deduplicationManager =
            deduplicationManager ?? DataDeduplicationManager();

  /// 初始化批次处理器
  Future<void> initialize() async {
    try {
      await _batchProcessor.initialize();
      AppLogger.business('基金数据批次处理器初始化完成', 'FundDataBatchProcessor');
    } catch (e) {
      AppLogger.error('基金数据批次处理器初始化失败', e);
      rethrow;
    }
  }

  /// 批量处理基金数据
  Future<FundDataBatchResult> processFundDataBatch(
    List<Map<String, dynamic>> rawDataList,
  ) async {
    final stopwatch = Stopwatch()..start();
    int processedCount = 0;
    int successCount = 0;
    int errorCount = 0;
    final List<String> errors = [];
    int totalMemoryFreed = 0;
    int totalCompressionSaved = 0;

    try {
      AppLogger.debug(
          '开始批量处理基金数据', '数据量: ${rawDataList.length}, 最大批次: $maxBatchSize');

      // 分批处理数据
      for (int i = 0; i < rawDataList.length; i += maxBatchSize) {
        final endIndex = (i + maxBatchSize).clamp(0, rawDataList.length);
        final batch = rawDataList.sublist(i, endIndex);

        if (stopwatch.elapsed > maxProcessingTime) {
          AppLogger.warn('批次处理超时，停止处理',
              '已处理: $processedCount, 耗时: ${stopwatch.elapsedMilliseconds}ms');
          break;
        }

        final batchResult = await _processSingleBatch(batch);
        processedCount += batch.length;
        successCount += batchResult.successCount;
        errorCount += batchResult.errorCount;
        errors.addAll(batchResult.errors);
        totalMemoryFreed += batchResult.memoryFreedBytes;
        totalCompressionSaved += batchResult.compressionSavedBytes;

        // 内存压力检查
        await _checkMemoryPressure();

        // 短暂休息，避免CPU过载
        await Future.delayed(const Duration(milliseconds: 10));
      }

      stopwatch.stop();

      final result = FundDataBatchResult(
        processedCount: processedCount,
        successCount: successCount,
        errorCount: errorCount,
        processingTime: stopwatch.elapsed,
        memoryFreedBytes: totalMemoryFreed,
        compressionSavedBytes: totalCompressionSaved,
        errors: errors,
      );

      AppLogger.business(
          '基金数据批次处理完成',
          '成功: $successCount, 失败: $errorCount, '
              '吞吐量: ${result.throughputItemsPerSecond.toStringAsFixed(1)} items/s');

      return result;
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('基金数据批次处理失败', e);

      return FundDataBatchResult(
        processedCount: processedCount,
        successCount: successCount,
        errorCount: errorCount + 1,
        processingTime: stopwatch.elapsed,
        memoryFreedBytes: totalMemoryFreed,
        compressionSavedBytes: totalCompressionSaved,
        errors: [...errors, e.toString()],
      );
    }
  }

  /// 处理单个批次
  Future<FundDataBatchResult> _processSingleBatch(
    List<Map<String, dynamic>> batch,
  ) async {
    int successCount = 0;
    int errorCount = 0;
    final List<String> errors = [];
    int memoryFreed = 0;
    int compressionSaved = 0;

    for (final rawData in batch) {
      try {
        // 数据预处理
        final processedData = await _preprocessData(rawData);

        // 数据压缩（如果启用且数据足够大）
        if (enableCompression && _shouldCompressData(processedData)) {
          final compressionResult =
              await _compressionStrategy.compress(processedData);
          compressionSaved +=
              compressionResult.originalSize - compressionResult.compressedSize;
        }

        // 数据去重（如果启用）
        if (enableDeduplication) {
          await _deduplicationManager.processData(processedData);
        }

        successCount++;
      } catch (e) {
        errorCount++;
        errors.add('处理数据失败: ${e.toString()}');
        AppLogger.warn('单条数据处理失败', e);
      }
    }

    return FundDataBatchResult(
      processedCount: batch.length,
      successCount: successCount,
      errorCount: errorCount,
      processingTime: Duration.zero, // 单个批次不计时间
      memoryFreedBytes: memoryFreed,
      compressionSavedBytes: compressionSaved,
      errors: errors,
    );
  }

  /// 数据预处理
  Future<Map<String, dynamic>> _preprocessData(
      Map<String, dynamic> rawData) async {
    // 验证必要字段
    _validateRequiredFields(rawData);

    // 清理和标准化数据
    final cleanedData = _cleanAndStandardizeData(rawData);

    // 数据类型转换
    final typedData = _convertDataTypes(cleanedData);

    return typedData;
  }

  /// 验证必要字段
  void _validateRequiredFields(Map<String, dynamic> data) {
    final requiredFields = ['code', 'name', 'nav'];
    for (final field in requiredFields) {
      if (!data.containsKey(field) || data[field] == null) {
        throw ArgumentError('缺少必要字段: $field');
      }
    }
  }

  /// 清理和标准化数据
  Map<String, dynamic> _cleanAndStandardizeData(Map<String, dynamic> data) {
    final cleaned = <String, dynamic>{};

    for (final entry in data.entries) {
      final key = entry.key.trim().toLowerCase();
      dynamic value = entry.value;

      // 清理字符串值
      if (value is String) {
        value = value.trim();
        if (value.isEmpty) continue;
      }

      // 清理数值
      if (value is num) {
        if (value.isNaN || value.isInfinite) continue;
      }

      cleaned[key] = value;
    }

    return cleaned;
  }

  /// 数据类型转换
  Map<String, dynamic> _convertDataTypes(Map<String, dynamic> data) {
    final converted = <String, dynamic>{};

    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;

      try {
        // 基金代码转换为字符串
        if (key.contains('code')) {
          converted[key] = value.toString();
        }
        // NAV相关字段转换为double
        else if (key.contains('nav') || key.contains('value')) {
          converted[key] = double.tryParse(value.toString()) ?? 0.0;
        }
        // 日期字段处理
        else if (key.contains('date') || key.contains('time')) {
          converted[key] = value.toString();
        }
        // 其他字段保持原类型
        else {
          converted[key] = value;
        }
      } catch (e) {
        AppLogger.debug('字段类型转换失败', '字段: $key, 值: $value, 错误: $e');
        converted[key] = value; // 转换失败时保持原值
      }
    }

    return converted;
  }

  /// 判断是否应该压缩数据
  bool _shouldCompressData(Map<String, dynamic> data) {
    try {
      final jsonString = jsonEncode(data);
      return jsonString.length > 1024; // 大于1KB的数据进行压缩
    } catch (e) {
      return false;
    }
  }

  /// 检查内存压力
  Future<void> _checkMemoryPressure() async {
    try {
      final memoryInfo = _memoryManager.getMemoryInfo();
      final usedMemoryMB =
          memoryInfo.totalMemoryMB - memoryInfo.availableMemoryMB;
      final usageRatio = usedMemoryMB / memoryInfo.totalMemoryMB;

      if (usageRatio > 0.85) {
        AppLogger.warn(
            '内存压力过高，触发清理', '使用率: ${(usageRatio * 100).toStringAsFixed(1)}%');
        await _memoryManager.forceGarbageCollection();
      }
    } catch (e) {
      AppLogger.debug('内存压力检查失败', e);
    }
  }

  /// 获取批次处理器状态
  Map<String, dynamic> getProcessorStatus() {
    return {
      'isInitialized': _batchProcessor.currentState.name != 'idle',
      'currentBatchSize': _batchProcessor.currentBatchSize,
      'queueLength': _batchProcessor.queueLength,
      'metrics': _batchProcessor.metrics.toMap(),
      'config': {
        'maxBatchSize': maxBatchSize,
        'maxProcessingTime': maxProcessingTime.inMilliseconds,
        'maxRetries': maxRetries,
        'enableCompression': enableCompression,
        'enableDeduplication': enableDeduplication,
      },
    };
  }

  /// 清理资源
  Future<void> dispose() async {
    try {
      await _batchProcessor.dispose();
      AppLogger.business('基金数据批次处理器已清理', 'FundDataBatchProcessor');
    } catch (e) {
      AppLogger.error('基金数据批次处理器清理失败', e);
    }
  }
}
