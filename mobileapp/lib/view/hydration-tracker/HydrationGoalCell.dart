import 'package:fitnessapp/utils/app_colors.dart';
import 'package:flutter/material.dart';

/// A card showing one hydration figure (litres). Tappable when [onTap] is set.
class HydrationGoalCell extends StatelessWidget {
  const HydrationGoalCell({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
  });

  final String icon;
  final String title;
  final double? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.whiteColor,
      borderRadius: BorderRadius.circular(15),
      elevation: 2,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Image.asset(icon, width: 36, height: 36, fit: BoxFit.contain),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (bounds) =>
                          LinearGradient(colors: AppColors.primaryG)
                              .createShader(bounds),
                      child: Text(
                        value == null ? "–" : "${value!.toStringAsFixed(2)} L",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(title,
                        style: const TextStyle(
                            color: AppColors.grayColor, fontSize: 12)),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(Icons.edit_outlined,
                    size: 18, color: AppColors.midGrayColor),
            ],
          ),
        ),
      ),
    );
  }
}
