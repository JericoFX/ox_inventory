import React, { useEffect, useState } from 'react';
import { useDrop } from 'react-dnd';
import InventoryGrid from './InventoryGrid';
import { useAppDispatch, useAppSelector } from '../../store';
import { selectItemAmount, selectRightInventory } from '../../store/inventory';
import useNuiEvent from '../../hooks/useNuiEvent';
import { clearTrade, setTradeInvite, setTradeState } from '../../store/trade';
import { fetchNui } from '../../utils/fetchNui';
import { DragSource } from '../../typings';
import { getItemUrl } from '../../helpers';
import { Items } from '../../store/items';

const RightInventory: React.FC = () => {
  const dispatch = useAppDispatch();
  const rightInventory = useAppSelector(selectRightInventory);
  const trade = useAppSelector((state) => state.trade);
  const itemAmount = useAppSelector(selectItemAmount);
  const [timeLeft, setTimeLeft] = useState<number | null>(null);
  const [inviteTimeLeft, setInviteTimeLeft] = useState<number | null>(null);

  useNuiEvent('tradeInvite', (data) => {
    dispatch(setTradeInvite(data));
  });

  useNuiEvent('tradeState', (data) => {
    dispatch(setTradeState(data));
  });

  useNuiEvent('tradeClosed', () => {
    dispatch(clearTrade());
  });

  useEffect(() => {
    if (!trade.expiresAt) {
      setTimeLeft(null);
      return;
    }
    const updateTimer = () => {
      setTimeLeft(Math.max(0, Math.floor((trade.expiresAt - Date.now()) / 1000)));
    };
    updateTimer();
    const interval = window.setInterval(updateTimer, 1000);
    return () => window.clearInterval(interval);
  }, [trade.expiresAt]);

  useEffect(() => {
    if (!trade.invite?.expiresAt) {
      setInviteTimeLeft(null);
      return;
    }
    const updateTimer = () => {
      setInviteTimeLeft(Math.max(0, Math.floor((trade.invite!.expiresAt - Date.now()) / 1000)));
    };
    updateTimer();
    const interval = window.setInterval(updateTimer, 1000);
    return () => window.clearInterval(interval);
  }, [trade.invite?.expiresAt]);

  const [, drop] = useDrop<DragSource, void, unknown>(() => ({
    accept: 'SLOT',
    drop: (source) => {
      if (!trade.active || source.inventory !== 'player' || !trade.tradeId) return;
      fetchNui('tradeOfferItem', { tradeId: trade.tradeId, slot: source.item.slot, count: itemAmount });
    },
  }));

  if (trade.invite && !trade.active) {
    return (
      <div className="trade-panel trade-panel-right">
        <h2>Trade request</h2>
        <p>{trade.invite.from.name} wants to trade.</p>
        {inviteTimeLeft !== null && <p className="trade-timer">Expires in {inviteTimeLeft}s</p>}
        <div className="trade-actions">
          <button
            className="trade-button"
            onClick={() => fetchNui('tradeRespond', { tradeId: trade.invite!.id, accepted: true })}
          >
            Accept
          </button>
          <button
            className="trade-button trade-button-secondary"
            onClick={() => fetchNui('tradeRespond', { tradeId: trade.invite!.id, accepted: false })}
          >
            Decline
          </button>
        </div>
      </div>
    );
  }

  if (trade.active) {
    return (
      <div className="trade-panel trade-panel-right">
        <div className="trade-header">
          <h2>Trading with {trade.partner?.name}</h2>
          {timeLeft !== null && <span className="trade-timer">Expires in {timeLeft}s</span>}
        </div>
        <div className="trade-columns">
          <div className="trade-column">
            <h3>Your offer</h3>
            <div className="trade-dropzone" ref={drop}>
              Drag items here
            </div>
            <div className="trade-items">
              {trade.offers.self.map((offer) => (
                <div className="trade-item trade-item-self" key={`self-${offer.slot}`}>
                  <div className="trade-item-image" style={{ backgroundImage: `url(${getItemUrl(offer.name)})` }} />
                  <div className="trade-item-info">
                    <span>{Items[offer.name]?.label || offer.name}</span>
                    <span>{offer.count}x</span>
                  </div>
                  <button
                    className="trade-remove"
                    onClick={() =>
                      trade.tradeId && fetchNui('tradeRemoveItem', { tradeId: trade.tradeId, slot: offer.slot })
                    }
                  >
                    Remove
                  </button>
                </div>
              ))}
              {trade.offers.self.length === 0 && <p className="trade-empty">No items offered</p>}
            </div>
          </div>
          <div className="trade-column">
            <h3>{trade.partner?.name}'s offer</h3>
            <div className="trade-items">
              {trade.offers.partner.map((offer) => (
                <div className="trade-item trade-item-partner" key={`partner-${offer.slot}`}>
                  <div className="trade-item-image" style={{ backgroundImage: `url(${getItemUrl(offer.name)})` }} />
                  <div className="trade-item-info">
                    <span>{Items[offer.name]?.label || offer.name}</span>
                    <span>{offer.count}x</span>
                  </div>
                </div>
              ))}
              {trade.offers.partner.length === 0 && <p className="trade-empty">No items offered</p>}
            </div>
          </div>
        </div>
        <div className="trade-confirmations">
          <span className={trade.confirmations.self ? 'trade-confirmed' : ''}>
            You: {trade.confirmations.self ? 'Confirmed' : 'Pending'}
          </span>
          <span className={trade.confirmations.partner ? 'trade-confirmed' : ''}>
            {trade.partner?.name}: {trade.confirmations.partner ? 'Confirmed' : 'Pending'}
          </span>
        </div>
        <div className="trade-actions">
          <button
            className="trade-button"
            onClick={() => trade.tradeId && fetchNui('tradeConfirm', { tradeId: trade.tradeId })}
            disabled={trade.confirmations.self}
          >
            Confirm
          </button>
          <button
            className="trade-button trade-button-secondary"
            onClick={() => trade.tradeId && fetchNui('tradeCancel', { tradeId: trade.tradeId })}
          >
            Cancel
          </button>
        </div>
      </div>
    );
  }

  return <InventoryGrid inventory={rightInventory} />;
};

export default RightInventory;
