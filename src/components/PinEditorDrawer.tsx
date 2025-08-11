import React, { useEffect, useMemo, useRef, useState } from "react";
import { supabase } from "../lib/supabaseClient";
import type { Pin } from "../types/types";
import { uploadPinMedia, getPinMedia } from "../lib/pinMedia";

type Draft =
  | (Pin & { isEdit?: true })
  | ({ id?: undefined; bed_id: string; image_id: string | null; x: number; y: number; name?: string; notes?: string; });

// Type guard functions
function isPin(draft: Draft): draft is Pin {
  return 'id' in draft && draft.id !== undefined;
}

function isNewPin(draft: Draft): draft is { bed_id: string; image_id: string | null; x: number; y: number; name?: string; notes?: string; } {
  return !('id' in draft) || draft.id === undefined;
}

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
  onOpenPinGallery?: (args: { pinId: string }) => void;
};

export default function PinEditorDrawer({
  open,
  onClose,
  bedId,
  imageId,
  initial,
  onSaved,
  onDeleted,
  onOpenPinGallery,
}: Props) {
  const [draft, setDraft] = useState<Draft | null>(null);
  const [uploadingFeatured, setUploadingFeatured] = useState(false);
  const [featuredUrl, setFeaturedUrl] = useState<string | null>(null);
  const featuredInputRef = useRef<HTMLInputElement | null>(null);

  // Prime the draft whenever the drawer opens
  useEffect(() => {
    if (!open) return;
    if (!initial) {
      setDraft(null);
      return;
    }

    if (isPin(initial)) {
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

  // Load a small featured preview from pin_media (first photo)
  useEffect(() => {
    let cancel = false;
    (async () => {
      if (!open || !draft || !isPin(draft)) return;
      try {
        const media = await getPinMedia(draft.id);
        if (!cancel) setFeaturedUrl(media[0]?.url ?? null);
      } catch {
        if (!cancel) setFeaturedUrl(null);
      }
    })();
    return () => { cancel = true; };
  }, [open, draft]);


  const baseline = useMemo(() => {
    if (!initial || !isPin(initial)) return null;
    const p = initial;
    return { name: p.name ?? "", notes: p.notes ?? "" };
  }, [initial]);

  const isDirty = useMemo(() => {
    if (!draft) return false;
    if (!isPin(draft)) return true; // new pin being created elsewhere
    if (!baseline) return false;
    return (draft.name ?? "") !== baseline.name || (draft.notes ?? "") !== baseline.notes;
  }, [draft, baseline]);

  const [saveStatus, setSaveStatus] = useState<null | { type: 'success' | 'error'; message: string }>(null);

  async function save() {
    if (!draft) return;

    // UPDATE
    if (isPin(draft)) {
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

      if (error) {
        console.error('Failed to update pin:', error);
        setSaveStatus({ type: 'error', message: `Failed to save: ${error.message}` });
        return;
      }
      onSaved(data as Pin);
      setSaveStatus({ type: 'success', message: 'Saved' });
      setTimeout(() => setSaveStatus(null), 1200);
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

    if (error) {
      console.error('Failed to create pin:', error);
      setSaveStatus({ type: 'error', message: `Failed to create: ${error.message}` });
      return;
    }
    onSaved(data as Pin);
    setSaveStatus({ type: 'success', message: 'Saved' });
    setTimeout(() => setSaveStatus(null), 1200);
    onClose();
  }

  async function remove() {
    if (!draft || !isPin(draft)) return;
    const id = draft.id;
    const { error } = await supabase.from("pins").delete().eq("id", id);
    if (error) {
      console.error('Failed to delete pin:', error);
      setSaveStatus({ type: 'error', message: `Failed to delete: ${error.message}` });
      return;
    }
    onDeleted(id);
    onClose();
  }

  // Don't render if draft is not properly initialized
  if (!draft) {
    return null;
  }

  return (
    <div className={`drawer ${open ? "open" : ""}`} aria-hidden={!open} onClick={onClose}>
      <div className="drawer-panel" role="dialog" aria-modal="true" onClick={(e) => e.stopPropagation()}>
        <div className="drawer-header">
          <div className="drag-handle" aria-hidden="true" />
          <div className="title">{isPin(draft) ? "Edit pin" : "Add pin"}</div>
          <div style={{ marginLeft: "auto" }}>
            <button className="pill" onClick={onClose}>Close</button>
          </div>
        </div>

        <div className="drawer-body">
          {isPin(draft) ? (
            <div className="field">
              <span>Featured image</span>
              <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
                <div style={{ width: 48, height: 48, borderRadius: 8, overflow: 'hidden', background: '#f3f4f6', border: '1px solid #e5e7eb' }}>
                  {featuredUrl ? (<img src={featuredUrl} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }} />) : null}
                </div>
                <button
                  className="pill"
                  type="button"
                  onClick={() => featuredInputRef.current?.click()}
                  disabled={uploadingFeatured}
                >{uploadingFeatured ? 'Uploading…' : 'Change photo'}</button>
                <input
                  ref={featuredInputRef}
                  type="file"
                  accept="image/*"
                  style={{ display: 'none' }}
                  onChange={async (e) => {
                    const file = e.target.files?.[0];
                    if (!file) return;
                    try {
                      setUploadingFeatured(true);
                      await uploadPinMedia(draft.id, file, { imageId: imageId ?? undefined });
                      // refresh preview to the latest uploaded
                      const media = await getPinMedia(draft.id);
                      setFeaturedUrl(media[0]?.url ?? null);
                    } catch (err) {
                      console.error('Failed to upload media:', err);
                      setSaveStatus({ type: 'error', message: `Upload failed: ${err instanceof Error ? err.message : 'Unknown error'}` });
                    } finally {
                      setUploadingFeatured(false);
                      e.currentTarget.value = '';
                    }
                  }}
                />
              </div>
            </div>
          ) : null}
          <div className="field">
            <span>Name</span>
            <input
              value={draft?.name ?? ""}
              onChange={(e) => setDraft((d) => (d ? { ...d, name: e.target.value } : d))}
              placeholder="e.g., Honeysuckle"
            />
          </div>

          {isPin(draft) ? (
            <div>
              <button
                type="button"
                className="pill"
                onClick={(e) => {
                  e.preventDefault();
                  e.stopPropagation();
                  onClose();
                  setTimeout(() => onOpenPinGallery?.({ pinId: draft.id }), 0);
                }}
              >
                Manage photos
              </button>
            </div>
          ) : null}

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
          {isPin(draft) ? (
            <button className="btn danger" onClick={remove}>Delete</button>
          ) : null}
          <div style={{ marginLeft: "auto" }} />
          <button className="pill" onClick={save} disabled={!isDirty}>Save</button>
        </div>

        {saveStatus ? (
          <div style={{ position: 'fixed', right: 20, bottom: 20, background: '#111827', color: '#fff', padding: '8px 12px', borderRadius: 8, boxShadow: '0 8px 20px rgba(0,0,0,0.3)' }}>{saveStatus.message}</div>
        ) : null}
      </div>
    </div>
  );
}