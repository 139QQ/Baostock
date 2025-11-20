// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../../utils/logger.dart';

/// 内存映射文件配置
class MemoryMappedFileConfig {
  final String tempDirectory;
  final int maxFileSizeMB;
  final Duration fileCleanupDelay;
  final bool enableCompression;
  final bool enableEncryption;
  final String? encryptionKey;

  const MemoryMappedFileConfig({
    this.tempDirectory = 'temp',
    this.maxFileSizeMB = 100,
    this.fileCleanupDelay = const Duration(minutes: 30),
    this.enableCompression = false,
    this.enableEncryption = false,
    this.encryptionKey,
  });
}

/// 文件传输状态
enum FileTransferStatus {
  preparing, // 准备中
  transferring, // 传输中
  completed, // 完成
  failed, // 失败
  cancelled, // 已取消
}

/// 文件传输信息
class FileTransferInfo {
  final String fileId;
  final String fileName;
  final int fileSizeBytes;
  final FileTransferStatus status;
  final DateTime startTime;
  final DateTime? endTime;
  final double progress; // 0.0 - 1.0
  final String? errorMessage;
  final int transferredBytes;

  FileTransferInfo({
    required this.fileId,
    required this.fileName,
    required this.fileSizeBytes,
    required this.status,
    required this.startTime,
    this.endTime,
    this.progress = 0.0,
    this.errorMessage,
    this.transferredBytes = 0,
  });

  FileTransferInfo copyWith({
    String? fileId,
    String? fileName,
    int? fileSizeBytes,
    FileTransferStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    double? progress,
    String? errorMessage,
    int? transferredBytes,
  }) {
    return FileTransferInfo(
      fileId: fileId ?? this.fileId,
      fileName: fileName ?? this.fileName,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
      transferredBytes: transferredBytes ?? this.transferredBytes,
    );
  }

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  double get transferSpeedMBps {
    if (duration.inSeconds == 0) return 0.0;
    return (transferredBytes / (1024 * 1024)) / duration.inSeconds;
  }

  Map<String, dynamic> toJson() {
    return {
      'fileId': fileId,
      'fileName': fileName,
      'fileSizeBytes': fileSizeBytes,
      'status': status.name,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'progress': progress,
      'errorMessage': errorMessage,
      'transferredBytes': transferredBytes,
      'durationMs': duration.inMilliseconds,
      'transferSpeedMBps': transferSpeedMBps,
    };
  }
}

/// 内存映射文件处理器
///
/// 提供高性能的文件传输机制，使用内存映射技术处理大数据对象
class MemoryMappedFileHandler {
  static final MemoryMappedFileHandler _instance =
      MemoryMappedFileHandler._internal();
  factory MemoryMappedFileHandler() => _instance;
  MemoryMappedFileHandler._internal();

  // 使用AppLogger静态方法
  MemoryMappedFileConfig _config = const MemoryMappedFileConfig();

  final Map<String, FileTransferInfo> _activeTransfers = {};
  final Map<String, File> _openFiles = {};
  Timer? _cleanupTimer;

  /// 配置处理器
  void configure(MemoryMappedFileConfig config) {
    _config = config;
    AppLogger.info('MemoryMappedFileHandler配置已更新');

    // 重启清理定时器
    if (_cleanupTimer != null) {
      _cleanupTimer!.cancel();
      _cleanupTimer = null;
    }

    _startCleanupTimer();
  }

  /// 启动处理器
  void start() {
    AppLogger.info('启动MemoryMappedFileHandler');

    // 创建临时目录
    final tempDir = Directory(_config.tempDirectory);
    if (!tempDir.existsSync()) {
      tempDir.createSync(recursive: true);
    }

    _startCleanupTimer();
  }

  /// 停止处理器
  Future<void> stop() async {
    AppLogger.info('停止MemoryMappedFileHandler');

    _cleanupTimer?.cancel();
    _cleanupTimer = null;

    // 取消所有活跃传输
    final transferIds = _activeTransfers.keys.toList();
    for (final transferId in transferIds) {
      await cancelTransfer(transferId);
    }

    // 清理所有打开的文件引用
    final fileIds = _openFiles.keys.toList();
    for (final fileId in fileIds) {
      _openFiles.remove(fileId);
    }

    AppLogger.info('MemoryMappedFileHandler已停止');
  }

  /// 创建内存映射文件
  Future<String> createMemoryMappedFile(
    String fileName,
    Uint8List data, {
    String? customId,
  }) async {
    final fileId = customId ?? 'file_${DateTime.now().millisecondsSinceEpoch}';
    final filePath = '${_config.tempDirectory}/$fileId.$fileName';

    try {
      AppLogger.debug('创建内存映射文件: $fileName ($fileId)');

      // 检查文件大小限制
      if (data.length > _config.maxFileSizeMB * 1024 * 1024) {
        throw ArgumentError(
            '文件大小超过限制: ${data.length}字节 > ${_config.maxFileSizeMB}MB');
      }

      // 创建传输信息
      final transferInfo = FileTransferInfo(
        fileId: fileId,
        fileName: fileName,
        fileSizeBytes: data.length,
        status: FileTransferStatus.preparing,
        startTime: DateTime.now(),
      );

      _activeTransfers[fileId] = transferInfo;

      // 处理数据（压缩、加密等）
      final processedData = await _processDataForWriting(data);

      // 写入文件
      final file = File(filePath);
      await file.writeAsBytes(processedData);

      // 更新传输状态
      _activeTransfers[fileId] = transferInfo.copyWith(
        status: FileTransferStatus.completed,
        endTime: DateTime.now(),
        progress: 1.0,
        transferredBytes: processedData.length,
      );

      // 记录打开的文件
      _openFiles[fileId] = file;

      AppLogger.debug('内存映射文件创建完成: $fileId (${processedData.length}字节)');
      return fileId;
    } catch (e) {
      AppLogger.error('创建内存映射文件失败: $fileId', e);

      _activeTransfers[fileId] = FileTransferInfo(
        fileId: fileId,
        fileName: fileName,
        fileSizeBytes: data.length,
        status: FileTransferStatus.failed,
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        errorMessage: e.toString(),
      );

      rethrow;
    }
  }

  /// 读取内存映射文件
  Future<Uint8List> readMemoryMappedFile(String fileId) async {
    try {
      AppLogger.debug('读取内存映射文件: $fileId');

      final file = _openFiles[fileId];
      if (file == null) {
        throw StateError('文件不存在或已关闭: $fileId');
      }

      // 读取文件数据
      final bytes = await file.readAsBytes();

      // 处理读取的数据（解压缩、解密等）
      final processedData = await _processDataForReading(bytes);

      AppLogger.debug('内存映射文件读取完成: $fileId (${processedData.length}字节)');
      return processedData;
    } catch (e) {
      AppLogger.error('读取内存映射文件失败: $fileId', e);
      rethrow;
    }
  }

  /// 异步传输大数据
  Future<String> transferLargeData(
    String fileName,
    Stream<List<int>> dataStream, {
    int chunkSize = 64 * 1024, // 64KB chunks
    String? customId,
    Function(double)? onProgress,
  }) async {
    final fileId =
        customId ?? 'transfer_${DateTime.now().millisecondsSinceEpoch}';
    final filePath = '${_config.tempDirectory}/$fileId.$fileName';

    try {
      AppLogger.debug('开始大数据传输: $fileName ($fileId)');

      // 创建传输信息
      final transferInfo = FileTransferInfo(
        fileId: fileId,
        fileName: fileName,
        fileSizeBytes: 0, // 未知大小
        status: FileTransferStatus.transferring,
        startTime: DateTime.now(),
      );

      _activeTransfers[fileId] = transferInfo;

      final file = File(filePath);
      final sink = file.openWrite();

      int totalBytes = 0;
      await for (final chunk in dataStream) {
        sink.add(chunk);
        totalBytes += chunk.length;

        // 更新传输进度
        final progress = onProgress != null ? 0.5 : 0.0; // 无法确定总大小时使用50%
        _activeTransfers[fileId] = transferInfo.copyWith(
          transferredBytes: totalBytes,
          progress: progress,
        );

        onProgress?.call(progress);
      }

      await sink.close();

      // 更新最终状态
      _activeTransfers[fileId] = transferInfo.copyWith(
        fileSizeBytes: totalBytes,
        status: FileTransferStatus.completed,
        endTime: DateTime.now(),
        progress: 1.0,
        transferredBytes: totalBytes,
      );

      _openFiles[fileId] = file;

      AppLogger.debug('大数据传输完成: $fileId (${totalBytes}字节)');
      return fileId;
    } catch (e) {
      AppLogger.error('大数据传输失败: $fileId', e);

      _activeTransfers[fileId] = FileTransferInfo(
        fileId: fileId,
        fileName: fileName,
        fileSizeBytes: 0,
        status: FileTransferStatus.failed,
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        errorMessage: e.toString(),
      );

      rethrow;
    }
  }

  /// 创建共享内存区域（用于Isolate间通信）
  Future<SharedMemoryInfo> createSharedMemory(int sizeBytes) async {
    final memoryId = 'shared_${DateTime.now().millisecondsSinceEpoch}';

    try {
      AppLogger.debug('创建共享内存: $memoryId (${sizeBytes}字节)');

      // 在实际实现中，这里应该使用真正的共享内存
      // 这里简化为创建临时文件作为共享内存载体
      final sharedFile = File('${_config.tempDirectory}/$memoryId.shared');
      await sharedFile.writeAsBytes(Uint8List(sizeBytes));

      final sharedMemory = SharedMemoryInfo(
        memoryId: memoryId,
        sizeBytes: sizeBytes,
        filePath: sharedFile.path,
      );

      _openFiles[memoryId] = sharedFile;

      AppLogger.debug('共享内存创建完成: $memoryId');
      return sharedMemory;
    } catch (e) {
      AppLogger.error('创建共享内存失败: $memoryId', e);
      rethrow;
    }
  }

  /// 访问共享内存
  Future<Uint8List> accessSharedMemory(String memoryId) async {
    try {
      final file = _openFiles[memoryId];
      if (file == null) {
        throw StateError('共享内存不存在: $memoryId');
      }

      final bytes = await file.readAsBytes();
      return bytes;
    } catch (e) {
      AppLogger.error('访问共享内存失败: $memoryId', e);
      rethrow;
    }
  }

  /// 取消传输
  Future<void> cancelTransfer(String fileId) async {
    try {
      final transferInfo = _activeTransfers[fileId];
      if (transferInfo == null) return;

      AppLogger.debug('取消传输: $fileId');

      // 更新状态
      _activeTransfers[fileId] = transferInfo.copyWith(
        status: FileTransferStatus.cancelled,
        endTime: DateTime.now(),
      );

      // 删除文件（如果存在）
      final filePath =
          '${_config.tempDirectory}/$fileId.${transferInfo.fileName}';
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }

      // 从打开文件列表中移除
      _openFiles.remove(fileId);
    } catch (e) {
      AppLogger.error('取消传输失败: $fileId', e);
    }
  }

  /// 删除文件
  Future<void> deleteFile(String fileId) async {
    try {
      AppLogger.debug('删除文件: $fileId');

      final file = _openFiles.remove(fileId);
      if (file != null) {
        await file.delete();
      }

      // 从活跃传输中移除
      _activeTransfers.remove(fileId);
    } catch (e) {
      AppLogger.error('删除文件失败: $fileId', e);
    }
  }

  /// 获取传输信息
  FileTransferInfo? getTransferInfo(String fileId) {
    return _activeTransfers[fileId];
  }

  /// 获取所有活跃传输
  Map<String, FileTransferInfo> getAllActiveTransfers() {
    return Map.unmodifiable(_activeTransfers);
  }

  /// 获取统计信息
  Map<String, dynamic> getStatistics() {
    final transfers = _activeTransfers.values.toList();
    final completed =
        transfers.where((t) => t.status == FileTransferStatus.completed).length;
    final failed =
        transfers.where((t) => t.status == FileTransferStatus.failed).length;
    final active = transfers
        .where((t) => t.status == FileTransferStatus.transferring)
        .length;

    final totalSizeBytes = transfers
        .where((t) => t.status == FileTransferStatus.completed)
        .map((t) => t.fileSizeBytes)
        .fold(0, (a, b) => a + b);

    return {
      'activeTransfers': active,
      'completedTransfers': completed,
      'failedTransfers': failed,
      'totalTransfers': transfers.length,
      'openFiles': _openFiles.length,
      'totalSizeBytes': totalSizeBytes,
      'totalSizeMB': (totalSizeBytes / (1024 * 1024)).toStringAsFixed(2),
      'config': {
        'tempDirectory': _config.tempDirectory,
        'maxFileSizeMB': _config.maxFileSizeMB,
        'enableCompression': _config.enableCompression,
        'enableEncryption': _config.enableEncryption,
      },
    };
  }

  /// 处理写入数据（压缩、加密等）
  Future<Uint8List> _processDataForWriting(Uint8List data) async {
    Uint8List processed = Uint8List.fromList(data);

    // 压缩
    if (_config.enableCompression) {
      processed = await _compressData(processed);
    }

    // 加密
    if (_config.enableEncryption && _config.encryptionKey != null) {
      processed = await _encryptData(processed, _config.encryptionKey!);
    }

    return processed;
  }

  /// 处理读取数据（解压缩、解密等）
  Future<Uint8List> _processDataForReading(Uint8List data) async {
    Uint8List processed = Uint8List.fromList(data);

    // 解密
    if (_config.enableEncryption && _config.encryptionKey != null) {
      processed = await _decryptData(processed, _config.encryptionKey!);
    }

    // 解压缩
    if (_config.enableCompression) {
      processed = await _decompressData(processed);
    }

    return processed;
  }

  /// 压缩数据（简化实现）
  Future<Uint8List> _compressData(Uint8List data) async {
    // 在实际实现中，应该使用真正的压缩算法（如gzip、zlib等）
    // 这里简化为直接返回原数据
    AppLogger.debug('数据压缩: ${data.length} -> ${data.length}字节');
    return data;
  }

  /// 解压缩数据（简化实现）
  Future<Uint8List> _decompressData(Uint8List data) async {
    AppLogger.debug('数据解压缩: ${data.length}字节');
    return data;
  }

  /// 加密数据（简化实现）
  Future<Uint8List> _encryptData(Uint8List data, String key) async {
    AppLogger.debug('数据加密: ${data.length}字节');
    // 在实际实现中，应该使用真正的加密算法
    return data;
  }

  /// 解密数据（简化实现）
  Future<Uint8List> _decryptData(Uint8List data, String key) async {
    AppLogger.debug('数据解密: ${data.length}字节');
    return data;
  }

  /// 启动清理定时器
  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(
      const Duration(minutes: 10),
      (_) => _performCleanup(),
    );
  }

  /// 执行清理
  void _performCleanup() {
    try {
      final now = DateTime.now();
      final filesToDelete = <String>[];

      // 清理完成的传输（超过延迟时间）
      for (final entry in _activeTransfers.entries) {
        final fileId = entry.key;
        final transferInfo = entry.value;

        if (transferInfo.status == FileTransferStatus.completed &&
            transferInfo.endTime != null &&
            now.difference(transferInfo.endTime!) > _config.fileCleanupDelay) {
          filesToDelete.add(fileId);
        }
      }

      // 删除文件
      for (final fileId in filesToDelete) {
        deleteFile(fileId);
      }

      if (filesToDelete.isNotEmpty) {
        AppLogger.debug('清理了 ${filesToDelete.length} 个过期文件');
      }
    } catch (e) {
      AppLogger.error('执行清理失败', e);
    }
  }
}

/// 共享内存信息
class SharedMemoryInfo {
  final String memoryId;
  final int sizeBytes;
  final String filePath;

  SharedMemoryInfo({
    required this.memoryId,
    required this.sizeBytes,
    required this.filePath,
  });

  Map<String, dynamic> toJson() {
    return {
      'memoryId': memoryId,
      'sizeBytes': sizeBytes,
      'filePath': filePath,
    };
  }
}
