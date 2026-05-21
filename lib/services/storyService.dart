import 'dart:io';
import 'package:dio/dio.dart';
import '../config/environment.dart';
import '../models/feedModel.dart';
import 'apiClient.dart';

class StoryService {
  final _client = ApiClient();

  String get _base => Environment.postServiceBaseUrl;

  Future<List<StoryFeedItem>> getStoryFeed() async {
    try {
      final resp = await _client.client.get('$_base/story/feed');
      final data = resp.data;
      if (data['success'] == true) {
        final items = data['data'] as List? ?? [];
        return items
            .whereType<Map>()
            .map((e) => StoryFeedItem.fromApi(e.cast<String, dynamic>()))
            .toList();
      }
      return [];
    } on DioException {
      return [];
    }
  }

  Future<List<Story>> getUserStories(String userId) async {
    try {
      final resp = await _client.client.get('$_base/story/user/$userId');
      final data = resp.data;
      if (data['success'] == true) {
        final items = data['data'] as List? ?? [];
        return items
            .whereType<Map>()
            .map((e) => Story.fromApi(e.cast<String, dynamic>()))
            .toList();
      }
      return [];
    } on DioException {
      return [];
    }
  }

  Future<Story?> createImageStory(File file) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path,
            filename: file.path.split('/').last),
      });
      final resp = await _client.client.post(
        '$_base/story/image',
        data: formData,
      );
      final data = resp.data;
      if (data['success'] == true && data['data'] != null) {
        return Story.fromApi((data['data'] as Map).cast<String, dynamic>());
      }
      return null;
    } on DioException {
      return null;
    }
  }

  Future<Story?> createVideoStory(File file) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path,
            filename: file.path.split('/').last),
      });
      final resp = await _client.client.post(
        '$_base/story/video',
        data: formData,
      );
      final data = resp.data;
      if (data['success'] == true && data['data'] != null) {
        return Story.fromApi((data['data'] as Map).cast<String, dynamic>());
      }
      return null;
    } on DioException {
      return null;
    }
  }

  Future<bool> viewStory(String storyId) async {
    try {
      final resp = await _client.client.post('$_base/story/$storyId/view');
      return resp.data['success'] == true;
    } on DioException {
      return false;
    }
  }

  Future<bool> deleteStory(String storyId) async {
    try {
      final resp = await _client.client.delete('$_base/story/$storyId');
      return resp.data['success'] == true;
    } on DioException {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getStoryViewers(String storyId) async {
    try {
      final resp = await _client.client.get('$_base/story/$storyId/viewers');
      final data = resp.data;
      if (data['success'] == true) {
        return (data['data'] as List? ?? [])
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();
      }
      return [];
    } on DioException {
      return [];
    }
  }
}
