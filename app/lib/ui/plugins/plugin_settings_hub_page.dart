// 插件设置一页到底：每个已安装插件一行。能在这里改的直接进原生表单，
// 只能在自己的网页界面里改的，点开详情，那里给「在网页版打开」（ticket #10）。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../plugins/native/native_state.dart' show nativePluginTitleProvider;
import '../../plugins/seams/seams.dart' show PluginSeat, SeatPlacement, Slots, seatPlanProvider;
import '../../state/plugin_config/plugin_config_state.dart';
import '../../state/plugins_state.dart';
import '../common/list_page_row.dart';
import '../shell/page_frame.dart';
import 'config/plugin_config_entries.dart';
import 'config/plugin_config_page.dart';
import 'plugin_detail_sheet.dart' show showBundleSheet;
import 'plugin_widgets.dart' show PluginAvatar;

/// 所有插件的设置，按插件名排一列。
///
/// 三种形态各给一个去处：
/// - 一个命名空间有原生表单 —— 直接进那张表单，不再经过插件详情；
/// - 多个命名空间 —— 进插件详情，那里逐条列出；
/// - 只有自己的网页界面 —— 同上进详情，右侧写「在网页版打开」。
class PluginSettingsHubPage extends ConsumerWidget {
  const PluginSettingsHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(installedPluginsProvider);
    final config = ref.watch(pluginConfigProvider).value;
    final bundles = async.value;

    if (bundles == null) {
      return AppPage.list(
        title: l10n.commonSettings,
        subtitle: Text(l10n.hubPlugins),
        children: [
          ListPageCard(
            children: [
              ListPageRow(
                title: async.hasError ? l10n.pluginsLoadFailed : l10n.hubPlugins,
                value: async.hasError ? l10n.commonRetry : null,
                chevron: false,
                onTap: async.hasError ? () => retryPluginList(ref) : null,
              ),
            ],
          ),
        ],
      );
    }

    final visible = [
      for (final bundle in bundles)
        if (bundle.enabled && bundleGroup(bundle) != BundleGroup.hidden) bundle,
    ];
    final titles = {
      for (final bundle in visible) bundle.name: _titleOf(ref, bundle),
    };
    visible.sort((a, b) => titles[a.name]!.toLowerCase().compareTo(titles[b.name]!.toLowerCase()));

    final rows = <Widget>[];
    for (final bundle in visible) {
      final entries = bundleConfigRows(bundle, config);
      final only = entries.length == 1 ? entries.single : null;
      final webOnly = entries.isEmpty && _hasOwnWebPage(ref, bundle);
      rows.add(
        ListPageRow(
          leading: PluginAvatar(
            name: bundle.name,
            title: titles[bundle.name],
            icon: bundle.meta?.icon,
            size: 32,
          ),
          leadingWidth: 40,
          title: titles[bundle.name],
          subtitle: titles[bundle.name] == bundle.name ? null : bundle.name,
          value: webOnly ? l10n.commonOpenInWeb : null,
          chevron: true,
          onTap: () {
            if (only != null) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => PluginConfigPage(ns: only.rowId)),
              );
              return;
            }
            showBundleSheet(context, bundle);
          },
        ),
      );
    }

    return AppPage.list(
      title: l10n.commonSettings,
      subtitle: Text(l10n.hubPlugins),
      children: [
        if (rows.isEmpty)
          ListPageCard(
            children: [ListPageRow(title: l10n.hubPlugins, chevron: false)],
          )
        else
          ListPageCard(children: rows),
      ],
    );
  }

  /// 插件给人们看的名字：它自己的原生标题，没有就是包名。
  String _titleOf(WidgetRef ref, PluginBundle bundle) {
    final native = ref.watch(nativePluginTitleProvider(bundle.name)).trim();
    return native.isEmpty ? bundle.name : native;
  }

  /// 第三方插件没有原生字段，但有自己的配置页（网页岛或 DSH Web）。
  bool _hasOwnWebPage(WidgetRef ref, PluginBundle bundle) {
    if (bundle.official) return false;
    final seat = PluginSeat(slot: Slots.bundleConfig, placement: SeatPlacement.row, package: bundle.name);
    return !ref.watch(seatPlanProvider(seat.request)).isEmpty;
  }
}
