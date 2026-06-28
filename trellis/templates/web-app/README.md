# web-app template

A shared starting point for rogueoak web applications, so every web app begins from the same stack
instead of re-deciding it. Fixed stack: **Next.js 16** (App Router), **TypeScript** (strict),
**Tailwind CSS** (v4), the **`@rogueoak/roots`** design foundation, and the **`@rogueoak/canopy`**
design system built on it.

Apply with (run `/trellis-install` first):

```
/trellis-template web-app
```

After that, plain `/trellis-update` keeps the owned conventions doc current - you never re-run the
command. Your app code and config (the seed files) are yours and are never touched again.

## What it installs

Owned by Trellis (refreshed on update - do not edit):

| File | Role |
|---|---|
| `docs/templates/web-app/conventions.md` | The stack, the standard layout, and how canopy plugs in. Kept current on update. |

Yours (seeded once, never touched again):

| File | Role |
|---|---|
| `package.json` | Dependencies (Next 16, React, `@rogueoak/roots`, `@rogueoak/canopy`, Tailwind v4) and scripts. |
| `tsconfig.json` | Strict TypeScript with the Next plugin and the `@/*` path alias. |
| `next.config.ts` | Next.js config (minimal to start). |
| `postcss.config.mjs` | Wires the `@tailwindcss/postcss` plugin. |
| `eslint.config.mjs` | Flat ESLint config extending `next`. |
| `app/layout.tsx` | Root App Router layout; imports `globals.css`. |
| `app/page.tsx` | A minimal home page. |
| `app/globals.css` | Tailwind v4 entry (`@import "tailwindcss"`) plus the roots and canopy styles. |

The seed mirrors a real project layout, so applying merges these into the repo root. A seed file
whose target already exists is **skipped, never overwritten** - reconcile those by hand.

## Setup after applying

1. `npm install` (the seed pins majors; npm resolves current patches).
2. `npm run dev` and open http://localhost:3000.
3. Read `docs/templates/web-app/conventions.md` before adding code - it is the spec this app
   follows. Build features under `app/`, shared UI in `components/`, non-UI helpers in `lib/`.

The seed is a known-good starting point, not a finished app: extend it with current package
versions. All `docs/rules/` guidelines still apply to everything you add.
