import 'package:get/get.dart';

class ChatType {
  int? id;
  String? type;
  String? name;
  String? groupImageUrl;
  String? createdAt;
  String? lastMessage;
  int? unreadCount;
  List<Members>? members;

  RxBool isPinned = false.obs;

  int? pinOrder;
  String? lastMessageAt;
  String? lastMessageContent;
  String? lastMessageType;
  int? lastSenderId;
  String? lastSenderName;
  bool? pinned;
  RxBool muted = false.obs;

  ChatType(
      {this.id,
        this.type,
        this.name,
        this.groupImageUrl,
        this.createdAt,
        this.lastMessage,
        this.unreadCount,
        this.members,
        this.pinOrder,
        this.lastMessageAt,
        this.lastMessageContent,
        this.lastMessageType,
        this.lastSenderId,
        this.lastSenderName,
        this.pinned,
        // this.muted,
      });

  ChatType.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    type = json['type'];
    name = json['name'];
    groupImageUrl = json['groupImageUrl'];
    createdAt = json['createdAt'];
    lastMessage = json['lastMessage'];
    unreadCount = json['unreadCount'];
    pinOrder = json['pinOrder'];
    lastMessageAt = json['lastMessageAt'];
    lastMessageContent = json['lastMessageContent'];
    lastMessageType = json['lastMessageType'];
    lastSenderId = json['lastSenderId'];
    lastSenderName = json['lastSenderName'];
    pinned = json['pinned'];

    muted = (json["muted"] == true).obs;


    if (json['members'] != null) {
      members = <Members>[];
      json['members'].forEach((v) {
        members!.add(new Members.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['type'] = type;
    data['name'] = name;
    data['groupImageUrl'] = groupImageUrl;
    data['createdAt'] = createdAt;
    data['lastMessage'] = lastMessage;
    data['unreadCount'] = unreadCount;
    data['pinOrder'] = pinOrder;
    data['lastMessageAt'] = lastMessageAt;
    data['lastMessageContent'] = lastMessageContent;
    data['lastMessageType'] = lastMessageType;
    data['lastSenderId'] = lastSenderId;
    data['lastSenderName'] = lastSenderName;
    data['pinned'] = pinned;
    data['muted'] = muted.value;


    if (members != null) {
      data['members'] = members!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Members {
  int? id;
  int? userId;
  String? firstName;
  String? lastName;
  String? username;
  String? profileImageUrl;
  String? role;
  bool? isOnline;
  String? joinedAt;

  Members(
      {this.id,
        this.userId,
        this.firstName,
        this.lastName,
        this.username,
        this.profileImageUrl,
        this.role,
        this.isOnline,
        this.joinedAt});

  Members.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['userId'];
    firstName = json['firstName'];
    lastName = json['lastName'];
    username = json['username'];
    profileImageUrl = json['profileImageUrl'];
    role = json['role'];
    isOnline = json['isOnline'];
    joinedAt = json['joinedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['userId'] = userId;
    data['firstName'] = firstName;
    data['lastName'] = lastName;
    data['username'] = username;
    data['profileImageUrl'] = profileImageUrl;
    data['role'] = role;
    data['isOnline'] = isOnline;
    data['joinedAt'] = joinedAt;
    return data;
  }
}
