// Agent panel rows styled like claude-statusline.omp.json (Catppuccin Frappe diamonds).
// Port of the old subagentStatusLine script (subagent-statusline.py), which Claude Code
// deprecated in favor of mods.
import type { Register } from 'claude-code'

const PALETTE = {
  crust: '#232634', mantle: '#292c3c', surface0: '#414559', surface1: '#51576d',
  overlay: '#949cbb', lavender: '#babbf1', sky: '#99d1db', teal: '#81c8be',
  green: '#a6d189', yellow: '#e5c890', red: '#e78284', pink: '#f4b8e4',
} as const
type Color = keyof typeof PALETTE

const ESC = '\x1b['
const RESET = `${ESC}0m`
const DIAMOND = ''
const ICON_TREE = ''
const ICON_TIMER = '\u{f051b}'
const ICON_CTX = ''
const ICON_DONE = ''

const rgb = (name: Color): string => {
  const h = PALETTE[name].slice(1)
  return [0, 2, 4].map(i => parseInt(h.slice(i, i + 2), 16)).join(';')
}
const fg = (name: Color): string => `${ESC}38;2;${rgb(name)}m`

// Same shape as the oh-my-posh diamonds: pointed left edge, notched right edge
const seg = (bg: Color, color: Color, text: string): string =>
  `${fg(bg)}${DIAMOND}${RESET}` +
  `${ESC}48;2;${rgb(bg)}m${fg(color)} ${text} ${RESET}` +
  `${ESC}38;2;${rgb(bg)};49m${ESC}7m${DIAMOND}${RESET}`

const duration = (sec: number): string => {
  sec = Math.max(0, Math.floor(sec))
  const h = Math.floor(sec / 3600)
  const m = Math.floor(sec / 60) % 60
  const s = sec % 60
  if (h) return `${h}h${String(m).padStart(2, '0')}m`
  return m ? `${m}m${String(s).padStart(2, '0')}s` : `${s}s`
}

const RUNNING = new Set(['pending', 'running', 'waiting'])

export const register: Register = on => {
  // cwd -> linked worktree name (or null); rows redraw every 5s, so don't re-walk the tree
  const worktrees = new Map<string, string | null>()

  on('ui.render', { component: 'AgentRow' }, async ($, e, next) => {
    try {
      const p = e.props

      const worktreeName = async (cwd: string): Promise<string | null> => {
        if (!cwd) return null
        const cached = worktrees.get(cwd)
        if (cached !== undefined) return cached
        let found: string | null = null
        const marker = '/.claude/worktrees/'
        const at = cwd.indexOf(marker)
        if (at >= 0) {
          found = cwd.slice(at + marker.length).split('/')[0] || null
        } else {
          // A linked worktree has a .git file pointing at the main repo; a main checkout has a dir
          let dir = cwd.replace(/\/+$/, '')
          while (dir) {
            const st = await $.fs.stat(`${dir}/.git`).catch(() => undefined)
            if (st?.kind === 'dir') break
            if (st?.kind === 'file') {
              found = dir.slice(dir.lastIndexOf('/') + 1)
              break
            }
            dir = dir.slice(0, dir.lastIndexOf('/'))
          }
        }
        worktrees.set(cwd, found)
        return found
      }

      const running = RUNNING.has(p.status)
      const firstLine = (s?: string) => s?.split('\n').find(l => l.trim())?.trim()
      const name = firstLine(p.name) ?? firstLine(p.label) ?? p.type ?? 'agent'

      const dot = running ? `${fg('yellow')}●` : `${fg('green')}${ICON_DONE}`
      let out = `${dot}${RESET} ${ESC}1m${fg('lavender')}${name}${RESET} `

      const wt = await worktreeName(p.cwd)
      if (wt) out += seg('surface1', 'pink', `${ICON_TREE} ${wt}`)

      if (running) {
        if (p.startTime > 0) {
          const now = await $.clock.now()
          out += seg('surface0', 'teal', `${ICON_TIMER} ${duration((now - p.startTime) / 1000)}`)
        }
        const tokens = p.tokenCount
        const window = p.contextWindowSize
        const pct = window ? ` ${Math.round((tokens * 100) / window)}%` : ''
        const color: Color = window && tokens / window >= 0.75 ? 'yellow' : 'sky'
        out += seg('mantle', color, `${ICON_CTX} ${Math.round(tokens / 1000)}k${pct}`)
      } else {
        out += seg('surface0', p.status === 'failed' || p.status === 'killed' ? 'red' : 'green', p.status || 'done')
      }

      return next({ ...e, props: { ...p, body: out } })
    } catch {
      return next(e) // fall back to Claude's default row
    }
  })
}
