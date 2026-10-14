const PANE = 'plans'
const NOT_FOUND =
  'plans-list was not found. Run src/install --vault <dir> in the obsidian-plans repository.'

let result = { entries: { inbox: [], plans: [] } }

function parseEntries(stdout) {
  const entries = { inbox: [], plans: [] }
  for (const line of stdout.split('\n')) {
    const [kind, name, branch = ''] = line.split('\t')
    if (kind === 'inbox') entries.inbox.push({ name })
    if (kind === 'plan') entries.plans.push({ name, branch })
  }
  return entries
}

async function runPlansList($) {
  const cwd = await $.session.cwd()
  let run
  try {
    run = await $.process.run(['plans-list'], { cwd })
  } catch {
    return { error: NOT_FOUND }
  }
  if (run.exitCode !== 0) return { error: run.stderr.trim() }
  return { entries: parseEntries(run.stdout) }
}

function toastText({ inbox, plans }) {
  return 'inbox ' + inbox.length + ' · plans ' + plans.length
}

function planRow({ name, branch }) {
  return branch ? name + ' [' + branch + ']' : name
}

export function register(on) {
  on('session.start', async ($, e, next) => {
    const started = await runPlansList($)
    const { inbox, plans } = started.entries ?? { inbox: [], plans: [] }
    if (inbox.length + plans.length > 0) $.ui.toast(toastText(started.entries))
    await $.command.register({ name: 'plans', description: 'Show inbox items and plans' })
    return next(e)
  })

  on('command.run', { command: 'plans' }, async ($) => {
    result = await runPlansList($)
    await $.ui.open({ id: PANE, title: 'Plans', closeOnEscape: true, focus: true })
    return {}
  })

  on('ui.render', { component: 'Pane' }, async ($, e, next) => {
    if (e.requestId !== PANE) return next(e)
    const { Box, Text } = $.ui.resolve(e)
    if (result.error) return Text({ children: [result.error] })

    const group = (title, rows) => [
      Text({ bold: true, children: [title + ' (' + rows.length + ')'] }),
      ...(rows.length > 0 ? rows : ['None.']).map((row) => Text({ children: [row] })),
    ]
    const { inbox, plans } = result.entries
    return Box({
      flexDirection: 'column',
      children: [
        ...group('Inbox', inbox.map((item) => item.name)),
        Text({ children: [' '] }),
        ...group('Plans', plans.map(planRow)),
      ],
    })
  })
}
