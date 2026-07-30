# ~/.ai-agents

Single source of truth for rules and skills shared across AI agents (Claude
Code, GitHub Copilot, Gemini CLI, Codex, OpenCode, Cursor), managed via
[Ruler](https://github.com/intellectronica/ruler).

## Structure

```
~/.ai-agents/
├── README.md
├── setup.sh          # Machine wiring — rerun on any new machine
└── core/             # Everything Ruler scans — see below
    ├── ruler.toml     # Target agents: claude, copilot, gemini-cli, codex, opencode, cursor
    ├── rules/         # Always-loaded rules, split by topic
    │   ├── general.md
    │   ├── code-quality.md
    │   └── git.md
    └── skills/        # Skills (SKILL.md), loaded on demand
        ├── agent-handoff/
        ├── agent-start/
        ├── css-styleguide/
        └── self-review/
```

Ruler recursively concatenates every `*.md` file it finds under `core/`
(including hidden subfolders) into the compiled rules, in this order: a
top-level `AGENTS.md` first if present, then everything else sorted by path.
Two subfolder names are reserved and excluded from concatenation: `skills/`
(propagated separately, see below) and `agents/` (Ruler subagents). Split
rules into as many files as you like under `core/rules/` (or any other
non-reserved name) — only `ruler.toml`, `skills/`, and rule `.md` files
belong inside `core/`. Keep `README.md` at the repo root, outside `core/`,
so it's never picked up.

## Rules vs. skills

- **Rules** (`core/rules/*.md`, compiled into `CLAUDE.md`/`AGENTS.md`/etc.)
  load in full on every session, for every agent, unconditionally. Keep this
  to the handful of rules that apply to 100% of tasks (git hygiene, general
  code quality). Split them into one file per topic — Ruler concatenates
  them all regardless of how they're organized.
- **Skills** (`core/skills/*/SKILL.md`) only load their body when relevant —
  only the `description` stays in context permanently. Anything specific to a
  stack or topic (e.g. CSS) belongs here, not in `AGENTS.md`. Before adding a
  new rule, ask: does this apply to *every* task? If not, it's a skill.

Auto-triggering a skill via a `paths:` frontmatter field (glob-based, like
Cursor's `globs`) is unreliable on Claude Code today — don't depend on it
(only a single combined glob pattern works, never a list). For guaranteed
triggering, use manual invocation (`disable-model-invocation: true` +
`/skill-name`) or a `PostToolUse` hook.

## How skills are distributed

- **Claude Code**: `~/.claude/skills` is symlinked to `core/skills/` (via
  `setup.sh`) — independent of Ruler, no command needed, edits are live
  immediately.
- **Copilot, Gemini CLI, Codex, OpenCode, Cursor**: no global skills folder —
  distribution goes through Ruler, per project (see below). Ruler's global
  fallback only covers rules, not skills.
- `core/skills/` must contain real directories, not symlinks — a symlink
  there makes `ruler apply`'s skill copy silently no-op (log says "Copying
  skills..." but 0 files land).

## Adding a new skill

- **Local**: create a real folder under `core/skills/<name>/SKILL.md` with
  standard frontmatter (`name`, `description`).
- **Remote** (an existing skill from a GitHub repo or the skills.sh
  marketplace), via [`npx skills`](https://github.com/vercel-labs/skills):

  ```bash
  npx skills add owner/repo@skill-name -g -a claude-code --copy -y
  ```

  | Flag | Why |
  |---|---|
  | `-g` | installs into `~/.claude/skills/`, symlinked to `core/skills/` — lands directly in this repo |
  | `-a claude-code` | scopes the install to this agent; otherwise the tool also writes into other agents' home-dir folders this repo doesn't track |
  | `--copy` | **required** — the tool's default mode symlinks to its own cache, violating the "real directories" rule above |
  | `-y` | skip confirmation prompts |

  Commit the resulting `core/skills/<name>/` folder to persist it and make
  it available on other machines.

## Machine setup: `setup.sh`

```bash
git clone <remote> ~/wherever
~/wherever/setup.sh
```

Idempotent — safe to rerun. `setup.sh` (or `setup.sh setup`, same thing):

1. Relocates the repo to `~/.ai-agents` if it isn't already there (`mv`,
   preserves git history).
2. Creates 2 machine-local symlinks (never versioned):

   | Link | Target | Why |
   |---|---|---|
   | `~/.config/ruler` | `core/` | Ruler's global fallback (rules only), used by `ruler apply` when a project has no local `.ruler` |
   | `~/.claude/skills` | `core/skills/` | Claude Code's native global skills folder, independent of Ruler |

To undo the machine wiring, run `~/.ai-agents/setup.sh remove` — it removes
the 2 symlinks above (only if they still point here) and leaves the repo
itself in place.

## Using Ruler in a project

Rules only (zero config, via the global fallback):

```bash
cd my-project && npx @intellectronica/ruler apply
```

Rules + skills (needs a local `.ruler` pointing to the central config):

```bash
cd my-project
ln -s ~/.config/ruler .ruler
npx @intellectronica/ruler apply
```

`ruler apply` writes `CLAUDE.md`, `AGENTS.md` (shared by
Copilot/Codex/Gemini CLI/OpenCode/Cursor), `.codex/config.toml`,
`opencode.json`, and copies skills into `.claude/skills/`, `.gemini/skills/`,
`.opencode/skills/`, `.agents/skills/`, `.cursor/skills/`. `ruler revert`
cleanly undoes it (`.bak` files).
