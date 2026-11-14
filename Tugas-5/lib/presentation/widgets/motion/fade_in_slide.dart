import 'dart:math' as math;

import 'package:flutter/material.dart';

bool _reduceMotion(BuildContext context) => MediaQuery.of(context).disableAnimations;

/// Muncul dengan fade + geser halus saat pertama kali tampil. [delay] untuk efek berurutan.
class FadeInSlide extends StatelessWidget {
  const FadeInSlide({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 420),
    this.offset = const Offset(0, 16),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    if (_reduceMotion(context)) return child;
    final total = duration + delay;
    final start = delay.inMilliseconds / total.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(start, 1.0, curve: Curves.easeOutCubic),
      child: child,
      builder: (_, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(offset.dx * (1 - t), offset.dy * (1 - t)), child: child),
      ),
    );
  }
}

/// Muncul dengan efek "membal" (skala dari kecil, sedikit melewati ukuran akhir).
class PopIn extends StatelessWidget {
  const PopIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 500),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (_reduceMotion(context)) return child;
    final total = duration + delay;
    final start = delay.inMilliseconds / total.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(start, 1.0, curve: Curves.easeOutBack),
      child: child,
      builder: (_, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.5 + 0.5 * t, child: child),
      ),
    );
  }
}

/// Membungkus daftar widget dengan [FadeInSlide] yang tertunda bertahap (stagger).
List<Widget> staggered(List<Widget> items, {int stepMs = 55, int maxMs = 400}) => [
      for (var i = 0; i < items.length; i++)
        FadeInSlide(delay: Duration(milliseconds: math.min(i * stepMs, maxMs)), child: items[i]),
    ];
