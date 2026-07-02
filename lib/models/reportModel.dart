import '../utils/json_helpers.dart';

class PostReportItem {
  final String id;
  final String postId;
  final String reason;
  final String status; // Pending | Dismissed | ActionTaken
  final DateTime createdAt;
  final String reporterId;
  final String? reporterName;
  // Snapshot bài bị báo cáo
  final String postContent;
  final String postType;
  final String? postImageUrl;
  final String postOwnerId;
  final String? postOwnerName;
  final bool postIsHidden;
  final bool postIsDeleted;

  const PostReportItem({
    required this.id,
    required this.postId,
    required this.reason,
    required this.status,
    required this.createdAt,
    required this.reporterId,
    this.reporterName,
    required this.postContent,
    required this.postType,
    this.postImageUrl,
    required this.postOwnerId,
    this.postOwnerName,
    required this.postIsHidden,
    required this.postIsDeleted,
  });

  factory PostReportItem.fromJson(Map<String, dynamic> json) {
    return PostReportItem(
      id: asText(json['id'] ?? json['Id']),
      postId: asText(json['postId'] ?? json['PostId']),
      reason: asText(json['reason'] ?? json['Reason']),
      status: asText(json['status'] ?? json['Status']),
      createdAt: DateTime.tryParse(
              asText(json['createdAt'] ?? json['CreatedAt'])) ??
          DateTime.now(),
      reporterId: asText(json['reporterId'] ?? json['ReporterId']),
      reporterName: (json['reporterName'] ?? json['ReporterName'])?.toString(),
      postContent: asText(json['postContent'] ?? json['PostContent']),
      postType: asText(json['postType'] ?? json['PostType']),
      postImageUrl: (json['postImageUrl'] ?? json['PostImageUrl'])?.toString(),
      postOwnerId: asText(json['postOwnerId'] ?? json['PostOwnerId']),
      postOwnerName:
          (json['postOwnerName'] ?? json['PostOwnerName'])?.toString(),
      postIsHidden: asBool(json['postIsHidden'] ?? json['PostIsHidden']),
      postIsDeleted: asBool(json['postIsDeleted'] ?? json['PostIsDeleted']),
    );
  }
}
