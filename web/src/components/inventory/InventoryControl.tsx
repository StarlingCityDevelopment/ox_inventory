import React, { useState, useRef, useEffect } from 'react';
import { useDrop } from 'react-dnd';
import { useAppDispatch, useAppSelector } from '../../store';
import { selectLeftInventory, selectItemAmount, setItemAmount } from '../../store/inventory';
import { DragSource } from '../../typings';
import { onUse } from '../../dnd/onUse';
import { onGive } from '../../dnd/onGive';
import { fetchNui } from '../../utils/fetchNui';
import { Locale } from '../../store/locale';
import bag from '../../assets/bag.png';
import { onRename } from '../../dnd/onRename';
import QuantityModal from '../utils/QuantityModal';

const formatAmount = (n: number) => (n > 0 ? n.toLocaleString('en-US') : '0');
const digitsOnly = (s: string) => s.replace(/\D/g, '');
const countDigitsBefore = (s: string, index: number) => digitsOnly(s.substring(0, index)).length;

const InventoryControl: React.FC = () => {
  const itemAmount = useAppSelector(selectItemAmount);
  const leftInventory = useAppSelector(selectLeftInventory);
  const contextMenuItem = useAppSelector((state) => state.contextMenu.item);
  const dispatch = useAppDispatch();

  const [amountModalItem, setAmountModalItem] = useState<DragSource['item'] | null>(null);
  const [amountModalMax, setAmountModalMax] = useState(1);
  const [amountModalInitial, setAmountModalInitial] = useState(1);
  const [value, setValue] = useState(formatAmount(itemAmount));
  const inputRef = useRef<HTMLInputElement>(null);
  const cursorRef = useRef<number | null>(null);

  const closeAmountModal = () => {
    setAmountModalItem(null);
    setAmountModalMax(1);
    setAmountModalInitial(1);
  };

  const openGiveAmountModal = (item: DragSource['item']) => {
    const sourceSlot = leftInventory.items[item.slot - 1];
    const max = Math.max(1, sourceSlot?.count ?? 1);

    if (max <= 1) {
      dispatch(setItemAmount(1));
      onGive(item);
      return;
    }

    const preferred = itemAmount > 0 ? Math.min(itemAmount, max) : 1;
    setAmountModalItem(item);
    setAmountModalMax(max);
    setAmountModalInitial(preferred);
  };

  const handleGiveClick = () => {
    if (!contextMenuItem) return;
    openGiveAmountModal({ slot: contextMenuItem.slot, name: contextMenuItem.name });
  };

  const refUse = useRef<HTMLButtonElement>(null);
  const [, useConnector] = useDrop<DragSource, void, any>(() => ({
    accept: 'SLOT',
    drop: (source) => {
      source.inventory === 'player' && onUse(source.item);
    },
  }));
  useConnector(refUse);

  const refGive = useRef<HTMLButtonElement>(null);
  const [, giveConnector] = useDrop<DragSource, void, any>(() => ({
    accept: 'SLOT',
    drop: (source) => {
      source.inventory === 'player' && openGiveAmountModal(source.item);
    },
  }));
  giveConnector(refGive);

  const refRename = useRef<HTMLButtonElement>(null);
  const [, renameConnector] = useDrop<DragSource, void, any>(() => ({
    accept: 'SLOT',
    drop: (source) => {
      if (source.item) {
        onRename(source.item);
      }
    },
  }));
  renameConnector(refRename);

  const commitValue = (raw: string, cursorIndex: number) => {
    const digitsBefore = countDigitsBefore(raw, cursorIndex);
    const num = parseInt(digitsOnly(raw), 10) || 0;

    setValue(formatAmount(num));
    dispatch(setItemAmount(num));
    cursorRef.current = digitsBefore;
  };

  const handleChange = (event: React.ChangeEvent<HTMLInputElement>) =>
    commitValue(event.target.value, event.target.selectionStart ?? 0);

  const handleKeyDown = (event: React.KeyboardEvent<HTMLInputElement>) => {
    const el = event.currentTarget;
    const pos = el.selectionStart ?? 0;

    if (pos !== el.selectionEnd) return;

    if (event.key === 'Backspace' && el.value[pos - 1] === ',') {
      event.preventDefault();
      commitValue(el.value.slice(0, pos - 2) + el.value.slice(pos), pos - 2);
    } else if (event.key === 'Delete' && el.value[pos] === ',') {
      event.preventDefault();
      commitValue(el.value.slice(0, pos) + el.value.slice(pos + 2), pos);
    }
  };

  useEffect(() => {
    if (!inputRef.current || cursorRef.current === null) return;
    let newPos = 0;
    let count = 0;

    for (let i = 0; i < value.length && count < cursorRef.current; i++) {
      if (/\d/.test(value[i])) count++;
      newPos++;
    }

    inputRef.current.setSelectionRange(newPos, newPos);
    cursorRef.current = null;
  }, [value]);

  return (
    <>
      <div className="hotinventory-grid-wrapper">
        <div className="label-container">
          <img src={bag} alt="" />
          <p>ACTIONS</p>
        </div>
        <div className="line-actions"></div>
        <div className="inventory-control">
          <div className="inventory-control-wrapper">
            <input
              className="inventory-control-input"
              type="text"
              ref={inputRef}
              value={value}
              onChange={handleChange}
              onKeyDown={handleKeyDown}
              min={0}
            />
            <button className="inventory-control-button" ref={refUse}>
              {Locale.ui_use || 'Use'}
            </button>
            <button className="inventory-control-button" ref={refGive} type="button" onMouseDown={handleGiveClick}>
              {Locale.ui_give || 'Give'}
            </button>
            <button className="inventory-control-button" ref={refRename}>
              {Locale.ui_rename || 'Rename'}
            </button>
          <button className="inventory-control-button" onClick={() => fetchNui('exit')}>
            {Locale.ui_close || 'Close'}
          </button>
          </div>
        </div>
      </div>
      <QuantityModal
        open={amountModalItem !== null}
        max={amountModalMax}
        initialValue={amountModalInitial}
        title={Locale.ui_quantity || 'Quantity'}
        cancelLabel={Locale.ui_cancel || 'Cancel'}
        confirmLabel={Locale.ui_confirm || 'Confirm'}
        onCancel={closeAmountModal}
        onConfirm={(value) => {
          if (!amountModalItem) return;
          dispatch(setItemAmount(value));
          onGive(amountModalItem);
          closeAmountModal();
        }}
      />
    </>
  );
};

export default InventoryControl;
