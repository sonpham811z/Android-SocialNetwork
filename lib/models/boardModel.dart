import '../utils/json_helpers.dart';

class BoardPost {
  final String id;
  final String tag;
  final String content;
  final bool isAnonymous;
  final String? authorId;
  final String? authorName;
  final String? authorAvatar;
  final int upvotesCount;
  final int downvotesCount;
  final int commentsCount;
  final int netVotes;
  final String? currentUserVote; // "up" | "down" | null
  final DateTime createdAt;
  final String timeAgo;

  const BoardPost({
    required this.id,
    required this.tag,
    required this.content,
    required this.isAnonymous,
    this.authorId,
    this.authorName,
    this.authorAvatar,
    required this.upvotesCount,
    required this.downvotesCount,
    required this.commentsCount,
    required this.netVotes,
    this.currentUserVote,
    required this.createdAt,
    required this.timeAgo,
  });

  factory BoardPost.fromJson(Map<String, dynamic> json) {
    return BoardPost(
      id:             asText(json['id'] ?? json['Id']),
      tag:            asText(json['tag'] ?? json['Tag']),
      content:        asText(json['content'] ?? json['Content']),
      isAnonymous:    asBool(json['isAnonymous'] ?? json['IsAnonymous']),
      authorId:       (json['authorId'] ?? json['AuthorId'])?.toString(),
      authorName:     (json['authorName'] ?? json['AuthorName'])?.toString(),
      authorAvatar:   (json['authorAvatar'] ?? json['AuthorAvatar'])?.toString(),
      upvotesCount:   asInt(json['upvotesCount'] ?? json['UpvotesCount']),
      downvotesCount: asInt(json['downvotesCount'] ?? json['DownvotesCount']),
      commentsCount:  asInt(json['commentsCount'] ?? json['CommentsCount']),
      netVotes:       asInt(json['netVotes'] ?? json['NetVotes']),
      currentUserVote: (json['currentUserVote'] ?? json['CurrentUserVote'])?.toString(),
      createdAt: DateTime.tryParse(
            asText(json['createdAt'] ?? json['CreatedAt'])) ??
          DateTime.now(),
      timeAgo: asText(json['timeAgo'] ?? json['TimeAgo']),
    );
  }

  BoardPost copyWith({
    int? upvotesCount,
    int? downvotesCount,
    int? commentsCount,
    int? netVotes,
    String? currentUserVote,
    bool clearVote = false,
  }) {
    return BoardPost(
      id:             id,
      tag:            tag,
      content:        content,
      isAnonymous:    isAnonymous,
      authorId:       authorId,
      authorName:     authorName,
      authorAvatar:   authorAvatar,
      upvotesCount:   upvotesCount ?? this.upvotesCount,
      downvotesCount: downvotesCount ?? this.downvotesCount,
      commentsCount:  commentsCount ?? this.commentsCount,
      netVotes:       netVotes ?? this.netVotes,
      currentUserVote: clearVote ? null : (currentUserVote ?? this.currentUserVote),
      createdAt:      createdAt,
      timeAgo:        timeAgo,
    );
  }
}

class BoardComment {
  final String id;
  final String boardPostId;
  final bool isAnonymous;
  final String? authorId;
  final String? authorName;
  final String? authorAvatar;
  final String content;
  final DateTime createdAt;
  final String timeAgo;
  final bool isMine;

  const BoardComment({
    required this.id,
    required this.boardPostId,
    required this.isAnonymous,
    this.authorId,
    this.authorName,
    this.authorAvatar,
    required this.content,
    required this.createdAt,
    required this.timeAgo,
    this.isMine = false,
  });

  factory BoardComment.fromJson(Map<String, dynamic> json) {
    return BoardComment(
      id:           asText(json['id'] ?? json['Id']),
      boardPostId:  asText(json['boardPostId'] ?? json['BoardPostId']),
      isAnonymous:  asBool(json['isAnonymous'] ?? json['IsAnonymous']),
      authorId:     (json['authorId'] ?? json['AuthorId'])?.toString(),
      authorName:   (json['authorName'] ?? json['AuthorName'])?.toString(),
      authorAvatar: (json['authorAvatar'] ?? json['AuthorAvatar'])?.toString(),
      content:      asText(json['content'] ?? json['Content']),
      createdAt: DateTime.tryParse(
            asText(json['createdAt'] ?? json['CreatedAt'])) ??
          DateTime.now(),
      timeAgo:      asText(json['timeAgo'] ?? json['TimeAgo']),
      isMine:       asBool(json['isMine'] ?? json['IsMine']),
    );
  }
}
