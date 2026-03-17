import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/authProvider.dart';
import '../../screens/authScreen/loginScreen.dart';

class AuthGuard extends StatefulWidget{
  final Widget child;

  const AuthGuard({
    super.key, 
    required this.child
  });

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  @override
  void initState() {
    super.initState();
    // Gọi hàm check token để đảm bảo data luôn mới nhất
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // 1. Đang móc token -> Hiện màn hình chờ
        if (authProvider.isCheckingAuth) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // 2. Có token -> Thả cửa cho vào màn hình chính
        if (authProvider.isAuthenticated) {
          return widget.child;
        }

        // 3. Không có token -> Sút về màn Login
        return const LoginScreen();
      },
    );
  }
}