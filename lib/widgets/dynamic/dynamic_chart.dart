import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/dashboard_service.dart';
import '../../core/constants/app_colors.dart';

class DynamicChart extends StatefulWidget {
  final Map<String, dynamic> schema;
  final Map<String, dynamic> formData;

  const DynamicChart({
    super.key,
    required this.schema,
    required this.formData,
  });

  @override
  State<DynamicChart> createState() => _DynamicChartState();
}

class _DynamicChartState extends State<DynamicChart> {
  bool _isLoading = false;
  Map<String, dynamic> _chartOption = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final props = widget.schema['props'] ?? {};
    final searchFlow = props['searchflow'];

    if (searchFlow == null) return;

    setState(() => _isLoading = true);
    
    try {
      final service = DashboardService();
      // Pass filters from formData if needed
      final res = await service.executeFlow(searchFlow, widget.formData);
      
      if (res != null) {
         // ECharts option is usually in res['data']['data'] based on Nuxt ChartWrapper
         // res.data.data
         if (res['data'] != null && res['data']['data'] != null) {
            setState(() => _chartOption = res['data']['data']);
         }
      }
    } catch (e) {
      print("DynamicChart Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_chartOption.isEmpty) {
      return const SizedBox(
        height: 200, 
        child: Center(child: Text("No chart data"))
      );
    }

    // Determine Chart Type from ECharts series
    final series = _chartOption['series'] as List?;
    if (series == null || series.isEmpty) return const Text("Invalid Chart Data");

    final firstSeries = series.first as Map<String, dynamic>;
    final type = firstSeries['type'] ?? 'line';

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: type == 'bar' 
          ? _buildBarChart() 
          : _buildLineChart(),
    );
  }

  Widget _buildLineChart() {
    // Basic ECharts -> FL Chart Line Mapping
    // XAxis data usually in _chartOption['xAxis']['data']
    // Series data in _chartOption['series'][0]['data']
    
    final xAxisData = _chartOption['xAxis']?['data'] as List?;
    final seriesList = _chartOption['series'] as List?;
    
    if (seriesList == null) return const SizedBox.shrink();

    List<LineChartBarData> lineBars = [];
    
    for (var s in seriesList) {
       final data = s['data'] as List?;
       if (data == null) continue;
       
       List<FlSpot> spots = [];
       for (int i = 0; i < data.length; i++) {
         spots.add(FlSpot(i.toDouble(), double.tryParse(data[i].toString()) ?? 0));
       }
       
       lineBars.add(LineChartBarData(
         spots: spots,
         isCurved: true,
         color: AppColors.primary,
         barWidth: 3,
         dotData: const FlDotData(show: false),
         belowBarData: BarAreaData(
           show: true,
           color: AppColors.primary.withOpacity(0.1),
         ),
       ));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (xAxisData != null && value.toInt() >= 0 && value.toInt() < xAxisData.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      xAxisData[value.toInt()].toString(), 
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: lineBars,
      ),
    );
  }

  Widget _buildBarChart() {
     final xAxisData = _chartOption['xAxis']?['data'] as List?;
     final seriesList = _chartOption['series'] as List?;
     
     if (seriesList == null) return const SizedBox.shrink();
     
     // Simplify to single series for MVP
     final s = seriesList.first as Map<String, dynamic>;
     final data = s['data'] as List?;
     
     List<BarChartGroupData> barGroups = [];
     if (data != null) {
       for (int i = 0; i < data.length; i++) {
         barGroups.add(BarChartGroupData(
           x: i,
           barRods: [
             BarChartRodData(
               toY: double.tryParse(data[i].toString()) ?? 0,
               color: AppColors.primary,
               width: 16,
               borderRadius: BorderRadius.circular(4),
             )
           ],
         ));
       }
     }

     return BarChart(
       BarChartData(
         gridData: const FlGridData(show: false),
         titlesData: FlTitlesData(
           bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (xAxisData != null && value.toInt() >= 0 && value.toInt() < xAxisData.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      xAxisData[value.toInt()].toString(), 
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
           leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
           topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
           rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
         ),
         borderData: FlBorderData(show: false),
         barGroups: barGroups,
       ),
     );
  }
}
