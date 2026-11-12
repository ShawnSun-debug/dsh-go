# Domain Docs

How the engineering skills should consume this repo's domain documentation when exploring the codebase.

## Before exploring, read these

- **`CONTEXT.md`** at the repo root.
- **`docs/adr/`**: read ADRs that touch the area you're about to work in.

This repo is **single-context**: no `CONTEXT-MAP.md`, no per-package `CONTEXT.md`. `app/` (Flutter), `packages/dsh_client`, `packages/dsh_remote`, `runtime/`, `sdk/`, `services/`, `tooling/` are packages of one product, not separate contexts.

If any of these files don't exist, **proceed silently**. Don't flag their absence; don't suggest creating them upfront. The `/domain-modeling` skill (reached via `/grill` and `/improve-codebase-architecture`) creates them lazily when terms or decisions actually get resolved.

## `CONTEXTS.md` is not the domain glossary

The repo root also holds `CONTEXTS.md` — a hardlink to `D:\Agent Contexts\dsh-go-fork.md` holding this project's **working context**: goal, entry files, known traps, verification state, rebuild timeline. Its global window `~/.dsh/memory/projects/dsh-go-fork.md` is a symlink to it.

It is not a glossary and not an ADR store: never write domain terms or decisions into it, and never read it in place of `CONTEXT.md`.

## File structure

```
/
├── CONTEXTS.md          ← working context (operations log; not a glossary)
├── CONTEXT.md           ← domain glossary + boundaries (created lazily by /domain-modeling)
├── docs/
│   ├── adr/             ← decisions, 0001-....md, 0002-....md
│   └── agents/          ← this config (issue-tracker / triage-labels / domain)
└── app/  packages/  runtime/  sdk/  services/  tooling/
```

### Sparse-checkout caveat

This clone keeps `docs/` **outside** the sparse-checkout cone (upstream ships ~10 MB there). Files under `docs/agents/` and `docs/adr/` are readable on disk immediately, but git treats them as untracked while `docs` is outside the cone — and if they are committed anyway, the next checkout strips them from the working tree.

So: before committing anything under `docs/`, run `git sparse-checkout add docs` (needs the wider sandbox — see `issue-tracker.md`), or accept that these files stay local-only.

## Use the glossary's vocabulary

When your output names a domain concept (in an issue title, a refactor proposal, a hypothesis, a test name), use the term as defined in `CONTEXT.md`. Don't drift to synonyms the glossary explicitly avoids.

If the concept you need isn't in the glossary yet, that's a signal: either you're inventing language the project doesn't use (reconsider) or there's a real gap (note it for `/domain-modeling`).

## Flag ADR conflicts

If your output contradicts an existing ADR, surface it explicitly rather than silently overriding:

> _Contradicts ADR-0007 (event-sourced orders), but worth reopening because…_
