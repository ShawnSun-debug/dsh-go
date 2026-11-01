// The chrome the drawer slides over: it steps aside with the drawer instead of
// being dimmed by the scrim.
//
// A scrim is a plain dark layer, and a glass button is almost all fill: cover it
// and the fill disappears while the icon stays bright, which reads as "the
// button turned transparent" and shifts with every drag frame. Fading the chrome
// itself keeps one clean motion, tied to the same animation as the panel.

import 'package:flutter/widgets.dart';

/// 1 with the drawer closed, 0 when it is fully over the page.
double drawerChromeOpacity(double progress) => (1 - progress).clamp(0.0, 1.0);

/// Publishes the drawer's progress to the chrome underneath it.
///
/// It carries the animation, not its value: the chrome listens to it and
/// rebuilds one opacity, while the page below never rebuilds as the drawer
/// moves.
class DrawerChromeScope extends InheritedWidget {
  const DrawerChromeScope({super.key, required this.progress, required super.child});

  final Animation<double> progress;

  static Animation<double>? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DrawerChromeScope>()?.progress;

  @override
  bool updateShouldNotify(DrawerChromeScope oldWidget) => progress != oldWidget.progress;
}

/// Fades [child] as the drawer comes over it. Without a [DrawerChromeScope]
/// (secondary pages, tests) it is the child, unchanged.
class DrawerChrome extends StatelessWidget {
  const DrawerChrome({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final progress = DrawerChromeScope.maybeOf(context);
    if (progress == null) return child;
    return AnimatedBuilder(
      animation: progress,
      child: child,
      builder: (context, child) => Opacity(opacity: drawerChromeOpacity(progress.value), child: child),
    );
  }
}
