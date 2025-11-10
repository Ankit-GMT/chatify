import 'package:get/get.dart';

class ChatType {
  int? id;
  String? type;
  String? name;
  String? groupImageUrl;
  String? createdAt;
  Null? lastMessage;
  int? unreadCount;
  List<Members>? members;

  RxBool isPinned = false.obs;

  ChatType(
      {this.id,
        this.type,
        this.name,
        this.groupImageUrl,
        this.createdAt,
        this.lastMessage,
        this.unreadCount,
        this.members});

  ChatType.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    type = json['type'];
    name = json['name'];
    groupImageUrl = json['groupImageUrl'];
    createdAt = json['createdAt'];
    lastMessage = json['lastMessage'];
    unreadCount = json['unreadCount'];
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
