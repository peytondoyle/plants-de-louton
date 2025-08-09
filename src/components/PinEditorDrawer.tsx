import React, { useEffect, useState } from "react";
import { supabase } from "../lib/supabaseClient";
import type { Pin } from "../types/types";

type Draft =
  | (Pin & { isEdit?: true })
  | ({ id?: undefined; bed_id: string; image_id: string | null; x: number; y: number; name?: string; notes?: string; });

type Props = {
  open: boolean;
  onClose: () => void;

  bedId: string;
  /** Associate new pins with a specific bed image (or null if “unscoped”). */
  imageId?: string;

  /** Existing pin to edit OR a position to create at. */
  initial?: Pin | { x: number; y: number };

  onSaved: (pin: Pin) => void;
  onDeleted: (id: string) => void;
};

export default function PinEditorDrawer({
  open,
  onClose,
  bedId,
  imageId,
  initial,
  onSaved,
  onDeleted,
}: Props) {
  const [draft, setDraft] = useState<Draft | null>(null);

  // Prime the draft whenever the drawer opens
  useEffect(() => {
    if (!open) return;
    if (!initial) {
      setDraft(null);
      return;
    }

    if ("id" in initial) {
      setDraft({ ...initial, isEdit: true });
    } else {
      setDraft({
        bed_id: bedId,
        image_id: imageId ?? null,
        x: initial.x,
        y: initial.y,
        name: "",
        notes: "",
      });
    }
  }, [open, initial, bedId, imageId]);

  async function save() {
    if (!draft) return;

    // UPDATE
    if ("id" in draft && draft.id) {
      const { data, error } = await supabase
        .from("pins")
        .update({
          name: draft.name ?? null,
          notes: draft.notes ?? null,
          x: draft.x,
          y: draft.y,
          updated_at: new Date().toISOString(),
        })
        .eq("id", draft.id)
        .select("*")
        .single();

      if (error) return alert(error.message);
      onSaved(data as Pin);
      onClose();
      return;
    }

    // INSERT
    const { data, error } = await supabase
      .from("pins")
      .insert({
        bed_id: draft.bed_id,
        image_id: draft.image_id ?? null,
        x: draft.x,
        y: draft.y,
        name: draft.name ?? null,
        notes: draft.notes ?? null,
      })
      .select("*")
      .single();

    if (error) return alert(error.message);
    onSaved(data as Pin);
    onClose();
  }

  async function remove() {
    if (!draft || !("id" in draft) || !draft.id) return;
    const id = draft.id;
    const { error } = await supabase.from("pins").delete().eq("id", id);
    if (error) return alert(error.message);
    onDeleted(id);
    onClose();
  }

  return (
    <div className={`drawer ${open ? "open" : ""}`} aria-hidden={!open}>
      <div className="drawer-panel" role="dialog" aria-modal="true">
        <div className="drawer-header">
          <div className="title">{("id" in (draft ?? {})) ? "Edit pin" : "Add pin"}</div>
          <div style={{ marginLeft: "auto" }}>
            <button className="pill" onClick={onClose}>Close</button>
          </div>
        </div>

        <div className="drawer-body">
          <div className="field">
            <span>Name</span>
            <input
              value={draft?.name ?? ""}
              onChange={(e) => setDraft((d) => (d ? { ...d, name: e.target.value } : d))}
              placeholder="e.g., Cosmos"
            />
          </div>

          <div className="field">
            <span>Notes</span>
            <textarea
              rows={6}
              value={draft?.notes ?? ""}
              onChange={(e) => setDraft((d) => (d ? { ...d, notes: e.target.value } : d))}
              placeholder="Any notes…"
            />
          </div>
        </div>

        <div className="drawer-actions">
          {("id" in (draft ?? {})) && draft?.id ? (
            <button className="btn danger" onClick={remove}>Delete</button>
          ) : null}
          <div style={{ marginLeft: "auto" }} />
          <button className="pill" onClick={save}>Save</button>
        </div>
      </div>
    </div>
  );
}