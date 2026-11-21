import 'package:fitnessapp/service/wellbeing_service.dart';
import 'package:fitnessapp/utils/app_colors.dart';
import 'package:fitnessapp/view/home/widgets/home_formatters.dart';
import 'package:flutter/material.dart';

/// Today's self-reported stress level. Tap to log or change it.
class StressTodayCard extends StatelessWidget {
  const StressTodayCard({
    super.key,
    required this.height,
    required this.entry,
    required this.onTap,
  });

  final double height;
  final StressEntry? entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final level = entry?.level;
    return Material(
      color: AppColors.whiteColor,
      borderRadius: BorderRadius.circular(20),
      elevation: 1,
      shadowColor: Colors.black26,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          height: height,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Stress today",
                style: TextStyle(
                  color: AppColors.blackColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      level == null ? "📝" : stressLevelEmojis[level - 1],
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            level == null
                                ? "Not logged"
                                : stressLevelLabels[level - 1],
                            style: const TextStyle(
                              color: AppColors.blackColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            level == null
                                ? "How do you feel?"
                                : "Level $level of 5",
                            style: const TextStyle(
                              color: AppColors.grayColor,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
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
