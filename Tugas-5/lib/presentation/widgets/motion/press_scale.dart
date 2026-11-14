import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Efek "menekan": anak mengecil sedikit saat disentuh + getar halus (opsional).
/// Memakai Listener sehingga tidak mengganggu gestur (tap/scroll) milik anak.
class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    this.scale = 0.96,
    this.haptic = true,
    this.enabled = true,
  });

  final Widget child;
  final double scale;
  final bool haptic;
  final bool enabled;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;
  Offset _start = Offset.zero;

  void _set(bool value) {
    if (_down == value) return;
    setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) {
        if (!widget.enabled) return;
        _start = e.position;
        _set(true);
        if (widget.haptic) HapticFeedback.selectionClick();
      },
      // Jika jari bergeser (mis. scroll), lepaskan efek tekan.
      onPointerMove: (e) {
        if (_down && (e.position - _start).distance > 10) _set(false);
      },
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down && widget.enabled ? widget.scale : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
