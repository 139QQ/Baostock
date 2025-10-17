import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 浏览器风格的持续加载状态指示器
///
/// 模拟现代浏览器的加载动画效果，提供流畅的加载体验
class BrowserStyleLoader extends StatefulWidget {
  final bool isLoading;
  final String? loadingText;
  final double? progress;
  final Color? color;
  final double height;
  final BorderRadius? borderRadius;

  const BrowserStyleLoader({
    super.key,
    required this.isLoading,
    this.loadingText,
    this.progress,
    this.color,
    this.height = 3.0,
    this.borderRadius,
  });

  @override
  State<BrowserStyleLoader> createState() => _BrowserStyleLoaderState();
}

class _BrowserStyleLoaderState extends State<BrowserStyleLoader>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _progressController;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));

    if (widget.isLoading) {
      _shimmerController.repeat();
      _progressController.forward();
    }
  }

  @override
  void didUpdateWidget(BrowserStyleLoader oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isLoading != widget.isLoading) {
      if (widget.isLoading) {
        _shimmerController.repeat();
        _progressController.forward(from: 0.0);
      } else {
        _shimmerController.stop();
        _shimmerController.reset();
        _progressController.forward();
      }
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading &&
        (widget.progress == null || widget.progress == 1.0)) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final primaryColor = widget.color ?? theme.primaryColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 加载进度条
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius:
                widget.borderRadius ?? BorderRadius.circular(widget.height / 2),
            color: primaryColor.withOpacity(0.1),
          ),
          child: Stack(
            children: [
              // 背景进度
              if (widget.progress != null)
                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor:
                          (widget.progress ?? 0.0) * _progressAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: widget.borderRadius ??
                              BorderRadius.circular(widget.height / 2),
                          color: primaryColor.withOpacity(0.3),
                        ),
                      ),
                    );
                  },
                ),

              // 闪烁效果
              if (widget.isLoading)
                AnimatedBuilder(
                  animation: _shimmerAnimation,
                  builder: (context, child) {
                    return FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _shimmerAnimation.value.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: widget.borderRadius ??
                              BorderRadius.circular(widget.height / 2),
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.transparent,
                              primaryColor.withOpacity(0.6),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),

        // 加载文本
        if (widget.loadingText != null) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                ),
              if (widget.isLoading) const SizedBox(width: 8),
              Text(
                widget.loadingText!,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// 顶部状态栏加载指示器
///
/// 在应用顶部显示加载状态，类似浏览器顶部的加载进度条
class TopBarLoadingIndicator extends StatefulWidget {
  final bool isLoading;
  final String? loadingText;
  final double? progress;
  final Color? color;
  final Duration fadeDuration;

  const TopBarLoadingIndicator({
    super.key,
    required this.isLoading,
    this.loadingText,
    this.progress,
    this.color,
    this.fadeDuration = const Duration(milliseconds: 300),
  });

  @override
  State<TopBarLoadingIndicator> createState() => _TopBarLoadingIndicatorState();
}

class _TopBarLoadingIndicatorState extends State<TopBarLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: widget.fadeDuration,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    if (widget.isLoading) {
      _fadeController.forward();
    }
  }

  @override
  void didUpdateWidget(TopBarLoadingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isLoading != widget.isLoading) {
      if (widget.isLoading) {
        _fadeController.forward();
      } else {
        _fadeController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: BrowserStyleLoader(
            isLoading: widget.isLoading,
            loadingText: widget.loadingText,
            progress: widget.progress,
            color: widget.color,
            height: 2.0,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(1),
              bottomRight: Radius.circular(1),
            ),
          ),
        );
      },
    );
  }
}

/// 智能加载状态管理器
///
/// 全局管理应用的加载状态，提供智能的加载控制
class SmartLoadingManager {
  static final SmartLoadingManager _instance = SmartLoadingManager._internal();
  factory SmartLoadingManager() => _instance;
  SmartLoadingManager._internal();

  final Map<String, LoadingTask> _loadingTasks = {};
  final StreamController<LoadingState> _stateController =
      StreamController<LoadingState>.broadcast();

  Stream<LoadingState> get loadingStateStream => _stateController.stream;

  /// 开始一个加载任务
  String startLoading({
    required String taskName,
    String? description,
    Duration? timeout,
  }) {
    final taskId = _generateTaskId();
    final task = LoadingTask(
      id: taskId,
      name: taskName,
      description: description,
      startTime: DateTime.now(),
      timeout: timeout ?? const Duration(seconds: 25),
    );

    _loadingTasks[taskId] = task;
    _notifyStateChange();

    // 设置超时定时器
    Timer(task.timeout, () {
      if (_loadingTasks.containsKey(taskId)) {
        _timeoutTask(taskId);
      }
    });

    return taskId;
  }

  /// 更新任务进度
  void updateProgress(String taskId, double progress) {
    final task = _loadingTasks[taskId];
    if (task != null) {
      task.progress = progress.clamp(0.0, 1.0);
      _notifyStateChange();
    }
  }

  /// 完成加载任务
  void completeLoading(String taskId) {
    final task = _loadingTasks[taskId];
    if (task != null) {
      task.progress = 1.0;
      task.endTime = DateTime.now();
      _notifyStateChange();

      // 延迟移除任务，以便用户看到完成状态
      Timer(const Duration(milliseconds: 10), () {
        _loadingTasks.remove(taskId);
        _notifyStateChange();
      });
    }
  }

  /// 取消加载任务
  void cancelLoading(String taskId) {
    if (_loadingTasks.containsKey(taskId)) {
      _loadingTasks[taskId]?.endTime = DateTime.now();
      _loadingTasks.remove(taskId);
      _notifyStateChange();
    }
  }

  /// 获取当前加载状态
  LoadingState getCurrentState() {
    if (_loadingTasks.isEmpty) {
      return LoadingState(isLoading: false, tasks: []);
    }

    final tasks = _loadingTasks.values.toList();
    final overallProgress = tasks.isEmpty
        ? 0.0
        : tasks.map((t) => t.progress).reduce((a, b) => a + b) / tasks.length;

    return LoadingState(
      isLoading: true,
      tasks: tasks,
      overallProgress: overallProgress,
      primaryTask:
          tasks.firstWhere((t) => !t.isCompleted, orElse: () => tasks.first),
    );
  }

  void _timeoutTask(String taskId) {
    final task = _loadingTasks[taskId];
    if (task != null) {
      task.isTimedOut = true;
      task.endTime = DateTime.now();
      _notifyStateChange();

      Timer(const Duration(seconds: 2), () {
        _loadingTasks.remove(taskId);
        _notifyStateChange();
      });
    }
  }

  void _notifyStateChange() {
    _stateController.add(getCurrentState());
  }

  String _generateTaskId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(10000)}';
  }

  /// 清理已完成的任务
  void cleanup() {
    final now = DateTime.now();
    _loadingTasks.removeWhere((taskId, task) {
      return task.endTime != null &&
          now.difference(task.endTime!).inMinutes > 1;
    });
  }

  void dispose() {
    _stateController.close();
  }
}

/// 加载任务信息
class LoadingTask {
  final String id;
  final String name;
  final String? description;
  final DateTime startTime;
  DateTime? endTime;
  final Duration timeout;

  double progress = 0.0;
  bool isTimedOut = false;

  LoadingTask({
    required this.id,
    required this.name,
    this.description,
    required this.startTime,
    this.endTime,
    required this.timeout,
  });

  bool get isCompleted => progress >= 1.0 || isTimedOut;
  Duration? get duration =>
      endTime != null ? endTime!.difference(startTime) : null;
}

/// 加载状态信息
class LoadingState {
  final bool isLoading;
  final List<LoadingTask> tasks;
  final double overallProgress;
  final LoadingTask? primaryTask;

  LoadingState({
    required this.isLoading,
    required this.tasks,
    this.overallProgress = 0.0,
    this.primaryTask,
  });

  String get loadingText {
    if (!isLoading) return '';
    if (primaryTask?.description != null) return primaryTask!.description!;
    if (tasks.isNotEmpty) return tasks.first.name;
    return '加载中...';
  }
}

/// 智能加载包装器
///
/// 自动管理加载状态的Widget包装器
class SmartLoadingWrapper extends StatefulWidget {
  final Widget child;
  final String taskName;
  final String? loadingText;
  final Duration? timeout;
  final Future<void> Function()? onLoad;
  final bool showTopIndicator;

  const SmartLoadingWrapper({
    super.key,
    required this.child,
    required this.taskName,
    this.loadingText,
    this.timeout,
    this.onLoad,
    this.showTopIndicator = true,
  });

  @override
  State<SmartLoadingWrapper> createState() => _SmartLoadingWrapperState();
}

class _SmartLoadingWrapperState extends State<SmartLoadingWrapper> {
  final SmartLoadingManager _loadingManager = SmartLoadingManager();
  late StreamSubscription<LoadingState> _subscription;
  String? _currentTaskId;
  LoadingState _currentState = LoadingState(isLoading: false, tasks: []);

  @override
  void initState() {
    super.initState();
    _subscription = _loadingManager.loadingStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _currentState = state;
        });
      }
    });

    _startLoading();
  }

  @override
  void didUpdateWidget(SmartLoadingWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.taskName != widget.taskName) {
      _restartLoading();
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    if (_currentTaskId != null) {
      _loadingManager.cancelLoading(_currentTaskId!);
    }
    super.dispose();
  }

  void _startLoading() async {
    _currentTaskId = _loadingManager.startLoading(
      taskName: widget.taskName,
      description: widget.loadingText,
      timeout: widget.timeout,
    );

    try {
      await widget.onLoad?.call();
      if (_currentTaskId != null) {
        _loadingManager.completeLoading(_currentTaskId!);
      }
    } catch (e) {
      if (_currentTaskId != null) {
        _loadingManager.cancelLoading(_currentTaskId!);
      }
    }
  }

  void _restartLoading() {
    if (_currentTaskId != null) {
      _loadingManager.cancelLoading(_currentTaskId!);
    }
    _startLoading();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.showTopIndicator)
          TopBarLoadingIndicator(
            isLoading: _currentState.isLoading,
            loadingText: _currentState.loadingText,
            progress: _currentState.overallProgress,
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}
