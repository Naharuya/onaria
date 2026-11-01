import 'package:flutter/material.dart';

import 'app_theme.dart';

/// A static light halo connects the native app to the Quiet Light website.
class SpaceScaffold extends StatelessWidget {
  const SpaceScaffold({super.key, this.appBar, required this.body});

  final PreferredSizeWidget? appBar;
  final Widget body;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
                child:
                    CustomPaint(painter: _SpacePainter(AppTheme.of(context)))),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: appBar,
            body: body,
          ),
        ],
      );
}

class _SpacePainter extends CustomPainter {
  const _SpacePainter(this.palette);
  final AppPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = palette.cream);
    canvas.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(0.9, -0.8),
            radius: 1.2,
            colors: [palette.sage, palette.cream.withValues(alpha: 0)],
          ).createShader(rect));
    canvas.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            center: Alignment(-1, 0.6),
            radius: 0.9,
            colors: [
              palette.green.withValues(alpha: 0.12),
              palette.green.withValues(alpha: 0)
            ],
          ).createShader(rect));
    // Quiet Light: a soft static halo echoes the website without video decoding,
    // motion sensitivity, extra network traffic, or an idle animation ticker.
    final center = Offset(size.width * .84, size.height * .24);
    final halo = Rect.fromCenter(
        center: center, width: size.width * .88, height: size.width * 1.08);
    canvas.drawOval(
        halo,
        Paint()
          ..color = palette.green.withValues(alpha: .13)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 22
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18));
    canvas.drawOval(
        halo,
        Paint()
          ..color = palette.green.withValues(alpha: .18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
    canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              palette.cream.withValues(alpha: .08),
              palette.cream.withValues(alpha: .9)
            ],
          ).createShader(rect));
  }

  @override
  bool shouldRepaint(covariant _SpacePainter oldDelegate) =>
      oldDelegate.palette.scheme != palette.scheme;
}
