import '../../data/interfaces/i_data_router.dart';

/// 智能数据源切换器接口
abstract class IIntelligentDataSourceSwitcher {
  /// 初始化切换器
  Future<void> initialize();

  /// 获取状态报告
  DataSourceStatusReport getStatusReport();

  /// 数据源切换事件
  Stream<DataSourceSwitchedEvent> get onDataSourceSwitched;
}

/// 数据源状态报告
class DataSourceStatusReport {
  final DataSource currentSource;
  final double averageResponseTime;
  final int errorCount;

  const DataSourceStatusReport({
    required this.currentSource,
    required this.averageResponseTime,
    required this.errorCount,
  });
}

/// 数据源切换事件
class DataSourceSwitchedEvent {
  final DataSource oldSource;
  final DataSource newSource;
  final String reason;

  const DataSourceSwitchedEvent({
    required this.oldSource,
    required this.newSource,
    required this.reason,
  });
}
