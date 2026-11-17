import { expect, test } from 'claude-code/testing'

const NOW = 1_790_000_000_000
const strip = (s: string) => s.replace(/\x1b\[[0-9;]*m/g, '')

const agent = (over: Record<string, unknown>) => ({
  id: 'a1', description: 'Check README links', type: 'Explore', status: 'running',
  kind: 'local_agent', taskStatus: 'running',
  label: 'Verifying anchors in claude/README.md\nmore detail',
  startTime: NOW - 125_000, cwd: '/home/carl/dotfiles/.claude/worktrees/agent-abc/claude',
  model: 'claude-haiku-5-5', contextWindowSize: 200_000, tokenCount: 160_000,
  tokenSamples: [], hasRow: true, rowIds: ['a1'],
  ...over,
})

for (const surface of ['terminal', 'desktop'] as const) {
  test(`${surface}: running row`, async ($, on) => {
    let body: string | undefined
    on('clock.now', () => ({ value: NOW }))
    on('ui.render', { component: 'AgentRow' }, (_, e, next) => {
      body = e.props.body
      return next(e)
    })
    const ui = await $.ui.mount({ plugin: 'subagent-rows', surface, component: 'AgentRow', props: agent({}) as never })
    const text = strip(body ?? '')
    expect(text).toContain('Verifying anchors in claude/README.md')
    expect(text).not.toContain('more detail')
    expect(text).toContain('agent-abc')
    expect(text).toMatch(/2m05s/)
    expect(text).toContain('160k 80%')
    expect(body).toContain('38;2;229;200;144m') // yellow context at >= 75%
    await ui.unmount()
  })

  test(`${surface}: finished row`, async ($, on) => {
    let body: string | undefined
    on('clock.now', () => ({ value: NOW }))
    on('ui.render', { component: 'AgentRow' }, (_, e, next) => {
      body = e.props.body
      return next(e)
    })
    const ui = await $.ui.mount({
      plugin: 'subagent-rows', surface, component: 'AgentRow',
      props: agent({ status: 'completed', taskStatus: 'completed', name: 'scout', cwd: '/tmp' }) as never,
    })
    const text = strip(body ?? '')
    expect(text).toContain('scout')
    expect(text).toContain('completed')
    expect(text).not.toContain('k ')
    await ui.unmount()
  })
}
