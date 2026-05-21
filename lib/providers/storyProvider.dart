import 'dart:io';
import 'package:flutter/material.dart';
import '../models/feedModel.dart';
import '../services/storyService.dart';

class StoryProvider extends ChangeNotifier {
  final _service = StoryService();

  List<StoryFeedItem> _feedItems = [];
  bool _isLoading = false;
  String? _error;

  List<StoryFeedItem> get feedItems => _feedItems;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadStoryFeed() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _feedItems = await _service.getStoryFeed();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Story?> createImageStory(File file) async {
    final story = await _service.createImageStory(file);
    if (story != null) {
      _prependOwnStory(story);
    }
    return story;
  }

  Future<Story?> createVideoStory(File file) async {
    final story = await _service.createVideoStory(file);
    if (story != null) {
      _prependOwnStory(story);
    }
    return story;
  }

  Future<void> markStoryViewed(String storyId, String userId) async {
    await _service.viewStory(storyId);

    // Update local state
    for (final item in _feedItems) {
      for (int i = 0; i < item.stories.length; i++) {
        if (item.stories[i].id == storyId && !item.stories[i].isViewedByCurrentUser) {
          final updated = Story(
            id: item.stories[i].id,
            user: item.stories[i].user,
            mediaUrl: item.stories[i].mediaUrl,
            thumbnailUrl: item.stories[i].thumbnailUrl,
            mediaType: item.stories[i].mediaType,
            viewsCount: item.stories[i].viewsCount + 1,
            isViewedByCurrentUser: true,
            isOwner: item.stories[i].isOwner,
            createdAt: item.stories[i].createdAt,
            expiresAt: item.stories[i].expiresAt,
          );
          item.stories[i] = updated;
          break;
        }
      }
    }
    notifyListeners();
  }

  Future<bool> deleteStory(String storyId) async {
    final ok = await _service.deleteStory(storyId);
    if (ok) {
      for (final item in _feedItems) {
        item.stories.removeWhere((s) => s.id == storyId);
      }
      _feedItems.removeWhere((item) => item.stories.isEmpty);
      notifyListeners();
    }
    return ok;
  }

  void _prependOwnStory(Story story) {
    final existingIdx = _feedItems.indexWhere((item) => item.user.id == story.user.id);
    if (existingIdx >= 0) {
      _feedItems[existingIdx].stories.insert(0, story);
    } else {
      _feedItems.insert(0, StoryFeedItem(
        user: story.user,
        stories: [story],
        hasUnseenStories: false,
      ));
    }
    notifyListeners();
  }
}
