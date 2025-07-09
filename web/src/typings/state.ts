import { Inventory } from './inventory';
import { Slot } from './slot';

export type State = {
  leftInventory: Inventory;
  rightInventory: Inventory;
  itemAmount: number;
  shiftPressed: boolean;
  isBusy: boolean;
  additionalMetadata: Array<{ metadata: string; value: string }>;
  history?: {
    leftInventory: Inventory;
    rightInventory: Inventory;
  };
  trade?: {
    isTrading: boolean;
    targetPlayer: {
      id: number;
      name: string;
    };
    playerConfirmed: boolean;
    targetConfirmed: boolean;
    playerItems: Slot[];
    targetItems: Slot[];
  };
};
