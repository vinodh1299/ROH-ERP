// lib/core/services/web_storage/web_storage_web.dart
// Web platform implementation utilizing window.localStorage directly
import 'dart:html' as html;

void saveWebStorage(String key, String value) {
  try {
    html.window.localStorage[key] = value;
  } catch (_) {}
}

String? getWebStorage(String key) {
  try {
    return html.window.localStorage[key];
  } catch (_) {
    return null;
  }
}

void removeWebStorage(String key) {
  try {
    html.window.localStorage.remove(key);
  } catch (_) {}
}

void clearAllWebStorage() {
  try {
    html.window.localStorage.remove('jwt_token');
    html.window.localStorage.remove('auth_token');
    html.window.localStorage.remove('user_role');
    html.window.localStorage.remove('user_email');
    html.window.localStorage.remove('user_name');
    html.window.localStorage.remove('user_id');
    html.window.localStorage.remove('is_logged_in');
  } catch (_) {}
}

void playWebNotificationSound() {
  try {
    final script = html.ScriptElement()
      ..text = '''
      (function() {
        try {
          const AudioContext = window.AudioContext || window.webkitAudioContext;
          if (!AudioContext) return;
          const ctx = window._notifAudioCtx || new AudioContext();
          window._notifAudioCtx = ctx;
          if (ctx.state === 'suspended') {
            ctx.resume();
          }
          const now = ctx.currentTime;

          // Tone 1: 587.33 Hz (D5) - pleasant soft bell
          const osc1 = ctx.createOscillator();
          const gain1 = ctx.createGain();
          osc1.type = 'sine';
          osc1.frequency.setValueAtTime(587.33, now);
          gain1.gain.setValueAtTime(0.001, now);
          gain1.gain.exponentialRampToValueAtTime(0.28, now + 0.02);
          gain1.gain.exponentialRampToValueAtTime(0.001, now + 0.35);
          osc1.connect(gain1);
          gain1.connect(ctx.destination);
          osc1.start(now);
          osc1.stop(now + 0.35);

          // Tone 2: 880.0 Hz (A5) - bell ring harmonic
          const osc2 = ctx.createOscillator();
          const gain2 = ctx.createGain();
          osc2.type = 'sine';
          osc2.frequency.setValueAtTime(880.0, now + 0.09);
          gain2.gain.setValueAtTime(0.001, now + 0.09);
          gain2.gain.exponentialRampToValueAtTime(0.32, now + 0.11);
          gain2.gain.exponentialRampToValueAtTime(0.001, now + 0.55);
          osc2.connect(gain2);
          gain2.connect(ctx.destination);
          osc2.start(now + 0.09);
          osc2.stop(now + 0.55);

          // Tone 3: 1174.66 Hz (D6) - sparkle accent
          const osc3 = ctx.createOscillator();
          const gain3 = ctx.createGain();
          osc3.type = 'sine';
          osc3.frequency.setValueAtTime(1174.66, now + 0.18);
          gain3.gain.setValueAtTime(0.001, now + 0.18);
          gain3.gain.exponentialRampToValueAtTime(0.22, now + 0.20);
          gain3.gain.exponentialRampToValueAtTime(0.001, now + 0.7);
          osc3.connect(gain3);
          gain3.connect(ctx.destination);
          osc3.start(now + 0.18);
          osc3.stop(now + 0.7);
        } catch (e) {
          console.warn('Audio chime error:', e);
        }
      })();
      ''';
    html.document.body?.append(script);
    script.remove();
  } catch (_) {}
}



/// Asks the browser for notification permission if the user hasn't decided yet.
void requestWebNotificationPermission() {
  try {
    if (!html.Notification.supported) return;
    if (html.Notification.permission == 'default') {
      html.Notification.requestPermission();
    }
  } catch (_) {}
}

/// Shows a browser system notification when permission has been granted.
void showWebSystemNotification(String title, String body, void Function() onClick) {
  try {
    if (!html.Notification.supported || html.Notification.permission != 'granted') return;
    final notification = html.Notification(title, body: body, icon: 'icons/Icon-192.png');
    notification.onClick.listen((_) {
      try {
        final focus = html.ScriptElement()..text = 'window.focus();';
        html.document.body?.append(focus);
        focus.remove();
      } catch (_) {}
      notification.close();
      onClick();
    });
  } catch (_) {}
}
