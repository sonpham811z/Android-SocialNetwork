import 'package:intl/intl.dart';

import '../utils/json_helpers.dart';

class UserProfile {
  final String id;
  final String name;
  final String handle;
  final String avatar;

  UserProfile({
    required this.id,
    required this.name,
    required this.handle,
    required this.avatar,
  });

  factory UserProfile.fromApi(Map<String, dynamic> json) {
    // Try to get display name from multiple possible fields
    String firstName = (json['firstName'] ?? '').toString().trim();
    String lastName = (json['lastName'] ?? '').toString().trim();
    String fullName = (json['fullName'] ?? '').toString().trim();
    String name = (json['name'] ?? '').toString().trim();

    // Build display name with priority
    String displayName = '';
    if (name.isNotEmpty) {
      displayName = name;
    } else if (fullName.isNotEmpty) {
      displayName = fullName;
    } else if (firstName.isNotEmpty || lastName.isNotEmpty) {
      displayName = '$firstName $lastName'.trim();
    }

    // Get username with priority
    String userName = (json['userName'] ??
            json['username'] ??
            json['UserName'] ??
            json['Username'] ??
            '')
        .toString()
        .trim();

    return UserProfile(
      id: asText(json['id']),
      name: displayName.isEmpty ? 'Unknown User' : displayName,
      handle: userName.isEmpty ? '@unknown' : '@$userName',
      avatar: asText(json['profilePictureUrl']),
    );
  }
}

class Comment {
  final String id;
  final UserProfile user;
  final String content;
  final String timestamp;

  Comment({
    required this.id,
    required this.user,
    required this.content,
    required this.timestamp,
  });

  factory Comment.fromApi(Map<String, dynamic> json) {
    return Comment(
      id: asText(json['id']),
      user: UserProfile.fromApi(asJsonMap(json['user']) ?? <String, dynamic>{}),
      content: asText(json['content']),
      timestamp: Post.formatTimestamp(asText(json['createdAt'])),
    );
  }
}

class Post {
  final String id;
  final String userId;
  final UserProfile user;
  final String content; // Caption của bài post
  final String timestamp;
  final String? image; // Ảnh (Optional)
  final String? audioUrl; // [NEW] Link file âm thanh (Optional)
  final List<double>? waveform; // [NEW] Sóng âm (Optional)
  final String? audioDuration; // [NEW] Thời lượng (Optional, vd: "0:45")
  final int likes;
  final int commentsCount;
  final bool isLikedByCurrentUser;
  final List<Comment>? commentsList;

  Post({
    required this.id,
    required this.userId,
    required this.user,
    required this.content,
    required this.timestamp,
    this.image,
    this.audioUrl, // [NEW]
    this.waveform, // [NEW]
    this.audioDuration, // [NEW]
    required this.likes,
    required this.commentsCount,
    this.isLikedByCurrentUser = false,
    this.commentsList,
  });

  factory Post.fromApi(Map<String, dynamic> json) {
    final commentsRaw = json['comments'];
    final comments = commentsRaw is List
        ? commentsRaw
            .whereType<Map>()
            .map((item) => Comment.fromApi(item.cast<String, dynamic>()))
            .toList()
        : <Comment>[];

    List<double>? waveform;
    final waveformRaw = json['waveform'];
    if (waveformRaw is List) {
      waveform = waveformRaw
          .map((item) => double.tryParse(item.toString()) ?? 0)
          .toList();
    }

    return Post(
      id: asText(json['id']),
      userId: asText(json['userId']),
      user: UserProfile.fromApi(asJsonMap(json['user']) ?? <String, dynamic>{}),
      content: asText(json['content']),
      timestamp: formatTimestamp(asText(json['createdAt'])),
      image: asText(json['imageUrl']).isEmpty ? null : asText(json['imageUrl']),
      audioUrl:
          asText(json['audioUrl']).isEmpty ? null : asText(json['audioUrl']),
      waveform: waveform,
      audioDuration: asText(json['audioDuration']).isEmpty
          ? null
          : asText(json['audioDuration']),
      likes: _toInt(json['likesCount']),
      commentsCount: _toInt(json['commentsCount']),
      isLikedByCurrentUser: _toBool(json['isLikedByCurrentUser']),
      commentsList: comments,
    );
  }

  Post copyWith({
    String? content,
    int? likes,
    int? commentsCount,
    bool? isLikedByCurrentUser,
    List<Comment>? commentsList,
  }) {
    return Post(
      id: id,
      userId: userId,
      user: user,
      content: content ?? this.content,
      timestamp: timestamp,
      image: image,
      audioUrl: audioUrl,
      waveform: waveform,
      audioDuration: audioDuration,
      likes: likes ?? this.likes,
      commentsCount: commentsCount ?? this.commentsCount,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
      commentsList: commentsList ?? this.commentsList,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    final normalized = (value ?? '').toString().toLowerCase();
    return normalized == 'true' || normalized == '1';
  }

  static String formatTimestamp(String value) {
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) {
      return 'Vừa xong';
    }

    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) {
      return 'Vừa xong';
    }
    if (diff.inHours < 1) {
      return '${diff.inMinutes} phút trước';
    }
    if (diff.inDays < 1) {
      return '${diff.inHours} giờ trước';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    }
    return DateFormat('dd/MM/yyyy').format(date);
  }
}

class Story {
  final String id;
  final UserProfile user;
  final String image;
  final bool isSeen;

  Story({
    required this.id,
    required this.user,
    required this.image,
    required this.isSeen,
  });
}

class FriendSuggestion {
  final String id;
  final UserProfile user;

  FriendSuggestion({
    required this.id,
    required this.user,
  });
}

// Mock Data
class MockData {
  static final currentUser = UserProfile(
    id: 'me',
    name: 'Nguyễn Văn A',
    handle: '@nguyenvana',
    avatar: 'https://i.pravatar.cc/150?img=1',
  );

  static final List<Story> stories = [
    Story(
      id: 's1',
      user: UserProfile(
        id: 'u1',
        name: 'Trần Thị B',
        handle: '@tranthib',
        avatar: 'https://i.pravatar.cc/150?img=5',
      ),
      image: 'https://picsum.photos/200/300?random=1',
      isSeen: false,
    ),
    Story(
      id: 's2',
      user: UserProfile(
        id: 'u2',
        name: 'Lê Văn C',
        handle: '@levanc',
        avatar: 'https://i.pravatar.cc/150?img=8',
      ),
      image: 'https://picsum.photos/200/300?random=2',
      isSeen: true,
    ),
    Story(
      id: 's3',
      user: UserProfile(
        id: 'u3',
        name: 'Phạm Thị D',
        handle: '@phamthid',
        avatar: 'https://i.pravatar.cc/150?img=10',
      ),
      image: 'https://picsum.photos/200/300?random=3',
      isSeen: false,
    ),
  ];

  static final List<Post> posts = [
    // Post 1: Ảnh bình thường
    Post(
      id: 'p1',
      userId: 'u2',
      user: UserProfile(
        id: 'u2',
        name: 'Minh Hiếu',
        handle: '@minhhieu',
        avatar: 'https://i.pravatar.cc/150?img=12',
      ),
      content: 'Hôm nay thời tiết đẹp quá! 🌞\nĐi cafe với bạn bè vui lắm 😊',
      timestamp: '2 giờ trước',
      image: 'https://picsum.photos/600/400?random=10',
      likes: 125,
      commentsCount: 8,
    ),

    // [NEW] Post 2: VOICE POST (Không có ảnh, có audio)
    Post(
      id: 'p_voice_1',
      userId: 'u_jack',
      user: UserProfile(
        id: 'u_jack',
        name: 'Jack 5 củ',
        handle: '@jack97',
        avatar: 'https://i.pravatar.cc/150?u=jack',
      ),
      content: 'Demo bài hát mới, anh em nghe thử nhé! 🎤🔥',
      timestamp: '5 phút trước',
      // Không có image
      audioUrl: 'dummy_url',
      audioDuration: '0:45',
      waveform: [
        0.3,
        0.5,
        0.8,
        0.4,
        0.6,
        0.9,
        0.5,
        0.3,
        0.7,
        0.4,
        0.6,
        0.8,
        0.5,
        0.9,
        0.3,
        0.6,
        0.8,
        0.4,
        0.7,
        0.2
      ],
      likes: 999,
      commentsCount: 200,
    ),

    // Post 3: Text only (Bình thường)
    Post(
      id: 'p2',
      userId: 'u6',
      user: UserProfile(
        id: 'u6',
        name: 'Hoàng Anh',
        handle: '@hoanganh',
        avatar: 'https://i.pravatar.cc/150?img=25',
      ),
      content: 'Vừa hoàn thành project lớn! 🎉',
      timestamp: '5 giờ trước',
      likes: 89,
      commentsCount: 12,
    ),

    // [NEW] Post 4: VOICE POST
    Post(
      id: 'p_voice_2',
      userId: 'u_tung',
      user: UserProfile(
        id: 'u_tung',
        name: 'Sơn Tùng',
        handle: '@sontungmtp',
        avatar: 'https://i.pravatar.cc/150?u=tung',
      ),
      content: 'Tâm sự đêm khuya... 🌙',
      timestamp: '1 giờ trước',
      audioUrl: 'dummy_url_2',
      audioDuration: '1:30',
      waveform: [
        0.2,
        0.4,
        0.6,
        0.8,
        1.0,
        0.8,
        0.6,
        0.4,
        0.2,
        0.1,
        0.3,
        0.5,
        0.7,
        0.9,
        0.6,
        0.4,
        0.2,
        0.5,
        0.8,
        0.3
      ],
      likes: 5000,
      commentsCount: 1500,
    ),
  ];

  static final List<FriendSuggestion> suggestions = [
    FriendSuggestion(
      id: 'fs1',
      user: UserProfile(
        id: 'u8',
        name: 'Nguyễn Thị Lan',
        handle: '@nguyenlan',
        avatar: 'https://i.pravatar.cc/150?img=35',
      ),
    ),
    FriendSuggestion(
      id: 'fs2',
      user: UserProfile(
        id: 'u9',
        name: 'Trần Văn Bảo',
        handle: '@tranvanbao',
        avatar: 'https://i.pravatar.cc/150?img=40',
      ),
    ),
    FriendSuggestion(
      id: 'fs3',
      user: UserProfile(
        id: 'u10',
        name: 'Lê Hoàng Nam',
        handle: '@lehoangnam',
        avatar: 'https://i.pravatar.cc/150?img=45',
      ),
    ),
  ];
}
