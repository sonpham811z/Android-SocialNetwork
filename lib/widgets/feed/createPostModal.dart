import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/authProvider.dart';
import '../../providers/postProvider.dart';
import '../../providers/userProfileProvider.dart';

// Visibility options matching PostVisibility enum in backend (Public=0, Friends=1, Private=2)
class _VisibilityOption {
  final String value;
  final String label;
  final String description;
  final IconData icon;
  final Color color;

  const _VisibilityOption({
    required this.value,
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
  });
}

const _visibilityOptions = [
  _VisibilityOption(
    value: 'Public',
    label: 'Công khai',
    description: 'Tất cả mọi người đều có thể xem',
    icon: Icons.public,
    color: Color(0xFF2D88FF),
  ),
  _VisibilityOption(
    value: 'Friends',
    label: 'Bạn bè',
    description: 'Chỉ bạn bè của bạn mới thấy',
    icon: Icons.people,
    color: Color(0xFF44BCA4),
  ),
  _VisibilityOption(
    value: 'Private',
    label: 'Chỉ mình tôi',
    description: 'Chỉ bạn mới có thể xem',
    icon: Icons.lock,
    color: Color(0xFFB0B3B8),
  ),
];

_VisibilityOption _optionOf(String value) =>
    _visibilityOptions.firstWhere((o) => o.value == value,
        orElse: () => _visibilityOptions.first);

class CreatePostModal extends StatefulWidget {
  final VoidCallback onClose;

  const CreatePostModal({
    super.key,
    required this.onClose,
  });

  @override
  State<CreatePostModal> createState() => _CreatePostModalState();
}

class _CreatePostModalState extends State<CreatePostModal> {
  final _textController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  String? _pickedImagePath;
  String? _pickedAudioPath;
  String _visibility = 'Public';

  Future<void> _submitPost() async {
    final content = _textController.text.trim();
    if (content.isEmpty) return;

    final postProvider = context.read<PostProvider>();
    final bool success;
    if (_pickedImagePath != null) {
      success = await postProvider.createImagePost(
        content: content,
        imagePath: _pickedImagePath!,
        visibility: _visibility,
      );
    } else if (_pickedAudioPath != null) {
      success = await postProvider.createVoicePost(
        content: content,
        audioPath: _pickedAudioPath!,
        visibility: _visibility,
      );
    } else {
      success = await postProvider.createTextPost(content, visibility: _visibility);
    }

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<PostProvider>().error ?? 'Đăng bài thất bại.')),
      );
      return;
    }

    _textController.clear();
    _pickedImagePath = null;
    _pickedAudioPath = null;
    widget.onClose();
  }

  Future<void> _pickImage() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null || !mounted) return;
    setState(() {
      _pickedImagePath = picked.path;
      _pickedAudioPath = null;
    });
  }

  Future<void> _pickAudio() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg'],
    );
    if (picked == null || picked.files.single.path == null || !mounted) return;
    setState(() {
      _pickedAudioPath = picked.files.single.path!;
      _pickedImagePath = null;
    });
  }

  Future<void> _showVisibilityPicker(bool isDark) async {
    final selected = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => _VisibilityPickerDialog(
        current: _visibility,
        isDark: isDark,
      ),
    );
    if (selected != null && mounted) {
      setState(() => _visibility = selected);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = context.watch<UserProfileProvider>().profile;
    final postProvider = context.watch<PostProvider>();
    final displayName = profile?.displayName ?? auth.user?.fullName ?? 'Bạn';
    final avatarUrl = profile?.avatar ?? '';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final modalBg = isDark ? const Color(0xFF18181B) : Colors.white;
    final borderColor = isDark ? AppTheme.slate800 : AppTheme.slate200;
    final textColor = colorScheme.onSurface;
    final subtleTextColor = isDark ? AppTheme.slate400 : AppTheme.slate500;
    final hintColor = isDark ? AppTheme.slate600 : AppTheme.slate400;
    final chipBg = isDark ? AppTheme.slate800 : AppTheme.slate100;

    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black.withOpacity(0.8),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.all(16),
              constraints: const BoxConstraints(maxWidth: 512),
              decoration: BoxDecoration(
                color: modalBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(textColor: textColor, subtleTextColor: subtleTextColor, borderColor: borderColor),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildUserInfo(
                              displayName,
                              avatarUrl,
                              textColor: textColor,
                              subtleTextColor: subtleTextColor,
                              chipBg: chipBg,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 16),
                            _buildTextInput(textColor: textColor, hintColor: hintColor),
                            const SizedBox(height: 16),
                            if (_pickedImagePath != null || _pickedAudioPath != null) ...[
                              _buildPickedMediaPreview(isDark: isDark),
                              const SizedBox(height: 12),
                            ],
                            _buildAttachmentOptions(subtleTextColor: subtleTextColor, borderColor: borderColor),
                            const SizedBox(height: 20),
                            _buildPostButton(postProvider.isSubmitting, isDark: isDark),
                          ],
                        ),
                      ),
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

  Widget _buildHeader({
    required Color textColor,
    required Color subtleTextColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          Text(
            'Tạo bài viết',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
          ),
          const Spacer(),
          GestureDetector(
            onTap: widget.onClose,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: borderColor.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, size: 20, color: subtleTextColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(
    String displayName,
    String avatarUrl, {
    required Color textColor,
    required Color subtleTextColor,
    required Color chipBg,
    required bool isDark,
  }) {
    final option = _optionOf(_visibility);

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: chipBg)),
          child: ClipOval(
            child: Image.network(
              avatarUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: chipBg,
                child: Icon(Icons.person, color: textColor),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayName,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 4),
            // Visibility chip — tap to change
            GestureDetector(
              onTap: () => _showVisibilityPicker(isDark),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: option.color.withValues(alpha: isDark ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: option.color.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(option.icon, size: 11, color: option.color),
                    const SizedBox(width: 4),
                    Text(
                      option.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: option.color,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 13, color: option.color),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextInput({required Color textColor, required Color hintColor}) {
    return TextField(
      controller: _textController,
      maxLines: null,
      minLines: 5,
      autofocus: true,
      style: TextStyle(color: textColor, fontSize: 18),
      decoration: InputDecoration(
        hintText: 'Bạn đang nghĩ gì thế?',
        hintStyle: TextStyle(color: hintColor, fontSize: 18),
        border: InputBorder.none,
        filled: false,
      ),
    );
  }

  Widget _buildAttachmentOptions({required Color subtleTextColor, required Color borderColor}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            'Thêm vào bài viết',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: subtleTextColor),
          ),
          const Spacer(),
          _buildAttachmentButton(Icons.image, Colors.green, onTap: _pickImage),
          _buildAttachmentButton(Icons.mic, Colors.deepPurpleAccent, onTap: _pickAudio),
          _buildAttachmentButton(Icons.people, Colors.blue),
          _buildAttachmentButton(Icons.emoji_emotions, Colors.yellow),
          _buildAttachmentButton(Icons.location_on, Colors.red),
        ],
      ),
    );
  }

  Widget _buildPickedMediaPreview({required bool isDark}) {
    final label = _pickedImagePath != null ? 'Đã chọn ảnh' : 'Đã chọn audio';
    final icon = _pickedImagePath != null ? Icons.image_outlined : Icons.audio_file_outlined;
    final previewBg = isDark ? AppTheme.slate800.withOpacity(0.6) : AppTheme.slate100;
    final previewBorder = isDark ? AppTheme.slate700 : AppTheme.slate200;
    final previewIconColor = isDark ? Colors.white70 : AppTheme.slate500;
    final previewTextColor = isDark ? Colors.white : AppTheme.slate900;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: previewBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: previewBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: previewIconColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: TextStyle(color: previewTextColor, fontSize: 13)),
          ),
          IconButton(
            onPressed: () => setState(() {
              _pickedImagePath = null;
              _pickedAudioPath = null;
            }),
            icon: Icon(Icons.close, size: 16, color: previewIconColor),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentButton(IconData icon, Color color, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: SizedBox(
        width: 32,
        height: 32,
        child: IconButton(
          icon: Icon(icon, size: 20, color: color),
          padding: EdgeInsets.zero,
          onPressed: onTap ?? () {},
        ),
      ),
    );
  }

  Widget _buildPostButton(bool isSubmitting, {required bool isDark}) {
    final btnBg = isDark ? Colors.white : AppTheme.violetPrimary;
    final btnFg = isDark ? Colors.black : Colors.white;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isSubmitting ? null : _submitPost,
        style: ElevatedButton.styleFrom(
          backgroundColor: btnBg,
          foregroundColor: btnFg,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: isSubmitting
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: btnFg),
              )
            : const Text('Đăng bài', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ── Visibility Picker Dialog ──────────────────────────────────────────────────

class _VisibilityPickerDialog extends StatelessWidget {
  final String current;
  final bool isDark;

  const _VisibilityPickerDialog({required this.current, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF242526) : Colors.white;
    final titleColor = isDark ? Colors.white : AppTheme.slate900;
    final borderColor = isDark ? AppTheme.slate700 : AppTheme.slate200;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ai có thể xem bài viết?',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Chọn đối tượng bạn muốn chia sẻ',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppTheme.slate400 : AppTheme.slate500,
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: borderColor, height: 1),
            const SizedBox(height: 8),
            ...(_visibilityOptions.map(
              (option) => _VisibilityOptionTile(
                option: option,
                isSelected: current == option.value,
                isDark: isDark,
                onTap: () => Navigator.of(context).pop(option.value),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _VisibilityOptionTile extends StatelessWidget {
  final _VisibilityOption option;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _VisibilityOptionTile({
    required this.option,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final descColor = isDark ? AppTheme.slate400 : AppTheme.slate500;
    final labelColor = isDark ? Colors.white : AppTheme.slate900;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? option.color.withValues(alpha: isDark ? 0.15 : 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? option.color.withValues(alpha: 0.5) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: option.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(option.icon, color: option.color, size: 20),
            ),
            const SizedBox(width: 12),
            // Labels
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? option.color : labelColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.description,
                    style: TextStyle(fontSize: 12, color: descColor),
                  ),
                ],
              ),
            ),
            // Checkmark
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: option.color, size: 22)
            else
              const SizedBox(width: 22),
          ],
        ),
      ),
    );
  }
}
