import 'package:flutter/material.dart';

import '../../../widgets/motion/press_scale.dart';

class GoogleButton extends StatelessWidget {
  const GoogleButton({super.key, required this.onPressed, this.enabled = true, this.loading = false});

  final VoidCallback onPressed;
  final bool enabled;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      enabled: enabled && !loading,
      child: OutlinedButton(
        onPressed: enabled && !loading ? onPressed : null,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: Tween(begin: 0.85, end: 1.0).animate(animation), child: child),
          ),
          child: loading
              ? const SizedBox(key: ValueKey('loading'), width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
              : Row(
                  key: const ValueKey('idle'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Text('G', style: TextStyle(color: Color(0xFF4285F4), fontWeight: FontWeight.w900, fontSize: 17)),
                    ),
                    const SizedBox(width: 12),
                    const Text('Lanjutkan dengan Google', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ],
                ),
        ),
      ),
    );
  }
}
