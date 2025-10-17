/// 图表组件库导出文件
///
/// 统一导出所有图表相关的类和工具，提供简洁的导入接口
library charts;

// 核心组件
export 'base_chart_widget.dart';
export 'chart_theme_manager.dart';
export 'chart_config_manager.dart';
export 'chart_di_container.dart';

// 数据模型
export 'models/chart_data.dart';

// 具体图表组件
export 'line_chart_widget.dart';
export 'bar_chart_widget.dart';
export 'pie_chart_widget.dart';

// 服务和数据
export 'services/chart_data_service.dart';

// 示例页面
export 'examples/real_fund_chart_example.dart';
