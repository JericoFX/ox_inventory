import React, { useEffect, useMemo, useRef, useState } from 'react';
import { Inventory } from '../../typings';
import WeightBar from '../utils/WeightBar';
import InventorySlot from './InventorySlot';
import { getTotalWeight, isSlotWithItem } from '../../helpers';
import { useAppSelector } from '../../store';
import { Items } from '../../store/items';
import { useIntersection } from '../../hooks/useIntersection';

const PAGE_SIZE = 30;

const InventoryGrid: React.FC<{ inventory: Inventory }> = ({ inventory }) => {
  const weight = useMemo(
    () => (inventory.maxWeight !== undefined ? Math.floor(getTotalWeight(inventory.items) * 1000) / 1000 : 0),
    [inventory.maxWeight, inventory.items]
  );
  const [page, setPage] = useState(0);
  const [search, setSearch] = useState('');
  const [typeFilter, setTypeFilter] = useState('all');
  const [rarityFilter, setRarityFilter] = useState('all');
  const [minWeight, setMinWeight] = useState('');
  const [maxWeight, setMaxWeight] = useState('');
  const [favoritesOnly, setFavoritesOnly] = useState(false);
  const containerRef = useRef(null);
  const { ref, entry } = useIntersection({ threshold: 0.5 });
  const isBusy = useAppSelector((state) => state.inventory.isBusy);
  const favorites = useAppSelector((state) => state.favorites.items);

  const rarityOptions = useMemo(() => {
    const values = new Set<string>();
    for (const slot of inventory.items) {
      if (slot.metadata?.rarity !== undefined) {
        values.add(String(slot.metadata.rarity));
      }
    }
    return Array.from(values).sort();
  }, [inventory.items]);

  const filtersActive =
    search.trim().length > 0 ||
    typeFilter !== 'all' ||
    rarityFilter !== 'all' ||
    minWeight.trim().length > 0 ||
    maxWeight.trim().length > 0 ||
    favoritesOnly;

  const filteredItems = useMemo(() => {
    const searchValue = search.trim().toLowerCase();
    const minWeightValue = minWeight ? Number(minWeight) : undefined;
    const maxWeightValue = maxWeight ? Number(maxWeight) : undefined;

    return inventory.items.filter((slot) => {
      if (!isSlotWithItem(slot)) return !filtersActive;

      if (favoritesOnly && !favorites.includes(slot.name)) return false;

      const itemData = Items[slot.name];
      const itemType = itemData?.weapon
        ? 'weapon'
        : itemData?.ammo
        ? 'ammo'
        : itemData?.component
        ? 'component'
        : itemData?.tint
        ? 'tint'
        : 'item';

      if (typeFilter !== 'all' && itemType !== typeFilter) return false;

      if (rarityFilter !== 'all' && String(slot.metadata?.rarity) !== rarityFilter) return false;

      const slotWeight = slot.weight || 0;
      if (!Number.isNaN(minWeightValue) && minWeightValue !== undefined && slotWeight < minWeightValue) return false;
      if (!Number.isNaN(maxWeightValue) && maxWeightValue !== undefined && slotWeight > maxWeightValue) return false;

      if (searchValue.length > 0) {
        const label = slot.metadata?.label || itemData?.label || slot.name;
        if (!label?.toLowerCase().includes(searchValue)) return false;
      }

      return true;
    });
  }, [inventory.items, search, typeFilter, rarityFilter, minWeight, maxWeight, favoritesOnly, favorites, filtersActive]);

  useEffect(() => {
    if (entry && entry.isIntersecting) {
      setPage((prev) => ++prev);
    }
  }, [entry]);

  useEffect(() => {
    setPage(0);
  }, [inventory.id, search, typeFilter, rarityFilter, minWeight, maxWeight, favoritesOnly]);

  return (
    <>
      <div className="inventory-grid-wrapper" style={{ pointerEvents: isBusy ? 'none' : 'auto' }}>
        <div>
          <div className="inventory-grid-header-wrapper">
            <p>{inventory.label}</p>
            {inventory.maxWeight && (
              <p>
                {weight / 1000}/{inventory.maxWeight / 1000}kg
              </p>
            )}
          </div>
          <div className="inventory-grid-filters">
            <input
              aria-label="Search"
              className="inventory-filter-input inventory-filter-icon"
              data-icon="search"
              placeholder="Search"
              title="Search"
              value={search}
              onChange={(event) => setSearch(event.target.value)}
            />
            <select
              aria-label="Type filter"
              className="inventory-filter-select inventory-filter-icon"
              data-icon="type"
              title="Type filter"
              value={typeFilter}
              onChange={(event) => setTypeFilter(event.target.value)}
            >
              <option value="all">All</option>
              <option value="weapon">Weapons</option>
              <option value="ammo">Ammo</option>
              <option value="component">Components</option>
              <option value="tint">Tints</option>
              <option value="item">Other</option>
            </select>
            <select
              aria-label="Rarity filter"
              className="inventory-filter-select inventory-filter-icon"
              data-icon="rarity"
              title="Rarity filter"
              value={rarityFilter}
              onChange={(event) => setRarityFilter(event.target.value)}
              disabled={rarityOptions.length === 0}
            >
              <option value="all">Rarity</option>
              {rarityOptions.map((rarity) => (
                <option key={rarity} value={rarity}>
                  {rarity}
                </option>
              ))}
            </select>
            <input
              aria-label="Minimum weight"
              className="inventory-filter-input inventory-filter-icon"
              data-icon="min-weight"
              placeholder="Min g"
              title="Minimum weight"
              value={minWeight}
              onChange={(event) => setMinWeight(event.target.value)}
              type="number"
              min="0"
            />
            <input
              aria-label="Maximum weight"
              className="inventory-filter-input inventory-filter-icon"
              data-icon="max-weight"
              placeholder="Max g"
              title="Maximum weight"
              value={maxWeight}
              onChange={(event) => setMaxWeight(event.target.value)}
              type="number"
              min="0"
            />
            <button
              aria-label="Favorites only"
              className={`inventory-filter-favorite ${favoritesOnly ? 'is-active' : ''}`}
              onClick={() => setFavoritesOnly((prev) => !prev)}
              title="Favorites only"
              type="button"
            >
              ★
            </button>
          </div>
          <WeightBar percent={inventory.maxWeight ? (weight / inventory.maxWeight) * 100 : 0} />
        </div>
        <div className="inventory-grid-container" ref={containerRef}>
          <>
            {filteredItems.slice(0, (page + 1) * PAGE_SIZE).map((item, index) => (
              <InventorySlot
                key={`${inventory.type}-${inventory.id}-${item.slot}`}
                item={item}
                ref={index === (page + 1) * PAGE_SIZE - 1 ? ref : null}
                inventoryType={inventory.type}
                inventoryGroups={inventory.groups}
                inventoryId={inventory.id}
              />
            ))}
          </>
        </div>
      </div>
    </>
  );
};

export default InventoryGrid;
