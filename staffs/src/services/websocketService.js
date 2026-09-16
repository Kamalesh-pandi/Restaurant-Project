import { Client } from '@stomp/stompjs';
import SockJS from 'sockjs-client';

class WebSocketService {
  constructor() {
    this.client = null;
    this.connected = false;
    this.listeners = new Map(); // topic -> Set of callbacks
  }

  connect(onStatusChange) {
    if (this.client && this.client.active) return;

    this.client = new Client({
      webSocketFactory: () => new SockJS('/ws'),
      reconnectDelay: 5000,
      heartbeatIncoming: 4000,
      heartbeatOutgoing: 4000,
      debug: () => {},
    });

    this.client.onConnect = () => {
      this.connected = true;
      if (onStatusChange) onStatusChange(true);
      console.log('[StaffPortal] WebSocket STOMP connected');

      const topics = ['/topic/tables', '/topic/orders', '/topic/alerts', '/topic/ready-alerts'];
      topics.forEach((topic) => {
        this.client.subscribe(topic, (message) => {
          let payload;
          try {
            payload = JSON.parse(message.body);
          } catch {
            payload = message.body;
          }
          this.notifyListeners(topic, payload);
        });
      });
    };

    this.client.onDisconnect = () => {
      this.connected = false;
      if (onStatusChange) onStatusChange(false);
      console.warn('[StaffPortal] WebSocket disconnected');
    };

    this.client.onStompError = (frame) => {
      console.error('[StaffPortal] STOMP Error:', frame.headers['message'], frame.body);
    };

    this.client.activate();
  }

  disconnect() {
    if (this.client) {
      this.client.deactivate();
      this.connected = false;
    }
  }

  subscribe(topic, callback) {
    if (!this.listeners.has(topic)) {
      this.listeners.set(topic, new Set());
    }
    this.listeners.get(topic).add(callback);
    return () => {
      if (this.listeners.has(topic)) {
        this.listeners.get(topic).delete(callback);
      }
    };
  }

  notifyListeners(topic, data) {
    if (this.listeners.has(topic)) {
      this.listeners.get(topic).forEach((cb) => {
        try { cb(data); } catch (e) {
          console.error(`[WS] Listener error on ${topic}:`, e);
        }
      });
    }
  }
}

export const wsService = new WebSocketService();
