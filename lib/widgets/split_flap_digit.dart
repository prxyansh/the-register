import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A custom widget that animates number changes with a split-flap departure
/// board style transition.
class SplitFlapDigit extends StatelessWidget {
  final int value;
  final TextStyle textStyle;

  const SplitFlapDigit({
    super.key,
    required this.value,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return Text(value.toString(), style: textStyle);
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      // Use layoutBuilder to keep digits aligned during transition
      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
        return Stack(
          alignment: Alignment.center,
          children: <Widget>[
            ...previousChildren,
            ?currentChild,
          ],
        );
      },
      transitionBuilder: (Widget child, Animation<double> animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, childWidget) {
            // animation.value goes 0 -> 1 for incoming child
            // animation.value goes 1 -> 0 for outgoing child
            
            final isIncoming = child.key == ValueKey<int>(value);
            
            // Incoming flips from -90 to 0. Outgoing flips from 0 to 90.
            final angle = isIncoming 
                ? (1 - animation.value) * -math.pi / 2
                : (1 - animation.value) * math.pi / 2;
                
            // Opacity: fade in the second half of the flip
            final opacity = isIncoming 
                ? (animation.value > 0.5 ? 1.0 : 0.0)
                : (animation.value > 0.5 ? 1.0 : 0.0);

            final transform = Matrix4.identity()
              ..setEntry(3, 2, 0.002) // Perspective
              ..rotateX(angle);

            return Opacity(
              opacity: opacity,
              child: Transform(
                transform: transform,
                alignment: Alignment.center,
                child: childWidget,
              ),
            );
          },
          child: child,
        );
      },
      child: Text(
        value.toString(),
        key: ValueKey<int>(value),
        style: textStyle,
      ),
    );
  }
}
