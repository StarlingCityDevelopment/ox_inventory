import React from 'react';
import { Inventory } from '../../typings';
import InventoryClothesSlot from './InventoryClothesSlot';
import { useAppSelector } from '../../store';

const images: Record<string, string> = {
  'clothes-1': 'https://files.fivemerr.com/images/9489297c-a8f4-4f42-ae44-1322e8b78a2c.webp',
  'clothes-2': 'https://files.fivemerr.com/images/c44090d2-db9a-4713-b3d3-c556287b66db.webp',
  'clothes-3': 'https://files.fivemerr.com/images/7ac9cc80-14ab-4d33-a3d8-7a5c807520b3.webp',
  'clothes-4': 'https://files.fivemerr.com/images/46e9253c-865d-4979-9ee9-5bbb46602ba2.webp',
  'clothes-5': 'https://files.fivemerr.com/images/f1f6b3ee-36cf-4d3c-9fb1-6e0ad79c4a6d.webp',
  'clothes-6': 'https://files.fivemerr.com/images/227d190d-5e8f-4a1f-a860-dca866be4c32.webp',
  'clothes-7': 'https://files.fivemerr.com/images/6617649c-101a-4ed1-9c46-0d3755320a79.webp',
  'clothes-8': '',

  'clothes-9': 'https://files.fivemerr.com/images/abb6f377-bf17-4b04-9160-5d517c5876e6.webp',
  'clothes-10': 'https://files.fivemerr.com/images/2ca43f9c-3160-4caa-91d0-d1f5b7c28380.webp',
  'clothes-11': 'https://files.fivemerr.com/images/ef16a1f8-2e2a-4e19-9554-6de1edc080e6.webp',
  'clothes-12': 'https://files.fivemerr.com/images/a65dc382-f7da-4317-8448-b12a918dae04.webp',
  'clothes-13': 'https://files.fivemerr.com/images/04ee5b64-5d51-4bd3-bf11-1675c6c314b8.webp',
  'clothes-14': 'https://files.fivemerr.com/images/d2cf1efd-ba3a-423b-b91f-5f6c7fe2bd42.webp',
  'clothes-15': 'https://files.fivemerr.com/images/b2d4dca4-1eca-4ec8-b218-b2466b241a6b.webp',
  'clothes-16': 'https://files.fivemerr.com/images/697de83e-06d9-4fbf-906e-bb26b7403fbe.webp',
};

const InventoryClothesGrid: React.FC<{ inventory: Inventory }> = ({ inventory }) => {
  const isBusy = useAppSelector((state) => state.inventory.isBusy);

  return (
    <>
      <div className="inventory-clothes-wrapper" style={{ pointerEvents: isBusy ? 'none' : 'auto' }}>
        <div className="inventory-clothes-container">
          <>
            {inventory.items.slice(0, 7).map((item) => (
              <InventoryClothesSlot
                key={`${inventory.type}-${inventory.id}-${item.slot}`}
                item={item}
                inventoryType={inventory.type}
                inventoryGroups={inventory.groups}
                inventoryId={inventory.id}
                default={images[`${inventory.type}-${item.slot}`]}
              />
            ))}
            {inventory.items.slice(7, 8).map((item) => (
              <InventoryClothesSlot
                key={`${inventory.type}-${inventory.id}-${item.slot}`}
                item={item}
                inventoryType={inventory.type}
                inventoryGroups={inventory.groups}
                inventoryId={inventory.id}
                default={images[`${inventory.type}-${item.slot}`]}
              />
            ))}
          </>
        </div>
        <div className="inventory-clothes-container">
          <>
            {inventory.items.slice(8, 16).map((item) => (
              <InventoryClothesSlot
                key={`${inventory.type}-${inventory.id}-${item.slot}`}
                item={item}
                inventoryType={inventory.type}
                inventoryGroups={inventory.groups}
                inventoryId={inventory.id}
                default={images[`${inventory.type}-${item.slot}`]}
              />
            ))}
          </>
        </div>
      </div>
    </>
  );
};

export default InventoryClothesGrid;
