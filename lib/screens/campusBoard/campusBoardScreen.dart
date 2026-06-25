import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/boardModel.dart';
import '../../providers/boardProvider.dart';
import '../../providers/authProvider.dart';

// ── Tag config ────────────────────────────────────────────────────────────────

class _Tag {
  final String label;
  final Color color;
  final IconData icon;
  const _Tag(this.label, this.color, this.icon);
}

const _tags = [
  _Tag('Tất cả',   Color(0xFF6366F1), Icons.grid_view_rounded),
  _Tag('hỏibài',   Color(0xFF2D88FF), Icons.menu_book_rounded),
  _Tag('timeline', Color(0xFF10B981), Icons.calendar_today_rounded),
  _Tag('tìmphòng', Color(0xFFF59E0B), Icons.home_work_rounded),
  _Tag('tâmsự',    Color(0xFFEC4899), Icons.favorite_rounded),
  _Tag('saleđồ',   Color(0xFF8B5CF6), Icons.storefront_rounded),
];

_Tag _tagConfig(String label) =>
    _tags.firstWhere((t) => t.label == label, orElse: () => _tags[0]);

// ── Screen ────────────────────────────────────────────────────────────────────

class CampusBoardScreen extends StatefulWidget {
  const CampusBoardScreen({super.key});

  @override
  State<CampusBoardScreen> createState() => _CampusBoardScreenState();
}

class _CampusBoardScreenState extends State<CampusBoardScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BoardProvider>().loadPosts(refresh: true);
    });
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.offset >=
            _scrollController.position.maxScrollExtent - 400) {
      context.read<BoardProvider>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F0F10) : AppTheme.slate50;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(isDark),
            _buildTagBar(isDark),
            _buildSortBar(isDark),
            Expanded(child: _buildFeed(isDark)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPostSheet(context, isDark),
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.edit_rounded, color: Colors.white),
        label: const Text('Đăng bài',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        elevation: 4,
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final titleColor = isDark ? Colors.white : AppTheme.slate900;
    final subColor = isDark ? AppTheme.slate400 : AppTheme.slate500;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text('Bảng Tin',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: titleColor)),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Beta',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6366F1))),
                ),
              ]),
              Text('Cộng đồng sinh viên · Ẩn danh',
                  style: TextStyle(fontSize: 12, color: subColor)),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => context.read<BoardProvider>().loadPosts(refresh: true),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF27272A) : AppTheme.slate100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.refresh_rounded,
                  size: 20,
                  color: isDark ? Colors.white70 : AppTheme.slate600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagBar(bool isDark) {
    return Consumer<BoardProvider>(
      builder: (_, provider, __) => SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          itemCount: _tags.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, i) {
            final t = _tags[i];
            final isActive = provider.activeTag == t.label;
            return GestureDetector(
              onTap: () => provider.setTag(t.label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive
                      ? t.color
                      : (isDark
                          ? const Color(0xFF27272A)
                          : AppTheme.slate100),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(t.icon,
                        size: 13,
                        color: isActive
                            ? Colors.white
                            : (isDark
                                ? AppTheme.slate400
                                : AppTheme.slate500)),
                    const SizedBox(width: 5),
                    Text(
                      '#${t.label}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? Colors.white
                            : (isDark
                                ? AppTheme.slate400
                                : AppTheme.slate600),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSortBar(bool isDark) {
    final subColor = isDark ? AppTheme.slate400 : AppTheme.slate500;
    return Consumer<BoardProvider>(
      builder: (_, provider, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Text('${provider.total} bài viết',
                style: TextStyle(fontSize: 12, color: subColor)),
            const Spacer(),
            _sortChip(Icons.local_fire_department_rounded, 'Hot',
                value: 'hot', provider: provider, isDark: isDark),
            const SizedBox(width: 6),
            _sortChip(Icons.access_time_rounded, 'Mới nhất',
                value: 'new', provider: provider, isDark: isDark),
          ],
        ),
      ),
    );
  }

  Widget _sortChip(IconData icon, String label,
      {required String value,
      required BoardProvider provider,
      required bool isDark}) {
    final isActive = provider.sort == value;
    final activeColor =
        value == 'hot' ? Colors.orangeAccent : const Color(0xFF2D88FF);
    final inactiveColor = isDark ? AppTheme.slate500 : AppTheme.slate400;
    return GestureDetector(
      onTap: () => provider.setSort(value),
      child: Row(
        children: [
          Icon(icon,
              size: 13, color: isActive ? activeColor : inactiveColor),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      isActive ? FontWeight.w700 : FontWeight.normal,
                  color: isActive ? activeColor : inactiveColor)),
        ],
      ),
    );
  }

  Widget _buildFeed(bool isDark) {
    return Consumer<BoardProvider>(
      builder: (_, provider, __) {
        if (provider.isLoading && provider.posts.isEmpty) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF6366F1)));
        }

        if (provider.error != null && provider.posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.grey, size: 48),
                const SizedBox(height: 12),
                Text(provider.error!,
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => provider.loadPosts(refresh: true),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        if (provider.posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox_rounded,
                    size: 56,
                    color: isDark ? AppTheme.slate600 : AppTheme.slate300),
                const SizedBox(height: 12),
                Text('Chưa có bài viết nào',
                    style: TextStyle(
                        color:
                            isDark ? AppTheme.slate500 : AppTheme.slate400)),
              ],
            ),
          );
        }

        final myId = context.read<AuthProvider>().user?.id ?? '';

        return RefreshIndicator(
          color: const Color(0xFF6366F1),
          onRefresh: () => provider.loadPosts(refresh: true),
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.only(top: 4, bottom: 120),
            itemCount: provider.posts.length + (provider.isLoadingMore ? 1 : 0),
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color:
                  isDark ? const Color(0xFF27272A) : AppTheme.slate100,
            ),
            itemBuilder: (_, i) {
              if (i >= provider.posts.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF6366F1)),
                    ),
                  ),
                );
              }
              final post = provider.posts[i];
              return _BoardPostCard(
                post: post,
                isDark: isDark,
                isOwner: post.authorId == myId,
                onVote: (voteType) =>
                    provider.toggleVote(post.id, voteType),
                onDelete: () => provider.deletePost(post.id),
              );
            },
          ),
        );
      },
    );
  }

  void _showPostSheet(BuildContext context, bool isDark) {
    String selectedTag = 'tâmsự';
    bool isAnon = true;
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) {
          final sheetBg = isDark ? const Color(0xFF18181B) : Colors.white;
          final borderColor =
              isDark ? const Color(0xFF27272A) : AppTheme.slate200;

          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF3F3F46)
                            : AppTheme.slate200,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Đăng lên Bảng Tin',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.slate900)),
                  const SizedBox(height: 12),
                  // Tag picker
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _tags.skip(1).map((t) {
                        final isActive = selectedTag == t.label;
                        return GestureDetector(
                          onTap: () => setS(() => selectedTag = t.label),
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? t.color
                                  : (isDark
                                      ? const Color(0xFF27272A)
                                      : AppTheme.slate100),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text('#${t.label}',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isActive
                                        ? Colors.white
                                        : (isDark
                                            ? AppTheme.slate400
                                            : AppTheme.slate500))),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    maxLines: 5,
                    minLines: 3,
                    autofocus: true,
                    style: TextStyle(
                        color: isDark ? Colors.white : AppTheme.slate900,
                        fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Bạn đang nghĩ gì? Chia sẻ với cộng đồng...',
                      hintStyle: TextStyle(
                          color: isDark
                              ? AppTheme.slate500
                              : AppTheme.slate400),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF27272A)
                          : AppTheme.slate50,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF6366F1))),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => setS(() => isAnon = !isAnon),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: isAnon
                                ? const Color(0xFF6366F1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: isAnon
                                  ? const Color(0xFF6366F1)
                                  : (isDark
                                      ? AppTheme.slate500
                                      : AppTheme.slate400),
                            ),
                          ),
                          child: isAnon
                              ? const Icon(Icons.check,
                                  size: 13, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text('Đăng ẩn danh',
                            style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? Colors.white70
                                    : AppTheme.slate700)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Consumer<BoardProvider>(
                    builder: (ctx2, provider, _) => SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: provider.isSubmitting
                            ? null
                            : () async {
                                if (controller.text.trim().isEmpty) return;
                                final ok = await provider.createPost(
                                  tag: selectedTag,
                                  content: controller.text.trim(),
                                  isAnonymous: isAnon,
                                );
                                if (!ctx2.mounted) return;
                                Navigator.pop(ctx2);
                                if (!ok) {
                                  ScaffoldMessenger.of(ctx2).showSnackBar(
                                    SnackBar(
                                        content: Text(provider.error ??
                                            'Đăng bài thất bại')),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: provider.isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('Đăng bài',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).whenComplete(controller.dispose);
  }
}

// ── Post Card ─────────────────────────────────────────────────────────────────

class _BoardPostCard extends StatelessWidget {
  final BoardPost post;
  final bool isDark;
  final bool isOwner;
  final void Function(String voteType) onVote;
  final VoidCallback onDelete;

  const _BoardPostCard({
    required this.post,
    required this.isDark,
    required this.isOwner,
    required this.onVote,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final tag = _tagConfig(post.tag);
    final textColor = isDark ? Colors.white : AppTheme.slate900;
    final subColor = isDark ? AppTheme.slate400 : AppTheme.slate500;

    return Material(
      color: isDark ? const Color(0xFF0F0F10) : Colors.white,
      child: InkWell(
        onTap: () => _showDetailSheet(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tag + author + time
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: tag.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(tag.icon, size: 10, color: tag.color),
                        const SizedBox(width: 4),
                        Text('#${tag.label}',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: tag.color)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (post.isAnonymous)
                    Row(children: [
                      Icon(Icons.person_off_outlined,
                          size: 11, color: subColor),
                      const SizedBox(width: 3),
                      Text('Ẩn danh',
                          style: TextStyle(fontSize: 11, color: subColor)),
                    ])
                  else
                    Text(post.authorName ?? '',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textColor)),
                  const Spacer(),
                  Text(post.timeAgo,
                      style: TextStyle(fontSize: 11, color: subColor)),
                  if (isOwner) ...[
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: onDelete,
                      child: const Icon(Icons.delete_outline_rounded,
                          size: 16, color: Colors.redAccent),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                post.content,
                style:
                    TextStyle(fontSize: 14, height: 1.5, color: textColor),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _voteBtn('up', Icons.arrow_upward_rounded,
                      Colors.orangeAccent),
                  const SizedBox(width: 4),
                  _scoreText(post.netVotes, subColor),
                  const SizedBox(width: 4),
                  _voteBtn('down', Icons.arrow_downward_rounded,
                      const Color(0xFF2D88FF)),
                  const SizedBox(width: 16),
                  Icon(Icons.chat_bubble_outline_rounded,
                      size: 15, color: subColor),
                  const SizedBox(width: 4),
                  Text('${post.commentsCount}',
                      style: TextStyle(fontSize: 13, color: subColor)),
                  const SizedBox(width: 6),
                  Text('Bình luận',
                      style: TextStyle(fontSize: 12, color: subColor)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailSheet(BuildContext context) {
    final tag = _tagConfig(post.tag);
    final textColor = isDark ? Colors.white : AppTheme.slate900;
    final subColor = isDark ? AppTheme.slate400 : AppTheme.slate500;
    final sheetBg = isDark ? const Color(0xFF18181B) : Colors.white;

    // Load comments when the sheet opens
    context.read<BoardProvider>().loadComments(post.id, refresh: true);

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
          child: SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
              ),
              child: StatefulBuilder(
                builder: (ctx, setS) => Consumer<BoardProvider>(
                  builder: (ctx2, provider, _) {
                    final livePost = provider.postById(post.id) ?? post;
                    final comments = provider.commentsOf(post.id);
                    final loading = provider.isLoadingComments(post.id);

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Handle bar
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(top: 12, bottom: 12),
                            decoration: BoxDecoration(
                              color: subColor.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        // Scrollable content + comments
                        Flexible(
                          child: SingleChildScrollView(
                            padding:
                                const EdgeInsets.fromLTRB(20, 0, 20, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Tag + author + time
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color:
                                            tag.color.withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(tag.icon,
                                              size: 11, color: tag.color),
                                          const SizedBox(width: 4),
                                          Text('#${tag.label}',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: tag.color)),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      post.isAnonymous
                                          ? 'Ẩn danh'
                                          : (post.authorName ?? ''),
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: textColor),
                                    ),
                                    Text('  ·  ${post.timeAgo}',
                                        style: TextStyle(
                                            fontSize: 11, color: subColor)),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  post.content,
                                  style: TextStyle(
                                      fontSize: 15,
                                      height: 1.6,
                                      color: textColor),
                                ),
                                const SizedBox(height: 20),
                                // Vote row (live)
                                Row(
                                  children: [
                                    _voteBtn('up', Icons.arrow_upward_rounded,
                                        Colors.orangeAccent, state: livePost),
                                    const SizedBox(width: 6),
                                    _scoreText(livePost.netVotes, subColor),
                                    const SizedBox(width: 6),
                                    _voteBtn(
                                        'down',
                                        Icons.arrow_downward_rounded,
                                        const Color(0xFF2D88FF),
                                        state: livePost),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Divider(
                                    color: isDark
                                        ? const Color(0xFF27272A)
                                        : AppTheme.slate100),
                                const SizedBox(height: 4),
                                Text(
                                  'Bình luận · ${livePost.commentsCount}',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: textColor),
                                ),
                                const SizedBox(height: 8),
                                if (loading && comments.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(
                                        child: SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Color(0xFF6366F1)))),
                                  )
                                else if (comments.isEmpty)
                                  Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 16),
                                    child: Center(
                                      child: Text(
                                        'Chưa có bình luận. Hãy là người đầu tiên!',
                                        style: TextStyle(
                                            fontSize: 13, color: subColor),
                                      ),
                                    ),
                                  )
                                else
                                  ...comments.map((c) => _commentTile(
                                        c,
                                        textColor: textColor,
                                        subColor: subColor,
                                        onDelete: () => provider.deleteComment(
                                            post.id, c.id),
                                      )),
                              ],
                            ),
                          ),
                        ),
                        // Comment input — own StatefulWidget so its
                        // TextEditingController lifecycle is tied to the widget
                        // (no use-after-dispose when the sheet is dismissed mid-send).
                        _BoardCommentInput(postId: post.id, isDark: isDark),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _commentTile(
    BoardComment c, {
    required Color textColor,
    required Color subColor,
    required VoidCallback onDelete,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.15),
            backgroundImage:
                (!c.isAnonymous && (c.authorAvatar ?? '').isNotEmpty)
                    ? NetworkImage(c.authorAvatar!)
                    : null,
            child: (c.isAnonymous || (c.authorAvatar ?? '').isEmpty)
                ? Icon(
                    c.isAnonymous
                        ? Icons.person_off_outlined
                        : Icons.person,
                    size: 14,
                    color: const Color(0xFF6366F1))
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      c.isAnonymous ? 'Ẩn danh' : (c.authorName ?? 'Người dùng'),
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: textColor),
                    ),
                    const SizedBox(width: 6),
                    Text(c.timeAgo,
                        style: TextStyle(fontSize: 11, color: subColor)),
                    const Spacer(),
                    if (c.isMine)
                      GestureDetector(
                        onTap: onDelete,
                        child: Icon(Icons.delete_outline_rounded,
                            size: 15, color: subColor),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(c.content,
                    style: TextStyle(
                        fontSize: 14, height: 1.4, color: textColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _voteBtn(String type, IconData icon, Color activeColor,
      {BoardPost? state}) {
    final p = state ?? post;
    final isActive = p.currentUserVote == type;
    final inactiveColor =
        isDark ? AppTheme.slate500 : AppTheme.slate400;
    return GestureDetector(
      onTap: () => onVote(type),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.12)
              : (isDark ? const Color(0xFF27272A) : AppTheme.slate100),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            size: 15, color: isActive ? activeColor : inactiveColor),
      ),
    );
  }

  Widget _scoreText(int net, Color subColor) {
    final color = net > 0
        ? Colors.orangeAccent
        : net < 0
            ? const Color(0xFF2D88FF)
            : subColor;
    return Text(
      net > 0 ? '+$net' : '$net',
      style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w700, color: color),
    );
  }
}

/// Ô nhập bình luận cho bottom sheet của Campus Board.
/// Là StatefulWidget riêng để TextEditingController gắn với vòng đời widget —
/// tránh lỗi "used after disposed" khi đóng sheet ngay sau khi bấm gửi.
class _BoardCommentInput extends StatefulWidget {
  final String postId;
  final bool isDark;

  const _BoardCommentInput({required this.postId, required this.isDark});

  @override
  State<_BoardCommentInput> createState() => _BoardCommentInputState();
}

class _BoardCommentInputState extends State<_BoardCommentInput> {
  final _controller = TextEditingController();
  bool _anon = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final provider = context.read<BoardProvider>();
    final ok = await provider.addComment(
      widget.postId,
      content: text,
      isAnonymous: _anon,
    );
    // Chỉ thao tác controller khi widget còn sống (sheet chưa bị đóng).
    if (ok && mounted) _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textColor = isDark ? Colors.white : AppTheme.slate900;
    final subColor = isDark ? AppTheme.slate400 : AppTheme.slate500;
    final isSubmitting =
        context.watch<BoardProvider>().isSubmittingComment;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
              color: isDark ? const Color(0xFF27272A) : AppTheme.slate100),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => _anon = !_anon),
            child: Tooltip(
              message: _anon ? 'Đang ẩn danh' : 'Hiện tên',
              child: Icon(
                _anon ? Icons.person_off_outlined : Icons.person_outline,
                size: 22,
                color: _anon ? const Color(0xFF6366F1) : subColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 4,
              style: TextStyle(color: textColor, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Viết bình luận...',
                hintStyle: TextStyle(color: subColor, fontSize: 14),
                isDense: true,
                filled: true,
                fillColor: isDark ? const Color(0xFF27272A) : AppTheme.slate100,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          isSubmitting
              ? const Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF6366F1))),
                )
              : IconButton(
                  icon: const Icon(Icons.send_rounded,
                      color: Color(0xFF6366F1)),
                  onPressed: _submit,
                ),
        ],
      ),
    );
  }
}
