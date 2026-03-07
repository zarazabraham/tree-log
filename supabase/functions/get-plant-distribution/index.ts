import { createClient } from "https://esm.sh/@supabase/supabase-js@2?target=deno";

// POST { plantKeys: string[] }
// Returns [{ plantKey: string, regionIds: string[] }]
//
// For each plant key:
//   1. Look up gbif_id from the plants table
//   2. Check plant_region_distribution cache (30-day TTL)
//   3. If stale/missing: query GBIF occurrence facet API for US state distribution
//   4. Map state names → US region IDs
//   5. Upsert into cache and return

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const CACHE_TTL_MS = 30 * 24 * 60 * 60 * 1000; // 30 days

// --- Supabase admin client ---
const rawSupabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
const supabaseUrl = rawSupabaseUrl
  .replace("http://127.0.0.1:54321", "http://host.docker.internal:54321")
  .replace("http://localhost:54321", "http://host.docker.internal:54321");
const serviceKey =
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
  Deno.env.get("SERVICE_ROLE_KEY") ??
  "";
if (!supabaseUrl) throw new Error("Missing SUPABASE_URL");
if (!serviceKey) throw new Error("Missing service role key");
const admin = createClient(supabaseUrl, serviceKey);

// --- State → Region ID mapping (normalised to lowercase) ---
const STATE_TO_REGION: Record<string, string> = {
  "washington": "pacific-northwest",
  "oregon": "pacific-northwest",
  "california": "california",
  "colorado": "mountain-west",
  "utah": "mountain-west",
  "nevada": "mountain-west",
  "idaho": "mountain-west",
  "montana": "mountain-west",
  "wyoming": "mountain-west",
  "arizona": "desert-southwest",
  "new mexico": "desert-southwest",
  "north dakota": "great-plains",
  "south dakota": "great-plains",
  "nebraska": "great-plains",
  "kansas": "great-plains",
  "oklahoma": "great-plains",
  "minnesota": "midwest",
  "wisconsin": "midwest",
  "michigan": "midwest",
  "illinois": "midwest",
  "indiana": "midwest",
  "ohio": "midwest",
  "iowa": "midwest",
  "missouri": "midwest",
  "maine": "northeast",
  "new hampshire": "northeast",
  "vermont": "northeast",
  "massachusetts": "northeast",
  "rhode island": "northeast",
  "connecticut": "northeast",
  "new york": "northeast",
  "pennsylvania": "northeast",
  "new jersey": "northeast",
  "delaware": "mid-atlantic-appalachia",
  "maryland": "mid-atlantic-appalachia",
  "virginia": "mid-atlantic-appalachia",
  "west virginia": "mid-atlantic-appalachia",
  "north carolina": "mid-atlantic-appalachia",
  "south carolina": "mid-atlantic-appalachia",
  "georgia": "southeast",
  "florida": "southeast",
  "alabama": "southeast",
  "mississippi": "southeast",
  "louisiana": "southeast",
  "arkansas": "southeast",
  "texas": "texas",
  "alaska": "alaska",
  "hawaii": "hawaii",
};

function stateNamesToRegionIds(stateNames: string[]): string[] {
  const regionSet = new Set<string>();
  for (const name of stateNames) {
    const normalised = name.trim().toLowerCase();
    const regionId = STATE_TO_REGION[normalised];
    if (regionId) regionSet.add(regionId);
  }
  return Array.from(regionSet);
}

function fetchWithTimeout(url: string, timeoutMs: number): Promise<Response> {
  const controller = new AbortController();
  const id = setTimeout(() => controller.abort(), timeoutMs);
  return fetch(url, { signal: controller.signal }).finally(() => clearTimeout(id));
}

// Query GBIF occurrence facets to find which US states this species has records in
async function fetchStatesFromGbif(gbifId: string): Promise<string[]> {
  const url =
    `https://api.gbif.org/v1/occurrence/search` +
    `?taxonKey=${encodeURIComponent(gbifId)}` +
    `&country=US&facet=stateProvince&facetLimit=60&limit=0`;

  const res = await fetchWithTimeout(url, 15_000);
  if (!res.ok) return [];

  const data = await res.json();
  const facets: any[] = data?.facets ?? [];
  const stateProvinceFacet = facets.find(
    (f: any) =>
      f.field === "STATE_PROVINCE" || f.field === "stateProvince"
  );

  if (!stateProvinceFacet) return [];

  return (stateProvinceFacet.counts ?? [])
    .filter((c: any) => typeof c.name === "string" && c.count > 0)
    .map((c: any) => c.name as string);
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

// --- Main handler ---
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  let body: any;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  const plantKeys: string[] = Array.isArray(body?.plantKeys) ? body.plantKeys : [];
  if (plantKeys.length === 0) {
    return jsonResponse([]);
  }

  try {
    // 1. Look up gbif_id for each plant key from the plants table
    const { data: plants, error: plantsErr } = await admin
      .from("plants")
      .select("key, gbif_id")
      .in("key", plantKeys);

    if (plantsErr) {
      return jsonResponse({ error: "DB lookup failed", details: plantsErr }, 500);
    }

    const gbifMap: Record<string, string> = {};
    for (const p of plants ?? []) {
      if (p.gbif_id) gbifMap[p.key] = String(p.gbif_id);
    }

    // 2. Check cache for all requested keys
    const { data: cached } = await admin
      .from("plant_region_distribution")
      .select("plant_key, region_ids, fetched_at")
      .in("plant_key", plantKeys);

    const cacheMap: Record<string, { regionIds: string[]; fetchedAt: number }> = {};
    for (const row of cached ?? []) {
      cacheMap[row.plant_key] = {
        regionIds: row.region_ids ?? [],
        fetchedAt: new Date(row.fetched_at).getTime(),
      };
    }

    // 3. Determine which plants need a fresh GBIF fetch
    const now = Date.now();
    const results: { plantKey: string; regionIds: string[] }[] = [];
    const toUpsert: { plant_key: string; region_ids: string[]; fetched_at: string }[] = [];

    for (const plantKey of plantKeys) {
      const cached = cacheMap[plantKey];
      if (cached && now - cached.fetchedAt < CACHE_TTL_MS) {
        results.push({ plantKey, regionIds: cached.regionIds });
        continue;
      }

      const gbifId = gbifMap[plantKey];
      if (!gbifId) {
        // No GBIF ID — can't determine distribution, return empty
        results.push({ plantKey, regionIds: [] });
        toUpsert.push({ plant_key: plantKey, region_ids: [], fetched_at: new Date().toISOString() });
        continue;
      }

      // Fetch from GBIF
      const stateNames = await fetchStatesFromGbif(gbifId);
      const regionIds = stateNamesToRegionIds(stateNames);

      results.push({ plantKey, regionIds });
      toUpsert.push({ plant_key: plantKey, region_ids: regionIds, fetched_at: new Date().toISOString() });
    }

    // 4. Upsert fresh results into cache (non-fatal)
    if (toUpsert.length > 0) {
      const { error: upsertErr } = await admin
        .from("plant_region_distribution")
        .upsert(toUpsert, { onConflict: "plant_key" });
      if (upsertErr) console.error("Cache upsert failed:", upsertErr);
    }

    return jsonResponse(results);
  } catch (err) {
    return jsonResponse({ error: "Unexpected error", details: String(err) }, 500);
  }
});
