import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/attendance_status.dart';
import '../theme/register_theme.dart';

/// A custom widget that draws a "stamp" indicator for attendance status.
/// Implements the "stamp resolution" animation described in the design spec.
class RegisterStamp extends StatefulWidget {
  final AttendanceStatus? status;
  final double size;

  const RegisterStamp({
    super.key,
    required this.status,
    this.size = 24.0,
  });

  @override
  State<RegisterStamp> createState() => _RegisterStampState();
}

class _RegisterStampState extends State<RegisterStamp> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    // Scale up slightly then back to normal
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 60),
    ]).animate(_controller);
    
    // Slight rotate-settle
    _rotateAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.1).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.1, end: -0.05).chain(CurveTween(curve: Curves.easeInOut)), weight: 30),
      TweenSequenceItem(tween: Tween(begin: -0.05, end: 0.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 30),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(RegisterStamp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status != oldWidget.status) {
      final isResolved = widget.status == AttendanceStatus.present || 
                         widget.status == AttendanceStatus.absent ||
                         widget.status == AttendanceStatus.manualOverride;
      
      if (isResolved && oldWidget.status != widget.status) {
        // Trigger stamp animation if reduce motion is off
        if (!MediaQuery.disableAnimationsOf(context)) {
          _controller.forward(from: 0.0);
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotateAnimation.value,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: CustomPaint(
                painter: _StampPainter(
                  status: widget.status,
                  isDark: Theme.of(context).brightness == Brightness.dark,
                  colorScheme: Theme.of(context).colorScheme,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StampPainter extends CustomPainter {
  final AttendanceStatus? status;
  final bool isDark;
  final ColorScheme colorScheme;

  _StampPainter({
    required this.status,
    required this.isDark,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    if (status == null) {
      // Upcoming: Empty outline
      final paint = Paint()
        ..color = colorScheme.onSurface.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, radius - 1, paint);
    } else if (status == AttendanceStatus.ambiguous) {
      // Pending/Ambiguous: Dotted outline
      final ambiguousColor = isDark ? RegisterTheme.ambiguousDark : RegisterTheme.ambiguous;
      final paint = Paint()
        ..color = ambiguousColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      _drawDottedCircle(canvas, center, radius - 1, paint);
    } else {
      // Resolved: Solid + Check/Slash
      final isPresent = status == AttendanceStatus.present || status == AttendanceStatus.manualOverride;
      final bgColor = isPresent 
          ? (isDark ? RegisterTheme.presentDark : RegisterTheme.present)
          : (isDark ? RegisterTheme.absentDark : RegisterTheme.absent);

      final bgPaint = Paint()
        ..color = bgColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, bgPaint);

      final iconPaint = Paint()
        ..color = isDark ? RegisterTheme.paperDark : RegisterTheme.paper
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 2.0;

      if (isPresent) {
        // Draw checkmark
        final path = Path();
        path.moveTo(center.dx - radius * 0.4, center.dy + radius * 0.1);
        path.lineTo(center.dx - radius * 0.1, center.dy + radius * 0.4);
        path.lineTo(center.dx + radius * 0.4, center.dy - radius * 0.3);
        canvas.drawPath(path, iconPaint);
      } else {
        // Draw slash
        final path = Path();
        path.moveTo(center.dx - radius * 0.4, center.dy - radius * 0.4);
        path.lineTo(center.dx + radius * 0.4, center.dy + radius * 0.4);
        canvas.drawPath(path, iconPaint);
      }
    }
  }

  void _drawDottedCircle(Canvas canvas, Offset center, double radius, Paint paint) {
    const int dashCount = 12;
    const double dashAngle = (2 * math.pi) / (dashCount * 2);
    for (int i = 0; i < dashCount * 2; i++) {
      if (i % 2 == 0) {
        final startAngle = i * dashAngle;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          dashAngle,
          false,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StampPainter oldDelegate) {
    return status != oldDelegate.status || isDark != oldDelegate.isDark;
  }
}
