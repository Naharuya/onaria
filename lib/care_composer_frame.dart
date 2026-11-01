import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 38 logical pixels approximates 10 CSS mm; physical length varies by display.
class CareComposerFrame extends StatefulWidget {
  const CareComposerFrame(
      {super.key, required this.child, this.active = true, this.color});
  final Widget child;
  final bool active;
  final Color? color;
  @override
  State<CareComposerFrame> createState() => _CareComposerFrameState();
}

class _CareComposerFrameState extends State<CareComposerFrame>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController motion =
      AnimationController(vsync: this, duration: const Duration(seconds: 10));
  bool focused = false;
  bool foreground = true;
  bool allowed = false;
  bool get showHighlight => widget.active && !focused && foreground && allowed;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    foreground = state == null || state == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final media = MediaQuery.maybeOf(context);
    allowed = TickerMode.valuesOf(context).enabled &&
        !(media?.disableAnimations ?? false) &&
        !(media?.accessibleNavigation ?? false);
    sync();
  }

  @override
  void didUpdateWidget(covariant CareComposerFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    sync();
  }

  void sync() {
    if (showHighlight) {
      if (!motion.isAnimating) motion.repeat();
    } else {
      motion.stop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      foreground = state == AppLifecycleState.resumed;
    });
    sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    return Focus(
      canRequestFocus: false,
      onFocusChange: (value) {
        setState(() {
          focused = value;
        });
        sync();
      },
      child: RepaintBoundary(
        child: Stack(children: [
          DecoratedBox(
              key: const ValueKey('care-composer-outline'),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: color.withValues(alpha: .16), width: .8)),
              child: Padding(
                  padding: const EdgeInsets.all(8), child: widget.child)),
          if (showHighlight)
            Positioned.fill(
                child: IgnorePointer(
                    child: CustomPaint(
                        key: const ValueKey('care-composer-highlight'),
                        painter: _Highlight(color, motion)))),
        ]),
      ),
    );
  }
}

class _Highlight extends CustomPainter {
  _Highlight(this.color, this.motion) : super(repaint: motion);
  final Color color;
  final Animation<double> motion;
  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(.75), const Radius.circular(24)));
    final metric = path.computeMetrics().first;
    final length = math.min(38.0, metric.length);
    final start = motion.value * metric.length;
    final end = start + length;
    final paint = Paint()
      ..color = color.withValues(alpha: .48)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
        metric.extractPath(start, math.min(end, metric.length)), paint);
    if (end > metric.length) {
      canvas.drawPath(metric.extractPath(0, end - metric.length), paint);
    }
  }

  @override
  bool shouldRepaint(_Highlight old) =>
      old.color != color || old.motion != motion;
}
