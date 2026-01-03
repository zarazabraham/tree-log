"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { supabase } from "@/lib/supabaseClient";

type TreeLogRow = {
  key: string;
  name: string | null;
  sightings_count: number;
  last_seen: string | null;
  thumbnail_url: string | null;
};

type TreeEntryRow = {
  key: string;
  display_name: string | null;
  notes: string | null;
  updated_at: string | null;
  created_at: string | null;
};

type PlantRow = {
  key: string;
  common_name: string | null;
  scientific_name: string | null;
  family: string | null;
  genus: string | null;
  reference_images: any[] | null;
  plant_details: any | null;
};

function formatDate(s: string | null) {
  if (!s) return "—";
  const d = new Date(s);
  if (Number.isNaN(d.getTime())) return "—";
  return d.toLocaleString();
}

function getRefImageUrl(img: any): string | null {
  return (
    img?.url ||
    img?.urls?.m ||
    img?.urls?.s ||
    img?.urls?.o ||
    img?.url?.m ||
    img?.url?.s ||
    img?.url?.o ||
    null
  );
}

export default function PlantDetailPage() {
  const params = useParams();

  // Robust param handling: supports /plants/[key] OR /plants/[plantKey]
  const plantKey = useMemo(() => {
    const raw =
      (params as any)?.key ?? (params as any)?.plantKey ?? (params as any)?.slug;
    return decodeURIComponent(String(raw ?? ""));
  }, [params]);

  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const [logRow, setLogRow] = useState<TreeLogRow | null>(null);
  const [entryRow, setEntryRow] = useState<TreeEntryRow | null>(null);
  const [plant, setPlant] = useState<PlantRow | null>(null);

  // UI modes
  const [isEditing, setIsEditing] = useState(false);

  // Editable fields
  const [displayName, setDisplayName] = useState("");
  const [notes, setNotes] = useState("");

  // Snapshot for cancel
  const originalRef = useRef<{ displayName: string; notes: string }>({
    displayName: "",
    notes: "",
  });

  // Toast
  const [toast, setToast] = useState<{ show: boolean; message: string }>({
    show: false,
    message: "",
  });
  const toastTimer = useRef<number | null>(null);

  function showToast(message: string) {
    setToast({ show: true, message });
    if (toastTimer.current) window.clearTimeout(toastTimer.current);
    toastTimer.current = window.setTimeout(() => {
      setToast({ show: false, message: "" });
    }, 2200);
  }

  useEffect(() => {
    return () => {
      if (toastTimer.current) window.clearTimeout(toastTimer.current);
    };
  }, []);

  useEffect(() => {
    let cancelled = false;

    async function load() {
      setLoading(true);
      setError(null);
      setIsEditing(false);

      // If route param didn't come through, show a helpful error
      if (!plantKey) {
        setError(
          "Missing plant key in URL. Make sure your folder is web/app/plants/[key]/page.tsx (or update useParams accordingly).",
        );
        setLoading(false);
        return;
      }

      // 1) Load deduped log row
      const { data: log, error: logErr } = await supabase
        .from("plant_log")
        .select("key,name,sightings_count,last_seen,thumbnail_url")
        .eq("key", plantKey)
        .maybeSingle();

      if (cancelled) return;

      if (logErr) {
        setError(`Error loading plant_log: ${logErr.message}`);
        setLoading(false);
        return;
      }

      setLogRow((log as TreeLogRow) ?? null);

      // 2) Load notes row; if missing, create it
      const { data: entry, error: entryErr } = await supabase
        .from("tree_entries")
        .select("key,display_name,notes,created_at,updated_at")
        .eq("key", plantKey)
        .maybeSingle();

      if (cancelled) return;

      if (entryErr) {
        setError(`Error loading tree_entries: ${entryErr.message}`);
        setLoading(false);
        return;
      }

      let resolvedEntry = entry as TreeEntryRow | null;

      if (!resolvedEntry) {
        const { data: created, error: createErr } = await supabase
          .from("tree_entries")
          .insert({
            key: plantKey,
            display_name: log?.name ?? null,
            notes: null,
          })
          .select("key,display_name,notes,created_at,updated_at")
          .single();

        if (cancelled) return;

        if (createErr) {
          setError(`Error creating tree_entries row: ${createErr.message}`);
          setLoading(false);
          return;
        }

        resolvedEntry = created as TreeEntryRow;
      }

      setEntryRow(resolvedEntry);

      const dn = resolvedEntry.display_name ?? (log?.name ?? "");
      const nt = resolvedEntry.notes ?? "";

      setDisplayName(dn);
      setNotes(nt);

      // Store original snapshot for cancel
      originalRef.current = { displayName: dn, notes: nt };

      // 3) Load plant data using lowercase key
      const keyLc = plantKey.toLowerCase();

      const { data: plantData, error: plantErr } = await supabase
        .from("plants")
        .select("key,common_name,scientific_name,family,genus,reference_images,plant_details,key_lc")
        .eq("key_lc", keyLc)
        .maybeSingle();

        // DEBUG: what did Supabase actually return?
        console.log("plantKey:", plantKey);
        console.log("plantErr:", plantErr);
        console.log("plantData:", plantData);

      if (cancelled) return;

      setPlant((plantData as PlantRow) ?? null);

      setLoading(false);
    }

    load();
    return () => {
      cancelled = true;
    };
  }, [plantKey]);

  function startEdit() {
    setIsEditing(true);
    originalRef.current = { displayName, notes };
  }

  function cancelEdit() {
    setDisplayName(originalRef.current.displayName);
    setNotes(originalRef.current.notes);
    setIsEditing(false);
    setError(null);
  }

  async function save() {
    setSaving(true);
    setError(null);

    const payload = {
      key: plantKey,
      display_name: displayName.trim() ? displayName.trim() : null,
      notes: notes.trim() ? notes.trim() : null,
      updated_at: new Date().toISOString(),
    };

    const { data, error } = await supabase
      .from("tree_entries")
      .upsert(payload, { onConflict: "key" })
      .select("key,display_name,notes,created_at,updated_at")
      .single();

    if (error) {
      setError(`Save failed: ${error.message}`);
      setSaving(false);
      return;
    }

    const updated = data as TreeEntryRow;
    setEntryRow(updated);

    const dn = updated.display_name ?? "";
    const nt = updated.notes ?? "";
    originalRef.current = { displayName: dn, notes: nt };

    setIsEditing(false);
    setSaving(false);
    showToast("Saved");
  }

  const title = entryRow?.display_name || logRow?.name || "Unknown plant";

  return (
    <div className="min-h-screen bg-zinc-50 px-6 py-10">
      {/* Toast */}
      {toast.show && (
        <div className="fixed left-1/2 top-6 z-50 -translate-x-1/2 rounded-full border bg-white px-4 py-2 text-sm text-zinc-900 shadow-sm">
          {toast.message}
        </div>
      )}

      <div className="mx-auto w-full max-w-3xl">
        <div className="mb-6 flex items-center justify-between">
          <Link href="/log" className="text-sm underline text-zinc-600">
            ← Back to Log
          </Link>

          <Link
            href="/upload"
            className="rounded-md bg-zinc-900 px-3 py-2 text-sm font-medium text-white hover:bg-zinc-800"
          >
            Upload
          </Link>
        </div>

        {loading && (
          <div className="rounded-lg border bg-white p-4 text-sm text-zinc-600">
            Loading…
          </div>
        )}

        {!loading && error && (
          <div className="rounded-lg border border-red-200 bg-red-50 p-4 text-sm text-red-700">
            {error}
          </div>
        )}

        {!loading && !error && (
          <div className="space-y-4">
            {/* Summary card */}
            <div className="rounded-lg border bg-white p-6">
              <div className="flex gap-4">
                <div className="h-20 w-20 shrink-0 overflow-hidden rounded-md bg-zinc-100">
                  {logRow?.thumbnail_url ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img
                      src={logRow.thumbnail_url}
                      alt="Plant thumbnail"
                      className="h-full w-full object-cover"
                    />
                  ) : (
                    <div className="flex h-full w-full items-center justify-center text-xs text-zinc-500">
                      No image
                    </div>
                  )}
                </div>

                <div className="min-w-0 flex-1">
                  <div className="text-lg font-semibold text-zinc-900">
                    {title}
                  </div>

                  <div className="mt-1 text-sm text-zinc-600">
                    {logRow?.sightings_count ?? 0} sightings · Last seen{" "}
                    {formatDate(logRow?.last_seen ?? null)}
                  </div>

                  <div className="mt-2 text-xs text-zinc-400">
                    Key: <span className="font-mono">{plantKey}</span>
                  </div>
                </div>
              </div>
            </div>

            {/* Plant details ALWAYS renders (shows empty state if plant is null) */}
            <div className="rounded-lg border bg-white p-6">
              <div className="text-base font-semibold text-zinc-900">
                Plant details
              </div>

              {!plant ? (
                <div className="mt-2 text-sm text-zinc-600">
                  No plant details found for this key yet. (This usually means
                  the URL key doesn’t match the plants table key.)
                </div>
              ) : (
                <>
                  <div className="mt-3 grid grid-cols-2 gap-3 text-sm">
                    <div>
                      <div className="text-xs font-medium text-zinc-500">
                        Common name
                      </div>
                      <div className="mt-1 text-zinc-900">
                        {plant.common_name || "—"}
                      </div>
                    </div>

                    <div>
                      <div className="text-xs font-medium text-zinc-500">
                        Scientific name
                      </div>
                      <div className="mt-1 text-zinc-900">
                        {plant.scientific_name || "—"}
                      </div>
                    </div>

                    <div>
                      <div className="text-xs font-medium text-zinc-500">
                        Family
                      </div>
                      <div className="mt-1 text-zinc-900">
                        {plant.family || "—"}
                      </div>
                    </div>

                    <div>
                      <div className="text-xs font-medium text-zinc-500">
                        Genus
                      </div>
                      <div className="mt-1 text-zinc-900">
                        {plant.genus || "—"}
                      </div>
                    </div>
                  </div>

                  {plant.reference_images?.length ? (
                    <div className="mt-4 grid grid-cols-3 gap-2">
                      {plant.reference_images.slice(0, 6).map((img: any, i: number) => {
                        const url = getRefImageUrl(img);
                        if (!url) return null;

                        // eslint-disable-next-line @next/next/no-img-element
                        return (
                          <img
                            key={i}
                            src={url}
                            alt="Reference"
                            className="h-24 w-full rounded object-cover"
                          />
                        );
                      })}
                    </div>
                  ) : (
                    <div className="mt-3 text-sm text-zinc-600">
                      No reference images available.
                    </div>
                  )}
                </>
              )}
            </div>

            {/* Notes card */}
            <div className="rounded-lg border bg-white p-6">
              <div className="mb-4 flex items-start justify-between gap-4">
                <div>
                  <div className="text-base font-semibold text-zinc-900">
                    Notes
                  </div>
                  <div className="mt-1 text-sm text-zinc-600">
                    Notes stick to this plant entry (across all sightings).
                  </div>
                </div>

                {!isEditing ? (
                  <button
                    onClick={startEdit}
                    className="shrink-0 rounded-md border bg-white px-3 py-2 text-sm font-medium text-zinc-900 hover:bg-zinc-50"
                  >
                    Edit
                  </button>
                ) : (
                  <div className="shrink-0 flex gap-2">
                    <button
                      onClick={cancelEdit}
                      className="rounded-md border bg-white px-3 py-2 text-sm font-medium text-zinc-900 hover:bg-zinc-50"
                      disabled={saving}
                    >
                      Cancel
                    </button>
                    <button
                      onClick={save}
                      disabled={saving}
                      className="rounded-md bg-zinc-900 px-3 py-2 text-sm font-medium text-white hover:bg-zinc-800 disabled:opacity-60"
                    >
                      {saving ? "Saving…" : "Save"}
                    </button>
                  </div>
                )}
              </div>

              {/* READ MODE */}
              {!isEditing && (
                <div className="space-y-4">
                  <div>
                    <div className="text-xs font-medium text-zinc-500">
                      Display name
                    </div>
                    <div className="mt-1 text-sm text-zinc-900">
                      {entryRow?.display_name?.trim()
                        ? entryRow.display_name
                        : "—"}
                    </div>
                  </div>

                  <div>
                    <div className="text-xs font-medium text-zinc-500">
                      Notes
                    </div>
                    <div className="mt-1 whitespace-pre-wrap rounded-md bg-zinc-50 p-3 text-sm text-zinc-900">
                      {entryRow?.notes?.trim()
                        ? entryRow.notes
                        : "No notes yet."}
                    </div>
                  </div>

                  <div className="text-xs text-zinc-500">
                    Last updated: {formatDate(entryRow?.updated_at ?? null)}
                  </div>
                </div>
              )}

              {/* EDIT MODE */}
              {isEditing && (
                <div>
                  <label className="block text-sm font-medium text-zinc-700">
                    Display name (optional)
                  </label>
                  <input
                    value={displayName}
                    onChange={(e) => setDisplayName(e.target.value)}
                    className="mt-1 w-full rounded-md border px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-zinc-200"
                    placeholder="e.g. The big tree by the creek"
                    disabled={saving}
                  />

                  <label className="mt-4 block text-sm font-medium text-zinc-700">
                    Notes
                  </label>
                  <textarea
                    value={notes}
                    onChange={(e) => setNotes(e.target.value)}
                    className="mt-1 min-h-[160px] w-full rounded-md border px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-zinc-200"
                    placeholder="What do you want to remember about this plant?"
                    disabled={saving}
                  />

                  <div className="mt-3 text-xs text-zinc-500">
                    Last updated: {formatDate(entryRow?.updated_at ?? null)}
                  </div>
                </div>
              )}
            </div>
            
  
          </div>
        )}
      </div>
    </div>
  );
}