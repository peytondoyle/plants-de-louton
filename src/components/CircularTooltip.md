# CircularTooltip Component

A robust, accessible tooltip component built with Floating UI that renders perfect circular tooltips with proper positioning and sizing.

## Features

- ✅ **Perfect circles**: Always maintains circular shape regardless of content
- ✅ **Smart positioning**: Automatically positions to avoid viewport edges
- ✅ **Accessible**: Full keyboard navigation and screen reader support
- ✅ **Responsive**: Adapts to different screen sizes
- ✅ **Smooth animations**: Fade-in/out with scale effects
- ✅ **Multiple placements**: Top, bottom, left, right
- ✅ **Customizable**: Delay, styling, and theme options

## Installation

The component uses `@floating-ui/react` which is already installed:

```bash
npm install @floating-ui/react
```

## Usage

### Basic Usage

```tsx
import { CircularTooltip } from './components/CircularTooltip';

<CircularTooltip label="This is a circular tooltip!">
  <button>Hover me</button>
</CircularTooltip>
```

### With Placement

```tsx
<CircularTooltip label="Tooltip on top" placement="top">
  <button>Hover me</button>
</CircularTooltip>

<CircularTooltip label="Tooltip on bottom" placement="bottom">
  <button>Hover me</button>
</CircularTooltip>

<CircularTooltip label="Tooltip on left" placement="left">
  <button>Hover me</button>
</CircularTooltip>

<CircularTooltip label="Tooltip on right" placement="right">
  <button>Hover me</button>
</CircularTooltip>
```

### With Custom Delay

```tsx
<CircularTooltip label="Delayed tooltip" delay={500}>
  <button>Hover me (500ms delay)</button>
</CircularTooltip>
```

### With Custom Styling

```tsx
<CircularTooltip 
  label="Custom styled tooltip" 
  className="my-custom-trigger"
>
  <button className="my-button">Hover me</button>
</CircularTooltip>
```

## Props

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `label` | `string` | - | The text content of the tooltip |
| `children` | `ReactNode` | - | The trigger element |
| `placement` | `'top' \| 'bottom' \| 'left' \| 'right'` | `'top'` | Where to position the tooltip |
| `delay` | `number` | `200` | Delay before showing tooltip (ms) |
| `className` | `string` | `''` | Additional CSS class for the trigger |

## CSS Customization

The tooltip uses CSS classes that can be customized:

- `.circular-tooltip` - Main tooltip container
- `.circular-tooltip-content` - The circular content area
- `.circular-tooltip-arrow` - The arrow pointer

### Example Customization

```css
.circular-tooltip-content {
  /* Custom size */
  width: 150px;
  height: 150px;
  max-width: 150px;
  max-height: 150px;
  
  /* Custom colors */
  background: #your-color;
  color: #your-text-color;
  
  /* Custom border */
  border: 2px solid #your-border-color;
}
```

## Migration from Legacy Tooltips

Replace your existing tooltip usage:

```tsx
// Old way
<Tooltip content="Some text">
  <button>Click me</button>
</Tooltip>

// New way
<CircularTooltip label="Some text">
  <button>Click me</button>
</CircularTooltip>
```

## Benefits over Manual CSS

1. **No more sizing issues**: Floating UI handles all positioning automatically
2. **Viewport awareness**: Tooltips never go off-screen
3. **Accessibility built-in**: Proper ARIA attributes and keyboard support
4. **Performance optimized**: Uses efficient positioning algorithms
5. **Maintainable**: No need to manually calculate positions or handle edge cases

## Browser Support

- Chrome 88+
- Firefox 85+
- Safari 14+
- Edge 88+

## Dependencies

- `@floating-ui/react` - For positioning and interactions
- React 18+ - For hooks and components
