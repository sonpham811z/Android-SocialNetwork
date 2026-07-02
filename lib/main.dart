import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'providers/authProvider.dart';
import 'providers/conversationProvider.dart';
import 'providers/friendProvider.dart';
import 'providers/notificationProvider.dart';
import 'providers/postProvider.dart';
import 'providers/storyProvider.dart';
import 'providers/themeProvider.dart';
import 'providers/languageProvider.dart';
import 'providers/userProfileProvider.dart';
import 'providers/userSettingsProvider.dart';
import 'providers/boardProvider.dart';
import 'providers/presenceProvider.dart';
import 'screens/authScreen/loginScreen.dart';
import 'screens/authScreen/signupScreen.dart';
import 'screens/appScreen/homeScreen.dart';
import 'screens/appScreen/introOnboardingScreen.dart';
import 'config/theme.dart';
import 'widgets/authGuard/authGuard.dart';
import 'screens/authScreen/resetPasswordScreen.dart';
import 'screens/appScreen/friendRequestScreen.dart';

// Handle background FCM messages (must be top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM] Background message: ${message.messageId}');
}

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

Future<void> _initLocalNotifications() async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );
  await _localNotifications.initialize(
    const InitializationSettings(android: android, iOS: ios),
  );
}

Future<void> _showLocalNotification(RemoteMessage message) async {
  final notification = message.notification;
  if (notification == null) return;

  const channel = AndroidNotificationChannel(
    'social_network_high',
    'Social Network Notifications',
    importance: Importance.high,
  );

  await _localNotifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await _localNotifications.show(
    notification.hashCode,
    notification.title,
    notification.body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        icon: '@mipmap/ic_launcher',
      ),
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase init — graceful fallback if google-services.json not yet configured
  bool firebaseReady = false;
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await _initLocalNotifications();
    firebaseReady = true;
    debugPrint('[Firebase] Initialized');
  } catch (e) {
    debugPrint('[Firebase] Not configured yet — push notifications disabled. $e');
  }

  runApp(MyApp(firebaseReady: firebaseReady));
}

class MyApp extends StatefulWidget {
  final bool firebaseReady;
  const MyApp({super.key, required this.firebaseReady});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    if (widget.firebaseReady) _initFcmHandlers();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _initFcmHandlers() {
    // Foreground messages → show local notification
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('[FCM] Foreground message: ${message.messageId}');
      _showLocalNotification(message);
    });

    // Tapped notification when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('[FCM] Opened from background: ${message.messageId}');
    });
  }

  void _initDeepLinks() async {
    _appLinks = AppLinks();
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) _handleDeepLink(initialUri);
    } catch (e) {
      debugPrint('Deep link init error: $e');
    }
    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleDeepLink,
      onError: (err) => debugPrint('Deep link stream error: $err'),
    );
  }

  void _handleDeepLink(Uri uri) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (uri.scheme == 'socialapp' && uri.host == 'login') {
        _navigatorKey.currentState?.pushReplacementNamed('/login');
      }
      if (uri.path == '/reset-password' || uri.host == 'reset-password') {
        final resetToken = uri.queryParameters['token'];
        if (resetToken != null && resetToken.isNotEmpty) {
          _navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => ResetPasswordScreen(token: resetToken),
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        ChangeNotifierProvider(create: (_) => UserSettingsProvider()),
        ChangeNotifierProvider(create: (_) => FriendProvider()),
        ChangeNotifierProvider(create: (_) => PostProvider()),
        ChangeNotifierProvider(create: (_) => StoryProvider()),
        ChangeNotifierProvider(create: (_) => ConversationProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => BoardProvider()),
        ChangeNotifierProvider(create: (_) => PresenceProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            navigatorKey: _navigatorKey,
            title: 'Social Network App',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: _PostAuthEntryScreen(firebaseReady: widget.firebaseReady),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/signup': (context) => const SignupScreen(),
              '/home': (context) => const AuthGuard(
                      child: _PostAuthEntryScreen(firebaseReady: false)),
              '/friend-requests': (context) => FriendRequestScreen(),
            },
          );
        },
      ),
    );
  }
}

class _PostAuthEntryScreen extends StatefulWidget {
  final bool firebaseReady;
  const _PostAuthEntryScreen({required this.firebaseReady});

  @override
  State<_PostAuthEntryScreen> createState() => _PostAuthEntryScreenState();
}

class _PostAuthEntryScreenState extends State<_PostAuthEntryScreen> {
  bool _fcmRegistered = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isCheckingAuth) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!authProvider.isAuthenticated) {
          _fcmRegistered = false;
          return const LoginScreen();
        }

        // Register FCM device token once after login
        if (widget.firebaseReady && !_fcmRegistered) {
          _fcmRegistered = true;
          _registerFcmToken(context);
        }

        if (authProvider.shouldShowIntro) {
          return IntroOnboardingScreen(
            onCompleted: () => context.read<AuthProvider>().markIntroAsSeen(),
          );
        }

        return const HomeScreen();
      },
    );
  }

  Future<void> _registerFcmToken(BuildContext context) async {
    // Capture provider before any await to avoid BuildContext-across-async-gap lint
    final notifProvider = context.read<NotificationProvider>();
    try {
      final messaging = FirebaseMessaging.instance;

      // Request permission (iOS / Android 13+)
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      final token = await messaging.getToken();
      if (token == null || !mounted) return;

      final platform = Platform.isIOS ? 'ios' : 'android';
      await notifProvider.registerDeviceToken(token, platform);
      debugPrint('[FCM] Token registered: ${token.substring(0, 10)}...');

      // Re-register when token refreshes
      messaging.onTokenRefresh.listen((newToken) {
        notifProvider.registerDeviceToken(newToken, platform);
      });
    } catch (e) {
      debugPrint('[FCM] Token registration error: $e');
    }
  }
}
