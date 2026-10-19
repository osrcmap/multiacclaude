#!/usr/bin/env bash
# Self-check for claude-switch-account: runs it against a throwaway HOME with a stub `claude`.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

ok() { "$@" || { echo "FAIL: $*" >&2; exit 1; }; }
no() { if "$@"; then echo "FAIL (should have failed): $*" >&2; exit 1; fi; }

export HOME="$tmp/home"
c="$HOME/.claude"
mkdir -p "$tmp/bin" "$c/skills/mine" "$c/skills/synced/x" "$c/agents" \
  "$c/plugins/cache/p" "$c/plugins/synced/x" "$HOME/proj"
cat > "$tmp/bin/claude" <<'EOF'
#!/bin/sh
echo "$CLAUDE_CONFIG_DIR|$PWD|$*" >> "$HOME/calls"
EOF
chmod +x "$tmp/bin/claude"
export PATH="$tmp/bin:$PATH"
unset ANTHROPIC_API_KEY CLAUDE_CODE_OAUTH_TOKEN

echo '{}' > "$c/settings.json"
echo '# mine' > "$c/CLAUDE.md"
echo "{\"plugins\":{\"p\":[{\"installPath\":\"$c/plugins/cache/p\"}]}}" > "$c/plugins/installed_plugins.json"
cat > "$HOME/.claude.json" <<EOF
{"oauthAccount":{"emailAddress":"me@home.dev"},
 "mcpServers":{"u1":{"command":"echo"}},
 "projects":{"$HOME/proj":{"mcpServers":{"l1":{"command":"echo"}}},
             "$HOME/gone":{"mcpServers":{"l2":{"command":"echo"}}}}}
EOF

csa="$here/claude-switch-account"
acc="$HOME/.claude-accounts/work"
calls="$HOME/calls"

"$csa" add work --sso >/dev/null
ok [ "$(readlink "$acc/settings.json")" = "$c/settings.json" ]
ok [ "$(readlink "$acc/CLAUDE.md")" = "$c/CLAUDE.md" ]
ok [ "$(readlink "$acc/agents")" = "$c/agents" ]
ok [ -d "$acc/skills" ]
no [ -L "$acc/skills" ]
ok [ -L "$acc/skills/mine" ]
no [ -e "$acc/skills/synced" ]
ok [ -d "$acc/plugins/cache/p" ]
no [ -e "$acc/plugins/synced" ]
ok grep -qF "$acc/plugins/cache/p" "$acc/plugins/installed_plugins.json"
no grep -qF "$c/plugins" "$acc/plugins/installed_plugins.json"
ok grep -qF "|mcp add-json -s user u1 {\"command\":\"echo\"}" "$calls"
ok grep -qF "$acc|$HOME/proj|mcp add-json -s local l1 {\"command\":\"echo\"}" "$calls"
no grep -qF l2 "$calls"
ok [ "$(tail -n 1 "$calls" | cut -d'|' -f3)" = "auth login --sso" ]
ok [ "$(stat -c %a "$acc" 2>/dev/null || stat -f %Lp "$acc")" = 700 ]

# launching passes args through and picks up added/removed skills
mkdir "$c/skills/new"
rm -r "$c/skills/mine"
"$csa" work --version
ok [ "$(tail -n 1 "$calls")" = "$acc|$PWD|--version" ]
ok [ -L "$acc/skills/new" ]
no [ -L "$acc/skills/mine" ]

# a file owned by the account is kept and reported, never overwritten
rm "$acc/CLAUDE.md"
echo own > "$acc/CLAUDE.md"
ok sh -c "'$csa' work 2>&1 | grep -q 'is not shared'"
ok [ "$(cat "$acc/CLAUDE.md")" = own ]

no "$csa" add work 2>/dev/null
no "$csa" add ../x 2>/dev/null
no "$csa" add ls 2>/dev/null
no "$csa" nope 2>/dev/null
ok sh -c "'$csa' ls | grep -q '^default .*me@home.dev'"
ok sh -c "'$csa' ls | grep -q '^work .*(not logged in)'"

# a failure before login leaves no half-made account behind
if [ "$(id -u)" != 0 ]; then
  touch "$c/plugins/unreadable"
  chmod 000 "$c/plugins/unreadable"
  no "$csa" add broken 2>/dev/null
  no [ -e "$HOME/.claude-accounts/broken" ]
  chmod 600 "$c/plugins/unreadable"
fi
echo ok
