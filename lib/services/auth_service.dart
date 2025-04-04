import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mongo_dart/mongo_dart.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

enum AuthStatus {
  initial,
  authenticating,
  authenticated,
  unauthenticated,
  error,
}

class User {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String provider;

  User({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.provider,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? json['display_name'],
      photoUrl: json['photoUrl'] ?? json['photo_url'],
      provider: json['provider'] ?? 'email',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'provider': provider,
    };
  }
}

class AuthService extends ChangeNotifier {
  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _token;
  String? _errorMessage;
  
  // MongoDB connection
  Db? _db;
  DbCollection? _userCollection;
  
  // Social login providers
  GoogleSignIn? _googleSignIn;
  
  // API endpoints (Cloudflare)
  final String _baseUrl = 'https://elevate-auth.yourdomain.workers.dev';
  
  // For development, use a mock MongoDB connection string
  // In production, this should be securely stored and not hardcoded
  final String _mongoDbUri = 'mongodb+srv://username:password@cluster.mongodb.net/elevate_app';
  
  // Flag to use mock responses for development
  final bool _useMockResponses = true;

  bool _isLoading = false;
  final bool _isAuthenticated = false;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get token => _token;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  AuthService() {
    // Initialize the database connection when the service is created
    _initializeMongoDB();
    
    // Initialize GoogleSignIn only if not using mock responses
    if (!_useMockResponses) {
      _googleSignIn = GoogleSignIn(scopes: ['email']);
    }
  }

  // Initialize the database connection
  Future<void> _initializeMongoDB() async {
    if (_useMockResponses) {
      // Skip actual DB connection when using mock responses
      return;
    }
    
    try {
      _db = await Db.create(_mongoDbUri);
      await _db!.open();
      _userCollection = _db!.collection('users');
      debugPrint('MongoDB connection established');
    } catch (e) {
      _errorMessage = 'Failed to connect to database: $e';
      _status = AuthStatus.error;
      debugPrint('MongoDB connection failed: $e');
      notifyListeners();
    }
  }

  // Email & Password Registration
  Future<bool> register(String email, String password, String name) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_useMockResponses) {
        // Simulate registration with mock data
        await Future.delayed(const Duration(seconds: 1));
        
        // Check if email is already used (simulate "user already exists" for test@test.com)
        if (email.toLowerCase() == 'test@test.com') {
          _errorMessage = 'Email already registered';
          _status = AuthStatus.unauthenticated;
          notifyListeners();
          return false;
        }
        
        // Create mock user
        final mockUserId = ObjectId();
        _token = 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}';
        _user = User(
          id: mockUserId.$oid,
          email: email,
          displayName: name,
          provider: 'email',
        );
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }
      
      // Real MongoDB implementation
      // Check if the user exists
      var existingUser = await _userCollection?.findOne(where.eq('email', email));
      if (existingUser != null) {
        _errorMessage = 'Email already registered';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }

      // Create a new user document
      final userId = ObjectId();
      final hash = await _hashPassword(password);
      
      await _userCollection?.insertOne({
        '_id': userId,
        'email': email,
        'password': hash,
        'displayName': name,
        'provider': 'email',
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      });

      // Generate JWT via Cloudflare Worker
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        _user = User(
          id: userId.$oid,
          email: email,
          displayName: name,
          provider: 'email',
        );
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(response.body);
        _errorMessage = data['message'] ?? 'Registration failed';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Registration failed: $e';
      _status = AuthStatus.error;
      debugPrint('Registration error: $e');
      notifyListeners();
      return false;
    }
  }

  // Email & Password Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_useMockResponses) {
        // Simulate login with mock data
        await Future.delayed(const Duration(seconds: 1));
        
        // Improved mock authentication logic
        // Check if the email format is valid
        final bool isValidEmail = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
        if (!isValidEmail) {
          throw Exception('Invalid email format');
        }
        
        // For testing purposes with improved validation:
        // - Allow login with any email-format address that contains "test" or "example"
        // - Password must be at least 6 characters
        if ((email.toLowerCase().contains('test') || email.toLowerCase().contains('example')) && 
            password.length >= 6) {
          final username = email.split('@')[0];
          final displayName = username.split('.').map((part) => 
            part.isNotEmpty ? '${part[0].toUpperCase()}${part.substring(1)}' : ''
          ).join(' ');
          
          _token = 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}';
          _user = User(
            id: 'mock_user_id_${DateTime.now().millisecondsSinceEpoch}',
            email: email,
            displayName: displayName,
            provider: 'email',
          );
          _status = AuthStatus.authenticated;
          notifyListeners();
          return true;
        } else {
          _errorMessage = 'Invalid email or password';
          _status = AuthStatus.unauthenticated;
          notifyListeners();
          return false;
        }
      }
      
      // Real implementation
      // Verify credentials with MongoDB
      var userDoc = await _userCollection?.findOne(where.eq('email', email));
      if (userDoc == null) {
        _errorMessage = 'User not found';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }

      final isValidPassword = await _verifyPassword(password, userDoc['password']);
      if (!isValidPassword) {
        _errorMessage = 'Invalid password';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }

      // Generate JWT via Cloudflare Worker
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        _user = User.fromJson(userDoc);
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(response.body);
        _errorMessage = data['message'] ?? 'Login failed';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Login failed: $e';
      _status = AuthStatus.error;
      debugPrint('Login error: $e');
      notifyListeners();
      return false;
    }
  }

  // Google Sign In
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_useMockResponses) {
        // Simulate Google sign-in with mock data
        await Future.delayed(const Duration(seconds: 1));
        
        _token = 'mock_google_token_${DateTime.now().millisecondsSinceEpoch}';
        _user = User(
          id: 'google_user_id',
          email: 'google.user@example.com',
          displayName: 'Google User',
          photoUrl: 'https://ui-avatars.com/api/?name=Google+User&background=4285F4&color=fff',
          provider: 'google',
        );
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }
      
      // Real implementation
      final GoogleSignInAccount? googleUser = await _googleSignIn?.signIn();
      if (googleUser == null) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Authenticate with Cloudflare Worker
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idToken': googleAuth.idToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        
        // Check if user exists, create if not
        var userDoc = await _userCollection?.findOne(where.eq('email', googleUser.email));
        if (userDoc == null) {
          final userId = ObjectId();
          await _userCollection?.insertOne({
            '_id': userId,
            'email': googleUser.email,
            'displayName': googleUser.displayName,
            'photoUrl': googleUser.photoUrl,
            'provider': 'google',
            'createdAt': DateTime.now().toUtc().toIso8601String(),
          });
          userDoc = {
            '_id': userId,
            'email': googleUser.email,
            'displayName': googleUser.displayName,
            'photoUrl': googleUser.photoUrl,
            'provider': 'google',
          };
        }
        
        _user = User.fromJson(userDoc);
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        _googleSignIn?.signOut();
        final data = jsonDecode(response.body);
        _errorMessage = data['message'] ?? 'Google authentication failed';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Google sign in failed: $e';
      _status = AuthStatus.error;
      debugPrint('Google sign-in error: $e');
      notifyListeners();
      return false;
    }
  }

  // Facebook Sign In
  Future<bool> signInWithFacebook() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_useMockResponses) {
        // Simulate Facebook sign-in with mock data
        await Future.delayed(const Duration(seconds: 1));
        
        _token = 'mock_facebook_token_${DateTime.now().millisecondsSinceEpoch}';
        _user = User(
          id: 'facebook_user_id',
          email: 'facebook.user@example.com',
          displayName: 'Facebook User',
          photoUrl: 'https://ui-avatars.com/api/?name=Facebook+User&background=1877F2&color=fff',
          provider: 'facebook',
        );
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }
      
      // Real implementation
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status != LoginStatus.success) {
        _errorMessage = 'Facebook login canceled or failed';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }

      final userData = await FacebookAuth.instance.getUserData();
      
      // Authenticate with Cloudflare Worker
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/facebook'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'accessToken': result.accessToken!.token,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        
        // Check if user exists, create if not
        var userDoc = await _userCollection?.findOne(where.eq('email', userData['email']));
        if (userDoc == null) {
          final userId = ObjectId();
          await _userCollection?.insertOne({
            '_id': userId,
            'email': userData['email'],
            'displayName': userData['name'],
            'photoUrl': userData['picture']['data']['url'],
            'provider': 'facebook',
            'createdAt': DateTime.now().toUtc().toIso8601String(),
          });
          userDoc = {
            '_id': userId,
            'email': userData['email'],
            'displayName': userData['name'],
            'photoUrl': userData['picture']['data']['url'],
            'provider': 'facebook',
          };
        }
        
        _user = User.fromJson(userDoc);
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        await FacebookAuth.instance.logOut();
        final data = jsonDecode(response.body);
        _errorMessage = data['message'] ?? 'Facebook authentication failed';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Facebook sign in failed: $e';
      _status = AuthStatus.error;
      debugPrint('Facebook sign-in error: $e');
      notifyListeners();
      return false;
    }
  }

  // GitHub Sign In (simplified)
  Future<bool> signInWithGitHub() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_useMockResponses) {
        // Simulate GitHub sign-in with mock data
        await Future.delayed(const Duration(seconds: 1));
        
        _token = 'mock_github_token_${DateTime.now().millisecondsSinceEpoch}';
        _user = User(
          id: 'github_user_id',
          email: 'github.user@example.com',
          displayName: 'GitHub User',
          photoUrl: 'https://ui-avatars.com/api/?name=GitHub+User&background=181717&color=fff',
          provider: 'github',
        );
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }
      
      // For a real implementation, you would use a proper OAuth flow
      // This is a simplified version
      
      // For this example, we'll use a mock implementation
      final userData = {
        'email': 'github_user@example.com',
        'name': 'GitHub User',
        'avatar_url': 'https://github.com/github-avatar.png'
      };
      
      // Check if user exists, create if not
      var userDoc = await _userCollection?.findOne(where.eq('email', userData['email']));
      if (userDoc == null) {
        final userId = ObjectId();
        await _userCollection?.insertOne({
          '_id': userId,
          'email': userData['email'],
          'displayName': userData['name'],
          'photoUrl': userData['avatar_url'],
          'provider': 'github',
          'createdAt': DateTime.now().toUtc().toIso8601String(),
        });
        userDoc = {
          '_id': userId,
          'email': userData['email'],
          'displayName': userData['name'],
          'photoUrl': userData['avatar_url'],
          'provider': 'github',
        };
      }
      
      _user = User.fromJson(userDoc);
      _status = AuthStatus.authenticated;
      _token = 'mock_github_token';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'GitHub sign in failed: $e';
      _status = AuthStatus.error;
      debugPrint('GitHub sign-in error: $e');
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      if (!_useMockResponses) {
        // Sign out from providers if using real implementation
        try {
          if (_googleSignIn != null) {
            await _googleSignIn!.signOut();
          }
          
          try {
            await FacebookAuth.instance.logOut();
          } catch (e) {
            // Ignore Facebook logout errors in web mode
            debugPrint('Facebook logout error (can be ignored): $e');
          }
          
          // Clear token from Cloudflare
          if (_token != null) {
            await http.post(
              Uri.parse('$_baseUrl/auth/logout'),
              headers: {'Authorization': 'Bearer $_token'},
            );
          }
        } catch (e) {
          debugPrint('Error during logout: $e');
          // Continue with local logout even if server logout fails
        }
      }
    } finally {
      // Always reset local state
      _status = AuthStatus.initial;
      _user = null;
      _token = null;
      _errorMessage = null;
      notifyListeners();
    }
  }

  // Check if the user is already authenticated (e.g., from stored token)
  Future<bool> checkAuthState() async {
    // In a real app, you would check for a stored token and validate it
    // For this example, we'll just return false
    return false;
  }

  // Password hashing (mock implementation - in production use a proper hashing library)
  Future<String> _hashPassword(String password) async {
    // In a real app, use a proper password hashing library
    // This is just a placeholder for the example
    return base64.encode(utf8.encode(password));
  }

  // Password verification (mock implementation - in production use a proper hashing library)
  Future<bool> _verifyPassword(String password, String hash) async {
    // In a real app, use a proper password verification function
    // This is just a placeholder for the example
    return base64.encode(utf8.encode(password)) == hash;
  }
} 