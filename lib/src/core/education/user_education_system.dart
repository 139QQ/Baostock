// ignore_for_file: unused_field, prefer_final_fields, prefer_const_constructors, public_member_api_docs, sort_constructors_first

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../interactions/gesture_system.dart';
import '../performance/performance_detector.dart';
import '../theme/design_tokens/app_colors.dart';
import '../theme/design_tokens/app_spacing.dart';
import '../theme/design_tokens/app_typography.dart';

/// 用户教育系统
/// 提供智能的用户引导、教程、帮助文档等功能
class UserEducationSystem {
  /// 创建单例实例的私有构造函数
  UserEducationSystem._();

  static UserEducationSystem? _instance;
  static UserEducationSystem get instance =>
      _instance ??= UserEducationSystem._();

  // 教育状态
  bool _isFirstLaunch = true;
  bool _showTips = true;
  bool _showGuides = true;
  int _tutorialStep = 0;
  final List<String> _completedTutorials = <String>[];

  // 性能相关
  PerformanceLevel _currentPerformanceLevel = PerformanceLevel.good;
  StreamSubscription<PerformanceResult>? _performanceSubscription;

  // 教育内容
  final Map<String, TutorialContent> _tutorialContents = {};
  final List<TipContent> _dailyTips = [];
  final List<GuideContent> _contextualGuides = [];

  /// 初始化教育系统
  Future<void> initialize() async {
    await _loadUserProgress();
    await _initializePerformanceMonitoring();
    await _generateTutorialContents();
    await _generateDailyTips();
    await _generateContextualGuides();
  }

  Future<void> _loadUserProgress() async {
    // 这里应该从本地存储加载用户进度
    // 目前使用模拟数据
    _isFirstLaunch = true;
    _showTips = true;
    _showGuides = true;
    _completedTutorials.clear();
  }

  Future<void> _initializePerformanceMonitoring() async {
    _performanceSubscription = SmartPerformanceDetector.instance
        .detectPerformance()
        .asStream()
        .listen((result) {
      _currentPerformanceLevel = result.level;
    });
  }

  Future<void> _generateTutorialContents() async {
    // 基础操作教程
    _tutorialContents['basic_navigation'] = TutorialContent(
      id: 'basic_navigation',
      title: '基础导航',
      description: '学习应用的基本导航操作',
      steps: [
        TutorialStep(
          title: '主界面导航',
          description: '使用侧边栏或底部导航栏访问不同功能模块',
          highlightArea: const Rect.fromLTWH(0, 0, 200, 60),
          gestureTypes: const [GestureType.singleTap],
        ),
        TutorialStep(
          title: '基金搜索',
          description: '点击搜索框，输入基金代码或名称进行搜索',
          highlightArea: const Rect.fromLTWH(50, 70, 300, 40),
          gestureTypes: const [GestureType.singleTap],
        ),
        TutorialStep(
          title: '查看详情',
          description: '点击基金卡片查看详细信息',
          highlightArea: const Rect.fromLTWH(20, 120, 350, 100),
          gestureTypes: const [GestureType.singleTap],
        ),
      ],
      estimatedDuration: const Duration(minutes: 3),
      difficulty: TutorialDifficulty.beginner,
    );

    // 手势操作教程
    _tutorialContents['gesture_operations'] = TutorialContent(
      id: 'gesture_operations',
      title: '手势操作',
      description: '学习各种快捷手势操作',
      steps: [
        TutorialStep(
          title: '左滑收藏',
          description: '向左滑动基金卡片可快速添加到收藏夹',
          highlightArea: const Rect.fromLTWH(20, 120, 350, 100),
          gestureTypes: const [GestureType.swipeLeft],
        ),
        TutorialStep(
          title: '右滑对比',
          description: '向右滑动基金卡片可添加到对比列表',
          highlightArea: const Rect.fromLTWH(20, 120, 350, 100),
          gestureTypes: const [GestureType.swipeRight],
        ),
        TutorialStep(
          title: '双击操作',
          description: '双击基金卡片可快速收藏或查看详情',
          highlightArea: const Rect.fromLTWH(20, 120, 350, 100),
          gestureTypes: const [GestureType.doubleTap],
        ),
        TutorialStep(
          title: '长按菜单',
          description: '长按基金卡片显示更多操作选项',
          highlightArea: const Rect.fromLTWH(20, 120, 350, 100),
          gestureTypes: const [GestureType.longPress],
        ),
      ],
      estimatedDuration: const Duration(minutes: 5),
      difficulty: TutorialDifficulty.intermediate,
    );

    // 高级功能教程
    _tutorialContents['advanced_features'] = TutorialContent(
      id: 'advanced_features',
      title: '高级功能',
      description: '学习数据分析和高级功能',
      steps: [
        TutorialStep(
          title: '图表交互',
          description: '学习如何与图表进行交互，缩放、滑动查看历史数据',
          highlightArea: const Rect.fromLTWH(0, 200, 400, 300),
          gestureTypes: const [
            GestureType.pinch,
            GestureType.swipeLeft,
            GestureType.swipeRight
          ],
        ),
        TutorialStep(
          title: '数据筛选',
          description: '使用筛选器快速找到符合条件的基金',
          highlightArea: const Rect.fromLTWH(300, 50, 100, 40),
          gestureTypes: const [GestureType.singleTap],
        ),
        TutorialStep(
          title: '语音控制',
          description: '使用语音命令快速操作应用（如设备支持）',
          highlightArea: const Rect.fromLTWH(350, 10, 30, 30),
          gestureTypes: const [],
        ),
      ],
      estimatedDuration: const Duration(minutes: 7),
      difficulty: TutorialDifficulty.advanced,
    );
  }

  Future<void> _generateDailyTips() async {
    _dailyTips.addAll([
      const TipContent(
        id: 'tip_001',
        title: '快速收藏',
        content: '双击基金卡片可以快速添加到收藏夹',
        category: TipCategory.productivity,
        icon: Icons.favorite,
        priority: TipPriority.high,
      ),
      const TipContent(
        id: 'tip_002',
        title: '语音搜索',
        content: '点击麦克风图标可以使用语音搜索基金',
        category: TipCategory.feature,
        icon: Icons.mic,
        priority: TipPriority.medium,
      ),
      const TipContent(
        id: 'tip_003',
        title: '手势导航',
        content: '左右滑动可以快速切换页面',
        category: TipCategory.navigation,
        icon: Icons.swipe,
        priority: TipPriority.medium,
      ),
      const TipContent(
        id: 'tip_004',
        title: '数据刷新',
        content: '下拉列表可以刷新最新的基金数据',
        category: TipCategory.data,
        icon: Icons.refresh,
        priority: TipPriority.high,
      ),
      const TipContent(
        id: 'tip_005',
        title: '批量操作',
        content: '长按基金卡片进入批量选择模式',
        category: TipCategory.productivity,
        icon: Icons.checklist,
        priority: TipPriority.low,
      ),
    ]);
  }

  Future<void> _generateContextualGuides() async {
    _contextualGuides.addAll([
      const GuideContent(
        id: 'guide_fund_details',
        title: '基金详情页指南',
        context: 'fund_details_page',
        content: '在基金详情页面，您可以查看基金的完整信息，包括历史表现、持仓分析等。',
        steps: [
          '查看净值走势图',
          '了解基金持仓',
          '查看历史分红',
          '阅读基金公告',
        ],
      ),
      const GuideContent(
        id: 'guide_comparison',
        title: '基金对比指南',
        context: 'comparison_page',
        content: '对比页面帮助您同时分析多只基金的表现。',
        steps: [
          '添加要对比的基金',
          '查看对比图表',
          '分析收益差异',
          '导出对比报告',
        ],
      ),
      const GuideContent(
        id: 'guide_portfolio',
        title: '投资组合指南',
        context: 'portfolio_page',
        content: '投资组合页面展示您的整体投资状况和收益分析。',
        steps: [
          '查看总资产',
          '分析收益分布',
          '风险评估',
          '优化建议',
        ],
      ),
    ]);
  }

  /// 检查是否为首次启动
  bool get isFirstLaunch => _isFirstLaunch;

  /// 开始欢迎教程
  TutorialSession startWelcomeTutorial() {
    if (!_isFirstLaunch) return TutorialSession.empty();

    _isFirstLaunch = false;
    return TutorialSession(
      content: _tutorialContents['basic_navigation']!,
      onComplete: () {
        _completedTutorials.add('basic_navigation');
        _saveUserProgress();
      },
    );
  }

  /// 开始特定教程
  TutorialSession startTutorial(String tutorialId) {
    final content = _tutorialContents[tutorialId];
    if (content == null) return TutorialSession.empty();

    return TutorialSession(
      content: content,
      onComplete: () {
        _completedTutorials.add(tutorialId);
        _saveUserProgress();
      },
    );
  }

  /// 获取每日提示
  TipContent getDailyTip() {
    if (_dailyTips.isEmpty) return _createDefaultTip();

    final now = DateTime.now();
    final seed = now.day + now.month * 31;
    final random = Random(seed);
    final index = random.nextInt(_dailyTips.length);
    return _dailyTips[index];
  }

  /// 获取上下文指南
  GuideContent? getContextualGuide(String context) {
    try {
      return _contextualGuides.firstWhere((guide) => guide.context == context);
    } catch (e) {
      return null;
    }
  }

  /// 检查教程是否完成
  bool isTutorialCompleted(String tutorialId) {
    return _completedTutorials.contains(tutorialId);
  }

  /// 获取完成的教程列表
  List<String> get completedTutorials => List.unmodifiable(_completedTutorials);

  /// 保存用户进度
  Future<void> _saveUserProgress() async {
    // 这里应该保存到本地存储
    print('保存用户进度: 完成教程 ${_completedTutorials.last}');
  }

  TipContent _createDefaultTip() {
    return const TipContent(
      id: 'default_tip',
      title: '使用提示',
      content: '探索应用的各种功能，发现更多投资机会',
      category: TipCategory.general,
      icon: Icons.lightbulb,
      priority: TipPriority.medium,
    );
  }

  /// 销毁系统
  void dispose() {
    _performanceSubscription?.cancel();
    _instance = null;
  }
}

/// 教程内容
class TutorialContent {
  final String id;
  final String title;
  final String description;
  final List<TutorialStep> steps;
  final Duration estimatedDuration;
  final TutorialDifficulty difficulty;
  final List<String> prerequisites;

  const TutorialContent({
    required this.id,
    required this.title,
    required this.description,
    required this.steps,
    required this.estimatedDuration,
    required this.difficulty,
    this.prerequisites = const [],
  });
}

/// 教程步骤
class TutorialStep {
  final String title;
  final String description;
  final Rect highlightArea;
  final List<GestureType> gestureTypes;
  final Widget? customWidget;
  final Duration? stepDuration;

  const TutorialStep({
    required this.title,
    required this.description,
    required this.highlightArea,
    required this.gestureTypes,
    this.customWidget,
    this.stepDuration,
  });
}

/// 教程难度
enum TutorialDifficulty {
  beginner,
  intermediate,
  advanced,
}

extension TutorialDifficultyExtension on TutorialDifficulty {
  String get displayName {
    switch (this) {
      case TutorialDifficulty.beginner:
        return '初级';
      case TutorialDifficulty.intermediate:
        return '中级';
      case TutorialDifficulty.advanced:
        return '高级';
    }
  }

  Color get color {
    switch (this) {
      case TutorialDifficulty.beginner:
        return SemanticColors.success500;
      case TutorialDifficulty.intermediate:
        return SemanticColors.warning500;
      case TutorialDifficulty.advanced:
        return SemanticColors.error500;
    }
  }
}

/// 教程会话
class TutorialSession {
  /// 创建教程会话实例
  const TutorialSession({
    required this.content,
    this.currentStep = 0,
    this.onComplete,
    this.onStepChanged,
    this.isActive = true,
  });

  /// 创建空的教程会话
  TutorialSession.empty()
      : content = const TutorialContent(
          id: 'empty',
          title: '',
          description: '',
          steps: [],
          estimatedDuration: Duration.zero,
          difficulty: TutorialDifficulty.beginner,
        ),
        currentStep = 0,
        onComplete = null,
        onStepChanged = null,
        isActive = false;

  final TutorialContent content;
  final int currentStep;
  final VoidCallback? onComplete;
  final VoidCallback? onStepChanged;
  final bool isActive;

  TutorialSession copyWith({
    int? currentStep,
    VoidCallback? onComplete,
    VoidCallback? onStepChanged,
    bool? isActive,
  }) {
    return TutorialSession(
      content: content,
      currentStep: currentStep ?? this.currentStep,
      onComplete: onComplete ?? this.onComplete,
      onStepChanged: onStepChanged ?? this.onStepChanged,
      isActive: isActive ?? this.isActive,
    );
  }

  TutorialStep? get currentStepData {
    if (currentStep < 0 || currentStep >= content.steps.length) {
      return null;
    }
    return content.steps[currentStep];
  }

  bool get isCompleted {
    return currentStep >= content.steps.length - 1;
  }

  bool get isFirstStep {
    return currentStep == 0;
  }

  int get totalSteps => content.steps.length;
  int get remainingSteps => totalSteps - currentStep - 1;
}

/// 提示内容
class TipContent {
  final String id;
  final String title;
  final String content;
  final TipCategory category;
  final IconData icon;
  final TipPriority priority;
  final DateTime? createdAt;
  final bool isRead;

  const TipContent({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.icon,
    required this.priority,
    this.createdAt,
    this.isRead = false,
  });
}

/// 提示分类
enum TipCategory {
  productivity,
  feature,
  navigation,
  data,
  general,
}

extension TipCategoryExtension on TipCategory {
  String get displayName {
    switch (this) {
      case TipCategory.productivity:
        return '效率提升';
      case TipCategory.feature:
        return '功能介绍';
      case TipCategory.navigation:
        return '导航操作';
      case TipCategory.data:
        return '数据相关';
      case TipCategory.general:
        return '通用提示';
    }
  }

  Color get color {
    switch (this) {
      case TipCategory.productivity:
        return BaseColors.primary500;
      case TipCategory.feature:
        return SemanticColors.info500;
      case TipCategory.navigation:
        return SemanticColors.warning500;
      case TipCategory.data:
        return SemanticColors.success500;
      case TipCategory.general:
        return NeutralColors.neutral600;
    }
  }
}

/// 提示优先级
enum TipPriority {
  high,
  medium,
  low,
}

extension TipPriorityExtension on TipPriority {
  String get displayName {
    switch (this) {
      case TipPriority.high:
        return '重要';
      case TipPriority.medium:
        return '一般';
      case TipPriority.low:
        return '提示';
    }
  }

  Color get color {
    switch (this) {
      case TipPriority.high:
        return SemanticColors.error500;
      case TipPriority.medium:
        return SemanticColors.warning500;
      case TipPriority.low:
        return SemanticColors.success500;
    }
  }
}

/// 指南内容
class GuideContent {
  final String id;
  final String title;
  final String context;
  final String content;
  final List<String> steps;
  final List<String> relatedTopics;
  final Duration? readingTime;

  const GuideContent({
    required this.id,
    required this.title,
    required this.context,
    required this.content,
    required this.steps,
    this.relatedTopics = const [],
    this.readingTime,
  });
}

/// 智能教程Widget
class SmartTutorialWidget extends StatefulWidget {
  final TutorialSession session;
  final Widget child;
  final VoidCallback? onSkip;
  final VoidCallback? onComplete;

  const SmartTutorialWidget({
    Key? key,
    required this.session,
    required this.child,
    this.onSkip,
    this.onComplete,
  }) : super(key: key);

  @override
  State<SmartTutorialWidget> createState() => _SmartTutorialWidgetState();
}

class _SmartTutorialWidgetState extends State<SmartTutorialWidget>
    with TickerProviderStateMixin {
  late AnimationController _overlayController;
  late AnimationController _contentController;
  late Animation<double> _overlayAnimation;
  late Animation<double> _contentAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _overlayController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _contentController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );

    _overlayAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _overlayController,
      curve: Curves.easeInOut,
    ));

    _contentAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOutBack,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOutCubic,
    ));

    _overlayController.forward();
    Timer(Duration(milliseconds: 150), () {
      _contentController.forward();
    });
  }

  @override
  void dispose() {
    _overlayController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.session.isActive) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        AnimatedBuilder(
          animation: _overlayAnimation,
          builder: (context, child) {
            return _buildTutorialOverlay();
          },
        ),
      ],
    );
  }

  Widget _buildTutorialOverlay() {
    return Stack(
      children: [
        // 半透明遮罩
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.5 * _overlayAnimation.value),
          ),
        ),
        // 高亮区域
        if (widget.session.currentStepData != null) _buildHighlightArea(),
        // 教程内容
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: AnimatedBuilder(
            animation: _contentAnimation,
            builder: (context, child) {
              return SlideTransition(
                position: _slideAnimation,
                child: Opacity(
                  opacity: _contentAnimation.value,
                  child: _buildTutorialContent(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightArea() {
    final step = widget.session.currentStepData!;

    // 创建高亮孔洞
    return ClipPath(
      clipper: HighlightClipper(
        highlightRect: step.highlightArea,
        padding: EdgeInsets.all(8),
      ),
      child: Container(
        color: Colors.transparent,
      ),
    );
  }

  Widget _buildTutorialContent() {
    final step = widget.session.currentStepData;
    if (step == null) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.all(BaseSpacing.lg),
      padding: EdgeInsets.all(BaseSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.dialog),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 进度指示器
          _buildProgressBar(),
          SizedBox(height: BaseSpacing.md),

          // 标题和难度
          Row(
            children: [
              Expanded(
                child: Text(
                  step.title,
                  style: AppTextStyles.h5.copyWith(
                    color: NeutralColors.neutral900,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: BaseSpacing.sm,
                  vertical: BaseSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color:
                      widget.session.content.difficulty.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                ),
                child: Text(
                  widget.session.content.difficulty.displayName,
                  style: AppTextStyles.caption.copyWith(
                    color: widget.session.content.difficulty.color,
                    fontWeight: FontWeights.medium,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: BaseSpacing.sm),

          // 描述
          Text(
            step.description,
            style: AppTextStyles.body.copyWith(
              color: NeutralColors.neutral700,
            ),
          ),

          // 手势提示
          if (step.gestureTypes.isNotEmpty) ...[
            SizedBox(height: BaseSpacing.md),
            _buildGestureHints(step.gestureTypes),
          ],

          // 自定义内容
          if (step.customWidget != null) ...[
            SizedBox(height: BaseSpacing.md),
            step.customWidget!,
          ],

          SizedBox(height: BaseSpacing.lg),

          // 操作按钮
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return LinearProgressIndicator(
      value: (widget.session.currentStep + 1) / widget.session.totalSteps,
      backgroundColor: NeutralColors.neutral200,
      valueColor: AlwaysStoppedAnimation<Color>(BaseColors.primary500),
    );
  }

  Widget _buildGestureHints(List<GestureType> gestures) {
    return Wrap(
      spacing: BaseSpacing.sm,
      runSpacing: BaseSpacing.xs,
      children: gestures.map((gesture) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: BaseSpacing.sm,
            vertical: BaseSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: BaseColors.primary50,
            borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getGestureIcon(gesture),
                size: 16,
                color: BaseColors.primary500,
              ),
              SizedBox(width: BaseSpacing.xs),
              Text(
                _getGestureName(gesture),
                style: AppTextStyles.caption.copyWith(
                  color: BaseColors.primary700,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // 跳过按钮
        TextButton(
          onPressed: _skipTutorial,
          child: Text('跳过'),
        ),

        Spacer(),

        // 上一步按钮
        if (!widget.session.isFirstStep)
          TextButton(
            onPressed: _previousStep,
            child: Text('上一步'),
          ),

        SizedBox(width: BaseSpacing.sm),

        // 下一步/完成按钮
        ElevatedButton(
          onPressed: widget.session.isCompleted ? _completeTutorial : _nextStep,
          style: ElevatedButton.styleFrom(
            backgroundColor: BaseColors.primary500,
            foregroundColor: Colors.white,
          ),
          child: Text(widget.session.isCompleted ? '完成' : '下一步'),
        ),
      ],
    );
  }

  IconData _getGestureIcon(GestureType gesture) {
    switch (gesture) {
      case GestureType.swipeLeft:
        return Icons.swipe_left;
      case GestureType.swipeRight:
        return Icons.swipe_right;
      case GestureType.swipeUp:
        return Icons.swipe_up;
      case GestureType.swipeDown:
        return Icons.swipe_down;
      case GestureType.longPress:
        return Icons.touch_app;
      case GestureType.doubleTap:
        return Icons.touch_app;
      case GestureType.singleTap:
        return Icons.touch_app;
      case GestureType.pinch:
        return Icons.pinch;
      case GestureType.spread:
        return Icons.open_in_full;
      case GestureType.rotate:
        return Icons.rotate_right;
    }
  }

  String _getGestureName(GestureType gesture) {
    switch (gesture) {
      case GestureType.swipeLeft:
        return '左滑';
      case GestureType.swipeRight:
        return '右滑';
      case GestureType.swipeUp:
        return '上滑';
      case GestureType.swipeDown:
        return '下滑';
      case GestureType.longPress:
        return '长按';
      case GestureType.doubleTap:
        return '双击';
      case GestureType.singleTap:
        return '单击';
      case GestureType.pinch:
        return '捏合';
      case GestureType.spread:
        return '张开';
      case GestureType.rotate:
        return '旋转';
    }
  }

  void _nextStep() {
    if (widget.session.isCompleted) {
      _completeTutorial();
    } else {
      widget.session.onStepChanged?.call();
      _restartAnimations();
    }
  }

  void _previousStep() {
    if (!widget.session.isFirstStep) {
      widget.session.onStepChanged?.call();
      _restartAnimations();
    }
  }

  void _skipTutorial() {
    widget.onSkip?.call();
  }

  void _completeTutorial() {
    widget.session.onComplete?.call();
    widget.onComplete?.call();
  }

  void _restartAnimations() {
    _overlayController.reset();
    _contentController.reset();
    _overlayController.forward();
    Timer(Duration(milliseconds: 150), () {
      _contentController.forward();
    });
  }
}

/// 高亮区域裁剪器
class HighlightClipper extends CustomClipper<Path> {
  /// 创建高亮区域裁剪器
  HighlightClipper({
    required this.highlightRect,
    this.padding = EdgeInsets.zero,
  });

  final Rect highlightRect;
  final EdgeInsets padding;

  @override
  Path getClip(Size size) {
    final path = Path();

    // 添加整个屏幕
    path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // 创建高亮区域（稍微扩大一点）
    final expandedRect = highlightRect.inflate(
      padding.left + padding.right,
    );

    // 从路径中减去高亮区域，创建孔洞效果
    final holePath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        expandedRect,
        Radius.circular(8),
      ));

    // 使用差集运算创建孔洞
    return Path.combine(PathOperation.difference, path, holePath);
  }

  @override
  bool shouldReclip(HighlightClipper oldClipper) {
    return oldClipper.highlightRect != highlightRect ||
        oldClipper.padding != padding;
  }
}

/// 每日提示Widget
class DailyTipWidget extends StatefulWidget {
  /// 创建每日提示Widget
  const DailyTipWidget({
    super.key,
    required this.tip,
    this.onClose,
    this.onRead,
  });

  final TipContent tip;
  final VoidCallback? onClose;
  final VoidCallback? onRead;

  @override
  State<DailyTipWidget> createState() => _DailyTipWidgetState();
}

class _DailyTipWidgetState extends State<DailyTipWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _animation,
        child: Container(
          margin: EdgeInsets.all(BaseSpacing.md),
          padding: EdgeInsets.all(BaseSpacing.md),
          decoration: BoxDecoration(
            color: widget.tip.category.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.card),
            border: Border.all(
              color: widget.tip.category.color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // 图标
              Container(
                padding: EdgeInsets.all(BaseSpacing.sm),
                decoration: BoxDecoration(
                  color: widget.tip.category.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                ),
                child: Icon(
                  widget.tip.icon,
                  color: widget.tip.category.color,
                  size: 20,
                ),
              ),

              SizedBox(width: BaseSpacing.md),

              // 内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.tip.title,
                          style: AppTextStyles.label.copyWith(
                            color: widget.tip.category.color,
                            fontWeight: FontWeights.semiBold,
                          ),
                        ),
                        SizedBox(width: BaseSpacing.xs),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: BaseSpacing.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: widget.tip.priority.color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.tip.priority.displayName,
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: BaseSpacing.xs),
                    Text(
                      widget.tip.content,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: NeutralColors.neutral700,
                      ),
                    ),
                  ],
                ),
              ),

              // 关闭按钮
              IconButton(
                onPressed: () {
                  widget.onClose?.call();
                  _dismiss();
                },
                icon: Icon(Icons.close, size: 16),
                color: NeutralColors.neutral500,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      widget.onClose?.call();
    });
  }
}
