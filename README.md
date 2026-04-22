# dotfiles — `demo` branch

Minimal dotfiles used by the Coder sales-demo templates:

- [`lab/coder-templates` / `demo-ai-gov-no-firewall`](https://gitlab.zambruhni.com/lab/coder-templates/-/tree/main/templates/demo-ai-gov-no-firewall)
- [`lab/coder-templates` / `demo-ai-governance`](https://gitlab.zambruhni.com/lab/coder-templates/-/tree/main/templates/demo-ai-governance)

## What's in here

Just a `.bashrc`:

- Clean green-arrow prompt, easy to read projected on a screen.
- Aliases pinning `claude` and `codex` to their "skip all prompts" flags so sales demos don't stall on approval dialogs.

Nothing else. No zsh, no starship, no oh-my-zsh, no VS Code settings.

## Full-featured version

The `main` branch of this repo has the full dev setup (starship, VS Code extensions, profiles, etc.). To use that instead, change the **Dotfiles Branch** parameter on the workspace-create form from `demo` → `main`.
