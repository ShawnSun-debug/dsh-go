// 上游 #211：`/` 只有作为输入框的首个 token 才唤起面板，与「输入框是否为空」无关。
// 这里直接测面板内容的判定（PaletteContent.of），不经过 widget 树。

import 'package:dsh_app/state/commands_state.dart';
import 'package:dsh_app/ui/chat/slash_palette.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/harness.dart';

void main() {
  final all = mergeSlashCommands(testHostCommands);

  PaletteContent? at(String text, {int? caret}) => PaletteContent.of(all, text, caret: caret);

  PaletteMatches matches(String text, {int? caret}) {
    final content = at(text, caret: caret);
    expect(content, isA<PaletteMatches>(), reason: 'expected the palette for ${text.replaceAll('\n', '\\n')}');
    return content! as PaletteMatches;
  }

  test('an empty box opens the palette on a bare slash', () {
    final content = matches('/');
    expect(content.typed, isFalse);
    expect(content.commands.length, all.length);
  });

  test('a slash placed at the front opens the palette with a draft behind the caret', () {
    // 复现 #211：先打「你好」，光标移到最前面，再打「/」。
    final content = matches('/你好', caret: 1);
    expect(content.typed, isFalse, reason: 'the draft after the caret is not the command name');
    expect(content.commands.map((c) => c.name), all.map((c) => c.name));
  });

  test('a slash after another token stays a plain message', () {
    expect(at('你好/'), isNull);
    expect(at('你好 /', caret: 4), isNull);
    expect(at('hello\n/', caret: 7), isNull);
    expect(at('hello\n/comp', caret: 11), isNull);
  });

  test('leading whitespace still counts as the first token', () {
    expect(matches('  /'), isA<PaletteMatches>());
    expect(matches('\n/comp', caret: 6).commands.map((c) => c.name), ['compact']);
  });

  test('only the text before the caret filters the rows', () {
    expect(matches('/comp', caret: 5).commands.map((c) => c.name), ['compact']);
    expect(matches('/compass', caret: 5).commands.map((c) => c.name), ['compact']);
    expect(matches('/comp', caret: 5).typed, isTrue);
  });

  test('a complete command with arguments shows its hint, not rows', () {
    final content = at('/plan ');
    expect(content, isA<PaletteHint>());
    expect((content! as PaletteHint).command.name, 'plan');
  });
}
