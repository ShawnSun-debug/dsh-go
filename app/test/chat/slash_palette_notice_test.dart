import 'package:dsh_app/state/commands_state.dart';
import 'package:dsh_app/ui/chat/slash_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/harness.dart';

void main() {
  setUpAll(loadTestFonts);

  const borrowedText = '来自上次对话，可能不含新装的技能';
  const retryText = '重试';

  Future<void> pump(WidgetTester tester, {bool borrowed = false, VoidCallback? onRetry}) async {
    final content = PaletteContent.of(mergeSlashCommands(testHostCommands), '/');
    expect(content, isA<PaletteMatches>());
    await tester.pumpWidget(
      testApp(
        Scaffold(
          body: Center(
            child: SizedBox(
              width: 340,
              child: SlashPalette(content: content!, onPick: (_) {}, borrowed: borrowed, onRetry: onRetry),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a borrowed catalog says where the rows came from', (tester) async {
    usePhoneView(tester);
    await pump(tester, borrowed: true);
    expect(find.text(borrowedText), findsOneWidget);
    expect(find.text(retryText), findsNothing);
  });

  testWidgets('a refused catalog offers a retry that fires once per tap', (tester) async {
    usePhoneView(tester);
    var taps = 0;
    await pump(tester, onRetry: () => taps++);
    expect(find.text(retryText), findsOneWidget);
    expect(find.text(borrowedText), findsNothing);
    await tester.tap(find.text(retryText));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('a live catalog adds neither line', (tester) async {
    usePhoneView(tester);
    await pump(tester);
    expect(find.text(retryText), findsNothing);
    expect(find.text(borrowedText), findsNothing);
    expect(find.byType(SlashPalette), findsOneWidget);
    // The notice never takes the palette's height budget: only rows remain.
    expect(tester.getSize(find.byType(SlashPalette)).height, lessThan(56.0 * 6));
  });
}
