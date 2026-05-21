import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/storyProvider.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  File? _selectedFile;
  bool _isVideo = false;
  bool _isUploading = false;
  final _picker = ImagePicker();

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        _selectedFile = File(picked.path);
        _isVideo = false;
      });
    }
  }

  Future<void> _pickVideo() async {
    final picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedFile = File(picked.path);
        _isVideo = true;
      });
    }
  }

  Future<void> _captureImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        _selectedFile = File(picked.path);
        _isVideo = false;
      });
    }
  }

  Future<void> _captureVideo() async {
    final picked = await _picker.pickVideo(source: ImageSource.camera);
    if (picked != null) {
      setState(() {
        _selectedFile = File(picked.path);
        _isVideo = true;
      });
    }
  }

  Future<void> _uploadStory() async {
    if (_selectedFile == null || _isUploading) return;

    setState(() => _isUploading = true);

    try {
      final provider = context.read<StoryProvider>();
      final story = _isVideo
          ? await provider.createVideoStory(_selectedFile!)
          : await provider.createImageStory(_selectedFile!);

      if (!mounted) return;

      if (story != null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Story đã được đăng!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể đăng story. Vui lòng thử lại.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _selectedFile == null
            ? _buildPicker()
            : _buildPreview(),
      ),
    );
  }

  Widget _buildPicker() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              const Text(
                'Tạo Story',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_stories, color: Colors.white38, size: 80),
                const SizedBox(height: 24),
                const Text(
                  'Chọn ảnh hoặc video\nđể tạo story của bạn',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 48),
                Row(
                  children: [
                    Expanded(
                      child: _PickerButton(
                        icon: Icons.photo_library_rounded,
                        label: 'Thư viện\nẢnh',
                        onTap: _pickImage,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PickerButton(
                        icon: Icons.video_library_rounded,
                        label: 'Thư viện\nVideo',
                        onTap: _pickVideo,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _PickerButton(
                        icon: Icons.camera_alt_rounded,
                        label: 'Chụp\nẢnh',
                        onTap: _captureImage,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PickerButton(
                        icon: Icons.videocam_rounded,
                        label: 'Quay\nVideo',
                        onTap: _captureVideo,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Preview
        _isVideo
            ? Container(
                color: Colors.black,
                child: const Center(
                  child: Icon(
                    Icons.play_circle_fill,
                    color: Colors.white54,
                    size: 80,
                  ),
                ),
              )
            : Image.file(_selectedFile!, fit: BoxFit.cover),

        // Gradient
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x99000000), Colors.transparent, Color(0x88000000)],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),

        // Top bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _selectedFile = null),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                  ),
                ),
                const Spacer(),
                if (_isVideo)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.videocam, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text('VIDEO', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Bottom: Post button
        Positioned(
          bottom: 24,
          left: 24,
          right: 24,
          child: _isUploading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : GestureDetector(
                  onTap: _uploadStory,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF8B5CF6),
                          Color(0xFFEC4899),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'Đăng Story',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _PickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.violetPrimary, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
