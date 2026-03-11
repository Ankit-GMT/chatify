import 'package:get/get.dart';

class ChatType {
  int? id;
  String? type;
  String? name;
  String? groupImageUrl;
  String? backgroundImageUrl;
  String? createdAt;
  String? lastMessage;
  // int? unreadCount;
  List<Members>? members;
  //
  int? pinOrder;
  RxInt unreadCount = 0.obs;
  RxString lastMessageAt = ''.obs;
  RxString lastMessageContent = ''.obs;
  //
  RxInt lastMessageId = 0.obs;
  RxBool lastMessageIsRead = false.obs;
  RxBool lastMessageIsDelivered = false.obs;
  //
  RxBool isBlockedByMe = false.obs;
  RxBool isBlockedByThem = false.obs;
  RxBool isBlocked = false.obs;
  //
  String? lastMessageType;
  int? lastSenderId;
  String? lastSenderName;
  RxBool pinned = false.obs;
  RxBool muted = false.obs;
  RxBool locked = false.obs;

  ChatType(
      {this.id,
        this.type,
        this.name,
        this.groupImageUrl,
        this.backgroundImageUrl,
        this.createdAt,
        this.lastMessage,
        // this.unreadCount,
        this.members,
        this.pinOrder,
        int? unreadCount,
        String? lastMessageAt,
        String? lastMessageContent,
        int? lastMessageId,
        bool? lastMessageIsRead,
        bool? lastMessageIsDelivered,
        bool? isBlockedByMe,
        bool? isBlockedByThem,
        bool? isBlocked,
        this.lastMessageType,
        this.lastSenderId,
        this.lastSenderName,
        // this.pinned,
        // this.muted,
        // this.locked,
      }){
    this.unreadCount.value = unreadCount ?? 0;
    this.lastMessageAt.value = lastMessageAt ?? '';
    this.lastMessageContent.value = lastMessageContent ?? '';

    this.lastMessageId.value = lastMessageId ?? 0;
    this.lastMessageIsRead.value = lastMessageIsRead ?? false;
    this.lastMessageIsDelivered.value = lastMessageIsDelivered ?? false;

    this.isBlockedByMe.value = isBlockedByMe ?? false;
    this.isBlockedByThem.value = isBlockedByThem ?? false;
    this.isBlocked.value = isBlocked ?? false;
  }

  ChatType.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    type = json['type'];
    name = json['name'];
    groupImageUrl = json['groupImageUrl'];
    backgroundImageUrl = json['backgroundImageUrl'];
    createdAt = json['createdAt'];
    lastMessage = json['lastMessage'];
    // unreadCount = (json['unreadCount'] as int).obs;
    pinOrder = json['pinOrder'];
    unreadCount = (json['unreadCount'] as int? ?? 0).obs;
    lastMessageAt = (json['lastMessageAt'] as String? ?? '').obs;
    lastMessageContent = (json['lastMessageContent']as String? ?? '').obs;
    lastMessageId = (json['lastMessageId'] as int? ?? 0).obs;
    lastMessageIsRead = (json['lastMessageIsRead'] == true).obs;
    lastMessageIsDelivered = (json['lastMessageIsDelivered'] == true).obs;
    lastSenderId = json['lastSenderId'];
    lastSenderName = json['lastSenderName'];
    pinned = (json['pinned'] == true).obs;

    muted = (json["muted"] == true).obs;
    locked = (json["locked"] == true).obs;

    isBlockedByMe = (json['isBlockedByMe'] == true).obs;
    isBlockedByThem = (json['isBlockedByThem'] == true).obs;
    isBlocked = (json['isBlocked'] == true).obs;


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
    data['backgroundImageUrl'] = backgroundImageUrl;
    data['createdAt'] = createdAt;
    data['lastMessage'] = lastMessage;
    data['unreadCount'] = unreadCount.value;
    data['pinOrder'] = pinOrder;
    data['lastMessageAt'] = lastMessageAt.value;
    data['lastMessageContent'] = lastMessageContent.value;
    data['lastMessageId'] = lastMessageId.value;
    data['lastMessageIsRead'] = lastMessageIsRead.value;
    data['lastMessageIsDelivered'] = lastMessageIsDelivered.value;
    data['lastMessageType'] = lastMessageType;
    data['lastSenderId'] = lastSenderId;
    data['lastSenderName'] = lastSenderName;
    data['pinned'] = pinned.value;
    data['muted'] = muted.value;
    data['locked'] = locked.value;
    data['isBlockedByMe'] = isBlockedByMe.value;
    data['isBlockedByThem'] = isBlockedByThem.value;
    data['isBlocked'] = isBlocked.value;


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
  int? privateChatId;


  Members(
      {this.id,
        this.userId,
        this.firstName,
        this.lastName,
        this.username,
        this.profileImageUrl,
        this.role,
        this.isOnline,
        this.joinedAt,
        this.privateChatId,
      });

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
    privateChatId = json['privateChatId'];
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
    data['privateChatId'] = privateChatId;
    return data;
  }
}
