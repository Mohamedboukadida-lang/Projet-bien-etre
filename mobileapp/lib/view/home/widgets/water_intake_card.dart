import 'package:dotted_dashed_line/dotted_dashed_line.dart';
import 'package:fitnessapp/service/HydrationService.dart';
import 'package:fitnessapp/utils/app_colors.dart';
import 'package:fitnessapp/view/home/widgets/home_formatters.dart';
import 'package:flutter/material.dart';
import 'package:simple_animation_progress_bar/simple_animation_progress_bar.dart';

/// Today's water intake against the goal, split by time of day.
class WaterIntakeCard extends StatelessWidget {
  const WaterIntakeCard({
    super.key,
    required this.height,
    required this.today,
    required this.goal,
    required this.entries,
    this.onTap,
  });

  final double height;
  final double? today;
  final double? goal;
  final List<IntakeEntry>? entries;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ratio = (today != null && goal != null && goal! > 0)
        ? (today! / goal!).clamp(0.0, 1.0)
        : 0.0;
    final slots = intakeByTimeOfDay(entries ?? const []);
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
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          child: Row(children: [
            SimpleAnimationProgressBar(
              key: ValueKey(ratio),
              height: height - 40,
              width: 22,
              backgroundColor: Colors.grey.shade100,
              foregroundColor: Colors.purple,
              ratio: ratio,
              direction: Axis.vertical,
              curve: Curves.fastLinearToSlowEaseIn,
              duration: const Duration(seconds: 2),
              borderRadius: BorderRadius.circular(30),
              gradientColor: LinearGradient(
                  colors: AppColors.primaryG,
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Water Intake",
                      style: TextStyle(
                          color: AppColors.blackColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  _GradientText(
                    today == null ? "–" : formatLitres(today!),
                    colors: AppColors.primaryG,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    goal == null
                        ? ""
                        : "of ${goal!.toStringAsFixed(1)} L · ${(ratio * 100).round()}%",
                    style: const TextStyle(color: AppColors.grayColor, fontSize: 10),
                  ),
                  const SizedBox(height: 10),
                  const Text("Today",
                      style: TextStyle(
                          color: AppColors.blackColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w400)),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (int i = 0; i < slots.length; i++)
                          _SlotRow(slot: slots[i], isLast: i == slots.length - 1),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({required this.slot, required this.isLast});

  final IntakeSlot slot;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final empty = slot.litres == 0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            width: 10,
            height: 4,
            decoration: BoxDecoration(
                color: AppColors.secondaryColor1.withValues(alpha: empty ? 0.2 : 0.7),
                borderRadius: BorderRadius.circular(5)),
          ),
          if (!isLast)
            DottedDashedLine(
              width: 0,
              height: 18,
              axis: Axis.vertical,
              dashColor: AppColors.secondaryColor1.withValues(alpha: 0.4),
            ),
        ]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(slot.label,
                  style: const TextStyle(color: AppColors.blackColor, fontSize: 11)),
              empty
                  ? const Text("—",
                      style: TextStyle(color: AppColors.midGrayColor, fontSize: 11))
                  : _GradientText(formatLitres(slot.litres),
                      colors: AppColors.secondaryG,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}

class _GradientText extends StatelessWidget {
  const _GradientText(this.text, {required this.colors, required this.style});

  final String text;
  final List<Color> colors;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(colors: colors).createShader(bounds),
      child: Text(text, style: style),
    );
  }
}
