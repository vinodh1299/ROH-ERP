// lib/core/services/poller.dart
import 'dart:async';

/// Runs [onTick] every [interval] while it is started *and* the app is in the
/// foreground. Starting is idempotent; coming back to the foreground refreshes
/// immediately. A tick is skipped while the previous one is still running.
class Poller {
  Poller(this.interval, this.onTick);

  final Duration interval;
  final Future<void> Function() onTick;

  Timer? _timer;
  bool _enabled = false;
  bool _foreground = true;
  bool _busy = false;

  bool get isEnabled => _enabled;

  void start() {
    if (_enabled) return;
    _enabled = true;
    _arm(refreshNow: true);
  }

  void stop() {
    _enabled = false;
    _timer?.cancel();
    _timer = null;
  }

  void setForeground(bool foreground) {
    if (foreground == _foreground) return;
    _foreground = foreground;
    if (!_enabled) return;
    if (foreground) {
      _arm(refreshNow: true);
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _arm({bool refreshNow = false}) {
    _timer?.cancel();
    _timer = null;
    if (!_foreground) return;
    _timer = Timer.periodic(interval, (_) => _tick());
    if (refreshNow) _tick();
  }

  Future<void> _tick() async {
    if (_busy) return;
    _busy = true;
    try {
      await onTick();
    } finally {
      _busy = false;
    }
  }
}
