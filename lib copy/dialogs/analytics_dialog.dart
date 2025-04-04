import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/analytics_service.dart';
import '../services/social_media_service.dart';

class AnalyticsDialog extends StatefulWidget {
  const AnalyticsDialog({super.key});

  @override
  State<AnalyticsDialog> createState() => _AnalyticsDialogState();
}

class _AnalyticsDialogState extends State<AnalyticsDialog> {
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
        _loadAnalyticsData();
      }
    });
  }

  Future<void> _loadAnalyticsData() async {
    if (_selectedPlatform == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
      await analyticsService.getAnalyticsData(_selectedPlatform!);
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
                  'Analytics',
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
                        _loadAnalyticsData();
                      },
                    ),
                    const SizedBox(height: 24),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      _buildAnalyticsContent(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsContent() {
    return Consumer<AnalyticsService>(
      builder: (context, analyticsService, child) {
        if (_selectedPlatform == null) {
          return const Center(
            child: Text('Please select a platform'),
          );
        }
        
        final analytics = analyticsService.analyticsData[_selectedPlatform];
        
        if (analytics == null) {
          return Center(
            child: Column(
              children: [
                const Text('No analytics data available'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _loadAnalyticsData,
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
                _buildCurrentMetricsSection(analytics.currentMetrics),
                const SizedBox(height: 24),
                _buildGrowthRatesSection(analytics.growthRates),
                const SizedBox(height: 24),
                // In a real app, we would render charts here with the time series data
                _buildTimeSeriesNote(analytics.timeSeriesData),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentMetricsSection(Map<String, dynamic> metrics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.insights, color: Colors.purple[700]),
            const SizedBox(width: 8),
            Text(
              'Current Metrics',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.purple[700],
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
              width: 120,
              height: 120,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.purple.withOpacity(0.3),
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
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: Text(
                      entry.key.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGrowthRatesSection(Map<String, double> growthRates) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.trending_up, color: Colors.green[700]),
            const SizedBox(width: 8),
            Text(
              'Growth Rates (30 days)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.green[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: growthRates.entries.map((entry) {
            final isPositive = entry.value >= 0;
            final color = isPositive ? Colors.green : Colors.red;
            
            return Container(
              width: 120,
              height: 120,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withOpacity(0.3),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        color: color,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${entry.value.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: Text(
                      entry.key.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTimeSeriesNote(Map<String, List<dynamic>> timeSeriesData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.timeline, color: Colors.blue[700]),
            const SizedBox(width: 8),
            Text(
              'Historical Data',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.blue[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.blue.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Time Series Data Available:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We have historical data for the following metrics: ${timeSeriesData.keys.join(', ')}.',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Note: In a real application, we would render interactive charts here with the time series data.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 