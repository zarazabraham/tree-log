// Stateless Pl@ntNet proxy.
//
// POST multipart/form-data:
//   image  (file, required)  — JPEG/PNG, already downscaled by the client
//   organ  (text, optional)  — leaf | flower | fruit | bark | auto   (default: leaf)
//
// Returns the best match as JSON. Nothing is persisted: the client owns the data
// and stores it in SwiftData. This function exists only because PLANTNET_KEY cannot
// ship inside the app bundle.

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const VALID_ORGANS = ["leaf", "flower", "fruit", "bark", "auto"];
const PLANTNET_TIMEOUT_MS = 30_000;
const MAX_IMAGE_BYTES = 10 * 1024 * 1024;

/// Canonical species key, used by the client as the identity of a Plant record.
function slugifyKey(s: string) {
  return s
    .toLowerCase()
    .trim()
    .replace(/\s+/g, "-")
    .replace(/[^a-z0-9-]/g, "");
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  const apiKey = Deno.env.get("PLANTNET_KEY");
  if (!apiKey) {
    return jsonResponse({ error: "Server misconfigured: missing PLANTNET_KEY" }, 500);
  }

  // --- Parse the uploaded image ---
  let form: FormData;
  try {
    form = await req.formData();
  } catch {
    return jsonResponse(
      { error: "Expected multipart/form-data with an 'image' file field" },
      400,
    );
  }

  const image = form.get("image");
  if (!(image instanceof File)) {
    return jsonResponse({ error: "Missing required file field: image" }, 400);
  }
  if (image.size === 0) {
    return jsonResponse({ error: "Uploaded image is empty" }, 400);
  }
  if (image.size > MAX_IMAGE_BYTES) {
    return jsonResponse(
      { error: `Image too large (${image.size} bytes, max ${MAX_IMAGE_BYTES})` },
      413,
    );
  }

  const organ = (form.get("organ") as string | null) || "leaf";
  if (!VALID_ORGANS.includes(organ)) {
    return jsonResponse(
      { error: `Invalid organ type. Must be one of: ${VALID_ORGANS.join(", ")}` },
      400,
    );
  }

  // --- Call Pl@ntNet ---
  const contentType = image.type || "image/jpeg";
  const extension = contentType.includes("png")
    ? "png"
    : contentType.includes("webp")
      ? "webp"
      : "jpg";

  const outbound = new FormData();
  outbound.append("images", image, `plant.${extension}`);
  outbound.append("organs", organ);

  const plantNetUrl =
    `https://my-api.plantnet.org/v2/identify/k-world-flora` +
    `?api-key=${encodeURIComponent(apiKey)}` +
    `&include-related-images=true` +
    `&nb-results=3` +
    `&lang=en`;

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), PLANTNET_TIMEOUT_MS);

  let idRes: Response;
  try {
    idRes = await fetch(plantNetUrl, {
      method: "POST",
      body: outbound,
      signal: controller.signal,
    });
  } catch (err) {
    if (err instanceof Error && err.name === "AbortError") {
      return jsonResponse({ error: "Pl@ntNet timed out after 30 seconds" }, 408);
    }
    return jsonResponse({ error: "Pl@ntNet request failed", details: String(err) }, 502);
  } finally {
    clearTimeout(timeoutId);
  }

  const raw = await idRes.json().catch(() => ({}));

  if (!idRes.ok) {
    // Pl@ntNet answers 404 "Species not found" for an unrecognizable photo. That is a
    // normal outcome, not a server fault, so surface it as 404 — the client turns it
    // into "No plant matched this photo" rather than an error banner.
    if (idRes.status === 404) {
      return jsonResponse({ error: "No match found for this image" }, 404);
    }
    return jsonResponse(
      { error: "Pl@ntNet request failed", status: idRes.status, details: raw },
      502,
    );
  }

  // --- Shape the best match for the client ---
  const best = raw?.results?.[0];
  if (!best) {
    return jsonResponse({ error: "No match found for this image" }, 404);
  }

  const commonName =
    best?.species?.commonNames?.[0] ||
    best?.species?.scientificNameWithoutAuthor ||
    best?.species?.scientificName ||
    "Unknown";

  const scientificName =
    best?.species?.scientificName || best?.species?.scientificNameWithoutAuthor || null;

  const rawKey =
    best?.species?.scientificNameWithoutAuthor ||
    best?.species?.scientificName ||
    commonName ||
    "unknown";

  const referenceImages = (best?.images ?? []).map((img: any) => ({
    organ: img.organ ?? null,
    author: img.author ?? null,
    license: img.license ?? null,
    url: img.url?.m || img.url?.s || img.url?.o || null,
  }));

  return jsonResponse({
    key: slugifyKey(String(rawKey)),
    name: commonName,
    commonName,
    scientificName,
    genus: best?.species?.genus?.scientificNameWithoutAuthor || null,
    family: best?.species?.family?.scientificNameWithoutAuthor || null,
    commonNames: Array.isArray(best?.species?.commonNames) ? best.species.commonNames : [],
    gbifId: best?.gbif?.id ? String(best.gbif.id) : null,
    powoId: best?.powo?.id ? String(best.powo.id) : null,
    iucnCategory: best?.iucn?.category ? String(best.iucn.category) : null,
    confidence: typeof best?.score === "number" ? best.score : null,
    referenceImages,
  });
});
