import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../widgets/glass_container.dart';
import '../widgets/stat_card.dart';
import '../core/constants/app_colors.dart';
import 'login_screen.dart';
import 'chat_screen.dart';
import 'ai_assistant_screen.dart';
import 'settings_screen.dart';
import 'dynamic_dashboard_tab.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ThemeService>(context, listen: false).loadTheme();
    });
  }

  final List<Widget> _pages = [
    const DynamicDashboardTab(),
    const ChatScreen(),
    const AiAssistantScreen(),
    const SettingsScreen(),
  ];

  void _logout() async {
    await Provider.of<AuthService>(context, listen: false).logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Theme.of(context).brightness == Brightness.light
                ? [
                    const Color(0xFFF1F5F9),
                    const Color(0xFFE2E8F0),
                  ]
                : [
                    const Color(0xFF0F172A),
                    const Color(0xFF1E293B),
                  ],
          ),
        ),
        child: Column(
          children: [
            // Custom AppBar for Glassmorphism feel
            GlassContainer(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                bottom: 16,
                left: 24,
                right: 24,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Overview',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const HeroIcon(HeroIcons.arrowRightOnRectangle),
                    onPressed: _logout,
                  ),
                ],
              ),
            ),
            Expanded(child: _pages[_currentIndex]),
          ],
        ),
      ),
      bottomNavigationBar: GlassContainer(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          elevation: 0,
          backgroundColor: Colors.transparent,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: const [
            BottomNavigationBarItem(
              icon: HeroIcon(HeroIcons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: HeroIcon(HeroIcons.chatBubbleLeftRight),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: HeroIcon(HeroIcons.sparkles),
              label: 'AI',
            ),
            BottomNavigationBarItem(
              icon: HeroIcon(HeroIcons.cog6Tooth),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Statistics',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: const [
            StatCard(
              title: 'Total Revenue',
              value: '\$45,231',
              icon: HeroIcons.currencyDollar,
              trend: '+20.1%',
              isTrendUp: true,
            ),
            StatCard(
              title: 'Active Users',
              value: '2,345',
              icon: HeroIcons.users,
              trend: '+15.2%',
              isTrendUp: true,
            ),
            StatCard(
              title: 'New Orders',
              value: '123',
              icon: HeroIcons.shoppingCart,
              trend: '-5.1%',
              isTrendUp: false,
              iconColor: AppColors.warning,
            ),
            StatCard(
              title: 'Pending Issues',
              value: '12',
              icon: HeroIcons.exclamationCircle,
              trend: '-2.3%',
              isTrendUp: true, // fewer issues is good
              iconColor: AppColors.error,
            ),
          ],
        ),
      ],
    );
  }
}
