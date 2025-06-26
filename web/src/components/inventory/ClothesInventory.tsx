import ClothesInventoryGrid from './ClothesInventoryGrid';
import { useAppSelector } from '../../store';
import { selectRightInventory } from '../../store/inventory';

const ClothesInventory: React.FC = () => {
  const rightInventory = useAppSelector(selectRightInventory);
  return <ClothesInventoryGrid inventory={rightInventory} />;
};

export default ClothesInventory;
