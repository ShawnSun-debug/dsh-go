// 拉抽屉时顶栏不该被 scrim 压成「底色没了、图标还在」的样子，而应随抽屉一起让开。

import 'package:dsh_app/ui/shell/drawer_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chrome opacity falls from 1 to 0 with the drawer and clamps overshoot', () {
    expect(drawerChromeOpacity(0), 1);
    expect(drawerChromeOpacity(0.5), 0.5);
    expect(drawerChromeOpacity(1), 0);
    expect(drawerChromeOpacity(1.2), 0);
    expect(drawerChromeOpacity(-0.2), 1);
  });

  testWidgets('the chrome follows the drawer animation frame by frame', (tester) async {
    final controller = AnimationController(vsync: const TestVSync(), duration: const Duration(milliseconds: 200));
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: DrawerChromeScope(progress: controller, child: const DrawerChrome(child: Text('header'))),
      ),
    );

    double opacity() => tester.widget<Opacity>(find.byType(Opacity)).opacity;

    expect(opacity(), 1, reason: 'a closed drawer leaves the header alone');
    controller.value = 0.4;
    await tester.pump();
    expect(opacity(), closeTo(0.6, 1e-9));
    controller.value = 1;
    await tester.pump();
    expect(opacity(), 0, reason: 'an open drawer owns the header area');
  });

  testWidgets('without a scope the chrome is the page as is', (tester) async {
    await tester.pumpWidget(
      const Directionality(textDirection: TextDirection.ltr, child: DrawerChrome(child: Text('header'))),
    );
    expect(find.byType(Opacity), findsNothing);
    expect(find.text('header'), findsOneWidget);
  });
}
