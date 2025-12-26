import 'package:flutter/material.dart';
import '../../services/dashboard_service.dart';
import '../../core/constants/app_colors.dart';

class DynamicSelect extends StatefulWidget {
  final Map<String, dynamic> schema;
  final Map<String, dynamic> formData;

  const DynamicSelect({
    super.key,
    required this.schema,
    required this.formData,
  });

  @override
  State<DynamicSelect> createState() => _DynamicSelectState();
}

class _DynamicSelectState extends State<DynamicSelect> {
  bool _isLoading = false;
  List<dynamic> _options = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchOptions();
  }

  Future<void> _fetchOptions() async {
    final props = widget.schema['props'] ?? {};
    final source = props['source'];

    if (source == null || source == '') return;

    setState(() => _isLoading = true);
    
    try {
      final service = DashboardService();
      // Only generic get, no params usually for simple combo
      final res = await service.executeFlow(source, {});
      
      if (res != null) {
         // Expecting res['data']['data'] as list of options
         if (res['data'] != null && res['data']['data'] is List) {
            setState(() {
              _options = res['data']['data'];
              _isLoading = false;
            });
         }
      }
    } catch (e) {
      print("DynamicSelect Error: $e");
      setState(() {
        _error = "Failed to load options";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final props = widget.schema['props'] ?? {};
    final key = props['key'] ?? '';
    final labelText = props['text'] ?? '';
    final labelField = props['label'] ?? 'name'; // Field to display in dropdown
    final valueField = key; // Usually the key matches the ID field in response? e.g. languageid
    
    // Ensure form data has key
    if (!widget.formData.containsKey(key)) {
        // widget.formData[key] = null; // Don't nullify if not there, wait for user or init
    }
    
    var currentValue = widget.formData[key];
    
    // Validate current value exists in options logic? 
    // Sometimes value is loaded from profile but options not loaded yet -> handled by isLoading
    // Sometimes value is distinct type (int vs string).
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (labelText.isNotEmpty)
             Text(
                labelText.toString().toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary),
             ),
          const SizedBox(height: 6),
          _isLoading 
            ? const LinearProgressIndicator(minHeight: 2)
            : DropdownButtonFormField<dynamic>(
                value: _isValidValue(currentValue) ? currentValue : null,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: _options.map((option) {
                    final display = option[labelField]?.toString() ?? 'Unknown';
                    final val = option[valueField];
                    return DropdownMenuItem<dynamic>(
                      value: val,
                      child: Text(display),
                    );
                }).toList(),
                onChanged: (val) {
                   setState(() {
                     widget.formData[key] = val;
                   });
                },
                hint: Text(props['place'] ?? 'Select...'),
              ),
        ],
      ),
    );
  }

  bool _isValidValue(dynamic val) {
    if (val == null) return false;
    // Check if val exists in _options values
    final props = widget.schema['props'] ?? {};
    final key = props['key'] ?? '';
    final valueField = key;
    
    return _options.any((opt) {
        final optVal = opt[valueField];
        // Handle type mismatch string vs int
        return optVal.toString() == val.toString();
    });
  }
}
