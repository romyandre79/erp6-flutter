import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../../core/constants/app_colors.dart';
import 'dynamic_chart.dart';
import 'dynamic_stat_card.dart';
import 'dynamic_table.dart';
import 'dynamic_select.dart';
import '../../services/dashboard_service.dart';

class FormRender extends StatefulWidget {
  final dynamic schema; // Map or List
  final Map<String, dynamic> formData;

  const FormRender({
    super.key,
    required this.schema,
    required this.formData,
  });

  @override
  State<FormRender> createState() => _FormRenderState();
}

class _FormRenderState extends State<FormRender> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    String? flowName;
    
    // Recursive search helper
    String? findFlow(dynamic node) {
      if (node is Map) {
        if (node['type'] == 'action') {
           final props = node['props'] ?? {};
           // Check onRead first, then onGet
           if (props['onRead'] != null && props['onRead'].toString().isNotEmpty) return props['onRead'];
           if (props['onGet'] != null && props['onGet'].toString().isNotEmpty) return props['onGet'];
        }
        if (node['children'] is List) {
           for (var child in node['children']) {
             final res = findFlow(child);
             if (res != null) return res;
           }
        }
      } else if (node is List) {
        for (var child in node) {
           final res = findFlow(child);
           if (res != null) return res;
        }
      }
      return null;
    }

    flowName = findFlow(widget.schema);

    if (flowName == null || flowName.isEmpty) return;

    try {
      final service = DashboardService();
      final res = await service.executeFlow(flowName, {});
      
      if (res != null) {
        // Assume data is in res['data']['data'] and it's a Map of fields
        if (res['data'] != null && res['data']['data'] != null) {
           final data = res['data']['data'];
           
           void updateFormData(Map<String, dynamic> newData) {
              setState(() {
                widget.formData.addAll(newData);
                // Also update controllers
                newData.forEach((key, value) {
                   if (_controllers.containsKey(key)) {
                     _controllers[key]!.text = value.toString();
                   }
                });
              });
           }

           if (data is Map<String, dynamic>) {
              updateFormData(data);
           } else if (data is List && data.isNotEmpty) {
              // If list, maybe take first item?
              if (data.first is Map<String, dynamic>) {
                 updateFormData(data.first);
              }
           }
        }
      }
    } catch (e) {
      print("FormRender AutoFetch Error: $e");
    }
  }
  @override
  Widget build(BuildContext context) {
    if (widget.schema == null) return const SizedBox.shrink();

    // If schema is a list, render a column of components
    if (widget.schema is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: (widget.schema as List).map((node) => _renderComponent(node)).toList(),
      );
    }
    
    // If schema is a single object (root node)
    if (widget.schema is Map) {
       // Usually root might have children
       if (widget.schema['children'] != null) {
         return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: (widget.schema['children'] as List).map((node) => _renderComponent(node)).toList(),
         );
       }
       return _renderComponent(widget.schema);
    }

    return const Text('Invalid Schema');
  }

  Widget _renderComponent(Map<String, dynamic> component) {
    final type = (component['type'] ?? '').toString().toLowerCase();
    final props = component['props'] ?? {};
    final key = props['key'] ?? '';

    switch (type) {
      case 'title':
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            props['text'] ?? '',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
          ),
        );

      case 'subtitle':
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Text(
            props['text'] ?? '',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
        );

      case 'label':
         return Padding(
          padding: const EdgeInsets.only(bottom: 4.0, top: 8.0),
          child: Text(
            (props['text'] ?? '').toString().toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        );

      case 'text':
      case 'longtext':
      case 'number':
      case 'password':
        return _buildTextField(component, type);

      case 'image':
        final src = props['src'] ?? '';
        if (src.isEmpty) return const SizedBox.shrink();
        
        // Handle potential base64 or url
        // For MVP assuming URL or asset placeholder
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: NetworkImage(src),
              fit: BoxFit.cover,
              onError: (_, __) => const Icon(Icons.broken_image), // Fallback
            ),
          ),
        );
        
      case 'chart':
        return DynamicChart(
          schema: component, 
          formData: widget.formData
        );

      case 'card':
        // If it has searchflow, treat as StatCard, otherwise generic container?
        // CardWrapper in Nuxt handles both, but let's prioritize StatCard for Dashboard.
        if (props['searchflow'] != null || props['value'] != null) {
           return DynamicStatCard(
             schema: component,
             formData: widget.formData,
           );
        }
        // Fallthrough to container if no data fetching involved (or handle as generic card)
        // For now, let's treat all dashboard 'cards' as DynamicStatCards if they are top level, 
        // but 'container' handles recursive.
        // Let's use DynamicStatCard if it looks like a stat card.
        return DynamicStatCard(
             schema: component,
             formData: widget.formData,
        );

      case 'table':
         return DynamicTable(
           schema: component,
           formData: widget.formData,
         );
      
      case 'form':
         // Just a container for now
         final children = component['children'] as List?;
         if (children == null) return const SizedBox.shrink();
         return Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: children.map((child) => _renderComponent(child)).toList(),
         );

      case 'date':
      case 'datetime':
         // Treat as text for MVP, or add DatePicker
         // Let's use _buildTextField but with onTap logic if needed
         // For now, simple text input specific for date
         return _buildTextField(component, 'date');

      case 'select':
         return DynamicSelect(
           schema: component,
           formData: widget.formData,
         );

      case 'button':
         return Padding(
           padding: const EdgeInsets.symmetric(vertical: 8.0),
           child: ElevatedButton(
             onPressed: () {
                // Handle action props['onClick']
             },
             style: ElevatedButton.styleFrom(
               backgroundColor: AppColors.primary,
               foregroundColor: Colors.white,
               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
             ),
             child: Text(props['text'] ?? 'Button'),
           ),
         );

      case 'widget':
      case 'cards': // Plural often container
      case 'tables':
      case 'container':
      case 'div':
      // case 'card': // Moved up
        // Recursive rendering for containers
        final children = component['children'] as List?;
        if (children == null) return const SizedBox.shrink();
        
        return Container(
           margin: const EdgeInsets.only(bottom: 16),
           padding: const EdgeInsets.all(12),
           decoration: BoxDecoration(
             // Only show border/bg for specific types if desired
             // border: Border.all(color: Colors.grey.withOpacity(0.2)),
             // borderRadius: BorderRadius.circular(8),
             // color: Colors.white.withOpacity(0.5),
           ),
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: children.map((child) => _renderComponent(child)).toList(),
           ),
        );

      default:
        // Fallback for unknown types or hidden
        // print("Unknown component type: $type");
        return const SizedBox.shrink();
    }
  }

  Widget _buildTextField(Map<String, dynamic> component, String type) {
    final props = component['props'] ?? {};
    final key = props['key'] ?? '';
    final label = props['text'] ?? '';
    final placeholder = props['place'] ?? '';
    
    // Initialize form data if needed
    if (key.isNotEmpty && !widget.formData.containsKey(key)) {
      widget.formData[key] = '';
    }

    TextInputType funcInputType() {
      if (type == 'number') return TextInputType.number;
      if (type == 'longtext') return TextInputType.multiline;
      return TextInputType.text;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty)
             Text(
                label.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary),
             ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _controllers.putIfAbsent(key, () => TextEditingController(text: widget.formData[key]?.toString())),
            keyboardType: funcInputType(),
            maxLines: type == 'longtext' ? 4 : 1,
            obscureText: type == 'password',
            onChanged: (val) {
              widget.formData[key] = val;
            },
            decoration: InputDecoration(
              hintText: placeholder,
              filled: true,
              fillColor: Colors.white.withOpacity(0.8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
