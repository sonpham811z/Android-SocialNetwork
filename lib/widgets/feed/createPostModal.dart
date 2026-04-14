import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/authProvider.dart';
import '../../providers/postProvider.dart';
import '../../providers/userProfileProvider.dart';

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

  Future<void> _submitPost() async {
    final content = _textController.text.trim();
    if (content.isEmpty) {
      return;
    }

    final postProvider = context.read<PostProvider>();
    final success = _pickedImagePath != null
        ? await postProvider.createImagePost(content: content, imagePath: _pickedImagePath!)
        : (_pickedAudioPath != null
            ? await postProvider.createVoicePost(content: content, audioPath: _pickedAudioPath!)
            : await postProvider.createTextPost(content));
    if (!mounted) {
      return;
    }

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
    if (picked == null || !mounted) {
      return;
    }
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
    if (picked == null || picked.files.single.path == null || !mounted) {
      return;
    }
    setState(() {
      _pickedAudioPath = picked.files.single.path!;
      _pickedImagePath = null;
    });
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

    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black.withOpacity(0.8),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping modal
            child: Container(
              margin: const EdgeInsets.all(16),
              constraints: const BoxConstraints(maxWidth: 512),
              decoration: BoxDecoration(
                color: const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.slate800),
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
                  // Header
                  _buildHeader(),

                  // Content
                  Flexible(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildUserInfo(displayName, avatarUrl),
                            const SizedBox(height: 16),
                            _buildTextInput(),
                            const SizedBox(height: 16),
                            if (_pickedImagePath != null || _pickedAudioPath != null) ...[
                              _buildPickedMediaPreview(),
                              const SizedBox(height: 12),
                            ],
                            _buildAttachmentOptions(),
                            const SizedBox(height: 20),
                            _buildPostButton(postProvider.isSubmitting),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.slate800),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'Tạo bài viết',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: widget.onClose,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.slate800.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: 20,
                color: AppTheme.slate400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(String displayName, String avatarUrl) {
    return Row(
      children: [
        // Avatar
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.slate800),
          ),
          child: ClipOval(
            child: Image.network(
              avatarUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppTheme.slate800,
                  child: const Icon(Icons.person, color: Colors.white),
                );
              },
            ),
          ),
        ),

        const SizedBox(width: 12),

        // User name and visibility
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.slate800,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.public,
                    size: 10,
                    color: AppTheme.slate400,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Công khai',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.slate400,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.unfold_more,
                    size: 10,
                    color: AppTheme.slate400,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextInput() {
    return TextField(
      controller: _textController,
      maxLines: null,
      minLines: 5,
      autofocus: true,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
      ),
      decoration: InputDecoration(
        hintText: 'Bạn đang nghĩ gì thế?',
        hintStyle: TextStyle(
          color: AppTheme.slate600,
          fontSize: 18,
        ),
        border: InputBorder.none,
      ),
    );
  }

  Widget _buildAttachmentOptions() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.slate800),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            'Thêm vào bài viết',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.slate300,
            ),
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

  Widget _buildPickedMediaPreview() {
    final label = _pickedImagePath != null ? 'Đã chọn ảnh' : 'Đã chọn audio';
    final icon = _pickedImagePath != null ? Icons.image_outlined : Icons.audio_file_outlined;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.slate800.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.slate700),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _pickedImagePath = null;
                _pickedAudioPath = null;
              });
            },
            icon: const Icon(Icons.close, size: 16, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentButton(IconData icon, Color color, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(icon, size: 20, color: color),
          padding: EdgeInsets.zero,
          onPressed: onTap ?? () {},
        ),
      ),
    );
  }

  Widget _buildPostButton(bool isSubmitting) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isSubmitting ? null : _submitPost,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text(
                'Đăng bài',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}