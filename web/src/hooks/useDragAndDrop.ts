import { useDrop, useDrag } from 'react-dnd';
import { useAppDispatch } from '../store';
import { onDrop } from '../dnd/onDrop';

export const useDragAndDrop = (item: any, slot: number, inventory: any, isPartnerInventory: boolean) => {
  const dispatch = useAppDispatch();

  const [{ isDragging }, dragSource] = useDrag({
    item: () => ({
      type: item?.name,
      id: item?.id,
      slot: slot,
      inventory: inventory,
    }),
    collect: (monitor) => ({
      isDragging: monitor.isDragging(),
    }),
  });

  const [{ isOver, canDrop }, dropTarget] = useDrop(() => ({
    accept: [item?.name],
    drop: (draggedItem: any) => {
      onDrop(draggedItem, { item, inventory, slot });
    },
    canDrop: () => {
      if (isPartnerInventory) return false;
      return inventory.id !== 'player';
    },
  }));

  return { isOver, canDrop, dropTarget, dragSource, isDragging, itemType: item?.name };
};
