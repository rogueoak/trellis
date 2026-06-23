# Guidelines

Rules every agent follows on rogueoak projects. Terse on purpose: more will land here over
time, so keep each rule a single, checkable line.

## Writing

1. Never use em-dashes or en-dashes (the long Unicode dashes). Use ASCII punctuation instead:
   a spaced hyphen ` - `, a comma, parentheses, or two sentences.
   - Yes: "Trellis is small - read it in a sitting."
   - The spaced hyphen above does the job a long dash would.
2. Prefer ASCII everywhere. Reach for a Unicode character only when it carries real meaning
   (a name, a currency, a math symbol), not for typographic flourish.

## Code

1. Tests, lint, and build must all pass before you push or merge. No "fix it in a follow-up."
2. On a pull request, resolve each review comment as you address it, and make sure every
   comment is resolved before the PR merges.
