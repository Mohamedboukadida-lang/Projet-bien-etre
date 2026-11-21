import 'dart:math' as math;

import 'package:fitnessapp/service/wellbeing_service.dart';
import 'package:fitnessapp/utils/app_colors.dart';
import 'package:fitnessapp/view/home/widgets/home_formatters.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Last night's sleep and the last 7 nights as mini bars. Tap to log.
class SleepCard extends StatelessWidget {
  const SleepCard({
    super.key,
    required this.height,
    required this.today,
    required this.entries,
    required this.onTap,
  });

  final double height;
  final DateTime today;

  /// Nights of the last 7 days, or null while unavailable.
  final List<SleepEntry>? entries;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lastNight = entries?.where((e) => isSameDay(e.date, today)).firstOrNull;
    final days = [for (int i = 6; i >= 0; i--) today.subtract(Duration(days: i))];
    final hours = [
      for (final d in days)
        (entries?.where((e) => isSameDay(e.date, d)).firstOrNull?.duration.inMinutes ?? 0) / 60
    ];
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Sleep",
                      style: TextStyle(
                          color: AppColors.blackColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                  Icon(lastNight == null ? Icons.add_circle_outline : Icons.edit_outlined,
                      size: 16, color: AppColors.midGrayColor),
                ],
              ),
              const SizedBox(height: 4),
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (b) =>
                    LinearGradient(colors: AppColors.primaryG).createShader(b),
                child: Text(
                  lastNight == null ? "Not logged" : formatDuration(lastNight.duration),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                lastNight == null
                    ? "Tap to log last night"
                    : "${formatClock(lastNight.bedTime)} – ${formatClock(lastNight.wakeTime)}",
                style: const TextStyle(color: AppColors.grayColor, fontSize: 10),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: BarChart(BarChartData(
                  maxY: math.max(9, hours.reduce(math.max) + 1),
                  minY: 0,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 14,
                        getTitlesWidget: (value, meta) => SideTitleWidget(
                          meta: meta,
                          space: 2,
                          child: Text(weekdayShort[days[value.toInt()].weekday - 1][0],
                              style: const TextStyle(fontSize: 9, color: AppColors.grayColor)),
                        ),
                      ),
                    ),
                  ),
                  barGroups: [
                    for (int i = 0; i < 7; i++)
                      BarChartGroupData(x: i, barRods: [
                        BarChartRodData(
                          toY: hours[i],
                          width: 8,
                          borderRadius: BorderRadius.circular(4),
                          backDrawRodData: BackgroundBarChartRodData(
                              show: true, toY: 9, color: AppColors.lightGrayColor),
                          gradient: LinearGradient(
                            colors: i == 6 ? AppColors.secondaryG : AppColors.primaryG,
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ]),
                  ],
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
