import { useMemo, useState } from "react";
import { supabase } from "../lib/supabaseClient";
import type { BedImage, Pin } from "../types/types";
import DeleteConfirmationModal from "./DeleteConfirmationModal";

type Props = {
  images: BedImage[];
  activePath?: string | null;
  onSelect: (img: BedImage, url: string) => void;
  onDelete?: (imageId: string) => void;
  onSetMain?: (imageId: string) => void;
  pins?: Pin[];
  bedId?: string;
};

export default function ImageHistory({ 
  images, 
  activePath = null, 
  onSelect, 
  onDelete,
  onSetMain,
  pins = [],
  bedId
}: Props) {
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [settingMainId, setSettingMainId] = useState<string | null>(null);
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [pendingDelete, setPendingDelete] = useState<{ id: string; path: string } | null>(null);

  // Precompute public URLs and pin counts once per images array
  const items = useMemo(() => {
    return images.map((img) => {
      const { data } = supabase.storage.from("plant-images").getPublicUrl(img.image_path);
      const imagePins = pins.filter(pin => pin.image_id === img.id);
      const pinCount = imagePins.length;
      
      return {
        img,
        url: data.publicUrl,
        ts: img.created_at ? new Date(img.created_at) : null,
        pinCount,
        isMain: img.image_path === activePath
      };
    });
  }, [images, pins, activePath]);

  if (!items.length) return null;

  const handleDelete = async (imageId: string, imagePath: string) => {
    if (!onDelete) return;
    
    setPendingDelete({ id: imageId, path: imagePath });
    setShowDeleteModal(true);
  };

  const confirmDelete = async () => {
    if (!pendingDelete || !onDelete) return;
    
    const { id: imageId, path: imagePath } = pendingDelete;
    setDeletingId(imageId);
    try {
      // Delete from storage first
      const { error: storageError } = await supabase.storage
        .from("plant-images")
        .remove([imagePath]);
      
      if (storageError) {
        console.error("Storage deletion error:", storageError);
        // Continue with database deletion even if storage fails
      }

      // Delete from database
      const { error: dbError } = await supabase
        .from("bed_images")
        .delete()
        .eq("id", imageId);

      if (dbError) {
        throw dbError;
      }

      onDelete(imageId);
    } catch (error: unknown) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      alert(`Failed to delete image: ${errorMessage}`);
    } finally {
      setDeletingId(null);
      setPendingDelete(null);
    }
  };

  const handleSetMain = async (imageId: string) => {
    if (!onSetMain) return;
    
    setSettingMainId(imageId);
    try {
      onSetMain(imageId);
    } finally {
      setSettingMainId(null);
    }
  };

  return (
    <>
      <div className="image-history" role="list" aria-label="Image history">
        {items.map(({ img, url, ts, pinCount, isMain }) => {
          const active = img.image_path === activePath;
          const title = ts
            ? ts.toLocaleDateString(undefined, { year: "numeric", month: "short", day: "numeric" })
            : img.image_path;

          return (
            <div key={img.id} className="hist-thumb-wrapper">
              <button
                type="button"
                role="listitem"
                className={`hist-thumb ${active ? "active" : ""}`}
                title={title}
                aria-current={active ? "true" : undefined}
                aria-pressed={active ? true : undefined}
                onClick={() => onSelect(img, url)}
              >
                <img
                  src={url}
                  alt=""
                  loading="lazy"
                  decoding="async"
                  draggable={false}
                />
                
                {/* Pin count indicator */}
                {pinCount > 0 && (
                  <div className="pin-count-badge" title={`${pinCount} pin${pinCount === 1 ? '' : 's'}`}>
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="currentColor">
                      <circle cx="12" cy="12" r="11" fill="currentColor" opacity="0.9"/>
                      <path d="M12 8.5a1.25 1.25 0 1 1 0-2.5 1.25 1.25 0 0 1 0 2.5Zm-1.1 2.7h2.2v6.3h-2.2z" fill="white"/>
                    </svg>
                    <span>{pinCount}</span>
                  </div>
                )}

                {/* Main image indicator */}
                {isMain && (
                  <div className="main-image-badge" title="Main image">
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="currentColor">
                      <path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z" fill="currentColor"/>
                    </svg>
                  </div>
                )}

                {/* Tiny date stripe overlay */}
                {ts && (
                  <div className="hist-meta">
                    {ts.toLocaleDateString()}
                  </div>
                )}
                
                {active && <span className="thumb-check" aria-hidden="true">✓</span>}
              </button>

              {/* Image management actions */}
              <div className="hist-actions">
                {!isMain && onSetMain && (
                  <button
                    type="button"
                    className="hist-action-btn hist-action-main"
                    onClick={() => handleSetMain(img.id)}
                    disabled={settingMainId === img.id}
                    title="Set as main image"
                    aria-label="Set as main image"
                  >
                    {settingMainId === img.id ? (
                      <svg className="spinner" width="12" height="12" viewBox="0 0 24 24">
                        <circle cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="2" fill="none" strokeDasharray="31.416" strokeDashoffset="31.416">
                          <animate attributeName="stroke-dasharray" dur="2s" values="0 31.416;15.708 15.708;0 31.416" repeatCount="indefinite"/>
                          <animate attributeName="stroke-dasharray" dur="2s" values="0;-15.708;-31.416" repeatCount="indefinite"/>
                        </circle>
                      </svg>
                    ) : (
                      <svg width="12" height="12" viewBox="0 0 24 24" fill="currentColor">
                        <path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z" fill="currentColor"/>
                      </svg>
                    )}
                  </button>
                )}
                
                {onDelete && (
                  <button
                    type="button"
                    className="hist-action-btn hist-action-delete"
                    onClick={() => handleDelete(img.id, img.image_path)}
                    disabled={deletingId === img.id}
                    title="Delete image"
                    aria-label="Delete image"
                  >
                    {deletingId === img.id ? (
                      <svg className="spinner" width="12" height="12" viewBox="0 0 24 24">
                        <circle cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="2" fill="none" strokeDasharray="31.416" strokeDashoffset="31.416">
                          <animate attributeName="stroke-dasharray" dur="2s" values="0 31.416;15.708 15.708;0 31.416" repeatCount="indefinite"/>
                          <animate attributeName="stroke-dasharray" dur="2s" values="0;-15.708;-31.416" repeatCount="indefinite"/>
                        </circle>
                      </svg>
                    ) : (
                      <svg width="12" height="12" viewBox="0 0 24 24" fill="currentColor">
                        <path d="M6 19c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V7H6v12zM19 4h-3.5l-1-1h-5l-1 1H5v2h14V4z" fill="currentColor"/>
                      </svg>
                    )}
                  </button>
                )}
              </div>
            </div>
          );
        })}
      </div>

      <DeleteConfirmationModal
        isOpen={showDeleteModal}
        onClose={() => {
          setShowDeleteModal(false);
          setPendingDelete(null);
        }}
        onConfirm={confirmDelete}
        title="Delete Image"
        message="Are you sure you want to delete this image? This action cannot be undone."
        confirmText="Delete"
        cancelText="Cancel"
      />
    </>
  );
}