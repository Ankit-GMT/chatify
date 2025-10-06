import 'package:chatify/models/chat_type.dart';

class ContactModel {
  String? phoneNumber;
  bool? registered;
  int? userId;
  String? firstName;
  String? lastName;
  String? profileImageUrl;
  ChatType? chat;

  ContactModel(
      {this.phoneNumber,
        this.registered,
        this.userId,
        this.firstName,
        this.lastName,
        this.profileImageUrl,
        this.chat});

  ContactModel.fromJson(Map<String, dynamic> json) {
    phoneNumber = json['phoneNumber'];
    registered = json['registered'];
    userId = json['userId'];
    firstName = json['firstName'];
    lastName = json['lastName'];
    profileImageUrl = json['profileImageUrl'];
    chat = json['chat'] != null ? ChatType.fromJson(json['chat']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['phoneNumber'] = phoneNumber;
    data['registered'] = registered;
    data['userId'] = userId;
    data['firstName'] = firstName;
    data['lastName'] = lastName;
    data['profileImageUrl'] = profileImageUrl;
    if (chat != null) {
      data['chat'] = chat!.toJson();
    }
    return data;
  }
}

// class Chat {
//   int? id;
//   String? type;
//   Null? name;
//   Null? groupImageUrl;
//   String? createdAt;
//   Null? lastMessage;
//   int? unreadCount;
//   List<Members>? members;
//
//   Chat(
//       {this.id,
//         this.type,
//         this.name,
//         this.groupImageUrl,
//         this.createdAt,
//         this.lastMessage,
//         this.unreadCount,
//         this.members});
//
//   Chat.fromJson(Map<String, dynamic> json) {
//     id = json['id'];
//     type = json['type'];
//     name = json['name'];
//     groupImageUrl = json['groupImageUrl'];
//     createdAt = json['createdAt'];
//     lastMessage = json['lastMessage'];
//     unreadCount = json['unreadCount'];
//     if (json['members'] != null) {
//       members = <Members>[];
//       json['members'].forEach((v) {
//         members!.add(new Members.fromJson(v));
//       });
//     }
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['id'] = this.id;
//     data['type'] = this.type;
//     data['name'] = this.name;
//     data['groupImageUrl'] = this.groupImageUrl;
//     data['createdAt'] = this.createdAt;
//     data['lastMessage'] = this.lastMessage;
//     data['unreadCount'] = this.unreadCount;
//     if (this.members != null) {
//       data['members'] = this.members!.map((v) => v.toJson()).toList();
//     }
//     return data;
//   }
// }
//
// class Members {
//   int? id;
//   int? userId;
//   String? firstName;
//   String? lastName;
//   String? username;
//   String? profileImageUrl;
//   String? role;
//   Null? isOnline;
//   String? joinedAt;
//
//   Members(
//       {this.id,
//         this.userId,
//         this.firstName,
//         this.lastName,
//         this.username,
//         this.profileImageUrl,
//         this.role,
//         this.isOnline,
//         this.joinedAt});
//
//   Members.fromJson(Map<String, dynamic> json) {
//     id = json['id'];
//     userId = json['userId'];
//     firstName = json['firstName'];
//     lastName = json['lastName'];
//     username = json['username'];
//     profileImageUrl = json['profileImageUrl'];
//     role = json['role'];
//     isOnline = json['isOnline'];
//     joinedAt = json['joinedAt'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['id'] = this.id;
//     data['userId'] = this.userId;
//     data['firstName'] = this.firstName;
//     data['lastName'] = this.lastName;
//     data['username'] = this.username;
//     data['profileImageUrl'] = this.profileImageUrl;
//     data['role'] = this.role;
//     data['isOnline'] = this.isOnline;
//     data['joinedAt'] = this.joinedAt;
//     return data;
//   }
// }