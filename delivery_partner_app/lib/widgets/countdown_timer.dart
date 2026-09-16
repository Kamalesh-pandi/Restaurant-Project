import 'dart:async';
import 'package:flutter/material.dart';
import '../config/theme.dart';

class CountdownTimerBar extends StatefulWidget {
  final int totalSeconds;
  final VoidCallback onTimeout;

  const CountdownTimerBar({
    super.key,
    this.totalSeconds = 30,
    required this.onTimeout,
  });

  @override
  State<CountdownTimerBar> createState() => _CountdownTimerBarState();
}

class _CountdownTimerBarState extends State<CountdownTimerBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _remainingSeconds = 30;
  Timer? _tickerTimer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.totalSeconds;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.totalSeconds),
    )..forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onTimeout();
      }
    });

    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _tickerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Acceptance Window',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 14, color: AppTheme.amber),
                const SizedBox(width: 4),
                Text(
                  '${_remainingSeconds}s left',
                  style: const TextStyle(
                    color: AppTheme.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return LinearProgressIndicator(
                value: 1.0 - _controller.value,
                minHeight: 6,
                backgroundColor: AppTheme.surfaceHighlight,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _remainingSeconds < 8 ? AppTheme.rose : AppTheme.amber,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
