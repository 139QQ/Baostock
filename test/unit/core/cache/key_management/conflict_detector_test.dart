/// 缓存键冲突检测器测试
library conflict_detector_test;

import 'package:flutter_test/flutter_test.dart';
import 'package:jisu_fund_analyzer/src/core/cache/cache_key_manager.dart';

/// 缓存键冲突类型
enum ConflictType {
  /// 完全重复
  duplicate,

  /// 类型冲突（相同标识符但不同类型）
  typeConflict,

  /// 版本冲突（相同键但不同版本）
  versionConflict,

  /// 参数冲突（相似键但参数不同）
  parameterConflict,

  /// 命名空间冲突
  namespaceConflict,
}

/// 缓存键冲突信息
class CacheKeyConflict {
  final String key1;
  final String key2;
  final ConflictType conflictType;
  final String description;
  final List<String> resolutionSuggestions;

  const CacheKeyConflict({
    required this.key1,
    required this.key2,
    required this.conflictType,
    required this.description,
    required this.resolutionSuggestions,
  });

  @override
  String toString() {
    return 'CacheKeyConflict(type: $conflictType, key1: $key1, key2: $key2, description: $description)';
  }
}

/// 简化的冲突检测器实现
class CacheKeyConflictDetector {
  final CacheKeyManager _keyManager = CacheKeyManager.instance;

  /// 检测缓存键冲突
  Future<List<CacheKeyConflict>> detectConflicts(List<String> cacheKeys) async {
    final conflicts = <CacheKeyConflict>[];
    final keyMap = <String, CacheKeyInfo>{};

    // 第一遍：解析所有有效键
    for (final key in cacheKeys) {
      final info = _keyManager.parseKey(key);
      if (info != null) {
        keyMap[key] = info;
      }
    }

    // 第二遍：检测冲突
    final keyList = keyMap.keys.toList();
    for (int i = 0; i < keyList.length; i++) {
      for (int j = i + 1; j < keyList.length; j++) {
        final key1 = keyList[i];
        final key2 = keyList[j];
        final info1 = keyMap[key1]!;
        final info2 = keyMap[key2]!;

        final conflict = _detectConflictBetweenKeys(key1, info1, key2, info2);
        if (conflict != null) {
          conflicts.add(conflict);
        }
      }
    }

    return conflicts;
  }

  /// 检测两个键之间的冲突
  CacheKeyConflict? _detectConflictBetweenKeys(
    String key1,
    CacheKeyInfo info1,
    String key2,
    CacheKeyInfo info2,
  ) {
    // 完全重复
    if (key1 == key2) {
      return CacheKeyConflict(
        key1: key1,
        key2: key2,
        conflictType: ConflictType.duplicate,
        description: '缓存键完全重复',
        resolutionSuggestions: ['删除重复键', '合并键内容'],
      );
    }

    // 类型冲突（相同标识符但不同类型）
    if (info1.identifier == info2.identifier && info1.type != info2.type) {
      return CacheKeyConflict(
        key1: key1,
        key2: key2,
        conflictType: ConflictType.typeConflict,
        description: '相同标识符但不同类型的缓存键',
        resolutionSuggestions: ['使用不同的标识符', '合并为统一的类型'],
      );
    }

    // 版本冲突（相似键但不同版本）
    if (info1.type == info2.type &&
        info1.identifier == info2.identifier &&
        info1.version != info2.version) {
      return CacheKeyConflict(
        key1: key1,
        key2: key2,
        conflictType: ConflictType.versionConflict,
        description: '相同缓存键但版本不同',
        resolutionSuggestions: ['统一使用最新版本', '保留多个版本用于兼容'],
      );
    }

    // 参数冲突（相似键但参数不同）
    if (info1.type == info2.type &&
        info1.identifier == info2.identifier &&
        info1.version == info2.version &&
        !_areParameterListsEqual(info1.params, info2.params)) {
      return CacheKeyConflict(
        key1: key1,
        key2: key2,
        conflictType: ConflictType.parameterConflict,
        description: '相同缓存键但参数不同',
        resolutionSuggestions: ['合并参数', '使用不同的标识符区分'],
      );
    }

    // 命名空间冲突（相似的键结构可能导致混淆）
    if (_isPotentialNamespaceConflict(info1, info2)) {
      return CacheKeyConflict(
        key1: key1,
        key2: key2,
        conflictType: ConflictType.namespaceConflict,
        description: '潜在的命名空间冲突',
        resolutionSuggestions: ['使用更具体的标识符', '添加类型前缀'],
      );
    }

    return null;
  }

  /// 比较参数列表是否相等
  bool _areParameterListsEqual(List<String> params1, List<String> params2) {
    if (params1.length != params2.length) return false;
    for (int i = 0; i < params1.length; i++) {
      if (params1[i] != params2[i]) return false;
    }
    return true;
  }

  /// 检测潜在的命名空间冲突
  bool _isPotentialNamespaceConflict(CacheKeyInfo info1, CacheKeyInfo info2) {
    // 相同类型，标识符包含关系
    if (info1.type == info2.type) {
      final id1 = info1.identifier;
      final id2 = info2.identifier;

      // 一个标识符包含另一个标识符
      if (id1.contains(id2) || id2.contains(id1)) {
        return true;
      }

      // 标识符相似度很高（简单的包含检测）
      if (id1.split('_').any((part) => id2.contains(part)) &&
          id2.split('_').any((part) => id1.contains(part))) {
        return true;
      }
    }

    return false;
  }

  /// 生成冲突解决建议
  List<String> generateResolutionSuggestions(CacheKeyConflict conflict) {
    final suggestions = <String>[];

    switch (conflict.conflictType) {
      case ConflictType.duplicate:
        suggestions.addAll(['删除重复键', '检查是否为数据错误', '合并键内容']);
        break;
      case ConflictType.typeConflict:
        suggestions.addAll(['使用更具体的标识符', '重新设计键结构', '添加类型前缀']);
        break;
      case ConflictType.versionConflict:
        suggestions.addAll(['统一使用最新版本', '保留多个版本用于兼容', '迁移到新版本']);
        break;
      case ConflictType.parameterConflict:
        suggestions.addAll(['合并参数', '使用不同的标识符', '创建新的键类型']);
        break;
      case ConflictType.namespaceConflict:
        suggestions.addAll(['使用更具体的标识符', '添加命名空间前缀', '重新组织键结构']);
        break;
    }

    return suggestions;
  }
}

void main() {
  group('缓存键冲突检测基础功能测试', () {
    late CacheKeyConflictDetector detector;

    setUp(() {
      detector = CacheKeyConflictDetector();
    });

    test('应该检测完全重复的缓存键', () async {
      final keys = [
        'jisu_fund_fundData_161725@latest',
        'jisu_fund_fundData_161725@latest',
        'jisu_fund_fundData_000001@latest',
      ];

      final conflicts = await detector.detectConflicts(keys);

      expect(conflicts, hasLength(1));
      expect(conflicts.first.conflictType, equals(ConflictType.duplicate));
      expect(conflicts.first.key1, equals(conflicts.first.key2));
    });

    test('应该检测类型冲突的缓存键', () async {
      final keys = [
        'jisu_fund_fundData_161725@latest',
        'jisu_fund_searchIndex_161725@latest',
        'jisu_fund_userPreference_161725@latest',
      ];

      final conflicts = await detector.detectConflicts(keys);

      expect(conflicts, hasLength(3)); // 3个键之间的两两冲突

      // 检查是否所有冲突都是类型冲突
      for (final conflict in conflicts) {
        expect(conflict.conflictType, equals(ConflictType.typeConflict));
        expect(conflict.description, contains('相同标识符但不同类型'));
      }
    });

    test('应该检测版本冲突的缓存键', () async {
      final keys = [
        'jisu_fund_fundData_161725@latest',
        'jisu_fund_fundData_161725@v1',
        'jisu_fund_fundData_161725@v2',
      ];

      final conflicts = await detector.detectConflicts(keys);

      expect(conflicts, hasLength(3)); // 3个键之间的两两冲突

      // 检查是否所有冲突都是版本冲突
      for (final conflict in conflicts) {
        expect(conflict.conflictType, equals(ConflictType.versionConflict));
        expect(conflict.description, contains('相同缓存键但版本不同'));
      }
    });

    test('应该检测参数冲突的缓存键', () async {
      final keys = [
        'jisu_fund_fundData_list_equity@latest_type_equity',
        'jisu_fund_fundData_list_equity@latest_type_equity_size_100',
        'jisu_fund_fundData_list_equity@latest_type_equity_size_200',
      ];

      final conflicts = await detector.detectConflicts(keys);

      expect(conflicts, hasLength(3)); // 3个键之间的两两冲突

      // 检查是否所有冲突都是参数冲突
      for (final conflict in conflicts) {
        expect(conflict.conflictType, equals(ConflictType.parameterConflict));
        expect(conflict.description, contains('相同缓存键但参数不同'));
      }
    });

    test('应该检测命名空间冲突的缓存键', () async {
      final keys = [
        'jisu_fund_fundData_fund_list@latest',
        'jisu_fund_fundData_fund_list_equity@latest',
        'jisu_fund_fundData_fund_list_bond@latest',
      ];

      final conflicts = await detector.detectConflicts(keys);

      expect(conflicts.isNotEmpty);

      // 检查是否有命名空间冲突
      final namespaceConflicts = conflicts
          .where((c) => c.conflictType == ConflictType.namespaceConflict)
          .toList();

      expect(namespaceConflicts, isNotEmpty);
    });

    test('应该正确处理无冲突的情况', () async {
      final keys = [
        'jisu_fund_fundData_161725@latest',
        'jisu_fund_searchIndex_fund_name@latest',
        'jisu_fund_userPreference_theme@latest',
        'jisu_fund_metadata_cache_version@latest',
      ];

      final conflicts = await detector.detectConflicts(keys);

      expect(conflicts, isEmpty);
    });
  });

  group('缓存键冲突检测边界情况测试', () {
    late CacheKeyConflictDetector detector;

    setUp(() {
      detector = CacheKeyConflictDetector();
    });

    test('应该处理空的键列表', () async {
      final conflicts = await detector.detectConflicts([]);
      expect(conflicts, isEmpty);
    });

    test('应该处理单个键的列表', () async {
      final conflicts =
          await detector.detectConflicts(['jisu_fund_fundData_test@latest']);
      expect(conflicts, isEmpty);
    });

    test('应该忽略无效的缓存键', () async {
      final keys = [
        'jisu_fund_fundData_test@latest',
        'invalid_key_format',
        'jisu_fund_fundData_test@latest', // 重复的键
        'another_invalid_format',
      ];

      final conflicts = await detector.detectConflicts(keys);

      // 应该只检测到一个重复冲突，忽略无效键
      expect(conflicts, hasLength(1));
      expect(conflicts.first.conflictType, equals(ConflictType.duplicate));
    });

    test('应该处理大量缓存键', () async {
      final keys = <String>[];

      // 生成100个测试键，其中包含一些冲突
      for (int i = 0; i < 50; i++) {
        keys.add('jisu_fund_fundData_fund_$i@latest');
        keys.add('jisu_fund_fundData_fund_$i@v1'); // 版本冲突
      }

      final conflicts = await detector.detectConflicts(keys);

      // 应该检测到50个版本冲突（每对键一个冲突）
      expect(conflicts, hasLength(50));

      for (final conflict in conflicts) {
        expect(conflict.conflictType, equals(ConflictType.versionConflict));
      }
    });

    test('应该处理复杂的冲突组合', () async {
      final keys = [
        // 完全重复
        'jisu_fund_fundData_test@latest',
        'jisu_fund_fundData_test@latest',

        // 类型冲突
        'jisu_fund_fundData_duplicate@latest',
        'jisu_fund_searchIndex_duplicate@latest',

        // 版本冲突
        'jisu_fund_fundData_version_conflict@latest',
        'jisu_fund_fundData_version_conflict@v1',

        // 参数冲突
        'jisu_fund_fundData_param_conflict@latest_param1',
        'jisu_fund_fundData_param_conflict@latest_param2',

        // 无冲突
        'jisu_fund_fundData_no_conflict@latest',
      ];

      final conflicts = await detector.detectConflicts(keys);

      // 应该检测到所有类型的冲突
      final duplicateConflicts = conflicts
          .where((c) => c.conflictType == ConflictType.duplicate)
          .toList();
      final typeConflicts = conflicts
          .where((c) => c.conflictType == ConflictType.typeConflict)
          .toList();
      final versionConflicts = conflicts
          .where((c) => c.conflictType == ConflictType.versionConflict)
          .toList();
      final parameterConflicts = conflicts
          .where((c) => c.conflictType == ConflictType.parameterConflict)
          .toList();

      expect(duplicateConflicts, hasLength(1));
      expect(typeConflicts, hasLength(1));
      expect(versionConflicts, hasLength(1));
      expect(parameterConflicts, hasLength(1));
    });
  });

  group('冲突解决建议测试', () {
    late CacheKeyConflictDetector detector;

    setUp(() {
      detector = CacheKeyConflictDetector();
    });

    test('应该为重复冲突生成合适的建议', () {
      final conflict = CacheKeyConflict(
        key1: 'jisu_fund_fundData_test@latest',
        key2: 'jisu_fund_fundData_test@latest',
        conflictType: ConflictType.duplicate,
        description: '缓存键完全重复',
        resolutionSuggestions: [],
      );

      final suggestions = detector.generateResolutionSuggestions(conflict);

      expect(suggestions, contains('删除重复键'));
      expect(suggestions, contains('检查是否为数据错误'));
      expect(suggestions, contains('合并键内容'));
    });

    test('应该为类型冲突生成合适的建议', () {
      final conflict = CacheKeyConflict(
        key1: 'jisu_fund_fundData_duplicate@latest',
        key2: 'jisu_fund_searchIndex_duplicate@latest',
        conflictType: ConflictType.typeConflict,
        description: '相同标识符但不同类型的缓存键',
        resolutionSuggestions: [],
      );

      final suggestions = detector.generateResolutionSuggestions(conflict);

      expect(suggestions, contains('使用更具体的标识符'));
      expect(suggestions, contains('重新设计键结构'));
      expect(suggestions, contains('添加类型前缀'));
    });

    test('应该为版本冲突生成合适的建议', () {
      final conflict = CacheKeyConflict(
        key1: 'jisu_fund_fundData_test@latest',
        key2: 'jisu_fund_fundData_test@v1',
        conflictType: ConflictType.versionConflict,
        description: '相同缓存键但版本不同',
        resolutionSuggestions: [],
      );

      final suggestions = detector.generateResolutionSuggestions(conflict);

      expect(suggestions, contains('统一使用最新版本'));
      expect(suggestions, contains('保留多个版本用于兼容'));
      expect(suggestions, contains('迁移到新版本'));
    });

    test('应该为参数冲突生成合适的建议', () {
      final conflict = CacheKeyConflict(
        key1: 'jisu_fund_fundData_param_test@latest_param1',
        key2: 'jisu_fund_fundData_param_test@latest_param2',
        conflictType: ConflictType.parameterConflict,
        description: '相同缓存键但参数不同',
        resolutionSuggestions: [],
      );

      final suggestions = detector.generateResolutionSuggestions(conflict);

      expect(suggestions, contains('合并参数'));
      expect(suggestions, contains('使用不同的标识符'));
      expect(suggestions, contains('创建新的键类型'));
    });

    test('应该为命名空间冲突生成合适的建议', () {
      final conflict = CacheKeyConflict(
        key1: 'jisu_fund_fundData_fund_list@latest',
        key2: 'jisu_fund_fundData_fund_list_equity@latest',
        conflictType: ConflictType.namespaceConflict,
        description: '潜在的命名空间冲突',
        resolutionSuggestions: [],
      );

      final suggestions = detector.generateResolutionSuggestions(conflict);

      expect(suggestions, contains('使用更具体的标识符'));
      expect(suggestions, contains('添加命名空间前缀'));
      expect(suggestions, contains('重新组织键结构'));
    });
  });

  group('冲突检测性能测试', () {
    late CacheKeyConflictDetector detector;

    setUp(() {
      detector = CacheKeyConflictDetector();
    });

    test('应该能高效处理大量缓存键', () async {
      final keys = <String>[];

      // 生成1000个测试键
      for (int i = 0; i < 1000; i++) {
        keys.add('jisu_fund_fundData_fund_$i@latest');
      }

      final stopwatch = Stopwatch()..start();
      final conflicts = await detector.detectConflicts(keys);
      stopwatch.stop();

      // 无冲突的检测应该在合理时间内完成
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      expect(conflicts, isEmpty);
    });

    test('应该能高效检测大量冲突', () async {
      final keys = <String>[];

      // 生成100对冲突的键
      for (int i = 0; i < 100; i++) {
        keys.add('jisu_fund_fundData_conflict_$i@latest');
        keys.add('jisu_fund_fundData_conflict_$i@v1'); // 版本冲突
      }

      final stopwatch = Stopwatch()..start();
      final conflicts = await detector.detectConflicts(keys);
      stopwatch.stop();

      // 冲突检测应该在合理时间内完成
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));
      expect(conflicts, hasLength(100));
    });
  });

  group('CacheKeyConflict对象测试', () {
    test('应该正确格式化toString', () {
      final conflict = CacheKeyConflict(
        key1: 'jisu_fund_fundData_test1@latest',
        key2: 'jisu_fund_fundData_test2@latest',
        conflictType: ConflictType.duplicate,
        description: '测试冲突',
        resolutionSuggestions: ['建议1', '建议2'],
      );

      final result = conflict.toString();
      expect(result, contains('CacheKeyConflict'));
      expect(result, contains('duplicate'));
      expect(result, contains('test1'));
      expect(result, contains('test2'));
      expect(result, contains('测试冲突'));
    });

    test('应该正确存储所有字段', () {
      final conflict = CacheKeyConflict(
        key1: 'key1',
        key2: 'key2',
        conflictType: ConflictType.typeConflict,
        description: '类型冲突描述',
        resolutionSuggestions: ['建议A', '建议B', '建议C'],
      );

      expect(conflict.key1, equals('key1'));
      expect(conflict.key2, equals('key2'));
      expect(conflict.conflictType, equals(ConflictType.typeConflict));
      expect(conflict.description, equals('类型冲突描述'));
      expect(conflict.resolutionSuggestions, equals(['建议A', '建议B', '建议C']));
    });
  });
}
