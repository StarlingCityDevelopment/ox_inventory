import React, { useEffect, useMemo, useRef, useState } from 'react';
import { Inventory } from '../../typings';
import WeightBar from '../utils/WeightBar';
import InventorySlot from './InventorySlot';
import { getTotalWeight } from '../../helpers';
import { useAppSelector } from '../../store';
import { useIntersection } from '../../hooks/useIntersection';

const PAGE_SIZE = 50;

const InventoryGrid: React.FC<{ inventory: Inventory }> = ({ inventory }) => {
  const weight = useMemo(
    () => (inventory.maxWeight !== undefined ? Math.floor(getTotalWeight(inventory.items) * 1000) / 1000 : 0),
    [inventory.maxWeight, inventory.items]
  );

  const [page, setPage] = useState(0);
  const containerRef = useRef<HTMLDivElement>(null);
  const { ref: sentinelRef, entry } = useIntersection({
    root: containerRef.current,
    threshold: 0.1,
  });
  const isBusy = useAppSelector((state) => state.inventory.isBusy);

  const itemsToDisplay = useMemo(() => {
    return inventory.items.slice(inventory.type === 'player' ? 5 : 0, (page + 1) * PAGE_SIZE);
  }, [inventory.items, inventory.type, page]);

  useEffect(() => {
    if (entry && entry.isIntersecting) setPage((prev) => prev + 1);
  }, [entry]);

  return (
    <>
      <div className="inventory-grid-wrapper" style={{ pointerEvents: isBusy ? 'none' : 'auto' }}>
        <>
          <div>
            <div className="inventory-grid-header-wrapper">
              <p>{inventory.label}</p>
              {inventory.type != 'shop' && inventory.type != 'crafting' && (
                <>
                  {inventory.maxWeight && (
                    <p>
                      {weight / 1000}/{inventory.maxWeight / 1000}kg
                    </p>
                  )}
                </>
              )}
            </div>
            {inventory.type != 'shop' && inventory.type != 'crafting' && (
              <WeightBar percent={inventory.maxWeight ? (weight / inventory.maxWeight) * 100 : 0} />
            )}
          </div>
        </>
        <div className="inventory-grid-container" ref={containerRef}>
          <>
            {itemsToDisplay.map((item, index) => (
              <InventorySlot
                key={`${inventory.type}-${inventory.id}-${item.slot}`}
                item={item}
                ref={index === (page + 1) * PAGE_SIZE - 1 ? sentinelRef : null}
                inventoryType={inventory.type}
                inventoryGroups={inventory.groups}
                inventoryId={inventory.id}
              />
            ))}
            <div ref={sentinelRef} style={{ height: '1px' }} />
          </>
        </div>
      </div>
      {inventory.type === 'player' && <div className="inventory-fast-grid">
        <>
          {inventory.items.slice(0, 5).map((item, index) => (
            <InventorySlot
              key={`${inventory.type}-${inventory.id}-${item.slot}`}
              item={item}
              ref={null}
              inventoryType={inventory.type}
              inventoryGroups={inventory.groups}
              inventoryId={inventory.id}
            />
          ))}
        </>
      </div>}
    </>
  );
};

export default InventoryGrid;
