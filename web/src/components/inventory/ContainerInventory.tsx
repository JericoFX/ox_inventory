import React from 'react';
import { useAppSelector } from '../../store';
import { selectRightInventory } from '../../store/inventory';
import InventoryGrid from './InventoryGrid';

const ContainerInventory: React.FC = () => {
  const rightInventory = useAppSelector(selectRightInventory);

  if (rightInventory.type !== 'container') return null;

  return <InventoryGrid inventory={rightInventory} />;
};

export default ContainerInventory;
