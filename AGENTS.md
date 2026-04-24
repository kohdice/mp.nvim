# AGENTS.md

This file provides guidance to AI agents and agentic coding tools when working with code in this repository.

## Project Overview

`mp.nvim` wraps the external `mp` (markdown preview) CLI and renders the current buffer in a
terminal tab via `mp --watch <path>`. The plugin exposes the `:Mp` user command
defined in `plugin/mp.lua`.

**Naming map (easy to get wrong):** the repository, Lua module, and external binary share
the stem `mp`, but they are distinct layers.

| Layer | Name |
|-------|------|
| Repository / plugin | `mp.nvim` |
| Lua module (`require`) | `mp` |
| External binary on `$PATH` | `mp` |
| User command | `:Mp` |

The Lua module name drops the `.nvim` suffix per Neovim convention: use `require('mp')`,
**not** `require('mp.nvim')`. Source files live under `lua/mp/` and `plugin/mp.lua`. The Lua
module and the external CLI happen to share the name `mp` — inside Lua code, `mp` refers to
the module; the CLI is only ever referenced through `vim.fn.executable('mp')` and the
subprocess invocation. No `doc/mp.txt` or test suite exists yet — if the user asks for tests,
confirm the framework (`busted` / `plenary.nvim`) before scaffolding.

## Development Environment

The dev shell is provided by Nix flakes and is auto-loaded via `direnv` (see `.envrc`).

First-time setup on a fresh checkout:

```sh
direnv allow   # one-time approval; afterwards the shell is auto-entered on `cd`
```

- Enter the shell manually: `nix develop`
- Update pinned Nix inputs: `nix flake update`
- Tools provided in the shell:
  - `lua-language-server` — LSP for editor integration
  - `luacheck` — Lua linter (configured via `.luacheckrc`)
  - `stylua` — Lua formatter (configured via `.stylua.toml`)

No test runner (`busted` / `plenary.nvim`) is configured yet. Do not invent test commands; if
the user asks to run tests, confirm the framework before scaffolding.

CI is configured (`.github/workflows/ci.yml`) and runs static analysis only — `stylua --check`
and `luacheck` inside `nix develop`. It does **not** run tests, build artifacts, or publish.

## Lua Module Layout

- `lua/mp/init.lua` ↔ `require('mp')` — business logic
- `lua/mp/<name>.lua` ↔ `require('mp.<name>')` — future submodules
- `plugin/mp.lua` — runtime entry; registers `:Mp` and guards on
  `vim.fn.has('nvim-0.12')`
- `doc/mp.txt` — vimdoc help (not yet created; run `:helptags doc/` after it is added)

## Runtime Requirements

- **Neovim 0.12.0+** — `plugin/mp.lua` MUST gate on `vim.fn.has('nvim-0.12')`
  and abort with a `vim.notify` error on older versions.
- **`mp` CLI on `$PATH`** — `M.open` MUST check `vim.fn.executable('mp')` and surface the
  missing-executable error through `adapter.notify_error`, not via direct `vim.notify`.

## Design Notes

Business logic in `lua/mp/init.lua` MUST route every Neovim API call
(`vim.api.nvim_*`, `vim.fn.*`, `vim.notify`) through a `default_adapter` table. The public
entry point `M.open({ adapter = ..., executable = ... })` MUST accept adapter and executable
overrides so unit tests can stub them without booting a real Neovim runtime.

When adding functionality that touches `vim.*`, extend `default_adapter` and route the call
through the adapter. Never call `vim.*` directly from business-logic paths — doing so forces
tests to require a live Neovim.

## Formatting

Lua code is formatted with `stylua` using `.stylua.toml`:

- 100 column width
- 2-space indentation
- Unix line endings
- `AutoPreferSingle` quote style — prefer single quotes
- `call_parentheses = "Input"` — preserve parentheses on function calls as written

Common commands:

- Format the whole tree: `stylua .`
- Check formatting without writing: `stylua --check .`
- Format a single file: `stylua path/to/file.lua`

CI runs `stylua --check .` on every push/PR to `main` and `develop`
(`.github/workflows/ci.yml`). Format locally before pushing to avoid a red build.

## Linting

Lua code is linted with `luacheck` using `.luacheckrc`:

- Targets LuaJIT 2.1 (matches Neovim's embedded runtime)
- 100 column max line length (matches `stylua`)
- `vim` is declared as a read-only global (Neovim injects it)

Common commands:

- Lint the whole tree: `luacheck .`
- Lint a single file: `luacheck path/to/file.lua`
- Suppress warnings inline: `-- luacheck: ignore <code>` (codes are shown in output
  because `codes = true` is set in `.luacheckrc`)

The `cache = true` setting writes incremental results to `.luacheckcache` at the
repository root. The file is gitignored and safe to delete (`rm .luacheckcache`)
if results look stale.

CI runs `luacheck .` on every push/PR to `main` and `develop`
(`.github/workflows/ci.yml`). Lint locally before pushing to avoid a red build.

## Repository Conventions

- `.plans/`, `.mcp.json`, and `settings.local.json` are gitignored (Claude Code workspace files).
- `.envrc.local` is supported for per-developer environment overrides and is gitignored.
- Commit messages and code-side text are English (per the user's global rule); explanations to
  the user in this repo are in Japanese.
- `CLAUDE.md` is a symlink to `AGENTS.md` — edit only `AGENTS.md`. The symlink keeps Claude
  Code, Codex, and other AGENTS.md-aware tools reading the same file.
