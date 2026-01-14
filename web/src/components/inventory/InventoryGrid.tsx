import React, { useEffect, useMemo, useRef, useState } from 'react';
import { Inventory, SlotWithItem } from '../../typings';
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
  // Implements: IDEA-05 – Add sorting controls for inventory grid.
  const [sortBy, setSortBy] = useState('slot');
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
  }, [
    inventory.items,
    search,
    typeFilter,
    rarityFilter,
    minWeight,
    maxWeight,
    favoritesOnly,
    favorites,
    filtersActive,
  ]);

  const sortedItems = useMemo(() => {
    if (sortBy === 'slot') return filteredItems;

    const itemsWith = filteredItems.filter(isSlotWithItem);
    const emptyItems = filteredItems.filter((slot) => !isSlotWithItem(slot));

    const labelFor = (slot: SlotWithItem) => slot.metadata?.label || Items[slot.name]?.label || slot.name;
    const rarityFor = (slot: SlotWithItem) => slot.metadata?.rarity;

    const compare = (a: SlotWithItem, b: SlotWithItem) => {
      switch (sortBy) {
        case 'name-asc':
          return labelFor(a).localeCompare(labelFor(b));
        case 'name-desc':
          return labelFor(b).localeCompare(labelFor(a));
        case 'weight-asc':
          return (a.weight ?? 0) - (b.weight ?? 0);
        case 'weight-desc':
          return (b.weight ?? 0) - (a.weight ?? 0);
        case 'rarity-asc': {
          const rarityA = rarityFor(a);
          const rarityB = rarityFor(b);
          if (rarityA === undefined && rarityB === undefined) return 0;
          if (rarityA === undefined) return 1;
          if (rarityB === undefined) return -1;
          const numA = typeof rarityA === 'number' ? rarityA : Number(rarityA);
          const numB = typeof rarityB === 'number' ? rarityB : Number(rarityB);
          if (!Number.isNaN(numA) && !Number.isNaN(numB)) return numA - numB;
          return String(rarityA).localeCompare(String(rarityB));
        }
        case 'rarity-desc': {
          const rarityA = rarityFor(a);
          const rarityB = rarityFor(b);
          if (rarityA === undefined && rarityB === undefined) return 0;
          if (rarityA === undefined) return 1;
          if (rarityB === undefined) return -1;
          const numA = typeof rarityA === 'number' ? rarityA : Number(rarityA);
          const numB = typeof rarityB === 'number' ? rarityB : Number(rarityB);
          if (!Number.isNaN(numA) && !Number.isNaN(numB)) return numB - numA;
          return String(rarityB).localeCompare(String(rarityA));
        }
        default:
          return 0;
      }
    };

    return [...itemsWith].sort(compare).concat(emptyItems);
  }, [filteredItems, sortBy]);

  useEffect(() => {
    if (entry && entry.isIntersecting) {
      setPage((prev) => ++prev);
    }
  }, [entry]);

  useEffect(() => {
    setPage(0);
  }, [inventory.id, search, typeFilter, rarityFilter, minWeight, maxWeight, favoritesOnly, sortBy]);

  return (
    <>
      <div className="inventory-grid-wrapper" style={{ pointerEvents: isBusy ? 'none' : 'auto' }}>
        <div>
          <div className="inventory-grid-header-wrapper">
            <p data-title="name">{inventory.label}</p>
            {inventory.maxWeight && (
              <p data-title="weight">
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
            {/* <select
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
            /> */}
            <select
              aria-label="Sort items"
              className="inventory-filter-select inventory-filter-icon"
              data-icon="sort"
              title="Sort items"
              value={sortBy}
              onChange={(event) => setSortBy(event.target.value)}
            >
              <option value="slot">Sort</option>
              <option value="name-asc">Name (A-Z)</option>
              <option value="name-desc">Name (Z-A)</option>
              <option value="weight-asc">Weight (Low-High)</option>
              <option value="weight-desc">Weight (High-Low)</option>
              <option value="rarity-asc">Rarity (Low-High)</option>
              <option value="rarity-desc">Rarity (High-Low)</option>
            </select>
            {(favorites.length > 0 && (
              <button
                aria-label="Favorites only"
                className={`inventory-filter-favorite ${favoritesOnly ? 'is-active' : ''}`}
                onClick={() => setFavoritesOnly((prev) => !prev)}
                title="Favorites only"
                type="button"
              >
                ★
              </button>
            )) || (
              <button
                disabled={true}
                aria-label="Favorites only"
                className={`inventory-filter-favorite ${favoritesOnly && favorites.length > 1 ? 'is-active' : ''}`}
                onClick={() => setFavoritesOnly((prev) => !prev)}
                title="Favorites only"
                type="button"
                style={{ pointerEvents: favorites.length >= 1 ? 'inherit' : 'none' }}
              >
                ★
              </button>
            )}
          </div>
          <WeightBar percent={inventory.maxWeight ? (weight / inventory.maxWeight) * 100 : 0} />
        </div>
        <div className="inventory-grid-container" ref={containerRef}>
          <>
            {sortedItems.slice(0, (page + 1) * PAGE_SIZE).map((item, index) => (
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
