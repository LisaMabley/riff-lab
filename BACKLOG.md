# Backlog

Working list of tickets and open questions. The product spec is [riff-lab-plan.md](riff-lab-plan.md); this file tracks how we get there.

- Each ticket is about 3–5 story points and one PR (see [CLAUDE.md](CLAUDE.md), "Work in small chunks").
- When a ticket is done, mark it `[x]` in the same commit, and add its PR number once it has one.
- When an open question is answered, record the decision in the spec (or in code, if it's purely technical) and delete it here.

## Current: Phase 1 foundation

Rebuilding the initial scaffold in small, reviewable commits on `stub-refactor`.

- [x] **1. Workspace skeleton:** pnpm workspaces, Turborepo, shared tsconfig, ESLint, Prettier (`88c31d1`)
- [x] **2. CI:** GitHub Actions for format, typecheck, lint, and tests (`77b8595`)
- [x] **3. Username schema:** `@riff-lab/core` with `usernameSchema` and tests (`6b08ad7`)
- [x] **4. Age check:** `isAdult` and tests
- [x] **5. Supabase setup:** CLI, config, empty seed, pgTAP helpers, schema guard tests, CI database job
- [ ] **6. Profiles table:** table, constraints, RLS, column-level grants, pgTAP tests, `limits.ts`
- [ ] **7. Onboarding RPC:** `complete_onboarding` with the 18+ check, tests, seed data
- [ ] **8. Generated types:** `packages/supabase` with `database.types.ts`

## Later in Phase 1 (not yet split into tickets)

From spec §17, Phase 1. Break each into tickets before starting it.

- Expo app shell
- Sign-in: email code, Apple, Google
- Image processing check on Edge Functions
- Image posts: upload, EXIF stripping, resizing, reordering, alt text
- Remixes: "remixed from" link, 24-hour rule, remixes on the original, placeholder card
- Feed: newest first, tag filter, remix count
- Comments and one level of replies
- Public tags with the blocked-words check
  - Tag words are shared (stored once), but keep RLS on: use a read policy, never disable RLS.
  - The read policy can't be `using (true)`. Per spec §8, a tag used only privately by someone else must never be visible to other users. Readers should see only tags used publicly somewhere, plus tags they used privately themselves. Decide between a read policy and an autocomplete RPC when we get here.
- Blocking
- Simple reporting
- Remix and comment notifications (in-app)

## Open questions

The spec's product-level questions are in §19. These are smaller ones that came up while building.

### Username rules

The spec doesn't define these. Current placeholder: 3–30 characters, `a-z`, `0-9`, `_`, `.`, stored lowercase. See [username.ts](packages/core/src/username.ts).

- Is the length range right?
- Is the character set right?
- Should leading, trailing, or repeated periods be allowed (`.maya`, `maya.`, `a..b`)? Currently they are.
- Should some names be reserved (`admin`, `support`, `riff`, …)?

### Display name and bio limits

Placeholders: display name 50 characters, bio 300. These depend on §19 "Profile fields" and "Text limits." They arrive in ticket 6.
