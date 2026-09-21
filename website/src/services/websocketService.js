import { Client } from '@stomp/stompjs';
import SockJS from 'sockjs-client';

const RAW_API_BASE = import.meta.env.VITE_WS_BASE_URL || import.meta.env.VITE_API_BASE_URL || '';
const WS_BASE_URL = RAW_API_BASE.replace(/\/+$/, '');
const WS_ENDPOINT = WS_BASE_URL ? `${WS_BASE_URL}/ws` : '/ws';

class WebSocketService {
  constructor() {
    this.client = null;
    this.connected = false;
    this.listeners = new Map(); // topic -> Set of callbacks
  }

  connect(onStatusChange) {
    if (this.client && this.client.active) return;

    this.client = new Client({
      webSocketFactory: () => new SockJS(WS_ENDPOINT),
      reconnectDelay: 5000,
      heartbeatIncoming: 4000,
      heartbeatOutgoing: 4000,
      debug: (str) => {
        // Uncomment for verbose STOMP debugging
        // console.log('[STOMP]', str);
      },
    });

    this.client.onConnect = () => {
      this.connected = true;
      if (onStatusChange) onStatusChange(true);
      console.log('WebSocket STOMP connected to /ws');

      // Subscribe to standard topics
      const topics = ['/topic/tables', '/topic/orders', '/topic/alerts', '/topic/ready-alerts'];
      topics.forEach((topic) => {
        this.client.subscribe(topic, (message) => {
          let payload;
          try {
            payload = JSON.parse(message.body);
          } catch (e) {
            payload = message.body;
          }
          this.notifyListeners(topic, payload);
        });
      });
    };

    this.client.onDisconnect = () => {
      this.connected = false;
      if (onStatusChange) onStatusChange(false);
      console.warn('WebSocket STOMP disconnected');
    };

    this.client.onStompError = (frame) => {
      console.error('STOMP Error:', frame.headers['message'], frame.body);
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
        try {
          cb(data);
        } catch (e) {
          console.error(`Error in listener for ${topic}:`, e);
        }
      });
    }
  }
}

export const wsService = new WebSocketService();
