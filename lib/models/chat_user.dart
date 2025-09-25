class ChatUser {
  int? id;
  String? firstName;
  String? lastName;
  String? username;
  String? about;
  String? email;
  String? countryCode;
  String? phoneNumber;
  String? profileImageUrl;
  bool? isOnline;
  String? dateOfBirth;

  ChatUser(
      {this.id,
        this.firstName,
        this.lastName,
        this.username,
        this.about,
        this.email,
        this.countryCode,
        this.phoneNumber,
        this.profileImageUrl,
        this.isOnline,
        this.dateOfBirth});

  ChatUser.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    firstName = json['firstName'] ?? '';
    lastName = json['lastName'] ?? '';
    username = json['username'] ?? '';
    about = json['about'] ?? '';
    email = json['email'] ?? '';
    countryCode = json['countryCode'] ?? '';
    phoneNumber = json['phoneNumber'] ?? '';
    profileImageUrl = json['profileImageUrl'] ?? '';
    isOnline = json['isOnline'];
    dateOfBirth = json['dateOfBirth'] ?? '';
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['firstName'] = firstName;
    data['lastName'] = lastName;
    data['username'] = username;
    data['about'] = about;
    data['email'] = email;
    data['countryCode'] = countryCode;
    data['phoneNumber'] = phoneNumber;
    data['profileImageUrl'] = profileImageUrl;
    data['isOnline'] = isOnline;
    data['dateOfBirth'] = dateOfBirth;
    return data;
  }
}
