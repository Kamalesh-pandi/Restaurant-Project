import { useEffect } from 'react';

export default function HotkeyHandler() {
  useEffect(() => {
    const handleKeyDown = (e) => {
      // F2: Quick Search
      if (e.key === 'F2') {
        e.preventDefault();
        window.dispatchEvent(new CustomEvent('pos-hotkey-search'));
      }
      // F4: Pay
      else if (e.key === 'F4') {
        e.preventDefault();
        window.dispatchEvent(new CustomEvent('pos-hotkey-pay'));
      }
      // Esc: Clear / Close
      else if (e.key === 'Escape') {
        window.dispatchEvent(new CustomEvent('pos-hotkey-esc'));
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, []);

  return null;
}
