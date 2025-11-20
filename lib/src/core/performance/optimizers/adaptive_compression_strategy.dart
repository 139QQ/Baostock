// ignore_for_file: directives_ordering, public_member_api_docs, sort_constructors_first, prefer_const_constructors

import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';

import '../../utils/logger.dart';

/// 压缩算法类型
enum CompressionAlgorithm {
  none, // 不压缩
  gzip, // gzip压缩
  brotli, // Brotli压缩（比gzip高15-25%）
  lz4, // LZ4压缩（速度优先）
  zstd, // Zstandard压缩（平衡压缩率和速度）
  deflate, // Deflate压缩
}

/// 数据特征分析结果
class DataCharacteristics {
  final int sizeBytes;
  final double entropy; // 熵值（0-1，越高越难压缩）
  final double repetitionRatio; // 重复率（0-1，越高越容易压缩）
  final bool isText; // 是否为文本数据
  final bool isJson; // 是否为JSON数据
  final bool isNumerical; // 是否为数值数据
  final bool isStructured; // 是否为结构化数据
  final String contentType; // 内容类型

  DataCharacteristics({
    required this.sizeBytes,
    required this.entropy,
    required this.repetitionRatio,
    required this.isText,
    required this.isJson,
    required this.isNumerical,
    required this.isStructured,
    required this.contentType,
  });

  /// 分析数据特征
  factory DataCharacteristics.analyze(dynamic data) {
    if (data == null) {
      return DataCharacteristics(
        sizeBytes: 0,
        entropy: 0.0,
        repetitionRatio: 0.0,
        isText: false,
        isJson: false,
        isNumerical: false,
        isStructured: false,
        contentType: 'unknown',
      );
    }

    final bytes = _convertToBytes(data);
    final sizeBytes = bytes.length;

    if (sizeBytes == 0) {
      return DataCharacteristics(
        sizeBytes: 0,
        entropy: 0.0,
        repetitionRatio: 0.0,
        isText: false,
        isJson: false,
        isNumerical: false,
        isStructured: false,
        contentType: 'unknown',
      );
    }

    final entropy = _calculateEntropy(bytes);
    final repetitionRatio = _calculateRepetitionRatio(bytes);
    final isText = _isTextData(bytes);
    final isJson = isText && _isJsonData(bytes);
    final isNumerical = _isNumericalData(bytes);
    final isStructured = isJson || _isStructuredData(bytes);
    final contentType = _detectContentType(bytes, isText, isJson);

    return DataCharacteristics(
      sizeBytes: sizeBytes,
      entropy: entropy,
      repetitionRatio: repetitionRatio,
      isText: isText,
      isJson: isJson,
      isNumerical: isNumerical,
      isStructured: isStructured,
      contentType: contentType,
    );
  }

  /// 将数据转换为字节
  static Uint8List _convertToBytes(dynamic data) {
    if (data is Uint8List) {
      return data;
    } else if (data is String) {
      return Uint8List.fromList(utf8.encode(data));
    } else if (data is List<int>) {
      return Uint8List.fromList(data);
    } else {
      // 尝试JSON序列化
      try {
        final jsonString = json.encode(data);
        return Uint8List.fromList(utf8.encode(jsonString));
      } catch (e) {
        return Uint8List.fromList([]);
      }
    }
  }

  /// 计算数据熵值
  static double _calculateEntropy(Uint8List bytes) {
    if (bytes.isEmpty) return 0.0;

    final frequency = <int, int>{};
    for (final byte in bytes) {
      frequency[byte] = (frequency[byte] ?? 0) + 1;
    }

    double entropy = 0.0;
    final length = bytes.length;

    for (final count in frequency.values) {
      if (count > 0) {
        final probability = count / length;
        entropy -= probability * math.log(probability) / math.ln2;
      }
    }

    return entropy / 8.0; // 归一化到0-1
  }

  /// 计算重复率
  static double _calculateRepetitionRatio(Uint8List bytes) {
    if (bytes.length < 2) return 0.0;

    int repetitions = 0;
    final seen = <int, bool>{};

    for (int i = 1; i < bytes.length; i++) {
      if (bytes[i] == bytes[i - 1]) {
        repetitions++;
      }
      seen[bytes[i]] = true;
    }

    // 同时考虑连续重复和整体重复
    final uniqueBytes = seen.length;
    final totalBytes = bytes.length;
    final uniqueRatio = uniqueBytes / totalBytes;

    return (repetitions / (totalBytes - 1)) * 0.5 + (1 - uniqueRatio) * 0.5;
  }

  /// 判断是否为文本数据
  static bool _isTextData(Uint8List bytes) {
    if (bytes.isEmpty) return false;

    int printableChars = 0;
    final maxSample = math.min(1000, bytes.length);

    for (int i = 0; i < maxSample; i++) {
      final byte = bytes[i];
      if ((byte >= 32 && byte <= 126) ||
          byte == 9 ||
          byte == 10 ||
          byte == 13) {
        printableChars++;
      }
    }

    return (printableChars / maxSample) > 0.8;
  }

  /// 判断是否为JSON数据
  static bool _isJsonData(Uint8List bytes) {
    try {
      final jsonString = String.fromCharCodes(bytes);
      final decoded = json.decode(jsonString);
      return decoded != null;
    } catch (e) {
      return false;
    }
  }

  /// 判断是否为数值数据
  static bool _isNumericalData(Uint8List bytes) {
    try {
      final string = String.fromCharCodes(bytes);
      return double.tryParse(string) != null || int.tryParse(string) != null;
    } catch (e) {
      return false;
    }
  }

  /// 判断是否为结构化数据
  static bool _isStructuredData(Uint8List bytes) {
    try {
      final string = String.fromCharCodes(bytes);
      // 简单检查是否包含结构化标记
      return string.contains('{') && string.contains('}') ||
          string.contains('[') && string.contains(']');
    } catch (e) {
      return false;
    }
  }

  /// 检测内容类型
  static String _detectContentType(Uint8List bytes, bool isText, bool isJson) {
    if (isJson) return 'application/json';
    if (!isText) return 'application/octet-stream';

    try {
      final string = String.fromCharCodes(bytes).toLowerCase();

      if (string.contains('<html')) return 'text/html';
      if (string.contains('<xml')) return 'application/xml';
      if (string.contains('image/')) return 'image/*';
      if (string.contains('text/')) return 'text/plain';

      return 'text/plain';
    } catch (e) {
      return 'unknown';
    }
  }
}

/// 压缩结果
class CompressionResult {
  final CompressionAlgorithm algorithm;
  final Uint8List compressedData;
  final int originalSize;
  final int compressedSize;
  final int compressionTimeMs;
  final double compressionRatio;

  CompressionResult({
    required this.algorithm,
    required this.compressedData,
    required this.originalSize,
    required this.compressedSize,
    required this.compressionTimeMs,
  }) : compressionRatio =
            originalSize > 0 ? compressedSize / originalSize : 1.0;

  /// 压缩率（百分比）
  double get compressionPercent => (1 - compressionRatio) * 100;
}

/// 自适应压缩策略配置
class AdaptiveCompressionConfig {
  /// 小数据阈值（字节）
  final int smallDataThreshold;

  /// 大数据阈值（字节）
  final int largeDataThreshold;

  /// 压缩算法选择权重
  final Map<CompressionAlgorithm, double> algorithmWeights;

  /// 是否启用性能基准测试
  final bool enableBenchmarking;

  /// 压缩超时时间
  final Duration compressionTimeout;

  const AdaptiveCompressionConfig({
    this.smallDataThreshold = 1024, // 1KB
    this.largeDataThreshold = 1024 * 1024, // 1MB
    this.algorithmWeights = const {
      CompressionAlgorithm.gzip: 0.3,
      CompressionAlgorithm.brotli: 0.3,
      CompressionAlgorithm.lz4: 0.2,
      CompressionAlgorithm.zstd: 0.2,
    },
    this.enableBenchmarking = true,
    this.compressionTimeout = const Duration(seconds: 5),
  });
}

/// 自适应压缩策略
///
/// 根据数据特征选择最佳压缩算法
class AdaptiveCompressionStrategy {
  final AdaptiveCompressionConfig _config;

  // 压缩性能基准数据
  final Map<String, Map<CompressionAlgorithm, double>> _performanceCache = {};

  AdaptiveCompressionStrategy({AdaptiveCompressionConfig? config})
      : _config = config ?? AdaptiveCompressionConfig();

  /// 压缩数据
  Future<CompressionResult> compress(dynamic data) async {
    final stopwatch = Stopwatch()..start();

    try {
      // 分析数据特征
      final characteristics = DataCharacteristics.analyze(data);
      AppLogger.debug('数据特征分析完成',
          '大小: ${characteristics.sizeBytes}B, 熵: ${characteristics.entropy.toStringAsFixed(3)}');

      // 选择压缩算法
      final algorithm = await _selectAlgorithm(characteristics);
      AppLogger.debug('选择压缩算法', algorithm.toString());

      // 执行压缩
      final bytes = DataCharacteristics._convertToBytes(data);
      final compressedBytes = await _compressWithAlgorithm(bytes, algorithm);
      stopwatch.stop();

      final result = CompressionResult(
        algorithm: algorithm,
        compressedData: compressedBytes,
        originalSize: bytes.length,
        compressedSize: compressedBytes.length,
        compressionTimeMs: stopwatch.elapsedMilliseconds,
      );

      // 更新性能基准
      if (_config.enableBenchmarking) {
        _updatePerformanceCache(characteristics, algorithm, result);
      }

      AppLogger.business('数据压缩完成',
          '算法: ${algorithm.toString()}, 压缩率: ${result.compressionPercent.toStringAsFixed(1)}%');

      return result;
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('数据压缩失败', e);

      // 降级到不压缩
      final bytes = DataCharacteristics._convertToBytes(data);
      return CompressionResult(
        algorithm: CompressionAlgorithm.none,
        compressedData: bytes,
        originalSize: bytes.length,
        compressedSize: bytes.length,
        compressionTimeMs: stopwatch.elapsedMilliseconds,
      );
    }
  }

  /// 选择最佳压缩算法
  Future<CompressionAlgorithm> _selectAlgorithm(
      DataCharacteristics characteristics) async {
    // 如果数据太小，不压缩
    if (characteristics.sizeBytes < _config.smallDataThreshold) {
      return CompressionAlgorithm.none;
    }

    // 如果数据压缩效果不好，不压缩
    if (characteristics.entropy > 0.95) {
      return CompressionAlgorithm.none;
    }

    // 基于数据特征和历史性能选择算法
    final candidates = _getCandidateAlgorithms(characteristics);

    if (_config.enableBenchmarking) {
      return await _benchmarkAlgorithms(characteristics, candidates);
    } else {
      return _selectByHeuristics(characteristics, candidates);
    }
  }

  /// 获取候选算法
  List<CompressionAlgorithm> _getCandidateAlgorithms(
      DataCharacteristics characteristics) {
    final candidates = <CompressionAlgorithm>[];

    // 基于数据大小选择
    if (characteristics.sizeBytes < _config.largeDataThreshold) {
      // 小数据：优先考虑速度
      candidates.addAll([
        CompressionAlgorithm.lz4,
        CompressionAlgorithm.gzip,
        CompressionAlgorithm.brotli,
      ]);
    } else {
      // 大数据：优先考虑压缩率
      candidates.addAll([
        CompressionAlgorithm.zstd,
        CompressionAlgorithm.brotli,
        CompressionAlgorithm.gzip,
      ]);
    }

    // 基于数据类型选择
    if (characteristics.isText) {
      // 文本数据：所有算法都适用
      candidates.add(CompressionAlgorithm.deflate);
    } else if (characteristics.isNumerical) {
      // 数值数据：二进制算法效果更好
      candidates.retainWhere((algo) =>
          algo == CompressionAlgorithm.gzip ||
          algo == CompressionAlgorithm.zstd);
    }

    // 基于重复率选择
    if (characteristics.repetitionRatio > 0.5) {
      // 高重复率：强压缩算法
      candidates.insert(0, CompressionAlgorithm.zstd);
      candidates.insert(1, CompressionAlgorithm.brotli);
    }

    return candidates.toSet().toList();
  }

  /// 通过启发式规则选择算法
  CompressionAlgorithm _selectByHeuristics(
    DataCharacteristics characteristics,
    List<CompressionAlgorithm> candidates,
  ) {
    if (candidates.isEmpty) {
      return CompressionAlgorithm.gzip; // 默认选择
    }

    // 基于配置权重排序
    candidates.sort((a, b) {
      final weightA = _config.algorithmWeights[a] ?? 0.0;
      final weightB = _config.algorithmWeights[b] ?? 0.0;
      return weightB.compareTo(weightA);
    });

    return candidates.first;
  }

  /// 性能基准测试
  Future<CompressionAlgorithm> _benchmarkAlgorithms(
    DataCharacteristics characteristics,
    List<CompressionAlgorithm> candidates,
  ) async {
    if (candidates.isEmpty) {
      return CompressionAlgorithm.gzip;
    }

    final testSize = math.min(1024, characteristics.sizeBytes);
    final testBytes = Uint8List.fromList(
        DataCharacteristics._convertToBytes(null).take(testSize).toList());

    AlgorithmResult? bestResult;

    for (final algorithm in candidates) {
      try {
        final result = await _benchmarkSingleAlgorithm(testBytes, algorithm);
        if (bestResult == null || _isBetterResult(result, bestResult)) {
          bestResult = result;
        }
      } catch (e) {
        AppLogger.debug('算法基准测试失败', '${algorithm.toString()}: $e');
      }
    }

    return bestResult?.algorithm ?? CompressionAlgorithm.gzip;
  }

  /// 单个算法基准测试
  Future<AlgorithmResult> _benchmarkSingleAlgorithm(
    Uint8List testData,
    CompressionAlgorithm algorithm,
  ) async {
    final stopwatch = Stopwatch()..start();

    final compressedBytes = await _compressWithAlgorithm(testData, algorithm);
    stopwatch.stop();

    final compressionRatio = compressedBytes.length / testData.length;
    final speed = testData.length / stopwatch.elapsedMicroseconds; // bytes/ms

    return AlgorithmResult(
      algorithm: algorithm,
      compressionRatio: compressionRatio,
      speed: speed,
      timeMs: stopwatch.elapsedMilliseconds,
    );
  }

  /// 判断哪个结果更好
  bool _isBetterResult(AlgorithmResult a, AlgorithmResult b) {
    // 综合考虑压缩率和速度
    final scoreA = a.compressionRatio * 0.7 + (1.0 / a.speed) * 0.3;
    final scoreB = b.compressionRatio * 0.7 + (1.0 / b.speed) * 0.3;

    return scoreA < scoreB; // 分数越低越好（压缩率低，速度高）
  }

  /// 使用指定算法压缩数据
  Future<Uint8List> _compressWithAlgorithm(
    Uint8List bytes,
    CompressionAlgorithm algorithm,
  ) async {
    switch (algorithm) {
      case CompressionAlgorithm.none:
        return bytes;

      case CompressionAlgorithm.gzip:
        return await _compressGzip(bytes);

      case CompressionAlgorithm.brotli:
        return await _compressBrotli(bytes);

      case CompressionAlgorithm.lz4:
        return await _compressLZ4(bytes);

      case CompressionAlgorithm.zstd:
        return await _compressZstd(bytes);

      case CompressionAlgorithm.deflate:
        return await _compressDeflate(bytes);
    }
  }

  /// Gzip压缩实现（简化版）
  Future<Uint8List> _compressGzip(Uint8List bytes) async {
    // 在实际应用中，应该使用dart:convert的GZipCodec
    // 这里提供一个简化的实现框架
    try {
      return Uint8List.fromList(bytes); // 临时实现
    } catch (e) {
      throw Exception('Gzip compression failed: $e');
    }
  }

  /// Brotli压缩实现
  Future<Uint8List> _compressBrotli(Uint8List bytes) async {
    // Brotli压缩实现
    try {
      return Uint8List.fromList(bytes); // 临时实现
    } catch (e) {
      throw Exception('Brotli compression failed: $e');
    }
  }

  /// LZ4压缩实现
  Future<Uint8List> _compressLZ4(Uint8List bytes) async {
    // LZ4压缩实现
    try {
      return Uint8List.fromList(bytes); // 临时实现
    } catch (e) {
      throw Exception('LZ4 compression failed: $e');
    }
  }

  /// Zstandard压缩实现
  Future<Uint8List> _compressZstd(Uint8List bytes) async {
    // Zstandard压缩实现
    try {
      return Uint8List.fromList(bytes); // 临时实现
    } catch (e) {
      throw Exception('Zstandard compression failed: $e');
    }
  }

  /// Deflate压缩实现
  Future<Uint8List> _compressDeflate(Uint8List bytes) async {
    // Deflate压缩实现
    try {
      return Uint8List.fromList(bytes); // 临时实现
    } catch (e) {
      throw Exception('Deflate compression failed: $e');
    }
  }

  /// 更新性能基准缓存
  void _updatePerformanceCache(
    DataCharacteristics characteristics,
    CompressionAlgorithm algorithm,
    CompressionResult result,
  ) {
    final key = _generateCacheKey(characteristics);

    if (!_performanceCache.containsKey(key)) {
      _performanceCache[key] = {};
    }

    // 更新平均性能
    final existingData = _performanceCache[key]![algorithm] ?? 1.0;
    final newData = result.compressionRatio;
    _performanceCache[key]![algorithm] = (existingData * 0.8 + newData * 0.2);
  }

  /// 生成缓存键
  String _generateCacheKey(DataCharacteristics characteristics) {
    return '${characteristics.contentType}_${characteristics.sizeBytes ~/ 1024}KB_'
        '${characteristics.entropy.toStringAsFixed(2)}_${characteristics.repetitionRatio.toStringAsFixed(2)}';
  }

  /// 获取压缩统计信息
  Map<String, dynamic> getCompressionStats() {
    return {
      'algorithmWeights': _config.algorithmWeights,
      'performanceCacheSize': _performanceCache.length,
      'algorithms':
          CompressionAlgorithm.values.map((algo) => algo.toString()).toList(),
    };
  }
}

/// 算法基准测试结果
class AlgorithmResult {
  final CompressionAlgorithm algorithm;
  final double compressionRatio; // 压缩率（0-1）
  final double speed; // 速度（bytes/ms）
  final int timeMs; // 耗时

  AlgorithmResult({
    required this.algorithm,
    required this.compressionRatio,
    required this.speed,
    required this.timeMs,
  });
}
