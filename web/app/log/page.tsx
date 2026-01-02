"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { supabase } from "@/lib/supabaseClient";

type TreeRow = {
  id: string;
  created_at: string;
  image_url: string | null;
  identified_name: string | null;
  scientific_name: string | null;
  confidence: number | null;
};

export default function LogPage() {
  const [rows, setRows] = useState<TreeRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function load() {
      setLoading(true);
      setError(null);

      const { data, error } = await supabase
        .from("trees")
        .select("id, created_at, image_url, identified_name, scientific_name, confidence")
        .order("created_at", { ascending: false })
        .limit(50);

      console.log("Supabase query result:", { data, error });

      if (error) {
        console.error("Error loading trees:", error);
        setError(error.message);
        setRows([]);
      } else {
        console.log("Loaded trees:", data);
        setRows((data ?? []) as TreeRow[]);
      }

      setLoading(false);
    }

    load();
  }, []);

  return (
    <div className="min-h-screen bg-zinc-50 px-6 py-10">
      <div className="mx-auto w-full max-w-3xl">
        <div className="mb-6 flex items-center justify-between">
          <h1 className="text-2xl font-semibold">Tree Log</h1>
          <div className="flex gap-3">
            <Link className="text-sm underline" href="/upload">
              Add new
            </Link>
            <Link className="text-sm underline" href="/">
              Home
            </Link>
          </div>
        </div>

        {loading && (
          <div className="rounded-lg border bg-white p-4 text-sm text-zinc-600">
            Loading…
          </div>
        )}

        {error && (
          <div className="rounded-lg border border-red-200 bg-red-50 p-4 text-sm text-red-700">
            Error loading log: {error}
          </div>
        )}

        {!loading && !error && rows.length === 0 && (
          <div className="rounded-lg border bg-white p-6 text-sm text-zinc-600">
            No trees logged yet. Go to <Link className="underline" href="/upload">Upload</Link> to add one.
          </div>
        )}

        <ul className="space-y-3">
          {rows.map((t) => (
            <li key={t.id} className="rounded-xl border bg-white p-3">
              <div className="flex gap-3">
                <div className="h-16 w-16 overflow-hidden rounded-lg bg-zinc-100">
                  {t.image_url ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img
                      src={t.image_url}
                      alt=""
                      className="h-full w-full object-cover"
                    />
                  ) : null}
                </div>

                <div className="flex-1">
                  <div className="flex items-start justify-between gap-3">
                    <div>
                      <div className="font-medium">
                        {t.identified_name ?? "Unknown"}
                      </div>
                      <div className="text-sm text-zinc-600 italic">
                        {t.scientific_name ?? ""}
                      </div>
                    </div>

                    {typeof t.confidence === "number" && (
                      <div className="rounded-full bg-zinc-100 px-2 py-1 text-xs text-zinc-700">
                        {(t.confidence * 100).toFixed(1)}%
                      </div>
                    )}
                  </div>

                  <div className="mt-1 text-xs text-zinc-500">
                    {new Date(t.created_at).toLocaleString()}
                  </div>
                </div>
              </div>
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
}