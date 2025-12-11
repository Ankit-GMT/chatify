class CallHistory {
  final int id;
  final String channelId;
  final UserSummary caller;
  final UserSummary? receiver;
  final List<UserSummary>? participants;
  final String callType;
  final bool isGroupCall;
  final String status;
  final DateTime startTime;
  final DateTime? endTime;
  final int? durationSeconds;
  final String formattedDuration;
  final DateTime createdAt;
  final int? groupId;
  final String? groupName;
  final String? groupImageUrl;

  CallHistory({
    required this.id,
    required this.channelId,
    required this.caller,
    this.receiver,
    this.participants,
    required this.callType,
    required this.isGroupCall,
    required this.status,
    required this.startTime,
    this.endTime,
    this.durationSeconds,
    required this.formattedDuration,
    required this.createdAt,
    this.groupId,
    this.groupName,
    this.groupImageUrl,
  });

  factory CallHistory.fromJson(Map<String, dynamic> json) {
    return CallHistory(
      id: json['id'],
      channelId: json['channelId'],
      caller: UserSummary.fromJson(json['caller']),
      receiver: json['receiver'] != null
          ? UserSummary.fromJson(json['receiver'])
          : null,
      participants: json['participants'] != null
          ? (json['participants'] as List)
          .map((p) => UserSummary.fromJson(p))
          .toList()
          : null,
      callType: json['callType'],
      isGroupCall: json['isGroupCall'],
      status: json['status'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'])
          : null,
      durationSeconds: json['durationSeconds'],
      formattedDuration: json['formattedDuration'],
      createdAt: DateTime.parse(json['createdAt']),
      groupId: json['groupId'],
      groupName: json['groupName'],
      groupImageUrl: json['groupImageUrl'],
    );
  }
}

class UserSummary {
  final int id;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? profileImageUrl;
  final bool isOnline;

  UserSummary({
    required this.id,
    required this.username,
    this.firstName,
    this.lastName,
    this.profileImageUrl,
    required this.isOnline,
  });

  factory UserSummary.fromJson(Map<String, dynamic> json) {
    return UserSummary(
      id: json['id'],
      username: json['username'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      profileImageUrl: json['profileImageUrl'],
      isOnline: json['isOnline'] ?? false,
    );
  }
}