# AGENTS.md

This file provides guidance to AI agents and agentic coding tools when working with code in
this repository. Configuration and behavior details that already live in source files
(`flake.nix`, `.stylua.toml`, `.luacheckrc`, `.gitignore`, `lua/mp/*.lua`,
`plugin/mp.lua`) are intentionally **not** restated here — read those files instead.

## Project Overview

`mp.nvim` wraps the external `mp` (markdown preview) CLI and renders the current buffer in a
Neovim terminal-backed scratch buffer. User commands are registered in `plugin/mp.lua`; the
rendering lifecycle is orchestrated in `lua/mp/init.lua`, with the default Neovim adapter in
`lua/mp/adapter.lua`, source-file validation/command construction in `lua/mp/source.lua`,
and preview state storage in `lua/mp/state.lua`. Read those files for the exact command list
and rendering model.

**Naming gotcha:** repository, Lua module, external binary, and user command all derive from
the stem `mp` but are distinct layers.

| Layer                      | Name                | Notes                                                                                      |
| -------------------------- | ------------------- | ------------------------------------------------------------------------------------------ |
| Repository / plugin        | `mp.nvim`           |                                                                                            |
| Lua module                 | `mp`                | `require('mp')`, **not** `require('mp.nvim')` (Neovim convention drops the `.nvim` suffix) |
| External binary on `$PATH` | `mp`                | Referenced only via `vim.fn.executable('mp')` and the subprocess invocation                |
| User command               | `:Mp` (and friends) | See `plugin/mp.lua` for the full list                                                      |

No `doc/mp.txt` or test suite exists yet. If the user asks for tests, confirm the framework
(`busted` / `plenary.nvim`) before scaffolding. After `doc/mp.txt` is added, run
`:helptags doc/`.

## Development Environment

The dev shell is provided by Nix flakes (`flake.nix`) and is auto-loaded via `direnv`
(`.envrc`).

- First-time setup on a fresh checkout: `direnv allow`.
- Enter the shell manually when direnv is unavailable: `nix develop`.
- `.envrc.local` is supported for per-developer overrides (gitignored).

CI (`.github/workflows/ci.yml`) runs **static analysis only** — `stylua --check` and
`luacheck` inside `nix develop`. It does **not** run tests, build artifacts, or publish.

## Runtime Requirements (Invariants)

Preserve these when refactoring entry points:

- **Neovim 0.12.0+** — `plugin/mp.lua` MUST gate on `vim.fn.has('nvim-0.12')` and abort with
  a `vim.notify` error on older versions.
- **`mp` CLI on `$PATH`** — `M.open` MUST check `vim.fn.executable('mp')` and surface the
  missing-executable error through `adapter.notify_error`, not via direct `vim.notify`.

## Design Rule: Adapter Pattern (Invariant)

Business logic in `lua/mp/*.lua` MUST route every Neovim API call (`vim.api.nvim_*`,
`vim.fn.*`, `vim.notify`) through the default adapter defined in `lua/mp/adapter.lua`.
Public entry points MUST accept adapter and executable overrides via their options table.

**Why:** unit tests should be able to stub the adapter without booting a real Neovim runtime.
Calling `vim.*` directly from a business-logic path forces tests to require a live editor.

When adding functionality that touches `vim.*`, extend `lua/mp/adapter.lua` and route the
call through the adapter. Never call `vim.*` directly from business-logic paths.

## Static Analysis

Tooling is configured by `.stylua.toml` (formatter) and `.luacheckrc` (linter) — read those
for actual settings. Inside `nix develop`:

- Format: `stylua .` (or `stylua --check .` to verify without writing).
- Lint: `luacheck .`.

`luacheck` writes incremental results to `.luacheckcache` (gitignored). Delete the file if
results look stale: `rm .luacheckcache`.

CI runs both checks on every push/PR to `main` and `develop`; run them locally before pushing.
