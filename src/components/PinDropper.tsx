import React, { useEffect, useMemo, useRef, useState } from "react";
import { supabase } from "../lib/supabaseClient";
import PlantPin from "./PlantPin";
import type { Pin } from "../types/types";

type Props = {
  bedId: string;
  imageUrl: string;
  section?: string;
  bedName?: string;
};

type Draft =
  | null
  | {
      id?: string;
      bed_id: string;
      x: number; // 0..1
      y: number; // 0..1
      name: string;
      notes: string | null;
      mode: "create" | "edit";
    };

export default function PinDropper({ bedId, imageUrl, section, bedName }: Props) {
  const [pins, setPins] = useState<Pin[]>([]);
  const [loading, setLoading] = useState(true);
  const [draft, setDraft] = useState<Draft>(null);

  const imgRef = useRef<HTMLImageElement | null>(null);

  // Load existing pins
  useEffect(() => {
    let cancel = false;
    async function run() {
      setLoading(true);
      const { data, error } = await supabase
        .from("pins")
        .select("*")
        .eq("bed_id", bedId)
        .order("created_at", { ascending: true });
      if (!cancel) {
        if (error) {
          alert(error.message);
        } else {
          setPins((data ?? []) as Pin[]);
        }
        setLoading(false);
      }
    }
    void run();
    return () => {
      cancel = true;
    };
  }, [bedId]);

  const canInteract = useMemo(() => Boolean(imageUrl && bedId), [imageUrl, bedId]);

  const handleImageClick = (e: React.MouseEvent) => {
    if (!canInteract || !imgRef.current) return;
    const rect = imgRef.current.getBoundingClientRect();
    const x = (e.clientX - rect.left) / rect.width;
    const y = (e.clientY - rect.top) / rect.height;

    setDraft({
      bed_id: bedId,
      x: clamp01(x),
      y: clamp01(y),
      name: "",
      notes: null,
      mode: "create",
    });
  };

  const editPin = (pin: Pin) => {
    setDraft({
      id: pin.id,
      bed_id: pin.bed_id,
      x: pin.x,
      y: pin.y,
      name: pin.name,
      notes: pin.notes,
      mode: "edit",
    });
  };

  const saveDraft = async () => {
    if (!draft) return;
    const payload: Partial<Pin> & { bed_id: string; x: number; y: number; name: string; notes: string | null } = {
      bed_id: draft.bed_id,
      x: draft.x,
      y: draft.y,
      name: draft.name,
      notes: draft.notes ?? null,
    };

    let saved: Pin | null = null;

    if (draft.id) {
      // update
      const { data, error } = await supabase
        .from("pins")
        .update({ ...payload, updated_at: new Date().toISOString() })
        .eq("id", draft.id)
        .select("*")
        .single();
      if (error) return alert(error.message);
      saved = data as Pin;
      setPins((prev) => prev.map((p) => (p.id === saved!.id ? saved! : p)));
    } else {
      // insert
      const { data, error } = await supabase
        .from("pins")
        .insert(payload)
        .select("*")
        .single();
      if (error) return alert(error.message);
      saved = data as Pin;
      setPins((prev) => [...prev, saved!]);
    }

    setDraft(null);
  };

  const deleteCurrent = async () => {
    if (!draft?.id) return;
    if (!confirm("Delete this pin?")) return;
    const { error } = await supabase.from("pins").delete().eq("id", draft.id);
    if (error) return alert(error.message);
    setPins((prev) => prev.filter((p) => p.id !== draft.id));
    setDraft(null);
  };

  const pinEls = useMemo(
    () => pins.map((p) => <PlantPin key={p.id} pin={p} onClick={editPin} />),
    [pins]
  );

  return (
    <div className="pinboard-wrap">
      <header className="pinboard-toolbar">
        <div className="row">
          <div className="label">
            Section
            <input className="text" value={section ?? ""} readOnly />
          </div>
          <div className="label">
            Bed
            <input className="text" value={bedName ?? ""} readOnly />
          </div>
        </div>
        <p className="hint">Click the image to drop a pin. Click a pin to edit or delete.</p>
      </header>

    <main
    className={`pinboard ${imageUrl ? "ready" : "empty"}`}
    onClick={imageUrl ? handleImageClick : undefined}
    >
    {!imageUrl ? (
        <div className="empty-state"><p>Upload an image to begin pinning.</p></div>
    ) : (
        <div className="pinboard-stage">
        <div className="image-shell">
            <img ref={imgRef} src={imageUrl} alt={`${section ?? ""} — ${bedName ?? ""}`} />
            <div className="pins-layer">{pinEls}</div>
        </div>
        </div>
    )}
    </main>

      {draft && (
        <div className="modal-backdrop" onClick={() => setDraft(null)}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <h2>{draft.mode === "create" ? "Add Plant" : "Edit Plant"}</h2>

            <div className="form-row">
              <label>
                Name
                <input
                  className="text"
                  value={draft.name}
                  onChange={(e) => setDraft({ ...draft, name: e.target.value })}
                  placeholder="e.g., Sedum (S. sieboldii)"
                />
              </label>
            </div>

            <div className="form-row">
              <label>
                Notes
                <textarea
                  className="text"
                  rows={3}
                  value={draft.notes ?? ""}
                  onChange={(e) => setDraft({ ...draft, notes: e.target.value })}
                  placeholder="Optional notes"
                />
              </label>
            </div>

            <div className="modal-actions">
              {draft.mode === "edit" && (
                <button className="btn danger" onClick={deleteCurrent}>Delete</button>
              )}
              <div style={{ flex: 1 }} />
              <button className="btn ghost" onClick={() => setDraft(null)}>Cancel</button>
              <button
                className="btn primary"
                onClick={saveDraft}
                disabled={!draft.name.trim()}
              >
                Save
              </button>
            </div>
          </div>
        </div>
      )}

      {loading && (
        <div className="modal-backdrop"><div className="modal"><p>Loading…</p></div></div>
      )}
    </div>
  );
}

function clamp01(n: number) {
  return Math.max(0, Math.min(1, n));
}