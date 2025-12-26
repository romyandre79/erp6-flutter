import 'package:flutter/material.dart';
import '../../services/dashboard_service.dart';
import '../../core/constants/app_colors.dart';

class DynamicTable extends StatefulWidget {
  final Map<String, dynamic> schema;
  final Map<String, dynamic> formData;

  const DynamicTable({
    super.key,
    required this.schema,
    required this.formData,
  });

  @override
  State<DynamicTable> createState() => _DynamicTableState();
}

class _DynamicTableState extends State<DynamicTable> {
  bool _isLoading = false;
  List<dynamic> _data = [];
  List<Map<String, dynamic>> _columns = [];
  
  // Pagination State
  int _currentPage = 1;
  int _totalPages = 0;
  int _totalRecords = 0;
  int _pageSize = 5;
  final List<int> _pageSizeOptions = [5, 10, 20, 50, 100];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _parseColumns();
    _fetchData();
  }

  void _parseColumns() {
    final children = widget.schema['children'] as List?;
    if (children == null) return;

    for (var child in children) {
      if (child['type'] == 'columns') {
        final cols = child['children'] as List?;
        if (cols != null) {
          for (var col in cols) {
            _columns.add({
               'key': col['props']?['key'] ?? '',
               'label': col['props']?['text'] ?? 'Column',
            });
          }
        }
      }
    }
  }

  Future<void> _fetchData() async {
    final props = widget.schema['props'] ?? {};
    final source = props['source'];

    if (source == null || source == '') return;

    setState(() => _isLoading = true);
    
    try {
      final service = DashboardService();
      
      final Map<String, dynamic> params = {
        'page': _currentPage,
        'limit': _pageSize, // API often uses limit/rows
        'rows': _pageSize, // some legacy might use rows
        'search': 'true', // Flag to enable search logic backend side
        // If we have search query
        if (_searchQuery.isNotEmpty) ...{
           // usually generic search param? Or specific columns?
           // Nuxt uses 'search'='true' and passes fields?
           // Let's assume generic 'search' param mapping if supported or 'q'?
           // The nuxt code sends generic search params via FormData if POST.
           // Let's pass it as a filter if possible, or assume backend handles generic search.
           // Actually Nuxt passes all filters. 
           // For now let's just send basic pagination.
           // 'search': _searchQuery ?
        }
      };
      
      // If POST based on Nuxt TablePagination logic:
      // dataForm.append('page', currentPage.value);
      // dataForm.append('rows', pageSize.value);
      // dataForm.append('search', 'true');
      
      // We are using executeFlow which likely POSTs.
      // We can pass params map.
      params['flowname'] = source;
      params['menu'] = 'admin'; // Context?
      
      // Add simple search if any
      // Nuxt implementation suggests complex search per column OR simple generic search
      // Let's assume there is a 'search' param in the flow that accepts the query?
      // Or maybe we map it?
      // nuxt: "const params = { page: ..., limit: ..., search: searchQuery.value }" if GET
      
      // If executeFlow is POST, we pass body.
      // Let's just pass everything in the map string dynamic.
      
      final res = await service.executeFlow(source, params);
      
      if (res != null) {
         if (res['data'] != null) {
            final d = res['data'];
            if (d['data'] is List) {
               setState(() {
                 _data = d['data'];
                 _currentPage = int.tryParse(d['page']?.toString() ?? '1') ?? 1;
                 _totalRecords = int.tryParse(d['total']?.toString() ?? '0') ?? 0;
                 // If totalPages not provided, calc it
                 _totalPages = int.tryParse(d['meta']?['totalPages']?.toString() ?? '') ?? 
                               (_totalRecords / _pageSize).ceil();
                 if (_totalPages < 1) _totalPages = 1;
               });
            }
         }
      }
    } catch (e) {
      print("DynamicTable Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onPageChanged(int newPage) {
    if (newPage < 1 || newPage > _totalPages) return;
    setState(() => _currentPage = newPage);
    _fetchData();
  }

  void _onPageSizeChanged(int? newSize) {
    if (newSize != null) {
      setState(() {
        _pageSize = newSize;
        _currentPage = 1; // Reset to first page
      });
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine title from schema props
    final title = widget.schema['props']?['text'] ?? 'Table';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
           BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title & Search
          Row(
            children: [
               Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
               const Spacer(),
               // Simple Search
               // For MVP just a button? Or small layout?
               // On mobile/tablet, space is tight.
            ],
          ),
          const SizedBox(height: 16),
          
          // Table Content
          if (_isLoading)
             const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
          else
             SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 600), // Min width to force horizontal scroll if needed
                  child: DataTable(
                    columns: _columns.isEmpty 
                      ? [const DataColumn(label: Text('No columns'))]
                      : _columns.map((col) => DataColumn(
                          label: Text(
                            col['label'].toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )
                        )).toList(),
                    rows: _data.map((row) {
                      return DataRow(
                        cells: _columns.isEmpty 
                          ? [const DataCell(Text('-'))]
                          : _columns.map((col) {
                              final val = row[col['key']] ?? '-';
                              return DataCell(Text(val.toString()));
                            }).toList()
                      );
                    }).toList(),
                  ),
                ),
             ),
             
          const SizedBox(height: 16),
          
          // Footer: Pagination Controls
          Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
                // Info
                Text("Page $_currentPage / $_totalPages ($_totalRecords items)", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                
                // Controls
                Row(
                  children: [
                     // Page Size Dropdown
                     DropdownButton<int>(
                       value: _pageSize,
                       items: _pageSizeOptions.map((e) => DropdownMenuItem(value: e, child: Text("$e"))).toList(),
                       onChanged: _onPageSizeChanged,
                       underline: const SizedBox.shrink(),
                       style: const TextStyle(fontSize: 12, color: Colors.black),
                     ),
                     const SizedBox(width: 8),
                     
                     // Nav Buttons
                     IconButton(
                       icon: const Icon(Icons.first_page),
                       onPressed: _currentPage > 1 ? () => _onPageChanged(1) : null,
                     ),
                     IconButton(
                       icon: const Icon(Icons.chevron_left),
                       onPressed: _currentPage > 1 ? () => _onPageChanged(_currentPage - 1) : null,
                     ),
                     IconButton(
                       icon: const Icon(Icons.chevron_right),
                       onPressed: _currentPage < _totalPages ? () => _onPageChanged(_currentPage + 1) : null,
                     ),
                     IconButton(
                       icon: const Icon(Icons.last_page),
                       onPressed: _currentPage < _totalPages ? () => _onPageChanged(_totalPages) : null,
                     ),
                  ],
                )
             ],
          )
        ],
      ),
    );
  }
}
