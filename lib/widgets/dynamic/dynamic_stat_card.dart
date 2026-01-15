import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:provider/provider.dart';
import '../../services/dashboard_service.dart';
import '../stat_card.dart';
import '../../core/constants/app_colors.dart';

class DynamicStatCard extends StatefulWidget {
  final Map<String, dynamic> schema;
  final Map<String, dynamic> formData;

  const DynamicStatCard({
    super.key,
    required this.schema,
    required this.formData,
  });

  @override
  State<DynamicStatCard> createState() => _DynamicStatCardState();
}

class _DynamicStatCardState extends State<DynamicStatCard> {
  String _value = '-';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final props = widget.schema['props'] ?? {};
    final searchFlow = props['searchflow'];

    if (searchFlow == null) {
      setState(() => _value = props['value'] ?? '0');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final service = DashboardService(); 
      
      final res = await service.executeFlow(searchFlow, {});
      if (res != null && res['data'] != null) {
        // userNuxt: data.value = res.data.data;
        // The value might be in a specific field or just the data itself.
        // Let's assume the flow returns a simple scalar or object with 'value'
        final data = res['data'];
        print("Data $data");
        if (data is Map && data.containsKey('count')) {
           setState(() => _value = data['count'].toString());
        } else if (data is Map && data.containsKey('value')) {
           setState(() => _value = data['value'].toString());
        } else if (data is Map && data.containsKey('data')) {
           setState(() => _value = data['data'].toString());
        } else {
           setState(() => _value = data.toString());
        }
      }
    } catch (e) {
      print("DynamicStatCard Error: $e");
      setState(() => _value = 'Error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  HeroIcons _mapIcon(String? iconName) {
    if (iconName == null) return HeroIcons.cube;
    // Basic mapping, extend as needed
    switch (iconName.toLowerCase()) {
      case 'users': return HeroIcons.users;
      case 'currency-dollar': return HeroIcons.currencyDollar;
      case 'shopping-cart': return HeroIcons.shoppingCart;
      case 'exclamation-circle': return HeroIcons.exclamationCircle;
      case 'chart-bar': return HeroIcons.chartBar;
      case 'cog': return HeroIcons.cog;
      // Add more matches
      default: return HeroIcons.cube;
    }
  }

  @override
  Widget build(BuildContext context) {
    final props = widget.schema['props'] ?? {};
    final children = widget.schema['children'] as List?;

    // If it's a "User Profile"-like card which is complex and has children,
    // we need to render the children.
    // However, if it's a StatCard, it usually doesn't have children in the Nuxt schema, 
    // OR it uses children to display the 'data'.
    
    // Check if it's a simple StatCard (no children or children only for data)
    // Nuxt CardWrapper renders UPageCard. 
    // If our current StatCard widget is too rigid, we might need a generic Card container 
    // that wraps children.
    
    // But for "content card" (like specific info card), let's see if we can use StatCard 
    // style if no children, or custom column if children exist.
    
    if (children != null && children.isNotEmpty) {
       // It's a container card. 
       // We should render children.
       // AND if one child has key='data', we inject fetching result.
       
       return Container(
         decoration: BoxDecoration(
           color: Colors.white.withOpacity(0.7),
           borderRadius: BorderRadius.circular(16),
           boxShadow: [
             BoxShadow(
               color: Colors.black.withOpacity(0.05),
               blurRadius: 10,
               offset: const Offset(0, 4),
             ),
           ],
         ),
         child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 if (props['title'] != null)
                   Padding(
                     padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 4.0),
                     child: Text(
                       props['title'], 
                       style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                     ),
                   ),
                 if (props['description'] != null)
                   Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 16.0),
                     child: Text(
                       props['description'], 
                       style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                     ),
                   ),
                 
                 ...children.map((child) {
                    final childProps = child['props'] ?? {};
                    if (childProps['key'] == 'data') {
                       // Render fetched data
                       return Padding(
                         padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                         child: Text(
                           "${_isLoading ? '...' : _value} ${childProps['text'] ?? ''}",
                           style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                         ),
                       );
                    }
                    // Import FormRender to avoid circular dep? 
                    // No, DynamicStatCard is imported by FormRender. 
                    // We can't import FormRender here easily due to circular dependency.
                    // We might need to pass a builder or refactor.
                    
                    // For now, let's just handle simple text children or ignore?
                    // Or move this logic to FormRender?
                    // FormRender calls DynamicStatCard.
                    
                    // If we need recursive rendering, DynamicStatCard should probably 
                    // just be for the "Stat" part, and "Card" container logic should be in FormRender.
                    
                    // User request: "content card, get data from json searchflow".
                    // If I look at Nuxt CardWrapper, it renders children.
                    
                    // OPTION: Pass a childBuilder to DynamicStatCard? 
                    // Or let FormRender handle the container part and only use this for fetching?
                    
                    // Let's implement a basic text renderer here for the child to avoid circular dep for now,
                    // or just return empty if complex.
                    // Usually these cards just have a text line or similar.
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(childProps['text'] ?? ''),
                    );
                 }),
                 const SizedBox(height: 16),
              ],
            ),
         ),
       );
    }
    
    // Default StatCard behavior for simple widgets
    return StatCard(
      title: props['title'] ?? 'Untitled',
      value: _isLoading ? '...' : _value,
      icon: _mapIcon(props['icon']),
      trend: props['trend'] ?? '',
      isTrendUp: props['isTrendUp'] == true,
      iconColor: props['iconColor'] != null 
          ? Color(int.parse(props['iconColor'].replaceAll('#', '0xFF'))) 
          : AppColors.primary,
    );
  }
}
