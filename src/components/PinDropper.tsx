import React, { useEffect, useMemo, useRef, useState, useCallback } from "react";
import { supabase } from "../lib/supabaseClient";
import type { Pin } from "../types/types";
import { getPinColors } from "../lib/pinColor";

type Props = {
  bedId: string;
  imageUrl: string;
  /** Only show pins that belong to this bed image. If omitted, shows all pins for the bed. */
  imageId?: string;
  section?: string;
  bedName?: string;

  // external editor hooks
  onCreateAt?: (pos: { x: number; y: number }) => void;
  onEditPin?: (pin: Pin) => void;
  onPinsChange?: (pins: Pin[]) => void;

  /** We use the drawer editor in BedDetail, so keep this true by default. */
  useExternalEditor?: boolean;

  /** When true, renders the inline hint above the image. */
  showInlineHint?: boolean;
  /** Optional overlay content to render inside the image shell (e.g., a tooltip button). */
  children?: React.ReactNode;
  /** Whether pins are visible. Defaults to true for backward compatibility. */
  isVisible?: boolean;
  /** Currently selected pin ID for visual feedback */
  selectedPinId?: string;
  /** Pins to display - if provided, component won't load its own pins */
  pins?: Pin[];
};

export default function PinDropper({
  bedId,
  imageUrl,
  imageId,
  section,
  bedName,
  onCreateAt,
  onEditPin,
  onPinsChange,
  useExternalEditor = true,
  showInlineHint = false,
  children,
  isVisible = true,
  selectedPinId,
  pins: externalPins,
}: Props) {
  const [internalPins, setInternalPins] = useState<Pin[]>([]);
  const [loading, setLoading] = useState(true);
  const imgRef = useRef<HTMLImageElement | null>(null);
  const containerRef = useRef<HTMLDivElement | null>(null);
  const [draggingPinId, setDraggingPinId] = useState<string | null>(null);
  const [dragStartPos, setDragStartPos] = useState<{ x: number; y: number } | null>(null);
  const [optimisticPins, setOptimisticPins] = useState<Pin[]>([]);
  const [pinWasMoved, setPinWasMoved] = useState<boolean>(false);
  const resizeObserverRef = useRef<ResizeObserver | null>(null);
  const allowDragRef = useRef<boolean>(false);
  const longPressTimerRef = useRef<number | null>(null);
  const downPointer = useRef<{ id: number; target: EventTarget | null } | null>(null);
  const [pinLuminance, setPinLuminance] = useState<Record<string, number | null>>({});
  const [pinBgRgb, setPinBgRgb] = useState<Record<string, { r: number; g: number; b: number } | null>>({});
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const lastSampleTsRef = useRef<number>(0);
  const pendingRafRef = useRef<number | null>(null);

  // Helpers to adapt pin core color for background contrast
  function parseHsl(hsl: string): { h: number; s: number; l: number } | null {
    const m = /hsl\((\d+)\s*,\s*(\d+)%\s*,\s*(\d+)%\)/i.exec(hsl);
    if (!m) return null;
    return { h: Number(m[1]), s: Number(m[2]), l: Number(m[3]) };
  }
  function hsl(h: number, s: number, l: number) {
    return `hsl(${h}, ${s}%, ${l}%)`;
  }
  function adaptiveCore(baseHsl: string, lum: number | null, rgb: { r: number; g: number; b: number } | null): { base: string; highlight: string } {
    const parsed = parseHsl(baseHsl);
    if (!parsed) return { base: baseHsl, highlight: baseHsl };
    const { h, s } = parsed;
    let l = 52; // neutral
    if (typeof lum === "number") {
      if (lum >= 200) l = 20;             // very bright bg → very dark
      else if (lum >= 170) l = 30;        // bright → dark
      else if (lum <= 55) l = 78;         // very dark → bright
      else if (lum <= 85) l = 68;         // dark → lighter
      else l = 52;                        // mid
    }
    const hl = Math.min(l + 12, 88);
    return { base: hsl(h, s, l), highlight: hsl(h, s, hl) };
  }

  // Use external pins if provided, otherwise use internal pins
  const pins = externalPins ?? internalPins;
  const setPins = useMemo(() => 
    externalPins ? (() => {}) : setInternalPins, 
    [externalPins, setInternalPins]
  );

  // Load pins for this bed (+ optional image filter) - only if external pins not provided
  useEffect(() => {
    if (externalPins) {
      // Use external pins, no need to load
      setLoading(false);
      setOptimisticPins(externalPins);
      return;
    }

    let cancel = false;

    async function run() {
      setLoading(true);

      let query = supabase
        .from("pins")
        .select("*")
        .eq("bed_id", bedId);

      if (imageId) query = query.eq("image_id", imageId);

      const { data, error } = await query.order("created_at", { ascending: true });

      if (!cancel) {
        if (error) {
          alert(error.message);
          setPins([]);
          setOptimisticPins([]);
        } else {
          const list = (data ?? []) as Pin[];
          setPins(list);
          setOptimisticPins(list);
        }
        setLoading(false);
      }
    }

    void run();
    return () => {
      cancel = true;
    };
  }, [bedId, imageId, externalPins, setPins]);

  // Update optimistic pins when external pins change, but avoid snap-backs immediately after a drag
  useEffect(() => {
    if (!externalPins || draggingPinId) return;

    // If ids changed (pin added/removed), always sync
    const idsA = new Set((optimisticPins ?? []).map(p => p.id));
    const idsB = new Set(externalPins.map(p => p.id));
    const idsChanged = idsA.size !== idsB.size || [...idsA].some(id => !idsB.has(id));
    if (idsChanged) {
      setOptimisticPins(externalPins);
      return;
    }

    // Compare positions; if very different (e.g., we just moved a pin), don't overwrite optimistic
    let maxDiff = 0;
    const mapA = new Map(optimisticPins.map(p => [p.id, p] as const));
    for (const p of externalPins) {
      const a = mapA.get(p.id);
      if (!a) { maxDiff = 1; break; }
      maxDiff = Math.max(maxDiff, Math.abs((a.x ?? 0) - (p.x ?? 0)), Math.abs((a.y ?? 0) - (p.y ?? 0)));
      if (maxDiff > 0.01) break; // significant difference
    }
    // Only sync if differences are tiny (server echo) to avoid visible snap
    if (maxDiff <= 0.01) {
      setOptimisticPins(externalPins);
    }
  }, [externalPins, optimisticPins, draggingPinId]);

  // Setup ResizeObserver for image container
  useEffect(() => {
    if (!containerRef.current) return;

    const observer = new ResizeObserver(() => {
      // Trigger re-render when container resizes to recalculate pin positions
      setOptimisticPins(current => current);
    });
    
    observer.observe(containerRef.current);
    resizeObserverRef.current = observer;

    return () => {
      observer.disconnect();
      resizeObserverRef.current = null;
    };
  }, []);

  // Helpers: sample luminance at a given percent position
  const sampleBackground = useCallback((px: number, py: number): { lum: number | null; rgb: { r: number; g: number; b: number } | null } => {
    const img = imgRef.current;
    if (!img || img.naturalWidth === 0) return { lum: null, rgb: null };
    if (!canvasRef.current) canvasRef.current = document.createElement('canvas');
    const canvas = canvasRef.current;
    const ctx = canvas.getContext('2d');
    if (!ctx) return { lum: null, rgb: null };
    const sampleSize = 10;
    canvas.width = sampleSize;
    canvas.height = sampleSize;
    const sx = Math.max(0, Math.min(img.naturalWidth - sampleSize, Math.round(px * img.naturalWidth) - Math.floor(sampleSize / 2)));
    const sy = Math.max(0, Math.min(img.naturalHeight - sampleSize, Math.round(py * img.naturalHeight) - Math.floor(sampleSize / 2)));
    ctx.clearRect(0, 0, sampleSize, sampleSize);
    ctx.drawImage(img, sx, sy, sampleSize, sampleSize, 0, 0, sampleSize, sampleSize);
    const data = ctx.getImageData(0, 0, sampleSize, sampleSize).data;
    let total = 0;
    let count = 0;
    let rSum = 0; let gSum = 0; let bSum = 0;
    for (let i = 0; i < data.length; i += 4) {
      const r = data[i];
      const g = data[i + 1];
      const b = data[i + 2];
      total += 0.2126 * r + 0.7152 * g + 0.0722 * b;
      rSum += r; gSum += g; bSum += b;
      count++;
    }
    const lum = count ? total / count : null;
    const rgb = count ? { r: Math.round(rSum / count), g: Math.round(gSum / count), b: Math.round(bSum / count) } : null;
    return { lum, rgb };
  }, []);

  // Sample luminance for all pins once when image loads or pin ids change
  const optimisticIdsKey = useMemo(() => optimisticPins.map(p => p.id).join(','), [optimisticPins]);
  useEffect(() => {
    const img = imgRef.current;
    if (!img || !imageUrl) return;
    let cancelled = false;
    (async () => {
      if (!img.complete || img.naturalWidth === 0) {
        await new Promise<void>((resolve) => {
          img.onload = () => resolve();
          img.onerror = () => resolve();
        });
      }
      const next: Record<string, number | null> = {};
      const nextRgb: Record<string, { r: number; g: number; b: number } | null> = {};
      for (const p of optimisticPins) {
        const { lum, rgb } = sampleBackground(p.x, p.y);
        next[p.id] = lum;
        nextRgb[p.id] = rgb;
      }
      if (!cancelled) { setPinLuminance(next); setPinBgRgb(nextRgb); }
    })();
    return () => { cancelled = true; };
  }, [imageUrl, optimisticIdsKey, sampleBackground, optimisticPins]);

  // Throttled per-drag sampling for the dragging pin only (avoids stutter)
  const scheduleSampleFor = useCallback((pinId: string, x: number, y: number) => {
    const now = performance.now();
    if (now - (lastSampleTsRef.current || 0) < 60) return; // ~16fps sampling while dragging
    lastSampleTsRef.current = now;
    if (pendingRafRef.current) cancelAnimationFrame(pendingRafRef.current);
    pendingRafRef.current = requestAnimationFrame(() => {
      const { lum, rgb } = sampleBackground(x, y);
      setPinLuminance(prev => ({ ...prev, [pinId]: lum }));
      setPinBgRgb(prev => ({ ...prev, [pinId]: rgb }));
    });
  }, [sampleBackground]);

  const canInteract = useMemo(
    () => Boolean(imageUrl && bedId && isVisible),
    [imageUrl, bedId, isVisible]
  );

  /**
   * Converts client coordinates to percentage values (0-1) with clamping
   */
  const clientToPercent = useCallback((clientX: number, clientY: number) => {
    if (!imgRef.current) return { x: 0, y: 0 };
    const rect = imgRef.current.getBoundingClientRect();
    const x = (clientX - rect.left) / rect.width;
    const y = (clientY - rect.top) / rect.height;
    return { x: clamp01(x), y: clamp01(y) };
  }, []);

  const handleImageClick = (e: React.MouseEvent) => {
    if (!canInteract || !imgRef.current) return;
    const { x, y } = clientToPercent(e.clientX, e.clientY);
    onCreateAt?.({ x, y });
  };

  const editPin = useCallback((pin: Pin) => onEditPin?.(pin), [onEditPin]);

  // Small mobile label bubble near the selected pin
  const selectedPinLabel = useMemo(() => {
    if (!selectedPinId) return null;
    const p = optimisticPins.find(x => x.id === selectedPinId);
    if (!p) return null;
    const name = p.name || "Untitled";
    return (
      <div
        style={{
          position: 'absolute',
          left: `${p.x * 100}%`,
          top: `${p.y * 100}%`,
          transform: 'translate(-50%, calc(-100% - 12px))',
          background: 'rgba(17,24,39,0.9)',
          color: '#fff',
          padding: '6px 8px',
          fontSize: 12,
          borderRadius: 8,
          pointerEvents: 'none',
          whiteSpace: 'nowrap',
        }}
      >
        {name}
      </div>
    );
  }, [selectedPinId, optimisticPins]);

  /**
   * Handles pin drag start with Pointer Events
   */
  const handlePinPointerDown = useCallback((e: React.PointerEvent, pin: Pin) => {
    e.preventDefault();
    e.stopPropagation();
    
    if (!canInteract) return;
    
    setPinWasMoved(false);
    allowDragRef.current = e.altKey || e.metaKey; // Desktop: hold Option/Command to move
    downPointer.current = { id: e.pointerId, target: e.target };
    setDragStartPos({ x: e.clientX, y: e.clientY });

    if (allowDragRef.current) {
      setDraggingPinId(pin.id);
      (e.target as HTMLElement).setPointerCapture(e.pointerId);
    } else if (e.pointerType === 'touch') {
      // Long-press to move on touch
      longPressTimerRef.current = window.setTimeout(() => {
        allowDragRef.current = true;
        setDraggingPinId(pin.id);
        const tgt = downPointer.current?.target as HTMLElement | null;
        const pid = downPointer.current?.id;
        if (tgt && typeof pid === 'number') {
          try { tgt.setPointerCapture(pid); } catch {}
        }
      }, 350);
    } else {
      // Click-only (select) scenario; we don't start drag here
    }
  }, [canInteract]);

  /**
   * Handles pin drag during pointer move
   */
  const handlePinPointerMove = useCallback((e: React.PointerEvent) => {
    if (!draggingPinId || !dragStartPos || !allowDragRef.current) return;
    
    const { x, y } = clientToPercent(e.clientX, e.clientY);
    
    // Check if pin actually moved (more than a tiny threshold)
    const currentPin = optimisticPins.find(p => p.id === draggingPinId);
    if (currentPin && (Math.abs(currentPin.x - x) > 0.005 || Math.abs(currentPin.y - y) > 0.005)) {
      setPinWasMoved(true);
    }
    
    // Update optimistic position immediately for smooth dragging
    setOptimisticPins(prev => 
      prev.map(p => 
        p.id === draggingPinId 
          ? { ...p, x, y }
          : p
      )
    );
    // Update luminance for only the dragging pin (throttled)
    scheduleSampleFor(draggingPinId, x, y);
  }, [draggingPinId, dragStartPos, clientToPercent, optimisticPins, scheduleSampleFor]);

  /**
   * Handles pin drag end and saves position
   */
  const handlePinPointerUp = useCallback((e: React.PointerEvent) => {
    if (longPressTimerRef.current) { clearTimeout(longPressTimerRef.current); longPressTimerRef.current = null; }
    if (!draggingPinId) return;
    
    const { x, y } = clientToPercent(e.clientX, e.clientY);
    
    // Release pointer capture
    (e.target as HTMLElement).releasePointerCapture(e.pointerId);
    
    // Create the updated pins array with the new position (based on optimistic state to avoid snapping)
    const updatedPins = optimisticPins.map(p => 
      p.id === draggingPinId 
        ? { ...p, x, y }
        : p
    );
    
    // Update optimistic state immediately for smooth UI
    setOptimisticPins(updatedPins);
    
    // Only update internal pins if not using external pins
    if (!externalPins) { setPins(updatedPins); }
    
    // Clear drag state
    setDraggingPinId(null);
    setDragStartPos(null);
    allowDragRef.current = false;
    
    // Reset moved flag immediately after commit
    setPinWasMoved(false);
    
    // Save to parent in the background (non-blocking)
    // Use requestAnimationFrame to ensure UI updates first
    requestAnimationFrame(() => {
      onPinsChange?.(updatedPins);
    });
  }, [draggingPinId, clientToPercent, onPinsChange, pins, externalPins, setPins]);

  /**
   * Handles keyboard navigation for pins
   */
  const handlePinKeyDown = useCallback((e: React.KeyboardEvent, pin: Pin) => {
    if (!canInteract) return;
    
    const shift = e.shiftKey;
    const step = shift ? 0.001 : 0.01; // 0.1% or 1% per keypress
    
    let newX = pin.x;
    let newY = pin.y;
    
    switch (e.key) {
      case 'ArrowLeft':
        newX = clamp01(pin.x - step);
        break;
      case 'ArrowRight':
        newX = clamp01(pin.x + step);
        break;
      case 'ArrowUp':
        newY = clamp01(pin.y - step);
        break;
      case 'ArrowDown':
        newY = clamp01(pin.y + step);
        break;
      case 'Enter':
        editPin(pin);
        return;
      case 'Escape':
        if (draggingPinId === pin.id) {
          setDraggingPinId(null);
          setDragStartPos(null);
          // Reset to original position
          setOptimisticPins(prev => 
            prev.map(p => 
              p.id === pin.id 
                ? pins.find(orig => orig.id === pin.id) || pin
                : p
            )
          );
        }
        return;
      default:
        return;
    }
    
    e.preventDefault();
    
    // Create updated pins array with new position
    const updatedPins = optimisticPins.map(p => 
      p.id === pin.id 
        ? { ...p, x: newX, y: newY }
        : p
    );
    
    // Update optimistic state immediately
    setOptimisticPins(updatedPins);
    
    // Save to parent in the background (non-blocking)
    requestAnimationFrame(() => {
      onPinsChange?.(updatedPins);
    });
  }, [canInteract, draggingPinId, pins, editPin, onPinsChange, optimisticPins]);



  const pinEls = useMemo(
    () =>
      optimisticPins.map((p) => (
        <button
          key={p.id}
          className={`pin ${selectedPinId === p.id ? 'pin--selected' : ''} ${draggingPinId === p.id ? 'pin--dragging' : ''}`}
          title={p.name ?? undefined}
          onClick={(e) => {
            e.stopPropagation();
            // Select and open editor on click when the pin wasn't dragged
            if (!pinWasMoved) {
              const event = new CustomEvent('pin-selected', { detail: { id: p.id } });
              window.dispatchEvent(event);
              editPin(p);
            }
          }}
          aria-label={p.name || `Pin at ${Math.round(p.x * 100)}%, ${Math.round(p.y * 100)}%`}
          onPointerDown={(e) => handlePinPointerDown(e, p)}
          onPointerMove={handlePinPointerMove}
          onPointerUp={handlePinPointerUp}
          onKeyDown={(e) => handlePinKeyDown(e, p)}
          tabIndex={0}
          style={(() => {
            const c = getPinColors(p.id);
            return {
              left: `${p.x * 100}%`,
              top: `${p.y * 100}%`,
              background: 'transparent',
              border: 'none',
              boxShadow: '0 1px 3px rgba(0,0,0,0.25)',
            } as React.CSSProperties;
          })()}
        >
          {(() => {
              const c = getPinColors(p.id);
            const isSelected = selectedPinId === p.id;
            const lum = pinLuminance[p.id];
              const bg = pinBgRgb[p.id];
            let halo = 'rgba(17,24,39,0.38)';
            if (typeof lum === 'number') {
              if (lum > 170) halo = 'rgba(17,24,39,0.55)';
              else if (lum < 85) halo = 'rgba(255,255,255,0.65)';
              else halo = 'rgba(107,114,128,0.55)';
            }
            const glow = isSelected ? 9 : 7;
            return (
              <span
                aria-hidden
                className="pin-glow"
                style={{
                  background: `radial-gradient(closest-side, ${halo}, rgba(0,0,0,0))`,
                  inset: `-${glow}px`,
                  opacity: isSelected ? 0.9 : 0.7,
                  filter: 'blur(4px)'
                } as React.CSSProperties}
              />
            );
          })()}

          <span
            aria-hidden
            className="pin-core"
            style={(() => {
              const c = getPinColors(p.id);
              const bg = pinBgRgb[p.id];
              const lum = pinLuminance[p.id] ?? null;
              return {
                background: (() => {
                  const core = adaptiveCore(c.base, lum, bg ?? null);
                  return `radial-gradient(circle at 30% 30%, ${core.highlight} 0%, ${core.base} 70%)`;
                })(),
                boxShadow: 'inset 0 1px 2px rgba(255,255,255,0.25), 0 1px 2px rgba(0,0,0,0.15)'
              } as React.CSSProperties;
            })()}
          />
        </button>
      )),
    [optimisticPins, selectedPinId, draggingPinId, handlePinPointerDown, handlePinPointerMove, handlePinPointerUp, handlePinKeyDown, editPin, pinWasMoved]
  );

  return (
    <div className="pinboard-wrap">
      {showInlineHint && (
        <p className="hint">Click the image to drop a pin. Click a pin to edit or delete.</p>
      )}

      <div
        className={`pinboard ${imageUrl ? "ready" : "empty"}`}
        onClick={imageUrl ? handleImageClick : undefined}
      >
        {!imageUrl ? (
          <div className="empty-state">
            <p>Upload an image to begin pinning.</p>
          </div>
        ) : (
          <div className="pinboard-stage">
            <div className="image-shell" ref={containerRef}>
              <img
                ref={imgRef}
                src={imageUrl}
                alt={`${section ?? ""} — ${bedName ?? ""}`}
                loading="eager"
                decoding="async"
                draggable={false}
              />
              <div 
                className="pins-layer" 
                style={{ 
                  pointerEvents: isVisible ? 'auto' : 'none',
                  userSelect: draggingPinId ? 'none' : 'auto'
                }}
              >
                {pinEls}
                {selectedPinLabel}
              </div>
              {children}
            </div>
          </div>
        )}
      </div>

      {loading && (
        <div className="modal-backdrop">
          <div className="modal"><p>Loading…</p></div>
        </div>
      )}
    </div>
  );
}

function clamp01(n: number) {
  return Math.max(0, Math.min(1, n));
}