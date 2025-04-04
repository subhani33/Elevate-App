import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/gpt_service.dart';
import '../services/social_media_service.dart';

class ProfileSuggestionsDialog extends StatefulWidget {
  const ProfileSuggestionsDialog({super.key});

  @override
  State<ProfileSuggestionsDialog> createState() => _ProfileSuggestionsDialogState();
}

class _ProfileSuggestionsDialogState extends State<ProfileSuggestionsDialog> {
  String? _selectedPlatform;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final socialMediaService = Provider.of<SocialMediaService>(context, listen: false);
      if (socialMediaService.platforms.isNotEmpty) {
        setState(() {
          _selectedPlatform = socialMediaService.platforms.first.name;
        });
        _loadSuggestions();
      }
    });
  }

  Future<void> _loadSuggestions() async {
    if (_selectedPlatform == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final gptService = Provider.of<GptService>(context, listen: false);
      await gptService.fetchSuggestions(platform: _selectedPlatform);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'AI Profile Suggestions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Consumer<SocialMediaService>(
              builder: (context, socialMediaService, child) {
                final platforms = socialMediaService.platforms;
                
                if (platforms.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No platforms connected. Please connect a social media platform first.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Platform:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedPlatform,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      items: platforms.map((platform) {
                        return DropdownMenuItem<String>(
                          value: platform.name,
                          child: Text(platform.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPlatform = value;
                        });
                        _loadSuggestions();
                      },
                    ),
                    const SizedBox(height: 24),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      _buildSuggestionsContent(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsContent() {
    return Consumer<GptService>(
      builder: (context, gptService, child) {
        if (gptService.suggestions.isEmpty) {
          return Center(
            child: Column(
              children: [
                const Text('No suggestions available'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _loadSuggestions,
                  child: const Text('Load Suggestions'),
                ),
              ],
            ),
          );
        }
        
        return SizedBox(
          height: 400,
          child: ListView.builder(
            itemCount: gptService.suggestions.length,
            itemBuilder: (context, index) {
              final suggestion = gptService.suggestions[index];
              
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              suggestion.model,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              suggestion.type.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        suggestion.text,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              // In a real app, this would save or copy the suggestion
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Suggestion copied to clipboard'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('Copy'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              // In a real app, this would apply the suggestion
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Suggestion applied to your profile'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Apply'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
} 