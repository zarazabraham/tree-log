import { createClient } from "https://esm.sh/@supabase/supabase-js@2?target=deno";

// POST { lat: number, lon: number }
// Returns { projectId, projectName, speciesCount, fromCache }

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// 7-day cache TTL
const CACHE_TTL_MS = 7 * 24 * 60 * 60 * 1000;

// --- Supabase admin client (same pattern as identify-tree) ---
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

// --- Helpers ---
function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function fetchWithTimeout(url: string, timeoutMs: number): Promise<Response> {
  const controller = new AbortController();
  const id = setTimeout(() => controller.abort(), timeoutMs);
  return fetch(url, { signal: controller.signal }).finally(() =>
    clearTimeout(id)
  );
}

// --- Step 1: Determine the best PlantNet project for a lat/lon ---
// Tries the PlantNet /v2/projects?lat=&lon= endpoint first,
// then falls back to a simple geographic bounding-box lookup.
async function findRegionalProject(
  lat: number,
  lon: number,
  apiKey: string
): Promise<{ id: string; name: string }> {
  try {
    const url =
      `https://my-api.plantnet.org/v2/projects` +
      `?lang=en&api-key=${encodeURIComponent(apiKey)}&lat=${lat}&lon=${lon}`;

    const res = await fetchWithTimeout(url, 10_000);
    if (res.ok) {
      const data = await res.json();
      const projects: any[] = Array.isArray(data)
        ? data
        : (data.data ?? data.projects ?? []);

      // Exclude the global catch-all; prefer the most specific regional project
      const regional = projects.filter(
        (p: any) => p.id && p.id !== "k-world-flora"
      );
      if (regional.length > 0) {
        return {
          id: regional[0].id as string,
          name: (regional[0].name ?? regional[0].id) as string,
        };
      }
    }
  } catch {
    // Fall through to bounding-box fallback
  }

  return geoFallbackProject(lat, lon);
}

// Simple lat/lon bounding-box fallback so the function always returns something useful
function geoFallbackProject(
  lat: number,
  lon: number
): { id: string; name: string } {
  // Europe
  if (lat >= 35 && lat <= 72 && lon >= -25 && lon <= 45)
    return { id: "k-europe", name: "Flora of Europe" };
  // North America
  if (lat >= 15 && lat <= 75 && lon >= -170 && lon <= -50)
    return { id: "k-north-america", name: "Flora of North America" };
  // South America
  if (lat >= -55 && lat <= 15 && lon >= -82 && lon <= -34)
    return { id: "k-south-america", name: "Flora of South America" };
  // Africa
  if (lat >= -35 && lat <= 37 && lon >= -20 && lon <= 55)
    return { id: "k-africa", name: "Flora of Africa" };
  // Australia / Oceania
  if (lat >= -50 && lat <= 0 && lon >= 110 && lon <= 180)
    return { id: "k-australia", name: "Flora of Australia" };
  // Asia (catch-all after the others)
  if (lat >= -10 && lat <= 75 && lon >= 45 && lon <= 145)
    return { id: "k-asia", name: "Flora of Asia" };

  return { id: "k-world-flora", name: "World Flora" };
}

// --- Step 2: Count species for a PlantNet project ---
// Checks for a total in response metadata first; if absent, paginates.
async function fetchSpeciesCount(
  projectId: string,
  apiKey: string
): Promise<{ count: number; resolvedProjectName: string }> {
  const PAGE_SIZE = 500;
  const MAX_PAGES = 200; // safety cap: 200 × 500 = 100 000 species

  const buildUrl = (page: number) =>
    `https://my-api.plantnet.org/v2/projects/${encodeURIComponent(projectId)}/species` +
    `?lang=en&api-key=${encodeURIComponent(apiKey)}&page=${page}&pageSize=${PAGE_SIZE}`;

  // Fetch page 1
  const res = await fetchWithTimeout(buildUrl(1), 30_000);
  if (!res.ok) {
    const errBody = await res.json().catch(() => ({}));
    throw new Error(
      `PlantNet species API returned ${res.status} for project "${projectId}": ${JSON.stringify(errBody)}`
    );
  }

  const data = await res.json();

  // Extract project name if the API returns it
  const resolvedProjectName: string =
    data?.project?.name ?? data?.projectName ?? projectId;

  // Prefer explicit total-count metadata (avoids unnecessary pagination)
  const metaTotal: number | null =
    data?.total ??
    data?.totalCount ??
    data?.meta?.total ??
    data?.meta?.totalCount ??
    null;

  if (typeof metaTotal === "number") {
    return { count: metaTotal, resolvedProjectName };
  }

  // No metadata — count by paginating
  const firstPage: any[] = Array.isArray(data)
    ? data
    : (data?.species ?? data?.data ?? data?.results ?? []);

  if (firstPage.length < PAGE_SIZE) {
    // Only one page
    return { count: firstPage.length, resolvedProjectName };
  }

  let count = firstPage.length;
  for (let page = 2; page <= MAX_PAGES; page++) {
    const pageRes = await fetchWithTimeout(buildUrl(page), 15_000);
    if (!pageRes.ok) break;

    const pageData = await pageRes.json();
    const pageSpecies: any[] = Array.isArray(pageData)
      ? pageData
      : (pageData?.species ?? pageData?.data ?? pageData?.results ?? []);

    count += pageSpecies.length;
    if (pageSpecies.length < PAGE_SIZE) break; // reached last page
  }

  return { count, resolvedProjectName };
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

  const lat = typeof body?.lat === "number" ? body.lat : null;
  const lon = typeof body?.lon === "number" ? body.lon : null;

  if (lat === null || lon === null) {
    return jsonResponse(
      { error: "Missing required fields: lat and lon (numbers)" },
      400
    );
  }

  const apiKey = Deno.env.get("PLANTNET_KEY");
  if (!apiKey) {
    return jsonResponse(
      { error: "Server misconfigured: missing PLANTNET_KEY" },
      500
    );
  }

  try {
    // 1. Determine regional project
    const project = await findRegionalProject(lat, lon, apiKey);

    // 2. Check cache
    const { data: cached, error: cacheErr } = await admin
      .from("regional_flora_cache")
      .select("project_id, project_name, species_count, fetched_at")
      .eq("project_id", project.id)
      .maybeSingle();

    if (!cacheErr && cached) {
      const ageMs = Date.now() - new Date(cached.fetched_at).getTime();
      if (ageMs < CACHE_TTL_MS) {
        return jsonResponse({
          projectId: cached.project_id,
          projectName: cached.project_name,
          speciesCount: cached.species_count,
          fromCache: true,
        });
      }
    }

    // 3. Fetch live count from PlantNet
    const { count, resolvedProjectName } = await fetchSpeciesCount(
      project.id,
      apiKey
    );

    // Use the API-returned name if we got one, otherwise keep the geo-fallback name
    const finalProjectName =
      resolvedProjectName !== project.id ? resolvedProjectName : project.name;

    // 4. Upsert into cache
    const { error: upsertErr } = await admin
      .from("regional_flora_cache")
      .upsert(
        {
          project_id: project.id,
          project_name: finalProjectName,
          species_count: count,
          fetched_at: new Date().toISOString(),
        },
        { onConflict: "project_id" }
      );

    if (upsertErr) {
      // Non-fatal: log but still return the result
      console.error("Cache upsert failed:", upsertErr);
    }

    return jsonResponse({
      projectId: project.id,
      projectName: finalProjectName,
      speciesCount: count,
      fromCache: false,
    });
  } catch (err) {
    return jsonResponse(
      { error: "Unexpected server error", details: String(err) },
      500
    );
  }
});
