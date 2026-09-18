# Plantydex

A Pokédex for plants. Photograph a plant, Pl@ntNet identifies it, and it's recorded as a
**sighting** of a **plant** species. Over time you build a collection, tracked as progress
across US floristic regions.

## Architecture

Your collection lives **on your phone**, in SwiftData, synced across your devices through
iCloud (CloudKit). There are no accounts, no shared database, and no per-user rows on a
server to get wrong.

A server exists for exactly one reason: the Pl@ntNet API key can't ship inside an app
bundle. So the backend is two stateless edge functions plus one global cache.

```
┌─ iPhone ───────────────────────────────┐    ┌─ Supabase ─────────────────────────┐
│ SwiftData + CloudKit                   │    │ identify-tree                       │
│   Plant ─┬─ Sighting (photo)           │───▶│   image → Pl@ntNet → JSON           │
│          └─ notes, regionIds           │    │   (stateless, stores nothing)       │
│   RegionalFloraCache                   │───▶│ get-regional-flora                  │
│                                        │    │   + regional_flora_cache (global)   │
│ GBIF (keyless) ◀── direct from device  │    │                                     │
└────────────────────────────────────────┘    └─────────────────────────────────────┘
```

| Path | What it is |
|---|---|
| `ios/Plantydex/` | The app. SwiftUI, SwiftData, a token-driven design system. |
| `supabase/` | Two edge functions and one migration. Hosted project ref `enjjvyhhyeufkkrxbhbk`. |

## Data model

On device (`ios/Plantydex/Models/`):

- **`Plant`** — one per species, keyed by a slugified scientific name. Holds taxonomy,
  Pl@ntNet reference images, your display name and notes, the US regions GBIF has records
  for, and denormalized `lastSeenAt` / `sightingCount` so the log sorts without a join.
- **`Sighting`** — one per photo you take. The JPEG lives in `externalStorage`, which
  CloudKit syncs as a CKAsset.
- **`RegionalFloraCache`** — local mirror of the server's species counts so the Progress
  tab renders instantly on launch.

On the server, one table: **`regional_flora_cache`**. It holds no user data — Pl@ntNet
species counts per region are identical for everyone and expensive to compute, so they're
cached centrally with a 7-day TTL.

### Known constraint

CloudKit forbids unique constraints, so `Plant.key` is deduplicated in code
(`IdentifyService` fetches before inserting) rather than by the schema. Two devices
identifying the same species while both offline can produce duplicate keys after sync;
the log and progress views group by key on read, so they still render correctly.

## Edge functions

| Function | JWT | Purpose |
|---|---|---|
| `identify-tree` | on | Accepts a multipart image, calls Pl@ntNet, returns the best match. Persists nothing. |
| `get-regional-flora` | off | Species count for a lat/lon, cached 7 days. |

`get-regional-flora` has JWT verification off because the client sends a publishable key,
which is not a JWT. Neither function exposes user data; abuse protection is Supabase's
per-project rate limiting.

## Local development

Requires Docker, the [Supabase CLI](https://supabase.com/docs/guides/local-development),
and Xcode 16+.

```bash
supabase start
supabase functions serve
```

Secrets are gitignored. You need to create:

| File | Keys |
|---|---|
| `supabase/functions/.env` | `PLANTNET_KEY` |
| `ios/Plantydex/Config.xcconfig` | `SB_URL`, `SB_ANON_KEY` — copy `Config.example.xcconfig` |

Get a Pl@ntNet API key at <https://my.plantnet.org/>.

### iOS

Open `ios/Plantydex/Plantydex.xcodeproj`. Copy `Config.example.xcconfig` to
`Config.xcconfig` and fill it in.

To run on a **physical device** against a local stack, `SB_URL` must be your Mac's LAN IP
(e.g. `http://192.168.1.50:54321`), not `127.0.0.1`, and both devices must be on the same
network. The simulator can use `127.0.0.1`.

CloudKit sync needs a simulator or device signed into iCloud. Without one the app falls
back to a local-only store — it still works, it just doesn't sync.

## Remaining blockers before TestFlight

1. **Hardcoded LAN endpoint.** `Config.xcconfig` points at a home IP over cleartext HTTP,
   and `Info.plist` still sets `NSAllowsArbitraryLoads` plus literal `SB_*` values. Needs
   split debug/release configs and a scoped ATS exception.
2. **No app icon.** `AppIcon.appiconset` declares three 1024×1024 slots and contains no
   images — an automatic App Store rejection.
3. **No `PrivacyInfo.xcprivacy`** despite using location.
4. **Region coverage gap.** `USRegion.stateToRegionId` maps 48 states; Kentucky and
   Tennessee belong to no region, so a species recorded only there unlocks nothing. This
   was inherited from the original server-side table.
