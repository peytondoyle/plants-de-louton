import { useEffect, useRef, useState } from "react";
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

  const [images, setImages] = useState<BedImage[]>([]);
  const [pins, setPins] = useState<Pin[]>([]);

  const [drawerOpen, setDrawerOpen] = useState(false);
  const [draftInit, setDraftInit] = useState<Pin | { x: number; y: number } | undefined>(undefined);
  const [imgVer, setImgVer] = useState(0);
  const [ready, setReady] = useState(false);

  const boardRef = useRef<HTMLDivElement | null>(null);

  async function refresh() {
    setReady(false);
    const data = await getBed(bedId);
    setBed(data.bed);
    setImageUrl(data.publicUrl || "");
    setImagePath(data.image?.image_path ?? null);
    setActiveImageId(data.image?.id);
    const hist = await listImagesForBed(bedId);
    setImages(hist);
    setReady(true);
  }

  useEffect(() => {
    void refresh();
  }, [bedId]);

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

  const createAt = (pos: { x: number; y: number }) => {
    setDraftInit(pos);
    setDrawerOpen(true);
  };
  const editPin = (pin: Pin) => {
    setDraftInit(pin);
    setDrawerOpen(true);
  };

  return (
    // Single container so this aligns perfectly with the header brand
    <main className="app-root container">
      {/* Page header */}
      <h1 className="page-title">{bed?.name ?? "Bed"}</h1>

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
              <div className="image-shell card" ref={boardRef as any}>
                <PinDropper
                  bedId={bedId}
                  imageUrl={`${imageUrl}?v=${imgVer}`}
                  imageId={activeImageId}
                  section={slug}
                  bedName={bed?.name ?? ""}
                  onCreateAt={createAt}
                  onEditPin={editPin}
                  onPinsChange={setPins}
                  useExternalEditor
                  showInlineHint
                >
                  {images.length > 0 && (
                    <div className="tt-wrap tt-wrap--abs" style={{ position: "absolute", right: 10, bottom: 10 }}>
                      <MainImageTooltip
                        imgEl={document.querySelector('.image-shell img') as HTMLImageElement}
                        containerEl={document.querySelector('.image-shell') as HTMLElement}
                        timestamp={new Date(
                          images.find((i) => i.image_path === imagePath)?.created_at ?? Date.now()
                        ).toLocaleString()}
                      />
                    </div>
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
                  onSelect={(id) => {
                    const found = images.find((i) => i.id === id);
                    if (!found) return;
                    const { data } = supabase.storage.from("plant-images").getPublicUrl(found.image_path);
                    setActiveImageId(found.id);
                    setImagePath(found.image_path);
                    setImageUrl(data.publicUrl);
                  }}
                />
              );
            })()}
          </div>

          <PinsPanel
            pins={pins}
            onAdd={() => {
              setDraftInit({ x: 0.5, y: 0.5 });
              setDrawerOpen(true);
            }}
            onOpen={(pin) => {
              setDraftInit(pin);
              setDrawerOpen(true);
            }}
          />

          <div className="card" style={{ padding: 10 }}>
            <div className="panel-title" style={{ marginBottom: 6 }}>
              Quick help
            </div>
            <div style={{ fontSize: 13, color: "#6b7280", lineHeight: 1.4 }}>
              Click the image to add a pin. Click a pin to edit. Use the thumbnails above to switch
              images.
            </div>
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
    </main>
  );
}