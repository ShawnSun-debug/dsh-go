import 'package:dsh_app/l10n/l10n.dart';
import 'package:dsh_app/plugins/seams/seams.dart';
import 'package:dsh_app/state/engine_settings_state.dart';
import 'package:dsh_app/state/hosts_state.dart';
import 'package:dsh_app/state/plugins_state.dart';
import 'package:dsh_app/ui/engine_settings/engine_settings_page.dart' show namespaceTitle;
import 'package:dsh_app/ui/theme/theme.dart';
import 'package:dsh_client/dsh_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/english_preview.dart' show useEnglish;

class _Installed extends InstalledPluginsController {
  @override
  Future<List<PluginBundle>?> build() async => const [];
}

class _Settings extends EngineSettingsController {
  _Settings(this.data);
  final EngineSettings data;

  @override
  Future<EngineSettings?> build() async => data;
}

Map<String, Object?> _node(String type, {Map<String, Object?> meta = const {}, Object? value, List<Object?>? list, Map<String, Object?>? dict, Object? inner}) => {
  'type': type,
  if (meta.isNotEmpty) 'meta': meta,
  if (value != null) 'value': value,
  if (list != null) 'list': list,
  if (dict != null) 'dict': dict,
  if (inner != null) 'inner': inner,
};

Map<String, Object?> _const(Object value) => _node('const', value: value);

/// The dsh-superagent namespace as superagent's settings/describe entry
/// describes it: 14 fields, stateDir restart-required.
SettingsNamespaceView _superagentView() => SettingsNamespaceView.fromJson({
  'ns': 'dsh-superagent',
  'revision': 1,
  'value': {
    'stateDir': '/data/state/superagent',
    'approvalMode': 'L3',
    'budgetTokensPerEval': 0,
    'budgetTokensPerHour': 2000000,
    'budgetOnExceed': 'pause',
    'actionRoots': <Object?>[],
    'recordingMode': 'summary',
    'recordingRetentionDays': 7,
    'recordingMaxBytes': 104857600,
    'remoteChannel': true,
    'notifications': true,
    'promptMaxChars': 100000,
    'admissionContextMaxPages': 10,
    'admissionContextTimeoutMs': 15000,
  },
  'schema': _node('object', dict: {
    'stateDir': _node('string', meta: {'comment': 'restart-required', 'description': 'Directory for the database and locks.'}),
    'approvalMode': _node('union', list: [_const('L1'), _const('L2'), _const('L3')]),
    'budgetTokensPerEval': _node('number'),
    'budgetTokensPerHour': _node('number'),
    'budgetOnExceed': _node('union', list: [_const('pause'), _const('observe')]),
    'actionRoots': _node('array', inner: _node('string')),
    'recordingMode': _node('union', list: [_const('off'), _const('summary'), _const('full')]),
    'recordingRetentionDays': _node('number'),
    'recordingMaxBytes': _node('number'),
    'remoteChannel': _node('boolean'),
    'notifications': _node('boolean'),
    'promptMaxChars': _node('number'),
    'admissionContextMaxPages': _node('number'),
    'admissionContextTimeoutMs': _node('number'),
  }),
});

void main() {
  Future<void> pump(WidgetTester tester) async {
    final view = _superagentView();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          seatInventoryProvider.overrideWith(
            (ref) => const SeatInventory(
              packages: {
                'dsh-superagent': PluginClientInfo(
                  package: 'dsh-superagent',
                  hasClient: false,
                  rowIds: ['dsh-superagent'],
                  configNamespaces: ['dsh-superagent'],
                ),
              },
            ),
          ),
          installedPluginsProvider.overrideWith(_Installed.new),
          engineSettingsProvider.overrideWith(() => _Settings(EngineSettings(namespaces: {'dsh-superagent': view}))),
        ],
        child: MaterialApp(
          theme: buildLightTheme(),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: SchemaConfigSeat(
                occupant: SlotOccupant(slot: Slots.settingsSection, package: 'dsh-superagent', cell: 'dsh-superagent'),
                placement: SeatPlacement.page,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('the namespace has a human title', () {
    expect(namespaceTitle('dsh-superagent'), 'Superagent');
  });

  testWidgets('the Superagent section reads Chinese copy, not the schema English', (tester) async {
    await pump(tester);
    for (final label in ['状态目录', '审批模式', '单次评估 token 上限', '每小时 token 上限', '超额后的行为', '动作根目录', '录制模式', '录制保留天数', '录制总大小上限', '远程通道', '通知', '提示词上限', '评估读几页上下文', '上下文读取超时']) {
      expect(find.text(label, skipOffstage: false), findsWidgets, reason: 'missing field label: $label');
    }
    expect(find.textContaining('L3 先问我', skipOffstage: false), findsWidgets);
    expect(find.text('Directory for the database and locks.', skipOffstage: false), findsNothing);
    expect(find.text('改了要重启才生效', skipOffstage: false), findsOneWidget);
  });

  testWidgets('English locale shows the English copy and no Chinese', (tester) async {
    useEnglish();
    await pump(tester);
    expect(find.text('状态目录', skipOffstage: false), findsNothing);
    for (final label in ['State directory', 'Approval mode', 'Action roots', 'Notifications']) {
      expect(find.text(label, skipOffstage: false), findsWidgets, reason: 'missing field label: $label');
    }
  });
}
