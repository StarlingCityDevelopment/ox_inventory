import React, { useEffect, useMemo, useRef, useState } from 'react';
import { FloatingOverlay, FloatingPortal } from '@floating-ui/react';

type QuantityModalProps = {
  open: boolean;
  max: number;
  initialValue?: number;
  title: string;
  cancelLabel: string;
  confirmLabel: string;
  onCancel: () => void;
  onConfirm: (value: number) => void;
};

const QuantityModal: React.FC<QuantityModalProps> = ({
  open,
  max,
  initialValue,
  title,
  cancelLabel,
  confirmLabel,
  onCancel,
  onConfirm,
}) => {
  const rangeRef = useRef<HTMLInputElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);
  const normalizedMax = useMemo(() => Math.max(1, Math.floor(max || 1)), [max]);
  const [value, setValue] = useState(1);

  const resolvedValue = useMemo(() => {
    const clamped = Math.max(1, Math.min(normalizedMax, Math.floor(value || 1)));
    return Number.isFinite(clamped) ? clamped : 1;
  }, [normalizedMax, value]);

  useEffect(() => {
    if (!open) return;

    const next = initialValue !== undefined ? initialValue : 1;
    const clamped = Math.max(1, Math.min(normalizedMax, Math.floor(next || 1)));
    setValue(Number.isFinite(clamped) ? clamped : 1);
    queueMicrotask(() => rangeRef.current?.focus());
  }, [open, initialValue, normalizedMax]);

  useEffect(() => {
    if (!open) return;

    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') onCancel();
    };

    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [open, onCancel]);

  if (!open) return null;

  return (
    <FloatingPortal>
      <FloatingOverlay
        lockScroll
        className="amount-modal-overlay"
        onMouseDown={(event) => {
          if (event.target === event.currentTarget) onCancel();
        }}
      >
        <div className="amount-modal" role="dialog" aria-modal="true">
          <div className="amount-modal-title">{title}</div>
          <div className="amount-modal-value">
            <input
              ref={inputRef}
              type="number"
              min={1}
              max={normalizedMax}
              value={resolvedValue}
              onChange={(event) => setValue(Number(event.target.value))}
              onKeyDown={(event) => {
                if (event.key === 'Enter') onConfirm(resolvedValue);
              }}
              className="amount-modal-input"
            />
            / {normalizedMax}
          </div>
          <input
            className="amount-modal-range"
            ref={rangeRef}
            type="range"
            min={1}
            max={normalizedMax}
            step={1}
            value={resolvedValue}
            onChange={(event) => setValue(Number(event.target.value))}
            onKeyDown={(event) => {
              if (event.key === 'Enter') onConfirm(resolvedValue);
            }}
          />
          <div className="amount-modal-actions">
            <button className="amount-modal-button" type="button" onMouseDown={onCancel}>
              {cancelLabel}
            </button>
            <button className="amount-modal-button" type="button" onMouseDown={() => onConfirm(resolvedValue)}>
              {confirmLabel}
            </button>
          </div>
        </div>
      </FloatingOverlay>
    </FloatingPortal>
  );
};

export default QuantityModal;
