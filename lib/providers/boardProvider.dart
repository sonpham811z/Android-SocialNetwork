import 'package:flutter/foundation.dart';
import '../models/boardModel.dart';
import '../services/boardService.dart';

class BoardProvider with ChangeNotifier {
  final BoardService _service = BoardService();

  List<BoardPost> _posts = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;
  String _activeTag = 'Tất cả';
  String _sort = 'hot';
  int _total = 0;

  // Pagination
  static const int _pageSize = 20;
  int _page = 1;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;

  // Comments cache per postId
  final Map<String, List<BoardComment>> _comments = {};
  final Set<String> _loadingComments = {};
  bool _isSubmittingComment = false;

  List<BoardPost> get posts => _posts;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  bool get isSubmittingComment => _isSubmittingComment;
  String? get error => _error;
  String get activeTag => _activeTag;
  String get sort => _sort;
  int get total => _total;

  List<BoardComment> commentsOf(String postId) => _comments[postId] ?? const [];
  bool isLoadingComments(String postId) => _loadingComments.contains(postId);
  BoardPost? postById(String postId) {
    final idx = _posts.indexWhere((p) => p.id == postId);
    return idx == -1 ? null : _posts[idx];
  }

  // Map tag display → API slug
  static const _tagSlug = {
    'Tất cả':   null,
    'hỏibài':   'hoibai',
    'timeline': 'timeline',
    'tìmphòng': 'timphong',
    'tâmsự':    'tamsu',
    'saleđồ':   'saledo',
  };

  Future<void> loadPosts({bool refresh = false}) async {
    if (_isLoading) return;
    _isLoading = true;
    if (refresh) _error = null;
    notifyListeners();

    try {
      final slug = _tagSlug[_activeTag];
      final result = await _service.getPosts(
          tag: slug, sort: _sort, page: 1, pageSize: _pageSize);
      _posts = result.posts;
      _total = result.total;
      _page = 1;
      _hasMore = result.posts.isNotEmpty && _posts.length < result.total;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tải thêm trang kế tiếp (infinite scroll).
  Future<void> loadMore() async {
    if (_isLoadingMore || _isLoading || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final slug = _tagSlug[_activeTag];
      final next = _page + 1;
      final result = await _service.getPosts(
          tag: slug, sort: _sort, page: next, pageSize: _pageSize);
      if (result.posts.isNotEmpty) {
        _posts = [..._posts, ...result.posts];
        _page = next;
      }
      _total = result.total;
      _hasMore = result.posts.isNotEmpty && _posts.length < result.total;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void setTag(String tag) {
    if (_activeTag == tag) return;
    _activeTag = tag;
    loadPosts(refresh: true);
  }

  void setSort(String sort) {
    if (_sort == sort) return;
    _sort = sort;
    loadPosts(refresh: true);
  }

  Future<bool> createPost({
    required String tag,
    required String content,
    required bool isAnonymous,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final post = await _service.createPost(
        tag: tag,
        content: content,
        isAnonymous: isAnonymous,
      );
      if (post != null) {
        _posts.insert(0, post);
        _total++;
      }
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> toggleVote(String postId, String voteType) async {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;

    final post = _posts[idx];
    final wasVote = post.currentUserVote;
    final isSameVote = wasVote == voteType;

    // Optimistic update
    _posts[idx] = _applyVoteOptimistic(post, voteType);
    notifyListeners();

    try {
      if (isSameVote) {
        await _service.deleteVote(postId);
      } else {
        await _service.vote(postId, voteType);
      }
    } catch (_) {
      // Rollback
      _posts[idx] = post;
      notifyListeners();
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await _service.deletePost(postId);
      _posts.removeWhere((p) => p.id == postId);
      _total--;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadComments(String postId, {bool refresh = false}) async {
    if (_loadingComments.contains(postId)) return;
    if (_comments.containsKey(postId) && !refresh) return;

    _loadingComments.add(postId);
    notifyListeners();

    try {
      final list = await _service.getComments(postId);
      _comments[postId] = list;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loadingComments.remove(postId);
      notifyListeners();
    }
  }

  Future<bool> addComment(
    String postId, {
    required String content,
    required bool isAnonymous,
  }) async {
    _isSubmittingComment = true;
    notifyListeners();

    try {
      final comment = await _service.addComment(
        postId: postId,
        content: content,
        isAnonymous: isAnonymous,
      );
      if (comment != null) {
        _comments[postId] = [...commentsOf(postId), comment];
        _bumpCommentCount(postId, 1);
      }
      return comment != null;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isSubmittingComment = false;
      notifyListeners();
    }
  }

  Future<void> deleteComment(String postId, String commentId) async {
    try {
      await _service.deleteComment(commentId);
      _comments[postId] =
          commentsOf(postId).where((c) => c.id != commentId).toList();
      _bumpCommentCount(postId, -1);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void _bumpCommentCount(String postId, int delta) {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    final p = _posts[idx];
    final next = (p.commentsCount + delta).clamp(0, 1 << 31);
    _posts[idx] = p.copyWith(commentsCount: next);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  BoardPost _applyVoteOptimistic(BoardPost post, String voteType) {
    final wasVote = post.currentUserVote;
    final isSame = wasVote == voteType;

    if (isSame) {
      // Toggle off
      return post.copyWith(
        upvotesCount:   voteType == 'up'   ? post.upvotesCount - 1   : post.upvotesCount,
        downvotesCount: voteType == 'down' ? post.downvotesCount - 1 : post.downvotesCount,
        netVotes: voteType == 'up' ? post.netVotes - 1 : post.netVotes + 1,
        clearVote: true,
      );
    }

    // Switch or new vote
    int up   = post.upvotesCount;
    int down = post.downvotesCount;
    int net  = post.netVotes;

    if (wasVote == 'up')   { up--;   net--; }
    if (wasVote == 'down') { down--; net++; }
    if (voteType == 'up')  { up++;   net++; }
    if (voteType == 'down'){ down++; net--; }

    return post.copyWith(
      upvotesCount:   up,
      downvotesCount: down,
      netVotes:       net,
      currentUserVote: voteType,
    );
  }
}
