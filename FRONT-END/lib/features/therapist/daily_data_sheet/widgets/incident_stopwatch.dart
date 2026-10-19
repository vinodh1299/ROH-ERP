import 'dart:async';
import 'package:flutter/material.dart';

/// Elapsed time as decimal minutes rounded to 0.1 (6 s); any time above
/// zero reports at least 0.1 so short incidents are not recorded as 0.
double elapsedToMinutes(Duration elapsed) {
  final ms = elapsed.inMilliseconds;
  if (ms <= 0) return 0;
  final tenths = (ms / 6000).round();
  return (tenths < 1 ? 1 : tenths) / 10;
}

/// Times an incident and reports its duration in decimal minutes (0.1 min
/// resolution) through [onMinutesUpdated].
class IncidentStopwatch extends StatefulWidget {
  final ValueChanged<double>? onMinutesUpdated;
  const IncidentStopwatch({super.key, this.onMinutesUpdated});

  @override
  State<IncidentStopwatch> createState() => _IncidentStopwatchState();
}

class _IncidentStopwatchState extends State<IncidentStopwatch> {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  double _reported = 0;

  /// Sends the elapsed minutes to the parent when the 0.1 min value changes.
  void _report() {
    final mins = elapsedToMinutes(_stopwatch.elapsed);
    if (mins > 0 && mins != _reported) {
      _reported = mins;
      widget.onMinutesUpdated?.call(mins);
    }
  }

  void _start() {
    if (!_stopwatch.isRunning) {
      _stopwatch.start();
      _timer = Timer.periodic(const Duration(milliseconds: 30), (_) {
        if (mounted) setState(() {});
        _report();
      });
    }
  }

  void _stop() {
    if (_stopwatch.isRunning) {
      _stopwatch.stop();
      _timer?.cancel();
      _report();
      if (mounted) setState(() {});
    }
  }

  void _reset() {
    _stopwatch.reset();
    _reported = 0;
    _timer?.cancel();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime() {
    final milli = _stopwatch.elapsedMilliseconds;
    final hundreds = (milli / 10).truncate() % 100;
    final seconds = (milli / 1000).truncate() % 60;
    final minutes = (milli / (1000 * 60)).truncate() % 60;

    final minStr = minutes.toString().padLeft(2, '0');
    final secStr = seconds.toString().padLeft(2, '0');
    final hunStr = hundreds.toString().padLeft(2, '0');

    return '$minStr:$secStr:$hunStr';
  }

  @override
  Widget build(BuildContext context) {
    final isRunning = _stopwatch.isRunning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatTime(),
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: _start,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  child: Text(
                    'Start',
                    style: TextStyle(
                      color: isRunning
                          ? const Color(0xFF4ADE80)
                          : const Color(0xFF86EFAC),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const Text(' | ',
                  style: TextStyle(color: Colors.white24, fontSize: 9)),
              InkWell(
                onTap: _stop,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  child: Text(
                    'Stop',
                    style: TextStyle(
                      color: Color(0xFFF87171),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const Text(' | ',
                  style: TextStyle(color: Colors.white24, fontSize: 9)),
              InkWell(
                onTap: _reset,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  child: Text(
                    'Reset',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
