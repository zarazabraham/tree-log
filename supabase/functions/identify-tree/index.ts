
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
      imgRes = await fetch(imageUrl, { signal: controller.signal })
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

    const plantNetUrl = "https://my-api.plantnet.org/v2/identify/all"

    const plantNetController = new AbortController()
    const plantNetTimeoutId = setTimeout(() => plantNetController.abort(), 30000) // 30 second timeout

    let idRes
    try {
      idRes = await fetch(plantNetUrl, {
        method: "POST",
        headers: {
          "Api-Key": apiKey,
        },
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
    const name =
      best?.species?.commonNames?.[0] ||
      best?.species?.scientificNameWithoutAuthor ||
      best?.species?.scientificName ||
      "Unknown"

    const confidence = typeof best?.score === "number" ? best.score : null

    // PlantNet doesn't directly return "features" in a friendly way.
    // For MVP, return a placeholder list; later we can compute features from tags/metadata or a second pass.
    const features: string[] = []

    return new Response(
      JSON.stringify({ name, confidence, features, rawTop: best }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    )
  } catch (err) {
    return new Response(
      JSON.stringify({ error: "Unexpected server error", details: String(err) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    )
  }
})