# 基速 (JiSu) - 基金探索页面UI设计文档

## 1. 设计概述

### 1.1 设计理念
基金探索页面的UI设计遵循"专业、简洁、高效"的原则，以金融投资场景为核心，提供直观的数据展示和流畅的交互体验。

### 1.2 设计目标
- **专业性**: 体现金融产品的专业属性，数据展示清晰准确
- **易用性**: 操作简单直观，降低用户学习成本
- **一致性**: 保持整体视觉风格统一，建立品牌认知
- **响应式**: 适配不同屏幕尺寸，确保多设备体验一致

### 1.3 色彩系统
```dart
// 主色调 - 专业蓝
const Color primaryBlue = Color(0xFF1E40AF);      // 主品牌色
const Color primaryLight = Color(0xFF3B82F6);     // 浅色变体
const Color primaryDark = Color(0xFF1E3A8A);      // 深色变体

// 功能色彩 - 涨跌色
const Color colorUp = Color(0xFFEF4444);          // 红色 - 上涨
const Color colorDown = Color(0xFF10B981);        // 绿色 - 下跌
const Color colorFlat = Color(0xFF6B7280);        // 灰色 - 持平

// 中性色
const Color gray50 = Color(0xFFF9FAFB);
const Color gray100 = Color(0xFFF3F4F6);
const Color gray200 = Color(0xFFE5E7EB);
const Color gray300 = Color(0xFFD1D5DB);
const Color gray400 = Color(0xFF9CA3AF);
const Color gray500 = Color(0xFF6B7280);
const Color gray600 = Color(0xFF4B5563);
const Color gray700 = Color(0xFF374151);
const Color gray800 = Color(0xFF1F2937);
const Color gray900 = Color(0xFF111827);

// 状态色
const Color success = Color(0xFF10B981);
const Color warning = Color(0xFFF59E0B);
const Color error = Color(0xFFEF4444);
const Color info = Color(0xFF3B82F6);
```

## 2. 页面布局架构

### 2.1 基金探索页面整体布局结构
```
┌─────────────────────────────────────────────────────────────┐
│                    顶部交互区域 (80px)                      │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ 搜索栏         │ 筛选条件组         │ 排序选择器      │  │
│  └───────────────────────────────────────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────┬──────────────────────────────────┐  │
│  │                     │                                    │  │
│  │   分类导航区域      │      核心内容区域                  │  │
│  │   (240px)          │      (自适应)                      │  │
│  │                     │                                    │  │
│  │  ┌───────────────┐ │                                    │  │
│  │  │ 基金类型导航  │ │      热门基金推荐                  │  │
│  │  │               │ │      (320px)                       │  │
│  │  └───────────────┘ │                                    │  │
│  │                     │                                    │  │
│  │  ┌───────────────┐ │      基金排行榜                    │  │
│  │  │ 投资策略导航  │ │      (自适应)                      │  │
│  │  │               │ │                                    │  │
│  │  └───────────────┘ │                                    │  │
│  │                     │                                    │  │
│  │  ┌───────────────┐ │      市场动态                      │  │
│  │  │ 市场动态导航  │ │      (240px)                       │  │
│  │  │               │ │                                    │  │
│  │  └───────────────┘ │                                    │  │
│  │                     │                                    │  │
│  │  ┌───────────────┐ │      工具与分析区域                │  │
│  │  │ 工具分析导航  │ │      (300px)                       │  │
│  │  │               │ │                                    │  │
│  │  └───────────────┘ └──────────────────────────────────┘  │
│  └─────────────────────┘                                    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 响应式布局断点
```dart
// 断点定义
class Breakpoints {
  static const double mobile = 480;      // 手机端
  static const double tablet = 768;      // 平板端  
  static const double desktop = 1024;    // 桌面端
  static const double large = 1440;      // 大屏端
}

// 布局适配策略
class ResponsiveLayout {
  // 手机端：单列布局
  Widget buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SearchFilterSection(),    // 搜索筛选
          HotFundsSection(),        // 热门基金
          FundRankingsSection(),    // 基金排行
          MarketDynamicsSection(),  // 市场动态
          ToolsAnalysisSection(),   // 工具分析
        ],
      ),
    );
  }
  
  // 平板端：两列布局
  Widget buildTabletLayout() {
    return Row(
      children: [
        Flexible(flex: 1, child: LeftNavigation()), // 左侧导航
        Flexible(flex: 3, child: RightContent()),   // 右侧内容
      ],
    );
  }
  
  // 桌面端：三列布局
  Widget buildDesktopLayout() {
    return Row(
      children: [
        SizedBox(width: 240, child: LeftNavigation()), // 固定宽度导航
        Expanded(child: MainContent()),                // 主内容区
        SizedBox(width: 300, child: RightSidebar()),   // 右侧工具栏
      ],
    );
  }
}
```

## 3. 组件设计规范

### 3.1 顶部搜索筛选区域

#### 搜索栏组件
```dart
class FundSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSearch;
  final VoidCallback onAdvancedFilter;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: gray200),
        boxShadow: [
          BoxShadow(
            color: gray100.withOpacity(0.5),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 搜索图标
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Icon(Icons.search, color: gray400, size: 20),
          ),
          
          // 搜索输入框
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: '搜索基金名称、代码、基金经理、基金公司',
                hintStyle: TextStyle(color: gray400, fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(fontSize: 14, color: gray700),
              onSubmitted: onSearch,
            ),
          ),
          
          // 高级筛选按钮
          Container(
            width: 1,
            height: 24,
            color: gray200,
          ),
          
          IconButton(
            icon: Icon(Icons.filter_list, color: primaryBlue, size: 20),
            onPressed: onAdvancedFilter,
            tooltip: '高级筛选',
          ),
        ],
      ),
    );
  }
}
```

#### 高级筛选面板
```dart
class AdvancedFilterPanel extends StatelessWidget {
  final FundFilter filters;
  final Function(FundFilter) onFiltersChanged;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: gray200),
        boxShadow: [
          BoxShadow(
            color: gray100.withOpacity(0.5),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 基金类型筛选
          _buildFilterSection(
            title: '基金类型',
            options: ['股票型', '债券型', '混合型', '货币型', '指数型', 'QDII'],
            selected: filters.fundTypes,
            onChanged: (types) => onFiltersChanged(filters.copyWith(fundTypes: types)),
          ),
          
          SizedBox(height: 16),
          
          // 风险等级筛选
          _buildFilterSection(
            title: '风险等级',
            options: ['R1', 'R2', 'R3', 'R4', 'R5'],
            selected: filters.riskLevels,
            onChanged: (levels) => onFiltersChanged(filters.copyWith(riskLevels: levels)),
          ),
          
          SizedBox(height: 16),
          
          // 基金规模筛选
          _buildRangeFilter(
            title: '基金规模',
            minLabel: '0亿',
            maxLabel: '1000亿+',
            values: RangeValues(filters.minScale ?? 0, filters.maxScale ?? 1000),
            onChanged: (range) => onFiltersChanged(filters.copyWith(
              minScale: range.start,
              maxScale: range.end,
            )),
          ),
          
          SizedBox(height: 16),
          
          // 成立时间筛选
          _buildDateRangeFilter(
            title: '成立时间',
            startDate: filters.establishStart,
            endDate: filters.establishEnd,
            onStartChanged: (date) => onFiltersChanged(filters.copyWith(establishStart: date)),
            onEndChanged: (date) => onFiltersChanged(filters.copyWith(establishEnd: date)),
          ),
          
          SizedBox(height: 20),
          
          // 操作按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => onFiltersChanged(FundFilter()),
                child: Text('重置', style: TextStyle(color: gray600)),
              ),
              SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('确定', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

### 3.2 基金卡片组件

#### 基金信息卡片
```dart
class FundCard extends StatelessWidget {
  final Fund fund;
  final VoidCallback? onTap;
  final bool showComparisonCheckbox;
  final bool isSelected;
  final Function(bool)? onSelectionChanged;
  
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? primaryBlue : gray200,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: gray100.withOpacity(0.5),
                blurRadius: isSelected ? 12 : 8,
                offset: Offset(0, isSelected ? 4 : 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 顶部信息区域
                      Row(
                        children: [
                          // 基金类型标签
                          _buildFundTypeTag(fund.type),
                          
                          SizedBox(width: 8),
                          
                          // 基金代码
                          Text(
                            fund.code,
                            style: TextStyle(
                              fontSize: 12,
                              color: gray500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          
                          Spacer(),
                          
                          // 对比选择框
                          if (showComparisonCheckbox)
                            Checkbox(
                              value: isSelected,
                              onChanged: (value) => onSelectionChanged?.call(value ?? false),
                              activeColor: primaryBlue,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                        ],
                      ),
                      
                      SizedBox(height: 8),
                      
                      // 基金名称
                      Text(
                        fund.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: gray800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      SizedBox(height: 4),
                      
                      // 基金经理和公司
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 14, color: gray500),
                          SizedBox(width: 4),
                          Text(
                            fund.manager,
                            style: TextStyle(fontSize: 13, color: gray600),
                          ),
                          SizedBox(width: 12),
                          Icon(Icons.business_outline, size: 14, color: gray500),
                          SizedBox(width: 4),
                          Text(
                            fund.company,
                            style: TextStyle(fontSize: 13, color: gray600),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 12),
                      
                      // 关键指标区域
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 近一年收益率
                          _buildReturnIndicator(
                            label: '近一年收益',
                            value: fund.return1Y,
                            isPercentage: true,
                          ),
                          
                          // 基金规模
                          _buildInfoIndicator(
                            label: '基金规模',
                            value: '${fund.scale}亿',
                          ),
                          
                          // 风险等级
                          _buildRiskIndicator(fund.riskLevel),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // 悬停效果
                Positioned.fill(
                  child: AnimatedOpacity(
                    duration: Duration(milliseconds: 200),
                    opacity: 0, // 通过MouseRegion控制
                    child: Container(
                      decoration: BoxDecoration(
                        color: primaryBlue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildFundTypeTag(String type) {
    final color = _getFundTypeColor(type);
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  
  Widget _buildReturnIndicator({
    required String label,
    required double value,
    bool isPercentage = false,
  }) {
    final isPositive = value > 0;
    final color = isPositive ? colorUp : colorDown;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: gray500),
        ),
        SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              isPositive ? '+' : '',
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              value.toStringAsFixed(2),
              style: TextStyle(
                fontSize: 18,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (isPercentage)
              Text(
                '%',
                style: TextStyle(
                  fontSize: 14,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildInfoIndicator({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: gray500),
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            color: gray800,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
  
  Widget _buildRiskIndicator(String riskLevel) {
    final level = int.tryParse(riskLevel.replaceAll('R', '')) ?? 3;
    final color = _getRiskColor(level);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '风险等级',
          style: TextStyle(fontSize: 12, color: gray500),
        ),
        SizedBox(height: 4),
        Row(
          children: List.generate(5, (index) {
            return Container(
              width: 8,
              height: 8,
              margin: EdgeInsets.only(right: 2),
              decoration: BoxDecoration(
                color: index < level ? color : gray200,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
        SizedBox(height: 2),
        Text(
          riskLevel,
          style: TextStyle(fontSize: 11, color: color),
        ),
      ],
    );
  }
  
  Color _getFundTypeColor(String type) {
    switch (type) {
      case '股票型': return Color(0xFFEF4444);
      case '债券型': return Color(0xFF10B981);
      case '混合型': return Color(0xFFF59E0B);
      case '货币型': return Color(0xFF3B82F6);
      case '指数型': return Color(0xFF8B5CF6);
      default: return gray500;
    }
  }
  
  Color _getRiskColor(int level) {
    if (level <= 2) return success;
    if (level <= 3) return warning;
    return error;
  }
}
```

### 3.3 排行榜组件

#### 基金排行榜表格
```dart
class FundRankingTable extends StatelessWidget {
  final List<FundRanking> rankings;
  final String selectedPeriod;
  final Function(String) onPeriodChanged;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: gray200),
      ),
      child: Column(
        children: [
          // 表头区域
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: gray50,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(bottom: BorderSide(color: gray200)),
            ),
            child: Row(
              children: [
                // 时间周期选择
                _buildPeriodSelector(),
                
                Spacer(),
                
                // 导出按钮
                TextButton.icon(
                  onPressed: () => _exportRankings(),
                  icon: Icon(Icons.download, size: 16, color: primaryBlue),
                  label: Text('导出', style: TextStyle(color: primaryBlue)),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: BorderSide(color: primaryBlue),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 表格头部
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: gray200)),
            ),
            child: Row(
              children: [
                SizedBox(width: 40, child: Text('排名', style: _headerTextStyle)),
                SizedBox(width: 80, child: Text('基金代码', style: _headerTextStyle)),
                Expanded(child: Text('基金名称', style: _headerTextStyle)),
                SizedBox(width: 80, child: Text('近1周', style: _headerTextStyle, textAlign: TextAlign.right)),
                SizedBox(width: 80, child: Text('近1月', style: _headerTextStyle, textAlign: TextAlign.right)),
                SizedBox(width: 80, child: Text('近3月', style: _headerTextStyle, textAlign: TextAlign.right)),
                SizedBox(width: 80, child: Text('近1年', style: _headerTextStyle, textAlign: TextAlign.right)),
                SizedBox(width: 80, child: Text('今年来', style: _headerTextStyle, textAlign: TextAlign.right)),
                SizedBox(width: 100, child: Text('成立来', style: _headerTextStyle, textAlign: TextAlign.right)),
              ],
            ),
          ),
          
          // 表格内容
          ...rankings.asMap().map((index, ranking) {
            return MapEntry(index, _buildRankingRow(ranking, index + 1));
          }).values.toList(),
        ],
      ),
    );
  }
  
  Widget _buildRankingRow(FundRanking ranking, int position) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: position % 2 == 0 ? gray50 : Colors.white,
        border: Border(bottom: BorderSide(color: gray100)),
      ),
      child: Row(
        children: [
          // 排名
          SizedBox(
            width: 40,
            child: Row(
              children: [
                _buildRankingBadge(position),
                SizedBox(width: 8),
                Text(
                  position.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _getRankingColor(position),
                  ),
                ),
              ],
            ),
          ),
          
          // 基金代码
          SizedBox(
            width: 80,
            child: Text(
              ranking.fundCode,
              style: TextStyle(fontSize: 13, color: gray600),
            ),
          ),
          
          // 基金名称
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ranking.fundName,
                  style: TextStyle(fontWeight: FontWeight.w500, color: gray800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  '${ranking.fundType} | ${ranking.company}',
                  style: TextStyle(fontSize: 12, color: gray500),
                ),
              ],
            ),
          ),
          
          // 收益率数据
          _buildReturnCell(ranking.return1W, width: 80),
          _buildReturnCell(ranking.return1M, width: 80),
          _buildReturnCell(ranking.return3M, width: 80),
          _buildReturnCell(ranking.return1Y, width: 80),
          _buildReturnCell(ranking.returnYTD, width: 80),
          _buildReturnCell(ranking.returnSinceInception, width: 100),
        ],
      ),
    );
  }
  
  Widget _buildReturnCell(double? returnValue, {required double width}) {
    if (returnValue == null) {
      return SizedBox(
        width: width,
        child: Text('--', style: TextStyle(color: gray400), textAlign: TextAlign.right),
      );
    }
    
    final isPositive = returnValue > 0;
    final color = isPositive ? colorUp : colorDown;
    
    return SizedBox(
      width: width,
      child: Text(
        '${isPositive ? '+' : ''}${returnValue.toStringAsFixed(2)}%',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }
  
  Widget _buildRankingBadge(int position) {
    if (position <= 3) {
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: _getRankingBadgeColor(position),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            position.toString(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
    
    return SizedBox(width: 20);
  }
  
  Color _getRankingBadgeColor(int position) {
    switch (position) {
      case 1: return Color(0xFFFFD700); // 金色
      case 2: return Color(0xFFC0C0C0); // 银色
      case 3: return Color(0xFFCD7F32); // 铜色
      default: return gray400;
    }
  }
  
  Color _getRankingColor(int position) {
    if (position <= 3) return primaryBlue;
    if (position <= 10) return success;
    if (position <= 50) return warning;
    return gray600;
  }
  
  Widget _buildPeriodSelector() {
    final periods = ['近1周', '近1月', '近3月', '近6月', '近1年', '今年来', '成立来'];
    
    return Container(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        itemCount: periods.length,
        separatorBuilder: (context, index) => SizedBox(width: 8),
        itemBuilder: (context, index) {
          final period = periods[index];
          final isSelected = period == selectedPeriod;
          
          return ChoiceChip(
            label: Text(period, style: TextStyle(fontSize: 12)),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) onPeriodChanged(period);
            },
            selectedColor: primaryBlue.withOpacity(0.1),
            backgroundColor: gray100,
            labelStyle: TextStyle(
              color: isSelected ? primaryBlue : gray600,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isSelected ? primaryBlue : Colors.transparent,
              ),
            ),
          );
        },
      ),
    );
  }
  
  TextStyle get _headerTextStyle => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: gray600,
  );
}
```

## 核心页面设计

### 1. 基金探索首页 (Fund Discovery Dashboard)

**功能目标**：提供市场概览和用户关注的核心指标

**布局设计**：

text

```
+----------------------------------------------------------------+
| 市场指数快照 (沪深300、上证指数、创业板指等)                   |
+----------------------------------------------------------------+
| 自选基金表现                 | 市场热点/新闻                   |
| +-----------------------+   | +---------------------------+   |
| | 基金1  +2.5%          |   | | 新闻标题1                 |   |
| | 基金2  -1.2%          |   | | 新闻标题2                 |   |
| | 基金3  +0.8%          |   | | 新闻标题3                 |   |
| +-----------------------+   | +---------------------------+   |
+----------------------------------------------------------------+
| 近期表现最佳基金 (排行榜前5)                                   |
+----------------------------------------------------------------+
```

**交互说明**：

- 市场指数可点击查看详细走势
- 自选基金项可点击跳转到基金详情
- 新闻项可点击查看全文
- 排行榜可切换不同时间周期(1月/3月/1年)

### 2. 基金详情页

**功能目标**：展示单只基金的全面信息和数据分析

**布局设计**：

text

```gr
+----------------------------------------------------------------+
| 基金基本信息区 (代码、名称、类型、公司、当前净值、日变化)      |
+----------------------------------------------------------------+
| 选项卡导航 [概览 | 历史净值 | 持仓分析 | 指标分析 | 同类对比]  |
+----------------------------------------------------------------+
| 内容区 (根据选项卡动态变化)                                    |
|                                                                |
| [概览选项卡]                                                  |
| +-------------------------+-----------------------------------+ |
| | 净值走势图 (可选周期)   | 关键指标卡片                      | |
| |                         | - 今年来收益                      | |
| |                         | - 近1年收益                       | |
| |                         | - 夏普比率                        | |
| |                         | - 最大回撤                        | |
| +-------------------------+-----------------------------------+ |
| |             基金档案信息 (经理、规模、费率等)               | |
| +-------------------------------------------------------------+ |
|                                                                |
+----------------------------------------------------------------+
```

**交互说明**：

- 图表支持鼠标悬停显示具体数值
- 图表时间周期可切换(1月/3月/1年/最大)
- 指标卡片可点击查看计算方法和详细解释
- 支持添加到自选/从自选移除操作

### 3. 自选基金页面

**功能目标**：管理并快速查看用户关注的基金

**布局设计**：

text

```
+----------------------------------------------------------------+
| 操作栏 [添加基金 | 创建分组 | 编辑分组 | 导出数据]             |
+----------------------------------------------------------------+
| 分组选项卡 [所有 | 股票型 | 混合型 | 债券型 | 自定义分组...]   |
+----------------------------------------------------------------+
| 基金列表 (表格形式)                                            |
| +--------+---------+-------+----------+-----------+-----------+ |
| | 选中   | 基金名称 | 最新净值 | 日涨跌 | 近1月收益 | 操作     | |
| +--------+---------+-------+----------+-----------+-----------+ |
| | □      | 基金A   | 1.235  | +1.25%   | +5.67%    | ⋮ (菜单) | |
| | □      | 基金B   | 2.104  | -0.87%   | -2.34%    | ⋮ (菜单) | |
| | □      | 基金C   | 3.456  | +0.23%   | +8.91%    | ⋮ (菜单) | |
| +--------+---------+-------+----------+-----------+-----------+ |
+----------------------------------------------------------------+
| 批量操作栏 [删除选中 | 移动到分组...] (当选择基金时显示)       |
+----------------------------------------------------------------+
```

**交互说明**：

- 表格支持点击列头排序
- 表格支持拖拽调整列宽
- 支持多选基金进行批量操作
- 可通过拖拽调整基金在不同分组间的归属

### 4. 基金探索/发现页面

**功能目标**：帮助用户发现新的投资机会

**布局设计**：

text

```
+----------------------------------------------------------------+
| 搜索框 (实时搜索基金代码/名称)                                |
+----------------------------------------------------------------+
| 筛选条件栏 [基金类型 | 风险等级 | 业绩表现 | 基金公司 | 更多]  |
+----------------------------------------------------------------+
| 排序选项 [按收益排序 | 按风险排序 | 按规模排序 | 综合评分]     |
+----------------------------------------------------------------+
| 基金网格列表                                                   |
| +-----------------+  +-----------------+  +-----------------+  |
| | 基金卡片        |  | 基金卡片        |  | 基金卡片        |  |
| | 名称/代码       |  | 名称/代码       |  | 名称/代码       |  |
| | 净值/日变化     |  | 净值/日变化     |  | 净值/日变化     |  |
| | 近1年收益       |  | 近1年收益       |  | 近1年收益       |  |
| | 添加自选按钮    |  | 添加自选按钮    |  | 添加自选按钮    |  |
| +-----------------+  +-----------------+  +-----------------+  |
+----------------------------------------------------------------+
| 分页控件                                                       |
+----------------------------------------------------------------+
```

**交互说明**：

- 搜索框支持实时显示搜索结果
- 筛选条件可使用多选和范围选择
- 基金卡片悬停显示更多信息
- 点击基金卡片跳转到详情页

### 5. 设置页面

**功能目标**：管理应用配置和用户偏好

**布局设计**：

text

```
+----------------------------------------------------------------+
| 设置导航侧边栏                                                 |
| +-----------------------+                                     |
| | 通用设置             |                                     |
| | 数据设置             |                                     |
| | 通知设置             |                                     |
| | 外观设置             |                                     |
| | 账号设置             |                                     |
| | 关于应用             |                                     |
| +-----------------------+                                     |
+----------------------------------------------------------------+
| 设置内容区                                                     |
|                                                                |
| [通用设置选项卡]                                              |
| +-------------------------------------------------------------+ |
| | 语言选择: [中文] ▽                                         | |
| | 货币单位: [人民币] ▽                                       | |
| | 日期格式: [年-月-日] ▽                                     | |
| | 数字格式: [千分位分隔] ☑                                   | |
| | 自动检查更新: ☑                                            | |
| +-------------------------------------------------------------+ |
|                                                                |
+----------------------------------------------------------------+
```

## 组件设计规范

### 数据表格

- 表头固定，内容可滚动
- 支持列排序（点击表头）
- 支持调整列宽（拖拽列边界）
- 奇偶行使用轻微背景色区别提高可读性
- 数值正负使用颜色区分（红/绿）

### 图表组件

- 统一使用深色系图表提高可读性
- 悬停显示数据点详细信息
- 支持图例显示/隐藏数据系列
- 时间轴支持缩放和平移

### 卡片设计

- 统一圆角：8px
- 阴影：轻微阴影提升层次感
- 内边距：16px
- 标题与内容区分明显

### 表单控件

- 输入框：有焦点时显示明显边框
- 下拉选择：清晰展示当前选项
- 按钮：主要操作使用主色，次要操作使用边框样式
- 开关：明确的开/关状态表示

## 交互状态设计

### 加载状态

- 页面级加载：骨架屏效果
- 组件级加载：旋转指示器或进度条
- 数据刷新：轻微闪烁提示或顶部进度条

### 空状态

- 无自选基金：插画+提示文字+引导操作按钮
- 无搜索结果：提示调整搜索条件
- 无网络连接：离线提示+重试按钮

### 错误状态

- API错误：友好错误提示+重试机制
- 数据异常：明确标识异常数据点

## 动效设计原则

### 微交互

- 按钮点击：轻微压感效果
- 页面切换：平滑过渡动画
- 数据更新：数字变化使用计数动画

### 功能动效

- 侧边栏展开/收起：平滑宽度变化
- 模态框出现：轻微缩放和淡入
- 列表更新：项添加/删除使用淡入淡出

## 可访问性考虑

### 视觉辅助

- 支持系统字体大小调整
- 高对比度模式支持
- 色盲友好配色方案

### 键盘导航

- 支持全键盘操作
- 明确焦点指示器
- 合理Tab键顺序

## 设计交付物

### 1. Figma/Adobe XD设计文件

- 完整页面设计
- 组件库与样式定义
- 交互原型

### 2. 设计规范文档

- 颜色、字体、间距系统
- 组件使用指南
- 动效规范

### 3. 资源导出

- 图标SVG文件
- 插画资源
- 高保真原型演示

## 下一步计划

1. 完成所有核心页面的高保真设计
2. 创建交互原型进行可用性测试
3. 与开发团队协作实现设计系统
4. 根据用户反馈迭代优化设计

此UI设计文档为"基速"桌面端应用提供了全面的设计指导，确保了用户体验的一致性和专业性。设计特别注重金融数据的清晰展示和高效操作，符合量化分析软件的专业定位。