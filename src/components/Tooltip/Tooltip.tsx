import React, { useCallback, useEffect, useId, useRef, useState } from "react";
import { createPortal } from "react-dom";
import "./Tooltip.css";

type Placement = "top" | "bottom" | "left" | "right";
type Theme = "dark" | "light";

interface TooltipProps {
  content: React.ReactNode;
  placement?: Placement;
  autoTheme?: boolean;
  delay?: number;
  children: React.ReactElement;
}

export default function Tooltip({ 
  content, 
  placement = "top", 
  autoTheme = false, 
  delay = 80,
  children 
}: TooltipProps) {
  const [isVisible, setIsVisible] = useState(false);
  const [theme, setTheme] = useState<Theme>("dark");
  const [position, setPosition] = useState({ top: 0, left: 0 });
  
  const triggerRef = useRef<HTMLSpanElement>(null);
  const tooltipRef = useRef<HTMLDivElement>(null);
  const timeoutRef = useRef<NodeJS.Timeout>();
  const tooltipId = useId();

  // No dedicated portal container needed; we'll portal directly to body

  // AutoTheme detection for images
  useEffect(() => {
    if (!autoTheme || !triggerRef.current) return;

    const detectTheme = () => {
      const img = triggerRef.current?.querySelector("img");
      if (!img || !img.complete || img.naturalWidth === 0) {
        setTheme("dark");
        return;
      }

      try {
        const canvas = document.createElement("canvas");
        const ctx = canvas.getContext("2d");
        if (!ctx) {
          setTheme("dark");
          return;
        }

        // Sample 12x12 area from center of image
        const sampleSize = 12;
        canvas.width = sampleSize;
        canvas.height = sampleSize;
        
        const rect = img.getBoundingClientRect();
        const centerX = Math.floor(img.naturalWidth / 2);
        const centerY = Math.floor(img.naturalHeight / 2);
        const offsetX = Math.floor(sampleSize / 2);
        const offsetY = Math.floor(sampleSize / 2);
        
        ctx.drawImage(
          img,
          centerX - offsetX, centerY - offsetY,
          sampleSize, sampleSize,
          0, 0, sampleSize, sampleSize
        );

        const imageData = ctx.getImageData(0, 0, sampleSize, sampleSize).data;
        let totalLuminance = 0;
        let pixelCount = 0;

        for (let i = 0; i < imageData.length; i += 4) {
          const r = imageData[i];
          const g = imageData[i + 1];
          const b = imageData[i + 2];
          // Luminance calculation (0.2126*R + 0.7152*G + 0.0722*B)
          const luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b;
          totalLuminance += luminance;
          pixelCount++;
        }

        const averageLuminance = totalLuminance / pixelCount;
        // Threshold at 0.6 (153/255) for light vs dark
        setTheme(averageLuminance > 153 ? "dark" : "light");
      } catch (error) {
        // Fallback to dark theme if sampling fails
        setTheme("dark");
      }
    };

    detectTheme();
  }, [autoTheme]);

  // Position calculation
  const calculatePosition = useCallback(() => {
    if (!triggerRef.current || !tooltipRef.current) return;

    const triggerRect = triggerRef.current.getBoundingClientRect();
    const tooltipRect = tooltipRef.current.getBoundingClientRect();
    const scrollX = window.pageXOffset || document.documentElement.scrollLeft;
    const scrollY = window.pageYOffset || document.documentElement.scrollTop;

    let top = 0;
    let left = 0;

    switch (placement) {
      case "top":
        top = triggerRect.top + scrollY - tooltipRect.height - 8;
        left = triggerRect.left + scrollX + (triggerRect.width / 2) - (tooltipRect.width / 2);
        // no arrow
        break;
      case "bottom":
        top = triggerRect.bottom + scrollY + 8;
        left = triggerRect.left + scrollX + (triggerRect.width / 2) - (tooltipRect.width / 2);
        // no arrow
        break;
      case "left":
        top = triggerRect.top + scrollY + (triggerRect.height / 2) - (tooltipRect.height / 2);
        left = triggerRect.left + scrollX - tooltipRect.width - 8;
        // no arrow
        break;
      case "right":
        top = triggerRect.top + scrollY + (triggerRect.height / 2) - (tooltipRect.height / 2);
        left = triggerRect.right + scrollX + 8;
        // no arrow
        break;
    }

    // Ensure tooltip stays within viewport
    const viewportWidth = window.innerWidth;
    const viewportHeight = window.innerHeight;

    if (left < 8) left = 8;
    if (left + tooltipRect.width > viewportWidth - 8) {
      left = viewportWidth - tooltipRect.width - 8;
    }
    if (top < 8) top = 8;
    if (top + tooltipRect.height > viewportHeight - 8) {
      top = viewportHeight - tooltipRect.height - 8;
    }

    setPosition({ top, left });
  }, [placement]);

  // Show/hide handlers with debouncing
  const showTooltip = useCallback(() => {
    if (timeoutRef.current) clearTimeout(timeoutRef.current);
    timeoutRef.current = setTimeout(() => {
      setIsVisible(true);
      // Calculate position after tooltip is visible
      setTimeout(calculatePosition, 10);
    }, delay);
  }, [delay, calculatePosition]);

  const hideTooltip = useCallback(() => {
    if (timeoutRef.current) clearTimeout(timeoutRef.current);
    timeoutRef.current = setTimeout(() => {
      setIsVisible(false);
    }, delay);
  }, [delay]);

  // Keyboard support
  const handleKeyDown = useCallback((e: KeyboardEvent) => {
    if (e.key === "Escape") {
      setIsVisible(false);
    }
  }, []);

  useEffect(() => {
    document.addEventListener("keydown", handleKeyDown);
    return () => document.removeEventListener("keydown", handleKeyDown);
  }, [handleKeyDown]);

  // Update position on scroll/resize
  useEffect(() => {
    if (!isVisible) return;

    const updatePosition = () => {
      if (isVisible) calculatePosition();
    };

    window.addEventListener("scroll", updatePosition, { passive: true });
    window.addEventListener("resize", updatePosition, { passive: true });

    return () => {
      window.removeEventListener("scroll", updatePosition);
      window.removeEventListener("resize", updatePosition);
    };
  }, [isVisible, calculatePosition]);

  return (
    <>
      <span
        ref={triggerRef}
        onMouseEnter={showTooltip}
        onMouseLeave={hideTooltip}
        onFocus={showTooltip}
        onBlur={hideTooltip}
        aria-describedby={isVisible ? tooltipId : undefined}
        style={{ display: "inline-flex" }}
      >
        {children}
      </span>
      {createPortal(
        <div
          ref={tooltipRef}
          id={tooltipId}
          role="tooltip"
          className={`tooltip tooltip--${placement} tooltip--${theme} ${isVisible ? "tooltip--visible" : ""}`}
          style={{
            top: position.top,
            left: position.left,
          }}
          aria-hidden={!isVisible}
        >
          <div className="tooltip__content">{content}</div>
        </div>,
        document.body
      )}
    </>
  );
}
