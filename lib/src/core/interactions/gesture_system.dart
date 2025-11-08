import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../performance/performance_detector.dart';

/// 多模态交互系统
/// 提供智能手势识别、语音控制、触觉反馈等多种交互方式
class MultiModalInteractionSystem {
  static MultiModalInteractionSystem? _instance;
  static MultiModalInteractionSystem get instance =>
      _instance ??= MultiModalInteractionSystem._();

  MultiModalInteractionSystem._();

  // 手势系统
  final Map<String, GestureRecognizer> _recognizers = {};
  final Map<String, Function(GestureData)> _gestureHandlers = {};

  // 语音控制
  final Map<String, Function(VoiceCommand)> _voiceHandlers = {};
  final List<String> _supportedCommands = [];
  bool _isVoiceEnabled = false;
  bool _isListening = false;

  // 触觉反馈
  bool _hapticEnabled = true;
  bool _audioFeedbackEnabled = true;

  // 性能监控
  PerformanceLevel _currentPerformanceLevel = PerformanceLevel.good;
  StreamSubscription<PerformanceResult>? _performanceSubscription;

  /// 初始化多模态交互系统
  Future<void> initialize() async {
    await _initializePerformanceMonitoring();
    await _initializeVoiceControl();
    await _initializeHapticFeedback();
    await _initializeGestures();
  }

  Future<void> _initializePerformanceMonitoring() async {
    _performanceSubscription = SmartPerformanceDetector.instance
        .detectPerformance()
        .asStream()
        .listen((result) {
      if (result.level != _currentPerformanceLevel) {
        _currentPerformanceLevel = result.level;
        _adaptToPerformanceLevel(result.level);
      }
    });
  }

  Future<void> _initializeVoiceControl() async {
    // 初始化语音控制命令
    _supportedCommands.addAll([
      '搜索基金',
      '查看详情',
      '添加收藏',
      '取消收藏',
      '加入对比',
      '刷新数据',
      '返回',
      '下一页',
      '上一页',
    ]);

    // 根据性能级别决定是否启用语音
    _isVoiceEnabled = _currentPerformanceLevel != PerformanceLevel.poor;
  }

  Future<void> _initializeHapticFeedback() async {
    // 根据性能级别决定触觉反馈强度
    _hapticEnabled =
        _currentPerformanceLevel.index >= PerformanceLevel.good.index;
    _audioFeedbackEnabled =
        _currentPerformanceLevel == PerformanceLevel.excellent;
  }

  Future<void> _initializeGestures() async {
    // 预注册常用手势识别器
    _registerCommonGestureRecognizers();
  }

  void _registerCommonGestureRecognizers() {
    // 基金卡片手势识别器
    registerGestureRecognizer('fund_card', FundCardGestureRecognizer());
    registerGestureRecognizer('chart', ChartGestureRecognizer());
    registerGestureRecognizer('navigation', NavigationGestureRecognizer());
  }

  void _adaptToPerformanceLevel(PerformanceLevel level) {
    switch (level) {
      case PerformanceLevel.excellent:
        _isVoiceEnabled = true;
        _hapticEnabled = true;
        _audioFeedbackEnabled = true;
        break;
      case PerformanceLevel.good:
        _isVoiceEnabled = true;
        _hapticEnabled = true;
        _audioFeedbackEnabled = false;
        break;
      case PerformanceLevel.fair:
        _isVoiceEnabled = false;
        _hapticEnabled = true;
        _audioFeedbackEnabled = false;
        break;
      case PerformanceLevel.poor:
        _isVoiceEnabled = false;
        _hapticEnabled = false;
        _audioFeedbackEnabled = false;
        break;
    }
  }

  /// 注册手势识别器
  void registerGestureRecognizer(String context, GestureRecognizer recognizer) {
    _recognizers[context] = recognizer;
  }

  /// 注册手势处理器
  void registerGestureHandler(String context, Function(GestureData) handler) {
    _gestureHandlers[context] = handler;
  }

  /// 注册语音命令处理器
  void registerVoiceHandler(String command, Function(VoiceCommand) handler) {
    _voiceHandlers[command] = handler;
    if (!_supportedCommands.contains(command)) {
      _supportedCommands.add(command);
    }
  }

  /// 触发手势
  void triggerGesture(String context, GestureData gestureData) {
    final handler = _gestureHandlers[context];
    if (handler != null) {
      try {
        handler(gestureData);
        _triggerFeedback(gestureData.type);
      } catch (e) {
        print('手势处理失败: $context - $e');
      }
    }
  }

  /// 触发语音命令
  Future<void> triggerVoiceCommand(String command,
      {Map<String, dynamic>? parameters}) async {
    if (!_isVoiceEnabled) return;

    final voiceCommand = VoiceCommand(
      command: command,
      parameters: parameters ?? {},
      timestamp: DateTime.now(),
    );

    final handler = _voiceHandlers[command];
    if (handler != null) {
      try {
        handler(voiceCommand);
        _triggerVoiceFeedback(command);
      } catch (e) {
        print('语音命令处理失败: $command - $e');
      }
    }
  }

  /// 开始语音监听
  Future<void> startVoiceListening() async {
    if (!_isVoiceEnabled || _isListening) return;

    _isListening = true;
    // 这里应该集成实际的语音识别服务
    // 目前使用模拟实现
    _simulateVoiceRecognition();
  }

  /// 停止语音监听
  void stopVoiceListening() {
    _isListening = false;
  }

  void _simulateVoiceRecognition() async {
    // 模拟语音识别过程
    await Future.delayed(Duration(seconds: 2));

    if (_isListening) {
      final random = Random();
      final command =
          _supportedCommands[random.nextInt(_supportedCommands.length)];
      await triggerVoiceCommand(command);

      // 继续监听
      _simulateVoiceRecognition();
    }
  }

  /// 触发反馈
  void _triggerFeedback(GestureType gestureType) {
    // 触觉反馈
    if (_hapticEnabled) {
      _triggerHapticFeedback(gestureType);
    }

    // 音频反馈
    if (_audioFeedbackEnabled) {
      _triggerAudioFeedback(gestureType);
    }
  }

  void _triggerHapticFeedback(GestureType gestureType) {
    // 根据手势类型提供不同的触觉反馈
    switch (gestureType) {
      case GestureType.swipeLeft:
      case GestureType.swipeRight:
      case GestureType.swipeUp:
      case GestureType.swipeDown:
        HapticFeedback.lightImpact();
        break;
      case GestureType.longPress:
        HapticFeedback.mediumImpact();
        break;
      case GestureType.doubleTap:
        HapticFeedback.heavyImpact();
        break;
      case GestureType.singleTap:
        HapticFeedback.selectionClick();
        break;
      default:
        HapticFeedback.lightImpact();
    }
  }

  void _triggerAudioFeedback(GestureType gestureType) {
    // 根据手势类型播放不同的音频反馈
    // 这里应该集成实际的音频播放系统
    print('播放音频反馈: ${gestureType.toString()}');
  }

  void _triggerVoiceFeedback(String command) {
    // 语音命令的音频反馈
    if (_audioFeedbackEnabled) {
      print('语音命令反馈: $command');
    }
  }

  /// 获取上下文的手势识别器
  GestureRecognizer? getGestureRecognizer(String context) {
    return _recognizers[context];
  }

  /// 清理资源
  void dispose() {
    _recognizers.clear();
    _gestureHandlers.clear();
    _voiceHandlers.clear();
    _performanceSubscription?.cancel();
    _isListening = false;
    _instance = null;
  }
}

/// 语音命令
class VoiceCommand {
  final String command;
  final Map<String, dynamic> parameters;
  final DateTime timestamp;
  final double confidence;

  const VoiceCommand({
    required this.command,
    required this.parameters,
    required this.timestamp,
    this.confidence = 1.0,
  });

  @override
  String toString() {
    return 'VoiceCommand(command: $command, confidence: $confidence)';
  }
}

/// 手势支持系统 (向后兼容)
/// 提供智能手势识别和处理功能，包括滑动手势、长按、双击等
@Deprecated('使用 MultiModalInteractionSystem 替代')
class GestureSystem {
  static final Map<String, GestureRecognizer> _recognizers = {};
  static final Map<String, Function(GestureData)> _gestureHandlers = {};

  /// 注册手势识别器
  static void registerGestureRecognizer(
      String context, GestureRecognizer recognizer) {
    _recognizers[context] = recognizer;
    MultiModalInteractionSystem.instance
        .registerGestureRecognizer(context, recognizer);
  }

  /// 注册手势处理器
  static void registerGestureHandler(
      String context, Function(GestureData) handler) {
    _gestureHandlers[context] = handler;
    MultiModalInteractionSystem.instance
        .registerGestureHandler(context, handler);
  }

  /// 触发手势
  static void triggerGesture(String context, GestureData gestureData) {
    final handler = _gestureHandlers[context];
    if (handler != null) {
      try {
        handler(gestureData);
      } catch (e) {
        print('手势处理失败: $context - $e');
      }
    }
    MultiModalInteractionSystem.instance.triggerGesture(context, gestureData);
  }

  /// 获取上下文的手势识别器
  static GestureRecognizer? getGestureRecognizer(String context) {
    return _recognizers[context];
  }

  /// 清理资源
  static void dispose() {
    _recognizers.clear();
    _gestureHandlers.clear();
  }
}

/// 手势数据
class GestureData {
  final GestureType type;
  final Offset startPosition;
  final Offset endPosition;
  final Duration duration;
  final double velocity;
  final double distance;
  final Map<String, dynamic>? additionalData;

  const GestureData({
    required this.type,
    required this.startPosition,
    required this.endPosition,
    required this.duration,
    required this.velocity,
    required this.distance,
    this.additionalData,
  });

  /// 计算手势方向
  SwipeDirection get direction {
    final dx = endPosition.dx - startPosition.dx;
    final dy = endPosition.dy - startPosition.dy;

    if (dx.abs() > dy.abs()) {
      return dx > 0 ? SwipeDirection.right : SwipeDirection.left;
    } else {
      return dy > 0 ? SwipeDirection.down : SwipeDirection.up;
    }
  }

  /// 是否为快速手势
  bool get isQuickGesture => velocity > 500.0;

  /// 是否为长距离手势
  bool get isLongDistance => distance > 100.0;
}

/// 手势类型
enum GestureType {
  swipeLeft,
  swipeRight,
  swipeUp,
  swipeDown,
  longPress,
  doubleTap,
  singleTap,
  pinch,
  spread,
  rotate,
}

/// 滑动方向
enum SwipeDirection {
  left,
  right,
  up,
  down,
}

/// 手势识别器基类
abstract class GestureRecognizer {
  final List<GestureType> supportedGestures;
  final Map<GestureType, Duration> gestureTimeouts;
  final double minSwipeDistance;
  final double minSwipeVelocity;
  final Duration longPressDuration;
  final Duration doubleTapTimeout;

  GestureRecognizer({
    required this.supportedGestures,
    this.gestureTimeouts = const {},
    this.minSwipeDistance = 50.0,
    this.minSwipeVelocity = 300.0,
    this.longPressDuration = const Duration(milliseconds: 500),
    this.doubleTapTimeout = const Duration(milliseconds: 300),
  });

  /// 识别手势
  void recognizeGesture(GestureData gestureData) {
    if (!supportedGestures.contains(gestureData.type)) return;

    switch (gestureData.type) {
      case GestureType.swipeLeft:
        if (_isValidSwipe(gestureData, SwipeDirection.left)) {
          onSwipeLeft(gestureData);
        }
        break;
      case GestureType.swipeRight:
        if (_isValidSwipe(gestureData, SwipeDirection.right)) {
          onSwipeRight(gestureData);
        }
        break;
      case GestureType.swipeUp:
        if (_isValidSwipe(gestureData, SwipeDirection.up)) {
          onSwipeUp(gestureData);
        }
        break;
      case GestureType.swipeDown:
        if (_isValidSwipe(gestureData, SwipeDirection.down)) {
          onSwipeDown(gestureData);
        }
        break;
      case GestureType.longPress:
        if (gestureData.duration >= longPressDuration) {
          onLongPress(gestureData);
        }
        break;
      case GestureType.doubleTap:
        onDoubleTap(gestureData);
        break;
      case GestureType.singleTap:
        onSingleTap(gestureData);
        break;
      case GestureType.pinch:
        onPinch(gestureData);
        break;
      case GestureType.spread:
        onSpread(gestureData);
        break;
      case GestureType.rotate:
        onRotate(gestureData);
        break;
    }
  }

  /// 验证滑动手势
  bool _isValidSwipe(
      GestureData gestureData, SwipeDirection expectedDirection) {
    return gestureData.direction == expectedDirection &&
        gestureData.distance >= minSwipeDistance &&
        gestureData.velocity >= minSwipeVelocity;
  }

  // 抽象方法，子类实现具体的手势处理逻辑
  void onSwipeLeft(GestureData gestureData) {}
  void onSwipeRight(GestureData gestureData) {}
  void onSwipeUp(GestureData gestureData) {}
  void onSwipeDown(GestureData gestureData) {}
  void onLongPress(GestureData gestureData) {}
  void onDoubleTap(GestureData gestureData) {}
  void onSingleTap(GestureData gestureData) {}
  void onPinch(GestureData gestureData) {}
  void onSpread(GestureData gestureData) {}
  void onRotate(GestureData gestureData) {}
}

/// 基金卡片手势识别器
class FundCardGestureRecognizer extends GestureRecognizer {
  final Function(GestureData)? onSwipeLeftToFavorite;
  final Function(GestureData)? onSwipeRightToCompare;
  final Function(GestureData)? onSwipeUpToDetails;
  final Function(GestureData)? onSwipeDownToShare;
  final Function(GestureData)? onLongPressMenu;
  final Function(GestureData)? onDoubleTapFavorite;
  final Function(GestureData)? onSingleTapDetails;

  FundCardGestureRecognizer({
    this.onSwipeLeftToFavorite,
    this.onSwipeRightToCompare,
    this.onSwipeUpToDetails,
    this.onSwipeDownToShare,
    this.onLongPressMenu,
    this.onDoubleTapFavorite,
    this.onSingleTapDetails,
  }) : super(
          supportedGestures: [
            GestureType.swipeLeft,
            GestureType.swipeRight,
            GestureType.swipeUp,
            GestureType.swipeDown,
            GestureType.longPress,
            GestureType.doubleTap,
            GestureType.singleTap,
          ],
        );

  @override
  void onSwipeLeft(GestureData gestureData) {
    onSwipeLeftToFavorite?.call(gestureData);
  }

  @override
  void onSwipeRight(GestureData gestureData) {
    onSwipeRightToCompare?.call(gestureData);
  }

  @override
  void onSwipeUp(GestureData gestureData) {
    onSwipeUpToDetails?.call(gestureData);
  }

  @override
  void onSwipeDown(GestureData gestureData) {
    onSwipeDownToShare?.call(gestureData);
  }

  @override
  void onLongPress(GestureData gestureData) {
    onLongPressMenu?.call(gestureData);
  }

  @override
  void onDoubleTap(GestureData gestureData) {
    onDoubleTapFavorite?.call(gestureData);
  }

  @override
  void onSingleTap(GestureData gestureData) {
    onSingleTapDetails?.call(gestureData);
  }
}

/// 图表手势识别器
class ChartGestureRecognizer extends GestureRecognizer {
  final Function(GestureData)? onSwipeLeftToPrevious;
  final Function(GestureData)? onSwipeRightToNext;
  final Function(GestureData)? onSwipeUpToZoomIn;
  final Function(GestureData)? onSwipeDownToZoomOut;
  final Function(GestureData)? onPinchToZoomOut;
  final Function(GestureData)? onSpreadToZoomIn;
  final Function(GestureData)? onDoubleTapToReset;
  final Function(GestureData)? onLongPressDetails;

  ChartGestureRecognizer({
    this.onSwipeLeftToPrevious,
    this.onSwipeRightToNext,
    this.onSwipeUpToZoomIn,
    this.onSwipeDownToZoomOut,
    this.onPinchToZoomOut,
    this.onSpreadToZoomIn,
    this.onDoubleTapToReset,
    this.onLongPressDetails,
  }) : super(
          supportedGestures: [
            GestureType.swipeLeft,
            GestureType.swipeRight,
            GestureType.swipeUp,
            GestureType.swipeDown,
            GestureType.pinch,
            GestureType.spread,
            GestureType.doubleTap,
            GestureType.longPress,
          ],
        );

  @override
  void onSwipeLeft(GestureData gestureData) {
    onSwipeLeftToPrevious?.call(gestureData);
  }

  @override
  void onSwipeRight(GestureData gestureData) {
    onSwipeRightToNext?.call(gestureData);
  }

  @override
  void onSwipeUp(GestureData gestureData) {
    onSwipeUpToZoomIn?.call(gestureData);
  }

  @override
  void onSwipeDown(GestureData gestureData) {
    onSwipeDownToZoomOut?.call(gestureData);
  }

  @override
  void onPinch(GestureData gestureData) {
    onPinchToZoomOut?.call(gestureData);
  }

  @override
  void onSpread(GestureData gestureData) {
    onSpreadToZoomIn?.call(gestureData);
  }

  @override
  void onDoubleTap(GestureData gestureData) {
    onDoubleTapToReset?.call(gestureData);
  }

  @override
  void onLongPress(GestureData gestureData) {
    onLongPressDetails?.call(gestureData);
  }
}

/// 导航手势识别器
class NavigationGestureRecognizer extends GestureRecognizer {
  final Function(GestureData)? onSwipeLeftToGoBack;
  final Function(GestureData)? onSwipeRightToGoForward;
  final Function(GestureData)? onSwipeUpToHome;
  final Function(GestureData)? onSwipeDownToMenu;
  final Function(GestureData)? onDoubleTapToTop;
  final Function(GestureData)? onLongPressToContextMenu;

  NavigationGestureRecognizer({
    this.onSwipeLeftToGoBack,
    this.onSwipeRightToGoForward,
    this.onSwipeUpToHome,
    this.onSwipeDownToMenu,
    this.onDoubleTapToTop,
    this.onLongPressToContextMenu,
  }) : super(
          supportedGestures: [
            GestureType.swipeLeft,
            GestureType.swipeRight,
            GestureType.swipeUp,
            GestureType.swipeDown,
            GestureType.doubleTap,
            GestureType.longPress,
          ],
        );

  @override
  void onSwipeLeft(GestureData gestureData) {
    onSwipeLeftToGoBack?.call(gestureData);
  }

  @override
  void onSwipeRight(GestureData gestureData) {
    onSwipeRightToGoForward?.call(gestureData);
  }

  @override
  void onSwipeUp(GestureData gestureData) {
    onSwipeUpToHome?.call(gestureData);
  }

  @override
  void onSwipeDown(GestureData gestureData) {
    onSwipeDownToMenu?.call(gestureData);
  }

  @override
  void onDoubleTap(GestureData gestureData) {
    onDoubleTapToTop?.call(gestureData);
  }

  @override
  void onLongPress(GestureData gestureData) {
    onLongPressToContextMenu?.call(gestureData);
  }
}

/// 手势检测器Widget
class GestureDetectorWidget extends StatefulWidget {
  final Widget child;
  final String gestureContext;
  final GestureRecognizer? customRecognizer;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;
  final Function(SwipeDirection)? onSwipe;
  final Function(double)? onScaleStart;
  final Function(double)? onScaleUpdate;
  final Function(double)? onScaleEnd;
  final Function(double)? onRotateStart;
  final Function(double)? onRotateUpdate;
  final Function(double)? onRotateEnd;

  const GestureDetectorWidget({
    Key? key,
    required this.child,
    required this.gestureContext,
    this.customRecognizer,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onSwipe,
    this.onScaleStart,
    this.onScaleUpdate,
    this.onScaleEnd,
    this.onRotateStart,
    this.onRotateUpdate,
    this.onRotateEnd,
  }) : super(key: key);

  @override
  State<GestureDetectorWidget> createState() => _GestureDetectorWidgetState();
}

class _GestureDetectorWidgetState extends State<GestureDetectorWidget>
    with TickerProviderStateMixin {
  Offset? _startPosition;
  Offset? _currentPosition;
  DateTime? _startTime;
  Timer? _longPressTimer;
  Timer? _doubleTapTimer;
  bool _isDoubleTap = false;

  final _swipeThreshold = 50.0;
  final _velocityThreshold = 300.0;
  final _longPressDelay = const Duration(milliseconds: 500);
  final _doubleTapDelay = const Duration(milliseconds: 300);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onLongPress: _handleLongPress,
      onDoubleTap: _handleDoubleTap,
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      onScaleStart: _handleScaleStart,
      onScaleUpdate: _handleScaleUpdate,
      onScaleEnd: _handleScaleEnd,
      child: widget.child,
    );
  }

  void _handleTapDown(TapDownDetails details) {
    _startPosition = details.globalPosition;
    _startTime = DateTime.now();

    // 启动长按定时器
    _longPressTimer?.cancel();
    _longPressTimer = Timer(_longPressDelay, () {
      if (_startPosition != null && _startTime != null) {
        _triggerGesture(GestureType.longPress, details.globalPosition);
      }
    });

    // 处理双击检测
    if (_isDoubleTap) {
      _isDoubleTap = false;
      _doubleTapTimer?.cancel();
      _triggerGesture(GestureType.doubleTap, details.globalPosition);
    } else {
      _isDoubleTap = true;
      _doubleTapTimer?.cancel();
      _doubleTapTimer = Timer(_doubleTapDelay, () {
        _isDoubleTap = false;
        _triggerGesture(GestureType.singleTap, details.globalPosition);
      });
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _longPressTimer?.cancel();
  }

  void _handleLongPress() {
    _longPressTimer?.cancel();
    if (_startPosition != null) {
      _triggerGesture(GestureType.longPress, _startPosition!);
    }
  }

  void _handleDoubleTap() {
    _triggerGesture(GestureType.doubleTap, _startPosition!);
  }

  void _handlePanStart(DragStartDetails details) {
    _startPosition = details.globalPosition;
    _startTime = DateTime.now();
    _longPressTimer?.cancel();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    _currentPosition = details.globalPosition;
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_startPosition == null ||
        _startTime == null ||
        _currentPosition == null) return;

    final endPosition = _currentPosition!;
    final duration = DateTime.now().difference(_startTime!);
    final distance = (endPosition - _startPosition!).distance;
    final velocity = distance / duration.inMilliseconds * 1000;

    if (distance >= _swipeThreshold && velocity >= _velocityThreshold) {
      _triggerSwipeGesture(
          _startPosition!, endPosition, duration, velocity, distance);
    }
  }

  void _handleScaleStart(ScaleStartDetails details) {
    widget.onScaleStart?.call(details.focalPoint.dx);
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    widget.onScaleUpdate?.call(details.scale);
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    widget.onScaleEnd?.call(1.0); // ScaleEndDetails 没有 scale 属性，使用默认值
  }

  void _triggerSwipeGesture(Offset start, Offset end, Duration duration,
      double velocity, double distance) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;

    GestureType? gestureType;
    if (dx.abs() > dy.abs()) {
      gestureType = dx > 0 ? GestureType.swipeRight : GestureType.swipeLeft;
    } else {
      gestureType = dy > 0 ? GestureType.swipeDown : GestureType.swipeUp;
    }

    final gestureData = GestureData(
      type: gestureType,
      startPosition: start,
      endPosition: end,
      duration: duration,
      velocity: velocity,
      distance: distance,
    );

    _triggerGestureData(gestureData);
  }

  void _triggerGesture(GestureType type, Offset position) {
    final gestureData = GestureData(
      type: type,
      startPosition: position,
      endPosition: position,
      duration: Duration.zero,
      velocity: 0,
      distance: 0,
    );

    _triggerGestureData(gestureData);
  }

  void _triggerGestureData(GestureData gestureData) {
    // 首先尝试使用自定义识别器
    if (widget.customRecognizer != null) {
      widget.customRecognizer!.recognizeGesture(gestureData);
    }

    // 然后触发全局手势处理
    GestureSystem.triggerGesture(widget.gestureContext, gestureData);

    // 最后触发Widget级别的回调
    switch (gestureData.type) {
      case GestureType.singleTap:
        widget.onTap?.call();
        break;
      case GestureType.doubleTap:
        widget.onDoubleTap?.call();
        break;
      case GestureType.longPress:
        widget.onLongPress?.call();
        break;
      case GestureType.swipeLeft:
      case GestureType.swipeRight:
      case GestureType.swipeUp:
      case GestureType.swipeDown:
        widget.onSwipe?.call(gestureData.direction);
        break;
      case GestureType.pinch:
        widget.onScaleEnd?.call(-1);
        break;
      case GestureType.spread:
        widget.onScaleEnd?.call(1);
        break;
      case GestureType.rotate:
        break;
    }
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _doubleTapTimer?.cancel();
    super.dispose();
  }
}

/// 手势反馈组件
class GestureFeedback extends StatefulWidget {
  final Widget child;
  final GestureType gestureType;
  final Duration duration;
  final Curve curve;
  final Color? feedbackColor;

  const GestureFeedback({
    Key? key,
    required this.child,
    required this.gestureType,
    this.duration = const Duration(milliseconds: 200),
    this.curve = Curves.easeOut,
    this.feedbackColor,
  }) : super(key: key);

  @override
  State<GestureFeedback> createState() => _GestureFeedbackState();
}

class _GestureFeedbackState extends State<GestureFeedback>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return _buildFeedback(widget.gestureType, _animation.value);
      },
    );
  }

  Widget _buildFeedback(GestureType type, double progress) {
    switch (type) {
      case GestureType.swipeLeft:
        return _buildSwipeFeedback(
            Icons.arrow_back, Alignment.centerLeft, progress);
      case GestureType.swipeRight:
        return _buildSwipeFeedback(
            Icons.arrow_forward, Alignment.centerRight, progress);
      case GestureType.swipeUp:
        return _buildSwipeFeedback(
            Icons.keyboard_arrow_up, Alignment.topCenter, progress);
      case GestureType.swipeDown:
        return _buildSwipeFeedback(
            Icons.keyboard_arrow_down, Alignment.bottomCenter, progress);
      case GestureType.longPress:
        return _buildLongPressFeedback(progress);
      case GestureType.doubleTap:
        return _buildTapFeedback(Icons.favorite, progress);
      case GestureType.singleTap:
        return _buildTapFeedback(Icons.touch_app, progress);
      case GestureType.pinch:
        return _buildScaleFeedback(Icons.close, progress);
      case GestureType.spread:
        return _buildScaleFeedback(Icons.open_in_full, progress);
      case GestureType.rotate:
        return _buildRotateFeedback(progress);
    }
  }

  Widget _buildSwipeFeedback(
      IconData icon, Alignment alignment, double progress) {
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: Align(
            alignment: alignment,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (widget.feedbackColor ?? Theme.of(context).primaryColor)
                    .withOpacity(0.2 * progress),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: (widget.feedbackColor ?? Theme.of(context).primaryColor)
                    .withOpacity(progress),
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLongPressFeedback(double progress) {
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: (widget.feedbackColor ?? Theme.of(context).primaryColor)
                    .withOpacity(0.5 * progress),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTapFeedback(IconData icon, double progress) {
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: Center(
            child: Icon(
              icon,
              color: (widget.feedbackColor ?? Theme.of(context).primaryColor)
                  .withOpacity(progress),
              size: 48 * (1 + progress * 0.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScaleFeedback(IconData icon, double progress) {
    return Transform.scale(
      scale: 1.0 + (progress * 0.1),
      child: widget.child,
    );
  }

  Widget _buildRotateFeedback(double progress) {
    return Transform.rotate(
      angle: progress * 0.1,
      child: widget.child,
    );
  }
}

/// 手势教程组件
class GestureTutorial extends StatefulWidget {
  final List<GestureType> gestures;
  final VoidCallback? onComplete;
  final Widget child;

  const GestureTutorial({
    Key? key,
    required this.gestures,
    this.onComplete,
    required this.child,
  }) : super(key: key);

  @override
  State<GestureTutorial> createState() => _GestureTutorialState();
}

class _GestureTutorialState extends State<GestureTutorial> {
  int currentGestureIndex = 0;
  bool isCompleted = false;

  @override
  Widget build(BuildContext context) {
    if (isCompleted || widget.gestures.isEmpty) {
      return widget.child;
    }

    final currentGesture = widget.gestures[currentGestureIndex];

    return Stack(
      children: [
        widget.child,
        _buildGestureOverlay(currentGesture),
      ],
    );
  }

  Widget _buildGestureOverlay(GestureType gesture) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(32),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getGestureIcon(gesture),
                    size: 64,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getGestureTitle(gesture),
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getGestureDescription(gesture),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (currentGestureIndex > 0)
                        TextButton(
                          onPressed: _previousGesture,
                          child: const Text('上一个'),
                        ),
                      TextButton(
                        onPressed: _skipTutorial,
                        child: const Text('跳过'),
                      ),
                      if (currentGestureIndex < widget.gestures.length - 1)
                        ElevatedButton(
                          onPressed: _nextGesture,
                          child: const Text('下一个'),
                        )
                      else
                        ElevatedButton(
                          onPressed: _completeTutorial,
                          child: const Text('完成'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getGestureIcon(GestureType gesture) {
    switch (gesture) {
      case GestureType.swipeLeft:
        return Icons.arrow_back;
      case GestureType.swipeRight:
        return Icons.arrow_forward;
      case GestureType.swipeUp:
        return Icons.keyboard_arrow_up;
      case GestureType.swipeDown:
        return Icons.keyboard_arrow_down;
      case GestureType.longPress:
        return Icons.touch_app;
      case GestureType.doubleTap:
        return Icons.favorite;
      case GestureType.singleTap:
        return Icons.touch_app;
      case GestureType.pinch:
        return Icons.close;
      case GestureType.spread:
        return Icons.open_in_full;
      case GestureType.rotate:
        return Icons.rotate_right;
    }
  }

  String _getGestureTitle(GestureType gesture) {
    switch (gesture) {
      case GestureType.swipeLeft:
        return '向左滑动';
      case GestureType.swipeRight:
        return '向右滑动';
      case GestureType.swipeUp:
        return '向上滑动';
      case GestureType.swipeDown:
        return '向下滑动';
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

  String _getGestureDescription(GestureType gesture) {
    switch (gesture) {
      case GestureType.swipeLeft:
        return '向左滑动基金卡片可添加到收藏夹';
      case GestureType.swipeRight:
        return '向右滑动基金卡片可添加到对比列表';
      case GestureType.swipeUp:
        return '向上滑动可查看基金详情';
      case GestureType.swipeDown:
        return '向下滑动可分享基金';
      case GestureType.longPress:
        return '长按基金卡片可显示更多选项';
      case GestureType.doubleTap:
        return '双击基金卡片可快速收藏';
      case GestureType.singleTap:
        return '单击基金卡片可查看详情';
      case GestureType.pinch:
        return '捏合手势可缩小视图';
      case GestureType.spread:
        return '张开手势可放大视图';
      case GestureType.rotate:
        return '旋转手势可切换视图模式';
    }
  }

  void _nextGesture() {
    setState(() {
      currentGestureIndex++;
    });
  }

  void _previousGesture() {
    setState(() {
      currentGestureIndex--;
    });
  }

  void _skipTutorial() {
    setState(() {
      isCompleted = true;
    });
    widget.onComplete?.call();
  }

  void _completeTutorial() {
    setState(() {
      isCompleted = true;
    });
    widget.onComplete?.call();
  }
}
