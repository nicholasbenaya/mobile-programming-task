import 'package:flutter/material.dart';

import '../../../widgets/motion/fade_in_slide.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, required this.subtitle});
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        PopIn(
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [scheme.primary, scheme.tertiary],
              ),
              boxShadow: [BoxShadow(color: scheme.primary.withValues(alpha: 0.3), blurRadius: 18, offset: const Offset(0, 8))],
            ),
            child: Icon(Icons.explore_rounded, size: 42, color: scheme.onPrimary),
          ),
        ),
        const SizedBox(height: 18),
        FadeInSlide(
          delay: const Duration(milliseconds: 150),
          child: Text('SensorLog', style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        ),
        const SizedBox(height: 6),
        FadeInSlide(
          delay: const Duration(milliseconds: 250),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              subtitle,
              key: ValueKey(subtitle),
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ),
      ],
    );
  }
}
