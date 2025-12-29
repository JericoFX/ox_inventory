import { createSlice, PayloadAction } from '@reduxjs/toolkit';

export type TradeOffer = {
  slot: number;
  name: string;
  count: number;
  metadata?: Record<string, any>;
};

export type TradeInvite = {
  id: string;
  from: { id: number; name: string };
  expiresAt: number;
};

export type TradeState = {
  active: boolean;
  tradeId?: string;
  partner?: { id: number; name: string };
  offers: {
    self: TradeOffer[];
    partner: TradeOffer[];
  };
  confirmations: {
    self: boolean;
    partner: boolean;
  };
  expiresAt?: number;
  invite?: TradeInvite;
};

const initialState: TradeState = {
  active: false,
  offers: {
    self: [],
    partner: [],
  },
  confirmations: {
    self: false,
    partner: false,
  },
};

export type TradePayload = {
  id: string;
  partner: { id: number; name: string };
  offers: TradeState['offers'];
  confirmations: TradeState['confirmations'];
  expiresAt: number;
};

export const tradeSlice = createSlice({
  name: 'trade',
  initialState,
  reducers: {
    setTradeInvite: (state, action: PayloadAction<TradeInvite>) => {
      state.invite = action.payload;
    },
    setTradeState: (state, action: PayloadAction<TradePayload>) => {
      state.active = true;
      state.tradeId = action.payload.id;
      state.partner = action.payload.partner;
      state.offers = action.payload.offers;
      state.confirmations = action.payload.confirmations;
      state.expiresAt = action.payload.expiresAt;
      state.invite = undefined;
    },
    clearTrade: (state) => {
      state.active = false;
      state.tradeId = undefined;
      state.partner = undefined;
      state.offers = { self: [], partner: [] };
      state.confirmations = { self: false, partner: false };
      state.expiresAt = undefined;
      state.invite = undefined;
    },
  },
});

export const { setTradeInvite, setTradeState, clearTrade } = tradeSlice.actions;

export default tradeSlice.reducer;
