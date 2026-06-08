class UserSettings {
  final String language;
  final String theme;
  final PrivacySettings privacySettings;
  final NotificationSettings notificationSettings;

  const UserSettings({
    this.language = 'en',
    this.theme = 'system',
    this.privacySettings = const PrivacySettings(),
    this.notificationSettings = const NotificationSettings(),
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    final privacy = json['privacySettings'] ?? json['PrivacySettings'];
    final notif = json['notificationSettings'] ?? json['NotificationSettings'];
    return UserSettings(
      language: (json['language'] ?? json['Language'] ?? 'en').toString(),
      theme: (json['theme'] ?? json['Theme'] ?? 'system').toString(),
      privacySettings: privacy != null
          ? PrivacySettings.fromJson(Map<String, dynamic>.from(privacy as Map))
          : const PrivacySettings(),
      notificationSettings: notif != null
          ? NotificationSettings.fromJson(Map<String, dynamic>.from(notif as Map))
          : const NotificationSettings(),
    );
  }

  Map<String, dynamic> toJson() => {
        'language': language,
        'theme': theme,
        'privacySettings': privacySettings.toJson(),
        'notificationSettings': notificationSettings.toJson(),
      };

  UserSettings copyWith({
    String? language,
    String? theme,
    PrivacySettings? privacySettings,
    NotificationSettings? notificationSettings,
  }) =>
      UserSettings(
        language: language ?? this.language,
        theme: theme ?? this.theme,
        privacySettings: privacySettings ?? this.privacySettings,
        notificationSettings: notificationSettings ?? this.notificationSettings,
      );
}

class NotificationSettings {
  final bool pushNotifications;
  final bool emailNotifications;
  final bool smsNotifications;
  final bool likes;
  final bool comments;
  final bool mentions;
  final bool newFollowers;
  final bool friendRequests;
  final bool messageRequests;
  final bool directMessages;

  const NotificationSettings({
    this.pushNotifications = true,
    this.emailNotifications = false,
    this.smsNotifications = false,
    this.likes = true,
    this.comments = true,
    this.mentions = true,
    this.newFollowers = false,
    this.friendRequests = true,
    this.messageRequests = true,
    this.directMessages = true,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    bool b(String key, String altKey, bool def) =>
        (json[key] ?? json[altKey] ?? def) as bool;
    return NotificationSettings(
      pushNotifications: b('pushNotifications', 'PushNotifications', true),
      emailNotifications: b('emailNotifications', 'EmailNotifications', false),
      smsNotifications: b('smsNotifications', 'SmsNotifications', false),
      likes: b('likes', 'Likes', true),
      comments: b('comments', 'Comments', true),
      mentions: b('mentions', 'Mentions', true),
      newFollowers: b('newFollowers', 'NewFollowers', false),
      friendRequests: b('friendRequests', 'FriendRequests', true),
      messageRequests: b('messageRequests', 'MessageRequests', true),
      directMessages: b('directMessages', 'DirectMessages', true),
    );
  }

  Map<String, dynamic> toJson() => {
        'pushNotifications': pushNotifications,
        'emailNotifications': emailNotifications,
        'smsNotifications': smsNotifications,
        'likes': likes,
        'comments': comments,
        'mentions': mentions,
        'newFollowers': newFollowers,
        'friendRequests': friendRequests,
        'messageRequests': messageRequests,
        'directMessages': directMessages,
      };

  NotificationSettings copyWith({
    bool? pushNotifications,
    bool? emailNotifications,
    bool? smsNotifications,
    bool? likes,
    bool? comments,
    bool? mentions,
    bool? newFollowers,
    bool? friendRequests,
    bool? messageRequests,
    bool? directMessages,
  }) =>
      NotificationSettings(
        pushNotifications: pushNotifications ?? this.pushNotifications,
        emailNotifications: emailNotifications ?? this.emailNotifications,
        smsNotifications: smsNotifications ?? this.smsNotifications,
        likes: likes ?? this.likes,
        comments: comments ?? this.comments,
        mentions: mentions ?? this.mentions,
        newFollowers: newFollowers ?? this.newFollowers,
        friendRequests: friendRequests ?? this.friendRequests,
        messageRequests: messageRequests ?? this.messageRequests,
        directMessages: directMessages ?? this.directMessages,
      );
}

class PrivacySettings {
  final String profileVisibility;
  final String whoCanSeeEmail;
  final String whoCanSeeFriends;
  final String whoCanSendFriendRequest;

  const PrivacySettings({
    this.profileVisibility = 'public',
    this.whoCanSeeEmail = 'friends',
    this.whoCanSeeFriends = 'friends',
    this.whoCanSendFriendRequest = 'everyone',
  });

  factory PrivacySettings.fromJson(Map<String, dynamic> json) => PrivacySettings(
        profileVisibility:
            (json['profileVisibility'] ?? json['ProfileVisibility'] ?? 'public').toString(),
        whoCanSeeEmail:
            (json['whoCanSeeEmail'] ?? json['WhoCanSeeEmail'] ?? 'friends').toString(),
        whoCanSeeFriends:
            (json['whoCanSeeFriends'] ?? json['WhoCanSeeFriends'] ?? 'friends').toString(),
        whoCanSendFriendRequest: (json['whoCanSendFriendRequest'] ??
                json['WhoCanSendFriendRequest'] ??
                'everyone')
            .toString(),
      );

  Map<String, dynamic> toJson() => {
        'profileVisibility': profileVisibility,
        'whoCanSeeEmail': whoCanSeeEmail,
        'whoCanSeeFriends': whoCanSeeFriends,
        'whoCanSendFriendRequest': whoCanSendFriendRequest,
      };

  PrivacySettings copyWith({
    String? profileVisibility,
    String? whoCanSeeEmail,
    String? whoCanSeeFriends,
    String? whoCanSendFriendRequest,
  }) =>
      PrivacySettings(
        profileVisibility: profileVisibility ?? this.profileVisibility,
        whoCanSeeEmail: whoCanSeeEmail ?? this.whoCanSeeEmail,
        whoCanSeeFriends: whoCanSeeFriends ?? this.whoCanSeeFriends,
        whoCanSendFriendRequest: whoCanSendFriendRequest ?? this.whoCanSendFriendRequest,
      );
}
