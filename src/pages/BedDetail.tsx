import { useCallback, useEffect, useRef, useState } from "react";
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

  const boardRef = useRef<HTMLDivElement | null>(null);

  const refresh = useCallback(async () => {
    setReady(false);
    const data = await getBed(bedId);
    setBed(data.bed);
    
    // Get stored image preference for this bed
    const storedImageId = localStorage.getItem(`bed-${bedId}-selected-image`);
    
    const hist = await listImagesForBed(bedId);
    setImages(hist);
    
    // If we have a stored preference and it exists in the images, use it
    let selectedImage = data.image;
    if (storedImageId && hist.find(img => img.id === storedImageId)) {
      selectedImage = hist.find(img => img.id === storedImageId) || data.image;
    }
    
    setImageUrl(selectedImage ? supabase.storage.from("plant-images").getPublicUrl(selectedImage.image_path).data.publicUrl : "");
    setImagePath(selectedImage?.image_path ?? null);
    setActiveImageId(selectedImage?.id);
    setMainImageId(data.image?.id); // Keep main image as the first/current image
    setPins(data.pins);
    setReady(true);
  }, [bedId]);

  useEffect(() => {
    if (bedId) {
      void refresh();
    }
  }, [bedId, refresh]);



  const onChangeImage = async (file: File) => {
    if (!bed) return;
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
      } else {
        // No images left
        setImageUrl("");
        setImagePath(null);
        setActiveImageId(undefined);
      }
    }
    
    // Refresh pins to remove any pins that were associated with the deleted image
    await refresh();
  };

  const handleSetMainImage = async (imageId: string) => {
    const targetImage = images.find(img => img.id === imageId);
    if (!targetImage) return;

    const { data } = supabase.storage.from("plant-images").getPublicUrl(targetImage.image_path);
    setImageUrl(data.publicUrl);
    setImagePath(targetImage.image_path);
    setActiveImageId(targetImage.id);
    setMainImageId(targetImage.id); // Set this as the main image
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
    <main className="app-root container">
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
      <div className="page-grid">
        <div className="left-col" ref={boardRef}>
          {imageUrl ? (
            <>
            <div className="pinboard-stage">
              <div className="image-shell card" ref={boardRef}>
                <PinDropper
                  bedId={bedId}
                  imageUrl={`${imageUrl}?v=${imgVer}`}
                  imageId={activeImageId}
                  section={slug}
                  bedName={bed?.name ?? ""}
                  onCreateAt={createAt}
                  onEditPin={editPin}
                  onPinsChange={savePinPositions}
                  useExternalEditor
                  showInlineHint
                  pins={activeImageId ? pins.filter(pin => pin.image_id === activeImageId) : pins}
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
            
            </>
          ) : (
            <div className="panel-empty">This bed has no image yet. Use “Change image”.</div>
          )}
        </div>

        <Sidebar>
          <div className="card panel panel--images">
            {(() => {
              const items = images.map((img) => {
                const { data } = supabase.storage.from("plant-images").getPublicUrl(img.image_path);
                const d = img.created_at ? new Date(img.created_at) : null;
                const label = d ? d.toLocaleDateString() : undefined;
                return { id: img.id, url: data.publicUrl, label };
              });
              const activeId = images.find((i) => i.image_path === imagePath)?.id;
              return (
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
                    
                    // Save the selected image preference to localStorage
                    localStorage.setItem(`bed-${bedId}-selected-image`, found.id);
                  }}
                  onDelete={handleDeleteImage}
                  onSetMain={handleSetMainImage}
                  pins={pins}
                  bedId={bedId}
                />
              );
            })()}
          </div>


          <PinsPanel
            pins={activeImageId ? pins.filter(pin => pin.image_id === activeImageId) : pins}
            onOpen={(pin) => {
              setDraftInit(pin);
              setDrawerOpen(true);
            }}
          />


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
    </main>
  );
}