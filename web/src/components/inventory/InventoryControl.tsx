import React, { useRef } from 'react';
import { useDrop } from 'react-dnd';
import { useAppDispatch, useAppSelector } from '../../store';
import { selectItemAmount, setItemAmount } from '../../store/inventory';
import { DragSource } from '../../typings';
import { onUse } from '../../dnd/onUse';
import { onGive } from '../../dnd/onGive';
import { Locale } from '../../store/locale';
import bag from '../../assets/bag.png';
import { onRename } from '../../dnd/onRename';

const InventoryControl: React.FC = () => {
  const itemAmount = useAppSelector(selectItemAmount);
  const dispatch = useAppDispatch();

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
      source.inventory === 'player' && onGive(source.item);
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

  const inputHandler = (event: React.ChangeEvent<HTMLInputElement>) => {
    event.target.valueAsNumber =
      isNaN(event.target.valueAsNumber) || event.target.valueAsNumber < 0 ? 0 : Math.floor(event.target.valueAsNumber);
    dispatch(setItemAmount(event.target.valueAsNumber));
  };

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
              type="number"
              defaultValue={itemAmount}
              onChange={inputHandler}
              min={0}
            />
            <button className="inventory-control-button" ref={refUse}>
              {Locale.ui_use || 'Use'}
            </button>
            <button className="inventory-control-button" ref={refGive}>
              {Locale.ui_give || 'Give'}
            </button>
            <button className="inventory-control-button" ref={refRename}>
              {Locale.ui_rename || 'Rename'}
            </button>
          </div>
        </div>
      </div>
    </>
  );
};

export default InventoryControl;
