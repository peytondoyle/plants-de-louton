import { useCallback, useEffect, useRef, useState, useLayoutEffect } from "react";
import { useParams } from "react-router-dom";
import { v4 as uuidv4 } from "uuid";

import { supabase } from "../lib/supabaseClient";
import { getBed } from "../lib/getBeds";
import { listImagesForBed } from "../lib/listImagesForBed";

import PinDropper from "../components/PinDropper";
import PinsPanel from "../components/PinsPanel";
import Sidebar from "../components/Sidebar";
import Filmstrip from "../components/Filmstrip";
import PinEditorDrawer from "../components/PinEditorDrawer";
import MainImageTooltip from "../components/MainImageTooltip";
import DeleteConfirmationModal from "../components/DeleteConfirmationModal";

import type { Bed, BedImage, Pin } from "../types/types";

const BUCKET = "plant-images";

export default function BedDetail() {
  const { slug = "", bedId = "" } = useParams();

  const [bed, setBed] = useState<Bed | null>(null);
  const [imageUrl, setImageUrl] = useState("");
  const [imagePath, setImagePath] = useState<string | null>(null);
  const [activeImageId, setActiveImageId] = useState<string | undefined>(undefined);
  const [mainImageId, setMainImageId] = useState<string | undefined>(undefined);

  const [images, setImages] = useState<BedImage[]>([]);
  const [pins, setPins] = useState<Pin[]>([]);

  const [drawerOpen, setDrawerOpen] = useState(false);
  const [draftInit, setDraftInit] = useState<Pin | { x: number; y: number } | undefined>(undefined);
  const [imgVer, setImgVer] = useState(0);
  const [ready, setReady] = useState(false);
  const [savingPins, setSavingPins] = useState(false);
  const [pinSaveStatus, setPinSaveStatus] = useState<{ type: 'success' | 'error'; message: string } | null>(null);
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [pendingDeleteId, setPendingDeleteId] = useState<string | null>(null);
  const [showFilmstrip, setShowFilmstrip] = useState(true);
  const [showImportPinsModal, setShowImportPinsModal] = useState(false);
  const [pendingImportTargetImageId, setPendingImportTargetImageId] = useState<string | null>(null);
  const [pendingImportPins, setPendingImportPins] = useState<Pin[]>([]);
  const uploadInputRef = useRef<HTMLInputElement | null>(null);

  const imageCardRef = useRef<HTMLDivElement | null>(null);
  const filmstripRef = useRef<HTMLDivElement | null>(null);
  const pinsCardRef = useRef<HTMLDivElement | null>(null);
  const [, setBoardHeightTick] = useState(0);
  const [pinsPanelHeight, setPinsPanelHeight] = useState<number | undefined>(undefined);
  const [isMobile, setIsMobile] = useState<boolean>(window.matchMedia('(max-width: 959px)').matches);
  const [promoteSelected, setPromoteSelected] = useState(false);
  const [allowCreate, setAllowCreate] = useState(false);

  const refresh = useCallback(async () => {
    setReady(false);
    const data = await getBed(bedId);
    setBed(data.bed);
    
    // Fallback preference (used only when DB has no main set)
    const storedImageId = localStorage.getItem(`bed-${bedId}-selected-image`);
    
    const hist = await listImagesForBed(bedId);
    setImages(hist);
    
    // Prefer DB main_image_id; else fall back to localStorage; else use server-provided image
    let selectedImage = data.image;
    if (data.bed?.main_image_id && hist.find(img => img.id === data.bed?.main_image_id)) {
      selectedImage = hist.find(img => img.id === data.bed?.main_image_id) || data.image;
    } else if (storedImageId && hist.find(img => img.id === storedImageId)) {
      selectedImage = hist.find(img => img.id === storedImageId) || data.image;
    }
    
    setImageUrl(selectedImage ? supabase.storage.from("plant-images").getPublicUrl(selectedImage.image_path).data.publicUrl : "");
    setImagePath(selectedImage?.image_path ?? null);
    setActiveImageId(selectedImage?.id);
    setMainImageId(data.bed?.main_image_id ?? undefined);
    setPins(data.pins);
    setReady(true);
  }, [bedId]);

  useEffect(() => {
    if (bedId) {
      void refresh();
    }
  }, [bedId, refresh]);

  // Keep Pins panel height in sync with image height when window resizes
  useEffect(() => {
    const onResize = () => setBoardHeightTick((v) => v + 1);
    window.addEventListener('resize', onResize);
    const id = setInterval(onResize, 500); // handle image load changes
    const mq = window.matchMedia('(max-width: 959px)');
    const mqHandler = (e: MediaQueryListEvent) => setIsMobile(e.matches);
    mq.addEventListener('change', mqHandler);
    return () => {
      window.removeEventListener('resize', onResize);
      clearInterval(id);
      mq.removeEventListener('change', mqHandler);
    };
  }, []);

  // Keep selection responsive: listen for pin-selected with latest pins
  useEffect(() => {
    const onPinSelected = (e: Event) => {
      const detail = (e as CustomEvent<{ id: string }>).detail;
      if (!detail?.id) return;
      const pin = pins.find((p) => p.id === detail.id);
      if (pin) {
        setDraftInit(pin);
        setPromoteSelected(true);
      }
    };
    window.addEventListener('pin-selected', onPinSelected as EventListener);
    return () => window.removeEventListener('pin-selected', onPinSelected as EventListener);
  }, [pins]);

  // Compute Pins panel height so Pins + Gallery total equals image height (desktop)
  useLayoutEffect(() => {
    const compute = () => {
      const imgRect = imageCardRef.current?.getBoundingClientRect();
      const galleryRect = filmstripRef.current?.getBoundingClientRect();
      const imageH = imgRect?.height ?? 0;
      const galleryH = galleryRect?.height ?? 0; // header-only when collapsed
      const sidebarEl = document.querySelector('.sidebar') as HTMLElement | null;
      const sidebarGap = sidebarEl ? parseInt(getComputedStyle(sidebarEl).gap || '10', 10) || 10 : 10;
      const pinsH = Math.max(0, imageH - (galleryH + sidebarGap));
      setPinsPanelHeight(pinsH || undefined);
    };
    compute();
    const ro = new ResizeObserver(compute);
    if (imageCardRef.current) ro.observe(imageCardRef.current);
    if (filmstripRef.current) ro.observe(filmstripRef.current);
    window.addEventListener('resize', compute);
    return () => { ro.disconnect(); window.removeEventListener('resize', compute); };
  }, [images.length, imageUrl, imgVer, showFilmstrip]);

  // Initialize filmstrip visibility from bed (persisted), defaulting to true on desktop and false on mobile if null
  useEffect(() => {
    const mq = window.matchMedia('(max-width: 768px)');
    const persisted = bed?.filmstrip_visible;
    if (persisted === true || persisted === false) {
      setShowFilmstrip(Boolean(persisted));
    } else {
      setShowFilmstrip(!mq.matches);
    }
  }, [bed]);



  const onChangeImage = async (file: File) => {
    if (!bed) return;
    // Preserve the current active image id for optional import
    const sourceImageId = activeImageId;
    const ext = (file.name.split(".").pop() || "jpg").toLowerCase();
    const path = `${bed.section}/${bed.name}/${uuidv4()}.${ext}`;

    const { error: upErr } = await supabase.storage
      .from(BUCKET)
      .upload(path, file, {
        cacheControl: "3600",
        upsert: false,
        contentType: file.type || "image/jpeg",
      });
    if (upErr) return alert(upErr.message);

    const { data, error } = await supabase
      .from("bed_images")
      .insert({ bed_id: bed.id, image_path: path })
      .select("*")
      .single();

    if (error) return alert(error.message);

    setImages((prev) => [data as BedImage, ...prev]);

    const { data: pub } = supabase.storage.from(BUCKET).getPublicUrl(path);
    setImageUrl(pub.publicUrl);
    setImagePath(path);
    setActiveImageId((data as BedImage).id);

    // Prompt to import pins from most recent (previous active) image
    if (sourceImageId) {
      const sourcePins = pins.filter(p => p.image_id === sourceImageId);
      if (sourcePins.length > 0) {
        setPendingImportTargetImageId((data as BedImage).id);
        setPendingImportPins(sourcePins);
        setShowImportPinsModal(true);
      }
    }
  };

  const handleDeleteImage = async (imageId: string) => {
    // Remove from local state
    setImages(prev => prev.filter(img => img.id !== imageId));
    
    // If this was the active image, switch to the next available one
    if (images.find(img => img.id === imageId)?.image_path === imagePath) {
      const remainingImages = images.filter(img => img.id !== imageId);
      if (remainingImages.length > 0) {
        const nextImage = remainingImages[0];
        const { data } = supabase.storage.from("plant-images").getPublicUrl(nextImage.image_path);
        setImageUrl(data.publicUrl);
        setImagePath(nextImage.image_path);
        setActiveImageId(nextImage.id);

        // Persist the new selection
        localStorage.setItem(`bed-${bedId}-selected-image`, nextImage.id);
      } else {
        // No images left
        setImageUrl("");
        setImagePath(null);
        setActiveImageId(undefined);

        // Clear persisted selection
        localStorage.removeItem(`bed-${bedId}-selected-image`);
      }
    }
    
    // Refresh pins to remove any pins that were associated with the deleted image
    await refresh();
  };

  const requestDeleteImage = (imageId: string) => {
    setPendingDeleteId(imageId);
    setShowDeleteModal(true);
  };

  const confirmDeleteImage = async () => {
    if (!pendingDeleteId) return;
    const image = images.find(i => i.id === pendingDeleteId);
    if (!image) {
      setShowDeleteModal(false);
      setPendingDeleteId(null);
      return;
    }

    try {
      // 1) Delete any pins tied to this image to satisfy potential FK constraints
      const { error: pinsErr } = await supabase
        .from("pins")
        .delete()
        .eq("image_id", pendingDeleteId);
      if (pinsErr) {
        console.error("Pin deletion error:", pinsErr);
        // Continue; pin deletion failure shouldn't block image deletion attempt
      }

      // 2) Delete from storage
      const { error: storageError } = await supabase.storage
        .from(BUCKET)
        .remove([image.image_path]);
      if (storageError) {
        console.error("Storage deletion error:", storageError);
        // Continue with database deletion even if storage fails
      }

      // 3) Delete from database
      const { error: dbError } = await supabase
        .from("bed_images")
        .delete()
        .eq("id", pendingDeleteId);
      if (dbError) throw dbError;

      // 4) If the deleted image was the main image, update bed's main_image_id
      let nextImageId: string | null = null;
      const remaining = images.filter(img => img.id !== pendingDeleteId);
      if (remaining.length > 0) nextImageId = remaining[0].id;
      if (bedId && bed?.main_image_id === pendingDeleteId) {
        const { error: bedErr } = await supabase.from("beds").update({ main_image_id: nextImageId }).eq("id", bedId);
        if (bedErr) console.error("Failed to update bed main image after delete:", bedErr);
        setBed(prev => (prev ? { ...prev, main_image_id: nextImageId } as Bed : prev));
        setMainImageId(nextImageId ?? undefined);
      }

      await handleDeleteImage(pendingDeleteId);
    } catch (err) {
      const msg = err instanceof Error ? err.message : (() => { try { return JSON.stringify(err); } catch { return String(err); } })();
      alert(`Failed to delete image: ${msg}`);
    } finally {
      setShowDeleteModal(false);
      setPendingDeleteId(null);
    }
  };

  const handleSetMainImage = async (imageId: string) => {
    const targetImage = images.find(img => img.id === imageId);
    if (!targetImage) return;

    const { data } = supabase.storage.from("plant-images").getPublicUrl(targetImage.image_path);
    setImageUrl(data.publicUrl);
    setImagePath(targetImage.image_path);
    setActiveImageId(targetImage.id);
    setMainImageId(targetImage.id); // Set this as the main image

    // Persist to Supabase for cross-device consistency
    if (bedId) {
      const { error } = await supabase.from("beds").update({ main_image_id: targetImage.id }).eq("id", bedId);
      if (error) {
        console.error("Failed to persist main image:", error);
      } else {
        setBed(prev => (prev ? { ...prev, main_image_id: targetImage.id } as Bed : prev));
      }
    }

    // Persist the selection so it's restored on load
    localStorage.setItem(`bed-${bedId}-selected-image`, targetImage.id);
  };

  const createAt = (pos: { x: number; y: number }) => {
    setDraftInit(pos);
    setDrawerOpen(true);
  };
  const editPin = (pin: Pin) => {
    setDraftInit(pin);
    setDrawerOpen(true);
  };

  /**
   * Saves pin position changes to Supabase immediately
   */
  const savePinPositions = async (updatedPins: Pin[]) => {
    try {
      // Find pins that have position changes
      const pinsToUpdate = updatedPins.filter(updatedPin => {
        const originalPin = pins.find(p => p.id === updatedPin.id);
        return originalPin && (
          Math.abs(originalPin.x - updatedPin.x) > 0.001 || 
          Math.abs(originalPin.y - updatedPin.y) > 0.001
        );
      });

      if (pinsToUpdate.length === 0) return;

      setSavingPins(true);
      setPinSaveStatus(null);

      // Update each pin position in Supabase
      for (const pin of pinsToUpdate) {
        const { error } = await supabase
          .from("pins")
          .update({
            x: pin.x,
            y: pin.y,
            updated_at: new Date().toISOString(),
          })
          .eq("id", pin.id);

        if (error) {
          console.error(`Failed to update pin ${pin.id}:`, error);
          throw new Error(`Failed to update pin: ${error.message}`);
        }
      }

      // Update local state with the new positions
      setPins(updatedPins);
      
      // Don't show success message for position saves
      // setPinSaveStatus({
      //   type: 'success',
      //   message: `Saved ${pinsToUpdate.length} pin position${pinsToUpdate.length > 1 ? 's' : ''}`
      // });

      // Clear success message after 3 seconds
      // setTimeout(() => setPinSaveStatus(null), 3000);
    } catch (error) {
      console.error("Failed to save pin positions:", error);
      setPinSaveStatus({
        type: 'error',
        message: error instanceof Error ? error.message : 'Failed to save pin positions'
      });

      // Clear error message after 5 seconds
      setTimeout(() => setPinSaveStatus(null), 5000);
    } finally {
      setSavingPins(false);
    }
  };

  return (
    // Single container so this aligns perfectly with the header brand
    <main
      className="app-root container"
      tabIndex={0}
      onClick={(e) => {
        const target = e.target as HTMLElement;
        // Ignore clicks originating inside the left image shell or within the pins panel card
        if (target.closest('.image-shell') || target.closest('.panel--images') || target.closest('.panel.panel--images') || target.closest('.pin-rows') || target.closest('.pin-row') || target.closest('.pin-edit')) {
          return;
        }
        setDraftInit(undefined);
      }}
    >
      {/* Page header */}
      <h1 className="page-title">{bed?.name ?? "Bed"}</h1>
      
      {/* Pin save status indicator - hidden for position saves */}
      {/* {savingPins && (
        <div style={{ 
          display: 'flex', 
          alignItems: 'center', 
          gap: '8px', 
          marginBottom: '16px',
          fontSize: '14px',
          color: '#6b7280'
        }}>
          <div style={{
            width: '16px',
            height: '16px',
            border: '2px solid #e5e7eb',
            borderTop: '2px solid #10b981',
            borderRadius: '50%',
            animation: 'spin 1s linear infinite'
          }} />
          Saving pin positions...
        </div>
      )} */}
      
      {pinSaveStatus && (
        <div style={{
          padding: '8px 12px',
          borderRadius: '8px',
          marginBottom: '16px',
          fontSize: '14px',
          backgroundColor: pinSaveStatus.type === 'success' ? '#ecfdf5' : '#fef2f2',
          color: pinSaveStatus.type === 'success' ? '#065f46' : '#991b1b',
          border: `1px solid ${pinSaveStatus.type === 'success' ? '#a7f3d0' : '#fecaca'}`
        }}>
          {pinSaveStatus.message}
        </div>
      )}

      {/* unified pill actions */}
      {/* <div className="page-toolbar">
        <Link to={`/section/${slug}`} className="ui-btn ui-btn--sm">
          <span style={{ display: "inline-flex", alignItems: "center", gap: 4 }}>
            <svg
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
              strokeWidth={2}
              stroke="currentColor"
              style={{ width: 14, height: 14 }}
              aria-hidden="true"
            >
              <path strokeLinecap="round" strokeLinejoin="round" d="M15.75 19.5 8.25 12l7.5-7.5" />
            </svg>
            Back yard
          </span>
        </Link>

        <label className="ui-btn ui-btn--sm" style={{ cursor: "pointer" }}>
          Change image
          <input
            type="file"
            accept="image/*"
            onChange={(e) => e.target.files?.[0] && onChangeImage(e.target.files[0])}
            style={{ display: "none" }}
          />
        </label>
      </div> */}

      {ready && (
      <div className="page-grid" style={{ alignItems: 'start' }}>
        <div className="left-col">
          {imageUrl ? (
            <>
              <div className="pinboard-stage">
              <div className="image-shell card" ref={imageCardRef}>
                <PinDropper
                  bedId={bedId}
                  imageUrl={`${imageUrl}?v=${imgVer}`}
                  imageId={activeImageId}
                  section={slug}
                  bedName={bed?.name ?? ""}
                  onCreateAt={createAt}
                  onEditPin={(pin) => {
                    setDraftInit(pin);
                    setDrawerOpen(true);
                  }}
                  onPinsChange={savePinPositions}
                  useExternalEditor
                  showInlineHint
                  pins={activeImageId ? pins.filter(pin => pin.image_id === activeImageId) : pins}
                  selectedPinId={draftInit && 'id' in (draftInit as any) ? (draftInit as Pin).id : undefined}
                  allowCreate={allowCreate}
                >
                  {images.length > 0 && (
                    <MainImageTooltip
                      timestamp={new Date(
                        images.find((i) => i.image_path === imagePath)?.created_at ?? Date.now()
                      ).toLocaleString()}
                    />
                  )}
                </PinDropper>
              </div>
            </div>

            {/* Gallery will render in sidebar under Pins */}
            
            </>
          ) : (
            <div className="panel-empty">This bed has no image yet. Use “Change image”.</div>
          )}
        </div>

        <Sidebar>
          <PinsPanel
            pins={activeImageId ? pins.filter(pin => pin.image_id === activeImageId) : pins}
            selectedPinId={draftInit && 'id' in (draftInit as any) ? (draftInit as Pin).id : undefined}
            fullHeight={isMobile ? undefined : pinsPanelHeight}
            cardRef={pinsCardRef}
            promoteSelected={promoteSelected}
            addMode={allowCreate}
            onToggleAddMode={() => setAllowCreate(v => !v)}
            onSelect={(pin) => {
              setDraftInit(pin || undefined);
              setPromoteSelected(false); // list-click selection shouldn't reorder
            }}
            onOpen={(pin) => {
              setDraftInit(pin);
              setDrawerOpen(true);
            }}
          />

          {/* Collapsible Gallery under Pins */}
          <div className="card panel panel--images" ref={filmstripRef}>
            <div className="panel-head">
              <div className="panel-title">Gallery</div>
              <div className="panel-actions" style={{ marginLeft: 'auto' }}>
                <button
                  type="button"
                  className="ui-btn ui-btn--sm ui-btn--ghost toggle-btn"
                  onClick={async () => {
                    const next = !showFilmstrip;
                    setShowFilmstrip(next);
                    if (bedId) {
                      const { data, error } = await supabase
                        .from('beds')
                        .update({ filmstrip_visible: next })
                        .eq('id', bedId)
                        .select('filmstrip_visible')
                        .single();
                      if (!error) setBed(prev => (prev ? { ...prev, filmstrip_visible: data?.filmstrip_visible ?? next } as Bed : prev));
                    }
                  }}
                  aria-expanded={showFilmstrip}
                  aria-controls="filmstrip-collapsible"
                >
                  {showFilmstrip ? 'Hide' : 'Show'}
                </button>
                <button
                  type="button"
                  className="ui-btn ui-btn--sm"
                  onClick={() => uploadInputRef.current?.click()}
                  aria-label="Upload image"
                >
                  Upload
                </button>
              </div>
            </div>
            <div id="filmstrip-collapsible" className={`filmstrip-collapsible ${showFilmstrip ? 'open' : 'closed'}`} style={{ display: 'grid' }}>
              {(() => {
                const items = images.map((img) => {
                  const { data } = supabase.storage.from("plant-images").getPublicUrl(img.image_path);
                  const exifIso = (img as any).exif_date as string | undefined;
                  const d = exifIso ? new Date(exifIso) : (img.created_at ? new Date(img.created_at) : null);
                  const label = d ? d.toLocaleDateString() : undefined;
                  return { id: img.id, url: data.publicUrl, label };
                });
                const activeId = images.find((i) => i.image_path === imagePath)?.id;
                return (
                  showFilmstrip ? (
                    <Filmstrip
                      items={items}
                      activeId={activeId}
                      mainImageId={mainImageId}
                      onSelect={(id) => {
                        const found = images.find((i) => i.id === id);
                        if (!found) return;
                        const { data } = supabase.storage.from("plant-images").getPublicUrl(found.image_path);
                        setActiveImageId(found.id);
                        setImagePath(found.image_path);
                        setImageUrl(data.publicUrl);
                        localStorage.setItem(`bed-${bedId}-selected-image`, found.id);
                      }}
                      onDelete={requestDeleteImage}
                      onSetMain={handleSetMainImage}
                      pins={pins}
                      bedId={bedId}
                    />
                  ) : null
                );
              })()}
            </div>
            <input
              ref={uploadInputRef}
              type="file"
              accept="image/*"
              style={{ display: 'none' }}
              onChange={(e) => {
                const f = e.target.files?.[0];
                if (f) void onChangeImage(f);
                e.currentTarget.value = "";
              }}
            />
          </div>


        </Sidebar>
      </div>
      )}

      <PinEditorDrawer
        open={drawerOpen}
        onClose={() => setDrawerOpen(false)}
        bedId={bedId}
        imageId={activeImageId}
        initial={draftInit}
        onSaved={(pin) => {
          setPins((prev) => {
            const i = prev.findIndex((p) => p.id === pin.id);
            if (i >= 0) {
              const c = prev.slice();
              c[i] = pin;
              return c;
            }
            return [pin, ...prev];
          });
          setImgVer((v) => v + 1);
        }}
        onDeleted={(id) => {
          setPins((prev) => prev.filter((p) => p.id !== id));
          setImgVer((v) => v + 1);
        }}
      />

      <DeleteConfirmationModal
        isOpen={showDeleteModal}
        onClose={() => {
          setShowDeleteModal(false);
          setPendingDeleteId(null);
        }}
        onConfirm={confirmDeleteImage}
        title="Delete Image"
        message="Are you sure you want to delete this image? This action cannot be undone."
        confirmText="Delete"
        cancelText="Cancel"
      />

      <DeleteConfirmationModal
        isOpen={showImportPinsModal}
        onClose={() => {
          setShowImportPinsModal(false);
          setPendingImportTargetImageId(null);
          setPendingImportPins([]);
        }}
        onConfirm={async () => {
          if (!pendingImportTargetImageId || !bed) return;
          try {
            const rows = pendingImportPins.map(p => ({
              bed_id: bed.id,
              image_id: pendingImportTargetImageId,
              name: p.name ?? null,
              notes: p.notes ?? null,
              x: p.x,
              y: p.y,
            }));
            if (rows.length > 0) {
              const { data, error } = await supabase.from('pins').insert(rows).select('*');
              if (error) throw error;
              const inserted = (data ?? []) as Pin[];
              setPins(prev => [...inserted, ...prev]);
            }
          } catch (err) {
            console.error('Failed to import pins:', err);
            alert(err instanceof Error ? err.message : String(err));
          } finally {
            setShowImportPinsModal(false);
            setPendingImportTargetImageId(null);
            setPendingImportPins([]);
          }
        }}
        title="Import pins?"
        message="Import pins from the most recent image into this new image?"
        confirmText="Yes, import"
        cancelText="No"
      />
    </main>
  );
}