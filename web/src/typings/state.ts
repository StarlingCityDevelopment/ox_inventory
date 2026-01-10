import { Inventory } from './inventory';
import { DragSource, DropTarget } from './dnd';

export type State = {
  leftInventory: Inventory;
  rightInventory: Inventory;
  clothesInventory: Inventory;
  itemAmount: number;
  shiftPressed: boolean;
  isBusy: boolean;
  additionalMetadata: Array<{ metadata: string; value: string }>;
  history?: {
    leftInventory: Inventory;
    rightInventory: Inventory;
    clothesInventory: Inventory;
  };
  quantityModal?: {
    open: boolean;
    source: DragSource;
    target?: DropTarget;
    max: number;
    mode?: string;
  };
};
