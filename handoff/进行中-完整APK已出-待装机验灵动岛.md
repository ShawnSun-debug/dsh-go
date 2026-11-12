# 交接：dsh-go fork · 完整 APK 已出，等装机验灵动岛

日期：2026-10-31 ｜ 分支：`feat/live-progress-107` ｜ 仓库：`D:\DSH go fork`（GitHub `ShawnSun-debug/dsh-go`，上游 `ccch1mneyyy/dsh-Go`）

## 1. 摘要

目标是给 DSH Go 加「Live Updates：锁屏/灵动岛上实时看回合进度」。代码已经合到 1.0.7 基线上并通过 CI 编译，**但前两次给的 APK 都装不上**（薄包缺 runtime 载荷，报「App 内的运行环境包不完整」）。第三次已改成「搬上游 v1.0.7 官方 runtime 载荷」再打包，**完整包（195.4 MB）已下载到本地**，装机验证尚未进行。项目上下文与踩坑记录在 `CONTEXTS.md`（硬链接 → `D:\Agent Contexts\dsh-go-fork.md`）。

## 2. 下一步第一步

**执行者：用户（装包）+ 下一个会话（看结果）。**

1. 让用户装：`D:\DSH go fork\_artifacts\dsh-go-1.0.7-arm64-liveprogress-full.apk`（195.4 MB，204,913,532 字节，CRC32 `7793f18f`）。若签名冲突先卸旧版。
2. 装机后跑一个回合，问用户三件事：通知里有没有「第 N 步 · 工具名」、有 todo 时百分比走不走、回合结束是否立刻消失。
3. 看不到就抓日志（这一步别猜，先拿证据）：
   ```
   adb logcat -c; adb logcat | Select-String -Pattern "LiveUpdater|dsh/notify|PromotedOngoing"
   ```
   然后对 `app/android/app/src/main/kotlin/io/github/ccch1mneyyy/dsh_app/notify/LiveUpdater.kt` 与 `app/lib/notify/live_progress.dart` 的自检结果。

## 3. 回滚路径

- **代码**：一切都在 `feat/live-progress-107` 上，干净点 `db286be`（= 1.0.7 + 灵动岛 + 进度功能，CI 已验过编译）。
  - 撤销本轮 CI 改动：`git revert 3098bf1 0f5e049`，或直接 `git reset --hard db286be`（会丢掉两个 commit，工作树无其它改动，安全）。
  - 旧 workflow 内容见 `git show db286be:.github/workflows/android-apk.yml`（47 行，只 `flutter build apk`，产出薄包）。
- **产物**：`_artifacts/` 在 `.git/info/exclude` 里，删掉不影响 git。完整包丢了可用 run [41209636991](https://github.com/ShawnSun-debug/dsh-go/actions/runs/41209636991) 的 artifact `dsh-go-apk-full` 重新拉（方法见「未决问题 4」）。
- **运行时载荷**：本轮的 runtime 是从上游 v1.0.7 release 抽的，没改仓库里任何 `runtime/` 文件，无需回滚。

## 4. 未决问题

1. **上次手机环境被删到 27.2 MB（原本约 195 MB）的原因仍未查明。** 已排除 CI 的 free-disk 步骤（只动 runner 目录）。用户对此极其敏感，任何清理动作都要先说明范围。
2. **版本号与官方不对齐**：`app/pubspec.yaml` 仍是 `1.0.4+1`，CI 没走 `tooling/build-apk.sh`，因此没传 `--build-name/--build-number`（走 Gradle 的 buildMinute 兜底）。正式发版需要对上。
3. **`runtime/build-runtime.sh` 目前是坏的**：钉死的 `proot 5.1.107.98` 已从 Termux 索引整个消失（`binary-aarch64/Packages` 里 `Package: proot` 一条都没有），跑到一半必 die。要不要修 pin、以及改为自建 runtime，是没定的决策。
4. **完整包依赖上游 release 资产**：workflow 里硬编码了 v1.0.7 的 URL 与 sha256 `18d3f8d8…c322a`。上游发新版必须同步改这两处，否则 CI 会静默搬旧载荷。
5. **`LiveUpdater` 只维护单个 `sessionId`**，两个会话同时跑会互相覆盖通知（已知限制，未修）。
6. **灵动岛依赖 Android 16 / API 36 的 promoted ongoing**；用户手机上是否支持、是否被系统降级成普通通知，尚未验证。
7. **工作区有 4 个未跟踪条目不是我建的**：`.gh-issues/`、`AGENTS.md`、`community-demands.md`、`docs/agents/`。来源不明，本轮一律没动。
8. **单连接下载只有 30–40 KB/s**，签名直链约 30–60 分钟过期，过期后 Range 请求返回 403（body ≈544 字节 XML）。下次拉大包必须先刷新直链、16 路并发、边下边校验 CRC，否则会像本轮一样拼出坏数据。

## 5. 建议技能

- `/code-architecture`：装机前想再审一遍 `app/lib/notify/live_progress.dart` 与 `chat_alerts.dart` 的接线（`_liveBegin`/`_liveEnd`、dispose 时的收尾）。
- `/systematic-debugging`：如果灵动岛不出现——先取证（logcat + 通知渠道状态），不要直接改代码。
- `/verification-before-completion`：任何「修好了」的说法之前，把 logcat 证据贴出来。
- `/handoff`：装机验完之后再交接一次。

## 6. 票状态（现场）

没有找到 `.scratch/<feature>/issues/`（本仓库不用这套）。工作项记在 fork 的 GitHub issues 上，约定见 `docs/agents/issue-tracker.md`、`docs/agents/triage-labels.md`。

## 7. git 现场

```
$ git log -1 --oneline
0f5e049 ci: runtime 载荷改从上游 v1.0.7 release 取（proot pin 已失效）

$ git status --short
?? .gh-issues/
?? AGENTS.md
?? community-demands.md
?? docs/agents/
```

（分支 `feat/live-progress-107`，工作树其余干净；`handoff/` 与 `_artifacts/` 是本轮新增的本地目录。）

## 关键文件地图

- 进度逻辑：`app/lib/notify/live_progress.dart`（新建，`LiveTurnProgress`，900 ms 节流）
- 通知接线：`app/lib/notify/chat_alerts.dart`（`_liveProgress` 表、`_liveBegin`/`_liveEnd`，约 480–610 行）
- 注入点：`app/lib/state/notify_state.dart`（约 383 行，`watchSession`）
- 安卓侧：`app/android/app/src/main/kotlin/.../notify/LiveUpdater.kt`（percent 或 text 变化都会重发）
- CI：`.github/workflows/android-apk.yml`（先搬上游 runtime 载荷 → `flutter build apk --flavor arm64`）
- Flavor 与载荷路径：`app/android/app/build.gradle.kts` 第 49–80 行
- 项目上下文：`CONTEXTS.md` ↔ `D:\Agent Contexts\dsh-go-fork.md`

## 既往证据

- 薄包（装不上）：run [41205006186](https://github.com/ShawnSun-debug/dsh-go/actions/runs/41205006186)，APK 46.5 MB，缺 `assets/runtime/`
- 完整包（本轮）：run [41209636991](https://github.com/ShawnSun-debug/dsh-go/actions/runs/41209636991)，APK 195.4 MB，含 `rootfs-arm64-v8a.tar.xz` 151 MB + manifest + 4 个 proot 相关 .so
