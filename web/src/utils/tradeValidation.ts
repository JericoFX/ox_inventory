import { Slot } from '../typings/slot';

export interface TradeValidationResult {
  isValid: boolean;
  reason?: string;
  invalidItems?: string[];
}

export const validateTradeItems = (
  playerItems: Slot[],
  targetItems: Slot[],
  playerInventory: Slot[],
  targetInventory: Slot[]
): TradeValidationResult => {
  const result: TradeValidationResult = {
    isValid: true,
    invalidItems: []
  };

  // Verificar si el jugador tiene suficiente espacio para los items del objetivo
  const playerUsedSlots = playerInventory.filter(item => item.name).length;
  const playerAvailableSlots = 40 - playerUsedSlots; // Asumiendo 40 slots máximo
  const targetItemsCount = targetItems.length;

  if (targetItemsCount > playerAvailableSlots) {
    result.isValid = false;
    result.reason = 'No tienes suficiente espacio en el inventario';
    return result;
  }

  // Verificar si los items del jugador siguen siendo válidos
  for (const tradeItem of playerItems) {
    // Buscar por originalSlot si existe, sino por slot normal
    const originalSlot = (tradeItem as any).metadata?.originalSlot || tradeItem.slot;
    
    const inventoryItem = playerInventory.find(
      item => item.name === tradeItem.name && item.slot === originalSlot
    );

    if (!inventoryItem || !inventoryItem.name) {
      result.isValid = false;
      result.invalidItems?.push(tradeItem.name);
      continue;
    }

    // Verificar si la cantidad sigue siendo válida
    if (inventoryItem.count && tradeItem.count && inventoryItem.count < tradeItem.count) {
      result.isValid = false;
      result.invalidItems?.push(`${tradeItem.name} (cantidad insuficiente)`);
    }
  }

  // Verificar peso máximo (si es aplicable)
  const calculateWeight = (items: Slot[]): number => {
    return items.reduce((total, item) => total + (item.weight || 0), 0);
  };

  const playerCurrentWeight = calculateWeight(playerInventory);
  const targetItemsWeight = calculateWeight(targetItems);
  const playerItemsWeight = calculateWeight(playerItems);
  const newPlayerWeight = playerCurrentWeight - playerItemsWeight + targetItemsWeight;

  // Asumiendo peso máximo de 100kg (100000g)
  const maxWeight = 100000;
  if (newPlayerWeight > maxWeight) {
    result.isValid = false;
    result.reason = 'Los items del objetivo exceden tu capacidad de peso';
    return result;
  }

  if (result.invalidItems?.length > 0) {
    result.reason = `Items no válidos: ${result.invalidItems.join(', ')}`;
  }

  return result;
};

export const validateItemTransfer = (
  item: Slot,
  fromInventory: Slot[],
  toInventory: Slot[]
): boolean => {
  // Verificar si el item existe en el inventario origen
  const sourceItem = fromInventory.find(
    invItem => invItem.name === item.name && invItem.slot === item.slot
  );

  if (!sourceItem) {
    return false;
  }

  // Verificar si hay espacio en el inventario destino
  const usedSlots = toInventory.filter(invItem => invItem.name).length;
  const availableSlots = 40 - usedSlots; // Asumiendo 40 slots máximo

  if (availableSlots <= 0) {
    return false;
  }

  // Verificar peso
  const targetWeight = toInventory.reduce((total, invItem) => total + (invItem.weight || 0), 0);
  const newWeight = targetWeight + (item.weight || 0);
  const maxWeight = 100000; // 100kg en gramos

  if (newWeight > maxWeight) {
    return false;
  }

  return true;
};
