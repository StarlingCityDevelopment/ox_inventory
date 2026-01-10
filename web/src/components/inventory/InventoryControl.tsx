import React, { useRef, useState } from 'react';
import { useDrop } from 'react-dnd';
import { useAppDispatch, useAppSelector } from '../../store';
import { selectLeftInventory, selectItemAmount, setItemAmount } from '../../store/inventory';
import { DragSource } from '../../typings';
import { onUse } from '../../dnd/onUse';
import { onGive } from '../../dnd/onGive';
import { Locale } from '../../store/locale';
import bag from '../../assets/bag.png';
import { onRename } from '../../dnd/onRename';
import QuantityModal from '../utils/QuantityModal';

const InventoryControl: React.FC = () => {
  const itemAmount = useAppSelector(selectItemAmount);
  const leftInventory = useAppSelector(selectLeftInventory);
  const contextMenuItem = useAppSelector((state) => state.contextMenu.item);
  const dispatch = useAppDispatch();

  const [amountModalItem, setAmountModalItem] = useState<DragSource['item'] | null>(null);
  const [amountModalMax, setAmountModalMax] = useState(1);
  const [amountModalInitial, setAmountModalInitial] = useState(1);

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
            <button className="inventory-control-button" ref={refUse}>
              {Locale.ui_use || 'Use'}
            </button>
            <button className="inventory-control-button" ref={refGive} type="button" onMouseDown={handleGiveClick}>
              {Locale.ui_give || 'Give'}
            </button>
            <button className="inventory-control-button" ref={refRename}>
              {Locale.ui_rename || 'Rename'}
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
