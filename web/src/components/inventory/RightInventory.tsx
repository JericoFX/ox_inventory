import React, { useMemo } from 'react';
import InventoryGrid from './InventoryGrid';
import { useAppSelector } from '../../store';
import { selectRightInventory, selectTrade } from '../../store/inventory';
import { Inventory } from '../../typings/inventory';

const RightInventory: React.FC = () => {
  const rightInventory = useAppSelector(selectRightInventory);
  const trade = useAppSelector(selectTrade);

  // Modificar el inventario de la derecha para mostrar items de trade si está activo
  const displayInventory: Inventory = useMemo(() => {
    if (!trade?.isTrading) return rightInventory;

    // Mantener la estructura original del inventario derecho
    const baseItems = [...rightInventory.items];
    
    // Agregar items de trade a los slots, manteniendo los originales
    const tradeItems = [
      // Items del jugador con metadata especial
      ...(trade.playerItems?.map(item => ({
        ...item,
        metadata: {
          ...item.metadata,
          tradeOwner: 'player',
          tradeId: trade.targetPlayer.id
        }
      })) || []),
      // Items del objetivo con metadata especial
      ...(trade.targetItems?.map(item => ({
        ...item,
        metadata: {
          ...item.metadata,
          tradeOwner: 'target',
          tradeId: trade.targetPlayer.id
        }
      })) || [])
    ];
    
    // Combinar items, dando prioridad a los items de trade
    tradeItems.forEach(tradeItem => {
      const existingIndex = baseItems.findIndex(item => item.slot === tradeItem.slot);
      if (existingIndex !== -1) {
        baseItems[existingIndex] = tradeItem;
      } else {
        baseItems.push(tradeItem);
      }
    });

    return {
      ...rightInventory,
      type: 'trade',
      items: baseItems,
      label: trade?.isTrading ? `Trade con ${trade.targetPlayer.name}` : rightInventory.label
    };
  }, [trade, rightInventory]);

  return <InventoryGrid inventory={displayInventory} />;
};

export default RightInventory;
