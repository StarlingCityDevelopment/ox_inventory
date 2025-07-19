import ClothesInventoryGrid from './ClothesInventoryGrid';
import { useAppSelector } from '../../store';
import { selectClothesInventory } from '../../store/inventory';

const ClothesInventory: React.FC = () => {
  const clothesInventory = useAppSelector(selectClothesInventory);
  return <ClothesInventoryGrid inventory={clothesInventory} />;
};

export default ClothesInventory;
