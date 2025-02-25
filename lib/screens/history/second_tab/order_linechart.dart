// ignore_for_file: unused_import, unused_local_variable, unnecessary_import

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:posapp/theme/rally.dart';
import 'package:posapp/theme/theme.dart';
import 'package:posapp/provider/src.dart';

class HistoryOrderLineChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final groupedData = context.select<HistorySupplierByLine, List<List<dynamic>>>(
      (provider) => provider.groupedData,
    );

    return Container(
      alignment: Alignment.center,
      margin: EdgeInsets.fromLTRB(48, 60, 48, 48),
      child: _drawLineChart(context, groupedData),
    );
  }

  /// for bigger number `getEfficientInterval` still display too much
  /// this is a adjustment to that issue
  double _interval(List<List<dynamic>> groupedData) {
    final maxVal = groupedData.fold<double>(0.0, (prev, e) {
      if (prev < e[1]) {
        return e[1];
      }
      return prev;
    });
    final minVal = groupedData.fold<double>(double.maxFinite, (prev, e) {
      if (prev >= e[1] && e[1] > 0) {
        return e[1];
      }
      return prev;
    });
    const maxSteps = 19;
    final expectedInterval = (maxVal % minVal) != 0 ? (maxVal % minVal) : minVal;
    final expectedSteps = maxVal ~/ expectedInterval;
    final modifier = (expectedSteps ~/ maxSteps) + 1;
    return expectedInterval * modifier;
  }

  Widget _drawLineChart(BuildContext context, List<List<dynamic>> groupedData) {
    var showTooltipsOnAllSpots = true;
    final _spots = _mapGroupDataToSpots(groupedData);
    final _mainChart = LineChartBarData(
      spots: _spots,
      //color: RallyColors().primaryColor,
      color: Color(0xFF1EB980),
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: FlDotData(show: true),
      isCurved: true,
      curveSmoothness: 0.2,
      preventCurveOverShooting: true,
      belowBarData: BarAreaData(show: false),
    );
    return _spots.isEmpty
        ? Center(child: Text('No data'))
        : StatefulBuilder(
            builder: (context, setState) => LineChart(
              LineChartData(
                backgroundColor: RallyColors.primaryBackground,
                lineTouchData: LineTouchData(
                  // show tooltips on all spots on long tap
                  touchCallback: (FlTouchEvent touchEvent, LineTouchResponse? touchResponse) {
                    Timer? _timer;
                    if (touchEvent is FlTapDownEvent) {
                      _timer = Timer(Duration(seconds: 1), () {
                        setState(() {
                          showTooltipsOnAllSpots = true;
                        });
                      });
                    } else if (touchEvent is FlTapUpEvent) {
                      // ignore: dead_code
                      _timer?.cancel();
                      setState(() {
                        showTooltipsOnAllSpots = false;
                      });
                    }
                  },
                  // must disable this for showingTooltipIndicators to work
                  handleBuiltInTouches: !showTooltipsOnAllSpots,
                  touchSpotThreshold: 20.0,
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(color: RallyColors.gray),
                    bottom: BorderSide(color: RallyColors.gray),
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                    showTitles: true,
                    // getTextStyles: Theme.of(context).textTheme.bodyMedium != null
                    //     ? (value) => Theme.of(context).textTheme.bodyMedium!
                    //     : null,
                    // margin: 12.0,
                    interval: _interval(groupedData),
                  )),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      // getTextStyles: Theme.of(context).textTheme.bodyMedium != null
                      //     ? (value) => Theme.of(context).textTheme.bodyMedium!
                      //     : null,
                      // margin: 24.0,
                      // convert index value back to yyyymmdd
                      // getTitles: (idx) => groupedData[idx.toInt()][0],
                    ),
                  ),
                  // gridData: FlGridData(show: false),
                  // minY: 0.0,
                  showingTooltipIndicators: showTooltipsOnAllSpots
                      ? [
                          ..._spots.map(
                            (spot) => ShowingTooltipIndicators([LineBarSpot(_mainChart, 0, spot)]),
                          ),
                        ]
                      : [],
                  // lineBarsData: [_mainChart],
                ),
              ),
            ),
          );
  }

  List<FlSpot> _mapGroupDataToSpots(List<List<dynamic>> groupedData) {
    return groupedData.asMap().entries.map((entry) {
      // second element of the inner list is set as the value
      return FlSpot(entry.key.toDouble(), entry.value[1]);
    }).toList();
  }
}
