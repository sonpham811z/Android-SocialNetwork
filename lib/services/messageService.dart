import '../config/environment.dart';
import '../models/chatModel.dart';
import '../utils/json_helpers.dart';
import 'apiClient.dart';

class MessageService {
  final ApiClient _apiClient = ApiClient();

  Exception _mapError(Object e) {
    if (e is Exception) return e;
    return Exception(e.toString());
  }

  Future<List<ConversationModel>> getConversations() async {
    try {
      final response = await _apiClient.dio.get(
        '${Environment.messageServiceBaseUrl}/conversations',
      );
      final body = asJsonMap(response.data) ?? {};
      final rawList = asJsonList(body['data'] ?? body['Data']) ?? [];
      return rawList
          .map((e) => ConversationModel.fromJson(asJsonMap(e) ?? {}))
          .toList();
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<ConversationModel> createOrGetOneToOne(String targetUserId) async {
    try {
      final response = await _apiClient.dio.post(
        '${Environment.messageServiceBaseUrl}/conversations/one-to-one',
        data: {'targetUserId': targetUserId},
      );
      final body = asJsonMap(response.data) ?? {};
      return ConversationModel.fromJson(asJsonMap(body['data'] ?? body['Data']) ?? {});
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<MessagePageResult> getMessages(
    String conversationId, {
    String? beforeMessageId,
    int pageSize = 30,
  }) async {
    try {
      final queryParams = <String, dynamic>{'pageSize': pageSize};
      if (beforeMessageId != null) queryParams['beforeMessageId'] = beforeMessageId;

      final response = await _apiClient.dio.get(
        '${Environment.messageServiceBaseUrl}/messages/$conversationId',
        queryParameters: queryParams,
      );
      final body = asJsonMap(response.data) ?? {};
      return MessagePageResult.fromJson(asJsonMap(body['data'] ?? body['Data']) ?? {});
    } catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> markAsRead(String conversationId) async {
    try {
      await _apiClient.dio.patch(
        '${Environment.messageServiceBaseUrl}/messages/$conversationId/read',
      );
    } catch (_) {
      // Mark as read is best-effort
    }
  }
}
