import { store } from '../store';
import { DragSource, DropTarget, InventoryType, SlotWithItem } from '../typings';
import { updateTradeItems } from '../store/inventory';
import { Items } from '../store/items';
import { isSlotWithItem } from '../helpers';
import { isEnvBrowser } from '../utils/misc';
import { fetchNui } from '../utils/fetchNui';

export const onTradeDrop = (source: DragSource, target?: DropTarget) => {
  const { inventory: state } = store.getState();
  
  // Solo procesar si estamos en modo trade
  if (!state.trade?.isTrading) return;
  
  // Solo permitir drag desde el inventario del jugador hacia el trade
  if (source.inventory === InventoryType.PLAYER && target?.inventory === 'trade') {
    const sourceSlot = state.leftInventory.items[source.item.slot - 1] as SlotWithItem;
    
    if (!isSlotWithItem(sourceSlot)) return;
    
    const sourceData = Items[sourceSlot.name];
    if (!sourceData) return console.error(`${sourceSlot.name} item data undefined!`);
    
    // Agregar item a los items del jugador en el trade
    const currentPlayerItems = state.trade.playerItems || [];
    
    // Verificar si el item ya está en el trade (por slot original)
    const existingItem = currentPlayerItems.find(item => 
      item.metadata?.originalSlot === sourceSlot.slot
    );
    
    if (existingItem) {
      console.log('Item already in trade');
      return;
    }
    
    // Calcular cantidad a mover (usar la cantidad disponible)
    const availableCount = sourceSlot.count || 1;
    const requestedCount = state.shiftPressed && availableCount > 1 
      ? Math.floor(availableCount / 2)
      : state.itemAmount === 0 || state.itemAmount > availableCount
      ? availableCount
      : Math.min(state.itemAmount, availableCount);
    
    // Crear nuevo item para el trade
    const targetSlot = target.item?.slot || (Math.max(0, ...currentPlayerItems.map(item => item.slot || 0)) + 1);
    
    const tradeItem = {
      ...sourceSlot,
      slot: targetSlot,
      count: requestedCount,
      metadata: {
        ...sourceSlot.metadata,
        originalSlot: sourceSlot.slot,
        tradeOwner: 'player'
      }
    };
    
    // Actualizar los items del trade
    const newPlayerItems = [...currentPlayerItems, tradeItem];
    
    store.dispatch(updateTradeItems({
      playerItems: newPlayerItems,
      targetItems: state.trade.targetItems || []
    }));
    
    // Sincronizar con el servidor
    if (!isEnvBrowser()) {
      fetchNui('updateTradeItems', {
        playerItems: newPlayerItems,
        targetItems: state.trade.targetItems || []
      });
    }
    
    console.log('Item moved to trade:', tradeItem);
  }
  
  // Si el target es el inventario del jugador (remover del trade)
  if (target?.inventory === InventoryType.PLAYER && source.inventory === 'trade') {
    // Remover item del trade
    const currentPlayerItems = state.trade.playerItems || [];
    
    // Encontrar el item basado en el slot del trade
    const newPlayerItems = currentPlayerItems.filter(item => 
      !(item.name === source.item.name && item.slot === source.item.slot)
    );
    
    store.dispatch(updateTradeItems({
      playerItems: newPlayerItems,
      targetItems: state.trade.targetItems || []
    }));
    
    // Sincronizar con el servidor
    if (!isEnvBrowser()) {
      fetchNui('updateTradeItems', {
        playerItems: newPlayerItems,
        targetItems: state.trade.targetItems || []
      });
    }
    
    console.log('Item removed from trade');
  }
};
