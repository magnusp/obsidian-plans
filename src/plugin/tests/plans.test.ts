import { expect, test } from 'claude-code/testing'

const PANE = {
  plugin: 'obsidian-plans',
  component: 'Pane',
  requestId: 'plans',
  surface: 'terminal',
  viewport: { columns: 100, rows: 30 },
  props: {
    title: 'Plans',
    isFocused: true,
    bodyColumns: 60,
    placement: 'inline',
    scroll: { offset: 0, bodyRows: 10 },
    view: {},
  },
} as const

const TAB = '\t'

function stubSession(on, plansList) {
  const toasts: string[] = []
  const commands: string[] = []
  const opened: string[] = []
  on('session.start', () => ({ cwd: '/work' }))
  on('session.cwd', () => ({ value: '/work' }))
  on('process.run', (_$, e) => plansList(e))
  on('ui.toast', (_$, e) => {
    toasts.push(e.text)
    return { value: undefined }
  })
  on('command.register', (_$, e) => {
    commands.push(e.name)
    return { value: undefined }
  })
  on('ui.open', (_$, e) => {
    opened.push(e.id)
    return { value: { isPlaced: true } }
  })
  return { toasts, commands, opened }
}

const answer = (exitCode: number, stdout: string, stderr = '') => ({ value: { exitCode, stdout, stderr } })
const found = (stdout: string) => () => answer(0, stdout)
const cannotStart = () => ({ deny: 'spawn plans-list ENOENT' })
const startSession = ($) => $.session.start({ surface: 'terminal', isInteractive: true, cwd: '/work' })

test('shows a toast with the counts at session start', async ($, on) => {
  const seen = stubSession(
    on,
    found(`inbox${TAB}2026-10-01-a\ninbox${TAB}2026-10-02-b\nplan${TAB}2026-10-10-c${TAB}feature/c\n`),
  )

  await startSession($)

  expect(seen.toasts).toEqual(['inbox 2 · plans 1'])
})

test('runs plans-list in the working directory of the session', async ($, on) => {
  let argv: string[] = []
  let cwd = ''
  stubSession(on, (e) => {
    argv = e.argv
    cwd = e.init.cwd
    return answer(0, '')
  })

  await startSession($)

  expect(argv).toEqual(['plans-list'])
  expect(cwd).toBe('/work')
})

test('shows no toast when there is nothing to show', async ($, on) => {
  const seen = stubSession(on, found(''))

  await startSession($)

  expect(seen.toasts).toEqual([])
})

test('shows no toast when plans-list fails', async ($, on) => {
  const seen = stubSession(on, () => answer(1, '', 'outside the ghq root'))

  await startSession($)

  expect(seen.toasts).toEqual([])
})

test('shows no toast when plans-list cannot start', async ($, on) => {
  const seen = stubSession(on, cannotStart)

  await startSession($)

  expect(seen.toasts).toEqual([])
})

test('registers the /plans command', async ($, on) => {
  const seen = stubSession(on, found(''))

  await startSession($)

  expect(seen.commands).toEqual(['plans'])
})

test('/plans opens the pane and returns no text', async ($, on) => {
  const seen = stubSession(on, found(''))

  const answer = await $.command.run({ command: 'plans', args: '' })

  expect(seen.opened).toEqual(['plans'])
  expect(answer).toEqual({})
})

test('the pane lists inbox items and plans with their branches', async ($, on) => {
  stubSession(
    on,
    found(`inbox${TAB}2026-10-01-a\nplan${TAB}2026-10-10-c${TAB}feature/c\nplan${TAB}2026-10-11-d${TAB}\n`),
  )
  await $.command.run({ command: 'plans', args: '' })

  const ui = await $.ui.mount(PANE)

  expect(await ui.find({ type: 'Text', text: 'Inbox (1)' })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: '2026-10-01-a' })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: 'Plans (2)' })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: '2026-10-10-c [feature/c]' })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: '2026-10-11-d' })).toBeDefined()
})

test('the pane shows None. for an empty group', async ($, on) => {
  stubSession(on, found(`inbox${TAB}2026-10-01-a\n`))
  await $.command.run({ command: 'plans', args: '' })

  const ui = await $.ui.mount(PANE)

  expect(await ui.find({ type: 'Text', text: 'Plans (0)' })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: 'None.' })).toBeDefined()
})

test('the pane shows the stderr message when plans-list fails', async ($, on) => {
  stubSession(on, () => answer(1, '', 'plans-resolve: config file is missing\n'))
  await $.command.run({ command: 'plans', args: '' })

  const ui = await $.ui.mount(PANE)

  expect(await ui.find({ type: 'Text', text: 'plans-resolve: config file is missing' })).toBeDefined()
})

test('the pane tells you to run install when plans-list is not found', async ($, on) => {
  stubSession(on, cannotStart)
  await $.command.run({ command: 'plans', args: '' })

  const ui = await $.ui.mount(PANE)

  expect(await ui.find({ type: 'Text', text: /Run src\/install --vault/ })).toBeDefined()
})
