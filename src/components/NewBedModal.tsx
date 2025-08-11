import { useRef, useState } from "react";
import { supabase } from "../lib/supabaseClient";
import type { Bed, BedImage } from "../types/types";
import { v4 as uuidv4 } from "uuid";

const BUCKET = "plant-images";

export default function NewBedModal({
  section,
  onClose,
  onCreated,
}: {
  section: string;
  onClose: () => void;
  onCreated: (args: { bed: Bed; image: BedImage | null; publicUrl: string }) => void;
}) {
  const [bedName, setBedName] = useState("");
  const [file, setFile] = useState<File | null>(null);
  const [busy, setBusy] = useState(false);
  const [dragActive, setDragActive] = useState(false);
  const [imagePreview, setImagePreview] = useState<string | null>(null);
  const inputRef = useRef<HTMLInputElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const humanSection = section.replace(/-/g, " ").replace(/\b\w/g, l => l.toUpperCase());

  async function getOrCreateBed(name: string): Promise<Bed> {
    const { data: existing } = await supabase
      .from("beds").select("*").eq("section", section).eq("name", name).maybeSingle();
    if (existing) return existing as Bed;

    const { data, error } = await supabase.from("beds").insert({ section, name }).select("*").single();
    if (error || !data) throw error ?? new Error("Failed to create bed");
    return data as Bed;
  }

  function slug(s: string) { return s.toLowerCase().trim().replace(/[^\w-]+/g, "-").replace(/-+/g, "-"); }
  function ext(f: File) { const n = f.name; const i = n.lastIndexOf("."); return i >= 0 ? n.slice(i + 1) : "jpg"; }

  const handleFileSelect = (selectedFile: File | null) => {
    setFile(selectedFile);
    if (selectedFile) {
      const reader = new FileReader();
      reader.onload = (e) => setImagePreview(e.target?.result as string);
      reader.readAsDataURL(selectedFile);
    } else {
      setImagePreview(null);
    }
  };

  const handleDrag = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    if (e.type === "dragenter" || e.type === "dragover") {
      setDragActive(true);
    } else if (e.type === "dragleave") {
      setDragActive(false);
    }
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setDragActive(false);
    
    if (e.dataTransfer.files && e.dataTransfer.files[0]) {
      const droppedFile = e.dataTransfer.files[0];
      if (droppedFile.type.startsWith('image/')) {
        handleFileSelect(droppedFile);
      }
    }
  };

  const create = async () => {
    if (!bedName.trim()) return;
    setBusy(true);
    try {
      const bed = await getOrCreateBed(bedName.trim());
      let image: BedImage | null = null;
      let publicUrl = "";

      if (file) {
        const path = `${slug(section)}/${slug(bedName)}/${uuidv4()}.${ext(file)}`;
        const { error: upErr } = await supabase.storage.from(BUCKET).upload(path, file, {
          cacheControl: "3600",
          upsert: false,
          contentType: file.type || "image/jpeg",
        });
        if (upErr) throw upErr;

        const { data, error } = await supabase
          .from("bed_images").insert({ bed_id: bed.id, image_path: path }).select("*").single();
        if (error || !data) throw error ?? new Error("Failed to save image");
        image = data as BedImage;

        publicUrl = supabase.storage.from(BUCKET).getPublicUrl(path).data.publicUrl;
      }

      onCreated({ bed, image, publicUrl });
      onClose();
    } catch (e: unknown) {
      const errorMessage = e instanceof Error ? e.message : String(e);
      alert(errorMessage);
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="modal-backdrop" onClick={onClose}>
      <div className="modal modal--large" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <h2 className="modal-title">Create New Bed</h2>
          <button className="modal-close" onClick={onClose} aria-label="Close">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M18 6L6 18M6 6l12 12"/>
            </svg>
          </button>
        </div>

        <div className="modal-body">
          <div className="form-section">
            <label className="form-label">
              <span className="form-label-text">Section</span>
              <div className="form-section-badge">{humanSection}</div>
            </label>
          </div>

          <div className="form-section">
            <label className="form-label">
              <span className="form-label-text">Bed Name</span>
              <input
                ref={inputRef}
                type="text"
                className="form-input"
                placeholder="e.g., Front Garden, Herb Corner, Rose Bed"
                value={bedName}
                onChange={(e) => setBedName(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && create()}
                autoFocus
              />
            </label>
          </div>

          <div className="form-section">
            <label className="form-label">
              <span className="form-label-text">Bed Image (Optional)</span>
              <div className="form-hint">Upload an image to get started with pinning plants</div>
            </label>
            
            <div
              className={`image-upload-area ${dragActive ? 'drag-active' : ''} ${imagePreview ? 'has-preview' : ''}`}
              onDragEnter={handleDrag}
              onDragLeave={handleDrag}
              onDragOver={handleDrag}
              onDrop={handleDrop}
            >
              {imagePreview ? (
                <div className="image-preview">
                  <img src={imagePreview} alt="Preview" />
                  <button 
                    className="image-preview-remove"
                    onClick={() => handleFileSelect(null)}
                    type="button"
                  >
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                      <path d="M18 6L6 18M6 6l12 12"/>
                    </svg>
                  </button>
                </div>
              ) : (
                <>
                  <div className="image-upload-icon">
                    <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
                      <path d="M21 19V5a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2z"/>
                      <path d="M8.5 10a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3z"/>
                      <path d="m21 15-3.086-3.086a2 2 0 0 0-2.828 0L6 21"/>
                    </svg>
                  </div>
                  <div className="image-upload-text">
                    <span className="image-upload-primary">Drop an image here</span>
                    <span className="image-upload-secondary">or click to browse</span>
                  </div>
                  <input
                    ref={fileInputRef}
                    type="file"
                    accept="image/*"
                    className="image-upload-input"
                    onChange={(e) => handleFileSelect(e.target.files?.[0] ?? null)}
                  />
                </>
              )}
            </div>
          </div>
        </div>

        <div className="modal-actions">
          <button 
            className="ui-btn ui-btn--secondary" 
            onClick={onClose} 
            disabled={busy}
            type="button"
          >
            Cancel
          </button>
          <button 
            className="ui-btn ui-btn--primary" 
            disabled={!bedName.trim() || busy} 
            onClick={create}
            type="button"
          >
            {busy ? (
              <>
                <span className="spinner spinner--sm"></span>
                Creating Bed...
              </>
            ) : (
              'Create Bed'
            )}
          </button>
        </div>
      </div>
    </div>
  );
}