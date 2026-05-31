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

  List<BoardPost> get posts => _posts;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
  String get activeTag => _activeTag;
  String get sort => _sort;
  int get total => _total;

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
      final result = await _service.getPosts(tag: slug, sort: _sort);
      _posts = result.posts;
      _total = result.total;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
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
