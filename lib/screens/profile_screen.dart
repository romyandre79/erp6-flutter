import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:provider/provider.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = await authService.getUser();
    if (mounted) {
      setState(() {
        _user = user;
        _isLoading = false;
      });
    }
  }
  
  String _getInitials() {
    if (_user == null) return 'U';
    final name = _user!['realname'] ?? _user!['username'] ?? 'User'; // Prioritize realname usually
    // Fallback if realname is like "John Doe"
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    // Safety check if user data missing (e.g. not logged in fully)
    final user = _user ?? {'username': 'Guest', 'email': '', 'realname': 'Guest User'};

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 280.0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 0,
            forceElevated: true,
            title: const Text('My Profile', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: const HeroIcon(HeroIcons.cog6Tooth, color: Colors.black54),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.blue.shade50, Colors.white],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60), // Spacing for AppBar
                    Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
                            ],
                            image: (user['photo'] != null && user['photo'].toString().isNotEmpty)
                                ? DecorationImage(image: NetworkImage(user['photo']), fit: BoxFit.cover)
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: (user['photo'] == null || user['photo'].toString().isEmpty) 
                              ? Text(_getInitials(), style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.grey.shade400))
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade600,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const HeroIcon(HeroIcons.camera, color: Colors.white, size: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(user['realname'] ?? user['username'] ?? 'User', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text(user['position'] ?? 'Software Engineer', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)), // Assuming 'position' field exists or placeholder
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _StatusBadge(label: 'Active', color: Colors.green.shade100, textColor: Colors.green.shade700),
                        const SizedBox(width: 8),
                        _StatusBadge(label: 'Full-Time', color: Colors.blue.shade100, textColor: Colors.blue.shade700),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                 const _WorkInfoCard(),
                 const SizedBox(height: 16),
                 _PersonalInfoCard(user: user),
                 const SizedBox(height: 16),
                 const _AddressInfoCard(),
                 const SizedBox(height: 32),
                 SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _StatusBadge({required this.label, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
    );
  }
}

class _WorkInfoCard extends StatelessWidget {
  const _WorkInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
             children: [
               HeroIcon(HeroIcons.briefcase, size: 20, color: Colors.blue.shade600),
               const SizedBox(width: 8),
               const Text('Work Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
             ],
          ),
          const Divider(height: 24),
          const _InfoRow(label: 'DEPARTMENT', value: 'Engineering'),
          const SizedBox(height: 16),
          const _InfoRow(label: 'MANAGER', value: 'Jane Smith'),
          const SizedBox(height: 16),
          const _InfoRow(label: 'DATE JOINED', value: 'Jan 10, 2022'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade500, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87)),
      ],
    );
  }
}

class _PersonalInfoCard extends StatelessWidget {
  final Map<String, dynamic> user;
  const _PersonalInfoCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
             children: [
               HeroIcon(HeroIcons.user, size: 20, color: Colors.blue.shade600),
               const SizedBox(width: 8),
               const Text('Personal Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
             ],
          ),
          const Divider(height: 24),
          const _Label('Username'),
          _TextField(initialValue: user['username'] ?? '', readOnly: true),
          const SizedBox(height: 16),
          const _Label('Full Name'),
          _TextField(initialValue: user['realname'] ?? '', readOnly: true),
          const SizedBox(height: 16),
          const _Label('Email Address'),
          _TextField(initialValue: user['email'] ?? '', icon: HeroIcons.envelope, readOnly: true), // Assuming backend email is also readonly or handled elsewhere
          const SizedBox(height: 16),
          const _Label('Phone Number'),
          _TextField(initialValue: user['phone'] ?? '', icon: HeroIcons.phone),
        ],
      ),
    );
  }
}

class _AddressInfoCard extends StatelessWidget {
  const _AddressInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
             children: [
               HeroIcon(HeroIcons.mapPin, size: 20, color: Colors.blue.shade600),
               const SizedBox(width: 8),
               const Text('Address Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
             ],
          ),
          const Divider(height: 24),
          const _Label('Street Address'),
          const _TextField(initialValue: '123 Main St, Apt 4B'),
          const SizedBox(height: 16),
          const _Label('City'),
          const _TextField(initialValue: 'New York'),
          const SizedBox(height: 16),
          const _Label('State/Province'),
          const _TextField(initialValue: 'NY'),
          const SizedBox(height: 16),
          const _Label('Zip Code'),
          const _TextField(initialValue: '10001'),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
    );
  }
}

class _TextField extends StatelessWidget {
  final String? initialValue;
  final bool readOnly;
  final HeroIcons? icon;

  const _TextField({this.initialValue, this.readOnly = false, this.icon});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      readOnly: readOnly,
      style: TextStyle(color: Colors.grey.shade800, fontSize: 14),
      decoration: InputDecoration(
        filled: true,
        fillColor: readOnly ? Colors.grey.shade50 : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.blue.shade500, width: 1.5)),
        prefixIcon: icon != null ? HeroIcon(icon!, color: Colors.grey.shade400, style: HeroIconStyle.solid, size: 20) : null,
      ),
    );
  }
}
