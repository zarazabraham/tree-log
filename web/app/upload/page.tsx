"use client";

import { useRef, useState } from "react";
import { supabase } from "../../lib/supabaseClient";

async function toJpeg(file: File): Promise<File> {
    // If already jpeg/jpg, keep it (PlantNet accepts jpeg/png)
    if (file.type === "image/jpeg" || file.type === "image/jpg") return file;

    const img = document.createElement("img");
    const url = URL.createObjectURL(file);

    await new Promise<void>((resolve, reject) => {
        img.onload = () => resolve();
        img.onerror = () => reject(new Error("Could not read image for conversion"));
        img.src = url;
    });

    const canvas = document.createElement("canvas");
    canvas.width = img.naturalWidth;
    canvas.height = img.naturalHeight;

    const ctx = canvas.getContext("2d");
    if (!ctx) throw new Error("Canvas not supported");

    ctx.drawImage(img, 0, 0);

    const blob: Blob = await new Promise((resolve, reject) => {
        canvas.toBlob(
            (b) => (b ? resolve(b) : reject(new Error("JPEG conversion failed"))),
            "image/jpeg",
            0.9
        );
    });

    URL.revokeObjectURL(url);

    return new File([blob], "tree.jpg", { type: "image/jpeg" });
}

export default function UploadPage() {
    const fileInputRef = useRef<HTMLInputElement | null>(null);
    const [file, setFile] = useState<File | null>(null);
    const [fileName, setFileName] = useState<string | null>(null);
    const [busy, setBusy] = useState(false);
    const [publicUrl, setPublicUrl] = useState<string | null>(null);
    const [error, setError] = useState<string | null>(null);
    const [identifyResult, setIdentifyResult] = useState<any>(null);

    async function uploadToSupabase() {
        setError(null);
        setPublicUrl(null);
        setIdentifyResult(null);

        if (!file) {
            setError("Please choose a photo first.");
            return;
        }

        setBusy(true);
        try {
            // Convert to JPEG if needed (PlantNet requires jpeg/png)
            const safeFile = await toJpeg(file);

            // toJpeg always returns JPEG, so extension is always jpg
            const path = `uploads/${crypto.randomUUID()}.jpg`;

            const { error: uploadErr } = await supabase.storage
                .from("tree-photos")
                .upload(path, safeFile, { upsert: false });

            if (uploadErr) throw uploadErr;

            // Get the public URL for the uploaded file (bucket must be public for MVP)
            const { data } = supabase.storage.from("tree-photos").getPublicUrl(path);

            const url = data.publicUrl;
            setPublicUrl(url);

            // 4) Call Edge Function to identify the tree
            const res = await fetch(
                `${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/identify-tree`,
                {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/json",
                        apikey: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
                        Authorization: `Bearer ${process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!}`,
                    },
                    body: JSON.stringify({ imageUrl: url }),
                }
            );

            const json = await res.json();
            if (!res.ok) {
                throw new Error(json?.error || "Identify failed");
            }

            // json contains: { id, created_at, name, confidence, ... }
            setIdentifyResult(json);
        } catch (err) {
            setError(err instanceof Error ? err.message : String(err));
        } finally {
            setBusy(false);
        }
    }

    return (
        <div className="min-h-screen flex items-center justify-center bg-zinc-50">
            <div className="w-full max-w-lg space-y-6 rounded-xl bg-white p-6 shadow">
                <h1 className="text-2xl font-bold">Tree Log — Upload</h1>

                {/* Hidden file input */}
                <input
                    type="file"
                    accept="image/*"
                    ref={fileInputRef}
                    style={{ display: "none" }}
                    onChange={(e) => {
                        const f = e.target.files?.[0] ?? null;
                        setFile(f);
                        setFileName(f?.name ?? null);
                    }}
                />

                {/* Choose photo button */}
                <button
                    className="w-full rounded-lg bg-black px-4 py-3 text-white"
                    onClick={() => fileInputRef.current?.click()}
                    disabled={busy}
                >
                    Choose a photo
                </button>

                {fileName && (
                    <p className="text-sm text-zinc-600">Selected: {fileName}</p>
                )}

                {/* Upload button */}
                <button
                    className="w-full rounded-lg border px-4 py-3"
                    onClick={uploadToSupabase}
                    disabled={!file || busy}
                >
                    {busy ? "Uploading..." : "Upload to Supabase"}
                </button>

                {error && (
                    <pre className="rounded bg-red-50 p-3 text-sm text-red-700 whitespace-pre-wrap">
                        {error}
                    </pre>
                )}

                {publicUrl && (
                    <div className="space-y-2 rounded bg-zinc-50 p-3">
                        <p className="text-sm font-medium">Public URL:</p>
                        <a className="break-all text-sm text-blue-600 underline" href={publicUrl} target="_blank" rel="noopener noreferrer">
                            {publicUrl}
                        </a>
                        <img src={publicUrl} alt="Uploaded preview" className="mt-2 w-full rounded-lg" />
                    </div>
                )}

                {identifyResult && (
                    <div className="space-y-2 rounded bg-green-50 p-4 border border-green-200">
                        <h2 className="text-lg font-semibold text-green-900">Tree Identified!</h2>
                        <div className="space-y-1">
                            <p className="text-sm">
                                <span className="font-medium">Name:</span> {identifyResult.name}
                            </p>
                            {identifyResult.confidence !== null && (
                                <p className="text-sm">
                                    <span className="font-medium">Confidence:</span>{" "}
                                    {(identifyResult.confidence * 100).toFixed(1)}%
                                </p>
                            )}
                            <p className="text-sm text-gray-600">
                                <span className="font-medium">ID:</span> {identifyResult.id}
                            </p>
                        </div>
                    </div>
                )}
            </div>
        </div>
    );
}