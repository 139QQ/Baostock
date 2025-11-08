import 'package:flutter/animation.dart';

/// 动画持续时间常量 (Animation Durations)
///
/// 定义应用中标准化的动画持续时间
class AnimationDurations {
  AnimationDurations._();

  // 基础持续时间
  /// 瞬时动画
  static const Duration instant = Duration.zero;

  /// 快速动画
  static const Duration fast = Duration(milliseconds: 150);

  /// 标准动画
  static const Duration normal = Duration(milliseconds: 250);

  /// 慢速动画
  static const Duration slow = Duration(milliseconds: 350);

  /// 更慢动画
  static const Duration slower = Duration(milliseconds: 500);

  // 特殊动画持续时间
  /// 微交互动画
  static const Duration microInteraction = Duration(milliseconds: 100);

  /// 页面转场动画
  static const Duration pageTransition = Duration(milliseconds: 300);

  /// 模态框转场动画
  static const Duration modalTransition = Duration(milliseconds: 200);

  /// 列表动画
  static const Duration listAnimation = Duration(milliseconds: 200);

  /// 卡片动画
  static const Duration cardAnimation = Duration(milliseconds: 180);

  /// 侧边栏动画
  static const Duration sidebarAnimation = Duration(milliseconds: 250);

  /// 淡入动画
  static const Duration fadeIn = Duration(milliseconds: 200);

  /// 上滑动画
  static const Duration slideUp = Duration(milliseconds: 300);

  /// 缩放动画
  static const Duration scaleAnimation = Duration(milliseconds: 150);

  /// 旋转动画
  static const Duration rotationAnimation = Duration(milliseconds: 400);

  /// 弹跳动画
  static const Duration bounceAnimation = Duration(milliseconds: 600);

  /// 脉冲动画
  static const Duration pulseAnimation = Duration(milliseconds: 1000);
}

/// 动画曲线常量 (Animation Curves)
///
/// 定义应用中标准化的动画曲线
class AnimationCurves {
  AnimationCurves._();

  // 基础曲线
  /// 线性曲线
  static const Curve linear = Curves.linear;

  /// 缓入曲线
  static const Curve easeIn = Curves.easeIn;

  /// 缓出曲线
  static const Curve easeOut = Curves.easeOut;

  /// 缓入缓出曲线
  static const Curve easeInOut = Curves.easeInOut;

  // 标准曲线
  /// 三次缓入曲线
  static const Curve easeInCubic = Curves.easeInCubic;

  /// 三次缓出曲线
  static const Curve easeOutCubic = Curves.easeOutCubic;

  /// 三次缓入缓出曲线
  static const Curve easeInOutCubic = Curves.easeInOutCubic;

  /// 二次缓入曲线
  static const Curve easeInQuad = Curves.easeInQuad;

  /// 二次缓出曲线
  static const Curve easeOutQuad = Curves.easeOutQuad;

  /// 二次缓入缓出曲线
  static const Curve easeInOutQuad = Curves.easeInOutQuad;

  /// 指数缓入曲线
  static const Curve easeInExpo = Curves.easeInExpo;

  /// 指数缓出曲线
  static const Curve easeOutExpo = Curves.easeOutExpo;

  /// 指数缓入缓出曲线
  static const Curve easeInOutExpo = Curves.easeInOutExpo;

  // 特殊曲线
  /// 弹跳缓入曲线
  static const Curve bounceIn = Curves.bounceIn;

  /// 弹跳缓出曲线
  static const Curve bounceOut = Curves.bounceOut;

  /// 弹跳缓入缓出曲线
  static const Curve bounceInOut = Curves.bounceInOut;

  /// 弹性缓入曲线
  static const Curve elasticIn = Curves.elasticIn;

  /// 弹性缓出曲线
  static const Curve elasticOut = Curves.elasticOut;

  /// 弹性缓入缓出曲线
  static const Curve elasticInOut = Curves.elasticInOut;

  // 自定义曲线
  /// 平滑曲线
  static const Curve smooth = Curves.fastOutSlowIn;

  /// 温和曲线
  static const Curve gentle = Curves.easeOutCubic;

  /// 轻快曲线
  static const Curve snappy = Curves.easeOutQuad;

  /// 戏剧性曲线
  static const Curve dramatic = Curves.elasticOut;
}

/// 动画配置类
///
/// 提供预定义的动画配置组合
class AnimationConfig {
  AnimationConfig._();

  /// 微交互动画配置
  static const Duration microDuration = AnimationDurations.microInteraction;

  /// 微交互曲线
  static const Curve microCurve = AnimationCurves.easeOutCubic;

  /// 页面转场动画配置
  static const Duration pageDuration = AnimationDurations.pageTransition;

  /// 页面转场曲线
  static const Curve pageCurve = AnimationCurves.easeInOutCubic;

  /// 模态框动画配置
  static const Duration modalDuration = AnimationDurations.modalTransition;

  /// 模态框曲线
  static const Curve modalCurve = AnimationCurves.easeOutCubic;

  /// 卡片动画配置
  static const Duration cardDuration = AnimationDurations.cardAnimation;

  /// 卡片动画曲线
  static const Curve cardCurve = AnimationCurves.easeOutQuad;

  /// 侧边栏动画配置
  static const Duration sidebarDuration = AnimationDurations.sidebarAnimation;

  /// 侧边栏动画曲线
  static const Curve sidebarCurve = AnimationCurves.easeOutCubic;

  /// 列表动画配置
  static const Duration listDuration = AnimationDurations.listAnimation;

  /// 列表动画曲线
  static const Curve listCurve = AnimationCurves.easeOutQuad;
}
