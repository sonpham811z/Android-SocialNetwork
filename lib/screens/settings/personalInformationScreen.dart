import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../providers/userProfileProvider.dart';

class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  State<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState
    extends State<PersonalInformationScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _fullNameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;
  late TextEditingController _bioController;

  // Track which fields are currently editable
  final Map<String, bool> _editableFields = {
    'fullName': false,
    'username': false,
    'email': false,
    'phone': false,
    'dob': false,
    'bio': false,
  };

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile =
        Provider.of<UserProfileProvider>(context, listen: false).profile;

    _fullNameController =
        TextEditingController(text: profile?.displayName ?? '');
    _usernameController =
        TextEditingController(text: profile?.username ?? '');
    _emailController = TextEditingController(text: profile?.email ?? '');
    _phoneController =
        TextEditingController(text: profile?.phoneNumber ?? '');
    _dobController =
        TextEditingController(text: _formatDateOfBirth(profile?.dateOfBirth));
    _bioController = TextEditingController(text: profile?.bio ?? '');
  }

  String _formatDateOfBirth(String? dob) {
    if (dob == null || dob.isEmpty) return '';
    try {
      final date = DateTime.parse(dob);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return dob;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _toggleEdit(String fieldKey) {
    setState(() {
      _editableFields[fieldKey] = !(_editableFields[fieldKey] ?? false);
    });
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked != null && mounted) {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E1E1E)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Uploading...'),
                ],
              ),
            ),
          ),
        ),
      );

      final provider =
          Provider.of<UserProfileProvider>(context, listen: false);
      final success = await provider.uploadProfilePicture(picked.path);

      if (mounted) {
        Navigator.pop(context); // close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Profile picture updated!'
                : provider.error ?? 'Failed to upload picture'),
            backgroundColor: success ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    // Build update data from changed fields
    final profile =
        Provider.of<UserProfileProvider>(context, listen: false).profile;

    final Map<String, dynamic> updateData = {};

    // Parse fullName back to firstName + lastName
    final fullNameParts = _fullNameController.text.trim().split(' ');
    final newFirstName = fullNameParts.first;
    final newLastName =
        fullNameParts.length > 1 ? fullNameParts.sublist(1).join(' ') : '';

    if (newFirstName != (profile?.firstName ?? '')) {
      updateData['firstName'] = newFirstName;
    }
    if (newLastName != (profile?.lastName ?? '')) {
      updateData['lastName'] = newLastName;
    }
    if (_usernameController.text.trim() != (profile?.username ?? '')) {
      updateData['username'] = _usernameController.text.trim();
    }
    if (_phoneController.text.trim() != (profile?.phoneNumber ?? '')) {
      updateData['phoneNumber'] = _phoneController.text.trim();
    }
    if (_bioController.text.trim() != (profile?.bio ?? '')) {
      updateData['bio'] = _bioController.text.trim();
    }

    // Parse date back to ISO format for API
    if (_dobController.text.trim().isNotEmpty) {
      final parts = _dobController.text.trim().split('/');
      if (parts.length == 3) {
        final isoDate = '${parts[2]}-${parts[1]}-${parts[0]}';
        if (isoDate != (profile?.dateOfBirth ?? '')) {
          updateData['dateOfBirth'] = isoDate;
        }
      }
    }

    if (updateData.isEmpty) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No changes to save'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final provider =
        Provider.of<UserProfileProvider>(context, listen: false);
    final success = await provider.updateMyProfile(updateData);

    if (mounted) {
      setState(() {
        _isSaving = false;
        // Reset all fields to readonly after save
        _editableFields.updateAll((key, value) => false);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Profile updated successfully!'
              : provider.error ?? 'Failed to update profile'),
          backgroundColor: success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
          icon: Icon(Icons.arrow_back,
              color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Personal Information',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer<UserProfileProvider>(
        builder: (context, provider, _) {
          final profile = provider.profile;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // ===== AVATAR SECTION =====
                  const SizedBox(height: 8),
                  _buildAvatarSection(profile, isDark),
                  const SizedBox(height: 32),

                  // ===== FORM FIELDS =====
                  _buildEditableField(
                    fieldKey: 'fullName',
                    controller: _fullNameController,
                    label: 'Full Name',
                    icon: Icons.person_outline,
                    isDark: isDark,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Full name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildEditableField(
                    fieldKey: 'username',
                    controller: _usernameController,
                    label: 'Username',
                    icon: Icons.alternate_email,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),

                  _buildEditableField(
                    fieldKey: 'email',
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    isDark: isDark,
                    keyboardType: TextInputType.emailAddress,
                    // Email typically shouldn't be editable
                    alwaysReadOnly: true,
                  ),
                  const SizedBox(height: 16),

                  _buildEditableField(
                    fieldKey: 'phone',
                    controller: _phoneController,
                    label: 'Phone',
                    icon: Icons.phone_outlined,
                    isDark: isDark,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),

                  _buildEditableField(
                    fieldKey: 'dob',
                    controller: _dobController,
                    label: 'Date of Birth',
                    icon: Icons.cake_outlined,
                    isDark: isDark,
                    hintText: 'DD/MM/YYYY',
                    keyboardType: TextInputType.datetime,
                  ),
                  const SizedBox(height: 16),

                  _buildEditableField(
                    fieldKey: 'bio',
                    controller: _bioController,
                    label: 'Bio',
                    icon: Icons.info_outline,
                    isDark: isDark,
                    maxLines: 3,
                    hintText: 'Tell something about yourself...',
                  ),
                  const SizedBox(height: 40),

                  // ===== SAVE BUTTON =====
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1877F2),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor:
                            const Color(0xFF1877F2).withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save_rounded, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ===== AVATAR WIDGET =====
  Widget _buildAvatarSection(dynamic profile, bool isDark) {
    final avatarUrl = profile?.profilePictureUrl;
    final initials = profile?.initials ?? 'U';

    return Center(
      child: Stack(
        children: [
          // Circle Avatar
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF1877F2), Color(0xFF42A5F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1877F2).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.transparent,
              backgroundImage:
                  avatarUrl != null && avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : null,
              child: avatarUrl == null || avatarUrl.isEmpty
                  ? Text(
                      initials,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
          ),

          // Camera button overlay
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickProfileImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1877F2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? const Color(0xFF0F0F10) : Colors.white,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== EDITABLE FIELD WIDGET =====
  Widget _buildEditableField({
    required String fieldKey,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    String? hintText,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool alwaysReadOnly = false,
    String? Function(String?)? validator,
  }) {
    final isEditable = _editableFields[fieldKey] ?? false;
    final isReadOnly = alwaysReadOnly || !isEditable;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.slate400 : AppTheme.slate500,
              letterSpacing: 0.3,
            ),
          ),
        ),

        // Input field
        TextFormField(
          controller: controller,
          readOnly: isReadOnly,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(
            fontSize: 15,
            color: isDark ? Colors.white : AppTheme.slate900,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark
                ? (isEditable
                    ? AppTheme.slate800
                    : AppTheme.slate800.withOpacity(0.5))
                : (isEditable
                    ? Colors.white
                    : AppTheme.slate100),
            hintText: hintText,
            hintStyle: TextStyle(
              color: isDark ? AppTheme.slate600 : AppTheme.slate400,
              fontSize: 15,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, right: 12),
              child: Icon(
                icon,
                size: 20,
                color: isEditable
                    ? const Color(0xFF1877F2)
                    : (isDark ? AppTheme.slate500 : AppTheme.slate400),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 48,
              minHeight: 48,
            ),
            suffixIcon: alwaysReadOnly
                ? Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.lock_outline,
                      size: 18,
                      color: isDark ? AppTheme.slate600 : AppTheme.slate400,
                    ),
                  )
                : IconButton(
                    icon: Icon(
                      isEditable
                          ? Icons.check_circle_rounded
                          : Icons.edit_rounded,
                      size: 20,
                      color: isEditable
                          ? Colors.green
                          : (isDark
                              ? AppTheme.slate500
                              : AppTheme.slate400),
                    ),
                    onPressed: () => _toggleEdit(fieldKey),
                  ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: isEditable
                  ? const BorderSide(
                      color: Color(0xFF1877F2), width: 1.5)
                  : BorderSide(
                      color: isDark
                          ? AppTheme.slate700.withOpacity(0.5)
                          : AppTheme.slate200,
                      width: 1,
                    ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFF1877F2), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Colors.redAccent, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Colors.redAccent, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
