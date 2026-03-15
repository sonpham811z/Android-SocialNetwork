import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/customTextField.dart'; // Import cái widget quen thuộc của bro
import 'package:provider/provider.dart';
import '../../providers/authProvider.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleChangePassword() async {
    // 1. Check validate form
    if (_formKey.currentState!.validate()) {
      
      // 2. Bật màn hình Loading full màn hình, chặn hoàn toàn thao tác (Chống spam)
      showDialog(
        context: context,
        barrierDismissible: false, // Bắt buộc đợi, không cho bấm ra ngoài để tắt
        builder: (context) => PopScope(
          canPop: false, // Chặn luôn nút Back vật lý trên Android
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? const Color(0xFF1E1E1E) 
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const CircularProgressIndicator(), // Vòng quay vô cực
            ),
          ),
        ),
      );

      // 3. Gọi Provider để bắn API
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      // 4. Xử lý sau khi gọi API xong
      if (mounted) {
        // Tắt cái Loading Dialog đi
        Navigator.pop(context);

        if (success) {
          // Báo thành công 
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đổi mật khẩu thành công!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          // Đá về màn hình Settings
          Navigator.pop(context); 
        } else {
          // Hiện thông báo lỗi màu đỏ (từ cái ApiError bóc ra)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.error ?? 'Đổi mật khẩu thất bại!'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F10) : AppTheme.slate50,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F0F10) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Change Password',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create a new password',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.slate900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your new password must be different from previous used passwords.',
                style: TextStyle(
                  color: isDark ? AppTheme.slate400 : AppTheme.slate500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),

              // --- Current Password ---
              CustomTextField(
                controller: _currentPasswordController,
                hintText: 'Current Password',
                prefixIcon: Icons.lock_outline,
                obscureText: _obscureCurrent,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureCurrent ? Icons.visibility_off : Icons.visibility,
                    color: isDark ? AppTheme.slate400 : AppTheme.slate500,
                  ),
                  onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your current password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // --- New Password ---
              CustomTextField(
                controller: _newPasswordController,
                hintText: 'New Password',
                prefixIcon: Icons.lock_reset_outlined,
                obscureText: _obscureNew,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNew ? Icons.visibility_off : Icons.visibility,
                    color: isDark ? AppTheme.slate400 : AppTheme.slate500,
                  ),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  if (value == _currentPasswordController.text) {
                    return 'New password must be different from the old one';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // --- Confirm New Password ---
              CustomTextField(
                controller: _confirmPasswordController,
                hintText: 'Confirm New Password',
                prefixIcon: Icons.check_circle_outline,
                obscureText: _obscureConfirm,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                    color: isDark ? AppTheme.slate400 : AppTheme.slate500,
                  ),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your new password';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),

              // --- Submit Button ---
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleChangePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.violetPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Update Password',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}