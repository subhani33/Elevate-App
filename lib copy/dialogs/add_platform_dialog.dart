import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../services/social_media_service.dart';

class AddPlatformDialog extends StatefulWidget {
  const AddPlatformDialog({super.key});

  @override
  State<AddPlatformDialog> createState() => _AddPlatformDialogState();
}

class _AddPlatformDialogState extends State<AddPlatformDialog> {
  String _selectedPlatform = 'LinkedIn';
  bool _isConnecting = false;
  String? _errorMessage;
  bool _useCustomProfile = false;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _profileUrlController = TextEditingController();

  final Map<String, Map<String, dynamic>> _platforms = {
    'LinkedIn': {
      'icon': 'assets/linkedin_logo.svg',
      'color': const Color(0xFF0077B5),
    },
    'Twitter': {
      'icon': 'assets/twitter_logo.svg',
      'color': const Color(0xFF1DA1F2),
    },
    'Instagram': {
      'icon': 'assets/instagram_logo.svg',
      'color': const Color(0xFFE1306C),
    },
    'Facebook': {
      'icon': 'assets/facebook_logo.svg',
      'color': const Color(0xFF1877F2),
    },
  };

  @override
  void dispose() {
    _usernameController.dispose();
    _profileUrlController.dispose();
    super.dispose();
  }

  void _updateProfileUrl() {
    if (!_useCustomProfile || _usernameController.text.isEmpty) return;
    
    String platformUrl = '';
    switch (_selectedPlatform.toLowerCase()) {
      case 'linkedin':
        platformUrl = 'https://linkedin.com/in/${_usernameController.text}';
        break;
      case 'twitter':
        platformUrl = 'https://twitter.com/${_usernameController.text}';
        break;
      case 'instagram':
        platformUrl = 'https://instagram.com/${_usernameController.text}';
        break;
      case 'facebook':
        platformUrl = 'https://facebook.com/${_usernameController.text}';
        break;
      default:
        platformUrl = 'https://${_selectedPlatform.toLowerCase()}.com/${_usernameController.text}';
    }
    
    _profileUrlController.text = platformUrl;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Connect New Platform'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select a platform to connect with your Elevate account. You can use OAuth or enter your profile details manually.',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: _platforms.entries.map((entry) {
                  final platformName = entry.key;
                  final platformData = entry.value;
                  final isSelected = _selectedPlatform == platformName;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPlatform = platformName;
                        _updateProfileUrl();
                      });
                    },
                    child: Container(
                      width: 80,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected 
                          ? Color.fromRGBO(
                              (platformData['color'] as Color).red,
                              (platformData['color'] as Color).green,
                              (platformData['color'] as Color).blue,
                              0.1)
                          : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected 
                            ? platformData['color']
                            : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: platformData['color'],
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(8),
                            child: SvgPicture.asset(
                              platformData['icon'],
                              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            platformName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? platformData['color'] : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                title: const Text('Enter Profile Manually'),
                subtitle: const Text('Provide your own username and profile URL'),
                value: _useCustomProfile,
                activeColor: _platforms[_selectedPlatform]!['color'],
                onChanged: (value) {
                  setState(() {
                    _useCustomProfile = value;
                    if (value && _usernameController.text.isNotEmpty) {
                      _updateProfileUrl();
                    }
                  });
                },
              ),
              if (_useCustomProfile) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    hintText: 'Enter your $_selectedPlatform username',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (_) => _updateProfileUrl(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _profileUrlController,
                  decoration: InputDecoration(
                    labelText: 'Profile URL',
                    hintText: 'https://${_selectedPlatform.toLowerCase()}.com/username',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 16),
              if (_isConnecting)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _connectPlatform,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _platforms[_selectedPlatform]!['color'],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Connect'),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isConnecting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Future<void> _connectPlatform() async {
    // Validate inputs if using custom profile
    if (_useCustomProfile) {
      if (_usernameController.text.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter a username';
        });
        return;
      }
      
      if (_profileUrlController.text.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter a profile URL';
        });
        return;
      }
    }
    
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });
    
    try {
      final socialMediaService = Provider.of<SocialMediaService>(
        context, 
        listen: false
      );
      
      bool success;
      if (_useCustomProfile) {
        success = await socialMediaService.addCustomProfile(
          _selectedPlatform,
          _usernameController.text,
          _profileUrlController.text,
        );
      } else {
        success = await socialMediaService.connectPlatform(_selectedPlatform);
      }
      
      if (success && mounted) {
        Navigator.pop(context);
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Failed to connect to $_selectedPlatform. Please try again.';
          _isConnecting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred: $e';
          _isConnecting = false;
        });
      }
    }
  }
} 