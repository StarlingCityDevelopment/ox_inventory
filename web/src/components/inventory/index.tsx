import React, { useState } from 'react';
import useNuiEvent from '../../hooks/useNuiEvent';
import InventoryControl from './InventoryControl';
import InventoryHotbar from './InventoryHotbar';
import { useAppDispatch, useAppSelector } from '../../store';
import { refreshSlots, setAdditionalMetadata, setupInventory, selectQuantityModal, closeQuantityModal, setItemAmount } from '../../store/inventory';
import { useExitListener } from '../../hooks/useExitListener';
import type { Inventory as InventoryProps } from '../../typings';
import RightInventory from './RightInventory';
import LeftInventory from './LeftInventory';
import Tooltip from '../utils/Tooltip';
import { closeTooltip } from '../../store/tooltip';
import InventoryContext from './InventoryContext';
import { closeContextMenu } from '../../store/contextMenu';
import Fade from '../utils/transitions/Fade';
import HotInventory from './HotInventory';
import ClothesInventory from './ClothesInventory';
import QuantityModal from '../utils/QuantityModal';
import { Locale } from '../../store/locale';
import { onDrop } from '../../dnd/onDrop';

const Inventory: React.FC = () => {
  const [inventoryVisible, setInventoryVisible] = useState(false);
  const dispatch = useAppDispatch();
  const quantityModal = useAppSelector(selectQuantityModal);

  useNuiEvent<boolean>('setInventoryVisible', setInventoryVisible);
  useNuiEvent<false>('closeInventory', () => {
    setInventoryVisible(false);
    dispatch(closeContextMenu());
    dispatch(closeTooltip());
  });
  useExitListener(setInventoryVisible);

  useNuiEvent<{
    leftInventory?: InventoryProps;
    clothesInventory?: InventoryProps;
    rightInventory?: InventoryProps;
  }>('setupInventory', (data) => {
    dispatch(setupInventory(data));
    !inventoryVisible && setInventoryVisible(true);
  });

  useNuiEvent('refreshSlots', (data) => dispatch(refreshSlots(data)));

  useNuiEvent('displayMetadata', (data: Array<{ metadata: string; value: string }>) => {
    dispatch(setAdditionalMetadata(data));
  });

  return (
    <>
      <Fade in={inventoryVisible}>
        <div className="inventory-wrapper">
          <div className="playerinventory">
            <div className='playerinventory-wrapper'>
              <LeftInventory />
              <HotInventory />
            </div>
          </div>
          <ClothesInventory />
          <div className="secondaryinventory">
            <div className='secondaryinventory-wrapper'>
              <RightInventory />
              <InventoryControl />
            </div>
          </div>
          <Tooltip />
          <InventoryContext />
        </div>
      </Fade>
      <InventoryHotbar />
      <QuantityModal
        open={!!quantityModal?.open}
        max={quantityModal?.max || 1}
        initialValue={1}
        title={Locale.ui_quantity || 'Quantity'}
        cancelLabel={Locale.ui_cancel || 'Cancel'}
        confirmLabel={Locale.ui_confirm || 'Confirm'}
        onCancel={() => dispatch(closeQuantityModal())}
        onConfirm={(value) => {
          if (!quantityModal) return;
          dispatch(setItemAmount(value));
          onDrop(quantityModal.source, quantityModal.target);
          dispatch(setItemAmount(0));
          dispatch(closeQuantityModal());
        }}
      />
    </>
  );
};

export default Inventory;
