import 'dart:async';

import 'package:dsh_app/state/commands_state.dart';
import 'package:dsh_app/state/connection_state.dart';
import 'package:dsh_app/state/hosts_state.dart';
import 'package:dsh_client/dsh_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../plugins/support/fake_plugin_host.dart';

/// Each test borrows a different host: the per-host catalog cache outlives a
/// container on purpose (that is what a new chat reuses).
var _hostId = 'a1';

const _appCommandNames = ['new', 'model', 'export', 'features'];

class _Active extends ActiveHostController {
  @override
  HostRef build() => HostRef.ssh(_hostId);
  @override
  void select(HostRef host) => state = host;
}

class _Connection extends Notifier<HostConnection?> {
  @override
  HostConnection? build() => null;
  void set(HostConnection? connection) => state = connection;
}

final _connection = NotifierProvider<_Connection, HostConnection?>(_Connection.new);

class _Client extends DshClient {
  _Client(this.fake) : super.withCarrier(fake);
  final FakePluginCarrier fake;
  List<SessionSummary> rows = [];
  final List<String> skillsAsked = [];
  int listCalls = 0;

  @override
  Future<List<SessionSummary>> listSessions() async {
    listCalls++;
    return rows;
  }

  /// Answers `skills/list` like the Host does, and records which session
  /// the new-chat palette borrowed.
  void serveSkills() {
    handlers['skills/list'] = (args) {
      final request = args['request'];
      final sessionId = request is Map ? request['sessionId'] : args['sessionId'];
      skillsAsked.add(sessionId as String? ?? '');
      return {
        'skills': [
          {'name': 'dsh-go-support', 'description': 'triage'},
        ],
      };
    };
  }

  Map<String, FutureOr<Object?> Function(Map<String, Object?> args)> get handlers => fake.handlers;
}

const _goalDescriptor = {
  'name': 'goal',
  'description': 'Set or view the goal',
  'input': {'hint': '[<objective>]'},
};

SessionSummary _row(String id, {String? origin}) => SessionSummary(
  sessionId: id,
  updatedAt: DateTime(2026, 11, 2),
  running: false,
  blank: false,
  agentAvailable: true,
  origin: origin,
);

HostConnection _host(_Client client, String id) =>
    HostConnection(client: client, label: id, isLocal: false, kind: HostKind.ssh, hostId: id);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  late ProviderContainer container;
  late _Client client;

  void boot() {
    client = _Client(FakePluginCarrier())..serveSkills();
    container = ProviderContainer(
      overrides: [
        activeHostProvider.overrideWith(_Active.new),
        activeConnectionProvider.overrideWith((ref) => AsyncData(ref.watch(_connection))),
      ],
    );
    container.read(_connection.notifier).set(_host(client, _hostId));
  }

  setUp(() {
    _hostId = 'a${DateTime.now().microsecondsSinceEpoch}';
    boot();
  });
  tearDown(() => container.dispose());

  Future<List<SlashCommand>> readNewChatCatalog() async {
    final provider = hostCommandsProvider(null);
    container.listen(provider, (_, _) {});
    return container.read(provider.future);
  }

  test('a new chat borrows the newest conversation host commands and skills', () async {
    client.fake.handlers['commands/list'] = (args) {
      expect(args['agentId'], 'newest', reason: 'the Host answers only for a real agent');
      return [_goalDescriptor, {'name': 'compact', 'description': 'Compact'}];
    };
    client.rows = [_row('child', origin: 'subagent'), _row('newest'), _row('older')];

    expect((await readNewChatCatalog()).map((c) => c.name), ['goal', 'compact']);
    expect(client.skillsAsked, ['newest'], reason: 'a subagent conversation is never borrowed');
    expect(container.read(slashCommandsProvider(null)).map((c) => c.name), [
      'new',
      'model',
      'compact',
      'goal',
      'export',
      'features',
      'dsh-go-support',
    ]);
    expect(container.read(newChatCatalogStaleProvider), isTrue);
  });

  test('a host with no conversation offers the app commands only, unmarked', () async {
    client.fake.handlers['commands/list'] = (_) => [_goalDescriptor];

    expect(await readNewChatCatalog(), isEmpty);
    expect(client.listCalls, 1);
    expect(container.read(slashCommandsProvider(null)).map((c) => c.name), _appCommandNames);
    expect(container.read(newChatCatalogStaleProvider), isFalse);
  });

  test('a refused lookup stays empty and is asked again, a later failure keeps the cache', () async {
    client.rows = [_row('newest')];
    client.handlers.remove('skills/list');
    expect(await readNewChatCatalog(), isEmpty, reason: 'the Host refused the catalog');
    expect(container.read(newChatCatalogRetryableProvider), isTrue, reason: 'the palette offers a retry');

    client.handlers['commands/list'] = (_) => [_goalDescriptor];
    client.serveSkills();
    container.invalidate(hostCommandsProvider(null));
    expect((await readNewChatCatalog()).single.name, 'goal', reason: 'a refused host is asked again');
    expect(container.read(newChatCatalogRetryableProvider), isFalse, reason: 'a successful borrow is not retryable');
    expect(container.read(newChatCatalogStaleProvider), isTrue, reason: 'and it says where the rows came from');

    client.handlers.remove('commands/list');
    container.invalidate(hostCommandsProvider(null));
    expect((await readNewChatCatalog()).single.name, 'goal', reason: 'the last catalog survives a refused call');
    final asked = client.listCalls;
    container.invalidate(hostCommandsProvider(null));
    await readNewChatCatalog();
    expect(client.listCalls, asked, reason: 'a borrowed catalog is asked for once, not per keystroke');
  });

  test('the borrowed catalog never leaves its host', () async {
    client.fake.handlers['commands/list'] = (_) => [_goalDescriptor];
    client.rows = [_row('newest')];
    expect((await readNewChatCatalog()).single.name, 'goal');

    _hostId = 'other-host';
    container.read(activeHostProvider.notifier).select(HostRef.ssh(_hostId));
    final other = _Client(FakePluginCarrier());
    container.read(_connection.notifier).set(_host(other, _hostId));
    expect(await readNewChatCatalog(), isEmpty);
    expect(container.read(slashCommandsProvider(null)).map((c) => c.name), _appCommandNames);
  });
}
