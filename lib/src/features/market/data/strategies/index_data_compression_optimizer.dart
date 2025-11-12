import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:decimal/decimal.dart';

import '../../../../core/utils/logger.dart';
import '../../models/market_index_data.dart';

/// 指数数据压缩优化器
///
/// 负责市场指数数据的压缩、解压缩和批量处理优化
class IndexDataCompressionOptimizer {
  /// 压缩配置
  final CompressionConfig _config;

  /// 压缩统计信息
  CompressionStatistics _statistics = CompressionStatistics();

  /// 构造函数
  IndexDataCompressionOptimizer({
    CompressionConfig? config,
  }) : _config = config ?? const CompressionConfig();

  /// 压缩单个指数数据
  CompressedIndexData compressIndexData(MarketIndexData data) {
    try {
      final stopwatch = Stopwatch()..start();

      // 1. 基础压缩：移除冗余字段
      final optimizedData = _removeRedundantFields(data);

      // 2. 数值精度优化
      final precisionOptimized = _optimizeNumericPrecision(optimizedData);

      // 3. 字符串压缩
      final stringCompressed = _compressStringFields(precisionOptimized);

      // 4. 二进制序列化
      final binaryData = _serializeToBinary(stringCompressed);

      // 5. 应用压缩算法
      final compressed = _applyCompression(binaryData);

      stopwatch.stop();

      // 更新统计信息
      _statistics.recordCompression(
        originalSize: _calculateOriginalSize(data),
        compressedSize: compressed.length,
        compressionTime: stopwatch.elapsed,
      );

      final result = CompressedIndexData(
        indexCode: data.code,
        compressedData: compressed,
        originalSize: _calculateOriginalSize(data),
        compressedSize: compressed.length,
        compressionAlgorithm: _config.algorithm,
        timestamp: data.updateTime,
      );

      AppLogger.debug(
          'Compressed index data for ${data.code}: ${result.compressionRatio.toStringAsFixed(2)}x');

      return result;
    } catch (e) {
      AppLogger.error('Failed to compress index data for ${data.code}: $e', e);
      _statistics.recordError();
      rethrow;
    }
  }

  /// 批量压缩指数数据
  List<CompressedIndexData> compressBatch(List<MarketIndexData> dataList) {
    final results = <CompressedIndexData>[];

    try {
      // 尝试批量压缩优化
      if (dataList.length > _config.batchCompressionThreshold) {
        final batchCompressed = _compressBatchOptimized(dataList);
        results.addAll(batchCompressed);
      } else {
        // 小批量逐个压缩
        for (final data in dataList) {
          final compressed = compressIndexData(data);
          results.add(compressed);
        }
      }

      AppLogger.debug('Batch compressed ${dataList.length} index data items');
    } catch (e) {
      AppLogger.error(
          'Batch compression failed, falling back to individual compression: $e',
          e);

      // 降级到逐个压缩
      for (final data in dataList) {
        try {
          final compressed = compressIndexData(data);
          results.add(compressed);
        } catch (e) {
          AppLogger.error(
              'Failed to compress individual item ${data.code}: $e', e);
        }
      }
    }

    return results;
  }

  /// 解压缩指数数据
  MarketIndexData decompressIndexData(CompressedIndexData compressedData) {
    try {
      final stopwatch = Stopwatch()..start();

      // 1. 解压缩算法
      final decompressedBinary =
          _decompressAlgorithm(compressedData.compressedData);

      // 2. 反序列化
      final stringData = _deserializeFromBinary(decompressedBinary);

      // 3. 解压缩字符串
      final stringDecompressed = _decompressStringFields(stringData);

      // 4. 恢复数值精度
      final precisionRestored = _restoreNumericPrecision(stringDecompressed);

      // 5. 恢复冗余字段
      final fullData = _restoreRedundantFields(precisionRestored);

      stopwatch.stop();

      // 更新统计信息
      _statistics.recordDecompression(
          compressedData.compressedSize, stopwatch.elapsed);

      AppLogger.debug(
          'Decompressed index data for ${compressedData.indexCode}');

      return fullData;
    } catch (e) {
      AppLogger.error(
          'Failed to decompress index data for ${compressedData.indexCode}: $e',
          e);
      _statistics.recordError();
      rethrow;
    }
  }

  /// 批量解压缩指数数据
  List<MarketIndexData> decompressBatch(
      List<CompressedIndexData> compressedList) {
    final results = <MarketIndexData>[];

    for (final compressed in compressedList) {
      try {
        final data = decompressIndexData(compressed);
        results.add(data);
      } catch (e) {
        AppLogger.error('Failed to decompress item ${compressed.indexCode}', e);
      }
    }

    return results;
  }

  /// 移除冗余字段
  MarketIndexData _removeRedundantFields(MarketIndexData data) {
    // 计算字段可以由其他字段推导，可以移除
    // changeAmount = currentValue - previousClose
    // changePercentage = (changeAmount / previousClose) * 100

    return MarketIndexData(
      code: data.code,
      name: data.name,
      currentValue: data.currentValue,
      previousClose: data.previousClose,
      openPrice: data.openPrice,
      highPrice: data.highPrice,
      lowPrice: data.lowPrice,
      changeAmount: Decimal.zero, // 移除，稍后重新计算
      changePercentage: Decimal.zero, // 移除，稍后重新计算
      volume: data.volume,
      turnover: data.turnover,
      updateTime: data.updateTime,
      marketStatus: data.marketStatus,
      qualityLevel: data.qualityLevel,
      dataSource: data.dataSource,
    );
  }

  /// 优化数值精度
  MarketIndexData _optimizeNumericPrecision(MarketIndexData data) {
    // 根据配置减少小数位数以节省空间
    return MarketIndexData(
      code: data.code,
      name: data.name,
      currentValue: _roundDecimal(data.currentValue, _config.pricePrecision),
      previousClose: _roundDecimal(data.previousClose, _config.pricePrecision),
      openPrice: _roundDecimal(data.openPrice, _config.pricePrecision),
      highPrice: _roundDecimal(data.highPrice, _config.pricePrecision),
      lowPrice: _roundDecimal(data.lowPrice, _config.pricePrecision),
      changeAmount: data.changeAmount,
      changePercentage: data.changePercentage,
      volume: data.volume,
      turnover: _roundDecimal(data.turnover, _config.turnoverPrecision),
      updateTime: data.updateTime,
      marketStatus: data.marketStatus,
      qualityLevel: data.qualityLevel,
      dataSource: data.dataSource,
    );
  }

  /// 保留指定小数位数
  Decimal _roundDecimal(Decimal value, int precision) {
    if (precision <= 0) return Decimal.parse(value.truncate().toString());

    Decimal factor = Decimal.one;
    for (int i = 0; i < precision; i++) {
      factor *= Decimal.fromInt(10);
    }
    return Decimal.parse(((value * factor).round() / factor).toString());
  }

  /// 压缩字符串字段
  MarketIndexData _compressStringFields(MarketIndexData data) {
    return MarketIndexData(
      code: data.code, // 指数代码通常很短，不压缩
      name: _compressString(data.name),
      currentValue: data.currentValue,
      previousClose: data.previousClose,
      openPrice: data.openPrice,
      highPrice: data.highPrice,
      lowPrice: data.lowPrice,
      changeAmount: data.changeAmount,
      changePercentage: data.changePercentage,
      volume: data.volume,
      turnover: data.turnover,
      updateTime: data.updateTime,
      marketStatus: data.marketStatus,
      qualityLevel: data.qualityLevel,
      dataSource: _compressString(data.dataSource),
    );
  }

  /// 压缩字符串
  String _compressString(String input) {
    if (input.length < _config.stringCompressionThreshold) {
      return input;
    }

    try {
      // 简单的字符串压缩：使用Gzip
      final bytes = utf8.encode(input);
      final compressed = gzip.encode(bytes);
      return base64.encode(compressed);
    } catch (e) {
      AppLogger.warn('String compression failed: $e');
      return input; // 降级到原始字符串
    }
  }

  /// 序列化为二进制
  List<int> _serializeToBinary(MarketIndexData data) {
    // 自定义二进制序列化格式
    final buffer = <int>[];

    // 版本标识
    buffer.addAll(_encodeInt16(1));

    // 字符串字段
    buffer.addAll(_encodeString(data.code));
    buffer.addAll(_encodeString(data.name));
    buffer.addAll(_encodeString(data.dataSource));

    // 数值字段 (转换为整数以节省空间)
    buffer.addAll(_encodeInt64(int.parse(
        (data.currentValue * Decimal.fromInt(100000)).truncate().toString())));
    buffer.addAll(_encodeInt64(int.parse(
        (data.previousClose * Decimal.fromInt(100000)).truncate().toString())));
    buffer.addAll(_encodeInt64(int.parse(
        (data.openPrice * Decimal.fromInt(100000)).truncate().toString())));
    buffer.addAll(_encodeInt64(int.parse(
        (data.highPrice * Decimal.fromInt(100000)).truncate().toString())));
    buffer.addAll(_encodeInt64(int.parse(
        (data.lowPrice * Decimal.fromInt(100000)).truncate().toString())));
    buffer.addAll(_encodeInt64(data.volume));
    buffer.addAll(_encodeInt64(int.parse(
        (data.turnover * Decimal.fromInt(100)).truncate().toString())));

    // 枚举字段
    buffer.add(data.marketStatus.index);
    buffer.add(data.qualityLevel.index);

    // 时间戳
    buffer.addAll(_encodeInt64(data.updateTime.millisecondsSinceEpoch));

    return buffer;
  }

  /// 从二进制反序列化
  MarketIndexData _deserializeFromBinary(List<int> binaryData) {
    int offset = 0;

    // 版本检查
    final version = _decodeInt16(binaryData, offset);
    offset += 2;

    if (version != 1) {
      throw UnsupportedError('Unsupported binary format version: $version');
    }

    // 字符串字段
    final code = _decodeString(binaryData, offset);
    offset += 4 + code.length;

    final name = _decodeString(binaryData, offset);
    offset += 4 + name.length;

    final dataSource = _decodeString(binaryData, offset);
    offset += 4 + dataSource.length;

    // 数值字段
    final currentValue = Decimal.fromInt(_decodeInt64(binaryData, offset)) /
        Decimal.fromInt(100000);
    offset += 8;

    final previousClose = Decimal.fromInt(_decodeInt64(binaryData, offset)) /
        Decimal.fromInt(100000);
    offset += 8;

    final openPrice = Decimal.fromInt(_decodeInt64(binaryData, offset)) /
        Decimal.fromInt(100000);
    offset += 8;

    final highPrice = Decimal.fromInt(_decodeInt64(binaryData, offset)) /
        Decimal.fromInt(100000);
    offset += 8;

    final lowPrice = Decimal.fromInt(_decodeInt64(binaryData, offset)) /
        Decimal.fromInt(100000);
    offset += 8;

    final volume = _decodeInt64(binaryData, offset);
    offset += 8;

    final turnover = Decimal.fromInt(_decodeInt64(binaryData, offset)) /
        Decimal.fromInt(100);
    offset += 8;

    // 枚举字段
    final marketStatusIndex = binaryData[offset++];
    final qualityLevelIndex = binaryData[offset++];

    final marketStatus = MarketStatus.values[marketStatusIndex];
    final qualityLevel = DataQualityLevel.values[qualityLevelIndex];

    // 时间戳
    final updateTime =
        DateTime.fromMillisecondsSinceEpoch(_decodeInt64(binaryData, offset));

    return MarketIndexData(
      code: code,
      name: name,
      currentValue: currentValue as Decimal,
      previousClose: previousClose as Decimal,
      openPrice: openPrice as Decimal,
      highPrice: highPrice as Decimal,
      lowPrice: lowPrice as Decimal,
      changeAmount: Decimal.zero, // 稍后重新计算
      changePercentage: Decimal.zero, // 稍后重新计算
      volume: volume,
      turnover: turnover as Decimal,
      updateTime: updateTime,
      marketStatus: marketStatus,
      qualityLevel: qualityLevel,
      dataSource: dataSource,
    );
  }

  /// 应用压缩算法
  List<int> _applyCompression(List<int> data) {
    switch (_config.algorithm) {
      case CompressionAlgorithm.gzip:
        return _applyGzipCompression(data);
      case CompressionAlgorithm.lz4:
        return _applyLZ4Compression(data);
      case CompressionAlgorithm.none:
        return data;
    }
  }

  /// 应用Gzip压缩
  List<int> _applyGzipCompression(List<int> data) {
    try {
      final bytes = Uint8List.fromList(data);
      final compressed = gzip.encode(bytes);
      return compressed;
    } catch (e) {
      AppLogger.warn('Gzip compression failed: $e');
      return data; // 降级到不压缩
    }
  }

  /// 应用LZ4压缩 (模拟实现)
  List<int> _applyLZ4Compression(List<int> data) {
    // 实际应用中应该使用lz4_dart包
    // 这里暂时使用Gzip作为替代
    return _applyGzipCompression(data);
  }

  /// 解压缩算法
  List<int> _decompressAlgorithm(List<int> compressedData) {
    switch (_config.algorithm) {
      case CompressionAlgorithm.gzip:
        return _decompressGzip(compressedData);
      case CompressionAlgorithm.lz4:
        return _decompressLZ4(compressedData);
      case CompressionAlgorithm.none:
        return compressedData;
    }
  }

  /// Gzip解压缩
  List<int> _decompressGzip(List<int> compressedData) {
    try {
      final bytes = Uint8List.fromList(compressedData);
      final decompressed = gzip.decode(bytes);
      return decompressed;
    } catch (e) {
      AppLogger.warn('Gzip decompression failed: $e');
      return compressedData; // 降级到原始数据
    }
  }

  /// LZ4解压缩 (模拟实现)
  List<int> _decompressLZ4(List<int> compressedData) {
    // 实际应用中应该使用lz4_dart包
    return _decompressGzip(compressedData);
  }

  /// 解压缩字符串字段
  MarketIndexData _decompressStringFields(MarketIndexData data) {
    return MarketIndexData(
      code: data.code,
      name: _decompressString(data.name),
      currentValue: data.currentValue,
      previousClose: data.previousClose,
      openPrice: data.openPrice,
      highPrice: data.highPrice,
      lowPrice: data.lowPrice,
      changeAmount: data.changeAmount,
      changePercentage: data.changePercentage,
      volume: data.volume,
      turnover: data.turnover,
      updateTime: data.updateTime,
      marketStatus: data.marketStatus,
      qualityLevel: data.qualityLevel,
      dataSource: _decompressString(data.dataSource),
    );
  }

  /// 解压缩字符串
  String _decompressString(String input) {
    try {
      final compressed = base64.decode(input);
      final decompressed = gzip.decode(compressed);
      return utf8.decode(decompressed);
    } catch (e) {
      // 如果解压缩失败，假设原始字符串未被压缩
      return input;
    }
  }

  /// 恢复数值精度
  MarketIndexData _restoreNumericPrecision(MarketIndexData data) {
    // 在这个优化场景中，我们实际上不需要恢复精度
    // 因为精度优化是合理的损失，不是临时的
    return data;
  }

  /// 恢复冗余字段
  MarketIndexData _restoreRedundantFields(MarketIndexData data) {
    // 重新计算变化字段
    final changeAmount = data.currentValue - data.previousClose;
    final changePercentage = data.previousClose != Decimal.zero
        ? Decimal.parse(
            (changeAmount * Decimal.fromInt(100) / data.previousClose)
                .toString())
        : Decimal.zero;

    return MarketIndexData(
      code: data.code,
      name: data.name,
      currentValue: data.currentValue,
      previousClose: data.previousClose,
      openPrice: data.openPrice,
      highPrice: data.highPrice,
      lowPrice: data.lowPrice,
      changeAmount: changeAmount,
      changePercentage: changePercentage,
      volume: data.volume,
      turnover: data.turnover,
      updateTime: data.updateTime,
      marketStatus: data.marketStatus,
      qualityLevel: data.qualityLevel,
      dataSource: data.dataSource,
    );
  }

  /// 批量压缩优化
  List<CompressedIndexData> _compressBatchOptimized(
      List<MarketIndexData> dataList) {
    // 批量压缩可以识别重复的字符串和模式
    final results = <CompressedIndexData>[];

    // 1. 分析数据中的重复模式
    final repeatedStrings = _findRepeatedStrings(dataList);

    // 2. 创建字典压缩
    final stringDictionary = _createStringDictionary(repeatedStrings);

    // 3. 使用字典压缩每个数据项
    for (final data in dataList) {
      final compressed = _compressWithDictionary(data, stringDictionary);
      results.add(compressed);
    }

    return results;
  }

  /// 查找重复字符串
  Map<String, int> _findRepeatedStrings(List<MarketIndexData> dataList) {
    final stringCounts = <String, int>{};

    for (final data in dataList) {
      // 统计各种字符串字段的出现频率
      _countString(stringCounts, data.name);
      _countString(stringCounts, data.dataSource);
    }

    // 返回出现频率大于1的字符串
    return Map.fromEntries(
      stringCounts.entries.where((entry) => entry.value > 1),
    );
  }

  /// 统计字符串
  void _countString(Map<String, int> counts, String str) {
    if (str.length >= _config.stringCompressionThreshold) {
      counts[str] = (counts[str] ?? 0) + 1;
    }
  }

  /// 创建字符串字典
  Map<String, int> _createStringDictionary(Map<String, int> repeatedStrings) {
    final dictionary = <String, int>{};
    int index = 0;

    // 按频率排序，高频字符串使用较短的索引
    final sortedStrings = repeatedStrings.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedStrings) {
      dictionary[entry.key] = index++;
    }

    return dictionary;
  }

  /// 使用字典压缩
  CompressedIndexData _compressWithDictionary(
      MarketIndexData data, Map<String, int> dictionary) {
    // 简化实现：在实际应用中这里应该使用字典来替换字符串
    // 目前先使用标准压缩
    return compressIndexData(data);
  }

  /// 计算原始数据大小
  int _calculateOriginalSize(MarketIndexData data) {
    // 估算原始JSON序列化后的大小
    final json = data.toJson();
    return utf8.encode(json.toString()).length;
  }

  /// 编码工具方法
  List<int> _encodeInt16(int value) {
    return [(value >> 8) & 0xFF, value & 0xFF];
  }

  List<int> _encodeInt64(int value) {
    return [
      (value >> 56) & 0xFF,
      (value >> 48) & 0xFF,
      (value >> 40) & 0xFF,
      (value >> 32) & 0xFF,
      (value >> 24) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 8) & 0xFF,
      value & 0xFF,
    ];
  }

  List<int> _encodeString(String str) {
    final bytes = utf8.encode(str);
    final lengthBytes = _encodeInt32(bytes.length);
    return [...lengthBytes, ...bytes];
  }

  List<int> _encodeInt32(int value) {
    return [
      (value >> 24) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 8) & 0xFF,
      value & 0xFF
    ];
  }

  /// 解码工具方法
  int _decodeInt16(List<int> data, int offset) {
    return (data[offset] << 8) | data[offset + 1];
  }

  int _decodeInt32(List<int> data, int offset) {
    return (data[offset] << 24) |
        (data[offset + 1] << 16) |
        (data[offset + 2] << 8) |
        data[offset + 3];
  }

  int _decodeInt64(List<int> data, int offset) {
    return (data[offset] << 56) |
        (data[offset + 1] << 48) |
        (data[offset + 2] << 40) |
        (data[offset + 3] << 32) |
        (data[offset + 4] << 24) |
        (data[offset + 5] << 16) |
        (data[offset + 6] << 8) |
        data[offset + 7];
  }

  String _decodeString(List<int> data, int offset) {
    final length = _decodeInt32(data, offset);
    final bytes = data.sublist(offset + 4, offset + 4 + length);
    return utf8.decode(bytes);
  }

  /// 获取压缩统计信息
  CompressionStatistics getStatistics() {
    return _statistics;
  }

  /// 重置统计信息
  void resetStatistics() {
    _statistics = CompressionStatistics();
  }
}

/// 压缩后的指数数据
class CompressedIndexData {
  final String indexCode;
  final List<int> compressedData;
  final int originalSize;
  final int compressedSize;
  final CompressionAlgorithm compressionAlgorithm;
  final DateTime timestamp;

  const CompressedIndexData({
    required this.indexCode,
    required this.compressedData,
    required this.originalSize,
    required this.compressedSize,
    required this.compressionAlgorithm,
    required this.timestamp,
  });

  /// 压缩比
  double get compressionRatio => originalSize / compressedSize;

  /// 压缩率
  double get compressionRate => (1 - compressedSize / originalSize) * 100;

  /// 转换为字节
  Uint8List toBytes() {
    return Uint8List.fromList(compressedData);
  }

  @override
  String toString() {
    return 'CompressedIndexData(index: $indexCode, ratio: ${compressionRatio.toStringAsFixed(2)}x, rate: ${compressionRate.toStringAsFixed(1)}%)';
  }
}

/// 压缩配置
class CompressionConfig {
  /// 压缩算法
  final CompressionAlgorithm algorithm;

  /// 价格精度 (小数位数)
  final int pricePrecision;

  /// 成交额精度 (小数位数)
  final int turnoverPrecision;

  /// 字符串压缩阈值
  final int stringCompressionThreshold;

  /// 批量压缩阈值
  final int batchCompressionThreshold;

  const CompressionConfig({
    this.algorithm = CompressionAlgorithm.gzip,
    this.pricePrecision = 2,
    this.turnoverPrecision = 0,
    this.stringCompressionThreshold = 10,
    this.batchCompressionThreshold = 10,
  });
}

/// 压缩算法
enum CompressionAlgorithm {
  none,
  gzip,
  lz4;

  String get name {
    switch (this) {
      case CompressionAlgorithm.none:
        return 'none';
      case CompressionAlgorithm.gzip:
        return 'gzip';
      case CompressionAlgorithm.lz4:
        return 'lz4';
    }
  }
}

/// 压缩统计信息
class CompressionStatistics {
  int totalCompressions = 0;
  int totalDecompressions = 0;
  int totalErrors = 0;
  int totalOriginalSize = 0;
  int totalCompressedSize = 0;
  Duration totalCompressionTime = Duration.zero;
  Duration totalDecompressionTime = Duration.zero;

  /// 记录压缩操作
  void recordCompression({
    required int originalSize,
    required int compressedSize,
    required Duration compressionTime,
  }) {
    totalCompressions++;
    totalOriginalSize += originalSize;
    totalCompressedSize += compressedSize;
    totalCompressionTime += compressionTime;
  }

  /// 记录解压缩操作
  void recordDecompression(int compressedSize, Duration decompressionTime) {
    totalDecompressions++;
    totalCompressedSize += compressedSize;
    totalDecompressionTime += decompressionTime;
  }

  /// 记录错误
  void recordError() {
    totalErrors++;
  }

  /// 平均压缩比
  double get averageCompressionRatio {
    return totalCompressedSize > 0
        ? totalOriginalSize / totalCompressedSize
        : 0.0;
  }

  /// 平均压缩率
  double get averageCompressionRate {
    return totalOriginalSize > 0
        ? (1 - totalCompressedSize / totalOriginalSize) * 100
        : 0.0;
  }

  /// 平均压缩时间
  Duration get averageCompressionTime {
    return totalCompressions > 0
        ? Duration(
            milliseconds:
                totalCompressionTime.inMilliseconds ~/ totalCompressions)
        : Duration.zero;
  }

  /// 平均解压缩时间
  Duration get averageDecompressionTime {
    return totalDecompressions > 0
        ? Duration(
            milliseconds:
                totalDecompressionTime.inMilliseconds ~/ totalDecompressions)
        : Duration.zero;
  }

  /// 错误率
  double get errorRate {
    final totalOperations = totalCompressions + totalDecompressions;
    return totalOperations > 0 ? totalErrors / totalOperations : 0.0;
  }

  @override
  String toString() {
    return 'CompressionStatistics(compressions: $totalCompressions, ratio: ${averageCompressionRatio.toStringAsFixed(2)}x, errorRate: ${(errorRate * 100).toStringAsFixed(1)}%)';
  }
}
