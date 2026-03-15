import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart'; 

import 'providers/authProvider.dart';
import 'providers/themeProvider.dart';
import 'screens/authScreen/loginScreen.dart';
import 'screens/authScreen/signupScreen.dart';
import 'screens/appScreen/homeScreen.dart';
import 'config/theme.dart';
import 'widgets/authGuard/authGuard.dart';
import 'screens/authScreen/resetPasswordScreen.dart';

void main() {
  runApp(const MyApp());
}

// Chuyển sang StatefulWidget để dùng initState
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Tạo GlobalKey để điều hướng mà không cần truyền context trực tiếp
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel(); // dlean memory
    super.dispose();
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();

    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      debugPrint('Ngon lành, bắt được deep link: $uri');
      
      // Kiểm tra đúng scheme và host anh em mình set trong AndroidManifest không
      if (uri.scheme == 'socialapp' && uri.host == 'login') {
        // Dùng navigatorKey để đẩy về màn hình login
        _navigatorKey.currentState?.pushReplacementNamed('/login');
      }

      if (uri.path == '/reset-password' || uri.host == 'reset-password') {
        // Trích xuất cái token từ url (ví dụ: socialapp://reset-password?token=XYZ)
        final String? resetToken = uri.queryParameters['token'];
        
        if (resetToken != null && resetToken.isNotEmpty) {
          // Đá sang màn hình Reset Password và truyền token sang
          _navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => ResetPasswordScreen(token: resetToken),
            ),
          );
        } else {
          debugPrint("Toang, link reset không có token!");
        }
      }
    }, onError: (err) {
      debugPrint('Toang, lỗi nhận deep link: $err');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            navigatorKey: _navigatorKey, // Gắn cái key "quyền lực" vào đây
            title: 'Social Network App',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                if (authProvider.isAuthenticated) {
                  return const HomeScreen();
                }
                return const LoginScreen();
              },
            ),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/signup': (context) => const SignupScreen(),
              '/home': (context) => const AuthGuard(child: HomeScreen()),
            },
          );
        },
      ),
    );
  }
}