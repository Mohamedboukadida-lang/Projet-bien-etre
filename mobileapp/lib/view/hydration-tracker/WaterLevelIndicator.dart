import 'dart:math' as math;

import 'package:fitnessapp/utils/app_colors.dart';
import 'package:flutter/material.dart';

/// Animated "glass" filled up to `currentLevel / goal`.
class HydrationLevelIndicator extends StatelessWidget {
  const HydrationLevelIndicator({
    super.key,
    required this.currentLevel,
    required this.goal,
  });

  final double currentLevel;
  final double goal;

  @override
  Widget build(BuildContext context) {
    final progress = goal <= 0 ? 0.0 : (currentLevel / goal).clamp(0.0, 1.0);
    final percent = goal <= 0 ? 0 : (currentLevel / goal * 100).round();
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (context, value, _) => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 140,
          color: AppColors.primaryColor2.withValues(alpha: 0.15),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _WaterPainter(value)),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "$percent%",
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: AppColors.blackColor),
                    ),
                    Text(
                      "${currentLevel.toStringAsFixed(2)} L of ${goal.toStringAsFixed(2)} L",
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.blackColor),
                    ),
                    if (percent >= 100)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text("Goal reached, well done!",
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.blackColor)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaterPainter extends CustomPainter {
  _WaterPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final top = size.height * (1 - progress);
    final path = Path()..moveTo(0, top);
    const waves = 2;
    for (double x = 0; x <= size.width; x += 4) {
      final y = top + 5 * math.sin(x / size.width * waves * 2 * math.pi);
      path.lineTo(x, y);
    }
    path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.primaryColor2, AppColors.primaryColor1],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WaterPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
