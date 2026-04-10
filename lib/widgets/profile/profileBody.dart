import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/feedModel.dart';
import '../../models/userModel.dart';
import '../../providers/authProvider.dart';
import '../../providers/userProfileProvider.dart';
import '../feed/postCard.dart';
import '../../screens/settings/settingsScreen.dart';

class ProfileBody extends StatefulWidget {
  const ProfileBody({super.key});

  @override
  State<ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<ProfileBody> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this)
      ..addListener(() {
        if (mounted) {
          setState(() {});
        }
      });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<UserProfileProvider>().loadMyProfile();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final myPosts = MockData.posts;

    return Consumer<UserProfileProvider>(
      builder: (context, profileProvider, _) {
        final profile = profileProvider.profile;

        if (profileProvider.isLoading && profile == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (profileProvider.error != null && profile == null) {
          return _buildErrorState(profileProvider.error!);
        }

        if (profile == null) {
          return _buildErrorState('Khong tim thay thong tin profile.');
        }

        return RefreshIndicator(
          onRefresh: () => profileProvider.loadMyProfile(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _buildProfileHeader(profile, isDark),
              ),
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    controller: _tabController,
                    indicatorColor: isDark ? Colors.white : AppTheme.violetPrimary,
                    labelColor: isDark ? Colors.white : AppTheme.slate900,
                    unselectedLabelColor: AppTheme.slate500,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    dividerColor: isDark ? AppTheme.slate800 : AppTheme.slate200,
                    tabs: const [
                      Tab(icon: Icon(Icons.grid_on_rounded), text: 'Posts'),
                      Tab(icon: Icon(Icons.badge_outlined), text: 'About'),
                      Tab(icon: Icon(Icons.groups_rounded), text: 'Connections'),
                    ],
                  ),
                  isDark,
                ),
                pinned: true,
              ),
              SliverPadding(
                padding: const EdgeInsets.only(top: 16, bottom: 100),
                sliver: _buildTabContent(
                  profile: profile,
                  isDark: isDark,
                  myPosts: myPosts,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(User profile, bool isDark) {
    final surfaceColor = isDark ? const Color(0xFF0F0F10) : Colors.white;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomLeft,
          children: [
            _buildCover(profile.coverPhotoUrl),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.68)],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              left: 20,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  shape: BoxShape.circle,
                ),
                child: _buildAvatar(profile, radius: 40),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildActionButton(
                    isDark,
                    Icons.edit,
                    'Edit Profile',
                    onTap: () {
                      _openEditProfileSheet(profile);
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildIconOnlyButton(isDark, Icons.share_outlined, onTap: () {}),
                  const SizedBox(width: 8),
                  _buildIconOnlyButton(
                    isDark,
                    Icons.settings_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Text(
                    profile.displayName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  if (profile.isVerified) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.verified, color: Colors.blue, size: 20),
                  ],
                ],
              ),
              if ((profile.username ?? '').isNotEmpty)
                Text(
                  '@${profile.username}',
                  style: TextStyle(color: AppTheme.slate500, fontSize: 14),
                ),

              const SizedBox(height: 12),

              Text(
                (profile.bio ?? '').trim().isEmpty
                    ? 'Cap nhat bio cua ban de nguoi khac hieu ban hon.'
                    : profile.bio!,
                style: TextStyle(
                  color: isDark ? Colors.white.withOpacity(0.9) : AppTheme.slate800,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppTheme.slate500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _buildLocation(profile),
                    style: TextStyle(color: AppTheme.slate500, fontSize: 13),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.calendar_month_outlined, size: 16, color: AppTheme.slate500),
                  const SizedBox(width: 4),
                  Text(
                    _formatJoined(profile.createdAt),
                    style: TextStyle(color: AppTheme.slate500, fontSize: 13),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildChip(
                    icon: profile.isPrivate ? Icons.lock_outline : Icons.public,
                    label: profile.isPrivate ? 'Private profile' : 'Public profile',
                    isDark: isDark,
                  ),
                  if ((profile.gender ?? '').isNotEmpty)
                    _buildChip(
                      icon: Icons.person_outline,
                      label: profile.gender!,
                      isDark: isDark,
                    ),
                  if (_formatDate(profile.dateOfBirth) != null)
                    _buildChip(
                      icon: Icons.cake_outlined,
                      label: _formatDate(profile.dateOfBirth)!,
                      isDark: isDark,
                    ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  _buildStatItem(isDark, '${profile.postsCount}', 'Posts'),
                  const SizedBox(width: 24),
                  _buildStatItem(isDark, '${profile.followersCount}', 'Followers'),
                  const SizedBox(width: 24),
                  _buildStatItem(isDark, '${profile.followingCount}', 'Following'),
                  const SizedBox(width: 24),
                  _buildStatItem(isDark, '${profile.friendsCount}', 'Friends'),
                ],
              ),

              const SizedBox(height: 12),
              Consumer<UserProfileProvider>(
                builder: (context, provider, _) {
                  if (!provider.useMockData) {
                    return const SizedBox.shrink();
                  }

                  return _buildChip(
                    icon: Icons.science_outlined,
                    label: 'Preview mode: Mock data',
                    isDark: isDark,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCover(String? coverUrl) {
    final hasCover = (coverUrl ?? '').trim().isNotEmpty;
    if (!hasCover) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A4B78), Color(0xFF3D8BC4), Color(0xFF72B2D7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );
    }

    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Image.network(
        coverUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A4B78), Color(0xFF3D8BC4), Color(0xFF72B2D7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatar(User profile, {double radius = 40}) {
    final imageUrl = (profile.profilePictureUrl ?? '').trim();

    if (imageUrl.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppTheme.violetPrimary.withOpacity(0.18),
        child: Text(
          profile.initials,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: radius * 0.45,
            color: Colors.white,
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundImage: NetworkImage(imageUrl),
      onBackgroundImageError: (_, __) {},
      child: const SizedBox.shrink(),
    );
  }

  String _buildLocation(User profile) {
    final parts = [profile.location, profile.city, profile.country]
        .where((value) => (value ?? '').trim().isNotEmpty)
        .cast<String>()
        .toList();
    if (parts.isEmpty) {
      return 'No location';
    }
    return parts.join(', ');
  }

  String _formatJoined(String? dateValue) {
    final date = DateTime.tryParse(dateValue ?? '');
    if (date == null) {
      return 'Joined recently';
    }
    return 'Joined ${DateFormat('MMM yyyy').format(date)}';
  }

  String? _formatDate(String? dateValue) {
    final date = DateTime.tryParse(dateValue ?? '');
    if (date == null) {
      return null;
    }
    return DateFormat('dd/MM/yyyy').format(date);
  }

  SliverList _buildTabContent({
    required User profile,
    required bool isDark,
    required List<Post> myPosts,
  }) {
    if (_tabController.index == 0) {
      if (myPosts.isEmpty) {
        return SliverList(
          delegate: SliverChildListDelegate([
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.slate800 : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppTheme.slate700 : AppTheme.slate200),
                ),
                child: Text(
                  'Ban chua co bai viet nao.',
                  style: TextStyle(color: isDark ? Colors.white70 : AppTheme.slate700),
                ),
              ),
            ),
          ]),
        );
      }

      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: PostCard(
                post: myPosts[index % myPosts.length],
                onToggleComments: () {},
              ),
            );
          },
          childCount: myPosts.length,
        ),
      );
    }

    if (_tabController.index == 1) {
      final details = <MapEntry<String, String>>[
        MapEntry('Email', profile.email),
        MapEntry('Username', (profile.username ?? '').isEmpty ? '-' : '@${profile.username}'),
        MapEntry('Phone', profile.phoneNumber ?? '-'),
        MapEntry('Website', profile.website ?? '-'),
        MapEntry('Date of birth', _formatDate(profile.dateOfBirth) ?? '-'),
        MapEntry('Age', profile.age?.toString() ?? '-'),
        MapEntry('Gender', profile.gender ?? '-'),
        MapEntry('Location', _buildLocation(profile)),
        MapEntry('Last active', _formatDateTime(profile.lastActiveAt) ?? '-'),
      ];

      return SliverList(
        delegate: SliverChildListDelegate([
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.slate800 : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? AppTheme.slate700 : AppTheme.slate200,
                ),
              ),
              child: Column(
                children: details
                    .map((entry) => _buildDetailRow(isDark, entry.key, entry.value))
                    .toList(),
              ),
            ),
          ),
        ]),
      );
    }

    return SliverList(
      delegate: SliverChildListDelegate([
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildMetricCard(isDark, 'Friends', profile.friendsCount, Icons.group_outlined),
              _buildMetricCard(
                isDark,
                'Followers',
                profile.followersCount,
                Icons.trending_up_rounded,
              ),
              _buildMetricCard(
                isDark,
                'Following',
                profile.followingCount,
                Icons.person_add_alt_1_rounded,
              ),
              _buildMetricCard(isDark, 'Posts', profile.postsCount, Icons.article_outlined),
            ],
          ),
        ),
      ]),
    );
  }

  String? _formatDateTime(String? dateValue) {
    final date = DateTime.tryParse(dateValue ?? '');
    if (date == null) {
      return null;
    }
    return DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());
  }

  Widget _buildErrorState(String message) {
    final normalizedError = message.toLowerCase();
    final shouldShowRelogin =
        normalizedError.contains('refresh token') ||
        normalizedError.contains('401') ||
        normalizedError.contains('unauthorized');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 32),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.read<UserProfileProvider>().loadMyProfile(),
              child: const Text('Thu lai'),
            ),
            if (shouldShowRelogin) ...[
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () async {
                  await context.read<AuthProvider>().logout();
                },
                child: const Text('Dang xuat de dang nhap lai'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.slate800 : AppTheme.slate100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.slate500),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: AppTheme.slate500, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(bool isDark, String title, String value) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppTheme.slate700 : AppTheme.slate200,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: AppTheme.slate500, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isDark ? Colors.white : AppTheme.slate900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(bool isDark, String label, int value, IconData icon) {
    return SizedBox(
      width: 160,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.slate800 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppTheme.slate700 : AppTheme.slate200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.violetPrimary),
            const SizedBox(height: 8),
            Text(
              '$value',
              style: TextStyle(
                color: isDark ? Colors.white : AppTheme.slate900,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              label,
              style: TextStyle(color: AppTheme.slate500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    bool isDark,
    IconData icon,
    String label, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.slate800 : AppTheme.slate200,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? AppTheme.slate700 : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isDark ? Colors.white : Colors.black),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconOnlyButton(bool isDark, IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.slate800 : AppTheme.slate200,
          shape: BoxShape.circle,
          border: Border.all(color: isDark ? AppTheme.slate700 : Colors.transparent),
        ),
        child: Icon(icon, size: 18, color: isDark ? Colors.white : Colors.black),
      ),
    );
  }

  Widget _buildStatItem(bool isDark, String value, String label) {
    return Row(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.slate500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Future<void> _openEditProfileSheet(User profile) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditProfileSheet(initialProfile: profile),
    );

    if (!mounted || updated != true) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cap nhat profile thanh cong.')),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  final User initialProfile;

  const _EditProfileSheet({required this.initialProfile});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _bioController;
  late final TextEditingController _genderController;
  late final TextEditingController _locationController;
  late final TextEditingController _cityController;
  late final TextEditingController _countryController;
  late final TextEditingController _websiteController;
  late final TextEditingController _phoneController;

  DateTime? _dateOfBirth;
  late bool _isPrivate;
  bool _isSubmitting = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile;
    _firstNameController = TextEditingController(text: profile.firstName);
    _lastNameController = TextEditingController(text: profile.lastName);
    _bioController = TextEditingController(text: profile.bio ?? '');
    _genderController = TextEditingController(text: profile.gender ?? '');
    _locationController = TextEditingController(text: profile.location ?? '');
    _cityController = TextEditingController(text: profile.city ?? '');
    _countryController = TextEditingController(text: profile.country ?? '');
    _websiteController = TextEditingController(text: profile.website ?? '');
    _phoneController = TextEditingController(text: profile.phoneNumber ?? '');

    _dateOfBirth = DateTime.tryParse(profile.dateOfBirth ?? '');
    _isPrivate = profile.isPrivate;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    _genderController.dispose();
    _locationController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _websiteController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141517) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.slate500,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Edit profile',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppTheme.slate900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPhotoActions(isDark),
                  const SizedBox(height: 14),
                  _buildTextField(
                    _firstNameController,
                    'First name',
                    isDark,
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'First name khong duoc de trong';
                      }
                      return null;
                    },
                  ),
                  _buildTextField(
                    _lastNameController,
                    'Last name',
                    isDark,
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Last name khong duoc de trong';
                      }
                      return null;
                    },
                  ),
                  _buildTextField(
                    _bioController,
                    'Bio',
                    isDark,
                    maxLines: 3,
                    maxLength: 500,
                  ),
                  _buildTextField(_genderController, 'Gender', isDark),
                  _buildTextField(_locationController, 'Location', isDark),
                  _buildTextField(_cityController, 'City', isDark),
                  _buildTextField(_countryController, 'Country', isDark),
                  _buildTextField(
                    _websiteController,
                    'Website',
                    isDark,
                    keyboardType: TextInputType.url,
                    validator: (value) {
                      final text = (value ?? '').trim();
                      if (text.isEmpty) {
                        return null;
                      }
                      final uri = Uri.tryParse(text);
                      if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
                        return 'Website phai bat dau bang http:// hoac https://';
                      }
                      return null;
                    },
                  ),
                  _buildTextField(
                    _phoneController,
                    'Phone number',
                    isDark,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 8),
                  _buildDatePicker(isDark),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    value: _isPrivate,
                    onChanged: (value) {
                      setState(() {
                        _isPrivate = value;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Private profile',
                      style: TextStyle(color: isDark ? Colors.white : AppTheme.slate900),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AppTheme.violetPrimary,
                        foregroundColor: Colors.white,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Save changes'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker(bool isDark) {
    final dateText = _dateOfBirth == null
        ? 'Chon ngay sinh'
        : DateFormat('dd/MM/yyyy').format(_dateOfBirth!);

    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Date of birth',
        filled: true,
        fillColor: isDark ? AppTheme.slate800 : AppTheme.slate100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  dateText,
                  style: TextStyle(color: isDark ? Colors.white : AppTheme.slate900),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: _pickDate,
            icon: Icon(Icons.calendar_month_outlined, color: AppTheme.slate500),
          ),
          if (_dateOfBirth != null)
            IconButton(
              onPressed: () {
                setState(() {
                  _dateOfBirth = null;
                });
              },
              icon: const Icon(Icons.clear),
              tooltip: 'Clear date',
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoActions(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isUploadingImage ? null : () => _pickAndUploadImage(isAvatar: true),
            icon: const Icon(Icons.account_circle_outlined),
            label: const Text('Avatar'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isUploadingImage ? null : () => _pickAndUploadImage(isAvatar: false),
            icon: const Icon(Icons.landscape_outlined),
            label: const Text('Cover'),
          ),
        ),
        if (_isUploadingImage) ...[
          const SizedBox(width: 10),
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: isDark ? Colors.white : AppTheme.slate900,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    bool isDark, {
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        keyboardType: keyboardType,
        validator: validator,
        style: TextStyle(color: isDark ? Colors.white : AppTheme.slate900),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: isDark ? AppTheme.slate800 : AppTheme.slate100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year, now.month, now.day),
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _dateOfBirth = selected;
    });
  }

  Future<void> _pickAndUploadImage({required bool isAvatar}) async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: isAvatar ? 800 : 1600,
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _isUploadingImage = true;
    });

    final provider = context.read<UserProfileProvider>();
    final success = isAvatar
        ? await provider.uploadProfilePicture(picked.path)
        : await provider.uploadCoverPhoto(picked.path);

    if (!mounted) {
      return;
    }

    setState(() {
      _isUploadingImage = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (isAvatar ? 'Da cap nhat avatar.' : 'Da cap nhat cover photo.')
              : (provider.error ?? 'Upload that bai.'),
        ),
        backgroundColor: success ? null : Colors.redAccent,
      ),
    );
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final payload = <String, dynamic>{};
    final profile = widget.initialProfile;

    void putIfChanged(String key, String nextValue, String oldValue) {
      final newText = nextValue.trim();
      final oldText = oldValue.trim();
      if (newText != oldText) {
        payload[key] = newText;
      }
    }

    putIfChanged('firstName', _firstNameController.text, profile.firstName);
    putIfChanged('lastName', _lastNameController.text, profile.lastName);
    putIfChanged('bio', _bioController.text, profile.bio ?? '');
    putIfChanged('gender', _genderController.text, profile.gender ?? '');
    putIfChanged('location', _locationController.text, profile.location ?? '');
    putIfChanged('city', _cityController.text, profile.city ?? '');
    putIfChanged('country', _countryController.text, profile.country ?? '');
    putIfChanged('website', _websiteController.text, profile.website ?? '');
    putIfChanged('phoneNumber', _phoneController.text, profile.phoneNumber ?? '');

    final oldDob = DateTime.tryParse(profile.dateOfBirth ?? '');
    final oldDobKey = oldDob == null ? '' : DateFormat('yyyy-MM-dd').format(oldDob);
    final newDobKey = _dateOfBirth == null ? '' : DateFormat('yyyy-MM-dd').format(_dateOfBirth!);
    if (newDobKey.isNotEmpty && newDobKey != oldDobKey) {
      payload['dateOfBirth'] = _dateOfBirth!.toIso8601String();
    } else if (oldDobKey.isNotEmpty && newDobKey.isEmpty) {
      payload['clearDateOfBirth'] = true;
    }

    if (_isPrivate != profile.isPrivate) {
      payload['isPrivate'] = _isPrivate;
    }

    if (payload.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Khong co thay doi nao de luu.')),
      );
      Navigator.pop(context, false);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final provider = context.read<UserProfileProvider>();
    final success = await provider.updateMyProfile(payload);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      Navigator.pop(context, true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(provider.error ?? 'Cap nhat profile that bai.'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  final bool isDark;

  _SliverAppBarDelegate(this._tabBar, this.isDark);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: isDark ? const Color(0xFF0F0F10) : Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}