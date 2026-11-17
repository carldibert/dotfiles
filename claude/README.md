# Claude Code statusline

A two-line [Claude Code](https://code.claude.com/docs/en/statusline) statusline drawn by [Oh My Posh](https://ohmyposh.dev/), in the same Catppuccin Frappé diamond segments as the [shell prompt](../README.md#the-prompt). A small Python script styles the rows in the agent panel to match.

![A Claude Code session with the statusline](screenshots/claude-session.png)

## What it shows

**Line 1, the session:**

| Segment | Shows |
| --- | --- |
| Model | Model name, e.g. `Opus 5.5` |
| Context | An 8-cell bar plus `NNNk/200k` tokens in context (see [thresholds](#context-thresholds)) |
| 5h | 5-hour usage limit: % used and time until it resets (`1h26m`) |
| 7d | 7-day usage limit: % used and when it resets (`Tue 18:00`) |
| Time | Wall-clock time of the session, with time spent waiting on the API dimmed after it |

The 5h and 7d segments turn yellow at 70% and red at 90%. They're hidden until Claude Code sends rate-limit data, which only happens after the first reply in a session.

**Line 2, where Claude is working:**

| Segment | Shows |
| --- | --- |
| Repo | Repo name only (falls back to the project folder's name outside a repo) |
| Git | Branch, ahead/behind, working tree and staged changes, stash count. Same symbols as the [prompt](../README.md#the-prompt) |
| Worktree | The worktree name and the branch it came from, when the session runs in a git worktree |
| Tail | Session cost (`$4.18`) and lines added/removed |

### Context thresholds

The bar always fills toward 200k tokens, whatever the model's real context window is. Past 200k a session gets slow and expensive, so that's where I checkpoint and start a fresh one.

| Tokens | Look |
| --- | --- |
| Under 150k | Green |
| 150k to 199k | Yellow, `checkpoint soon` |
| 200k and up | Whole segment red, `CHECKPOINT NOW` |

![The three context states](screenshots/claude-states.png)

## Agent panel

The `subagent-rows` mod (`mods/subagent-rows/`) renders each row of the panel Claude Code shows while subagents run: the agent's name, its worktree (when it runs in one), how long it has been running, and its tokens and context %. Context turns yellow at 75%. Finished agents get a check mark and their final status (red if it failed or was killed). Claude Code draws the tree for nested agents itself, the mod only fills in each row.

This used to be a `subagentStatusLine` script (`subagent-statusline.py`). Claude Code 2.1.326 deprecated that setting in favor of mods, so the same rendering now lives in a mod's `AgentRow` render hook.

![Subagents running in worktrees](screenshots/claude-agents.png)

## Dependencies

| Need | Arch package | Notes |
| --- | --- | --- |
| Claude Code | - | 2.1.326+ (`statusLine` `refreshInterval`, mods with `AgentRow`) |
| Oh My Posh 31.4+ | `oh-my-posh-bin` (AUR) | needs the `claude` segment, added in 31.4 |
| git | `git` | for the git segment |
| A Nerd Font | `ttf-nerd-fonts-symbols-mono` | icons; WezTerm has them built in |

## Install

1. Install Oh My Posh: `paru -S oh-my-posh-bin` on Arch, or see [Oh My Posh](../README.md#oh-my-posh) for other systems.
2. Link the statusline config into `~/.claude/`. `install.sh` does this when it finds Claude Code (`~/.claude` exists), or by hand:

   ```bash
   ln -s ~/dotfiles/claude/claude-statusline.omp.json ~/.claude/
   ```

3. Add this to `~/.claude/settings.json`, next to whatever is already in it. `settings.json` holds other settings too, so it isn't linked from the repo.

   ```json
   "statusLine": {
     "type": "command",
     "command": "oh-my-posh claude --config ~/.claude/claude-statusline.omp.json",
     "refreshInterval": 5
   },
   "env": {
     "CLAUDE_CODE_PLUGIN_DIRS": "~/dotfiles/claude/mods/subagent-rows"
   }
   ```

   `CLAUDE_CODE_PLUGIN_DIRS` loads the agent panel mod straight from the repo in every session, and an interactive session reloads it when a file in it changes. If `env` already exists, add the key to it. Several folders are separated with `:`.

4. Start a new Claude Code session.

`refreshInterval` redraws the statusline every 5 seconds, so the clock keeps moving while Claude works. The agent rows refresh on their own every 5 seconds. Without it, the statusline only updates when the conversation changes.

## Customizing

- **Colors:** the `palette` block at the top of `claude-statusline.omp.json`, and `PALETTE` in `mods/subagent-rows/hooks/register.ts`. Both use the Catppuccin Frappé names.
- **Context thresholds:** search the `.omp.json` for `150000` and `200000`. The bar's `200000` divisor and the `/200k` label are in the same template.
- **Rate-limit colors:** the `70` and `90` in the 5h and 7d segments' `foreground_templates` and `background_templates`.
- **Segments:** each segment is one entry in a block's `segments` list. Delete one to drop it.

To try a change without a live session, pipe a sample payload into Oh My Posh. The fields are listed in the [statusline docs](https://code.claude.com/docs/en/statusline).

```bash
echo '{"model":{"display_name":"Opus 5.5"},"workspace":{"project_dir":"'$PWD'"},"context_window":{"total_input_tokens":162000,"context_window_size":200000},"cost":{"total_cost_usd":4.18,"total_duration_ms":4325000,"total_api_duration_ms":545000}}' \
  | oh-my-posh claude --config ~/.claude/claude-statusline.omp.json
```

## Troubleshooting

- **No 5h / 7d segments:** normal until the first reply in a session. Claude Code only sends usage limits for Claude subscriptions, so they also stay hidden when you sign in with an API key.
- **Boxes instead of icons:** the terminal font has no Nerd Font icons. Install `ttf-nerd-fonts-symbols-mono` (kitty picks it up as a fallback) or use a Nerd Font.
- **Agent rows look like Claude Code's defaults:** the mod isn't loaded, or its hook threw and fell back to the default row. Check `CLAUDE_CODE_PLUGIN_DIRS` in `settings.json`, then run the mod's checks and tests:

  ```bash
  claude plugin validate ~/dotfiles/claude/mods/subagent-rows
  claude plugin test ~/dotfiles/claude/mods/subagent-rows
  ```

  `claude --debug` logs a line for any hook the engine skipped.
