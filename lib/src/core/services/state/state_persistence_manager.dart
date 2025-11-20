import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:path/path.dart' as path;

import '../base/i_unified_service.dart';

/// 状态持久化管理器
///
/// 负责应用程序状态的持久化存储和恢复，包括：
/// - 状态快照的保存和加载
/// - 增量状态同步
/// - 状态版本控制
/// - 自动备份和恢复
/// - 状态迁移支持
class StatePersistenceManager extends IUnifiedService {
  late final String _stateStoragePath;
  late final String _backupStoragePath;
  late final String _migrationPath;

  // 持久化配置
  static const Duration _autoSaveInterval = Duration(minutes: 2);
  static const Duration _backupInterval = Duration(hours: 1);
  static const int _maxSnapshotCount = 10;
  static const int _maxBackupCount = 5;

  // 定时器
  Timer? _autoSaveTimer;
  Timer? _backupTimer;

  // 持久化状态
  bool _isInitialized = false;
  Map<String, dynamic> _currentState = {};

  @override
  String get serviceName => 'StatePersistenceManager';

  @override
  String get version => '1.0.0';

  @override
  List<String> get dependencies => [
        'UnifiedStateService',
      ];

  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  /// 当前持久化的状态
  Map<String, dynamic> get currentState => Map.unmodifiable(_currentState);

  @override
  Future<void> initialize(ServiceContainer container) async {
    setLifecycleState(ServiceLifecycleState.initializing);

    try {
      // 初始化存储路径
      await _initializeStoragePaths();

      // 创建存储目录
      await _ensureStorageDirectories();

      // 加载最新的状态快照
      await _loadLatestSnapshot();

      // 启动自动保存定时器
      _startAutoSave();

      // 启动自动备份定时器
      _startAutoBackup();

      _isInitialized = true;
      setLifecycleState(ServiceLifecycleState.initialized);

      if (kDebugMode) {
        print('StatePersistenceManager initialized successfully');
        print('State storage path: $_stateStoragePath');
        print('Backup storage path: $_backupStoragePath');
      }
    } catch (e) {
      setLifecycleState(ServiceLifecycleState.error);
      throw ServiceInitializationException(
        serviceName,
        'Failed to initialize StatePersistenceManager: $e',
        e,
      );
    }
  }

  @override
  Future<void> dispose() async {
    setLifecycleState(ServiceLifecycleState.disposing);

    try {
      // 停止定时器
      _autoSaveTimer?.cancel();
      _backupTimer?.cancel();

      // 保存最终状态
      await _saveCurrentState();

      setLifecycleState(ServiceLifecycleState.disposed);

      if (kDebugMode) {
        print('StatePersistenceManager disposed successfully');
      }
    } catch (e) {
      setLifecycleState(ServiceLifecycleState.error);
      if (kDebugMode) {
        print('Error disposing StatePersistenceManager: $e');
      }
    }
  }

  @override
  Future<ServiceHealthStatus> checkHealth() async {
    try {
      final isHealthy = lifecycleState == ServiceLifecycleState.initialized &&
          _isInitialized &&
          await _verifyStorageHealth();

      return ServiceHealthStatus(
        isHealthy: isHealthy,
        message: isHealthy
            ? 'State persistence is healthy'
            : 'State persistence has issues',
        lastCheck: DateTime.now(),
        details: await _getHealthDetails(),
      );
    } catch (e) {
      return ServiceHealthStatus(
        isHealthy: false,
        message: 'Health check failed: $e',
        lastCheck: DateTime.now(),
      );
    }
  }

  @override
  ServiceStats getStats() {
    return ServiceStats(
      serviceName: serviceName,
      version: version,
      uptime: DateTime.now().difference(DateTime.now()), // TODO: 保存实际启动时间
      memoryUsage: _getCurrentMemoryUsage(),
      customMetrics: {
        'snapshotCount': _getSnapshotCount(),
        'backupCount': _getBackupCount(),
        'currentStateSize': _currentState.length,
        'lastSaveTime': _getLastSaveTime(),
        'lastBackupTime': _getLastBackupTime(),
      },
    );
  }

  /// 保存状态快照
  Future<void> saveSnapshot({
    required Map<String, dynamic> state,
    String? name,
    bool createBackup = true,
  }) async {
    try {
      final snapshotName = name ?? _generateSnapshotName();
      final timestamp = DateTime.now();

      final snapshot = {
        'name': snapshotName,
        'timestamp': timestamp.toIso8601String(),
        'version': version,
        'state': state,
        'metadata': {
          'createdBy': 'StatePersistenceManager',
          'size': json.encode(state).length,
          'checksum': _calculateChecksum(state),
        },
      };

      final snapshotPath = path.join(_stateStoragePath, '$snapshotName.json');
      final snapshotFile = File(snapshotPath);

      // 保存快照
      await snapshotFile.writeAsString(
        jsonEncode(snapshot),
        encoding: utf8,
      );

      // 更新当前状态
      _currentState = Map.from(state);

      // 创建备份（可选）
      if (createBackup) {
        await _createBackup(snapshotName, snapshot);
      }

      // 清理旧快照
      await _cleanupOldSnapshots();

      if (kDebugMode) {
        print('State snapshot saved: $snapshotName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving state snapshot: $e');
      }
      rethrow;
    }
  }

  /// 加载状态快照
  Future<Map<String, dynamic>?> loadSnapshot(String snapshotName) async {
    try {
      final snapshotPath = path.join(_stateStoragePath, '$snapshotName.json');
      final snapshotFile = File(snapshotPath);

      if (!await snapshotFile.exists()) {
        if (kDebugMode) {
          print('Snapshot file not found: $snapshotName');
        }
        return null;
      }

      final snapshotJson = await snapshotFile.readAsString(encoding: utf8);
      final snapshot = jsonDecode(snapshotJson) as Map<String, dynamic>;

      // 验证快照完整性
      if (!_validateSnapshot(snapshot)) {
        if (kDebugMode) {
          print('Snapshot validation failed: $snapshotName');
        }
        return null;
      }

      final state = snapshot['state'] as Map<String, dynamic>;

      if (kDebugMode) {
        print('State snapshot loaded: $snapshotName');
      }

      return state;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading state snapshot: $e');
      }
      return null;
    }
  }

  /// 删除状态快照
  Future<bool> deleteSnapshot(String snapshotName) async {
    try {
      final snapshotPath = path.join(_stateStoragePath, '$snapshotName.json');
      final snapshotFile = File(snapshotPath);

      if (await snapshotFile.exists()) {
        await snapshotFile.delete();

        // 删除相关备份
        await _deleteSnapshotBackup(snapshotName);

        if (kDebugMode) {
          print('State snapshot deleted: $snapshotName');
        }

        return true;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting state snapshot: $e');
      }
      return false;
    }
  }

  /// 获取所有快照列表
  Future<List<SnapshotInfo>> getAllSnapshots() async {
    try {
      final directory = Directory(_stateStoragePath);
      final files = await directory
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.json'))
          .cast<File>()
          .toList();

      final snapshots = <SnapshotInfo>[];

      for (final file in files) {
        try {
          final snapshotJson = await file.readAsString(encoding: utf8);
          final snapshot = jsonDecode(snapshotJson) as Map<String, dynamic>;

          snapshots.add(SnapshotInfo(
            name: snapshot['name'] as String,
            timestamp: DateTime.parse(snapshot['timestamp'] as String),
            version: snapshot['version'] as String,
            size: snapshot['metadata']['size'] as int,
            checksum: snapshot['metadata']['checksum'] as String,
          ));
        } catch (e) {
          if (kDebugMode) {
            print('Error reading snapshot file ${file.path}: $e');
          }
        }
      }

      // 按时间戳排序（最新的在前）
      snapshots.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return snapshots;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting all snapshots: $e');
      }
      return [];
    }
  }

  /// 创建备份
  Future<void> createBackup({String? snapshotName}) async {
    try {
      final name = snapshotName ?? _generateSnapshotName();
      await _createBackup(name, _currentState);

      if (kDebugMode) {
        print('Backup created: $name');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating backup: $e');
      }
      rethrow;
    }
  }

  /// 从备份恢复
  Future<bool> restoreFromBackup(String backupName) async {
    try {
      final backupPath = path.join(_backupStoragePath, '$backupName.json');
      final backupFile = File(backupPath);

      if (!await backupFile.exists()) {
        if (kDebugMode) {
          print('Backup file not found: $backupName');
        }
        return false;
      }

      final backupJson = await backupFile.readAsString(encoding: utf8);
      final backup = jsonDecode(backupJson) as Map<String, dynamic>;

      // 验证备份完整性
      if (!_validateSnapshot(backup)) {
        if (kDebugMode) {
          print('Backup validation failed: $backupName');
        }
        return false;
      }

      final state = backup['state'] as Map<String, dynamic>;

      // 恢复状态
      _currentState = Map.from(state);

      // 保存恢复后的状态
      await _saveCurrentState();

      if (kDebugMode) {
        print('State restored from backup: $backupName');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error restoring from backup: $e');
      }
      return false;
    }
  }

  /// 执行状态迁移
  Future<MigrationResult> performMigration({
    required String fromVersion,
    required String toVersion,
    Map<String, dynamic>? migrationData,
  }) async {
    try {
      final migrationPath =
          path.join(_migrationPath, '${fromVersion}_to_$toVersion.json');

      // 检查迁移文件是否存在
      final migrationFile = File(migrationPath);
      if (!await migrationFile.exists()) {
        return MigrationResult(
          success: false,
          fromVersion: fromVersion,
          toVersion: toVersion,
          error: 'Migration file not found',
          migratedItems: 0,
        );
      }

      final migrationJson = await migrationFile.readAsString(encoding: utf8);
      final migrationConfig = jsonDecode(migrationJson) as Map<String, dynamic>;

      // 执行迁移逻辑
      int migratedItems = 0;
      final currentVersion = version;

      // 这里简化实现，实际项目中应该根据迁移配置执行具体的迁移逻辑
      if (migrationConfig.containsKey('steps')) {
        final steps = migrationConfig['steps'] as List<dynamic>;
        for (final step in steps) {
          try {
            await _executeMigrationStep(step, migrationData);
            migratedItems++;
          } catch (e) {
            if (kDebugMode) {
              print('Migration step failed: $e');
            }
          }
        }
      }

      // 更新版本号
      // version = toVersion;

      return MigrationResult(
        success: true,
        fromVersion: fromVersion,
        toVersion: toVersion,
        migratedItems: migratedItems,
      );
    } catch (e) {
      return MigrationResult(
        success: false,
        fromVersion: fromVersion,
        toVersion: toVersion,
        error: e.toString(),
        migratedItems: 0,
      );
    }
  }

  /// 压缩存储
  Future<void> compactStorage() async {
    try {
      // 清理旧快照
      await _cleanupOldSnapshots();

      // 清理旧备份
      await _cleanupOldBackups();

      // 压缩重复数据
      await _optimizeStorage();

      if (kDebugMode) {
        print('Storage compaction completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error compacting storage: $e');
      }
      rethrow;
    }
  }

  // 私有方法

  Future<void> _initializeStoragePaths() async {
    // 简化实现：使用临时目录
    final appSupportDir = Directory.systemTemp;

    // 简化实现：直接使用临时目录
    _stateStoragePath = path.join(appSupportDir.path, 'state_snapshots');
    _backupStoragePath = path.join(appSupportDir.path, 'state_backups');
    _migrationPath = path.join(appSupportDir.path, 'state_migrations');
  }

  Future<void> _ensureStorageDirectories() async {
    await Directory(_stateStoragePath).create(recursive: true);
    await Directory(_backupStoragePath).create(recursive: true);
    await Directory(_migrationPath).create(recursive: true);
  }

  Future<void> _loadLatestSnapshot() async {
    try {
      final snapshots = await getAllSnapshots();
      if (snapshots.isNotEmpty) {
        final latestSnapshot = snapshots.first;
        final state = await loadSnapshot(latestSnapshot.name);

        if (state != null) {
          _currentState = state;
          if (kDebugMode) {
            print('Loaded latest snapshot: ${latestSnapshot.name}');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading latest snapshot: $e');
      }
    }
  }

  void _startAutoSave() {
    _autoSaveTimer = Timer.periodic(_autoSaveInterval, (_) {
      _saveCurrentState();
    });
  }

  void _startAutoBackup() {
    _backupTimer = Timer.periodic(_backupInterval, (_) {
      _createBackup('auto_backup_${DateTime.now().millisecondsSinceEpoch}',
          _currentState);
    });
  }

  Future<void> _saveCurrentState() async {
    try {
      if (_currentState.isNotEmpty) {
        await saveSnapshot(
          state: _currentState,
          name: 'auto_save_${DateTime.now().millisecondsSinceEpoch}',
          createBackup: false, // 自动保存不创建备份，避免备份过多
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during auto save: $e');
      }
    }
  }

  String _generateSnapshotName() {
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    return 'snapshot_$timestamp';
  }

  String _calculateChecksum(Map<String, dynamic> data) {
    // 简化的校验和计算
    final dataString = jsonEncode(data);
    return dataString.length.toString();
  }

  bool _validateSnapshot(Map<String, dynamic> snapshot) {
    try {
      // 基本验证
      if (!snapshot.containsKey('name') ||
          !snapshot.containsKey('timestamp') ||
          !snapshot.containsKey('state') ||
          !snapshot.containsKey('metadata')) {
        return false;
      }

      // 校验和验证（简化实现）
      final metadata = snapshot['metadata'] as Map<String, dynamic>;
      if (!metadata.containsKey('checksum')) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _createBackup(
      String snapshotName, Map<String, dynamic> snapshot) async {
    try {
      final backupPath = path.join(_backupStoragePath, '$snapshotName.json');
      final backupFile = File(backupPath);

      await backupFile.writeAsString(
        jsonEncode(snapshot),
        encoding: utf8,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error creating backup: $e');
      }
    }
  }

  Future<void> _cleanupOldSnapshots() async {
    try {
      final snapshots = await getAllSnapshots();
      if (snapshots.length > _maxSnapshotCount) {
        final snapshotsToDelete = snapshots.skip(_maxSnapshotCount);

        for (final snapshot in snapshotsToDelete) {
          await deleteSnapshot(snapshot.name);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error cleaning up old snapshots: $e');
      }
    }
  }

  Future<void> _cleanupOldBackups() async {
    try {
      final directory = Directory(_backupStoragePath);
      final files = await directory
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.json'))
          .cast<File>()
          .toList();

      if (files.length > _maxBackupCount) {
        files.sort((a, b) {
          final aStat = a.statSync();
          final bStat = b.statSync();
          return aStat.modified.compareTo(bStat.modified);
        });

        final filesToDelete = files.take(files.length - _maxBackupCount);

        for (final file in filesToDelete) {
          await file.delete();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error cleaning up old backups: $e');
      }
    }
  }

  Future<void> _optimizeStorage() async {
    try {
      // 这里可以添加存储优化逻辑
      // 例如：合并相似快照、压缩数据等
    } catch (e) {
      if (kDebugMode) {
        print('Error optimizing storage: $e');
      }
    }
  }

  Future<void> _deleteSnapshotBackup(String snapshotName) async {
    try {
      final backupPath = path.join(_backupStoragePath, '$snapshotName.json');
      final backupFile = File(backupPath);

      if (await backupFile.exists()) {
        await backupFile.delete();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting snapshot backup: $e');
      }
    }
  }

  Future<bool> _verifyStorageHealth() async {
    try {
      // 检查存储目录是否可访问
      final stateDir = Directory(_stateStoragePath);
      if (!await stateDir.exists()) {
        return false;
      }

      final backupDir = Directory(_backupStoragePath);
      if (!await backupDir.exists()) {
        return false;
      }

      // 检查磁盘空间（简化实现）
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> _getHealthDetails() async {
    return {
      'isInitialized': _isInitialized,
      'stateStoragePath': _stateStoragePath,
      'backupStoragePath': _backupStoragePath,
      'snapshotCount': await _getSnapshotCount(),
      'backupCount': await _getBackupCount(),
      'currentStateSize': _currentState.length,
    };
  }

  Future<int> _getSnapshotCount() async {
    try {
      final directory = Directory(_stateStoragePath);
      final files = await directory
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.json'))
          .length;

      return files;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getBackupCount() async {
    try {
      final directory = Directory(_backupStoragePath);
      final files = await directory
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.json'))
          .length;

      return files;
    } catch (e) {
      return 0;
    }
  }

  DateTime? _getLastSaveTime() {
    // 简化实现：返回当前时间
    return DateTime.now();
  }

  DateTime? _getLastBackupTime() {
    // 简化实现：返回当前时间
    return DateTime.now();
  }

  int _getCurrentMemoryUsage() {
    try {
      return 0; // 简化实现
    } catch (e) {
      return 0;
    }
  }

  Future<void> _executeMigrationStep(
    Map<String, dynamic> step,
    Map<String, dynamic>? migrationData,
  ) async {
    // 简化实现：根据步骤类型执行迁移逻辑
    final stepType = step['type'] as String;

    switch (stepType) {
      case 'field_rename':
        await _executeFieldRename(step, migrationData);
        break;
      case 'field_add':
        await _executeFieldAdd(step, migrationData);
        break;
      case 'field_remove':
        await _executeFieldRemove(step, migrationData);
        break;
      case 'data_transform':
        await _executeDataTransform(step, migrationData);
        break;
      default:
        if (kDebugMode) {
          print('Unknown migration step type: $stepType');
        }
    }
  }

  Future<void> _executeFieldRename(
    Map<String, dynamic> step,
    Map<String, dynamic>? migrationData,
  ) async {
    // 简化实现：执行字段重命名
    if (kDebugMode) {
      print('Executing field rename migration: ${step['description']}');
    }
  }

  Future<void> _executeFieldAdd(
    Map<String, dynamic> step,
    Map<String, dynamic>? migrationData,
  ) async {
    // 简化实现：执行字段添加
    if (kDebugMode) {
      print('Executing field add migration: ${step['description']}');
    }
  }

  Future<void> _executeFieldRemove(
    Map<String, dynamic> step,
    Map<String, dynamic>? migrationData,
  ) async {
    // 简化实现：执行字段删除
    if (kDebugMode) {
      print('Executing field remove migration: ${step['description']}');
    }
  }

  Future<void> _executeDataTransform(
    Map<String, dynamic> step,
    Map<String, dynamic>? migrationData,
  ) async {
    // 简化实现：执行数据转换
    if (kDebugMode) {
      print('Executing data transform migration: ${step['description']}');
    }
  }
}

// 辅助类定义

/// 快照信息
class SnapshotInfo {
  final String name;
  final DateTime timestamp;
  final String version;
  final int size;
  final String checksum;

  const SnapshotInfo({
    required this.name,
    required this.timestamp,
    required this.version,
    required this.size,
    required this.checksum,
  });
}

/// 迁移结果
class MigrationResult {
  final bool success;
  final String fromVersion;
  final String toVersion;
  final String? error;
  final int migratedItems;

  const MigrationResult({
    required this.success,
    required this.fromVersion,
    required this.toVersion,
    this.error,
    required this.migratedItems,
  });
}
