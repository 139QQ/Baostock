import 'dart:async';
import 'package:hive/hive.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/fund_favorite/src/entities/fund_favorite.dart';
import 'package:jisu_fund_analyzer/src/features/portfolio/domain/fund_favorite/src/entities/fund_favorite_list.dart';

/// 自选基金Hive适配器
///
/// 支持FundFavorite和相关的价格提醒设置的类型转换
class FundFavoriteAdapter extends TypeAdapter<FundFavorite> {
  @override
  final int typeId = 10; // 使用更高的typeId避免冲突

  @override
  FundFavorite read(BinaryReader reader) {
    try {
      final numberOfFields = reader.readByte();

      // 防护：限制字段数量，防止恶意或损坏数据导致无限循环
      if (numberOfFields < 0 || numberOfFields > 50) {
        throw FormatException(
            'Invalid field count: $numberOfFields. Expected between 0 and 50.');
      }

      final fields = <int, dynamic>{};
      for (int i = 0; i < numberOfFields; i++) {
        try {
          fields[i] = reader.read();
        } catch (e) {
          throw FormatException('Failed to read field $i: $e');
        }
      }

      return FundFavorite(
        fundCode: fields[0] as String? ?? '',
        fundName: fields[1] as String? ?? '',
        fundType: fields[2] as String? ?? '',
        fundManager: fields[3] as String? ?? '',
        addedAt: _parseDateTime(fields[4]),
        sortWeight: (fields[5] as num?)?.toDouble() ?? 0.0,
        notes: fields[6] as String?,
        priceAlerts: fields[7] as PriceAlertSettings?,
        updatedAt: _parseDateTime(fields[8]),
        currentNav: (fields[9] as num?)?.toDouble(),
        dailyChange: (fields[10] as num?)?.toDouble(),
        previousNav: (fields[11] as num?)?.toDouble(),
        establishDate: fields[12] == null ? null : _parseDateTime(fields[12]),
        fundScale: (fields[13] as num?)?.toDouble(),
        isSynced: fields[14] as bool? ?? false,
        cloudId: fields[15] as String?,
      );
    } catch (e) {
      // 如果读取失败，返回一个默认的对象，避免应用崩溃
      return FundFavorite(
        fundCode: 'ERROR',
        fundName: '数据读取失败',
        fundType: '未知',
        fundManager: '未知',
        addedAt: DateTime.now(),
        sortWeight: 0.0,
        notes: '数据读取时发生错误',
        priceAlerts: null,
        updatedAt: DateTime.now(),
        currentNav: null,
        dailyChange: null,
        previousNav: null,
        establishDate: null,
        fundScale: null,
        isSynced: false,
        cloudId: null,
      );
    }
  }

  @override
  void write(BinaryWriter writer, FundFavorite obj) {
    writer.writeByte(16); // 写入字段数量
    writer.write(obj.fundCode);
    writer.write(obj.fundName);
    writer.write(obj.fundType);
    writer.write(obj.fundManager);
    writer.write(obj.addedAt.toIso8601String());
    writer.write(obj.sortWeight);
    writer.write(obj.notes);
    writer.write(obj.priceAlerts);
    writer.write(obj.updatedAt.toIso8601String());
    writer.write(obj.currentNav);
    writer.write(obj.dailyChange);
    writer.write(obj.previousNav);
    writer.write(obj.establishDate?.toIso8601String());
    writer.write(obj.fundScale);
    writer.write(obj.isSynced);
    writer.write(obj.cloudId);
  }

  /// 安全解析DateTime的方法
  DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      try {
        // 处理空字符串
        if (value.isEmpty) {
          return DateTime.now();
        }
        return DateTime.parse(value);
      } catch (e) {
        // 如果解析失败，返回当前时间
        return DateTime.now();
      }
    }

    // 其他类型返回当前时间
    return DateTime.now();
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FundFavoriteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

/// 价格提醒设置适配器
class PriceAlertSettingsAdapter extends TypeAdapter<PriceAlertSettings> {
  @override
  final int typeId = 11;

  @override
  PriceAlertSettings read(BinaryReader reader) {
    try {
      final numberOfFields = reader.readByte();

      // 防护：限制字段数量，防止恶意或损坏数据导致无限循环
      if (numberOfFields < 0 || numberOfFields > 20) {
        throw FormatException(
            'Invalid field count: $numberOfFields. Expected between 0 and 20.');
      }

      final fields = <int, dynamic>{};
      for (int i = 0; i < numberOfFields; i++) {
        try {
          fields[i] = reader.read();
        } catch (e) {
          throw FormatException('Failed to read field $i: $e');
        }
      }

      return PriceAlertSettings(
        enabled: fields[0] as bool? ?? false,
        riseThreshold: (fields[1] as num?)?.toDouble(),
        fallThreshold: (fields[2] as num?)?.toDouble(),
        targetPrices: (fields[3] as List<dynamic>?)
                ?.map((e) => e as TargetPriceAlert)
                .toList() ??
            [],
        lastAlertTime: fields[4] == null ? null : _parseDateTime(fields[4]),
        alertMethods: (fields[5] as List<dynamic>?)
                ?.map((e) => AlertMethod.values[e as int])
                .toList() ??
            [AlertMethod.push],
      );
    } catch (e) {
      // 如果读取失败，返回一个默认的对象，避免应用崩溃
      return const PriceAlertSettings(
        enabled: false,
        riseThreshold: null,
        fallThreshold: null,
        targetPrices: [],
        lastAlertTime: null,
        alertMethods: [AlertMethod.push],
      );
    }
  }

  @override
  void write(BinaryWriter writer, PriceAlertSettings obj) {
    writer.writeByte(6); // 写入字段数量
    writer.write(obj.enabled);
    writer.write(obj.riseThreshold);
    writer.write(obj.fallThreshold);
    writer.write(obj.targetPrices);
    writer.write(obj.lastAlertTime?.toIso8601String());
    writer.write(obj.alertMethods.map((e) => e.index).toList());
  }

  /// 安全解析DateTime的方法
  DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      try {
        // 处理空字符串
        if (value.isEmpty) {
          return DateTime.now();
        }
        return DateTime.parse(value);
      } catch (e) {
        // 如果解析失败，返回当前时间
        return DateTime.now();
      }
    }

    // 其他类型返回当前时间
    return DateTime.now();
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriceAlertSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

/// 目标价格提醒适配器
class TargetPriceAlertAdapter extends TypeAdapter<TargetPriceAlert> {
  @override
  final int typeId = 12;

  @override
  TargetPriceAlert read(BinaryReader reader) {
    try {
      final numberOfFields = reader.readByte();

      // 防护：限制字段数量，防止恶意或损坏数据导致无限循环
      if (numberOfFields < 0 || numberOfFields > 10) {
        throw FormatException(
            'Invalid field count: $numberOfFields. Expected between 0 and 10.');
      }

      final fields = <int, dynamic>{};
      for (int i = 0; i < numberOfFields; i++) {
        try {
          fields[i] = reader.read();
        } catch (e) {
          throw FormatException('Failed to read field $i: $e');
        }
      }

      return TargetPriceAlert(
        targetPrice: (fields[0] as num?)?.toDouble() ?? 0.0,
        type: fields[1] != null &&
                fields[1] is int &&
                fields[1] < TargetPriceType.values.length
            ? TargetPriceType.values[fields[1] as int]
            : TargetPriceType.reach,
        isActive: fields[2] as bool? ?? true,
        createdAt: _parseDateTime(fields[3]),
      );
    } catch (e) {
      // 如果读取失败，返回一个默认的对象，避免应用崩溃
      return TargetPriceAlert(
        targetPrice: 0.0,
        type: TargetPriceType.exceed,
        isActive: false,
        createdAt: DateTime.now(),
      );
    }
  }

  @override
  void write(BinaryWriter writer, TargetPriceAlert obj) {
    writer.writeByte(4); // 写入字段数量
    writer.write(obj.targetPrice);
    writer.write(obj.type.index);
    writer.write(obj.isActive);
    writer.write(obj.createdAt.toIso8601String());
  }

  /// 安全解析DateTime的方法
  DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      try {
        // 处理空字符串
        if (value.isEmpty) {
          return DateTime.now();
        }
        return DateTime.parse(value);
      } catch (e) {
        // 如果解析失败，返回当前时间
        return DateTime.now();
      }
    }

    // 其他类型返回当前时间
    return DateTime.now();
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TargetPriceAlertAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

/// 自选基金列表适配器
class FundFavoriteListAdapter extends TypeAdapter<FundFavoriteList> {
  @override
  final int typeId = 13;

  @override
  FundFavoriteList read(BinaryReader reader) {
    try {
      final startTime = DateTime.now();

      final numberOfFields = reader.readByte();

      // 防护：限制字段数量，防止恶意或损坏数据导致无限循环
      // FundFavoriteList 应该正好有 17 个字段
      if (numberOfFields < 0 || numberOfFields > 25) {
        throw FormatException(
            'Invalid field count: $numberOfFields. Expected between 0 and 25.');
      }

      // 如果字段数量不是17，记录警告但继续处理
      if (numberOfFields != 17) {
        print('⚠️ FundFavoriteList: 字段数量异常 ($numberOfFields)，期望 17');
      }

      final fields = <int, dynamic>{};
      for (int i = 0; i < numberOfFields; i++) {
        // 超时保护：如果读取时间超过5秒，抛出异常
        if (DateTime.now().difference(startTime).inSeconds > 5) {
          throw TimeoutException(
              '读取 FundFavoriteList 超时', const Duration(seconds: 5));
        }

        try {
          fields[i] = reader.read();
        } catch (e) {
          // 如果单个字段读取失败，使用默认值而不是抛出异常
          print('⚠️ 读取字段 $i 失败，使用默认值: $e');
          fields[i] = _getDefaultFieldValue(i);
        }
      }

      return FundFavoriteList(
        id: fields[0] as String? ?? '',
        name: fields[1] as String? ?? '',
        description: fields[2] as String?,
        createdAt: _parseDateTime(fields[3]),
        updatedAt: _parseDateTime(fields[4]),
        fundCount: fields[5] as int? ?? 0,
        sortConfig:
            fields[6] as SortConfiguration? ?? const SortConfiguration(),
        filterConfig:
            fields[7] as FilterConfiguration? ?? const FilterConfiguration(),
        syncConfig:
            fields[8] as SyncConfiguration? ?? const SyncConfiguration(),
        statistics: fields[9] as ListStatistics? ??
            ListStatistics(statisticsAt: DateTime.now()),
        isDefault: fields[10] as bool? ?? false,
        isEnabled: fields[11] as bool? ?? true,
        iconCode: fields[12] as String?,
        colorTheme: fields[13] as String?,
        isPublic: fields[14] as bool? ?? false,
        shareCode: fields[15] as String?,
        tags: (fields[16] as List<dynamic>?)?.cast<String>() ?? [],
      );
    } catch (e) {
      // 如果读取失败，返回一个默认的对象，避免应用崩溃
      return FundFavoriteList(
        id: 'error_recovery',
        name: '恢复列表',
        description: '数据读取失败时创建的默认列表',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        fundCount: 0,
        sortConfig: const SortConfiguration(),
        filterConfig: const FilterConfiguration(),
        syncConfig: const SyncConfiguration(),
        statistics: ListStatistics(statisticsAt: DateTime.now()),
        isDefault: false,
        isEnabled: true,
        iconCode: null,
        colorTheme: null,
        isPublic: false,
        shareCode: null,
        tags: const [],
      );
    }
  }

  @override
  void write(BinaryWriter writer, FundFavoriteList obj) {
    writer.writeByte(17); // 写入字段数量
    writer.write(obj.id);
    writer.write(obj.name);
    writer.write(obj.description);
    writer.write(obj.createdAt.toIso8601String());
    writer.write(obj.updatedAt.toIso8601String());
    writer.write(obj.fundCount);
    writer.write(obj.sortConfig);
    writer.write(obj.filterConfig);
    writer.write(obj.syncConfig);
    writer.write(obj.statistics);
    writer.write(obj.isDefault);
    writer.write(obj.isEnabled);
    writer.write(obj.iconCode);
    writer.write(obj.colorTheme);
    writer.write(obj.isPublic);
    writer.write(obj.shareCode);
    writer.write(obj.tags);
  }

  /// 安全解析DateTime的方法
  DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      try {
        // 处理空字符串
        if (value.isEmpty) {
          return DateTime.now();
        }
        return DateTime.parse(value);
      } catch (e) {
        // 如果解析失败，返回当前时间
        return DateTime.now();
      }
    }

    // 其他类型返回当前时间
    return DateTime.now();
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FundFavoriteListAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  /// 获取字段的默认值（用于读取失败时的容错处理）
  dynamic _getDefaultFieldValue(int fieldIndex) {
    switch (fieldIndex) {
      case 0:
        return ''; // id
      case 1:
        return ''; // name
      case 2:
        return null; // description
      case 3:
        return DateTime.now().toIso8601String(); // createdAt
      case 4:
        return DateTime.now().toIso8601String(); // updatedAt
      case 5:
        return 0; // fundCount
      case 6:
        return const SortConfiguration(); // sortConfig
      case 7:
        return const FilterConfiguration(); // filterConfig
      case 8:
        return const SyncConfiguration(); // syncConfig
      case 9:
        return ListStatistics(statisticsAt: DateTime.now()); // statistics
      case 10:
        return false; // isDefault
      case 11:
        return true; // isEnabled
      case 12:
        return null; // iconCode
      case 13:
        return null; // colorTheme
      case 14:
        return false; // isPublic
      case 15:
        return null; // shareCode
      case 16:
        return const []; // tags
      default:
        return null;
    }
  }
}

/// 排序配置适配器
class SortConfigurationAdapter extends TypeAdapter<SortConfiguration> {
  @override
  final int typeId = 14;

  @override
  SortConfiguration read(BinaryReader reader) {
    try {
      final numberOfFields = reader.readByte();

      // 防护：限制字段数量
      if (numberOfFields < 0 || numberOfFields > 10) {
        throw FormatException('Invalid field count: $numberOfFields');
      }

      final fields = <int, dynamic>{};
      for (int i = 0; i < numberOfFields; i++) {
        fields[i] = reader.read();
      }

      return SortConfiguration(
        sortType: fields[0] != null &&
                fields[0] is int &&
                fields[0] < FundFavoriteSortType.values.length
            ? FundFavoriteSortType.values[fields[0] as int]
            : FundFavoriteSortType.addTime,
        direction: fields[1] != null &&
                fields[1] is int &&
                fields[1] < FundFavoriteSortDirection.values.length
            ? FundFavoriteSortDirection.values[fields[1] as int]
            : FundFavoriteSortDirection.descending,
        enableCustomSort: fields[2] as bool? ?? false,
      );
    } catch (e) {
      return const SortConfiguration();
    }
  }

  @override
  void write(BinaryWriter writer, SortConfiguration obj) {
    writer.writeByte(3);
    writer.write(obj.sortType.index);
    writer.write(obj.direction.index);
    writer.write(obj.enableCustomSort);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SortConfigurationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

/// 筛选配置适配器
class FilterConfigurationAdapter extends TypeAdapter<FilterConfiguration> {
  @override
  final int typeId = 15;

  @override
  FilterConfiguration read(BinaryReader reader) {
    try {
      final numberOfFields = reader.readByte();
      if (numberOfFields < 0 || numberOfFields > 20) {
        throw FormatException('Invalid field count: $numberOfFields');
      }

      final fields = <int, dynamic>{};
      for (int i = 0; i < numberOfFields; i++) {
        fields[i] = reader.read();
      }

      return FilterConfiguration(
        allowedFundTypes: (fields[0] as List<dynamic>?)?.cast<String>() ?? [],
        minFundScale: (fields[1] as num?)?.toDouble(),
        maxFundScale: (fields[2] as num?)?.toDouble(),
        minEstablishYears: fields[3] as int?,
        onlyWithAlerts: fields[4] as bool? ?? false,
        onlySynced: fields[5] as bool? ?? false,
        customFilters:
            (fields[6] as Map<dynamic, dynamic>?)?.cast<String, dynamic>() ??
                {},
      );
    } catch (e) {
      return const FilterConfiguration();
    }
  }

  @override
  void write(BinaryWriter writer, FilterConfiguration obj) {
    writer.writeByte(7);
    writer.write(obj.allowedFundTypes);
    writer.write(obj.minFundScale);
    writer.write(obj.maxFundScale);
    writer.write(obj.minEstablishYears);
    writer.write(obj.onlyWithAlerts);
    writer.write(obj.onlySynced);
    writer.write(obj.customFilters);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FilterConfigurationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

/// 同步配置适配器
class SyncConfigurationAdapter extends TypeAdapter<SyncConfiguration> {
  @override
  final int typeId = 17;

  @override
  SyncConfiguration read(BinaryReader reader) {
    try {
      final numberOfFields = reader.readByte();
      if (numberOfFields < 0 || numberOfFields > 20) {
        throw FormatException('Invalid field count: $numberOfFields');
      }

      final fields = <int, dynamic>{};
      for (int i = 0; i < numberOfFields; i++) {
        fields[i] = reader.read();
      }

      return SyncConfiguration(
        autoSync: fields[0] as bool? ?? true,
        syncInterval: fields[1] as int? ?? 30,
        wifiOnly: fields[2] as bool? ?? true,
        lastSyncTime: fields[3] == null ? null : _parseDateTime(fields[3]),
        retryCount: fields[4] as int? ?? 0,
        maxRetries: fields[5] as int? ?? 3,
      );
    } catch (e) {
      return const SyncConfiguration();
    }
  }

  @override
  void write(BinaryWriter writer, SyncConfiguration obj) {
    writer.writeByte(6);
    writer.write(obj.autoSync);
    writer.write(obj.syncInterval);
    writer.write(obj.wifiOnly);
    writer.write(obj.lastSyncTime?.toIso8601String());
    writer.write(obj.retryCount);
    writer.write(obj.maxRetries);
  }

  /// 安全解析DateTime的方法
  DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      try {
        // 处理空字符串
        if (value.isEmpty) {
          return DateTime.now();
        }
        return DateTime.parse(value);
      } catch (e) {
        // 如果解析失败，返回当前时间
        return DateTime.now();
      }
    }

    // 其他类型返回当前时间
    return DateTime.now();
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncConfigurationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

/// 列表统计信息适配器
class ListStatisticsAdapter extends TypeAdapter<ListStatistics> {
  @override
  final int typeId = 18;

  @override
  ListStatistics read(BinaryReader reader) {
    try {
      final numberOfFields = reader.readByte();
      if (numberOfFields < 0 || numberOfFields > 20) {
        throw FormatException('Invalid field count: $numberOfFields');
      }

      final fields = <int, dynamic>{};
      for (int i = 0; i < numberOfFields; i++) {
        fields[i] = reader.read();
      }

      return ListStatistics(
        totalProfit: (fields[0] as num?)?.toDouble() ?? 0.0,
        totalProfitRate: (fields[1] as num?)?.toDouble() ?? 0.0,
        dailyProfit: (fields[2] as num?)?.toDouble() ?? 0.0,
        dailyProfitRate: (fields[3] as num?)?.toDouble() ?? 0.0,
        bestPerformingFund: fields[4] as String?,
        worstPerformingFund: fields[5] as String?,
        averageDailyChange: (fields[6] as num?)?.toDouble() ?? 0.0,
        statisticsAt: _parseDateTime(fields[7]),
      );
    } catch (e) {
      return ListStatistics(statisticsAt: DateTime.now());
    }
  }

  /// 安全解析DateTime的方法
  DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      try {
        // 处理空字符串
        if (value.isEmpty) {
          return DateTime.now();
        }
        return DateTime.parse(value);
      } catch (e) {
        // 如果解析失败，返回当前时间
        return DateTime.now();
      }
    }

    // 其他类型返回当前时间
    return DateTime.now();
  }

  @override
  void write(BinaryWriter writer, ListStatistics obj) {
    writer.writeByte(8);
    writer.write(obj.totalProfit);
    writer.write(obj.totalProfitRate);
    writer.write(obj.dailyProfit);
    writer.write(obj.dailyProfitRate);
    writer.write(obj.bestPerformingFund);
    writer.write(obj.worstPerformingFund);
    writer.write(obj.averageDailyChange);
    writer.write(obj.statisticsAt.toString());
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListStatisticsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
