# 交接：superagent v0.2 已发布待合，联动 dsh-go 前两张已合入

## 摘要

superagent 插件的四提案（票 01–12）已合入 main（PR #14，main @ 2765c0c）。这一轮做 v0.2 验收债（规格 #15）+ 与 dsh-go 联动的前两张（规格 #23）：集成分支 `feature/v0.2-verification-debt` @ `666e02b` 已推 origin，draft PR **#21**。

已合入：票 #16 typecheck 归零、#17 Windows 平台分派（全量 0 failed）、#20 v0.2.0 发布与迁移、#24 设置命名空间、#25 审批投影契约。最终验证：`tsc` 0 错误，全量 **1395 passed / 0 failed / 33 skipped**。

没做的：#26–#29 四张联动票未开工（dsh-go 侧一行代码没动），code review 未跑，PR #21 仍是 draft，也没有向上游提 issue。用户明确要求「跑完现有子代理就停」，所以停在这里。

## 下一步第一步

在 `D:\Agent Workspace\superagent-proposals\repo`（当前分支 `feature/v0.2-verification-debt` @ `666e02b`）跑 `skill` 工具加载 **code-architecture**（code-review 成员），对 PR #21 做两轴审查：

```powershell
cd 'D:\Agent Workspace\superagent-proposals\repo'
git -c safe.directory='*' log --oneline main..HEAD   # 待审 5 个 merge commit
```

审出的问题交给**一个**实施子代理修（worktree 从 `666e02b` 起），修完再 `gh pr ready 21 --repo ShawnSun-debug/dsh-superagent-prototype`；合并 PR 由用户决定。

若用户要的是联动而不是收口，则改为启动 #26（dsh-go 原生设置页，Blocked by #24 已完成），worktree 从 `666e02b` 起，目标仓库是 `D:\DSH go fork`。

## 回滚路径

- **main 未被污染**：main @ `2765c0c`（PR #14 的 merge commit），本轮所有改动都在 `feature/v0.2-verification-debt`。不想要就直接关 PR #21，`git -C repo checkout main`。
- **丢弃整条分支**：`git -C repo branch -D feature/v0.2-verification-debt`（远端：`git -C repo push origin --delete feature/v0.2-verification-debt`）。
- **清理 worktree**（t14–t20，各票分支）：`git -C repo worktree remove <path> --force`，再 `git -C repo worktree prune`。
- **证据不能删**：`D:\Agent Workspace\superagent-proposals\evidence-t12\`（票 12 验收矩阵、host-mount、real 场景 JSON）与票目录 `outputs\superagent-tickets\*.md` 完成记录，回滚只回代码，证据留着。
- **v0.2 行为变化要一起回滚**：`stateDir` 现在是 volatile + restart-required，且旧 Store 里的预算/录制值会被命名空间默认值覆盖（见 `docs/006-deployment.md`）；只回代码不回状态库的话，先在 Deployment 页重设一次。

## 未决问题

1. **skipped 33 是否接受**：30 个 POSIX-only 夹具显式 `skipIf(win32)` + 3 个 opt-in 真实检查。票 #17 只要求「每个跳过有原因、清单入文档」，我口头给过「≤7」的口气，实际不可能不移植夹具就做到。要压到 7 得把 `/bin/sh` 假件整套移植成 `.cmd`（另开票量级）。
2. **#18 与 #13 未收口**：票 12 场景 10（真实 live）是 `unavailable-data`——`~/.dsh/.credentials.yaml` 由原生凭据库保护，Agent 读取被拒，环境无 `DSH_LIVE_API_KEY`。补跑命令在票 #18 的 comment 里。要不要用户自己跑一次把 #18/#13 关掉，未定。
3. **`private: true` 未改**：发 GitHub Release tarball 没问题；要 `npm publish` 得改 false（票 #20 没被授权动这个字段）。
4. **peer 范围**：`dsh-*` 21 个 peer 保持 `^0.2.1-alpha.2`（不是字面 rc 下限），刻意扩大兼容面；若评审要求收紧需先确认 registry 有 rc.3 全量包。
5. **上游提案形态**（#29 未开工）：默认按 issue + patch 分支，不直接开 PR；需要用户确认，且要写出利弊与回滚（用户明确要这两项）。
6. **#22 Windows 垫片**：`writeEnvironment` 只写 `/bin/sh`，Windows worker 的 gh/lark-cli 不可执行，已单开 #22 但未排期。
7. **#24 缺真机验收**：dsh-go 原生设置页渲染没在安卓上验过（本机无设备），只用宿主同版本 `SettingsForms` 验了 describe/mutate 契约；#28 真机票要补。
8. **并发 flake**：`tests/panel-execution.spec.tsx` 在满并发全量下会假红（单跑通过），`--maxWorkers=4` 稳定；不要把它当回归。
9. **AGPL 边界**：dsh-go 是 AGPL-3.0、superagent 是 MIT，联动只能走契约（settings schema / 审批投影 / 凭据 RPC），代码不要互相拷。
10. **交接落在哪**：这份写在当前工作区 `D:\DSH go fork\handoff`（该目录已有两份 dsh-go 交接与 INDEX）。若希望在 superagent 工作区另存一份，复制过去即可——两个目录目前只有这一份提到 superagent。

## 建议技能

- **`code-architecture`** —— code-review 入口（本轮未跑，第一步就是它）。
- **`implement-spec`** —— 继续 #26–#29 的票执行（票图与规格在 GitHub）。
- **`verification-before-completion`** —— 声明「全绿 / 已发布」之前强制跑证据。
- **`grill`** —— 上游提案的措辞、利弊、回滚论证（#29）。
- **`to-spec` / `to-tickets`** —— 只由用户手敲；不要让模型代触发。
- **`diagnose-windows-sandbox-acl`** —— 若 Windows 上再出现写/读失败。

## 票状态（现场）

当前工作区没有 `.scratch/<feature>/issues/`；票在 GitHub issue tracker（`ShawnSun-debug/dsh-superagent-prototype`）。下表「实现」是代码是否已进集成分支，「票面」是 issue 是否已关。

| 票 | 标题 | 实现 | 票面 | Blocked by |
|---|---|---|---|---|
| #15 | v0.2 规格 | — | open | — |
| #16 | typecheck 归零 | 已合入 | open | — |
| #17 | Windows 平台分派 | 已合入 | open | — |
| #18 | 真实 live 验收 | 入口已合入，场景 10 unavailable-data | open | 用户凭据（外部） |
| #19 | 宿主挂载验收 | 已合入（真实宿主跑过） | open | — |
| #20 | v0.2.0 发布与迁移 | 已合入 | open | #16/#17/#19（已满足） |
| #22 | Windows worker 垫片 | 未开工 | open | — |
| #23 | 联动规格 | — | open | — |
| #24 | 设置命名空间 | 已合入 | open | — |
| #25 | 审批投影契约 | 已合入 | open | — |
| #26 | dsh-go 原生设置页 | 未开工 | open | #24（已满足，可立即开工） |
| #27 | dsh-go 原生审批 | 未开工 | open | #25（已满足，可立即开工） |
| #28 | 能力与 SAF 动作根 | 未开工 | open | #26、#27 |
| #29 | 上游提案 | 未开工 | open | #28、#20（#20 已满足） |
| #13 | 票 12 联调 | 场景 1–9 有证据 | open | 场景 10 需凭据 |

**能立刻开工的**：#26、#27、#22（互不阻塞）。

## git 现场

superagent 仓库（`D:\Agent Workspace\superagent-proposals\repo`）：工作树干净；`HEAD = 666e02b build: 重建 lib（票 #24 设置命名空间与 #25 审批投影）`。

```
## git status --short → 无输出（干净）
## 分支：feature/v0.2-verification-debt（*）、feature/superagent-four-proposals、main
## 票分支：ticket/16… ticket/25（各自 worktree t14–t20 都在）
```

dsh-go fork（`D:\DSH go fork`）：**本轮未改任何代码**；`HEAD = 0f5e049 ci: runtime 载荷改从上游 v1.0.7 release 取（proot pin 已失效）`。

```
## git status --short（未跟踪，既有）
?? .gh-issues/  ?? AGENTS.md  ?? community-demands.md  ?? docs/agents/  ?? handoff/
```

关键引用（不复制正文）：规格 #15 / #23，PR #14 / #21，验收矩阵 `D:\Agent Workspace\superagent-proposals\evidence-t12\acceptance-matrix.md`，完成记录 `outputs\superagent-tickets\*.md`。
