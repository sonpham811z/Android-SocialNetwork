import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/friendModel.dart';
import '../../providers/authProvider.dart';
import '../../providers/conversationProvider.dart';
import '../../services/FriendService.dart';
import 'groupChatScreen.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _friendService = FriendService();

  List<FriendshipModel> _friends = [];
  final Set<String> _selectedIds = {};
  bool _isLoadingFriends = true;
  bool _isCreating = false;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    try {
      final result = await _friendService.getMyFriends(pageSize: 100);
      if (mounted) {
        setState(() {
          _friends = result.data?.items ?? [];
          _isLoadingFriends = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingFriends = false);
    }
  }

  Future<void> _createGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Vui lòng nhập tên nhóm');
      return;
    }
    if (_selectedIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chọn ít nhất 2 người để tạo nhóm')),
      );
      return;
    }

    setState(() {
      _isCreating = true;
      _nameError = null;
    });

    try {
      final currentUserId = context.read<AuthProvider>().user?.id ?? '';
      final memberIds = [
        ..._selectedIds.where((id) => id != currentUserId),
      ];

      final conv = await context
          .read<ConversationProvider>()
          .createGroup(name, memberIds);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => GroupChatScreen(
              conversationId: conv.id,
              groupName: conv.groupName ?? name,
              memberIds: conv.members,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tạo nhóm thất bại: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final scaffoldBg = isDark ? const Color(0xFF0F0F10) : Theme.of(context).scaffoldBackgroundColor;
    final inputBg = isDark ? AppTheme.slate800 : AppTheme.slate100;
    final dividerColor = isDark ? Colors.white12 : AppTheme.slate200;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F0F10) : Colors.white,
        elevation: 1,
        shadowColor: isDark ? Colors.white10 : Colors.black12,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tạo nhóm chat',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _isCreating ? null : _createGroup,
            child: _isCreating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.violetPrimary),
                  )
                : const Text(
                    'Tạo',
                    style: TextStyle(
                      color: AppTheme.violetPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group name input
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: TextField(
              controller: _nameController,
              style: TextStyle(color: textColor),
              textCapitalization: TextCapitalization.words,
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
              decoration: InputDecoration(
                hintText: 'Tên nhóm...',
                hintStyle: TextStyle(
                    color: isDark ? Colors.grey : AppTheme.slate400),
                prefixIcon: const Icon(Icons.group, color: AppTheme.violetPrimary),
                filled: true,
                fillColor: inputBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                errorText: _nameError,
              ),
            ),
          ),

          // Selected count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Thành viên: ${_selectedIds.length} đã chọn',
              style: TextStyle(
                color: AppTheme.violetPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),

          Divider(color: dividerColor, height: 1),

          // Friends list
          Expanded(
            child: _isLoadingFriends
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.violetPrimary),
                  )
                : _friends.isEmpty
                    ? Center(
                        child: Text(
                          'Bạn chưa có bạn bè nào.',
                          style: TextStyle(color: AppTheme.slate500),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _friends.length,
                        itemBuilder: (context, index) =>
                            _buildFriendTile(_friends[index], isDark, textColor),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendTile(
      FriendshipModel friendship, bool isDark, Color textColor) {
    final friend = friendship.friend;
    final isSelected = _selectedIds.contains(friend.id);
    final avatarBg = isDark ? AppTheme.slate800 : AppTheme.slate200;

    return ListTile(
      onTap: () => setState(() {
        if (isSelected) {
          _selectedIds.remove(friend.id);
        } else {
          _selectedIds.add(friend.id);
        }
      }),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: avatarBg,
        backgroundImage:
            friend.avatarUrl != null ? NetworkImage(friend.avatarUrl!) : null,
        child: friend.avatarUrl == null
            ? Text(
                friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?',
                style: TextStyle(
                    color: textColor, fontWeight: FontWeight.bold),
              )
            : null,
      ),
      title: Text(
        friend.name,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '@${friend.userName}',
        style: TextStyle(
            color: isDark ? Colors.grey : AppTheme.slate500, fontSize: 12),
      ),
      trailing: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? AppTheme.violetPrimary : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? AppTheme.violetPrimary
                : (isDark ? Colors.white38 : AppTheme.slate300),
            width: 2,
          ),
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : null,
      ),
    );
  }
}
