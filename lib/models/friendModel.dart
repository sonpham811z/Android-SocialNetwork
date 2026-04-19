import '../utils/json_helpers.dart';

class FriendApiResponse<T> {
  final bool success;
  final String message;
  final T? data;

  FriendApiResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory FriendApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? raw) fromData,
  ) {
    return FriendApiResponse<T>(
      success: asBool(json['success'] ?? json['Success']),
      message: asText(json['message'] ?? json['Message']),
      data: json['data'] != null || json['Data'] != null
          ? fromData(json['data'] ?? json['Data'])
          : null,
    );
  }
}

class PaginatedResponse<T> {
  final List<T> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final bool hasNext;

  PaginatedResponse({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.hasNext,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> itemJson) fromItem,
  ) {
    final rawItems =
        asJsonList(json['items'] ?? json['Items']) ?? const <dynamic>[];
    final parsedItems = rawItems
        .map((item) => fromItem(asJsonMap(item) ?? <String, dynamic>{}))
        .toList();

    final page = asInt(json['page'] ?? json['Page'], fallback: 1);
    final pageSize = asInt(json['pageSize'] ?? json['PageSize'], fallback: 20);
    final totalCount = asInt(json['totalCount'] ?? json['TotalCount']);
    final computedHasNext = page * pageSize < totalCount;

    return PaginatedResponse<T>(
      items: parsedItems,
      page: page,
      pageSize: pageSize,
      totalCount: totalCount,
      hasNext:
          asBool(json['hasNext'] ?? json['HasNext'], fallback: computedHasNext),
    );
  }
}

class UserLite {
  final String id;
  final String name;
  final String userName;
  final String? avatarUrl;

  UserLite({
    required this.id,
    required this.name,
    required this.userName,
    required this.avatarUrl,
  });

  factory UserLite.fromJson(Map<String, dynamic> json) {
    return UserLite(
      id: asText(json['id'] ?? json['Id']),
      name: asText(
        json['name'] ?? json['Name'] ?? json['fullName'] ?? json['FullName'],
      ),
      userName: asText(
        json['userName'] ??
            json['UserName'] ??
            json['username'] ??
            json['Username'],
      ),
      avatarUrl: (json['avatarUrl'] ??
              json['AvatarUrl'] ??
              json['profilePictureUrl'] ??
              json['ProfilePictureUrl'])
          ?.toString(),
    );
  }
}

class FriendshipModel {
  final String id;
  final UserLite friend;
  final DateTime createdAt;

  FriendshipModel({
    required this.id,
    required this.friend,
    required this.createdAt,
  });

  factory FriendshipModel.fromJson(Map<String, dynamic> json) {
    return FriendshipModel(
      id: asText(json['id'] ?? json['Id']),
      friend: UserLite.fromJson(
          asJsonMap(json['friend'] ?? json['Friend']) ?? <String, dynamic>{}),
      createdAt: DateTime.tryParse(
            (json['createdAt'] ?? json['CreatedAt'] ?? '').toString(),
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class FriendRequestModel {
  final String id;
  final UserLite sender;
  final UserLite receiver;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  FriendRequestModel({
    required this.id,
    required this.sender,
    required this.receiver,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FriendRequestModel.fromJson(Map<String, dynamic> json) {
    return FriendRequestModel(
      id: asText(json['id'] ?? json['Id']),
      sender: UserLite.fromJson(
          asJsonMap(json['sender'] ?? json['Sender']) ?? <String, dynamic>{}),
      receiver: UserLite.fromJson(
          asJsonMap(json['receiver'] ?? json['Receiver']) ??
              <String, dynamic>{}),
      status: asText(json['status'] ?? json['Status']),
      createdAt: DateTime.tryParse(
            (json['createdAt'] ?? json['CreatedAt'] ?? '').toString(),
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse(
        (json['updatedAt'] ?? json['UpdatedAt'] ?? '').toString(),
      ),
    );
  }
}

class FollowModel {
  final String id;
  final UserLite user;
  final DateTime createdAt;

  FollowModel({
    required this.id,
    required this.user,
    required this.createdAt,
  });

  factory FollowModel.fromJson(Map<String, dynamic> json) {
    return FollowModel(
      id: asText(json['id'] ?? json['Id']),
      user: UserLite.fromJson(
          asJsonMap(json['user'] ?? json['User']) ?? <String, dynamic>{}),
      createdAt: DateTime.tryParse(
            (json['createdAt'] ?? json['CreatedAt'] ?? '').toString(),
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class BlockModel {
  final String id;
  final UserLite blockedUser;
  final DateTime createdAt;

  BlockModel({
    required this.id,
    required this.blockedUser,
    required this.createdAt,
  });

  factory BlockModel.fromJson(Map<String, dynamic> json) {
    return BlockModel(
      id: asText(json['id'] ?? json['Id']),
      blockedUser: UserLite.fromJson(
          asJsonMap(json['blockedUser'] ?? json['BlockedUser']) ??
              <String, dynamic>{}),
      createdAt: DateTime.tryParse(
            (json['createdAt'] ?? json['CreatedAt'] ?? '').toString(),
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class SocialSummaryModel {
  final String userId;
  final int friendsCount;
  final int followersCount;
  final int followingCount;
  final bool isFriend;
  final bool isFollowing;
  final bool isBlocked;
  final bool hasPendingRequest;

  SocialSummaryModel({
    required this.userId,
    required this.friendsCount,
    required this.followersCount,
    required this.followingCount,
    required this.isFriend,
    required this.isFollowing,
    required this.isBlocked,
    required this.hasPendingRequest,
  });

  factory SocialSummaryModel.fromJson(Map<String, dynamic> json) {
    return SocialSummaryModel(
      userId: asText(json['userId'] ?? json['UserId']),
      friendsCount: asInt(json['friendsCount'] ?? json['FriendsCount']),
      followersCount: asInt(json['followersCount'] ?? json['FollowersCount']),
      followingCount: asInt(json['followingCount'] ?? json['FollowingCount']),
      isFriend: asBool(json['isFriend'] ?? json['IsFriend']),
      isFollowing: asBool(json['isFollowing'] ?? json['IsFollowing']),
      isBlocked: asBool(json['isBlocked'] ?? json['IsBlocked']),
      hasPendingRequest:
          asBool(json['hasPendingRequest'] ?? json['HasPendingRequest']),
    );
  }
}
