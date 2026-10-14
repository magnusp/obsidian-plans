import { defineConfig } from 'astro/config'
import starlight from '@astrojs/starlight'
import starlightLinksValidator from 'starlight-links-validator'

export default defineConfig({
  integrations: [
    starlight({
      title: 'obsidian-plans',
      description: 'Scripts, skills, and a Claude Code plugin that keep plans and inbox items in an Obsidian vault.',
      social: [{ icon: 'github', label: 'GitHub', href: 'https://github.com/magnusp/obsidian-plans' }],
      plugins: [starlightLinksValidator()],
      sidebar: [
        { label: 'Start here', slug: 'index' },
        { label: 'Design contract', slug: 'design' },
        { label: 'Research', items: [{ autogenerate: { directory: 'research' } }] },
      ],
    }),
  ],
})
