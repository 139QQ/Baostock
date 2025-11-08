import 'package:flutter/material.dart';
import '../../../features/fund/domain/entities/fund.dart';
import '../../../features/portfolio/domain/entities/portfolio_holding.dart';
import 'fund_data_card.dart';

/// 可拖拽的基金卡片
/// 支持拖拽到对比区域、收藏夹、投资组合等目标区域
class DraggableFundCard extends StatefulWidget {
  final Fund fund;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final Function(Fund)? onFavoriteToggle;
  final Function(Fund)? onCompareToggle;
  final bool isFavorite;
  final bool isComparing;
  final bool enableDrag;

  const DraggableFundCard({
    Key? key,
    required this.fund,
    this.onTap,
    this.onDoubleTap,
    this.onFavoriteToggle,
    this.onCompareToggle,
    this.isFavorite = false,
    this.isComparing = false,
    this.enableDrag = true,
  }) : super(key: key);

  @override
  State<DraggableFundCard> createState() => _DraggableFundCardState();
}

class _DraggableFundCardState extends State<DraggableFundCard>
    with TickerProviderStateMixin {
  late AnimationController _dragAnimationController;
  late AnimationController _hoverAnimationController;
  late Animation<double> _dragAnimation;
  late Animation<double> _hoverAnimation;

  bool _isDragging = false;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _dragAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _hoverAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _dragAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(
          parent: _dragAnimationController, curve: Curves.easeInOut),
    );
    _hoverAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _hoverAnimationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _dragAnimationController.dispose();
    _hoverAnimationController.dispose();
    super.dispose();
  }

  void _onDragStarted() {
    setState(() {
      _isDragging = true;
    });
    _dragAnimationController.forward();
  }

  void _onDragEnded() {
    setState(() {
      _isDragging = false;
    });
    _dragAnimationController.reverse();
  }

  void _onHoverChanged(bool isHovering) {
    setState(() {
      _isHovering = isHovering;
    });
    if (isHovering) {
      _hoverAnimationController.forward();
    } else {
      _hoverAnimationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enableDrag) {
      return FundDataCard(
        fund: widget.fund,
        onTap: widget.onTap,
        onFavorite: widget.onFavoriteToggle != null
            ? () => widget.onFavoriteToggle!(widget.fund)
            : null,
        onCompare: widget.onCompareToggle != null
            ? () => widget.onCompareToggle!(widget.fund)
            : null,
        isFavorite: widget.isFavorite,
        isSelected: widget.isComparing,
      );
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_dragAnimation, _hoverAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _isDragging
              ? _dragAnimation.value
              : (_isHovering ? _hoverAnimation.value : 1.0),
          child: Draggable<Fund>(
            data: widget.fund,
            feedback: Material(
              borderRadius: BorderRadius.circular(12),
              elevation: 12,
              color: Colors.transparent,
              child: Container(
                width: 280,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).cardColor,
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Opacity(
                  opacity: 0.9,
                  child: FundDataCard(
                    fund: widget.fund,
                    mode: FundDataCardMode.compact,
                  ),
                ),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.3,
              child: FundDataCard(
                fund: widget.fund,
                onTap: null, // 禁用拖拽时的点击
                onFavorite: widget.onFavoriteToggle != null
                    ? () => widget.onFavoriteToggle!(widget.fund)
                    : null,
                onCompare: widget.onCompareToggle != null
                    ? () => widget.onCompareToggle!(widget.fund)
                    : null,
                isFavorite: widget.isFavorite,
                isSelected: widget.isComparing,
              ),
            ),
            onDragStarted: _onDragStarted,
            onDragEnd: (details) => _onDragEnded(),
            onDragCompleted: _onDragEnded,
            onDraggableCanceled: (velocity, offset) => _onDragEnded(),
            child: MouseRegion(
              onEnter: (_) => _onHoverChanged(true),
              onExit: (_) => _onHoverChanged(false),
              child: FundDataCard(
                fund: widget.fund,
                onTap: widget.onTap,
                onFavorite: widget.onFavoriteToggle != null
                    ? () => widget.onFavoriteToggle!(widget.fund)
                    : null,
                onCompare: widget.onCompareToggle != null
                    ? () => widget.onCompareToggle!(widget.fund)
                    : null,
                isFavorite: widget.isFavorite,
                isSelected: widget.isComparing,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 拖拽目标区域基类
class DragTargetArea<T extends Object> extends StatefulWidget {
  final Widget child;
  final String? hintText;
  final String? activeHintText;
  final bool Function(T? data) onWillAccept;
  final void Function(T data) onAccept;
  final Color? activeColor;
  final double borderRadius;

  const DragTargetArea({
    Key? key,
    required this.child,
    this.hintText,
    this.activeHintText,
    required this.onWillAccept,
    required this.onAccept,
    this.activeColor,
    this.borderRadius = 12.0,
  }) : super(key: key);

  @override
  State<DragTargetArea<T>> createState() => _DragTargetAreaState<T>();
}

class _DragTargetAreaState<T extends Object> extends State<DragTargetArea<T>>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onHoverChanged(bool isHovering) {
    if (_isHovering != isHovering) {
      setState(() {
        _isHovering = isHovering;
      });
      if (isHovering) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.activeColor ?? Theme.of(context).primaryColor;

    return DragTarget<T>(
      onWillAccept: (data) => data != null && widget.onWillAccept(data),
      onAccept: (data) {
        widget.onAccept(data);
        _onHoverChanged(false);
      },
      onLeave: (_) => _onHoverChanged(false),
      builder: (context, candidateData, rejectedData) {
        final isActive = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: isActive ? activeColor : Colors.grey.withOpacity(0.3),
              width: isActive ? 2 : 1,
            ),
            color: isActive ? activeColor.withOpacity(0.1) : Colors.transparent,
          ),
          child: Stack(
            children: [
              widget.child,
              if (isActive)
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(widget.borderRadius),
                          color:
                              activeColor.withOpacity(0.05 * _animation.value),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_circle_outline,
                                size: 48,
                                color:
                                    activeColor.withOpacity(_animation.value),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.activeHintText ??
                                    widget.hintText ??
                                    '拖拽到这里',
                                style: TextStyle(
                                  color:
                                      activeColor.withOpacity(_animation.value),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

/// 基金对比拖拽目标区域
class FundComparisonDropZone extends StatelessWidget {
  final List<Fund> comparisonFunds;
  final Function(Fund) onFundAdded;
  final Function(String)? onFundRemoved;

  const FundComparisonDropZone({
    Key? key,
    required this.comparisonFunds,
    required this.onFundAdded,
    this.onFundRemoved,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DragTargetArea<Fund>(
      hintText: '拖拽基金到这里进行对比',
      activeHintText: '松开添加到对比列表',
      onWillAccept: (data) =>
          data != null && !comparisonFunds.any((f) => f.code == data.code),
      onAccept: onFundAdded,
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[300] ?? Colors.grey,
            style: BorderStyle.solid,
            width: 1,
          ),
        ),
        child: comparisonFunds.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.compare_arrows,
                      size: 32,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '拖拽基金到这里进行对比',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: comparisonFunds.map((fund) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(fund.name),
                        avatar: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Text(
                            fund.code.substring(0, 2),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          onFundRemoved?.call(fund.code);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
      ),
    );
  }
}

/// 投资组合拖拽目标区域
class PortfolioDropZone extends StatelessWidget {
  final List<PortfolioHolding> holdings;
  final Function(Fund) onFundAdded;

  const PortfolioDropZone({
    Key? key,
    required this.holdings,
    required this.onFundAdded,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DragTargetArea<Fund>(
      hintText: '拖拽基金添加到投资组合',
      activeHintText: '松开添加到投资组合',
      onWillAccept: (data) => data != null,
      onAccept: onFundAdded,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[300] ?? Colors.grey,
            style: BorderStyle.solid,
            width: 1,
          ),
        ),
        child: holdings.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '拖拽基金添加到投资组合',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: holdings.length,
                itemBuilder: (context, index) {
                  final holding = holdings[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        holding.fundCode.substring(0, 2),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    title: Text(holding.fundName),
                    subtitle:
                        Text('${holding.holdingAmount.toStringAsFixed(2)} 份'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '¥${holding.marketValue.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          holding.returnDescription,
                          style: TextStyle(
                            color: holding.isProfitable
                                ? Colors.green
                                : Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

/// 基金收藏拖拽目标区域
class FavoriteDropZone extends StatelessWidget {
  final List<Fund> favoriteFunds;
  final Function(Fund) onFundAdded;
  final Function(String)? onFundRemoved;

  const FavoriteDropZone({
    Key? key,
    required this.favoriteFunds,
    required this.onFundAdded,
    this.onFundRemoved,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DragTargetArea<Fund>(
      hintText: '拖拽基金添加到收藏夹',
      activeHintText: '松开添加到收藏夹',
      onWillAccept: (data) =>
          data != null && !favoriteFunds.any((f) => f.code == data.code),
      onAccept: onFundAdded,
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[300] ?? Colors.grey,
            style: BorderStyle.solid,
            width: 1,
          ),
        ),
        child: favoriteFunds.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 32,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '拖拽基金添加到收藏夹',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: favoriteFunds.map((fund) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(fund.name),
                        avatar: CircleAvatar(
                          backgroundColor: Colors.red,
                          child: Text(
                            fund.code.substring(0, 2),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          onFundRemoved?.call(fund.code);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
      ),
    );
  }
}
