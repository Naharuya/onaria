import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A quiet perimeter highlight. 53 logical pixels is approximately 10 mm on
/// the S22 Ultra's verified 375.78 dpi / 2.8125 device-pixel ratio setting.
class QuietComposerFrame extends StatefulWidget {
  const QuietComposerFrame(
      {super.key, required this.child, this.active = true});
  final Widget child;
  final bool active;
  @override
  State<QuietComposerFrame> createState() => _QuietComposerFrameState();
}

class _QuietComposerFrameState extends State<QuietComposerFrame>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _phase;
  bool _motionAllowed = false;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    _phase =
        AnimationController(vsync: this, duration: const Duration(seconds: 10));
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final media = MediaQuery.maybeOf(context);
    _motionAllowed = TickerMode.of(context) &&
        !(media?.disableAnimations ?? false) &&
        !(media?.accessibleNavigation ?? false);
    _sync();
  }

  @override
  void didUpdateWidget(covariant QuietComposerFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }

  void _sync() {
    if (!_motionAllowed || !_foreground || !widget.active) {
      _phase.stop();
    } else if (!_phase.isAnimating) {
      _phase.repeat();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _phase.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return RepaintBoundary(
        child: CustomPaint(
      foregroundPainter: _ComposerBorder(_phase, accent),
      child: RepaintBoundary(
          child:
              Padding(padding: const EdgeInsets.all(8), child: widget.child)),
    ));
  }
}

class _ComposerBorder extends CustomPainter {
  _ComposerBorder(this.phase, this.accent) : super(repaint: phase);
  final Animation<double> phase;
  final Color accent;
  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(1), const Radius.circular(24)));
    canvas.drawPath(
        path,
        Paint()
          ..color = accent.withValues(alpha: .18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .8);
    final metric = path.computeMetrics().first;
    final length = math.min(53.0, metric.length);
    final start = phase.value * metric.length;
    final end = start + length;
    final segment = metric.extractPath(start, math.min(end, metric.length));
    if (end > metric.length)
      segment.addPath(metric.extractPath(0, end - metric.length), Offset.zero);
    canvas.drawPath(
        segment,
        Paint()
          ..color = accent.withValues(alpha: .18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
    canvas.drawPath(
        segment,
        Paint()
          ..color = accent.withValues(alpha: .75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _ComposerBorder oldDelegate) =>
      oldDelegate.accent != accent || oldDelegate.phase != phase;
}
