import { createSlice, PayloadAction } from '@reduxjs/toolkit';

const STORAGE_KEY = 'ox_inventory_favorites';

const loadFavorites = () => {
  if (typeof window === 'undefined') return [];

  try {
    const raw = window.localStorage.getItem(STORAGE_KEY);
    if (!raw) return [];
    const data = JSON.parse(raw);
    return Array.isArray(data) ? data.filter((entry) => typeof entry === 'string') : [];
  } catch {
    return [];
  }
};

type FavoritesState = {
  items: string[];
};

const initialState: FavoritesState = {
  items: loadFavorites(),
};

const favoritesSlice = createSlice({
  name: 'favorites',
  initialState,
  reducers: {
    toggleFavorite(state, action: PayloadAction<string>) {
      const itemName = action.payload;
      if (!itemName) return;
      const index = state.items.indexOf(itemName);
      if (index === -1) {
        state.items.push(itemName);
      } else {
        state.items.splice(index, 1);
      }
    },
    setFavorites(state, action: PayloadAction<string[]>) {
      state.items = action.payload;
    },
  },
});

export const favoritesStorageKey = STORAGE_KEY;
export const { toggleFavorite, setFavorites } = favoritesSlice.actions;
export default favoritesSlice.reducer;
