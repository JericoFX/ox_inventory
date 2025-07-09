import React, { useState } from 'react';
import { useDrop } from 'react-dnd';
import { useAppDispatch, useAppSelector } from '../../store';
import { selectItemAmount, setItemAmount, selectTrade, confirmTrade, cancelTrade } from '../../store/inventory';
import { DragSource } from '../../typings';
import { onUse } from '../../dnd/onUse';
import { onGive } from '../../dnd/onGive';
import { fetchNui } from '../../utils/fetchNui';
import { Locale } from '../../store/locale';
import { isEnvBrowser } from '../../utils/misc';
import UsefulControls from './UsefulControls';

const InventoryControl: React.FC = () => {
  const itemAmount = useAppSelector(selectItemAmount);
  const trade = useAppSelector(selectTrade);
  const dispatch = useAppDispatch();

  const [infoVisible, setInfoVisible] = useState(false);

  const [, use] = useDrop<DragSource, void, any>(() => ({
    accept: 'SLOT',
    drop: (source) => {
      source.inventory === 'player' && onUse(source.item);
    },
  }));

  const [, give] = useDrop<DragSource, void, any>(() => ({
    accept: 'SLOT',
    drop: (source) => {
      source.inventory === 'player' && onGive(source.item);
    },
  }));

  const inputHandler = (event: React.ChangeEvent<HTMLInputElement>) => {
    event.target.valueAsNumber =
      isNaN(event.target.valueAsNumber) || event.target.valueAsNumber < 0 ? 0 : Math.floor(event.target.valueAsNumber);
    dispatch(setItemAmount(event.target.valueAsNumber));
  };

  const handleTradeReady = async () => {
    if (!trade?.isTrading) return;
    
    try {
      if (!isEnvBrowser()) {
        await fetchNui('confirmTrade', {
          targetPlayerId: trade.targetPlayer.id,
          playerItems: trade.playerItems,
          targetItems: trade.targetItems
        });
      }
      
      dispatch(confirmTrade({ 
        playerConfirmed: true, 
        targetConfirmed: trade.targetConfirmed 
      }));
    } catch (error) {
      console.error('Error confirming trade:', error);
    }
  };

  const handleTradeCancel = async () => {
    if (!trade?.isTrading) return;
    
    try {
      if (!isEnvBrowser()) {
        await fetchNui('cancelTrade', {
          targetPlayerId: trade.targetPlayer.id
        });
      }
      dispatch(cancelTrade());
    } catch (error) {
      console.error('Error canceling trade:', error);
    }
  };

  return (
    <>
      <UsefulControls infoVisible={infoVisible} setInfoVisible={setInfoVisible} />
      <div className="inventory-control">
        <div className="inventory-control-wrapper">
          <input
            className="inventory-control-input"
            type="number"
            defaultValue={itemAmount}
            onChange={inputHandler}
            min={0}
          />
          <button 
            className={`inventory-control-button ${trade?.isTrading ? 'trade-ready' : ''}`}
            ref={trade?.isTrading ? undefined : use}
            onClick={trade?.isTrading ? handleTradeReady : undefined}
            disabled={trade?.isTrading && trade.playerConfirmed}
          >
            <svg viewBox="0 0 24 24">
              <path d="M12 2a1 1 0 0 1 1 1v8h8a1 1 0 1 1 0 2h-9a1 1 0 0 1-1-1V3a1 1 0 0 1 1-1z" />
            </svg>
            {trade?.isTrading ? (trade.playerConfirmed ? 'Ready ✓' : 'Ready') : (Locale.ui_use || 'Use')}
          </button>
          <button 
            className={`inventory-control-button ${trade?.isTrading ? 'trade-cancel' : ''}`}
            ref={trade?.isTrading ? undefined : give}
            onClick={trade?.isTrading ? handleTradeCancel : undefined}
          >
            <svg viewBox="0 0 24 24">
              <path d="M14 3l7 7-7 7v-4H4v-6h10V3z" />
            </svg>
            {trade?.isTrading ? 'Cancel' : (Locale.ui_give || 'Give')}
          </button>
          <button className="inventory-control-button" onClick={() => fetchNui('exit')}>
            <svg viewBox="0 0 24 24">
              <path d="M18 6L6 18M6 6l12 12" stroke="currentColor" strokeWidth="2" strokeLinecap="round" />
            </svg>
            {Locale.ui_close || 'Close'}
          </button>
        </div>
      </div>

      <button className="useful-controls-button" onClick={() => setInfoVisible(true)}>
        <svg xmlns="http://www.w3.org/2000/svg" height="2em" viewBox="0 0 524 524">
          <path d="M256 512A256 256 0 1 0 256 0a256 256 0 1 0 0 512zM216 336h24V272H216c-13.3 0-24-10.7-24-24s10.7-24 24-24h48c13.3 0 24 10.7 24 24v88h8c13.3 0 24 10.7 24 24s-10.7 24-24 24H216c-13.3 0-24-10.7-24-24s10.7-24 24-24zm40-208a32 32 0 1 1 0 64 32 32 0 1 1 0-64z" />
        </svg>
      </button>
    </>
  );
};

export default InventoryControl;
