import 'package:flutter/material.dart';

import '../../theme/rung_colors.dart';

/// Horizontal application-status stepper: dots joined by a rail, filled up to
/// and including the current step. The final "decision" dot takes the
/// outcome colour (green on accept, red on reject) so a rejection reads at a
/// glance without opening the application.
///
/// The rail is laid out as a separate flex row underneath the dots — each
/// step occupies two half-units, so a segment spanning two of them lands
/// exactly between neighbouring dot centres in both LTR and RTL.
class StatusStepper extends StatelessWidget {
  const StatusStepper({
    super.key,
    required this.labels,
    required this.currentIndex,
    this.decisionColor,
    this.dotSize = 16,
    this.labelSize = 9,
  });

  final List<String> labels;

  /// Zero-based index of the furthest reached step.
  final int currentIndex;

  /// Colour for the last dot once [currentIndex] reaches it.
  final Color? decisionColor;

  final double dotSize;
  final double labelSize;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    final last = labels.length - 1;
    final decision = decisionColor ?? c.accent;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: dotSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Row(
                children: [
                  const Spacer(),
                  for (var i = 0; i < last; i++)
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: 2,
                        color: i < currentIndex ? c.accent : c.line2,
                      ),
                    ),
                  const Spacer(),
                ],
              ),
              Row(
                children: [
                  for (var i = 0; i < labels.length; i++)
                    Expanded(
                      child: Center(
                        child: _Dot(
                          size: dotSize,
                          reached: i <= currentIndex,
                          color: i == last ? decision : c.accent,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < labels.length; i++)
              Expanded(
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: labelSize,
                    fontWeight: FontWeight.w600,
                    color: i <= currentIndex ? c.ink : c.ink3,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.size, required this.reached, required this.color});

  final double size;
  final bool reached;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.rung;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: reached ? color : c.surface3,
        shape: BoxShape.circle,
        border: Border.all(color: reached ? color : c.line2, width: 2),
      ),
    );
  }
}
