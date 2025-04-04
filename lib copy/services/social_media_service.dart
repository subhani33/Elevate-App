import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:encrypt/encrypt.dart' as encrypt;

class SocialPlatform {
  final String id;
  final String name;
  final String username;
  final bool isConnected;
  final String? accessToken;
  final String? profileUrl;
  final Map<String, dynamic>? metrics;

  SocialPlatform({
    required this.id,
    required this.name,
    required this.username,
    this.isConnected = false,
    this.accessToken,
    this.profileUrl,
    this.metrics,
  });

  factory SocialPlatform.fromJson(Map<String, dynamic> json) {
    return SocialPlatform(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      isConnected: json['isConnected'] ?? false,
      accessToken: json['accessToken'],
      profileUrl: json['profileUrl'],
      metrics: json['metrics'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'isConnected': isConnected,
      'accessToken': accessToken,
      'profileUrl': profileUrl,
      'metrics': metrics,
    };
  }
}

class SocialMediaService extends ChangeNotifier {
  final String _baseUrl = 'https://elevate-api.example.com/social';
  final bool _useMockData = true; // Set to false in production
  
  List<SocialPlatform> _platforms = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // Encryption key (in production, this should be securely stored)
  final _encryptionKey = encrypt.Key.fromLength(32);
  final _iv = encrypt.IV.fromLength(16);
  
  List<SocialPlatform> get platforms => _platforms;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  SocialMediaService() {
    // Initialize with mock data
    if (_useMockData) {
      _platforms = _getMockPlatforms();
    }
  }
  
  // Load connected platforms from API or mock data
  Future<void> loadConnectedPlatforms() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      if (_useMockData) {
        await Future.delayed(const Duration(milliseconds: 800)); // Simulate network delay
        _platforms = _getMockPlatforms();
      } else {
        final response = await http.get(
          Uri.parse('$_baseUrl/platforms'),
          headers: {'Content-Type': 'application/json'},
        );
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          _platforms = (data['platforms'] as List)
              .map((item) => SocialPlatform.fromJson(item))
              .toList();
        } else {
          throw Exception('Failed to load platforms: ${response.statusCode}');
        }
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load platforms: $e';
      
      // If real API fails, fall back to mock data
      if (!_useMockData) {
        _platforms = _getMockPlatforms();
      }
      
      notifyListeners();
    }
  }
  
  // Connect a new platform via OAuth
  Future<bool> connectPlatform(String platformName, {String? customUsername, String? customProfileUrl}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      if (_useMockData) {
        await Future.delayed(const Duration(seconds: 1)); // Simulate auth process
        
        String? mockToken;
        try {
          mockToken = _encryptToken('mock_token_$platformName');
        } catch (e) {
          _errorMessage = 'Failed to secure platform token: $e';
          _isLoading = false;
          notifyListeners();
          return false;
        }
        
        // Use custom username if provided, otherwise generate a default one
        final username = customUsername ?? 'user_${platformName.toLowerCase()}';
        final profileUrl = customProfileUrl ?? 'https://$platformName.com/$username';
        
        // Add a new mock platform
        final newPlatform = SocialPlatform(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: platformName,
          username: username,
          isConnected: true,
          accessToken: mockToken,
          profileUrl: profileUrl,
          metrics: _getMockMetrics(platformName),
        );
        
        _platforms.add(newPlatform);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // Real OAuth implementation
        try {
          // Implement platform-specific OAuth flow here or use custom credentials
          String? token;
          
          if (customUsername != null && customProfileUrl != null) {
            // For custom profile, we'll just use a fake token
            token = 'custom_profile_token';
          } else {
            token = await _performOAuthFlow(platformName);
          }
          
          if (token == null) {
            throw Exception('Failed to obtain OAuth token');
          }
          
          final encryptedToken = _encryptToken(token);
          
          // Store the connection in your backend
          final response = await http.post(
            Uri.parse('$_baseUrl/connect'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'platform': platformName,
              'token': encryptedToken,
              if (customUsername != null) 'username': customUsername,
              if (customProfileUrl != null) 'profileUrl': customProfileUrl,
            }),
          );
          
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final newPlatform = SocialPlatform.fromJson(data);
            _platforms.add(newPlatform);
            _isLoading = false;
            notifyListeners();
            return true;
          } else {
            throw Exception('Failed to connect platform: ${response.statusCode}');
          }
        } catch (e) {
          _errorMessage = 'OAuth process failed: $e';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to connect platform: $e';
      notifyListeners();
      return false;
    }
  }
  
  // Add a method to manually add a custom profile
  Future<bool> addCustomProfile(String platformName, String username, String profileUrl) async {
    return connectPlatform(
      platformName,
      customUsername: username,
      customProfileUrl: profileUrl,
    );
  }
  
  // Edit an existing platform
  Future<bool> editPlatform(String platformId, {String? username, String? profileUrl}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      if (_useMockData) {
        await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
        
        final platformIndex = _platforms.indexWhere((platform) => platform.id == platformId);
        if (platformIndex == -1) {
          throw Exception('Platform not found');
        }
        
        final oldPlatform = _platforms[platformIndex];
        final updatedPlatform = SocialPlatform(
          id: oldPlatform.id,
          name: oldPlatform.name,
          username: username ?? oldPlatform.username,
          isConnected: oldPlatform.isConnected,
          accessToken: oldPlatform.accessToken,
          profileUrl: profileUrl ?? oldPlatform.profileUrl,
          metrics: oldPlatform.metrics,
        );
        
        _platforms[platformIndex] = updatedPlatform;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // Real implementation would update in backend
        final response = await http.put(
          Uri.parse('$_baseUrl/platforms/$platformId'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            if (username != null) 'username': username,
            if (profileUrl != null) 'profileUrl': profileUrl,
          }),
        );
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final updatedPlatform = SocialPlatform.fromJson(data);
          
          final platformIndex = _platforms.indexWhere((platform) => platform.id == platformId);
          if (platformIndex != -1) {
            _platforms[platformIndex] = updatedPlatform;
          }
          
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          throw Exception('Failed to update platform: ${response.statusCode}');
        }
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to update platform: $e';
      notifyListeners();
      return false;
    }
  }
  
  // Helper method for OAuth flow (to be implemented per platform)
  Future<String?> _performOAuthFlow(String platformName) async {
    // This should be implemented for each platform
    switch (platformName.toLowerCase()) {
      case 'linkedin':
        // Implement LinkedIn OAuth
        break;
      case 'twitter':
        // Implement Twitter OAuth
        break;
      case 'facebook':
        // Implement Facebook OAuth
        break;
      default:
        throw Exception('Unsupported platform: $platformName');
    }
    return null;
  }
  
  // Disconnect a platform
  Future<bool> disconnectPlatform(String platformId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      if (_useMockData) {
        await Future.delayed(const Duration(milliseconds: 500));
        _platforms.removeWhere((platform) => platform.id == platformId);
      } else {
        final response = await http.delete(
          Uri.parse('$_baseUrl/disconnect/$platformId'),
          headers: {'Content-Type': 'application/json'},
        );
        
        if (response.statusCode == 200) {
          _platforms.removeWhere((platform) => platform.id == platformId);
        } else {
          throw Exception('Failed to disconnect platform: ${response.statusCode}');
        }
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to disconnect platform: $e';
      notifyListeners();
      return false;
    }
  }
  
  // Encrypt token for secure storage
  String _encryptToken(String token) {
    final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
    final encrypted = encrypter.encrypt(token, iv: _iv);
    return encrypted.base64;
  }
  
  // This method is kept for future use but marked with an underscore to indicate it's private
  // and may not currently be used in the application
  @pragma('vm:prefer-inline')
  // ignore: unused_element
  String _decryptToken(String encryptedToken) {
    final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
    final decrypted = encrypter.decrypt64(encryptedToken, iv: _iv);
    return decrypted;
  }
  
  // Mock platforms for development and testing
  List<SocialPlatform> _getMockPlatforms() {
    return [
      SocialPlatform(
        id: '1',
        name: 'LinkedIn',
        username: 'johndoe',
        isConnected: true,
        accessToken: _encryptToken('mock_token_linkedin'),
        profileUrl: 'https://linkedin.com/in/johndoe',
        metrics: _getMockMetrics('LinkedIn'),
      ),
      SocialPlatform(
        id: '2',
        name: 'Twitter',
        username: '@johndoe',
        isConnected: true,
        accessToken: _encryptToken('mock_token_twitter'),
        profileUrl: 'https://twitter.com/johndoe',
        metrics: _getMockMetrics('Twitter'),
      ),
      SocialPlatform(
        id: '3',
        name: 'Instagram',
        username: 'johndoe_photos',
        isConnected: true,
        accessToken: _encryptToken('mock_token_instagram'),
        profileUrl: 'https://instagram.com/johndoe_photos',
        metrics: _getMockMetrics('Instagram'),
      ),
    ];
  }
  
  // Fix string interpolation in the metrics method
  Map<String, dynamic> _getMockMetrics(String platform) {
    final random = Random();
    
    switch (platform) {
      case 'LinkedIn':
        return {
          'connections': 500 + random.nextInt(1000),
          'posts': 25 + random.nextInt(50),
          'engagement_rate': '${(3 + random.nextDouble() * 4).toStringAsFixed(1)}%',
          'profile_views': 100 + random.nextInt(400),
          'growth_rate': '${(1 + random.nextDouble() * 2).toStringAsFixed(1)}%',
        };
      case 'Twitter':
        return {
          'followers': 1000 + random.nextInt(5000),
          'tweets': 100 + random.nextInt(900),
          'retweets': 50 + random.nextInt(200),
          'likes': 300 + random.nextInt(1500),
          'engagement_rate': '${(2 + random.nextDouble() * 3).toStringAsFixed(1)}%',
        };
      case 'Instagram':
        return {
          'followers': 2000 + random.nextInt(8000),
          'posts': 40 + random.nextInt(100),
          'likes': 1000 + random.nextInt(5000),
          'comments': 50 + random.nextInt(300),
          'engagement_rate': '${(3 + random.nextDouble() * 5).toStringAsFixed(1)}%',
        };
      case 'Facebook':
        return {
          'friends': 500 + random.nextInt(2000),
          'page_likes': 200 + random.nextInt(1000),
          'posts': 30 + random.nextInt(100),
          'engagement_rate': '${(2 + random.nextDouble() * 3).toStringAsFixed(1)}%',
          'reach': 1000 + random.nextInt(10000),
        };
      default:
        return {
          'followers': 100 + random.nextInt(1000),
          'posts': 10 + random.nextInt(50),
          'engagement_rate': '${(1 + random.nextDouble() * 5).toStringAsFixed(1)}%',
        };
    }
  }
} 