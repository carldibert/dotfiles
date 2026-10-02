# dotfiles

My terminal setup: [kitty](https://sw.kovidgoyal.net/kitty/) + zsh with [oh-my-zsh](https://ohmyz.sh/), in the [Catppuccin Frappé](https://catppuccin.com/) palette. The prompt is a native oh-my-zsh theme that rebuilds Oh My Posh's `wholespace` theme. A matching WezTerm + Oh My Posh setup is included for Windows, so both systems show the same prompt.

![kitty with the wholespace-frappe prompt](screenshots/prompt.png)

## What's inside

| Path | What it is | Installed to |
| --- | --- | --- |
| `kitty/kitty.conf` | kitty config: Catppuccin Frappé colors, Noto Sans Mono 10pt, 75% opacity with blur, powerline tab bar, custom shortcuts | `~/.config/kitty/kitty.conf` |
| `zsh/.zshrc` | oh-my-zsh setup with plugins | `~/.zshrc` |
| `zsh/themes/wholespace-frappe.zsh-theme` | The prompt theme | `~/.oh-my-zsh/custom/themes/` |
| `windows/wholespace-frappe.omp.json` | The same prompt as an Oh My Posh config, for PowerShell | `%USERPROFILE%\.config\oh-my-posh\` |
| `windows/.wezterm.lua` | WezTerm config matching kitty | `%USERPROFILE%\.wezterm.lua` |
| `windows/Microsoft.PowerShell_profile.ps1` | PowerShell profile that loads the prompt | `$PROFILE` |
| `packages/arch.txt` | Arch packages the setup needs | - |
| `install.sh` | Installs everything on Linux | - |

## The prompt

The screenshot above shows it in kitty. Laid out in text (icons omitted):

```
[os] ♥ 00:56:29 | CPU: 3.87% | RAM: 18.4/62 | 7ms                [node] [github] [branch] main ≡
[folder] home/Documents/Repos/TuffLevels [status]
```

**Line 1, left:** OS logo (read from `/etc/os-release`), clock, CPU use since the last prompt, RAM used/total in GiB, and how long the last command took.

**Line 1, right:** Node.js version (only in Node projects, with an npm or yarn icon) and git:

| Git symbol | Meaning |
| --- | --- |
| `≡` | In sync with upstream |
| `↑1 ↓2` | Commits ahead / behind upstream |
| `≢` | No upstream branch |
| pencil `?1 ~2` | Working tree: untracked (`?`), added (`+`), modified (`~`), deleted (`-`) |
| checkbox `+1` | Staged changes, same symbols |
| stack `1` | Stash entries |

The host icon shows GitHub, GitLab, Bitbucket or Azure DevOps based on the remote URL.

**Line 2:** the path (`~` is shown as `home`) and a status icon that turns red when the last command failed.

After you press Enter, the prompt collapses to a single arrow to keep scrollback clean. The tab title shows the current folder name.

The theme was checked against Oh My Posh 31.4.0 running the same config. Their output matched glyph for glyph and color for color across git states, timer lengths and path types. The CPU figure is deliberately different: it shows real use since the previous prompt.

## Dependencies

| Need | Arch package | Notes |
| --- | --- | --- |
| zsh 5.3+ | `zsh` | |
| git 2.35+ | `git` | `--show-stash` needs 2.35 |
| curl | `curl` | used to install oh-my-zsh |
| kitty | `kitty` | any truecolor terminal works for the prompt |
| Noto Sans Mono | `noto-fonts` | terminal font |
| Nerd Font symbols | `ttf-nerd-fonts-symbols-mono` | prompt icons; kitty uses it as a fallback font |
| oh-my-zsh | - | installed by `install.sh` |
| [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) | - | cloned by `install.sh` |
| [fast-syntax-highlighting](https://github.com/zdharma-continuum/fast-syntax-highlighting) | - | cloned by `install.sh` |

The theme reads `/proc/stat` and `/proc/meminfo`, so it's Linux-only. It needs a UTF-8 locale and switches to `C.UTF-8` on its own if the current locale isn't UTF-8.

## Install (Linux)

```bash
git clone https://github.com/carldibert/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh --dry-run   # see what it will do
./install.sh
exec zsh
```

`install.sh`:

1. Installs `packages/arch.txt` with `sudo pacman -S --needed`. Skip this with `--no-packages`, for example on a non-Arch server.
2. Installs oh-my-zsh if `~/.oh-my-zsh` doesn't exist.
3. Clones the two zsh plugins.
4. Symlinks the configs into place. Any existing file is moved to `<file>.bak-<date>` first.

Running it again is safe: anything already linked is left alone.

## Install (Windows 11)

```powershell
winget install Microsoft.PowerShell wez.wezterm
winget install JanDeDobbeleer.OhMyPosh -s winget
```

1. Install [Noto Sans Mono](https://fonts.google.com/noto/specimen/Noto+Sans+Mono): unzip it, select the `static\NotoSansMono-*.ttf` files, then right-click and choose **Install**. WezTerm already includes the Nerd Font icons.
2. Copy `windows/wholespace-frappe.omp.json` to `%USERPROFILE%\.config\oh-my-posh\`.
3. Copy `windows/.wezterm.lua` to `%USERPROFILE%\`.
4. Add the lines from `windows/Microsoft.PowerShell_profile.ps1` to `notepad $PROFILE`.
5. If the profile is blocked from running, use `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`.

## kitty shortcuts

`kitty.conf` clears kitty's default shortcuts and defines its own:

| Keys | Action |
| --- | --- |
| `Ctrl+Shift+C` / `Ctrl+Shift+V` | Copy / paste |
| `Alt+Enter` / `Alt+W` | New / close window (split) |
| `Ctrl+Tab` / `Alt+Tab` | Next / previous window |
| `Alt+R` | Resize the current window |
| `Alt+L` | Next layout |
| `Alt+T` / `Alt+Q` | New / close tab |
| `Alt+Right` / `Alt+Left` | Next / previous tab |
| `Alt+↑` / `Alt+↓` | Move tab forward / backward |
| `Alt+N` | Rename tab |
| `Alt+Numpad+` / `Alt+Numpad−` / `Alt+Backspace` | Font bigger / smaller / reset |
| `Alt+F5` | Reload kitty.conf |

Selecting text copies it, and middle-click pastes the selection.

## Customizing

- **Colors:** edit the `_ws_c` table at the top of the theme. On Windows, edit the `palette` block in the `.omp.json`. Both use the Catppuccin Frappé names (`crust`, `surface0`, `blue`, …).
- **Icons:** the `_ws_g` table maps names to Nerd Font code points (`"${(#):-0xE0B2}"`). Look up others at [nerdfonts.com/cheat-sheet](https://www.nerdfonts.com/cheat-sheet).
- **Segments:** each segment is one `_ws_*` function. To drop one, delete its `left+=` line in `_ws_precmd`.

## Credits

- [`wholespace`](https://ohmyposh.dev/docs/themes) theme from the Oh My Posh theme gallery, which this prompt recreates
- [Catppuccin](https://github.com/catppuccin/catppuccin) Frappé palette
- [oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh), [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions), [fast-syntax-highlighting](https://github.com/zdharma-continuum/fast-syntax-highlighting)
- [Nerd Fonts](https://www.nerdfonts.com/) for the icons

## License

[MIT](LICENSE)
