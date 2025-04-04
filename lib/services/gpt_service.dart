import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class GptSuggestion {
  final String text;
  final String model;
  final String type; // 'bio', 'content', 'engagement', etc.

  GptSuggestion({
    required this.text,
    required this.model,
    required this.type,
  });

  factory GptSuggestion.fromJson(Map<String, dynamic> json) {
    return GptSuggestion(
      text: json['text'] ?? '',
      model: json['model'] ?? 'GPT',
      type: json['type'] ?? 'general',
    );
  }
}

class GptService extends ChangeNotifier {
  final String _baseUrl = 'https://elevate-api.example.com/suggestions';
  final bool _useMockData = true; // Set to false in production
  
  List<GptSuggestion> _suggestions = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // Available models
  final List<String> _availableModels = ['GPT-3.5', 'GPT-4', 'Claude', 'Gemini'];
  String _selectedModel = 'GPT-3.5'; // Default model
  
  List<GptSuggestion> get suggestions => _suggestions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<String> get availableModels => _availableModels;
  String get selectedModel => _selectedModel;
  
  // Add rate limiting variables
  static const int _minRequestInterval = 2; // minimum seconds between requests
  DateTime? _lastRequestTime;
  final String _apiKey = const String.fromEnvironment('GPT_API_KEY');
  
  // Select a different model
  void selectModel(String model) {
    if (_availableModels.contains(model) && _selectedModel != model) {
      _selectedModel = model;
      notifyListeners();
    }
  }
  
  // Get response from GPT for a specific query
  Future<String> getGptResponse(String query) async {
    if (_isLoading) {
      return 'A request is already in progress. Please wait.';
    }
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      if (_useMockData) {
        await Future.delayed(const Duration(milliseconds: 1200)); // Simulate network delay
        
        final response = _getMockGptResponse(query);
        _isLoading = false;
        notifyListeners();
        return response;
      } else {
        // Add rate limiting protection
        final now = DateTime.now();
        if (_lastRequestTime != null && 
            now.difference(_lastRequestTime!).inSeconds < _minRequestInterval) {
          throw Exception('Please wait before making another request');
        }
        _lastRequestTime = now;
        
        final response = await http.post(
          Uri.parse('$_baseUrl/chat'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
          body: jsonEncode({
            'query': query,
            'model': _selectedModel,
          }),
        ).timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw Exception('Request timed out'),
        );
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final responseText = data['response'] as String;
          _isLoading = false;
          notifyListeners();
          return responseText;
        } else if (response.statusCode == 429) {
          throw Exception('Rate limit exceeded. Please try again later.');
        } else {
          throw Exception('Failed to get response: ${response.statusCode}');
        }
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to get response: $e';
      notifyListeners();
      
      // If real API fails, fall back to mock response
      if (!_useMockData) {
        return _getMockGptResponse(query);
      }
      return 'Error: $_errorMessage';
    }
  }
  
  // Generate a mock GPT response based on query
  String _getMockGptResponse(String query) {
    final responses = [
      'Based on my analysis of your social media profiles, $query could benefit from more consistent posting schedules. Try posting 2-3 times per week at similar times to build a regular audience.',
      'Looking at your engagement metrics, I notice that $query gets more interaction when you include visuals. Consider adding images or short videos to your posts.',
      'For $query, I recommend focusing on building your personal brand through storytelling. Share your experiences and insights to connect more authentically with your audience.',
      'When it comes to $query, the data suggests that shorter, more focused content performs better. Try limiting your posts to 2-3 key points with actionable advice.',
      'Analyzing trends related to $query, I see that posts with questions or calls to action get 40% more comments. Try ending your posts with a thought-provoking question.',
    ];
    
    final random = Random();
    final responseIndex = random.nextInt(responses.length);
    
    return '$_selectedModel says: ${responses[responseIndex]}';
  }
  
  // Fetch suggestions from API or use mock data
  Future<void> fetchSuggestions({String? platform, String? profileType}) async {
    if (_isLoading) {
      _errorMessage = 'A request is already in progress';
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      if (_useMockData) {
        await Future.delayed(const Duration(milliseconds: 800)); // Simulate network delay
        _suggestions = _getMockSuggestions(platform, profileType);
      } else {
        // Add rate limiting protection
        final now = DateTime.now();
        if (_lastRequestTime != null && 
            now.difference(_lastRequestTime!).inSeconds < _minRequestInterval) {
          throw Exception('Please wait before making another request');
        }
        _lastRequestTime = now;
        
        final response = await http.get(
          Uri.parse('$_baseUrl?platform=$platform&profileType=$profileType'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception('Request timed out'),
        );
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          _suggestions = (data['suggestions'] as List)
              .map((item) => GptSuggestion.fromJson(item))
              .toList();
        } else if (response.statusCode == 429) {
          throw Exception('Rate limit exceeded. Please try again later.');
        } else {
          throw Exception('Failed to load suggestions: ${response.statusCode}');
        }
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load suggestions: $e';
      // If real API fails, fall back to mock data
      if (!_useMockData) {
        _suggestions = _getMockSuggestions(platform, profileType);
      }
      notifyListeners();
    }
  }
  
  // Mock suggestions for development and testing
  List<GptSuggestion> _getMockSuggestions(String? platform, String? profileType) {
    final List<GptSuggestion> mockSuggestions = [
      GptSuggestion(
        text: "Try updating your bio to highlight your key achievements in just 2-3 sentences.",
        model: "GPT-3.5",
        type: "bio",
      ),
      GptSuggestion(
        text: "Your profile photo could benefit from better lighting. Consider a professional headshot.",
        model: "GPT-4",
        type: "visual",
      ),
      GptSuggestion(
        text: "Posting content between 5-7 PM on Tuesdays has shown 30% higher engagement for your audience.",
        model: "GPT-4",
        type: "timing",
      ),
      GptSuggestion(
        text: "Try using more storytelling in your posts - your audience engages more with narrative content.",
        model: "Claude",
        type: "content",
      ),
      GptSuggestion(
        text: "Add 2-3 relevant industry hashtags to your posts to increase discoverability.",
        model: "GPT-3.5",
        type: "hashtags",
      ),
      GptSuggestion(
        text: "Your LinkedIn headline could be more impactful. Focus on the value you provide, not just your title.",
        model: "GPT-4",
        type: "headline",
      ),
      GptSuggestion(
        text: "Consider creating a weekly series on a topic your followers care about to build consistent engagement.",
        model: "Claude",
        type: "strategy",
      ),
      GptSuggestion(
        text: "Your text-heavy posts get fewer likes. Try adding a visual element to every post.",
        model: "GPT-3.5",
        type: "visual",
      ),
    ];
    
    // Filter by platform if provided
    List<GptSuggestion> filtered = mockSuggestions;
    if (platform != null && platform.isNotEmpty && platform != 'all') {
      // In a real implementation, we would filter more intelligently
      filtered = filtered.take(Random().nextInt(3) + 2).toList();
    }
    
    // Shuffle to add variety
    filtered.shuffle();
    
    return filtered;
  }
} 