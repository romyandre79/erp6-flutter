import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/dashboard_service.dart';
import '../widgets/dynamic/form_render.dart';
import '../widgets/glass_container.dart';

class DynamicDashboardTab extends StatefulWidget {
  const DynamicDashboardTab({super.key});

  @override
  State<DynamicDashboardTab> createState() => _DynamicDashboardTabState();
}

class _DynamicDashboardTabState extends State<DynamicDashboardTab> {
  final DashboardService _dashboardService = DashboardService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _groupedWidgets = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final widgets = await _dashboardService.fetchWidgets('admin');
    
    // Process widgets
    // Group by dashgroup
    // Sort by position
    
    final Map<int, List<dynamic>> groups = {};
    
    for (var widget in widgets) {
      final groupKey = int.tryParse(widget['dashgroup']?.toString() ?? '0') ?? 0;
      if (!groups.containsKey(groupKey)) {
        groups[groupKey] = [];
      }
      
      // Parse widgetform if string
      if (widget['widgetform'] is String) {
        try {
          widget['widgetform'] = jsonDecode(widget['widgetform']);
        } catch (e) {
          print("Error parsing widgetform for ${widget['widgetname']}: $e");
          widget['widgetform'] = null;
        }
      }
      
      groups[groupKey]!.add(widget);
    }
    
    // Sort groups and items
    final sortedGroupKeys = groups.keys.toList()..sort();
    
    final List<Map<String, dynamic>> result = [];
    for (var key in sortedGroupKeys) {
      final items = groups[key]!;
      items.sort((a, b) {
        final posA = int.tryParse(a['position']?.toString() ?? '0') ?? 0;
        final posB = int.tryParse(b['position']?.toString() ?? '0') ?? 0;
        return posA.compareTo(posB);
      });
      result.add({'group': key, 'items': items});
    }

    if (mounted) {
      setState(() {
        _groupedWidgets = result;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_groupedWidgets.isEmpty) {
      return const Center(child: Text('No widgets found. Check backend or .env configuration.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _groupedWidgets.length,
      itemBuilder: (context, index) {
        final group = _groupedWidgets[index];
        final items = group['items'] as List<dynamic>;

        return Column(
          children: [
            // Render items in this group
            // Ideally should be a Row if they fit, or wrapped.
            // Nuxt version: flex-row flex-nowrap gap-3
            
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: items.map((item) {
                  final webFormat = item['webformat']?.toString() ?? '';
                  int flex = 1;
                  if (webFormat.contains('w-full')) flex = 12;
                  else if (webFormat.contains('w-11/12')) flex = 11;
                  else if (webFormat.contains('w-10/12')) flex = 10; // 5/6
                  else if (webFormat.contains('w-3/4')) flex = 9;
                  else if (webFormat.contains('w-2/3')) flex = 8;
                  else if (webFormat.contains('w-1/2')) flex = 6;
                  else if (webFormat.contains('w-5/12')) flex = 5;
                  else if (webFormat.contains('w-1/3')) flex = 4;
                  else if (webFormat.contains('w-1/4')) flex = 3;
                  else if (webFormat.contains('w-1/6')) flex = 2;
                  else if (webFormat.contains('w-1/12')) flex = 1;
                  else flex = 12; 
                  
                  return Expanded(
                    flex: flex,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: GlassContainer(
                        padding: const EdgeInsets.all(16),
                        child: FormRender(
                            schema: item['widgetform'],
                            formData: {}, 
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
