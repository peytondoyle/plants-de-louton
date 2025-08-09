import { useEffect, useState } from "react";
import { supabase } from "../lib/supabaseClient";
import type { Pin } from "../types/types";

type Draft = {
  id?: string;
  bed_id: string;
  x: number;
  y: number;
  name: string;
  notes: string | null;
};

export default function PinEditorDrawer({
  open,
  onClose,
  bedId,
  initial, // undefined=create, Pin=edit, or {x,y} for new at position
  onSaved,
  onDeleted,
}: {
  open: boolean;
  onClose: () => void;
  bedId: string;
  initial?: Pin | { x: number; y: number };
  onSaved: (pin: Pin) => void;
  onDeleted: (id: string) => void;
}) {
  const [draft, setDraft] = useState<Draft | null>(null);
  const isEdit = !!(draft && draft.id);

  useEffect(() => {
    if (!open) return;
    if (!initial) { setDraft(null); return; }
    if ("id" in (initial as any)) {
      const p = initial as Pin;
      setDraft({ id: p.id, bed_id: p.bed_id, x: p.x, y: p.y, name: p.name, notes: p.notes ?? null });
    } else {
      const pos = initial as { x: number; y: number };
      setDraft({ bed_id: bedId, x: pos.x, y: pos.y, name: "", notes: null });
    }
  }, [open, initial, bedId]);

  async function save() {
    if (!draft) return;
    if (draft.id) {
      const { data, error } = await supabase
        .from("pins")
        .update({ name: draft.name, notes: draft.notes, x: draft.x, y: draft.y, updated_at: new Date().toISOString() })
        .eq("id", draft.id)
        .select("*")
        .single();
      if (error) return alert(error.message);
      onSaved(data as Pin);
      onClose();
    } else {
      const { data, error } = await supabase
        .from("pins")
        .insert({ bed_id: draft.bed_id, x: draft.x, y: draft.y, name: draft.name, notes: draft.notes })
        .select("*")
        .single();
      if (error) return alert(error.message);
      onSaved(data as Pin);
      onClose();
    }
  }

  async function del() {
    if (!draft?.id) return;
    if (!confirm("Delete this pin?")) return;
    const { error } = await supabase.from("pins").delete().eq("id", draft.id);
    if (error) return alert(error.message);
    onDeleted(draft.id);
    onClose();
  }

  return (
    <div className={`drawer ${open ? "open" : ""}`} onClick={onClose}>
      <div className="drawer-panel" onClick={(e) => e.stopPropagation()}>
        <div className="drawer-header">
          <div className="title">{isEdit ? "Edit pin" : "Add pin"}</div>
          <button className="btn ghost" onClick={onClose}>Close</button>
        </div>

        <div className="drawer-body">
          <label className="field">
            <span>Name</span>
            <input value={draft?.name ?? ""} onChange={(e) => draft && setDraft({ ...draft, name: e.target.value })} />
          </label>
          <label className="field">
            <span>Notes</span>
            <textarea rows={3} value={draft?.notes ?? ""} onChange={(e) => draft && setDraft({ ...draft, notes: e.target.value })}/>
          </label>
        </div>

        <div className="drawer-actions">
          {isEdit && <button className="btn danger" onClick={del}>Delete</button>}
          <div style={{ flex: 1 }} />
          <button className="btn primary" onClick={save} disabled={!draft?.name.trim()}>Save</button>
        </div>
      </div>
    </div>
  );
}