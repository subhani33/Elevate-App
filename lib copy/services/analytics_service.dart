import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProfileAnalysis {
  final String platform;
  final List<String> strengths;
  final List<String> weaknesses;
  final Map<String, dynamic> metrics;
  final List<String> suggestions;

  ProfileAnalysis({
    required this.platform,
    required this.strengths,
    required this.weaknesses,
    required this.metrics,
    required this.suggestions,
  });

  factory ProfileAnalysis.fromJson(Map<String, dynamic> json) {
    return ProfileAnalysis(
      platform: json['platform'] ?? '',
      strengths: List<String>.from(json['strengths'] ?? []),
      weaknesses: List<String>.from(json['weaknesses'] ?? []),
      metrics: json['metrics'] ?? {},
      suggestions: List<String>.from(json['suggestions'] ?? []),
    );
  }
}

class AnalyticsData {
  final String platform;
  final Map<String, List<dynamic>> timeSeriesData;
  final Map<String, dynamic> currentMetrics;
  final Map<String, double> growthRates;

  AnalyticsData({
    required this.platform,
    required this.timeSeriesData,
    required this.currentMetrics,
    required this.growthRates,
  });

  factory AnalyticsData.fromJson(Map<String, dynamic> json) {
    return AnalyticsData(
      platform: json['platform'] ?? '',
      timeSeriesData: Map<String, List<dynamic>>.from(json['timeSeriesData'] ?? {}),
      currentMetrics: json['currentMetrics'] ?? {},
      growthRates: Map<String, double>.from(json['growthRates'] ?? {}),
    );
  }
}

class AnalyticsService extends ChangeNotifier {
  final String _baseUrl = 'https://elevate-api.example.com/analytics';
  final bool _useMockData = true; // Set to false in production
  
  final Map<String, ProfileAnalysis> _profileAnalyses = {};
  final Map<String, AnalyticsData> _analyticsData = {};
  bool _isLoading = false;
  String? _errorMessage;
  
  Map<String, ProfileAnalysis> get profileAnalyses => _profileAnalyses;
  Map<String, AnalyticsData> get analyticsData => _analyticsData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Get profile analysis for a specific platform
  Future<ProfileAnalysis?> getProfileAnalysis(String platform) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      if (_useMockData) {
        await Future.delayed(const Duration(milliseconds: 800)); // Simulate network delay
        final analysis = _getMockProfileAnalysis(platform);
        _profileAnalyses[platform] = analysis;
        _isLoading = false;
        notifyListeners();
        return analysis;
      } else {
        final response = await http.get(
          Uri.parse('$_baseUrl/profile/$platform'),
          headers: {'Content-Type': 'application/json'},
        );
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final analysis = ProfileAnalysis.fromJson(data);
          _profileAnalyses[platform] = analysis;
          _isLoading = false;
          notifyListeners();
          return analysis;
        } else {
          throw Exception('Failed to load profile analysis: ${response.statusCode}');
        }
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load profile analysis: $e';
      
      // If real API fails, fall back to mock data
      if (!_useMockData) {
        final analysis = _getMockProfileAnalysis(platform);
        _profileAnalyses[platform] = analysis;
        notifyListeners();
        return analysis;
      }
      
      notifyListeners();
      return null;
    }
  }
  
  // Get analytics data for a specific platform
  Future<AnalyticsData?> getAnalyticsData(String platform) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      if (_useMockData) {
        await Future.delayed(const Duration(milliseconds: 800)); // Simulate network delay
        final data = _getMockAnalyticsData(platform);
        _analyticsData[platform] = data;
        _isLoading = false;
        notifyListeners();
        return data;
      } else {
        final response = await http.get(
          Uri.parse('$_baseUrl/metrics/$platform'),
          headers: {'Content-Type': 'application/json'},
        );
        
        if (response.statusCode == 200) {
          final jsonData = jsonDecode(response.body);
          final data = AnalyticsData.fromJson(jsonData);
          _analyticsData[platform] = data;
          _isLoading = false;
          notifyListeners();
          return data;
        } else {
          throw Exception('Failed to load analytics data: ${response.statusCode}');
        }
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load analytics data: $e';
      
      // If real API fails, fall back to mock data
      if (!_useMockData) {
        final data = _getMockAnalyticsData(platform);
        _analyticsData[platform] = data;
        notifyListeners();
        return data;
      }
      
      notifyListeners();
      return null;
    }
  }
  
  // Get profile analyses for all platforms
  Future<void> getAllProfileAnalyses(List<String> platforms) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      for (final platform in platforms) {
        await getProfileAnalysis(platform);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Get analytics data for all platforms
  Future<void> getAllAnalyticsData(List<String> platforms) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      for (final platform in platforms) {
        await getAnalyticsData(platform);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Mock profile analysis for development and testing
  ProfileAnalysis _getMockProfileAnalysis(String platform) {
    switch (platform.toLowerCase()) {
      case 'linkedin':
        return ProfileAnalysis(
          platform: 'LinkedIn',
          strengths: [
            'Professional headline is clear and concise',
            'Profile photo is professional and high quality',
            'Skills section is well organized and relevant',
            'Experience section demonstrates progression'
          ],
          weaknesses: [
            'About section is too long (currently 8 paragraphs)',
            'Missing recommendations from colleagues',
            'Low posting frequency (less than 1 post per month)',
            'Limited engagement with industry content'
          ],
          metrics: {
            'profile_completion': 85,
            'network_quality': 72,
            'engagement_score': 43,
            'content_relevance': 68
          },
          suggestions: [
            'Reduce your About section to 2-3 paragraphs focusing on value proposition',
            'Request recommendations from 3-5 recent colleagues',
            'Schedule at least one post per week about industry trends',
            'Engage with 5-10 posts in your feed daily'
          ],
        );
      case 'twitter':
        return ProfileAnalysis(
          platform: 'Twitter',
          strengths: [
            'Consistent posting schedule (3-5 tweets per week)',
            'Good balance of original content and retweets',
            'Profile bio clearly communicates expertise',
            'Strong engagement with industry hashtags'
          ],
          weaknesses: [
            'Low media content (only 5% of tweets include images)',
            'Tweets often exceed optimal length of 100 characters',
            'Limited use of Twitter Lists for network building',
            'Profile banner image doesn\'t align with personal brand'
          ],
          metrics: {
            'profile_completion': 78,
            'audience_alignment': 65,
            'engagement_score': 59,
            'content_relevance': 72
          },
          suggestions: [
            'Include images or videos in at least 30% of your tweets',
            'Keep most tweets under 100 characters for better engagement',
            'Create 3-5 public Twitter Lists around key industry topics',
            'Update your banner image to showcase your professional focus'
          ],
        );
      case 'instagram':
        return ProfileAnalysis(
          platform: 'Instagram',
          strengths: [
            'High-quality visual content that\'s consistent in style',
            'Effective use of Instagram Stories for daily updates',
            'Good engagement with followers in comments',
            'Strategic use of location tags to increase visibility'
          ],
          weaknesses: [
            'Inconsistent posting schedule (gaps of 10+ days)',
            'Bio lacks clear call-to-action',
            'Limited use of Instagram Reels',
            'Hashtag strategy needs refinement (too many generic tags)'
          ],
          metrics: {
            'profile_completion': 82,
            'visual_consistency': 88,
            'engagement_score': 67,
            'hashtag_effectiveness': 49
          },
          suggestions: [
            'Establish a consistent posting schedule (2-3 posts per week)',
            'Add a clear call-to-action in your bio',
            'Create at least one Reel per week to boost visibility',
            'Develop a custom hashtag strategy with 5-10 specific tags'
          ],
        );
      case 'facebook':
        return ProfileAnalysis(
          platform: 'Facebook',
          strengths: [
            'Strong personal story in the About section',
            'Regular updates on professional achievements',
            'Good mix of personal and professional content',
            'Consistent branding across profile and cover photos'
          ],
          weaknesses: [
            'Limited use of Facebook Groups for networking',
            'Posts often lack calls-to-action',
            'Infrequent use of Facebook Live',
            'Privacy settings may be limiting professional visibility'
          ],
          metrics: {
            'profile_completion': 75,
            'content_diversity': 68,
            'engagement_score': 52,
            'network_quality': 64
          },
          suggestions: [
            'Join and actively participate in 3-5 industry-related Facebook Groups',
            'Add clear calls-to-action to at least 50% of your posts',
            'Schedule a monthly Facebook Live session on a professional topic',
            'Review privacy settings to ensure professional content is publicly visible'
          ],
        );
      default:
        return ProfileAnalysis(
          platform: platform,
          strengths: [
            'Clear profile information',
            'Regular posting schedule',
          ],
          weaknesses: [
            'Limited engagement with audience',
            'Content strategy needs improvement',
          ],
          metrics: {
            'profile_completion': 60,
            'engagement_score': 40,
          },
          suggestions: [
            'Increase posting frequency',
            'Engage more with followers',
          ],
        );
    }
  }
  
  // Mock analytics data for development and testing
  AnalyticsData _getMockAnalyticsData(String platform) {
    final random = Random();
    final now = DateTime.now();
    
    // Generate 30 days of mock data
    List<Map<String, dynamic>> generateTimeSeriesData(
      String metric,
      double baseValue,
      double volatility,
      double trend
    ) {
      final data = <Map<String, dynamic>>[];
      double value = baseValue;
      
      for (int i = 30; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final change = (random.nextDouble() * 2 - 1) * volatility + trend;
        value = max(0, value + change);
        
        data.add({
          'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
          'value': value.round(),
        });
      }
      
      return data;
    }
    
    switch (platform.toLowerCase()) {
      case 'linkedin':
        return AnalyticsData(
          platform: 'LinkedIn',
          timeSeriesData: {
            'profile_views': generateTimeSeriesData(
              'profile_views',
              50.0,
              10.0,
              0.5
            ),
            'post_impressions': generateTimeSeriesData(
              'post_impressions',
              200.0,
              50.0,
              2.0
            ),
            'connections': generateTimeSeriesData(
              'connections',
              500.0,
              5.0,
              3.0
            ),
            'engagement_rate': generateTimeSeriesData(
              'engagement_rate',
              2.5,
              0.3,
              0.05
            ),
          },
          currentMetrics: {
            'profile_views': 78,
            'post_impressions': 342,
            'connections': 618,
            'engagement_rate': 3.2,
            'comments_received': 28,
            'shares_received': 15,
          },
          growthRates: {
            'profile_views': 12.5,
            'post_impressions': 24.8,
            'connections': 8.3,
            'engagement_rate': 15.2,
          },
        );
      case 'twitter':
        return AnalyticsData(
          platform: 'Twitter',
          timeSeriesData: {
            'followers': generateTimeSeriesData(
              'followers',
              1200.0,
              20.0,
              10.0
            ),
            'tweet_impressions': generateTimeSeriesData(
              'tweet_impressions',
              500.0,
              100.0,
              5.0
            ),
            'mentions': generateTimeSeriesData(
              'mentions',
              30.0,
              10.0,
              0.2
            ),
            'engagement_rate': generateTimeSeriesData(
              'engagement_rate',
              1.8,
              0.4,
              0.03
            ),
          },
          currentMetrics: {
            'followers': 1485,
            'tweet_impressions': 782,
            'mentions': 42,
            'engagement_rate': 2.3,
            'retweets': 68,
            'likes': 215,
          },
          growthRates: {
            'followers': 6.7,
            'tweet_impressions': 18.9,
            'mentions': 28.6,
            'engagement_rate': 9.5,
          },
        );
      case 'instagram':
        return AnalyticsData(
          platform: 'Instagram',
          timeSeriesData: {
            'followers': generateTimeSeriesData(
              'followers',
              2500.0,
              30.0,
              15.0
            ),
            'reach': generateTimeSeriesData(
              'reach',
              800.0,
              150.0,
              10.0
            ),
            'saves': generateTimeSeriesData(
              'saves',
              40.0,
              8.0,
              0.5
            ),
            'engagement_rate': generateTimeSeriesData(
              'engagement_rate',
              3.2,
              0.5,
              0.04
            ),
          },
          currentMetrics: {
            'followers': 2872,
            'reach': 1245,
            'saves': 67,
            'engagement_rate': 4.1,
            'comments': 138,
            'likes': 428,
          },
          growthRates: {
            'followers': 11.2,
            'reach': 22.4,
            'saves': 35.8,
            'engagement_rate': 14.3,
          },
        );
      case 'facebook':
        return AnalyticsData(
          platform: 'Facebook',
          timeSeriesData: {
            'page_likes': generateTimeSeriesData(
              'page_likes',
              850.0,
              15.0,
              5.0
            ),
            'post_reach': generateTimeSeriesData(
              'post_reach',
              450.0,
              80.0,
              4.0
            ),
            'shares': generateTimeSeriesData(
              'shares',
              25.0,
              5.0,
              0.3
            ),
            'engagement_rate': generateTimeSeriesData(
              'engagement_rate',
              1.5,
              0.3,
              0.02
            ),
          },
          currentMetrics: {
            'page_likes': 978,
            'post_reach': 625,
            'shares': 34,
            'engagement_rate': 1.9,
            'comments': 85,
            'reactions': 312,
          },
          growthRates: {
            'page_likes': 5.2,
            'post_reach': 15.8,
            'shares': 21.4,
            'engagement_rate': 8.6,
          },
        );
      default:
        return AnalyticsData(
          platform: platform,
          timeSeriesData: {
            'followers': generateTimeSeriesData(
              'followers',
              100.0,
              10.0,
              1.0
            ),
            'engagement': generateTimeSeriesData(
              'engagement',
              50.0,
              10.0,
              0.5
            ),
          },
          currentMetrics: {
            'followers': 125,
            'engagement': 65,
          },
          growthRates: {
            'followers': 5.0,
            'engagement': 8.0,
          },
        );
    }
  }
} 