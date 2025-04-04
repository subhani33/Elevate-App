import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/social_media_service.dart';
import '../services/gpt_service.dart';
import '../widgets/social_media_row.dart';
import '../widgets/suggestion_box.dart';
import '../dialogs/add_platform_dialog.dart';
import '../dialogs/profile_analysis_dialog.dart';
import '../dialogs/profile_suggestions_dialog.dart';
import '../dialogs/analytics_dialog.dart';
import '../dialogs/manage_profiles_dialog.dart';
import '../components/rotating_globe.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  final TextEditingController _gptQueryController = TextEditingController();
  bool _isSubmitting = false;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize services
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServices();
    });
  }

  @override
  void dispose() {
    _gptQueryController.dispose();
    super.dispose();
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
        _showErrorSnackBar('Failed to initialize services: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _submitGptQuery() async {
    final query = _gptQueryController.text.trim();
    if (query.isEmpty) {
      _showErrorSnackBar('Please enter a query');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final gptService = Provider.of<GptService>(context, listen: false);
      final response = await gptService.getGptResponse(query);
      
      if (mounted) {
        _showGptResponseDialog(response);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to get response: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showGptResponseDialog(String response) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI Response'),
        content: SingleChildScrollView(
          child: Text(response),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAddPlatformDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddPlatformDialog(),
    );
  }

  void _showManageProfilesDialog() {
    showDialog(
      context: context,
      builder: (context) => const ManageProfilesDialog(),
    );
  }

  void _showProfileAnalysisDialog() {
    showDialog(
      context: context,
      builder: (context) => const ProfileAnalysisDialog(),
    );
  }

  void _showProfileSuggestionsDialog() {
    showDialog(
      context: context,
      builder: (context) => const ProfileSuggestionsDialog(),
    );
  }

  void _showAnalyticsDialog() {
    showDialog(
      context: context,
      builder: (context) => const AnalyticsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.user;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      // Use SafeArea to prevent overflow at the top (status bar)
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context, user),
            // Use Expanded with SingleChildScrollView to prevent pixel overflow
            Expanded(
              child: _buildMainContent(),
            ),
            // Wrap SuggestionBox in ConstrainedBox to limit its height
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: const SuggestionBox(),
            ),
          ],
        ),
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
            color: const Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
          Row(
            children: [
              const RotatingGlobe(size: 24),
              const SizedBox(width: 8),
              const Text(
                'Elevate',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          // User profile section
          Row(
            children: [
              // User info - limit width to prevent overflow
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user?.displayName ?? 'User',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      user?.email ?? 'user@example.com',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
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
    );
  }

  Widget _buildMainContent() {
    // SingleChildScrollView to handle content overflow
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Social Media Integration section
          _buildSocialMediaSection(),
          const SizedBox(height: 16),
          
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
                const SizedBox(height: 12),
                _buildQuickStats(),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // GPT Section
          _buildGptSection(),
          
          const SizedBox(height: 16),
          
          // Platform Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Boost Your Profile',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                _buildActionCards(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialMediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Social Platforms',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _showManageProfilesDialog,
                    icon: const Icon(Icons.settings),
                    label: const Text('Manage Profiles'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _showAddPlatformDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Platform'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const SocialMediaRow(),
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
            elevation: 2,
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
              elevation: 2,
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

  Widget _buildGptSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withOpacity(0.95),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.smart_toy,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'GPT Interaction',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Ask Elevate AI about your social media presence, content ideas, or engagement strategies:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _gptQueryController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Example: "How can I improve my engagement rate on LinkedIn?"',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                fillColor: Colors.grey[50],
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitGptQuery,
                icon: _isSubmitting 
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(_isSubmitting ? 'Processing...' : 'Get AI Insights'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCards() {
    final List<Map<String, dynamic>> actions = [
      {
        'title': 'Connect Platform',
        'description': 'Add a new social media platform to your account',
        'icon': Icons.add_circle,
        'color': const Color(0xFF4E6BFF),
        'onTap': _showAddPlatformDialog,
      },
      {
        'title': 'Profile Analysis',
        'description': 'Get a detailed analysis of your social media profiles',
        'icon': Icons.analytics,
        'color': const Color(0xFF6B4EFF),
        'onTap': _showProfileAnalysisDialog,
      },
      {
        'title': 'Content Suggestions',
        'description': 'Get AI-generated content ideas for your platforms',
        'icon': Icons.lightbulb,
        'color': const Color(0xFFFF6B4E),
        'onTap': _showProfileSuggestionsDialog,
      },
      {
        'title': 'Analytics Dashboard',
        'description': 'View detailed metrics across all your platforms',
        'icon': Icons.bar_chart,
        'color': const Color(0xFF4EFF6B),
        'onTap': _showAnalyticsDialog,
      },
    ];
    
    return Column(
      children: actions.map((action) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: InkWell(
            onTap: action['onTap'] as Function(),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(
                        (action['color'] as Color).red,
                        (action['color'] as Color).green,
                        (action['color'] as Color).blue,
                        0.1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      action['icon'] as IconData,
                      color: action['color'] as Color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          action['title'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          action['description'] as String,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'dashboard':
        // Just refresh the page
        _initializeServices();
        break;
      case 'profile_analysis':
        _showProfileAnalysisDialog();
        break;
      case 'profile_suggestions':
        _showProfileSuggestionsDialog();
        break;
      case 'analytics':
        _showAnalyticsDialog();
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
      _showErrorSnackBar('Failed to logout: $e');
    }
  }
} 