import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../providers/authProvider.dart';
import '../../providers/themeProvider.dart';
import '../../widgets/customTextField.dart';
import '../../widgets/googleButton.dart';
import '../../config/theme.dart';
import '../../services/authService.dart';
import '../../config/environment.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

// Thêm SingleTickerProviderStateMixin để làm animation cho cái vòng tròn Pulse
class _SignupScreenState extends State<SignupScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Biến kiểm soát hiển thị màn hình Verify
  bool _isSubmitted = false;
  bool _isResending = false;

  // Controller cho hiệu ứng vòng tròn nhấp nháy (Pulse Animation)
  late AnimationController _pulseController;
  
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: Environment.googleClientId, 
    scopes: ['email', 'profile', 'openid'],
  );

  @override
  void initState() {
    super.initState();
    // Khởi tạo animation lặp đi lặp lại liên tục
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final success = await authProvider.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        dateOfBirth: '1990-01-01', // Default date
        gender: 'Other', // Default gender
      );

      if (mounted) {
        if (success) {
          // Thay vì chuyển sang /home, giờ ta chuyển sang màn hình Verify
          setState(() {
            _isSubmitted = true;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.error ?? 'Registration failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Hàm xử lý gửi lại email
  Future<void> _handleResendEmail() async {
    setState(() {
      _isResending = true;
    });

    // TODO: Tích hợp gọi API Resend Email ở đây
    await Future.delayed(const Duration(seconds: 2)); // Giả lập loading 2s

    if (mounted) {
      setState(() {
        _isResending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email resent! Please check your inbox.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final credential = googleAuth.idToken;

        if (credential != null && mounted) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          final success = await authProvider.googleLogin(credential);

          if (mounted) {
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Google signup successful!'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pushReplacementNamed(context, '/home');
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(authProvider.error ?? 'Google signup failed'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google sign in error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 1024;
    final isTablet = size.width > 600 && size.width <= 1024;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF1E1E1E),
                        const Color(0xFF0F0F10),
                      ]
                    : [
                        AppTheme.slate100,
                        AppTheme.slate200,
                        AppTheme.slate100,
                      ],
              ),
            ),
          ),
          
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: isDesktop ? 192 : 128,
              height: isDesktop ? 192 : 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.violetPrimary.withOpacity(0.3),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            right: -40,
            child: Container(
              width: isDesktop ? 144 : 96,
              height: isDesktop ? 144 : 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark 
                    ? AppTheme.slate700.withOpacity(0.3)
                    : AppTheme.slate300.withOpacity(0.5),
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(isDesktop ? 32 : 16),
                child: Center(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 1200 : (isTablet ? 800 : 600),
                    ),
                    child: Card(
                      elevation: 20,
                      shadowColor: AppTheme.violetPrimary.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: isDesktop
                          ? _buildDesktopLayout(authProvider, isDark)
                          : _buildMobileLayout(authProvider, isDark),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(AuthProvider authProvider, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.violetPrimary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                bottomLeft: Radius.circular(24),
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.2,
                    child: CustomPaint(
                      painter: WavePainter(),
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.group_outlined,
                            size: 200,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Join Our Community!',
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Chuyển đổi giữa Form đăng ký và Giao diện Verify
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: _isSubmitted 
                ? _buildVerificationLayout(isDark) 
                : _buildFormContent(authProvider, isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(AuthProvider authProvider, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      // Chuyển đổi giữa Form đăng ký và Giao diện Verify
      child: _isSubmitted 
          ? _buildVerificationLayout(isDark) 
          : _buildFormContent(authProvider, isDark),
    );
  }

  // --- UI VERIFY EMAIL (Bê từ React qua) ---
  Widget _buildVerificationLayout(bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Animation Icon vòng tròn tỏa ra
        Stack(
          alignment: Alignment.center,
          children: [
            // Vòng tròn tỏa ra (Pulse)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_pulseController.value * 0.5), // Phóng to 1.5 lần
                  child: Opacity(
                    opacity: 1.0 - _pulseController.value, // Mờ dần
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.violetPrimary.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            // Nền tĩnh và Icon mail bên trong
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.violetPrimary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mark_email_unread_outlined, 
                color: AppTheme.violetPrimary, 
                size: 40,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),

        Text(
          'Check Your Email',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'We have sent a verification link to',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: isDark ? AppTheme.slate400 : AppTheme.slate500,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 4),
        
        Text(
          _emailController.text, // Lấy email người dùng vừa nhập
          style: const TextStyle(
            color: AppTheme.violetPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 24),

        Text(
          "Click the link in the email to verify your account. If you don't see it, check your spam folder.",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isDark ? AppTheme.slate500 : AppTheme.slate400,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 32),

        // Nút Resend Email
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _isResending ? null : _handleResendEmail,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40),
            ),
            child: _isResending
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Resend Email'),
          ),
        ),

        const SizedBox(height: 16),

        // Nút Back to Login
        TextButton.icon(
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/login');
          },
          icon: Icon(
            Icons.arrow_back, 
            size: 16, 
            color: isDark ? AppTheme.slate400 : AppTheme.slate500,
          ),
          label: Text(
            'Back to Login',
            style: TextStyle(
              color: isDark ? AppTheme.slate400 : AppTheme.slate500,
            ),
          ),
        ),
      ],
    );
  }

  // --- UI FORM ĐĂNG KÝ (Giữ nguyên như cũ) ---
  Widget _buildFormContent(AuthProvider authProvider, bool isDark) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          
          Stack(
            alignment: Alignment.center,
            children: [
              Column(
                children: [
                  Text(
                    'SIGN UP',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Create account',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              Positioned(
                right: 0,
                top: 0,
                child: IconButton(
                  icon: Icon(
                    isDark ? Icons.light_mode : Icons.dark_mode,
                    color: isDark ? Colors.amber : AppTheme.slate900,
                  ),
                  onPressed: () {
                    themeProvider.toggleTheme();
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          if (authProvider.error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                authProvider.error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),

          CustomTextField(
            controller: _firstNameController,
            hintText: 'First Name',
            prefixIcon: Icons.person_outline,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your first name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          CustomTextField(
            controller: _lastNameController,
            hintText: 'Last Name',
            prefixIcon: Icons.person_outline,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your last name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          CustomTextField(
            controller: _emailController,
            hintText: 'Email',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          CustomTextField(
            controller: _passwordController,
            hintText: 'Password',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: isDark ? AppTheme.slate400 : AppTheme.slate500,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 8) {
                return 'Password must be at least 8 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          CustomTextField(
            controller: _confirmPasswordController,
            hintText: 'Confirm Password',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscureConfirmPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                color: isDark ? AppTheme.slate400 : AppTheme.slate500,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: authProvider.isLoading ? null : _handleSignup,
              child: authProvider.isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Sign Up Now'),
            ),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(child: Divider(color: isDark ? AppTheme.slate700 : AppTheme.slate200)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Sign up',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.slate900,
                        ),
                      ),
                      TextSpan(
                        text: ' with Others',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(child: Divider(color: isDark ? AppTheme.slate700 : AppTheme.slate200)),
            ],
          ),
          const SizedBox(height: 24),

          GoogleSignInButton(
            onPressed: _handleGoogleSignIn,
            text: 'Sign up with Google',
          ),
          const SizedBox(height: 24),

          Center(
            child: RichText(
              text: TextSpan(
                text: "Already have an account? ",
                style: Theme.of(context).textTheme.bodyMedium,
                children: [
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: Text(
                        'Login',
                        style: TextStyle(
                          color: AppTheme.violetPrimary,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path1 = Path();
    path1.moveTo(0, size.height * 0.25);
    path1.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.3,
      size.width * 0.5,
      size.height * 0.25,
    );
    path1.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.2,
      size.width,
      size.height * 0.25,
    );
    path1.lineTo(size.width, 0);
    path1.lineTo(0, 0);
    path1.close();

    canvas.drawPath(path1, paint);

    final path2 = Path();
    path2.moveTo(0, size.height * 0.5);
    path2.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.55,
      size.width * 0.5,
      size.height * 0.5,
    );
    path2.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.45,
      size.width,
      size.height * 0.5,
    );
    path2.lineTo(size.width, size.height * 0.25);
    path2.lineTo(0, size.height * 0.25);
    path2.close();

    canvas.drawPath(path2, paint..color = Colors.white.withOpacity(0.05));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}