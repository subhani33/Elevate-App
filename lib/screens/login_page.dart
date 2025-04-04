import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../widgets/custom_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  
  bool _isLogin = true;
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isFacebookLoading = false;
  bool _isGithubLoading = false;
  
  late final AnimationController _animationController;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 400),
    );
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
      if (_isLogin) {
        _animationController.reverse();
      } else {
        _animationController.forward();
      }
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    final authService = Provider.of<AuthService>(context, listen: false);
    bool success;
    
    try {
      if (_isLogin) {
        success = await authService.login(
          _emailController.text.trim(),
          _passwordController.text,
        );
        
        if (success && mounted) {
          // Show welcome message
          final user = authService.user;
          final displayName = user?.displayName ?? 'User';
          
          _showWelcomeDialog(displayName);
          
          // Navigate to dashboard after showing welcome message
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.of(context).pushReplacementNamed('/dashboard');
            }
          });
        } else if (mounted) {
          setState(() {
            _errorMessage = authService.errorMessage ?? 'Login failed';
            _isLoading = false;
          });
          
          // Show error as SnackBar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_errorMessage ?? 'Authentication failed'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        // Registration
        if (_nameController.text.trim().isEmpty) {
          setState(() {
            _errorMessage = 'Please enter your name';
            _isLoading = false;
          });
          return;
        }
        
        success = await authService.register(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
        );
        
        if (success && mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful! Please log in.'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Switch to login mode
          setState(() {
            _isLogin = true;
            _isLoading = false;
            _animationController.reverse();
          });
        } else if (mounted) {
          setState(() {
            _errorMessage = authService.errorMessage ?? 'Registration failed';
            _isLoading = false;
          });
          
          // Show error as SnackBar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_errorMessage ?? 'Registration failed'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred: $e';
          _isLoading = false;
        });
        
        // Show error as SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_isGoogleLoading) return;
    
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final success = await authService.signInWithGoogle();
      
      if (success && mounted) {
        // Show welcome message
        final user = authService.user;
        final displayName = user?.displayName ?? 'User';
        
        _showWelcomeDialog(displayName);
        
        // Navigate to dashboard after showing welcome message
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/dashboard');
          }
        });
      } else if (mounted) {
        setState(() {
          _errorMessage = authService.errorMessage ?? 'Google sign-in failed';
          _isGoogleLoading = false;
        });
        
        // Show error as SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage ?? 'Authentication failed'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred: $e';
          _isGoogleLoading = false;
        });
        
        // Show error as SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _signInWithFacebook() async {
    if (_isFacebookLoading) return;
    
    setState(() {
      _isFacebookLoading = true;
      _errorMessage = null;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final success = await authService.signInWithFacebook();
      
      if (success && mounted) {
        // Show welcome message
        final user = authService.user;
        final displayName = user?.displayName ?? 'User';
        
        _showWelcomeDialog(displayName);
        
        // Navigate to dashboard after showing welcome message
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/dashboard');
          }
        });
      } else if (mounted) {
        setState(() {
          _errorMessage = authService.errorMessage ?? 'Facebook sign-in failed';
          _isFacebookLoading = false;
        });
        
        // Show error as SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage ?? 'Authentication failed'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred: $e';
          _isFacebookLoading = false;
        });
        
        // Show error as SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _signInWithGitHub() async {
    if (_isGithubLoading) return;
    
    setState(() {
      _isGithubLoading = true;
      _errorMessage = null;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final success = await authService.signInWithGitHub();
      
      if (success && mounted) {
        // Show welcome message
        final user = authService.user;
        final displayName = user?.displayName ?? 'User';
        
        _showWelcomeDialog(displayName);
        
        // Navigate to dashboard after showing welcome message
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/dashboard');
          }
        });
      } else if (mounted) {
        setState(() {
          _errorMessage = authService.errorMessage ?? 'GitHub sign-in failed';
          _isGithubLoading = false;
        });
        
        // Show error as SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage ?? 'Authentication failed'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred: $e';
          _isGithubLoading = false;
        });
        
        // Show error as SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showWelcomeDialog(String displayName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Welcome'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 50,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome back, $displayName!',
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    } else if (!_isLogin && value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (!_isLogin && (value == null || value.isEmpty)) {
      return 'Please enter your name';
    }
    return null;
  }

  void _showErrorMessage() {
    if (_errorMessage != null && _errorMessage!.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
      // Clear the error message after showing it
      setState(() {
        _errorMessage = null;
      });
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Show error message if it exists
    _showErrorMessage();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final viewInsets = MediaQuery.of(context).viewInsets;
    final isKeyboardOpen = viewInsets.bottom > 0;
    
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1A237E), // Deep blue
                  Color(0xFF7B1FA2), // Purple
                ],
              ),
            ),
          ),
          
          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 400),
                  child: Card(
                    elevation: 4.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    color: Colors.white.withOpacity(0.9),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Logo and title
                          Center(
                            child: Column(
                              children: [
                                // Elevate Logo
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Elevate',
                                      style: TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF6B4EFF),
                                        letterSpacing: 1.2,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black12,
                                            offset: Offset(0, 2),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.star,
                                      color: const Color(0xFF6B4EFF),
                                      size: 28,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _isLogin ? 'Welcome Back' : 'Create Account',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _isLogin
                                      ? 'Sign in to continue to your account'
                                      : 'Fill in your details to get started',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
                          
                          const SizedBox(height: 32),
                          
                          // Form
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Name field (only for register)
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  height: _isLogin ? 0 : 80,
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 300),
                                    opacity: _isLogin ? 0 : 1,
                                    child: TextFormField(
                                      controller: _nameController,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white,
                                        hintText: 'Full Name',
                                        prefixIcon: const Icon(Icons.person),
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
                                          borderSide: const BorderSide(color: Color(0xFF6B4EFF), width: 2),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Colors.red, width: 2),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                      ),
                                      validator: _validateName,
                                      textInputAction: TextInputAction.next,
                                    ),
                                  ),
                                ),
                                
                                // Email field
                                TextFormField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    hintText: 'Email',
                                    prefixIcon: const Icon(Icons.email),
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
                                      borderSide: const BorderSide(color: Color(0xFF6B4EFF), width: 2),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Colors.red, width: 2),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: _validateEmail,
                                  textInputAction: TextInputAction.next,
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Password field
                                TextFormField(
                                  controller: _passwordController,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    hintText: 'Password',
                                    prefixIcon: const Icon(Icons.lock),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isPasswordVisible = !_isPasswordVisible;
                                        });
                                      },
                                    ),
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
                                      borderSide: const BorderSide(color: Color(0xFF6B4EFF), width: 2),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Colors.red, width: 2),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  obscureText: !_isPasswordVisible,
                                  validator: _validatePassword,
                                  textInputAction: _isLogin ? TextInputAction.done : TextInputAction.next,
                                ),
                              ],
                            ),
                          ).animate()
                            .fadeIn(delay: const Duration(milliseconds: 500))
                            .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
                          
                          const SizedBox(height: 16),
                          
                          // Remember me and forgot password
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      onChanged: (value) {
                                        setState(() {
                                          _rememberMe = value!;
                                        });
                                      },
                                      activeColor: const Color(0xFF6B4EFF),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Remember me',
                                    style: TextStyle(
                                      color: Color(0xFF333333),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              if (_isLogin)
                                TextButton(
                                  onPressed: () {
                                    // Handle forgot password
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Password reset feature coming soon!'),
                                        backgroundColor: Color(0xFF6B4EFF),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      color: Color(0xFF6B4EFF),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ).animate().fadeIn(delay: const Duration(milliseconds: 600)),
                          
                          const SizedBox(height: 24),
                          
                          // Sign in / Sign up button
                          ElevatedButton(
                            onPressed: _isLoading ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6B4EFF),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFF6B4EFF).withOpacity(0.5),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    _isLogin ? 'Sign In' : 'Sign Up',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ).animate().fadeIn(delay: const Duration(milliseconds: 700)),
                          
                          const SizedBox(height: 20),
                          
                          // Or continue with
                          if (!isKeyboardOpen)
                            Row(
                              children: [
                                Expanded(child: Divider(color: Colors.grey[400])),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'Or continue with',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: Colors.grey[400])),
                              ],
                            ).animate().fadeIn(delay: const Duration(milliseconds: 800)),
                          
                          const SizedBox(height: 16),
                          
                          // Social login buttons
                          if (!isKeyboardOpen)
                            Column(
                              children: [
                                SocialLoginButton(
                                  label: 'Google',
                                  iconPath: 'assets/google_logo.svg',
                                  onPressed: _signInWithGoogle,
                                  isLoading: _isGoogleLoading,
                                ),
                                
                                SocialLoginButton(
                                  label: 'Facebook',
                                  iconPath: 'assets/facebook_logo.svg',
                                  onPressed: _signInWithFacebook,
                                  isLoading: _isFacebookLoading,
                                ),
                                
                                SocialLoginButton(
                                  label: 'GitHub',
                                  iconPath: 'assets/github_logo.svg',
                                  onPressed: _signInWithGitHub,
                                  isLoading: _isGithubLoading,
                                ),
                              ],
                            ).animate().fadeIn(delay: const Duration(milliseconds: 900)),
                          
                          const SizedBox(height: 24),
                          
                          // Sign up / Sign in text (at bottom)
                          Center(
                            child: RichText(
                              text: TextSpan(
                                text: _isLogin ? "Don't have an account? " : "Already have an account? ",
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 14,
                                ),
                                children: [
                                  TextSpan(
                                    text: _isLogin ? 'Sign Up' : 'Sign In',
                                    style: const TextStyle(
                                      color: Color(0xFF6B4EFF),
                                      fontWeight: FontWeight.bold,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = _toggleAuthMode,
                                  ),
                                ],
                              ),
                            ),
                          ).animate().fadeIn(delay: const Duration(milliseconds: 1000)),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn().scale(
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1.0, 1.0),
                      duration: 500.ms,
                      curve: Curves.easeOutQuad,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 