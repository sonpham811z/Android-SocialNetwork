import 'package:flutter/foundation.dart';

import '../models/friendModel.dart';
import '../services/FriendService.dart';

class FriendProvider with ChangeNotifier {
  final FriendService _service = FriendService();

  bool _isLoading = false;
  bool _isActionLoading = false;
  String? _error;

  List<FriendshipModel> _friends = <FriendshipModel>[];
  List<FriendRequestModel> _receivedRequests = <FriendRequestModel>[];
  List<FriendRequestModel> _sentRequests = <FriendRequestModel>[];
  List<FollowModel> _followers = <FollowModel>[];
  List<FollowModel> _following = <FollowModel>[];
  List<BlockModel> _blockedUsers = <BlockModel>[];

  SocialSummaryModel? _socialSummary;
  List<String> _friendIds = <String>[];

  bool get isLoading => _isLoading;
  bool get isActionLoading => _isActionLoading;
  String? get error => _error;
  List<FriendshipModel> get friends => _friends;
  List<FriendRequestModel> get receivedRequests => _receivedRequests;
  List<FriendRequestModel> get sentRequests => _sentRequests;
  List<FollowModel> get followers => _followers;
  List<FollowModel> get following => _following;
  List<BlockModel> get blockedUsers => _blockedUsers;
  SocialSummaryModel? get socialSummary => _socialSummary;
  List<String> get friendIds => _friendIds;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> _runLoad(Future<void> Function() operation) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await operation();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> _runAction(Future<void> Function() operation) async {
    _isActionLoading = true;
    _error = null;
    notifyListeners();

    try {
      await operation();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMyFriends({int page = 1, int pageSize = 20}) async {
    await _runLoad(() async {
      final res = await _service.getMyFriends(page: page, pageSize: pageSize);
      _friends = res.data?.items ?? <FriendshipModel>[];
    });
  }

  Future<void> loadFriendsByUserId(
    String userId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    await _runLoad(() async {
      final res = await _service.getFriendsByUserId(
        userId,
        page: page,
        pageSize: pageSize,
      );
      _friends = res.data?.items ?? <FriendshipModel>[];
    });
  }

  Future<void> loadFriendIds() async {
    await _runLoad(() async {
      final res = await _service.getFriendIds();
      _friendIds = res.data ?? <String>[];
    });
  }

  Future<void> loadSocialSummary(String userId) async {
    await _runLoad(() async {
      final res = await _service.getSocialSummary(userId);
      _socialSummary = res.data;
    });
  }

  Future<void> loadReceivedRequests({int page = 1, int pageSize = 20}) async {
    await _runLoad(() async {
      final res =
          await _service.getReceivedRequests(page: page, pageSize: pageSize);
      _receivedRequests = res.data?.items ?? <FriendRequestModel>[];
    });
  }

  Future<void> loadSentRequests({int page = 1, int pageSize = 20}) async {
    await _runLoad(() async {
      final res =
          await _service.getSentRequests(page: page, pageSize: pageSize);
      _sentRequests = res.data?.items ?? <FriendRequestModel>[];
    });
  }

  Future<void> loadFollowers(
    String userId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    await _runLoad(() async {
      final res =
          await _service.getFollowers(userId, page: page, pageSize: pageSize);
      _followers = res.data?.items ?? <FollowModel>[];
    });
  }

  Future<void> loadFollowing(
    String userId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    await _runLoad(() async {
      final res =
          await _service.getFollowing(userId, page: page, pageSize: pageSize);
      _following = res.data?.items ?? <FollowModel>[];
    });
  }

  Future<void> loadBlockedUsers({int page = 1, int pageSize = 20}) async {
    await _runLoad(() async {
      final res =
          await _service.getBlockedUsers(page: page, pageSize: pageSize);
      _blockedUsers = res.data?.items ?? <BlockModel>[];
    });
  }

  Future<bool> sendFriendRequest(String receiverId) async {
    return _runAction(() async {
      await _service.sendFriendRequest(receiverId);
      await loadSentRequests();
    });
  }

  Future<bool> acceptRequest(String requestId) async {
    return _runAction(() async {
      await _service.acceptRequest(requestId);
      _receivedRequests = _receivedRequests
          .where((request) => request.id != requestId)
          .toList();
    });
  }

  Future<bool> declineRequest(String requestId) async {
    return _runAction(() async {
      await _service.declineRequest(requestId);
      _receivedRequests = _receivedRequests
          .where((request) => request.id != requestId)
          .toList();
    });
  }

  Future<bool> cancelRequest(String requestId) async {
    return _runAction(() async {
      await _service.cancelRequest(requestId);
      _sentRequests =
          _sentRequests.where((request) => request.id != requestId).toList();
    });
  }

  Future<bool> unfriend(String targetUserId) async {
    return _runAction(() async {
      await _service.unfriend(targetUserId);
      _friends = _friends
          .where((friendship) => friendship.friend.id != targetUserId)
          .toList();
    });
  }

  Future<bool> follow(String followeeId) async {
    return _runAction(() async {
      await _service.follow(followeeId);
    });
  }

  Future<bool> unfollow(String followeeId) async {
    return _runAction(() async {
      await _service.unfollow(followeeId);
      _following =
          _following.where((entry) => entry.user.id != followeeId).toList();
    });
  }

  Future<bool> blockUser(String blockedId) async {
    return _runAction(() async {
      await _service.blockUser(blockedId);
    });
  }

  Future<bool> unblockUser(String blockedId) async {
    return _runAction(() async {
      await _service.unblockUser(blockedId);
      _blockedUsers = _blockedUsers
          .where((entry) => entry.blockedUser.id != blockedId)
          .toList();
    });
  }
}
