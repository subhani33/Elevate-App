import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../services/social_media_service.dart';

class ManageProfilesDialog extends StatefulWidget {
  const ManageProfilesDialog({super.key});

  @override
  State<ManageProfilesDialog> createState() => _ManageProfilesDialogState();
}

class _ManageProfilesDialogState extends State<ManageProfilesDialog> {
  bool _isLoading = false;
  String? _errorMessage;
  SocialPlatform? _selectedPlatform;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _profileUrlController = TextEditingController();
  
  @override
  void dispose() {
    _usernameController.dispose();
    _profileUrlController.dispose();
    super.dispose();
  }
  
  void _selectPlatform(SocialPlatform platform) {
    setState(() {
      _selectedPlatform = platform;
      _usernameController.text = platform.username;
      _profileUrlController.text = platform.profileUrl ?? '';
    });
  }
  
  Map<String, Color> get _platformColors => {
    'LinkedIn': const Color(0xFF0077B5),
    'Twitter': const Color(0xFF1DA1F2),
    'Instagram': const Color(0xFFE1306C),
    'Facebook': const Color(0xFF1877F2),
  };
  
  Map<String, String> get _platformIcons => {
    'LinkedIn': 'assets/linkedin_logo.svg',
    'Twitter': 'assets/twitter_logo.svg',
    'Instagram': 'assets/instagram_logo.svg',
    'Facebook': 'assets/facebook_logo.svg',
  };
  
  Color _getPlatformColor(String platform) {
    return _platformColors[platform] ?? const Color(0xFF6B4EFF);
  }
  
  String _getPlatformIcon(String platform) {
    return _platformIcons[platform] ?? 'assets/plus_icon.svg';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Text('Manage Profiles'),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 500,
        child: Consumer<SocialMediaService>(
          builder: (context, socialMediaService, child) {
            final platforms = socialMediaService.platforms;
            
            if (platforms.isEmpty) {
              return const Center(
                child: Text('No platforms connected. Add a platform first.'),
              );
            }
            
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side - platform list
                SizedBox(
                  width: 150,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Platforms',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: platforms.length,
                          itemBuilder: (context, index) {
                            final platform = platforms[index];
                            final isSelected = _selectedPlatform?.id == platform.id;
                            
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              leading: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: _getPlatformColor(platform.name),
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(8),
                                child: SvgPicture.asset(
                                  _getPlatformIcon(platform.name),
                                  colorFilter: const ColorFilter.mode(
                                    Colors.white,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                              title: Text(
                                platform.name,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              subtitle: Text(
                                platform.username,
                                style: const TextStyle(fontSize: 12),
                              ),
                              selected: isSelected,
                              selectedTileColor: _getPlatformColor(platform.name).withOpacity(0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              onTap: () => _selectPlatform(platform),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Divider
                const VerticalDivider(),
                
                // Right side - edit form
                Expanded(
                  child: _selectedPlatform == null
                      ? const Center(
                          child: Text('Select a platform to edit'),
                        )
                      : _buildEditForm(),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
      contentPadding: const EdgeInsets.all(24),
    );
  }
  
  Widget _buildEditForm() {
    if (_selectedPlatform == null) return const SizedBox();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getPlatformColor(_selectedPlatform!.name),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(8),
              child: SvgPicture.asset(
                _getPlatformIcon(_selectedPlatform!.name),
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Edit ${_selectedPlatform!.name} Profile',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _usernameController,
          decoration: InputDecoration(
            labelText: 'Username',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _profileUrlController,
          decoration: InputDecoration(
            labelText: 'Profile URL',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: _confirmDeletePlatform,
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveProfileChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: _getPlatformColor(_selectedPlatform!.name),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _saveProfileChanges() async {
    if (_selectedPlatform == null) return;
    
    // Validate inputs
    if (_usernameController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Username cannot be empty';
      });
      return;
    }
    
    if (_profileUrlController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Profile URL cannot be empty';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final socialMediaService = Provider.of<SocialMediaService>(context, listen: false);
      
      final success = await socialMediaService.editPlatform(
        _selectedPlatform!.id,
        username: _usernameController.text,
        profileUrl: _profileUrlController.text,
      );
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        if (success) {
          // Re-select platform to refresh data
          final updatedPlatform = socialMediaService.platforms.firstWhere(
            (p) => p.id == _selectedPlatform!.id,
            orElse: () => _selectedPlatform!,
          );
          _selectPlatform(updatedPlatform);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() {
            _errorMessage = 'Failed to update profile';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error: $e';
        });
      }
    }
  }
  
  void _confirmDeletePlatform() {
    if (_selectedPlatform == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text(
          'Are you sure you want to delete your ${_selectedPlatform!.name} profile? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePlatform();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _deletePlatform() async {
    if (_selectedPlatform == null) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final socialMediaService = Provider.of<SocialMediaService>(context, listen: false);
      
      final success = await socialMediaService.disconnectPlatform(_selectedPlatform!.id);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _selectedPlatform = null;
        });
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() {
            _errorMessage = 'Failed to delete profile';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error: $e';
        });
      }
    }
  }
} 