import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/analytics_service.dart';
import '../services/social_media_service.dart';

class ProfileAnalysisDialog extends StatefulWidget {
  const ProfileAnalysisDialog({super.key});

  @override
  State<ProfileAnalysisDialog> createState() => _ProfileAnalysisDialogState();
}

class _ProfileAnalysisDialogState extends State<ProfileAnalysisDialog> {
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
        _loadProfileAnalysis();
      }
    });
  }

  Future<void> _loadProfileAnalysis() async {
    if (_selectedPlatform == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
      await analyticsService.getProfileAnalysis(_selectedPlatform!);
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
                  'Profile Analysis',
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
                        _loadProfileAnalysis();
                      },
                    ),
                    const SizedBox(height: 24),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      _buildAnalysisContent(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisContent() {
    return Consumer<AnalyticsService>(
      builder: (context, analyticsService, child) {
        if (_selectedPlatform == null) {
          return const Center(
            child: Text('Please select a platform'),
          );
        }
        
        final analysis = analyticsService.profileAnalyses[_selectedPlatform];
        
        if (analysis == null) {
          return Center(
            child: Column(
              children: [
                const Text('No analysis data available'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _loadProfileAnalysis,
                  child: const Text('Load Data'),
                ),
              ],
            ),
          );
        }
        
        return SizedBox(
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection(
                  title: 'Strengths',
                  items: analysis.strengths,
                  icon: Icons.thumb_up,
                  color: Colors.green,
                ),
                const SizedBox(height: 24),
                _buildSection(
                  title: 'Weaknesses',
                  items: analysis.weaknesses,
                  icon: Icons.thumb_down,
                  color: Colors.orange,
                ),
                const SizedBox(height: 24),
                _buildMetricsSection(analysis.metrics),
                const SizedBox(height: 24),
                _buildSection(
                  title: 'Suggestions',
                  items: analysis.suggestions,
                  icon: Icons.lightbulb,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection({
    required String title,
    required List<String> items,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(top: 8, right: 8, left: 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(
                  item,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildMetricsSection(Map<String, dynamic> metrics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.bar_chart, color: Colors.blue[700]),
            const SizedBox(width: 8),
            Text(
              'Metrics',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.blue[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: metrics.entries.map((entry) {
            return Container(
              width: 110,
              height: 110,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    entry.value.toString(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry.key.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
} 