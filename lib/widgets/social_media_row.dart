import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../services/social_media_service.dart';
import '../dialogs/add_platform_dialog.dart';

class SocialMediaRow extends StatelessWidget {
  const SocialMediaRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SocialMediaService>(
      builder: (context, socialMediaService, child) {
        final platforms = socialMediaService.platforms;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Connected Platforms',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...platforms.map((platform) => _buildPlatformIcon(context, platform)),
                    _buildAddButton(context),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlatformIcon(BuildContext context, SocialPlatform platform) {
    String assetName;
    Color backgroundColor;
    
    switch (platform.name.toLowerCase()) {
      case 'linkedin':
        assetName = 'assets/linkedin_logo.svg';
        backgroundColor = const Color(0xFF0077B5);
        break;
      case 'twitter':
        assetName = 'assets/twitter_logo.svg';
        backgroundColor = const Color(0xFF1DA1F2);
        break;
      case 'instagram':
        assetName = 'assets/instagram_logo.svg';
        backgroundColor = const Color(0xFFE1306C);
        break;
      case 'facebook':
        assetName = 'assets/facebook_logo.svg';
        backgroundColor = const Color(0xFF1877F2);
        break;
      default:
        assetName = 'assets/elevate_logo.svg';
        backgroundColor = const Color(0xFF6B4EFF);
    }
    
    return GestureDetector(
      onTap: () => _showPlatformDetails(context, platform),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(
                      backgroundColor.red,
                      backgroundColor.green,
                      backgroundColor.blue,
                      0.3
                    ),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: SvgPicture.asset(
                assetName,
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              platform.username,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAddPlatformDialog(context),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/plus_icon.svg',
                  width: 24,
                  height: 24,
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add New',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPlatformDetails(BuildContext context, SocialPlatform platform) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(platform.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Username: ${platform.username}'),
            const SizedBox(height: 8),
            if (platform.profileUrl != null)
              Text('Profile URL: ${platform.profileUrl}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _confirmDisconnect(context, platform);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Disconnect Platform'),
            ),
          ],
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

  void _confirmDisconnect(BuildContext context, SocialPlatform platform) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Disconnect'),
        content: Text('Are you sure you want to disconnect ${platform.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final socialMediaService = Provider.of<SocialMediaService>(
                context, 
                listen: false
              );
              socialMediaService.disconnectPlatform(platform.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }

  void _showAddPlatformDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddPlatformDialog(),
    );
  }
} 