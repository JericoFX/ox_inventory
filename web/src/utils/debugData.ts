import { isEnvBrowser } from './misc';

interface DebugEvent<T = any> {
  action: string;
  data: T;
}

/**
 * Emulates dispatching an event using SendNUIMessage in the lua scripts.
 * This is used when developing in browser
 *
 * @param events - The event you want to cover
 * @param timer - How long until it should trigger (ms)
 */
export const debugData = <P>(events: DebugEvent<P>[], timer = 1000): void => {
  if (import.meta.env.DEV && isEnvBrowser()) {
    for (const event of events) {
      setTimeout(() => {
        window.dispatchEvent(
          new MessageEvent('message', {
            data: {
              action: event.action,
              data: event.data,
            },
          })
        );
      }, timer);
    }
  }
};

// Mock trade data for testing
export const mockTradeData = {
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
      name: 'pistol',
      label: 'Pistol',
      weight: 1200,
      slot: 1,
      count: 1,
      description: 'A standard pistol',
      metadata: {
        durability: 85,
        ammo: 12
      },
      stack: false
    },
    {
      name: 'money',
      label: 'Money',
      weight: 0,
      slot: 2,
      count: 500,
      description: 'Cash money',
      metadata: {},
      stack: true
    }
  ]
};

// Helper function to simulate trade events
export const simulateTradeEvents = () => {
  if (import.meta.env.DEV && isEnvBrowser()) {
    // Simulate trade initialization after 2 seconds
    setTimeout(() => {
      window.dispatchEvent(
        new MessageEvent('message', {
          data: {
            action: 'initTrade',
            data: mockTradeData,
          },
        })
      );
    }, 2000);
  }
};
