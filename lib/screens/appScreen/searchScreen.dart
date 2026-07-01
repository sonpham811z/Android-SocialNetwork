import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/feedModel.dart';
import '../../providers/authProvider.dart';
import '../../providers/friendProvider.dart';
import '../../services/postService.dart';
import '../../services/userProfileService.dart';
import '../../widgets/feed/postCard.dart';
import 'userProfileScreen.dart';

/// Màn tìm kiếm gộp: tab "Mọi người" (user) + tab "Bài viết" (post & #hashtag).
class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  final int initialTabIndex;

  const SearchScreen({super.key, this.initialQuery, this.initialTabIndex = 0});

  static Future<void> open(
    BuildContext context, {
    String? initialQuery,
    int initialTabIndex = 0,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            SearchScreen(initialQuery: initialQuery, initialTabIndex: initialTabIndex),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 180),
      ),
    );
  }

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _userProfileService = UserProfileService();
  final _postService = PostService();
  late final TabController _tabController;
  Timer? _debounce;

  List<UserSearchResult> _users = [];
  List<Post> _posts = [];
  bool _loadingUsers = false;
  bool _loadingPosts = false;
  String? _error;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
    _controller.addListener(_onTextChanged);

    final initial = widget.initialQuery?.trim() ?? '';
    if (initial.isNotEmpty) {
      _controller.text = initial;
      WidgetsBinding.instance.addPostFrameCallback((_) => _search(initial));
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _debounce?.cancel();
    final q = _controller.text.trim();
    if (q == _lastQuery) return;
    if (q.isEmpty) {
      setState(() {
        _users = [];
        _posts = [];
        _error = null;
        _lastQuery = '';
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(q));
  }

  Future<void> _search(String q) async {
    if (!mounted) return;
    setState(() {
      _loadingUsers = true;
      _loadingPosts = true;
      _error = null;
      _lastQuery = q;
    });

    // Tìm user + bài viết song song.
    final results = await Future.wait([
      _userProfileService
          .searchUsersByUsername(q.replaceFirst('@', ''), pageSize: 20)
          .then<Object>((v) => v)
          .catchError((_) => 'error'),
      _postService
          .searchPosts(q, pageSize: 20)
          .then<Object>((v) => v)
          .catchError((_) => 'error'),
    ]);

    if (!mounted) return;
    setState(() {
      final userRes = results[0];
      final postRes = results[1];
      _users = userRes is List<UserSearchResult> ? userRes : [];
      _posts = postRes is PostListResult ? postRes.posts : [];
      _loadingUsers = false;
      _loadingPosts = false;
      if (userRes == 'error' && postRes == 'error') {
        _error = 'Không thể tìm kiếm.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F0F10) : AppTheme.slate50;
    final barBg = isDark ? const Color(0xFF18181B) : Colors.white;
    final inputBg = isDark ? const Color(0xFF27272A) : AppTheme.slate100;
    final hintColor = isDark ? AppTheme.slate500 : AppTheme.slate400;
    final textColor = isDark ? Colors.white : AppTheme.slate900;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: barBg,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: inputBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) {
                      _debounce?.cancel();
                      final q = _controller.text.trim();
                      if (q.isNotEmpty) _search(q);
                    },
                    style: TextStyle(color: textColor, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Tìm người dùng, bài viết, #hashtag...',
                      hintStyle: TextStyle(color: hintColor, fontSize: 14),
                      prefixIcon:
                          Icon(Icons.search_rounded, color: hintColor, size: 20),
                      suffixIcon: _controller.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close_rounded,
                                  color: hintColor, size: 18),
                              onPressed: () {
                                _controller.clear();
                                _focusNode.requestFocus();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Hủy',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : AppTheme.slate600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.violetPrimary,
            unselectedLabelColor: isDark ? AppTheme.slate400 : AppTheme.slate500,
            indicatorColor: AppTheme.violetPrimary,
            tabs: const [
              Tab(text: 'Mọi người'),
              Tab(text: 'Bài viết'),
            ],
          ),
        ),
      ),
      body: _error != null
          ? _buildError(isDark)
          : TabBarView(
              controller: _tabController,
              children: [
                _buildUsersTab(isDark),
                _buildPostsTab(isDark),
              ],
            ),
    );
  }

  Widget _buildError(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.grey, size: 40),
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => _search(_lastQuery),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab(bool isDark) {
    if (_loadingUsers) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_controller.text.isEmpty) {
      return _emptyState(isDark, Icons.person_search_rounded,
          'Nhập tên hoặc @username để tìm');
    }
    if (_users.isEmpty) {
      return _emptyState(
          isDark, Icons.search_off_rounded, 'Không tìm thấy người dùng');
    }
    return Consumer<FriendProvider>(
      builder: (context, friendProvider, _) {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _users.length,
          itemBuilder: (context, i) =>
              _UserResultTile(item: _users[i], friendProvider: friendProvider),
        );
      },
    );
  }

  Widget _buildPostsTab(bool isDark) {
    if (_loadingPosts) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_controller.text.isEmpty) {
      return _emptyState(
          isDark, Icons.article_outlined, 'Nhập từ khoá hoặc #hashtag để tìm bài viết');
    }
    if (_posts.isEmpty) {
      return _emptyState(
          isDark, Icons.search_off_rounded, 'Không tìm thấy bài viết');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _posts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final post = _posts[i];
        return PostCard(
          post: post,
          onAuthorTap: () => UserProfileScreen.open(
            context,
            post.userId,
            displayName: post.user.name,
            avatarUrl: post.user.avatar,
          ),
        );
      },
    );
  }

  Widget _emptyState(bool isDark, IconData icon, String message) {
    final subtleColor = isDark ? AppTheme.slate500 : AppTheme.slate400;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: subtleColor),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: subtleColor, fontSize: 14)),
        ],
      ),
    );
  }
}

// ── User result tile (kèm nút kết bạn) ────────────────────────────────────────

class _UserResultTile extends StatelessWidget {
  final UserSearchResult item;
  final FriendProvider friendProvider;

  const _UserResultTile({required this.item, required this.friendProvider});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final normalized = item.username.toLowerCase();

    final isFriend = friendProvider.friends
        .any((f) => f.friend.userName.toLowerCase() == normalized);
    final hasSent = friendProvider.sentRequests
        .any((r) => r.receiver.userName.toLowerCase() == normalized);
    final hasReceived = friendProvider.receivedRequests
        .any((r) => r.sender.userName.toLowerCase() == normalized);
    final myId = (context.read<AuthProvider>().user?.id ?? '');
    final isSelf = item.id == myId;

    return InkWell(
      onTap: () => UserProfileScreen.open(
        context,
        item.id,
        displayName: item.fullName.isNotEmpty ? item.fullName : item.username,
        avatarUrl: item.profilePictureUrl,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: isDark ? const Color(0xFF3F3F46) : AppTheme.slate200,
              backgroundImage: (item.profilePictureUrl ?? '').isNotEmpty
                  ? NetworkImage(item.profilePictureUrl!)
                  : null,
              child: (item.profilePictureUrl ?? '').isEmpty
                  ? Icon(Icons.person,
                      color: isDark ? Colors.white54 : AppTheme.slate500, size: 22)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.fullName.isNotEmpty ? item.fullName : item.username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: isDark ? Colors.white : AppTheme.slate900,
                          ),
                        ),
                      ),
                      if (item.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified_rounded,
                            size: 14, color: Colors.blue),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${item.username}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppTheme.slate400 : AppTheme.slate500,
                    ),
                  ),
                ],
              ),
            ),
            if (!isSelf) _buildAction(context, isDark, isFriend, hasSent, hasReceived),
          ],
        ),
      ),
    );
  }

  Widget _buildAction(BuildContext context, bool isDark, bool isFriend,
      bool hasSent, bool hasReceived) {
    if (isFriend) return _badge('Bạn bè', isDark);
    if (hasSent) return _badge('Đã gửi', isDark);
    if (hasReceived) return _badge('Đã nhận', isDark);

    return SizedBox(
      height: 32,
      child: ElevatedButton.icon(
        onPressed: () async {
          final fp = context.read<FriendProvider>();
          final ok = await fp.sendFriendRequest(item.id);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(ok ? 'Đã gửi lời mời kết bạn' : (fp.error ?? 'Lỗi')),
          ));
        },
        icon: const Icon(Icons.person_add_alt_1_rounded, size: 14),
        label: const Text('Kết bạn', style: TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2D88FF),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _badge(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF3F3F46) : AppTheme.slate200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white70 : AppTheme.slate600,
        ),
      ),
    );
  }
}
