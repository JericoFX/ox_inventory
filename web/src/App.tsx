import InventoryComponent from './components/inventory';
import useNuiEvent from './hooks/useNuiEvent';
import { Items } from './store/items';
import { Locale } from './store/locale';
import { setImagePath } from './store/imagepath';
import { setupInventory, initTrade, confirmTrade } from './store/inventory';
import { Inventory } from './typings';
import { useAppDispatch } from './store';
import { debugData } from './utils/debugData';
import DragPreview from './components/utils/DragPreview';
import { fetchNui } from './utils/fetchNui';
import { useDragDropManager } from 'react-dnd';
import KeyPress from './components/utils/KeyPress';
import { isEnvBrowser } from './utils/misc';

debugData([
  {
    action: 'setupInventory',
    data: {
      leftInventory: {
        id: 'test',
        type: 'player',
        slots: 50,
        label: 'Bob Smith',
        weight: 3000,
        maxWeight: 5000,
        items: [
          {
            slot: 1,
            name: 'iron',
            weight: 3000,
            metadata: {
              description: `name: Svetozar Miletic  \n Gender: Male`,
              ammo: 3,
              mustard: '60%',
              ketchup: '30%',
              mayo: '10%',
            },
            count: 5,
          },
          { slot: 2, name: 'powersaw', weight: 0, count: 1, metadata: { durability: 75 } },
          { slot: 3, name: 'copper', weight: 100, count: 12, metadata: { type: 'Special' } },
          {
            slot: 4,
            name: 'water',
            weight: 100,
            count: 1,
            metadata: { description: 'Generic item description', rarity: 'legendary' },
          },
          { slot: 5, name: 'water', weight: 100, count: 1 },
          {
            slot: 6,
            name: 'backwoods',
            weight: 100,
            count: 1,
            metadata: {
              label: 'Russian Cream',
              imageurl: 'https://i.imgur.com/2xHhTTz.png',
              rarity: 'epic',
            },
          },
        ],
      },
      rightInventory: {
        id: 'shop',
        type: 'container',
        slots: 10,
        label: 'Contenedor',
        weight: 3000,
        maxWeight: 5000,
        items: [
          {
            slot: 1,
            name: 'lockpick',
            weight: 500,
            price: 300,
            ingredients: {
              iron: 5,
              copper: 12,
              powersaw: 0.1,
            },
            metadata: {
              description: 'Simple lockpick that breaks easily and can pick basic door locks',
            },
          },
        ],
      },
    },
  },
]);

// Debug data para sistema de trading
if (isEnvBrowser()) {
  // Simular inicio de trade después de 3 segundos
  setTimeout(() => {
    const tradeData = {
      targetPlayer: {
        id: 2,
        name: 'John Doe'
      },
      playerItems: [
        {
          name: 'water',
          label: 'Water',
          weight: 500,
          slot: 1,
          count: 2,
          description: 'A refreshing bottle of water',
          metadata: {},
          stack: true
        },
        {
          name: 'bread',
          label: 'Bread',
          weight: 200,
          slot: 2,
          count: 1,
          description: 'Fresh bread',
          metadata: {},
          stack: true
        }
      ],
      targetItems: [
        {
          name: 'lockpick',
          label: 'Lockpick',
          weight: 100,
          slot: 1,
          count: 1,
          description: 'A simple lockpick',
          metadata: {},
          stack: true
        },
        {
          name: 'iron',
          label: 'Iron',
          weight: 150,
          slot: 2,
          count: 3,
          description: 'Raw iron ore',
          metadata: {},
          stack: true
        }
      ]
    };
    
    window.dispatchEvent(
      new MessageEvent('message', {
        data: {
          action: 'initTrade',
          data: tradeData,
        },
      })
    );
  }, 3000);
}

const App: React.FC = () => {
  const dispatch = useAppDispatch();
  const manager = useDragDropManager();

  useNuiEvent<{
    locale: { [key: string]: string };
    items: typeof Items;
    leftInventory: Inventory;
    imagepath: string;
  }>('init', ({ locale, items, leftInventory, imagepath }) => {
    for (const name in locale) Locale[name] = locale[name];
    for (const name in items) Items[name] = items[name];

    setImagePath(imagepath);
    dispatch(setupInventory({ leftInventory }));
  });

  fetchNui('uiLoaded', {});

  // Recibe datos de ítems añadidos en runtime
  useNuiEvent<{ [key: string]: (typeof Items)[string] }>('registerItem', (itemData) => {
    for (const name in itemData) Items[name] = itemData[name];
  });

  useNuiEvent('closeInventory', () => {
    manager.dispatch({ type: 'dnd-core/END_DRAG' });
  });

  return (
    <div className="app-wrapper">
      <InventoryComponent />
      <DragPreview />
      <KeyPress />
      {isEnvBrowser() && (
        <button
          onClick={() => {
            const tradeData = {
              targetPlayer: {
                id: 2,
                name: 'John Doe'
              },
              playerItems: [], // Inicialmente vacío
              targetItems: []  // Inicialmente vacío
            };
            
            dispatch(initTrade(tradeData));
          }}
          style={{
            position: 'fixed',
            top: '10px',
            right: '10px',
            padding: '10px 20px',
            backgroundColor: '#4a5336',
            color: 'white',
            border: 'none',
            borderRadius: '5px',
            cursor: 'pointer',
            zIndex: 9999
          }}
        >
          Test Trade
        </button>
      )}
      {isEnvBrowser() && (
        <button
          onClick={() => {
            dispatch(confirmTrade({ 
              playerConfirmed: false, 
              targetConfirmed: true 
            }));
          }}
          style={{
            position: 'fixed',
            top: '60px',
            right: '10px',
            padding: '10px 20px',
            backgroundColor: '#d08b45',
            color: 'white',
            border: 'none',
            borderRadius: '5px',
            cursor: 'pointer',
            zIndex: 9999
          }}
        >
          Simulate Target Confirm
        </button>
      )}
      {isEnvBrowser() && (
        <button
          onClick={() => {
            const tradeData = {
              targetPlayer: {
                id: 2,
                name: 'John Doe'
              },
              playerItems: [
                {
                  name: 'water',
                  label: 'Water',
                  weight: 500,
                  slot: 1,
                  count: 2,
                  description: 'A refreshing bottle of water',
                  metadata: { tradeOwner: 'player' },
                  stack: true
                }
              ],
              targetItems: [
                {
                  name: 'lockpick',
                  label: 'Lockpick',
                  weight: 100,
                  slot: 21,
                  count: 1,
                  description: 'A simple lockpick',
                  metadata: { tradeOwner: 'target' },
                  stack: true
                }
              ]
            };
            
            dispatch(initTrade(tradeData));
          }}
          style={{
            position: 'fixed',
            top: '110px',
            right: '10px',
            padding: '10px 20px',
            backgroundColor: '#2196F3',
            color: 'white',
            border: 'none',
            borderRadius: '5px',
            cursor: 'pointer',
            zIndex: 9999
          }}
        >
          Test Trade with Items
        </button>
      )}
    </div>
  );
};

addEventListener('dragstart', function (event) {
  event.preventDefault();
});

export default App;
