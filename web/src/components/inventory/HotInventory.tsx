import HotInventoryGrid from './HotInventoryGrid';
import { useAppSelector } from '../../store';
import { selectLeftInventory } from '../../store/inventory';

const HotInventory: React.FC = () => {
  const leftInventory = useAppSelector(selectLeftInventory);

  return <HotInventoryGrid inventory={leftInventory} />;
};

export default HotInventory;
