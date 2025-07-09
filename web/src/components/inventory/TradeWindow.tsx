import React, { useState } from 'react';
import { useAppDispatch, useAppSelector } from '../../store';
import { selectTrade, confirmTrade } from '../../store/inventory';
import InventoryGrid from './InventoryGrid';
import { fetchNui } from '../../utils/fetchNui';
import { Inventory } from '../../typings/inventory';
import { isEnvBrowser } from '../../utils/misc';

const TradeWindow: React.FC = () => {
  const dispatch = useAppDispatch();
  const trade = useAppSelector(selectTrade);
  const [isConfirming, setIsConfirming] = useState(false);

  if (!trade?.isTrading) return null;

  const handleConfirmTrade = async () => {
    setIsConfirming(true);
    
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
    } finally {
      setIsConfirming(false);
    }
  };

  const handleCancelTrade = async () => {
    try {
      if (!isEnvBrowser()) {
        await fetchNui('cancelTrade', {
          targetPlayerId: trade.targetPlayer.id
        });
      } else {
        // Simular cancelación en el navegador
        dispatch(confirmTrade({ 
          playerConfirmed: false, 
          targetConfirmed: false 
        }));
      }
    } catch (error) {
      console.error('Error canceling trade:', error);
    }
  };

  // Crear inventarios mock para mostrar los items del trade
  const playerTradeInventory: Inventory = {
    id: 'player-trade',
    type: 'trade',
    slots: 8,
    maxWeight: 1000,
    items: trade.playerItems || [],
    label: 'Tus Items'
  };

  const targetTradeInventory: Inventory = {
    id: 'target-trade',
    type: 'trade',
    slots: 8,
    maxWeight: 1000,
    items: trade.targetItems || [],
    label: trade.targetPlayer.name
  };

  return (
    <div className="trade-window">
      <div className="trade-header">
        <h3>Intercambio con {trade.targetPlayer.name}</h3>
        <button className="trade-close" onClick={handleCancelTrade}>
          ×
        </button>
      </div>
      
      <div className="trade-content">
        <div className="trade-section">
          <h4>Tus Items para Intercambiar</h4>
          <div className="trade-inventory">
            {trade.playerItems && trade.playerItems.length > 0 ? (
              <InventoryGrid inventory={playerTradeInventory} />
            ) : (
              <div className="empty-trade-slot">
                <p>Arrastra items aquí desde tu inventario</p>
              </div>
            )}
          </div>
          <div className="trade-status">
            {trade.playerConfirmed && <span className="confirmed">✓ Confirmado</span>}
          </div>
        </div>
        
        <div className="trade-divider">
          <div className="trade-arrow">⇄</div>
          <div className="trade-info">
            <small>Intercambio</small>
          </div>
        </div>
        
        <div className="trade-section">
          <h4>Items de {trade.targetPlayer.name}</h4>
          <div className="trade-inventory">
            {trade.targetItems && trade.targetItems.length > 0 ? (
              <InventoryGrid inventory={targetTradeInventory} />
            ) : (
              <div className="empty-trade-slot">
                <p>Esperando items de {trade.targetPlayer.name}</p>
              </div>
            )}
          </div>
          <div className="trade-status">
            {trade.targetConfirmed && <span className="confirmed">✓ Confirmado</span>}
          </div>
        </div>
      </div>
      
      <div className="trade-actions">
        <button 
          className="trade-button trade-confirm" 
          onClick={handleConfirmTrade}
          disabled={isConfirming || trade.playerConfirmed}
        >
          {isConfirming ? 'Confirmando...' : trade.playerConfirmed ? 'Confirmado' : 'Confirmar'}
        </button>
        
        <button 
          className="trade-button trade-cancel" 
          onClick={handleCancelTrade}
        >
          Cancelar
        </button>
      </div>
    </div>
  );
};

export default TradeWindow;
