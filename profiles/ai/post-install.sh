#!/usr/bin/env bash
# Claude Code uses its own installer rather than mise: it puts claude in
# ~/.local/bin and keeps it up to date in the background.
command -v claude >/dev/null 2>&1 && exit 0
curl -fsSL https://claude.ai/install.sh | bash
