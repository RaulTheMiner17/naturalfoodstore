import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Supabase

import '../main.dart'; // To access supabase client
import '../admin/admin_dashboard_screen.dart'; // Import admin screen
import '../screens/order_history_screen.dart'; // Import the order history screen
import '../screens/saved_addresses_screen.dart'; // Import the saved addresses screen
import '../screens/faqs_page.dart'; // Import the FAQs page
import '../screens/contact_us_page.dart'; // Import the Contact Us page
import '../screens/account_settings_screen.dart'; // <<< Import the new screen

// Convert ProfileTab to a StatefulWidget
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  String _userEmail = 'Loading...';
  String? _userName; // To store the user's name
  String? _avatarUrl; // To store the avatar URL
  bool _isLoading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    // Load user data when the widget is initialized
    _loadUserData();

    // Optional: Listen for auth state changes to refresh data if needed
    supabase.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.userUpdated || data.event == AuthChangeEvent.signedIn) {
        _loadUserData(); // Reload data if user info might have changed
      }
    });
  }

  Future<void> _loadUserData() async {
    // Avoid unnecessary rebuilds if already loading
    if(!mounted) return; // Check if widget is still in the tree
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      final user = supabase.auth.currentUser;
      if (user != null && mounted) {
        setState(() {
          _userEmail = user.email ?? 'Not logged in';
          // Get name and avatar URL from metadata
          _userName = user.userMetadata?['full_name'] as String?;
          _avatarUrl = user.userMetadata?['avatar_url'] as String?;
          _isAdmin = (_userEmail == 'natural.f00dst0r3s@gmail.com');
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _userEmail = 'Not logged in';
          _userName = null;
          _avatarUrl = null;
          _isAdmin = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        print("Error loading user data: $e");
        setState(() {
          _userEmail = 'Error loading data';
          _userName = null;
          _avatarUrl = null;
          _isAdmin = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define text styles for consistency
    final titleStyle = Theme.of(context).textTheme.titleMedium;
    final subtitleStyle = Theme.of(context)
        .textTheme
        .bodyMedium
        ?.copyWith(color: Colors.grey[600]);
    final listTileTitleStyle = Theme.of(context)
        .textTheme
        .titleMedium
        ?.copyWith(fontSize: 16); // Slightly smaller for list tiles

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loader
          : RefreshIndicator( // Optional: Add pull-to-refresh
        onRefresh: _loadUserData,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
          children: <Widget>[
            // --- User Info Section ---
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 55, // Slightly larger
                  backgroundColor: const Color(0xFFE0E0E0), // Lighter grey
                  // Display network image if URL exists, else placeholder
                  backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
                      ? NetworkImage(_avatarUrl!)
                      : null,
                  child: _avatarUrl == null || _avatarUrl!.isEmpty
                      ? const Icon(
                    Icons.person_outline,
                    size: 60,
                    color: Color(0xFFBDBDBD), // Darker grey icon
                  )
                      : null, // Don't show icon if image is loading/loaded
                ),
                const SizedBox(height: 16),
                // Display User Name if available
                if (_userName != null && _userName!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      _userName!,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Text(
                  _userEmail, // Display user email
                  style: _userName != null && _userName!.isNotEmpty
                      ? subtitleStyle // Use subtitle style if name exists
                      : Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600), // Use headline if only email
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            const SizedBox(height: 30), // Space before options

            // --- General Options Section ---
            _buildSectionTitle(context, 'Account'),
            _buildProfileOption(
              context,
              icon: Icons.settings_outlined,
              title: 'Account Settings',
              subtitle: 'Manage your profile details',
              onTap: () async {
                // Navigate and wait for result (optional) then refresh
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AccountSettingsScreen()),
                );
                // Refresh data when returning from settings
                if (mounted) {
                  _loadUserData();
                }
              },
            ),
            _buildProfileOption(
              context,
              icon: Icons.location_on_outlined,
              title: 'Saved Addresses',
              subtitle: 'Manage your delivery addresses',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SavedAddressesScreen(),
                  ),
                );
              },
            ),
            _buildProfileOption(
              context,
              icon: Icons.credit_card_outlined,
              title: 'Payment Methods',
              subtitle: 'Manage your cards',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text(
                        'Navigate to Payment Methods (Not Implemented)')));
              },
            ),
            const SizedBox(height: 20), // Space before next section

            _buildSectionTitle(context, 'Activity'),
            _buildProfileOption(
              context,
              icon: Icons.history_outlined,
              title: 'Order History',
              subtitle: 'View your past orders',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OrderHistoryScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 20), // Space before next section

            _buildSectionTitle(context, 'Support'),
            _buildProfileOption(
              context,
              icon: Icons.help_outline,
              title: 'Help & Support',
              subtitle: 'Get assistance',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ContactUsPage(),
                  ),
                );
              },
            ),
            _buildProfileOption(
              context,
              icon: Icons.question_answer_outlined,
              title: 'FAQs',
              subtitle: 'Frequently asked questions',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FaqsPage(),
                  ),
                );
              },
            ),

            // --- Admin Panel Section ---
            if (_isAdmin) ...[
              const SizedBox(height: 20),
              const Divider(height: 1, thickness: 0.5),
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined,
                    color: Colors.deepOrangeAccent),
                title: Text('Admin Panel',
                    style: listTileTitleStyle?.copyWith(
                        color: Colors.deepOrangeAccent)),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AdminDashboardScreen()),
                  );
                },
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 8.0), // Adjust padding
              ),
              const Divider(height: 1, thickness: 0.5),
            ],
            const SizedBox(height: 40), // Space at the bottom
          ],
        ),
      ),
    );
  }

  // Helper widget to build section titles (Unchanged)
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Colors.grey[500],
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // Helper widget to build consistent ListTiles for profile options (Unchanged)
  Widget _buildProfileOption(
      BuildContext context, {
        required IconData icon,
        required String title,
        String? subtitle,
        required VoidCallback onTap,
      }) {
    return ListTile(
      leading: Icon(icon,
          color: Theme.of(context)
              .primaryColorDark), // Use a consistent icon color
      title: Text(title,
          style:
          Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16)),
      subtitle: subtitle != null
          ? Text(subtitle,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey[600]))
          : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
      contentPadding:
      const EdgeInsets.symmetric(vertical: 4.0), // Adjust vertical padding
      visualDensity: VisualDensity.compact, // Make tiles slightly denser
    );
  }
}