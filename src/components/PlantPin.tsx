import React from "react";
import type { Pin } from "../types/types";

type Props = {
  pin: Pin;
  onClick: (pin: Pin) => void;
};

export default function PlantPin({ pin, onClick }: Props) {
  return (
    <button
      className="pin"
      style={{ left: `${pin.x * 100}%`, top: `${pin.y * 100}%` }}
      title={pin.name ?? undefined}  
      aria-label={`Pin ${pin.name}`}
      onClick={(e) => {
        e.stopPropagation();
        onClick(pin);
      }}
    />
  );
}