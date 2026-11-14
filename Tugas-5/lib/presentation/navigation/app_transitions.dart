import 'package:flutter/material.dart';

enum RouteStyle { fadeSlide, slideUp }

/// Transisi antar-layar: memudar + bergeser halus (dari samping atau dari bawah).
class AppTransitions {
  const AppTransitions._();

  static Route<T> route<T>(Widget page, {RouteStyle style = RouteStyle.fadeSlide}) {
    final begin = style == RouteStyle.slideUp ? const Offset(0, 0.18) : const Offset(0.08, 0);
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 340),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (context, animation, secondary, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(begin: begin, end: Offset.zero).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}
