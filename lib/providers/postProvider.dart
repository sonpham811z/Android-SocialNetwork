import 'package:flutter/foundation.dart';

import '../models/feedModel.dart';
import '../services/postService.dart';

class PostProvider with ChangeNotifier {
  final PostService _service = PostService();

  final List<Post> _feedPosts = [];
  final List<Post> _myPosts = [];
  bool _isLoadingFeed = false;
  bool _isLoadingMyPosts = false;
  bool _isSubmitting = false;
  String? _error;

  List<Post> get feedPosts => List.unmodifiable(_feedPosts);
  List<Post> get myPosts => List.unmodifiable(_myPosts);
  bool get isLoadingFeed => _isLoadingFeed;
  bool get isLoadingMyPosts => _isLoadingMyPosts;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;

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
      final posts = await _service.getFeed();
      _feedPosts
        ..clear()
        ..addAll(posts);
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
      final posts = await _service.getUserPosts(userId);
      _myPosts
        ..clear()
        ..addAll(posts);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingMyPosts = false;
      notifyListeners();
    }
  }

  Future<bool> createTextPost(String content) async {
    final normalized = content.trim();
    if (normalized.isEmpty || _isSubmitting) {
      return false;
    }

    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final created = await _service.createTextPost(content: normalized);
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

  Future<bool> createImagePost({required String content, required String imagePath}) async {
    final normalized = content.trim();
    if (normalized.isEmpty || imagePath.trim().isEmpty || _isSubmitting) {
      return false;
    }

    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final created = await _service.createImagePost(content: normalized, imagePath: imagePath);
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

  Future<bool> createVoicePost({required String content, required String audioPath}) async {
    final normalized = content.trim();
    if (normalized.isEmpty || audioPath.trim().isEmpty || _isSubmitting) {
      return false;
    }

    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final created = await _service.createVoicePost(content: normalized, audioPath: audioPath);
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
      _updatePostById(postId, (post) => post.copyWith(commentsList: comments, commentsCount: comments.length));
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> createComment(String postId, String content) async {
    final normalized = content.trim();
    if (normalized.isEmpty) {
      return false;
    }

    try {
      final created = await _service.createComment(postId, normalized);
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