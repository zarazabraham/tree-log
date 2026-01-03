import { createClient } from "https://esm.sh/@supabase/supabase-js@2?target=deno";

// Minimal, robust handler for: POST { imageUrl, lat?, lng?, organ? }
// Returns: { key, name, confidence, referenceImages, ... }

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// --- helpers ---
function slugifyKey(s: string) {
  return s
    .toLowerCase()
    .trim()
    .replace(/\s+/g, "-")
    .replace(/[^a-z0-9-]/g, "");
}

// Create admin client with service role key for database operations
const rawSupabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
const supabaseUrl = rawSupabaseUrl
  .replace("http://127.0.0.1:54321", "http://host.docker.internal:54321")
  .replace("http://localhost:54321", "http://host.docker.internal:54321");

// Use the built-in service role key if available, otherwise allow a custom env var name.
// (Supabase CLI can skip env vars that start with SUPABASE_ when using --env-file)
const serviceKey =
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
  Deno.env.get("SERVICE_ROLE_KEY") ??
  "";

if (!supabaseUrl) {
  throw new Error("Missing SUPABASE_URL");
}
if (!serviceKey) {
  throw new Error("Missing service role key (SUPABASE_SERVICE_ROLE_KEY or SERVICE_ROLE_KEY)");
}

const admin = createClient(supabaseUrl, serviceKey);

Deno.serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  // Only allow POST
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  // Parse body safely
  let body: any;
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON body" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const imageUrl = body?.imageUrl as string | undefined;
  const lat = typeof body?.lat === "number" ? body.lat : null;
  const lng = typeof body?.lng === "number" ? body.lng : null;

  if (!imageUrl || typeof imageUrl !== "string") {
    return new Response(JSON.stringify({ error: "Missing required field: imageUrl" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  // If the client sends a localhost URL, Docker can't reach it.
  // Rewrite to host.docker.internal so the container can reach your Mac.
  const normalizedImageUrl = imageUrl
    .replace("http://127.0.0.1:54321", "http://host.docker.internal:54321")
    .replace("http://localhost:54321", "http://host.docker.internal:54321");

  const apiKey = Deno.env.get("PLANTNET_KEY");
  if (!apiKey) {
    return new Response(JSON.stringify({ error: "Server misconfigured: missing PLANTNET_KEY" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  // Get optional organ parameter (default to "leaf")
  const organ = (body?.organ as string) || "leaf";
  const validOrgans = ["leaf", "flower", "fruit", "bark", "auto"];
  if (!validOrgans.includes(organ)) {
    return new Response(
      JSON.stringify({
        error: `Invalid organ type. Must be one of: ${validOrgans.join(", ")}`,
      }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  try {
    // 1) Download the image (PlantNet expects multipart image upload)
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 15000);

    let imgRes: Response;
    try {
      imgRes = await fetch(normalizedImageUrl, { signal: controller.signal });
    } catch (fetchErr) {
      clearTimeout(timeoutId);
      if (fetchErr instanceof Error && fetchErr.name === "AbortError") {
        return new Response(JSON.stringify({ error: "Image fetch timeout after 15 seconds" }), {
          status: 408,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      throw fetchErr;
    }
    clearTimeout(timeoutId);

    if (!imgRes.ok) {
      return new Response(
        JSON.stringify({ error: `Could not fetch imageUrl (HTTP ${imgRes.status})` }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const imgBlob = await imgRes.blob();

    // Detect content type from response or blob
    const contentType = imgRes.headers.get("content-type") || imgBlob.type || "image/jpeg";
    const extension = contentType.includes("png")
      ? "png"
      : contentType.includes("webp")
        ? "webp"
        : "jpg";

    // 2) Call Pl@ntNet Identify
    const form = new FormData();
    form.append("images", imgBlob, `tree.${extension}`);
    form.append("organs", organ);

    const project = "k-world-flora";
    const plantNetUrl =
      `https://my-api.plantnet.org/v2/identify/${project}` +
      `?api-key=${encodeURIComponent(apiKey)}` +
      `&include-related-images=true` +
      `&nb-results=3` +
      `&lang=en`;

    const plantNetController = new AbortController();
    const plantNetTimeoutId = setTimeout(() => plantNetController.abort(), 30000);

    let idRes: Response;
    try {
      idRes = await fetch(plantNetUrl, {
        method: "POST",
        body: form,
        signal: plantNetController.signal,
      });
    } catch (fetchErr) {
      clearTimeout(plantNetTimeoutId);
      if (fetchErr instanceof Error && fetchErr.name === "AbortError") {
        return new Response(JSON.stringify({ error: "PlantNet API timeout after 30 seconds" }), {
          status: 408,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      throw fetchErr;
    }
    clearTimeout(plantNetTimeoutId);

    const raw = await idRes.json().catch(() => ({}));

    if (!idRes.ok) {
      return new Response(
        JSON.stringify({
          error: "PlantNet request failed",
          status: idRes.status,
          details: raw,
        }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // 3) Extract best match
    const best = raw?.results?.[0];

    // Build plant record from extracted information
    const commonName =
      best?.species?.commonNames?.[0] ||
      best?.species?.scientificNameWithoutAuthor ||
      best?.species?.scientificName ||
      "Unknown";

    const scientificName =
      best?.species?.scientificName || best?.species?.scientificNameWithoutAuthor || null;

    const family = best?.species?.family?.scientificNameWithoutAuthor || null;
    const genus = best?.species?.genus?.scientificNameWithoutAuthor || null;
    const commonNames = Array.isArray(best?.species?.commonNames) ? best.species.commonNames : [];

    const gbifId = best?.gbif?.id ? String(best.gbif.id) : null;
    const powoId = best?.powo?.id ? String(best.powo.id) : null;
    const iucnCategory = best?.iucn?.category ? String(best.iucn.category) : null;

    const confidence = typeof best?.score === "number" ? best.score : null;

    const features: string[] = [];

    const referenceImages =
      (best?.images ?? []).map((img: any) => ({
        organ: img.organ,
        author: img.author,
        license: img.license,
        citation: img.citation,
        url: img.url?.m || img.url?.s || img.url?.o || null,
        urls: img.url ?? null,
      })) ?? [];

    // ✅ Canonical key used for BOTH DB + URL routing
    const rawKey =
      best?.species?.scientificNameWithoutAuthor ||
      best?.species?.scientificName ||
      commonName ||
    
      "unknown";
    const plantKey = slugifyKey(String(rawKey));
    const plantKeyLc = plantKey
      .trim()
      .toLowerCase()
      .replace(/\s+/g, "-");

    await admin.from("plants").upsert(
      {
        key: plantKey,
        key_lc: plantKeyLc,
        common_name: commonName,
        scientific_name: scientificName,
        family,
        genus,
        reference_images: referenceImages,
        plant_details: best,
      },
      { onConflict: "key" }
    );

    // 4) Upsert into plants table
    const { data: plantData, error: plantError } = await admin
      .from("plants")
      .upsert(
        {
          key: plantKey,
          key_lc: plantKey.toLowerCase(),
          common_name: commonName,
          scientific_name: scientificName,
          family,
          genus,
          reference_images: referenceImages,
          plant_details: best, // store the whole best match for now
          updated_at: new Date().toISOString(),
        },
        { onConflict: "key" },
      )
      .select("id")
      .single();

    if (plantError) {
      return new Response(JSON.stringify({ error: "Plant upsert failed", details: plantError }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 5) Insert sighting record
    const { data, error } = await admin
      .from("sightings")
      .insert({
        plant_id: plantData.id,
        image_url: imageUrl,
        lat,
        lng,
        confidence,
      })
      .select("id, created_at")
      .single();

    if (error) {
      return new Response(JSON.stringify({ error: "Sighting insert failed", details: error }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // ✅ Return key so frontend can link to /plants/{key}
    return new Response(
      JSON.stringify({
        key: plantKey,
        id: data.id,
        created_at: data.created_at,
        name: commonName,
        commonName,
        scientificName,
        genus,
        family,
        commonNames,
        gbifId,
        powoId,
        iucnCategory,
        confidence,
        features,
        referenceImages,
        rawTop: best,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: "Unexpected server error", details: String(err) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});