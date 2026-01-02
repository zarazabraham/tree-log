"use client";

import { useEffect, useState } from "react";
import { supabase } from "../../lib/supabaseClient";

type TreeRow = {
  id: string;
  created_at: string;
  identified_name: string | null;
  confidence: number | null;
  image_url: string;
};

export default function LogPage() {
  const [rows, setRows] = useState<TreeRow[]>([]);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    (async () => {
      const { data, error } = await supabase
        .from("trees")
        .select("id, created_at, identified_name, confidence, image_url")
        .order("created_at", { ascending: false })
        .limit(25);

      if (error) setError(error.message);
      else setRows((data as TreeRow[]) ?? []);
    })();
  }, []);

  return (
    <main style={{ padding: 24, maxWidth: 900, margin: "0 auto" }}>
      <h1 style={{ fontSize: 28, fontWeight: 700 }}>Tree Log</h1>
      <p style={{ marginTop: 8, opacity: 0.8 }}>
        Recent trees you’ve identified.
      </p>

      <div style={{ marginTop: 12 }}>
        <a href="/upload">← Upload another</a>
      </div>

      {error && (
        <pre style={{ marginTop: 16, color: "crimson", whiteSpace: "pre-wrap" }}>
          {error}
        </pre>
      )}

      <div style={{ marginTop: 16, display: "grid", gap: 12 }}>
        {rows.map((r) => (
          <div
            key={r.id}
            style={{ border: "1px solid #ddd", borderRadius: 12, padding: 12 }}
          >
            <div style={{ display: "flex", gap: 12, alignItems: "center" }}>
              <img
                src={r.image_url}
                alt={r.identified_name ?? "Tree"}
                style={{ width: 96, height: 96, objectFit: "cover", borderRadius: 10 }}
              />
              <div>
                <div style={{ fontWeight: 700 }}>
                  {r.identified_name ?? "Unknown"}
                </div>
                <div style={{ opacity: 0.8 }}>
                  Confidence: {r.confidence ?? "n/a"}
                </div>
                <div style={{ opacity: 0.6, fontSize: 12 }}>
                  {new Date(r.created_at).toLocaleString()}
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>
    </main>
  );
}