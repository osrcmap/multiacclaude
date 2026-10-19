# multiacclaude

`claude-switch-account` (alias `csa`) switches between Claude Code accounts (work, personal…)
without `/logout` and `/login`. Each account has its own login, history and sessions, but
shares the config you write yourself. You can have several accounts open at once in
different terminals.

## Install

Requires bash and Claude Code (macOS, Linux or WSL). `jq` is optional: it is used to copy
your MCP servers.

```sh
npm install -g @osrcmap/multiacclaude   # installs the claude-switch-account and csa commands
```

Or from source:

```sh
git clone https://github.com/osrcmap/multiacclaude ~/multiacclaude
ln -s ~/multiacclaude/claude-switch-account ~/.local/bin/csa   # or any directory on your PATH
```

## Usage

```sh
csa add work             # create the account and log in (accepts --sso, --console, --email X)
csa work                 # start Claude with the work account
csa work --resume        # any other arguments are passed to claude
csa ls                   # list accounts and their email
claude                   # your usual account (~/.claude), unchanged
```

## What is shared and what is not

The default account (`~/.claude`) is the source. Other accounts live in
`~/.claude-accounts/<name>` (what Claude calls `CLAUDE_CONFIG_DIR`).

| Shared (symlinked to `~/.claude`) | Per account |
|---|---|
| `settings.json` (model, hooks, permissions, status line, enabled plugins) | Login and credentials |
| `CLAUDE.md`, `rules/` | History, sessions and conversations (`projects/`) |
| `agents/`, `commands/`, `skills/`, `output-styles/` | Auto memory |
| `hooks/`, `themes/`, `workflows/`, `keybindings.json` | Installed plugins, and skills/plugins synced from claude.ai |
| | MCP servers and their OAuth logins, per-project trust, caches |

Changes to shared config apply to every account: `/model` in `csa work` also changes it
for `claude`.

When an account is created:
- **Plugins**: the ones you have installed are copied. If you install a new one later, it is
  enabled in the shared `settings.json`; if it doesn't show up in another account, install it
  there: `csa work plugin install <plugin>`.
- **MCP**: your user and project MCP servers are copied (requires `jq`). Servers you add later
  belong to each account: `csa work mcp add ...`.
- **Skills**: those in `~/.claude/skills` are linked one by one. A skill you create inside an
  account stays in that account.

If a shared file becomes account-specific (for example, because you created it while in that
account), `csa` warns you on launch and leaves it alone. Merge it into `~/.claude` and delete
it from the account to share it again.

## Notes

- **macOS**: each account stores its credentials in its own Keychain entry.
- **Removing an account**: `csa work auth logout && rm -rf ~/.claude-accounts/work`.
- **`ANTHROPIC_API_KEY` or `CLAUDE_CODE_OAUTH_TOKEN`** set in your shell take precedence over
  any login. `csa` warns you if they are set.
- **VS Code / JetBrains**: the extension uses the default account. To use another one, quit
  the editor and open it from a terminal with `CLAUDE_CONFIG_DIR=~/.claude-accounts/work code .`
  (if it is already running, it reuses that window and doesn't inherit the variable).
- The desktop app and claude.ai are not affected.
