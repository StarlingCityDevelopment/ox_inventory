import { CaseReducer, PayloadAction } from '@reduxjs/toolkit';
import { getItemData, itemDurability } from '../helpers';
import { Items } from '../store/items';
import { Inventory, State } from '../typings';

const setupInventoryItems = (inventory: Inventory, curTime: number) => {
  return Array.from(Array(inventory.slots), (_, index) => {
    const item = Object.values(inventory.items).find((item) => item?.slot === index + 1) || { slot: index + 1 };

    if (!item.name) return item;
    if (typeof Items[item.name] === 'undefined') {
      getItemData(item.name);
    }

    item.durability = itemDurability(item.metadata, curTime);
    return item;
  });
};

export const setupInventoryReducer: CaseReducer<State, PayloadAction<{ leftInventory?: Inventory; clothesInventory?: Inventory; rightInventory?: Inventory; }>> = (state, action) => {
  const { leftInventory, clothesInventory, rightInventory } = action.payload;
  const curTime = Math.floor(Date.now() / 1000);

  if (leftInventory) state.leftInventory = { ...leftInventory, items: setupInventoryItems(leftInventory, curTime) };
  if (clothesInventory) state.clothesInventory = { ...clothesInventory, items: setupInventoryItems(clothesInventory, curTime) };
  if (rightInventory) state.rightInventory = { ...rightInventory, items: setupInventoryItems(rightInventory, curTime) };

  state.shiftPressed = false;
  state.isBusy = false;
};
