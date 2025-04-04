import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/gpt_service.dart';
import '../services/social_media_service.dart';
import '../widgets/suggestion_box.dart';
import '../widgets/social_media_row.dart';
import '../dialogs/profile_analysis_dialog.dart';
import '../dialogs/profile_suggestions_dialog.dart';
import '../dialogs/analytics_dialog.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    
    // Initialize services
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServices();
    });
  }

  Future<void> _initializeServices() async {
    try {
      final socialMediaService = Provider.of<SocialMediaService>(context, listen: false);
      final gptService = Provider.of<GptService>(context, listen: false);
      
      // Load platforms and suggestions
      await Future.wait([
        socialMediaService.loadConnectedPlatforms(),
        gptService.fetchSuggestions(),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize services: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.user;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildAppBar(context, user),
          Expanded(
            child: _buildMainContent(),
          ),
          const SuggestionBox(),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left menu button
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: _handleMenuSelection,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'dashboard',
                  child: Text('Dashboard'),
                ),
                const PopupMenuItem(
                  value: 'profile_analysis',
                  child: Text('Profile Analysis'),
                ),
                const PopupMenuItem(
                  value: 'profile_suggestions',
                  child: Text('Profile Suggestions'),
                ),
                const PopupMenuItem(
                  value: 'analytics',
                  child: Text('Analytics'),
                ),
              ],
            ),
            
            // App Title
            const Text(
              'Elevate Dashboard',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            // User profile section
            Row(
              children: [
                // User info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user?.displayName ?? 'User',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      user?.email ?? 'user@example.com',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                // Logout button
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => _handleLogout(context),
                  tooltip: 'Logout',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        // Social Media Integration section
        const SocialMediaRow(),
        const SizedBox(height: 24),
        
        // Quick Stats Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quick Stats',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              _buildQuickStats(),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Recent Activity Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              _buildRecentActivity(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Consumer<SocialMediaService>(
      builder: (context, socialMediaService, child) {
        final platforms = socialMediaService.platforms;
        
        if (platforms.isEmpty) {
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Connect a social media platform to see your stats here.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
          ),
          itemCount: platforms.length,
          itemBuilder: (context, index) {
            final platform = platforms[index];
            final metrics = platform.metrics;
            
            if (metrics == null) {
              return const SizedBox();
            }
            
            String primaryMetric = '';
            String primaryMetricLabel = '';
            Color platformColor;
            
            switch (platform.name.toLowerCase()) {
              case 'linkedin':
                primaryMetric = metrics['connections']?.toString() ?? '0';
                primaryMetricLabel = 'CONNECTIONS';
                platformColor = const Color(0xFF0077B5);
                break;
              case 'twitter':
                primaryMetric = metrics['followers']?.toString() ?? '0';
                primaryMetricLabel = 'FOLLOWERS';
                platformColor = const Color(0xFF1DA1F2);
                break;
              case 'instagram':
                primaryMetric = metrics['followers']?.toString() ?? '0';
                primaryMetricLabel = 'FOLLOWERS';
                platformColor = const Color(0xFFE1306C);
                break;
              case 'facebook':
                primaryMetric = metrics['friends']?.toString() ?? '0';
                primaryMetricLabel = 'FRIENDS';
                platformColor = const Color(0xFF1877F2);
                break;
              default:
                primaryMetric = metrics['followers']?.toString() ?? '0';
                primaryMetricLabel = 'FOLLOWERS';
                platformColor = const Color(0xFF6B4EFF);
            }
            
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.fromRGBO(platformColor.red, platformColor.green, platformColor.blue, 0.8),
                      platformColor,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      platform.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      primaryMetric,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      primaryMetricLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRecentActivity() {
    // This would normally be populated with real activity data
    // For this demo, we'll use mock data
    final activities = [
      {
        'platform': 'LinkedIn',
        'action': 'Profile view',
        'detail': '15 new profile views this week',
        'time': '2 hours ago',
        'icon': Icons.visibility,
        'color': const Color(0xFF0077B5),
      },
      {
        'platform': 'Twitter',
        'action': 'New follower',
        'detail': '@techinfluencer started following you',
        'time': '5 hours ago',
        'icon': Icons.person_add,
        'color': const Color(0xFF1DA1F2),
      },
      {
        'platform': 'Instagram',
        'action': 'Post engagement',
        'detail': 'Your latest post received 45 likes',
        'time': '1 day ago',
        'icon': Icons.favorite,
        'color': const Color(0xFFE1306C),
      },
    ];
    
    return Column(
      children: activities.map((activity) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: Color.fromRGBO(
                (activity['color'] as Color).red,
                (activity['color'] as Color).green,
                (activity['color'] as Color).blue,
                0.2,
              ),
              child: Icon(
                activity['icon'] as IconData,
                color: activity['color'] as Color,
              ),
            ),
            title: Text(
              '${activity['platform']} - ${activity['action']}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(activity['detail'] as String),
                const SizedBox(height: 4),
                Text(
                  activity['time'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'dashboard':
        _initializeServices();
        break;
      case 'profile_analysis':
        showDialog(
          context: context,
          builder: (context) => const ProfileAnalysisDialog(),
        ).catchError((e) => _handleError('Failed to show profile analysis: $e'));
        break;
      case 'profile_suggestions':
        showDialog(
          context: context,
          builder: (context) => const ProfileSuggestionsDialog(),
        ).catchError((e) => _handleError('Failed to show suggestions: $e'));
        break;
      case 'analytics':
        showDialog(
          context: context,
          builder: (context) => const AnalyticsDialog(),
        ).catchError((e) => _handleError('Failed to show analytics: $e'));
        break;
    }
  }

  void _handleLogout(BuildContext context) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.logout();
      
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      _handleError('Failed to logout: $e');
    }
  }
} 