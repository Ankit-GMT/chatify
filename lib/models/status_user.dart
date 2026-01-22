class Status {
  final int id;
  final String type;
  final String? mediaUrl;
  final String caption;
  final DateTime createdAt;
  final bool viewed;
  final bool isMine;

  final String? backgroundColor;
  final String? font;
  final int? viewCount;
  final int? replyCount;

  Status({
    required this.id,
    required this.type,
    this.mediaUrl,
    required this.caption,
    required this.createdAt,
    required this.viewed,
    required this.isMine,
    this.backgroundColor,
    this.font,
    this.viewCount,
    this.replyCount,
  });
}


class StatusUser {
  final String userId;
  final String firstName;
  final String lastName;
  final String? profilePic;
  final bool isOnline;
  final List<Status> statuses;

  StatusUser({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.profilePic,
    required this.statuses,
    required this.isOnline,
  });
}

class StatusViewer {
  final int id;
  final int userId;
  final String name;
  final String username;
  final String? profileImage;
  final DateTime viewedAt;

  StatusViewer({
    required this.id,
    required this.userId,
    required this.name,
    required this.username,
    required this.profileImage,
    required this.viewedAt,
  });

  factory StatusViewer.fromJson(Map<String, dynamic> json) {
    return StatusViewer(
      id: json['id'],
      userId: json['userId'],
      name: "${json['firstName']} ${json['lastName']}",
      username: json['username'],
      profileImage: json['profileImageUrl'],
      viewedAt: DateTime.parse(json['viewedAt']),
    );
  }
}

class ScheduledStatus {
  final int id;
  final String type;
  final String content;
  final String mediaUrl;
  final DateTime scheduledAt;
  final String state;
  final DateTime createdAt;
  final DateTime? postedAt;
  final int? postedStatusId;

  ScheduledStatus({
    required this.id,
    required this.type,
    required this.content,
    required this.mediaUrl,
    required this.scheduledAt,
    required this.state,
    required this.createdAt,
    this.postedAt,
    this.postedStatusId,
  });

  factory ScheduledStatus.fromJson(Map<String, dynamic> json) {
    return ScheduledStatus(
      id: json['id'],
      type: json['type'],
      content: json['content'] ?? '',
      mediaUrl: json['mediaUrl'],
      scheduledAt: DateTime.parse(json['scheduledAt']),
      state: json['state'],
      createdAt: DateTime.parse(json['createdAt']),
      postedAt:
      json['postedAt'] != null ? DateTime.parse(json['postedAt']) : null,
      postedStatusId: json['postedStatusId'],
    );
  }

  bool get isScheduled => state == 'SCHEDULED';
}

