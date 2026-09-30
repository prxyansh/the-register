import 'package:flutter/material.dart';
import '../data/attendance_status.dart';
import '../theme/register_theme.dart';
import 'register_stamp.dart';

/// A custom register row widget for displaying classes.
/// Implements the hairline rule and in-progress underline from the design spec.
class RegisterRow extends StatelessWidget {
  final String time;
  final String title;
  final String? subtitle;
  final AttendanceStatus? status;
  final double? progress; // 0.0 to 1.0 (null if not today/not live)
  final VoidCallback? onTap;
  final Widget? trailing;

  const RegisterRow({
    super.key,
    required this.time,
    required this.title,
    this.subtitle,
    this.status,
    this.progress,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 56,
                  child: Text(
                    time,
                    style: RegisterTheme.data(theme.colorScheme.onSurface),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: RegisterTheme.body(theme.colorScheme.onSurface).copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: RegisterTheme.bodySmall(
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                if (trailing != null) 
                  trailing!
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: RegisterStamp(status: status),
                  ),
              ],
            ),
          ),
          // Hairline rule at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 1,
              color: theme.dividerTheme.color,
            ),
          ),
          // In-progress underline (animated if updating)
          if (progress != null && progress! > 0 && progress! < 1)
            Positioned(
              left: 0,
              bottom: 0,
              child: _ProgressBar(
                progress: progress!, 
                color: isDark ? RegisterTheme.stampBlueDark : RegisterTheme.stampBlue,
              ),
            ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double progress;
  final Color color;
  
  const _ProgressBar({required this.progress, required this.color});
  
  @override
  Widget build(BuildContext context) {
    // We use MediaQuery to get full width.
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Disable animation if reduced motion is requested
    if (MediaQuery.disableAnimationsOf(context)) {
      return Container(
        height: 2,
        width: screenWidth * progress,
        color: color,
      );
    }
    
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: progress, end: progress),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Container(
          height: 2,
          width: screenWidth * value,
          color: color,
        );
      },
    );
  }
}
