import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../services/social_media_service.dart';
import '../services/gpt_service.dart';
import '../dialogs/add_platform_dialog.dart';

class ThirdPage extends StatefulWidget {
  const ThirdPage({super.key});

  @override
  State<ThirdPage> createState() => _ThirdPageState();
}

class _ThirdPageState extends State<ThirdPage> {
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
      await socialMediaService.loadConnectedPlatforms();
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to load platforms: $e');
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
        content: Text(response),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Elevate - AI & Social'),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Social Platforms Section
            _buildSocialPlatformsSection(),
            const SizedBox(height: 32),
            
            // GPT Box Section
            _buildGptBoxSection(),
            const SizedBox(height: 32),
            
            // Model Selection Section
            _buildModelSelectionSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialPlatformsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Social Platforms',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Side - Platform List
            Expanded(
              flex: 3,
              child: _buildPlatformsList(),
            ),
            const SizedBox(width: 16),
            // Right Side - Add Platform Button
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _showAddPlatformDialog,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/plus_icon.svg',
                          width: 32,
                          height: 32,
                          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Social Platform APIs',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Option to add more',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlatformsList() {
    return Consumer<SocialMediaService>(
      builder: (context, socialMediaService, child) {
        final platforms = socialMediaService.platforms;
        
        if (socialMediaService.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (platforms.isEmpty) {
          return const Center(
            child: Text(
              'No platforms connected yet.\nTap the + button to add one.',
              textAlign: TextAlign.center,
            ),
          );
        }
        
        return Column(
          children: platforms.map((platform) => _buildPlatformItem(platform)).toList(),
        );
      },
    );
  }

  Widget _buildPlatformItem(SocialPlatform platform) {
    String assetName;
    Color platformColor;
    
    switch (platform.name.toLowerCase()) {
      case 'linkedin':
        assetName = 'assets/linkedin_logo.svg';
        platformColor = const Color(0xFF0077B5);
        break;
      case 'twitter':
        assetName = 'assets/twitter_logo.svg';
        platformColor = const Color(0xFF1DA1F2);
        break;
      case 'instagram':
        assetName = 'assets/instagram_logo.svg';
        platformColor = const Color(0xFFE1306C);
        break;
      case 'facebook':
        assetName = 'assets/facebook_logo.svg';
        platformColor = const Color(0xFF1877F2);
        break;
      default:
        assetName = 'assets/elevate_logo.svg';
        platformColor = const Color(0xFF6B4EFF);
    }
    
    return Container(
      width: double.infinity,
      height: 50,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: platformColor, width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: platformColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                bottomLeft: Radius.circular(6),
              ),
            ),
            child: SvgPicture.asset(
              assetName,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              platform.username,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showPlatformOptions(platform),
            color: platformColor,
          ),
        ],
      ),
    );
  }

  void _showPlatformOptions(SocialPlatform platform) {
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
                _confirmDisconnect(platform);
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

  void _confirmDisconnect(SocialPlatform platform) {
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

  Widget _buildGptBoxSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'GPT Box',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _gptQueryController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Ask something...',
            filled: true,
            fillColor: Colors.grey[50],
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
              borderSide: const BorderSide(color: Colors.blueAccent),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitGptQuery,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Submit'),
          ),
        ),
      ],
    );
  }

  Widget _buildModelSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Model Selection',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Consumer<GptService>(
          builder: (context, gptService, child) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: gptService.selectedModel,
                  icon: const Icon(Icons.arrow_drop_down),
                  iconSize: 24,
                  elevation: 16,
                  style: const TextStyle(color: Colors.black87, fontSize: 16),
                  isExpanded: true,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      gptService.selectModel(newValue);
                    }
                  },
                  items: gptService.availableModels
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        const Text(
          'Select the AI model you want to use for generating responses.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
} 