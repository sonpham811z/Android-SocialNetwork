import 'package:flutter/foundation.dart';

import '../models/feedModel.dart';
import '../services/postService.dart';

class PostProvider with ChangeNotifier {
  final PostService _service = PostService();

  final List<Post> _feedPosts = [];
  final List<Post> _myPosts = [];
  int _feedPostsTotalCount = 0;
  int _myPostsTotalCount = 0;
  bool _isLoadingFeed = false;
  bool _isLoadingMyPosts = false;
  bool _isSubmitting = false;
  String? _error;

  List<Post> get feedPosts => List.unmodifiable(_feedPosts);
  List<Post> get myPosts => List.unmodifiable(_myPosts);
  int get feedPostsTotalCount => _feedPostsTotalCount;
  int get myPostsTotalCount => _myPostsTotalCount;
  bool get isLoadingFeed => _isLoadingFeed;
  bool get isLoadingMyPosts => _isLoadingMyPosts;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;

  /// Reset all cached state — call on logout / account switch.
  void clear() {
    _feedPosts.clear();
    _myPosts.clear();
    _feedPostsTotalCount = 0;
    _myPostsTotalCount = 0;
    _isLoadingFeed = false;
    _isLoadingMyPosts = false;
    _isSubmitting = false;
    _error = null;
    notifyListeners();
  }

  Future<void> loadFeed({bool forceRefresh = false}) async {
    if (_isLoadingFeed) {
      return;
    }

    if (_feedPosts.isNotEmpty && !forceRefresh) {
      return;
    }

    _isLoadingFeed = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.getFeed();
      _feedPosts
        ..clear()
        ..addAll(result.posts);
      _feedPostsTotalCount = result.totalCount;
    } catch (e) {
      _error = e is Exception ? e.toString().replaceFirst('Exception: ', '') : e.toString();
    } finally {
      _isLoadingFeed = false;
      notifyListeners();
    }
  }

  Future<void> loadMyPosts(String userId, {bool forceRefresh = false}) async {
    if (_isLoadingMyPosts || userId.trim().isEmpty) {
      return;
    }

    if (_myPosts.isNotEmpty && !forceRefresh) {
      return;
    }

    _isLoadingMyPosts = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.getUserPosts(userId);
      _myPosts
        ..clear()
        ..addAll(result.posts);
      _myPostsTotalCount = result.totalCount;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingMyPosts = false;
      notifyListeners();
    }
  }

  Future<bool> createTextPost(String content, {String visibility = 'Public'}) async {
    final normalized = content.trim();
    if (normalized.isEmpty || _isSubmitting) {
      return false;
    }

    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final created = await _service.createTextPost(content: normalized, visibility: visibility);
      if (created != null) {
        _feedPosts.insert(0, created);
        _myPosts.insert(0, created);
      }
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> createImagePost({required String content, required String imagePath, String visibility = 'Public'}) async {
    final normalized = content.trim();
    if (normalized.isEmpty || imagePath.trim().isEmpty || _isSubmitting) {
      return false;
    }

    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final created = await _service.createImagePost(content: normalized, imagePath: imagePath, visibility: visibility);
      if (created != null) {
        _feedPosts.insert(0, created);
        _myPosts.insert(0, created);
      }
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> createVoicePost({required String content, required String audioPath, String visibility = 'Public'}) async {
    final normalized = content.trim();
    if (normalized.isEmpty || audioPath.trim().isEmpty || _isSubmitting) {
      return false;
    }

    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final created = await _service.createVoicePost(content: normalized, audioPath: audioPath, visibility: visibility);
      if (created != null) {
        _feedPosts.insert(0, created);
        _myPosts.insert(0, created);
      }
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> createVideoPost({required String content, required String videoPath, String visibility = 'Public'}) async {
    final normalized = content.trim();
    if (normalized.isEmpty || videoPath.trim().isEmpty || _isSubmitting) {
      return false;
    }

    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final created = await _service.createVideoPost(content: normalized, videoPath: videoPath, visibility: visibility);
      if (created != null) {
        _feedPosts.insert(0, created);
        _myPosts.insert(0, created);
      }
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sharePost(
    String originalPostId, {
    String content = '',
    String visibility = 'Public',
  }) async {
    if (_isSubmitting) return false;

    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final created = await _service.sharePost(
        originalPostId: originalPostId,
        content: content,
        visibility: visibility,
      );
      if (created != null) {
        _feedPosts.insert(0, created);
        _myPosts.insert(0, created);
        // Cập nhật sharesCount của bài gốc (optimistic)
        _updatePostById(originalPostId, (p) => p.copyWith(sharesCount: p.sharesCount + 1));
      }
      _isSubmitting = false;
      notifyListeners();
      return created != null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleLike(Post post) async {
    final isLiked = post.isLikedByCurrentUser;
    final optimistic = post.copyWith(
      isLikedByCurrentUser: !isLiked,
      likes: isLiked ? (post.likes - 1).clamp(0, 1 << 31) : post.likes + 1,
    );
    _replacePost(optimistic);
    notifyListeners();

    try {
      if (isLiked) {
        await _service.unlikePost(post.id);
      } else {
        await _service.likePost(post.id);
      }
    } catch (e) {
      _replacePost(post);
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadComments(String postId) async {
    try {
      final comments = await _service.getComments(postId);
      _updatePostById(postId, (post) => post.copyWith(
        commentsList: comments,
        commentsCount: comments.length,
      ));
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> createComment(String postId, String content, {String? parentCommentId}) async {
    final normalized = content.trim();
    if (normalized.isEmpty) {
      return false;
    }

    try {
      final created = await _service.createComment(
        postId,
        normalized,
        parentCommentId: parentCommentId,
      );
      if (created != null) {
        _updatePostById(postId, (post) {
          final nextComments = [...(post.commentsList ?? <Comment>[]), created];
          return post.copyWith(commentsList: nextComments, commentsCount: nextComments.length);
        });
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateComment(String postId, String commentId, String content) async {
    final normalized = content.trim();
    if (normalized.isEmpty) {
      return false;
    }

    try {
      final updated = await _service.updateComment(commentId, normalized);
      if (updated != null) {
        _updatePostById(postId, (post) {
          final nextComments = (post.commentsList ?? <Comment>[]).map((c) {
            return c.id == commentId ? updated : c;
          }).toList();
          return post.copyWith(commentsList: nextComments);
        });
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteComment(String postId, String commentId) async {
    try {
      final success = await _service.deleteComment(commentId);
      if (success) {
        _updatePostById(postId, (post) {
          final nextComments = (post.commentsList ?? <Comment>[])
              .where((c) => c.id != commentId && c.parentCommentId != commentId)
              .toList();
          return post.copyWith(commentsList: nextComments, commentsCount: nextComments.length);
        });
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleCommentLike(String postId, String commentId) async {
    // Optimistic update
    bool wasLiked = false;
    _updatePostById(postId, (post) {
      final nextComments = (post.commentsList ?? <Comment>[]).map((c) {
        if (c.id != commentId) return c;
        wasLiked = c.isLikedByCurrentUser;
        return c.copyWith(
          isLikedByCurrentUser: !wasLiked,
          likesCount: wasLiked
              ? (c.likesCount - 1).clamp(0, 1 << 31)
              : c.likesCount + 1,
        );
      }).toList();
      return post.copyWith(commentsList: nextComments);
    });
    notifyListeners();

    // Call API
    try {
      if (wasLiked) {
        await _service.unlikeComment(commentId);
      } else {
        await _service.likeComment(commentId);
      }
    } catch (_) {
      // Rollback on failure
      _updatePostById(postId, (post) {
        final rollback = (post.commentsList ?? <Comment>[]).map((c) {
          if (c.id != commentId) return c;
          return c.copyWith(
            isLikedByCurrentUser: wasLiked,
            likesCount: wasLiked
                ? c.likesCount + 1
                : (c.likesCount - 1).clamp(0, 1 << 31),
          );
        }).toList();
        return post.copyWith(commentsList: rollback);
      });
      notifyListeners();
    }
  }

  Future<bool> updatePost({
    required String postId,
    required String content,
  }) async {
    final normalized = content.trim();
    if (normalized.isEmpty || _isSubmitting) {
      return false;
    }

    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _service.updatePost(postId: postId, content: normalized);
      if (updated != null) {
        _replacePost(updated);
      }
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePost(String postId) async {
    if (_isSubmitting) {
      return false;
    }

    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _service.deletePost(postId);
      if (success) {
        _feedPosts.removeWhere((post) => post.id == postId);
        _myPosts.removeWhere((post) => post.id == postId);
      }
      _isSubmitting = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = e.toString();
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  void _replacePost(Post nextPost) {
    _updatePostById(nextPost.id, (_) => nextPost);
  }

  void _updatePostById(String postId, Post Function(Post post) updater) {
    for (var i = 0; i < _feedPosts.length; i++) {
      if (_feedPosts[i].id == postId) {
        _feedPosts[i] = updater(_feedPosts[i]);
      }
    }

    for (var i = 0; i < _myPosts.length; i++) {
      if (_myPosts[i].id == postId) {
        _myPosts[i] = updater(_myPosts[i]);
      }
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}