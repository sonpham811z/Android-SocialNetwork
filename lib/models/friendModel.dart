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
      success: (json['success'] ?? json['Success'] ?? false) as bool,
      message: (json['message'] ?? json['Message'] ?? '') as String,
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
    final rawItems = (json['items'] ?? json['Items'] ?? []) as List<dynamic>;
    final parsedItems =
        rawItems.map((item) => fromItem(item as Map<String, dynamic>)).toList();

    final page = (json['page'] ?? json['Page'] ?? 1) as int;
    final pageSize = (json['pageSize'] ?? json['PageSize'] ?? 20) as int;
    final totalCount = (json['totalCount'] ?? json['TotalCount'] ?? 0) as int;
    final computedHasNext = page * pageSize < totalCount;

    return PaginatedResponse<T>(
      items: parsedItems,
      page: page,
      pageSize: pageSize,
      totalCount: totalCount,
      hasNext: (json['hasNext'] ?? json['HasNext'] ?? computedHasNext) as bool,
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
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      name: (json['name'] ??
              json['Name'] ??
              json['fullName'] ??
              json['FullName'] ??
              '')
          .toString(),
      userName: (json['userName'] ??
              json['UserName'] ??
              json['username'] ??
              json['Username'] ??
              '')
          .toString(),
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
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      friend: UserLite.fromJson(
        (json['friend'] ?? json['Friend'] ?? <String, dynamic>{})
            as Map<String, dynamic>,
      ),
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
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      sender: UserLite.fromJson(
        (json['sender'] ?? json['Sender'] ?? <String, dynamic>{})
            as Map<String, dynamic>,
      ),
      receiver: UserLite.fromJson(
        (json['receiver'] ?? json['Receiver'] ?? <String, dynamic>{})
            as Map<String, dynamic>,
      ),
      status: (json['status'] ?? json['Status'] ?? '').toString(),
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
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      user: UserLite.fromJson(
        (json['user'] ?? json['User'] ?? <String, dynamic>{})
            as Map<String, dynamic>,
      ),
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
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      blockedUser: UserLite.fromJson(
        (json['blockedUser'] ?? json['BlockedUser'] ?? <String, dynamic>{})
            as Map<String, dynamic>,
      ),
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
      userId: (json['userId'] ?? json['UserId'] ?? '').toString(),
      friendsCount: (json['friendsCount'] ?? json['FriendsCount'] ?? 0) as int,
      followersCount:
          (json['followersCount'] ?? json['FollowersCount'] ?? 0) as int,
      followingCount:
          (json['followingCount'] ?? json['FollowingCount'] ?? 0) as int,
      isFriend: (json['isFriend'] ?? json['IsFriend'] ?? false) as bool,
      isFollowing:
          (json['isFollowing'] ?? json['IsFollowing'] ?? false) as bool,
      isBlocked: (json['isBlocked'] ?? json['IsBlocked'] ?? false) as bool,
      hasPendingRequest: (json['hasPendingRequest'] ??
          json['HasPendingRequest'] ??
          false) as bool,
    );
  }
}
