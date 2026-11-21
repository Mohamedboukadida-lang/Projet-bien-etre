import 'dart:math' as math;

import 'package:fitnessapp/utils/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Bar chart of litres drunk per day this week (Monday first), with the daily
/// goal as a dashed line.
class HistoricalIntakeTrends extends StatelessWidget {
  const HistoricalIntakeTrends(
      {super.key,
      required this.values,
      required this.goal,
      this.loading = false});

  /// 7 values, Monday to Sunday. Empty when not loaded.
  final List<double> values;
  final double goal;
  final bool loading;

  static const _weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final maxY = math.max(goal, values.fold<double>(0, math.max)) * 1.2;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text("This week",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blackColor)),
          ),
          AspectRatio(
            aspectRatio: 1.7,
            child: values.isNotEmpty
                ? BarChart(_data(maxY <= 0 ? 1 : maxY))
                : Center(
                    child: loading
                        ? const CircularProgressIndicator()
                        : const Text("No data available",
                            style: TextStyle(color: AppColors.grayColor)),
                  ),
          ),
        ],
      ),
    );
  }

  BarChartData _data(double maxY) {
    return BarChartData(
      maxY: maxY,
      minY: 0,
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      extraLinesData: ExtraLinesData(horizontalLines: [
        if (goal > 0)
          HorizontalLine(
            y: goal,
            color: AppColors.secondaryColor1,
            strokeWidth: 1.5,
            dashArray: [6, 4],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.topRight,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.secondaryColor1),
              labelResolver: (line) => "goal ${line.y.toStringAsFixed(1)} L",
            ),
          ),
      ]),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            interval: 1,
            // Whole litres only; fl_chart also labels the (non-round) max,
            // which would overlap the label below it.
            getTitlesWidget: (value, meta) => value != value.roundToDouble()
                ? const SizedBox.shrink()
                : SideTitleWidget(
                    meta: meta,
                    child: Text(value.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.grayColor)),
                  ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            getTitlesWidget: (value, meta) => SideTitleWidget(
              meta: meta,
              child: Text(_weekDays[value.toInt() % 7],
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.grayColor)),
            ),
          ),
        ),
      ),
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => AppColors.blackColor.withValues(alpha: 0.8),
          getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
            "${_weekDays[group.x]}: ${rod.toY.toStringAsFixed(2)} L",
            const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ),
      barGroups: [
        for (int i = 0; i < values.length && i < 7; i++)
          BarChartGroupData(x: i, barRods: [
            BarChartRodData(
              toY: values[i],
              width: 16,
              borderRadius: BorderRadius.circular(6),
              gradient: LinearGradient(
                colors: values[i] >= goal && goal > 0
                    ? AppColors.secondaryG.reversed.toList()
                    : AppColors.primaryG.reversed.toList(),
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ]),
      ],
    );
  }
}
