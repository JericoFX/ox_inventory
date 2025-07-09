import { createSlice, current, isFulfilled, isPending, isRejected, PayloadAction } from '@reduxjs/toolkit';
import type { RootState } from '.';
import {
  moveSlotsReducer,
  refreshSlotsReducer,
  setupInventoryReducer,
  stackSlotsReducer,
  swapSlotsReducer,
} from '../reducers';
import { State } from '../typings';

const initialState: State = {
  leftInventory: {
    id: '',
    type: '',
    slots: 0,
    maxWeight: 0,
    items: [],
  },
  rightInventory: {
    id: '',
    type: '',
    slots: 0,
    maxWeight: 0,
    items: [],
  },
  additionalMetadata: new Array(),
  itemAmount: 0,
  shiftPressed: false,
  isBusy: false,
  trade: {
    isTrading: false,
    targetPlayer: { id: 0, name: '' },
    playerConfirmed: false,
    targetConfirmed: false,
    playerItems: [],
    targetItems: [],
  },
};

export const inventorySlice = createSlice({
  name: 'inventory',
  initialState,
  reducers: {
    stackSlots: stackSlotsReducer,
    swapSlots: swapSlotsReducer,
    setupInventory: setupInventoryReducer,
    moveSlots: moveSlotsReducer,
    refreshSlots: refreshSlotsReducer,
    setAdditionalMetadata: (state, action: PayloadAction<Array<{ metadata: string; value: string }>>) => {
      const metadata = [];

      for (let i = 0; i < action.payload.length; i++) {
        const entry = action.payload[i];
        if (!state.additionalMetadata.find((el) => el.value === entry.value)) metadata.push(entry);
      }

      state.additionalMetadata = [...state.additionalMetadata, ...metadata];
    },
    setItemAmount: (state, action: PayloadAction<number>) => {
      state.itemAmount = action.payload;
    },
    setShiftPressed: (state, action: PayloadAction<boolean>) => {
      state.shiftPressed = action.payload;
    },
    setContainerWeight: (state, action: PayloadAction<number>) => {
      const container = state.leftInventory.items.find((item) => item.metadata?.container === state.rightInventory.id);

      if (!container) return;

      container.weight = action.payload;
    },
    initTrade: (state, action: PayloadAction<{ targetPlayer: { id: number; name: string }, playerItems: Slot[], targetItems: Slot[] }>) => {
      state.trade = {
        isTrading: true,
        targetPlayer: action.payload.targetPlayer,
        playerConfirmed: false,
        targetConfirmed: false,
        playerItems: action.payload.playerItems,
        targetItems: action.payload.targetItems,
      };
    },
    confirmTrade: (state, action: PayloadAction<{ playerConfirmed: boolean, targetConfirmed: boolean }>) => {
      if (state.trade) {
        state.trade.playerConfirmed = action.payload.playerConfirmed;
        state.trade.targetConfirmed = action.payload.targetConfirmed;

        if (state.trade.playerConfirmed && state.trade.targetConfirmed) {
          // Logic for exchanging items
          const temp = state.trade.playerItems;
          state.trade.playerItems = state.trade.targetItems;
          state.trade.targetItems = temp;
          state.trade.isTrading = false; // End trade
        }
      }
    },
    updateTradeItems: (state, action: PayloadAction<{ playerItems: Slot[], targetItems: Slot[] }>) => {
      if (state.trade) {
        state.trade.playerItems = action.payload.playerItems;
        state.trade.targetItems = action.payload.targetItems;
        // Reset confirmations when items change
        state.trade.playerConfirmed = false;
        state.trade.targetConfirmed = false;
      }
    },
    cancelTrade: (state) => {
      state.trade = {
        isTrading: false,
        targetPlayer: { id: 0, name: '' },
        playerConfirmed: false,
        targetConfirmed: false,
        playerItems: [],
        targetItems: [],
      };
    },
  },
  extraReducers: (builder) => {
    builder.addMatcher(isPending, (state) => {
      state.isBusy = true;

      state.history = {
        leftInventory: current(state.leftInventory),
        rightInventory: current(state.rightInventory),
      };
    });
    builder.addMatcher(isFulfilled, (state) => {
      state.isBusy = false;
    });
    builder.addMatcher(isRejected, (state) => {
      if (state.history && state.history.leftInventory && state.history.rightInventory) {
        state.leftInventory = state.history.leftInventory;
        state.rightInventory = state.history.rightInventory;
      }
      state.isBusy = false;
    });
  },
});

export const {
  setAdditionalMetadata,
  setItemAmount,
  setShiftPressed,
  setupInventory,
  swapSlots,
  moveSlots,
  stackSlots,
  refreshSlots,
  setContainerWeight,
  initTrade,
  confirmTrade,
  updateTradeItems,
  cancelTrade,
} = inventorySlice.actions;
export const selectLeftInventory = (state: RootState) => state.inventory.leftInventory;
export const selectRightInventory = (state: RootState) => state.inventory.rightInventory;
export const selectItemAmount = (state: RootState) => state.inventory.itemAmount;
export const selectIsBusy = (state: RootState) => state.inventory.isBusy;
export const selectTrade = (state: RootState) => state.inventory.trade;

export default inventorySlice.reducer;
