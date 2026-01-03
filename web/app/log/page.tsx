"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { supabase } from "@/lib/supabaseClient";

type TreeLogRow = {
  key: string;
  name: string;
  sightings_count: number;
  last_seen: string;
  thumbnail_url: string | null;
};

function formatLastSeen(lastSeen: string | null) {
  if (!lastSeen) return "—";
  const d = new Date(lastSeen);
  if (Number.isNaN(d.getTime())) return "—";
  return d.toLocaleString();
}

export default function LogPage() {
  const [rows, setRows] = useState<TreeLogRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;

    async function load() {
      setLoading(true);
      setError(null);

      const { data, error } = await supabase
        .from("plant_log")
        .select("key,name,sightings_count,last_seen,thumbnail_url")
        .order("last_seen", { ascending: false });

      if (cancelled) return;

      if (error) {
        setError(error.message);
        setRows([]);
      } else {
        setRows((data as TreeLogRow[]) ?? []);
      }

      setLoading(false);
    }

    load();
    return () => {
      cancelled = true;
    };
  }, []);

  return (
    <div className="min-h-screen bg-zinc-50 px-6 py-10">
      <div className="mx-auto w-full max-w-3xl">
        <div className="mb-6 flex items-center justify-between">
          <h1 className="text-2xl font-semibold text-zinc-900">My Plant Log</h1>

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
            Error loading log: {error}
          </div>
        )}

        {!loading && !error && rows.length === 0 && (
          <div className="rounded-lg border bg-white p-6">
            <div className="text-zinc-900 font-medium">No plants logged yet.</div>
            <div className="mt-1 text-sm text-zinc-600">
              Go to <Link className="underline" href="/upload">Upload</Link> to add one.
            </div>
          </div>
        )}

        {!loading && !error && rows.length > 0 && (
          <ul className="space-y-3">
            {rows.map((p) => {
              const thumb = p.thumbnail_url;
              const name = p.name || "Unknown plant";
              const count = p.sightings_count;

              return (
                <li key={p.key}>
                  <Link
                    href={`/plants/${encodeURIComponent(p.key)}`}
                    className="block rounded-lg border bg-white p-4 transition-colors hover:bg-zinc-50"
                  >
                    <div className="flex gap-4">
                      <div className="h-16 w-16 shrink-0 overflow-hidden rounded-md bg-zinc-100">
                        {thumb ? (
                          // eslint-disable-next-line @next/next/no-img-element
                          <img
                            src={thumb}
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
                        <div className="flex items-start justify-between gap-3">
                          <div className="min-w-0">
                            <div className="truncate text-base font-semibold text-zinc-900">
                              {name}
                            </div>
                          </div>

                          <div className="shrink-0 rounded-full bg-zinc-100 px-2.5 py-1 text-xs font-medium text-zinc-700">
                            {count} {count === 1 ? "sighting" : "sightings"}
                          </div>
                        </div>

                        <div className="mt-2 text-xs text-zinc-500">
                          Last seen: {formatLastSeen(p.last_seen)}
                        </div>
                      </div>
                    </div>
                  </Link>
                </li>
              );
            })}
          </ul>
        )}
      </div>
    </div>
  );
}