import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 用户引导组件
///
/// 为首次使用极简布局的用户提供引导说明
/// 包括界面更新介绍、功能位置提示等
class UserOnboardingGuide extends StatefulWidget {
  const UserOnboardingGuide({super.key});

  @override
  State<UserOnboardingGuide> createState() => _UserOnboardingGuideState();
}

class _UserOnboardingGuideState extends State<UserOnboardingGuide>
    with TickerProviderStateMixin {
  bool _showGuide = false;
  int _currentStep = 0;
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<GuideStep> _guideSteps = [
    GuideStep(
      title: '欢迎使用极简界面',
      description: '我们重新设计了基金探索页面，采用更简洁的单栏布局，让您更专注于基金发现。',
      icon: Icons.auto_awesome,
      highlightArea: Rect.zero, // 全屏引导
    ),
    GuideStep(
      title: '智能搜索框',
      description: '顶部搜索框支持基金代码、名称搜索，快速找到您感兴趣的基金。',
      icon: Icons.search,
      highlightArea: const Rect.fromLTWH(32, 100, 600, 50),
    ),
    GuideStep(
      title: '快速筛选',
      description: '使用筛选标签快速找到热门基金、高收益产品等。',
      icon: Icons.filter_list,
      highlightArea: const Rect.fromLTWH(32, 180, 400, 40),
    ),
    GuideStep(
      title: '悬浮工具栏',
      description: '底部悬浮工具栏提供筛选、对比、计算等核心功能，随时可用。',
      icon: Icons.apps,
      highlightArea: const Rect.fromLTWH(32, 600, 800, 64),
    ),
    GuideStep(
      title: '布局切换',
      description: '点击右上角按钮可在极简布局和传统布局之间自由切换。',
      icon: Icons.swap_horiz,
      highlightArea: const Rect.fromLTWH(650, 20, 80, 40),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _checkIfShouldShowGuide();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// 检查是否应该显示引导
  Future<void> _checkIfShouldShowGuide() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenMinimalistGuide =
          prefs.getBool('has_seen_minimalist_guide') ?? false;

      if (!hasSeenMinimalistGuide) {
        setState(() {
          _showGuide = true;
        });
        _animationController.forward();
      }
    } catch (e) {
      debugPrint('检查引导状态失败: $e');
    }
  }

  /// 标记引导已完成
  Future<void> _markGuideAsCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_minimalist_guide', true);
    } catch (e) {
      debugPrint('保存引导状态失败: $e');
    }
  }

  /// 跳过引导
  void _skipGuide() {
    _animationController.reverse().then((_) {
      setState(() {
        _showGuide = false;
      });
      _markGuideAsCompleted();
    });
  }

  /// 下一步
  void _nextStep() {
    if (_currentStep < _guideSteps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep++;
      });
    } else {
      _completeGuide();
    }
  }

  /// 上一步
  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep--;
      });
    }
  }

  /// 完成引导
  void _completeGuide() {
    _animationController.reverse().then((_) {
      setState(() {
        _showGuide = false;
      });
      _markGuideAsCompleted();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_showGuide) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.black54,
      body: Stack(
        children: [
          // 高亮区域（可选）
          if (_guideSteps[_currentStep].highlightArea != Rect.zero)
            _buildHighlightOverlay(),

          // 引导内容
          FadeTransition(
            opacity: _fadeAnimation,
            child: _buildGuideContent(),
          ),
        ],
      ),
    );
  }

  /// 构建高亮覆盖层
  Widget _buildHighlightOverlay() {
    final highlightArea = _guideSteps[_currentStep].highlightArea;
    return Positioned.fill(
      child: ClipPath(
        clipper: _HighlightClipper(highlightArea),
        child: Container(
          color: Colors.black54,
        ),
      ),
    );
  }

  /// 构建引导内容
  Widget _buildGuideContent() {
    final step = _guideSteps[_currentStep];

    return Column(
      children: [
        // 顶部跳过按钮
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _skipGuide,
                  child: const Text(
                    '跳过引导',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 主要引导内容
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _guideSteps.length,
            onPageChanged: (index) {
              setState(() {
                _currentStep = index;
              });
            },
            itemBuilder: (context, index) {
              return _buildGuideStep(_guideSteps[index]);
            },
          ),
        ),

        // 底部导航
        _buildBottomNavigation(),
      ],
    );
  }

  /// 构建引导步骤
  Widget _buildGuideStep(GuideStep step) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 图标
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              step.icon,
              size: 40,
              color: const Color(0xFF2E7D32),
            ),
          ),

          const SizedBox(height: 32),

          // 标题
          Text(
            step.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // 描述
          Text(
            step.description,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          // 步骤指示器
          const SizedBox(height: 48),
          _buildStepIndicator(),
        ],
      ),
    );
  }

  /// 构建步骤指示器
  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _guideSteps.length,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: index == _currentStep
                ? Colors.white
                : Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  /// 构建底部导航
  Widget _buildBottomNavigation() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 上一步按钮
            if (_currentStep > 0)
              ElevatedButton(
                onPressed: _previousStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('上一步'),
              )
            else
              const SizedBox(width: 80),

            // 下一步/完成按钮
            ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: Text(
                _currentStep == _guideSteps.length - 1 ? '开始使用' : '下一步',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 引导步骤数据类
class GuideStep {
  final String title;
  final String description;
  final IconData icon;
  final Rect highlightArea;

  const GuideStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.highlightArea,
  });
}

/// 高亮区域裁剪器
class _HighlightClipper extends CustomClipper<Path> {
  final Rect highlightArea;

  _HighlightClipper(this.highlightArea);

  @override
  Path getClip(Size size) {
    final path = Path();

    // 添加整个屏幕路径
    path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // 如果有高亮区域，减去高亮区域
    if (highlightArea != Rect.zero) {
      final highlightPath = Path();
      highlightPath.addRRect(
        RRect.fromRectAndRadius(
          highlightArea,
          const Radius.circular(8),
        ),
      );
      path.addPath(highlightPath, Offset.zero);
    }

    return path;
  }

  @override
  bool shouldReclip(_HighlightClipper oldClipper) {
    return oldClipper.highlightArea != highlightArea;
  }
}
