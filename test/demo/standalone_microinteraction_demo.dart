import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 独立的基金数据模型
class SimpleFund {
  final String code;
  final String name;
  final String type;
  final String company;
  final String manager;
  final double return1W;
  final double return1M;
  final double return3M;
  final double return6M;
  final double return1Y;
  final double return3Y;
  final double scale;
  final String riskLevel;
  final String status;
  final bool isFavorite;

  const SimpleFund({
    required this.code,
    required this.name,
    required this.type,
    required this.company,
    required this.manager,
    required this.return1W,
    required this.return1M,
    required this.return3M,
    required this.return6M,
    required this.return1Y,
    required this.return3Y,
    required this.scale,
    required this.riskLevel,
    required this.status,
    required this.isFavorite,
  });

  SimpleFund copyWith({
    String? code,
    String? name,
    String? type,
    String? company,
    String? manager,
    double? return1W,
    double? return1M,
    double? return3M,
    double? return6M,
    double? return1Y,
    double? return3Y,
    double? scale,
    String? riskLevel,
    String? status,
    bool? isFavorite,
  }) {
    return SimpleFund(
      code: code ?? this.code,
      name: name ?? this.name,
      type: type ?? this.type,
      company: company ?? this.company,
      manager: manager ?? this.manager,
      return1W: return1W ?? this.return1W,
      return1M: return1M ?? this.return1M,
      return3M: return3M ?? this.return3M,
      return6M: return6M ?? this.return6M,
      return1Y: return1Y ?? this.return1Y,
      return3Y: return3Y ?? this.return3Y,
      scale: scale ?? this.scale,
      riskLevel: riskLevel ?? this.riskLevel,
      status: status ?? this.status,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

// 简化的微交互基金卡片
class SimpleMicrointeractiveFundCard extends StatefulWidget {
  final SimpleFund fund;
  final bool enableAnimations;
  final bool compactMode;
  final VoidCallback? onTap;
  final VoidCallback? onAddToWatchlist;
  final VoidCallback? onCompare;
  final VoidCallback? onShare;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;

  const SimpleMicrointeractiveFundCard({
    super.key,
    required this.fund,
    this.enableAnimations = true,
    this.compactMode = false,
    this.onTap,
    this.onAddToWatchlist,
    this.onCompare,
    this.onShare,
    this.onSwipeLeft,
    this.onSwipeRight,
  });

  @override
  State<SimpleMicrointeractiveFundCard> createState() =>
      _SimpleMicrointeractiveFundCardState();
}

class _SimpleMicrointeractiveFundCardState
    extends State<SimpleMicrointeractiveFundCard>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _hoverController;
  late AnimationController _scaleController;
  late AnimationController _numberController;
  late AnimationController _favoriteController;

  late Animation<double> _hoverAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _favoriteAnimation;

  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFavorite = false;

  double _displayedReturn = 0.0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.fund.isFavorite;
    _displayedReturn = widget.fund.return1Y;

    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _numberController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _favoriteController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _hoverAnimation = Tween<double>(
      begin: 0.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _favoriteAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _favoriteController,
      curve: Curves.elasticOut,
    ));

    // 数字动画监听器
    _numberController.addListener(() {
      if (mounted) {
        setState(() {
          final progress = _numberController.value;
          _displayedReturn = widget.fund.return1Y * progress;
        });
      }
    });

    // 启动数字动画
    if (widget.enableAnimations) {
      _startNumberAnimation();
    }
  }

  @override
  void didUpdateWidget(SimpleMicrointeractiveFundCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fund.return1Y != widget.fund.return1Y) {
      if (widget.enableAnimations) {
        _startNumberAnimation();
      } else {
        setState(() {
          _displayedReturn = widget.fund.return1Y;
        });
      }
    }

    if (oldWidget.fund.isFavorite != widget.fund.isFavorite) {
      setState(() {
        _isFavorite = widget.fund.isFavorite;
      });
      if (widget.enableAnimations) {
        _favoriteController.forward().then((_) {
          _favoriteController.reverse();
        });
      }
    }
  }

  void _startNumberAnimation() {
    final startValue = _displayedReturn;
    final endValue = widget.fund.return1Y;

    if (startValue == endValue) return;

    _numberController.reset();
    _numberController.animateTo(1.0);
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _scaleController.dispose();
    _numberController.dispose();
    _favoriteController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.enableAnimations) {
      _scaleController.forward();
    }
    setState(() {
      _isPressed = true;
    });
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.enableAnimations) {
      _scaleController.reverse();
    }
    setState(() {
      _isPressed = false;
    });
    widget.onTap?.call();
  }

  void _onTapCancel() {
    if (widget.enableAnimations) {
      _scaleController.reverse();
    }
    setState(() {
      _isPressed = false;
    });
  }

  void _onMouseEnter(PointerEnterEvent event) {
    if (widget.enableAnimations) {
      _hoverController.forward();
    }
    setState(() {
      _isHovered = true;
    });
  }

  void _onMouseExit(PointerExitEvent event) {
    if (widget.enableAnimations) {
      _hoverController.reverse();
    }
    setState(() {
      _isHovered = false;
    });
  }

  void _onFavoriteTap() {
    setState(() {
      _isFavorite = !_isFavorite;
    });

    if (widget.enableAnimations) {
      _favoriteController.forward().then((_) {
        _favoriteController.reverse();
      });
    }

    HapticFeedback.mediumImpact();
    widget.onAddToWatchlist?.call();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.compactMode) {
      return _buildCompactCard();
    }

    return MouseRegion(
      onEnter: _onMouseEnter,
      onExit: _onMouseExit,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedBuilder(
          animation: Listenable.merge(
              [_hoverAnimation, _scaleAnimation, _favoriteAnimation]),
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                  0, widget.enableAnimations ? -_hoverAnimation.value : 0),
              child: Transform.scale(
                scale: widget.enableAnimations && _isPressed
                    ? _scaleAnimation.value
                    : 1.0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      if (widget.enableAnimations)
                        BoxShadow(
                          color:
                              Theme.of(context).colorScheme.shadow.withOpacity(
                                    _isHovered ? 0.3 : 0.1,
                                  ),
                          blurRadius: _isHovered ? 12 : 6,
                          offset: Offset(
                              0,
                              widget.enableAnimations
                                  ? _hoverAnimation.value / 2
                                  : 2),
                        ),
                    ],
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.2),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.onTap,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(),
                              const SizedBox(height: 12),
                              _buildPerformanceMetrics(),
                              const SizedBox(height: 12),
                              _buildActions(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCompactCard() {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Text(
          widget.fund.code.substring(0, 3),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
      title: Text(
        widget.fund.name,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${widget.fund.type} | ${widget.fund.company}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${_displayedReturn.toStringAsFixed(2)}%',
            style: TextStyle(
              color: _displayedReturn >= 0 ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 8),
          Transform.scale(
            scale: widget.enableAnimations ? _favoriteAnimation.value : 1.0,
            child: IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : null,
              ),
              onPressed: _onFavoriteTap,
            ),
          ),
        ],
      ),
      onTap: widget.onTap,
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.fund.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.fund.code,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.fund.type,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${_displayedReturn.toStringAsFixed(2)}%',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: _displayedReturn >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              '近1年',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPerformanceMetrics() {
    return Row(
      children: [
        _buildMetric('近1周', widget.fund.return1W),
        _buildMetric('近1月', widget.fund.return1M),
        _buildMetric('近3月', widget.fund.return3M),
        _buildMetric('近6月', widget.fund.return6M),
      ],
    );
  }

  Widget _buildMetric(String label, double value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '${value.toStringAsFixed(2)}%',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: value >= 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              '规模: ${widget.fund.scale.toStringAsFixed(1)}亿',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getRiskColor().withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.fund.riskLevel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _getRiskColor(),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: widget.enableAnimations ? _favoriteAnimation.value : 1.0,
              child: IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : null,
                ),
                onPressed: _onFavoriteTap,
                tooltip: '收藏',
              ),
            ),
            IconButton(
              icon: const Icon(Icons.compare_arrows),
              onPressed: () {
                HapticFeedback.lightImpact();
                widget.onCompare?.call();
              },
              tooltip: '对比',
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                HapticFeedback.lightImpact();
                widget.onShare?.call();
              },
              tooltip: '分享',
            ),
          ],
        ),
      ],
    );
  }

  Color _getRiskColor() {
    switch (widget.fund.riskLevel) {
      case 'R1':
        return Colors.green;
      case 'R2':
        return Colors.lightGreen;
      case 'R3':
        return Colors.orange;
      case 'R4':
        return Colors.red;
      case 'R5':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

void main() {
  runApp(const StandaloneMicrointeractionDemo());
}

class StandaloneMicrointeractionDemo extends StatelessWidget {
  const StandaloneMicrointeractionDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Microinteraction Fund Card Demo',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const MicrointeractionDemoPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MicrointeractionDemoPage extends StatefulWidget {
  const MicrointeractionDemoPage({super.key});

  @override
  State<MicrointeractionDemoPage> createState() =>
      _MicrointeractionDemoPageState();
}

class _MicrointeractionDemoPageState extends State<MicrointeractionDemoPage> {
  bool _enableAnimations = true;
  bool _compactMode = false;
  final ScrollController _scrollController = ScrollController();

  final List<SimpleFund> _testFunds = [
    const SimpleFund(
      code: '110022',
      name: 'E Fund Consumer Industry Stock',
      type: 'Stock',
      company: 'E Fund',
      manager: 'Xiao Nan',
      return1W: 0.5,
      return1M: 2.3,
      return3M: 5.6,
      return6M: 8.9,
      return1Y: 15.6,
      return3Y: 45.2,
      scale: 85.6,
      riskLevel: 'R3',
      status: 'Normal',
      isFavorite: false,
    ),
    const SimpleFund(
      code: '000001',
      name: 'China Asset Growth Mixed',
      type: 'Mixed',
      company: 'China Asset',
      manager: 'Zhang Kun',
      return1W: -0.2,
      return1M: 1.5,
      return3M: 3.8,
      return6M: 12.3,
      return1Y: 28.9,
      return3Y: 65.4,
      scale: 156.8,
      riskLevel: 'R4',
      status: 'Normal',
      isFavorite: true,
    ),
    const SimpleFund(
      code: '161725',
      name: 'China Merchants CSI Baijiu Index',
      type: 'Index',
      company: 'China Merchants',
      manager: 'Hou Hao',
      return1W: -1.8,
      return1M: -3.2,
      return3M: 8.5,
      return6M: 18.7,
      return1Y: -5.3,
      return3Y: 45.8,
      scale: 785.2,
      riskLevel: 'R4',
      status: 'Normal',
      isFavorite: false,
    ),
    const SimpleFund(
      code: '005827',
      name: 'E Fund Blue Chip Select Mixed',
      type: 'Mixed',
      company: 'E Fund',
      manager: 'Zhang Kun',
      return1W: 1.2,
      return1M: 4.5,
      return3M: 12.3,
      return6M: 23.4,
      return1Y: 35.7,
      return3Y: 125.6,
      scale: 268.9,
      riskLevel: 'R3',
      status: 'Normal',
      isFavorite: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Microinteraction Fund Card Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(_compactMode ? Icons.view_list : Icons.view_module),
            onPressed: () {
              setState(() {
                _compactMode = !_compactMode;
              });
            },
            tooltip: _compactMode ? 'Card View' : 'Compact View',
          ),
          IconButton(
            icon: Icon(
                _enableAnimations ? Icons.animation : Icons.animation_outlined),
            onPressed: () {
              setState(() {
                _enableAnimations = !_enableAnimations;
              });
            },
            tooltip:
                _enableAnimations ? 'Disable Animations' : 'Enable Animations',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildInfoCard(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _testFunds.length,
              itemBuilder: (context, index) {
                final fund = _testFunds[index];
                return SimpleMicrointeractiveFundCard(
                  fund: fund,
                  enableAnimations: _enableAnimations,
                  compactMode: _compactMode,
                  onTap: () => _showSnackBar('Tapped ${fund.name}'),
                  onAddToWatchlist: () {
                    _showSnackBar('${_isFavoriteMessage(fund)} ${fund.name}');
                  },
                  onCompare: () {
                    _showSnackBar('Added ${fund.name} to comparison');
                  },
                  onShare: () {
                    _showSnackBar('Shared ${fund.name}');
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildPerformanceInfo(),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.touch_app,
                size: 24,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Microinteraction Fund Card Demo',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hover animations, number scrolling, gesture operations',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFeatureList(),
        ],
      ),
    );
  }

  Widget _buildFeatureList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFeatureItem(
            'Hover Animation', 'Card elevation + shadow gradient'),
        _buildFeatureItem('Number Scrolling', 'Smooth return rate animation'),
        _buildFeatureItem('Haptic Feedback', 'Vibration feedback on touch'),
        _buildFeatureItem(
            'Performance Optimized', 'Device-adaptive animation levels'),
      ],
    );
  }

  Widget _buildFeatureItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer
                            .withOpacity(0.8),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.speed,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Performance Monitor',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMetric(
                    'Animation', _enableAnimations ? 'Enabled' : 'Disabled'),
              ),
              Expanded(
                child: _buildMetric(
                    'View Mode', _compactMode ? 'Compact' : 'Card'),
              ),
              Expanded(
                child: _buildMetric('Device', _getDeviceType()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withOpacity(0.7),
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  String _getDeviceType() {
    final screenWidth = MediaQuery.of(context).size.width;
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;

    if (screenWidth < 600 || pixelRatio < 2.0) {
      return 'Low-end';
    } else if (screenWidth > 1200) {
      return 'Desktop';
    } else {
      return 'Standard';
    }
  }

  String _isFavoriteMessage(SimpleFund fund) {
    return fund.isFavorite ? 'Remove from favorites' : 'Add to favorites';
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
