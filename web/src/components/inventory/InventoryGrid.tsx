import React, { useEffect, useMemo, useRef, useState } from 'react';
import { Inventory } from '../../typings';
import InventorySlot from './InventorySlot';
import { getTotalWeight } from '../../helpers';
import { useAppSelector } from '../../store';
import bag from '../../assets/bag.png';
import weights from '../../assets/weight.png';

const PAGE_SIZE = 40;

const InventoryGrid: React.FC<{ inventory: Inventory }> = ({ inventory }) => {
  const weight = useMemo(
    () => (inventory.maxWeight !== undefined ? Math.floor(getTotalWeight(inventory.items) * 1000) / 1000 : 0),
    [inventory.maxWeight, inventory.items]
  );

  const [page, setPage] = useState(0);
  const containerRef = useRef<HTMLDivElement | null>(null);
  const sentinelRef = useRef<HTMLDivElement | null>(null);
  const isBusy = useAppSelector((state) => state.inventory.isBusy);

  useEffect(() => {
    setPage(0);
  }, [inventory.id, inventory.items.length]);

  useEffect(() => {
    const container = containerRef.current;
    const sentinel = sentinelRef.current;
    if (!container || !sentinel) return;

    const startIndex = inventory.type === 'player' ? 5 : 0;
    const totalAvailable = Math.max(inventory.items.length - startIndex, 0);
    if ((page + 1) * PAGE_SIZE >= totalAvailable) return;

    const observer = new IntersectionObserver(
      (entries) => {
        const first = entries[0];
        if (first.isIntersecting) {
          setPage((p) => p + 1);
        }
      },
      { root: container, threshold: 0.1 }
    );

    observer.observe(sentinel);
    return () => observer.disconnect();
  }, [page, inventory.items.length, inventory.type]);

  return (
    <>
      <div className="inventory-grid-wrapper" style={{ pointerEvents: isBusy ? 'none' : 'auto' }}>
        <div>
          <div className="inventory-grid-header-wrapper">
            <div className="label-container">
              <img src={bag} alt="" />
              <p>{inventory.label}</p>
            </div>
            {inventory.maxWeight && (
              <div className="weight-container">
                <img src={weights} alt="" />
                <p>
                  {(weight / 1000).toFixed(2)}/{inventory.maxWeight / 1000}kg
                </p>
              </div>
            )}
          </div>
        </div>
        <div
          className={inventory.type == 'player' ? 'inventory-grid-container' : 'secinventory-grid-container'}
          ref={containerRef}
        >
          <>
            {(() => {
              const start = inventory.type == 'player' ? 5 : 0;
              const end = start + (page + 1) * PAGE_SIZE;
              return inventory.items.slice(start, end).map((item) => (
                <InventorySlot
                  key={`${inventory.type}-${inventory.id}-${item.slot}`}
                  item={item}
                  inventoryType={inventory.type}
                  inventoryGroups={inventory.groups}
                  inventoryId={inventory.id}
                />
              ));
            })()}
            <div ref={sentinelRef} style={{ width: '100%', height: 1 }} />
          </>
        </div>
      </div>
    </>
  );
};

export default InventoryGrid;
