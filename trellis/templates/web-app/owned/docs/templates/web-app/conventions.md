# Web-app conventions

The shared spec for a rogueoak web application. This file is **owned by Trellis** and refreshed on
every `/trellis-update` - do not edit it. To change the stack, change the `web-app` template in the
Trellis repo. Everything in `docs/rules/` applies on top of this.

## Stack

| Concern | Choice | Notes |
|---|---|---|
| Framework | **Next.js 16**, App Router | Server Components by default; add `"use client"` only where a component needs interactivity. |
| Language | **TypeScript**, strict | `strict: true`; no `any` for convenience - model the type. |
| Styling | **Tailwind CSS v4** | CSS-first: configured in `app/globals.css` via `@import "tailwindcss"` and `@theme`; there is no `tailwind.config.ts`. |
| Design system | **`@rogueoak/canopy`** | The component and design-token layer. Reach for canopy components before hand-rolling UI. |

Name major versions here; use the current patch releases when you install.

## Layout

```
app/                 # routes, layouts, and pages (App Router)
  layout.tsx         # root layout; imports globals.css
  page.tsx           # home page
  globals.css        # Tailwind entry + canopy styles + @theme tokens
components/          # shared, reusable UI (compose canopy here)
lib/                 # non-UI helpers: data access, utilities, types
public/              # static assets served as-is
```

- Co-locate route-specific UI under its `app/` segment; promote to `components/` once it is reused.
- Keep `lib/` free of JSX - it is for logic, not rendering.
- Use the `@/*` path alias (set in `tsconfig.json`) for imports from the project root.

## Styling and canopy

- Tailwind utilities are the default for layout and spacing. Define design tokens (colors, fonts,
  spacing scale) in the `@theme` block of `app/globals.css`, not a JS config.
- canopy ships components and styles. Import its stylesheet once in `app/globals.css` and use its
  components from `@rogueoak/canopy`; prefer extending canopy over duplicating a component it
  already provides.

## Conventions that carry over

- Server Components are the default; mark client components explicitly and keep them small.
- TypeScript stays strict - fix types rather than casting around them.
- `npm run lint` and `npm run build` must pass before you push (per `docs/rules/guidelines.md`).
- Public-facing copy (page text, metadata, errors) follows `docs/rules/language.md`.
