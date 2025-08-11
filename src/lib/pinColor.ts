/**
 * Deterministically generate a pleasant color set from a string seed.
 * We use the pin id so colors are stable across sessions without DB changes.
 */
export function getPinColors(seed: string): {
  base: string;       // main color
  highlight: string;  // lighter variant for gradient
  shadow: string;     // rgba shadow color
} {
  const hash = hashString(seed);
  // Spread hues around the wheel. Keep saturation and lightness in a pleasing range.
  const hue = Math.abs(hash) % 360;
  const saturation = 70; // %
  const lightness = 50;  // %

  const base = `hsl(${hue}, ${saturation}%, ${lightness - 5}%)`;
  const highlight = `hsl(${hue}, ${saturation}%, ${Math.min(lightness + 10, 90)}%)`;
  const shadow = `hsla(${hue}, ${Math.max(saturation - 20, 40)}%, ${Math.max(lightness - 10, 20)}%, 0.35)`;

  return { base, highlight, shadow };
}

function hashString(input: string): number {
  let h = 2166136261; // FNV-1a basis
  for (let i = 0; i < input.length; i++) {
    h ^= input.charCodeAt(i);
    h += (h << 1) + (h << 4) + (h << 7) + (h << 8) + (h << 24); // * 16777619 with bit ops
  }
  return h | 0;
}


