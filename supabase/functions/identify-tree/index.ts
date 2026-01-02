import { createClient } from "https://esm.sh/@supabase/supabase-js@2?target=deno";

// Minimal, robust handler for: POST { imageUrl, lat?, lng?, organ? }
// Returns: { name, confidence, features }

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

Deno.serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: corsHeaders,
    })
  }

  // Only allow POST
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    })
  }

  // Parse body safely
  let body: any
  try {
    body = await req.json()
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON body" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    })
  }

  const imageUrl = body?.imageUrl as string | undefined
  let normalizedImageUrl = imageUrl;

// If the client sends a localhost URL, Docker can't reach it.
// Rewrite to host.docker.internal so the container can reach your Mac.
  normalizedImageUrl = normalizedImageUrl
  .replace("http://127.0.0.1:54321", "http://host.docker.internal:54321")
  .replace("http://localhost:54321", "http://host.docker.internal:54321");
  
  const lat = typeof body?.lat === "number" ? body.lat : null
  const lng = typeof body?.lng === "number" ? body.lng : null

  if (!imageUrl || typeof imageUrl !== "string") {
    return new Response(JSON.stringify({ error: "Missing required field: imageUrl" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    })
  }

  const apiKey = Deno.env.get("PLANTNET_KEY")
  if (!apiKey) {
    return new Response(JSON.stringify({ error: "Server misconfigured: missing PLANTNET_KEY" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    })
  }

  const SUPABASE_URL = Deno.env.get("SUPABASE_URL")
  const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")

  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    return new Response(JSON.stringify({ error: "Server misconfigured: missing Supabase env" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    })
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false },
  })

  // Get optional organ parameter (default to "leaf")
  const organ = (body?.organ as string) || "leaf"
  const validOrgans = ["leaf", "flower", "fruit", "bark", "auto"]
  if (!validOrgans.includes(organ)) {
    return new Response(JSON.stringify({
      error: `Invalid organ type. Must be one of: ${validOrgans.join(", ")}`
    }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    })
  }

  try {
    // 1) Download the image (PlantNet expects multipart image upload)
    // Add timeout to prevent hanging
    const controller = new AbortController()
    const timeoutId = setTimeout(() => controller.abort(), 15000) // 15 second timeout

    let imgRes
    try {
      imgRes = await fetch(normalizedImageUrl, { signal: controller.signal })
    } catch (fetchErr) {
      clearTimeout(timeoutId)
      if (fetchErr instanceof Error && fetchErr.name === "AbortError") {
        return new Response(
          JSON.stringify({ error: "Image fetch timeout after 15 seconds" }),
          { status: 408, headers: { ...corsHeaders, "Content-Type": "application/json" } },
        )
      }
      throw fetchErr
    }
    clearTimeout(timeoutId)

    if (!imgRes.ok) {
      return new Response(
        JSON.stringify({ error: `Could not fetch imageUrl (HTTP ${imgRes.status})` }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      )
    }

    let imgBlob
    try {
      imgBlob = await imgRes.blob()
    } catch (blobErr) {
      return new Response(
        JSON.stringify({ error: "Failed to read image data from URL" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      )
    }

    // Detect content type from response or blob
    const contentType = imgRes.headers.get("content-type") || imgBlob.type || "image/jpeg"
    const extension = contentType.includes("png") ? "png" :
                     contentType.includes("webp") ? "webp" : "jpg"

    // 2) Call Pl@ntNet Identify (basic usage; you can refine organ/project later)
    // Docs: PlantNet "identify" endpoint typically accepts multipart form fields:
    // - images: file
    // - organs: e.g. "leaf"
    // - (optional) include-related-images, lang, etc.
    const form = new FormData()
    form.append("images", imgBlob, `tree.${extension}`)
    form.append("organs", organ)

    const project = "k-world-flora"
    // add these query params:
    const plantNetUrl =
    `https://my-api.plantnet.org/v2/identify/${project}` +
    `?api-key=${encodeURIComponent(apiKey)}` +
    `&include-related-images=true` +
    `&nb-results=3` +
    `&lang=en`

    const plantNetController = new AbortController()
    const plantNetTimeoutId = setTimeout(() => plantNetController.abort(), 30000) // 30 second timeout

    let idRes
    try {
      idRes = await fetch(plantNetUrl, {
        method: "POST",
        body: form,
        signal: plantNetController.signal,
      })
    } catch (fetchErr) {
      clearTimeout(plantNetTimeoutId)
      if (fetchErr instanceof Error && fetchErr.name === "AbortError") {
        return new Response(
          JSON.stringify({ error: "PlantNet API timeout after 30 seconds" }),
          { status: 408, headers: { ...corsHeaders, "Content-Type": "application/json" } },
        )
      }
      throw fetchErr
    }
    clearTimeout(plantNetTimeoutId)

    const raw = await idRes.json().catch(() => ({}))

    if (!idRes.ok) {
      return new Response(
        JSON.stringify({
          error: "PlantNet request failed",
          status: idRes.status,
          details: raw,
        }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      )
    }

    // 3) Extract best match (PlantNet returns results[] with score)
    const best = raw?.results?.[0]

    // Extract detailed plant information
    const commonName =
      best?.species?.commonNames?.[0] ??
      best?.species?.scientificNameWithoutAuthor ??
      best?.species?.scientificName ??
      "Unknown"

    const scientificName =
      best?.species?.scientificNameWithoutAuthor ??
      best?.species?.scientificName ??
      null

    const genus = best?.species?.genus?.scientificNameWithoutAuthor ?? null
    const family = best?.species?.family?.scientificNameWithoutAuthor ?? null
    const commonNames = Array.isArray(best?.species?.commonNames) ? best.species.commonNames : []

    const gbifId = best?.gbif?.id ? String(best.gbif.id) : null
    const powoId = best?.powo?.id ? String(best.powo.id) : null
    const iucnCategory = best?.iucn?.category ? String(best.iucn.category) : null

    const confidence = typeof best?.score === "number" ? best.score : null

    // PlantNet doesn't directly return "features" in a friendly way.
    // For MVP, return a placeholder list; later we can compute features from tags/metadata or a second pass.
    const features: string[] = []

    // Extract reference images from PlantNet response
    const referenceImages =
      Array.isArray(best?.images)
        ? best.images.slice(0, 6).map((img: any) => ({
            url: img?.url?.m ?? img?.url?.o ?? img?.url?.s, // use medium first
            urlSmall: img?.url?.s ?? null,
            urlOriginal: img?.url?.o ?? null,
            organ: img?.organ ?? null,
            author: img?.author ?? null,
            license: img?.license ?? null,
            citation: img?.citation ?? null,
          })).filter((x: any) => x.url)
        : []

    // 4) Store result in database
    const { data, error } = await supabase
      .from("trees")
      .insert({
        image_path: imageUrl, // MVP: store URL as path for now
        image_url: imageUrl,
        lat,
        lng,
        identified_name: commonName,
        scientific_name: scientificName,
        genus,
        family,
        common_names: commonNames,
        gbif_id: gbifId,
        powo_id: powoId,
        iucn_category: iucnCategory,
        confidence,
        features,
      })
      .select("id, created_at")
      .single()

    if (error) {
      return new Response(
        JSON.stringify({ error: "DB insert failed", details: error }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      )
    }

    return new Response(
      JSON.stringify({
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
    )
  } catch (err) {
    return new Response(
      JSON.stringify({ error: "Unexpected server error", details: String(err) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    )
  }
})