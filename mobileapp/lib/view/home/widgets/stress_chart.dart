import 'package:fitnessapp/service/wellbeing_service.dart';
import 'package:fitnessapp/utils/app_colors.dart';
import 'package:fitnessapp/view/home/widgets/home_formatters.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Stress levels (1-5) over the last 7 days; days without an entry are gaps.
class StressChart extends StatelessWidget {
  const StressChart({super.key, required this.today, required this.entries, required this.height});

  final DateTime today;
  final List<StressEntry>? entries;
  final double height;

  @override
  Widget build(BuildContext context) {
    final days = [for (int i = 6; i >= 0; i--) today.subtract(Duration(days: i))];
    final levels = [
      for (final d in days) entries?.where((e) => isSameDay(e.date, d)).firstOrNull?.level
    ];
    if (levels.every((l) => l == null)) {
      return Container(
        height: height * 0.5,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.lightGrayColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          entries == null ? "Stress data unavailable" : "No stress logged in the last 7 days",
          style: const TextStyle(color: AppColors.grayColor, fontSize: 13),
        ),
      );
    }
    final spots = [
      for (int i = 0; i < 7; i++)
        levels[i] == null ? FlSpot.nullSpot : FlSpot(i.toDouble(), levels[i]!.toDouble())
    ];
    return SizedBox(
      height: height,
      child: LineChart(LineChartData(
        minX: -0.3,
        maxX: 6.3,
        minY: 0.5,
        maxY: 5.5,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            preventCurveOverShooting: true,
            barWidth: 3,
            isStrokeCapRound: true,
            gradient: LinearGradient(colors: AppColors.secondaryG),
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 4,
                color: Colors.white,
                strokeWidth: 3,
                strokeColor: AppColors.secondaryColor1,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.secondaryColor2.withValues(alpha: 0.3),
                  AppColors.secondaryColor2.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.secondaryColor1,
            tooltipBorderRadius: BorderRadius.circular(12),
            getTooltipItems: (touched) => [
              for (final s in touched)
                LineTooltipItem(
                  "${weekdayShort[days[s.x.toInt()].weekday - 1]}: "
                  "${stressLevelLabels[s.y.toInt() - 1]}",
                  const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: AppColors.grayColor.withValues(alpha: 0.12), strokeWidth: 1.5),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final label = switch (value) { 1 => 'Low', 3 => 'Mid', 5 => 'High', _ => '' };
                return SideTitleWidget(
                  meta: meta,
                  child: Text(label,
                      style: const TextStyle(color: AppColors.grayColor, fontSize: 11)),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value != value.roundToDouble() || value < 0 || value > 6) {
                  return const SizedBox.shrink();
                }
                final d = days[value.toInt()];
                return SideTitleWidget(
                  meta: meta,
                  space: 8,
                  child: Text(value == 6 ? 'Today' : weekdayShort[d.weekday - 1],
                      style: const TextStyle(color: AppColors.grayColor, fontSize: 11)),
                );
              },
            ),
          ),
        ),
      )),
    );
  }
}
