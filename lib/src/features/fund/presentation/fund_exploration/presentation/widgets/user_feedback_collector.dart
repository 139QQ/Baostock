import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 用户反馈收集组件
class UserFeedbackCollector extends StatefulWidget {
  const UserFeedbackCollector({super.key});

  @override
  State<UserFeedbackCollector> createState() => _UserFeedbackCollectorState();
}

class _UserFeedbackCollectorState extends State<UserFeedbackCollector>
    with TickerProviderStateMixin {
  bool _showFeedback = false;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _checkIfShouldShowFeedback();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkIfShouldShowFeedback() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastShown = prefs.getInt('feedback_last_shown') ?? 0;
      final hasCompleted = prefs.getBool('feedback_completed') ?? false;

      final now = DateTime.now().millisecondsSinceEpoch;
      final daysSinceLastShown = (now - lastShown) / (1000 * 60 * 60 * 24);

      if (hasCompleted || daysSinceLastShown < 7) {
        return;
      }

      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        _showFeedbackPanel();
      }
    } catch (e) {
      debugPrint('检查反馈显示时机失败: $e');
    }
  }

  void _showFeedbackPanel() {
    setState(() {
      _showFeedback = true;
    });
    _animationController.forward();
  }

  void _closeFeedback() {
    _animationController.reverse().then((_) {
      setState(() {
        _showFeedback = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_showFeedback) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              margin: const EdgeInsets.all(16.0),
              constraints: BoxConstraints(
                maxWidth: 500,
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: FeedbackForm(
                onSubmit: _submitFeedback,
                onClose: _closeFeedback,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitFeedback({
    required int satisfaction,
    required String usability,
    required String features,
    required String suggestions,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('feedback_satisfaction', satisfaction);
      await prefs.setString('feedback_usability', usability);
      await prefs.setString('feedback_features', features);
      await prefs.setString('feedback_suggestions', suggestions);
      await prefs.setBool('feedback_completed', true);
      await prefs.setInt(
          'feedback_last_shown', DateTime.now().millisecondsSinceEpoch);

      _showThankYouMessage();
    } catch (e) {
      debugPrint('保存反馈失败: $e');
      _showErrorMessage();
    }
  }

  void _showThankYouMessage() {
    _closeFeedback();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('感谢您的反馈！我们会认真考虑您的建议。'),
        backgroundColor: Color(0xFF2E7D32),
      ),
    );
  }

  void _showErrorMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('提交失败，请稍后重试'),
        backgroundColor: Color(0xFFD32F2F),
      ),
    );
  }
}

/// 反馈表单组件
class FeedbackForm extends StatefulWidget {
  final Function({
    required int satisfaction,
    required String usability,
    required String features,
    required String suggestions,
  }) onSubmit;
  final VoidCallback onClose;

  const FeedbackForm({
    super.key,
    required this.onSubmit,
    required this.onClose,
  });

  @override
  State<FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<FeedbackForm> {
  int _satisfactionRating = 0;
  String _usabilityRating = '';
  String _featuresAccessibility = '';
  final TextEditingController _suggestionsController = TextEditingController();

  final List<String> _usabilityOptions = [
    '非常易用',
    '比较易用',
    '一般',
    '不太好用',
    '很难用',
  ];

  final List<String> _featureOptions = [
    '所有功能都能轻松找到',
    '大部分功能能找到',
    '部分功能需要时间寻找',
    '很难找到需要的功能',
  ];

  @override
  void dispose() {
    _suggestionsController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_satisfactionRating == 0) {
      _showValidationError('请为整体体验打分');
      return;
    }

    if (_usabilityRating.isEmpty) {
      _showValidationError('请评价界面易用性');
      return;
    }

    if (_featuresAccessibility.isEmpty) {
      _showValidationError('请评价功能可达性');
      return;
    }

    widget.onSubmit(
      satisfaction: _satisfactionRating,
      usability: _usabilityRating,
      features: _featuresAccessibility,
      suggestions: _suggestionsController.text,
    );
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF9800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxHeight < 600;
        final padding = isSmallScreen ? 16.0 : 24.0;

        return Padding(
          padding: EdgeInsets.all(padding),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '使用体验反馈',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 18 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),
                Text(
                  '为了不断改进我们的产品，请您花费1-2分钟分享使用体验。',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: const Color(0xFF666666),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 16 : 24),
                _buildSatisfactionRating(),
                SizedBox(height: isSmallScreen ? 16 : 24),
                _buildUsabilityRating(),
                SizedBox(height: isSmallScreen ? 16 : 24),
                _buildFeaturesAccessibility(),
                SizedBox(height: isSmallScreen ? 16 : 24),
                _buildSuggestionsInput(),
                SizedBox(height: isSmallScreen ? 16 : 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 12 : 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      '提交反馈',
                      style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSatisfactionRating() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '您对新的极简界面整体满意度如何？',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (index) {
            final score = index + 1;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _satisfactionRating = score;
                });
              },
              child: Column(
                children: [
                  Icon(
                    _satisfactionRating >= score
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$score分',
                    style: TextStyle(
                      fontSize: 12,
                      color: _satisfactionRating >= score
                          ? Colors.amber
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildUsabilityRating() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '界面易用性如何？',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _usabilityOptions.map((option) {
            final isSelected = _usabilityRating == option;
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _usabilityRating = selected ? option : '';
                });
              },
              backgroundColor: Colors.grey.shade100,
              selectedColor: Colors.green.shade100,
              checkmarkColor: Colors.green,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFeaturesAccessibility() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '功能是否容易找到？',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _featureOptions.map((option) {
            final isSelected = _featuresAccessibility == option;
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _featuresAccessibility = selected ? option : '';
                });
              },
              backgroundColor: Colors.grey.shade100,
              selectedColor: Colors.blue.shade100,
              checkmarkColor: Colors.blue,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSuggestionsInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '其他建议或意见（选填）',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _suggestionsController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: '请输入您的宝贵建议...',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }
}
