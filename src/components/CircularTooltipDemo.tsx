import React from 'react';
import { CircularTooltip } from './CircularTooltip';

export const CircularTooltipDemo: React.FC = () => {
  return (
    <div style={{ padding: '20px', display: 'flex', gap: '20px', flexWrap: 'wrap' }}>
      <h3>Circular Tooltip Demo</h3>
      
      <div style={{ display: 'flex', gap: '10px', alignItems: 'center' }}>
        <CircularTooltip label="Info" placement="top">
          <button style={{ padding: '8px 16px', borderRadius: '6px', border: '1px solid #ccc' }}>
            Hover me (top)
          </button>
        </CircularTooltip>

        <CircularTooltip label="Help" placement="bottom">
          <button style={{ padding: '8px 16px', borderRadius: '6px', border: '1px solid #ccc' }}>
            Hover me (bottom)
          </button>
        </CircularTooltip>

        <CircularTooltip label="Question" placement="left">
          <button style={{ padding: '8px 16px', borderRadius: '6px', border: '1px solid #ccc' }}>
            Hover me (left)
          </button>
        </CircularTooltip>

        <CircularTooltip label="Note" placement="right">
          <button style={{ padding: '8px 16px', borderRadius: '6px', border: '1px solid #ccc' }}>
            Hover me (right)
          </button>
        </CircularTooltip>
      </div>

      <div style={{ marginTop: '20px' }}>
        <CircularTooltip label="Information">
          <span style={{ color: 'blue', textDecoration: 'underline', cursor: 'pointer' }}>
            Info tooltip
          </span>
        </CircularTooltip>
      </div>
    </div>
  );
};
