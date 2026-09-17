# Plantydex

A Pokédex for plants. Photograph a plant, Pl@ntNet identifies it, and it's
recorded as a **sighting** of a **plant** species. Over time you build a
collection, tracked as progress across US floristic regions.

## Surfaces

| Path | What it is | Status |
|---|---|---|
| `ios/Plantydex/` | SwiftUI app — Log / Upload / Progress tabs, token-driven design system | **The product.** Active development. |
| `supabase/` | Postgres + Storage + Deno edge functions | Active. Hosted project ref `enjjvyhhyeufkkrxbhbk`. |
| `web/` | Next.js 16 prototype — `/upload`, `/log`, `/plants/[key]` | **Frozen.** Kept as a debug/admin surface; no new features. |

## ⚠️ Schema drift — do not run `supabase db reset`

The migrations in `supabase/migrations/` **do not describe the live database.**

They build a `trees` table and a `plant_log` view over it. Every piece of
running code instead uses `plants`, `sightings`, `tree_entries`, and a
differently-shaped `plant_log` (`key`, `name`, `sightings_count`,
`thumbnail_url`). Those objects were created by hand in the Supabase
dashboard and were never captured as migrations.

Consequences until this is fixed:

- `supabase db reset` will produce a database the app cannot run against.
- A fresh local stack will not work without manually recreating the schema.
- `20260102203326_create_tree_photos_bucket.sql` is an empty file; the
  `tree-photos` storage bucket also exists only in the dashboard.

The fix is to run `supabase db pull` against the linked project to capture
reality, then delete the obsolete migrations. Until then, treat the hosted
database as the source of truth.

## Data model (as actually deployed)

- **`plants`** — the shared species catalogue, keyed by a slugified
  scientific name (`key`, with `key_lc` for lookups). Holds taxonomy,
  Pl@ntNet reference images, and the raw match blob.
- **`sightings`** — one row per photo you take, referencing `plants.id`.
- **`tree_entries`** — your per-species display name and notes, keyed by
  the same plant `key`.
- **`plant_log`** — a view that collapses sightings into one row per
  species with a count, last-seen timestamp, and thumbnail.
- **`regional_flora_cache`**, **`plant_region_distribution`** — caches for
  the Progress tab (7-day and 30-day TTLs enforced in the edge functions).

## Edge functions

| Function | Auth | Purpose |
|---|---|---|
| `identify-tree` | `verify_jwt = true` | Downloads the uploaded image, calls Pl@ntNet, upserts `plants`, inserts a `sighting`. |
| `get-regional-flora` | `verify_jwt = false` | Species count for the user's region, cached. |
| `get-plant-distribution` | `verify_jwt = false` | Maps plant keys to US region ids via GBIF, cached. |

The two regional functions have JWT verification off because the iOS client
sends a publishable key, which is not a JWT. Both should move to
`verify_jwt = true` when Sign in with Apple lands.

## Local development

Requires Docker, the [Supabase CLI](https://supabase.com/docs/guides/local-development), Node 22+, and Xcode.

```bash
supabase start
supabase functions serve
```

Secrets are gitignored. You need to create:

| File | Keys |
|---|---|
| `supabase/functions/.env` | `PLANTNET_KEY` |
| `supabase/.env.local` | `PLANTNET_KEY`, `SB_URL`, `SB_SERVICE_ROLE_KEY` |
| `web/.env.local` | `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY` |
| `ios/Plantydex/Config.xcconfig` | `SB_URL`, `SB_ANON_KEY` — copy `Config.example.xcconfig` |

Get a Pl@ntNet API key at <https://my.plantnet.org/>.

### Web

```bash
cd web && npm ci && npm run dev
```

`web/.env.local` must exist even for `npm run build` — the Supabase client is
constructed at module scope, so prerendering `/log` fails without it.

### iOS

Open `ios/Plantydex/Plantydex.xcodeproj`. Copy `Config.example.xcconfig` to
`Config.xcconfig` and fill it in.

To run on a **physical device** against a local stack, `SB_URL` must be your
Mac's LAN IP (e.g. `http://192.168.1.50:54321`), not `127.0.0.1` — and both
devices must be on the same network. The simulator can use `127.0.0.1`.

## Known blockers before TestFlight

1. **No authentication.** Everything uses the anon key and RLS is
   `USING (true)`. `sightings` and `tree_entries` have no owner column, so
   every user would share one global plant log and could edit each other's
   notes. Needs Sign in with Apple plus `user_id` scoping.
2. **Hardcoded LAN endpoint.** `Config.xcconfig` is wired to a home IP over
   cleartext HTTP, and `Info.plist` sets `NSAllowsArbitraryLoads` to permit
   it. Needs split debug/release configs and a scoped ATS exception.
3. **No app icon.** `AppIcon.appiconset` declares three 1024×1024 slots and
   contains no images — an automatic App Store rejection.
4. **Deployment target is iOS 26.0**, which excludes almost every device.
5. **No `PrivacyInfo.xcprivacy`** despite using location.
6. The schema drift above.
