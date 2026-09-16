import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme.dart';

class SlideToAction extends StatefulWidget {
  final String text;
  final Future<void> Function() onSlideComplete;
  final Color actionColor;
  final IconData icon;
  final bool isLoading;

  const SlideToAction({
    super.key,
    required this.text,
    required this.onSlideComplete,
    this.actionColor = AppTheme.emerald,
    this.icon = Icons.arrow_forward_ios_rounded,
    this.isLoading = false,
  });

  @override
  State<SlideToAction> createState() => _SlideToActionState();
}

class _SlideToActionState extends State<SlideToAction> {
  double _dragPosition = 0.0;
  bool _isCompleted = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDrag = constraints.maxWidth - 60;

        return Container(
          height: 62,
          decoration: BoxDecoration(
            color: AppTheme.surfaceSlate,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppTheme.borderSlate, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: widget.actionColor.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Sliding fill background
              AnimatedContainer(
                duration: const Duration(milliseconds: 50),
                width: _dragPosition + 60,
                decoration: BoxDecoration(
                  color: widget.actionColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(32),
                ),
              ),

              // Centered Prompt Text
              Center(
                child: widget.isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation(widget.actionColor),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Processing...',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.text,
                            style: TextStyle(
                              color: AppTheme.textPrimary.withOpacity(0.85),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.keyboard_double_arrow_right_rounded,
                            size: 20,
                            color: widget.actionColor.withOpacity(0.8),
                          ),
                        ],
                      ),
              ),

              // Draggable Action Thumb
              if (!widget.isLoading)
                Positioned(
                  left: _dragPosition,
                  top: 3,
                  bottom: 3,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      setState(() {
                        _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, maxDrag);
                      });
                    },
                    onHorizontalDragEnd: (details) async {
                      if (_dragPosition >= maxDrag * 0.75 && !_isCompleted) {
                        setState(() {
                          _dragPosition = maxDrag;
                          _isCompleted = true;
                        });
                        HapticFeedback.heavyImpact();
                        await widget.onSlideComplete();
                        if (mounted) {
                          setState(() {
                            _dragPosition = 0.0;
                            _isCompleted = false;
                          });
                        }
                      } else {
                        // Snap back
                        setState(() {
                          _dragPosition = 0.0;
                        });
                      }
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: widget.actionColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: widget.actionColor.withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.icon,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
