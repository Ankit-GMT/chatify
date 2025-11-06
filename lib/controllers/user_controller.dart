import 'dart:convert';
import 'package:chatify/constants/apis.dart';
import 'package:chatify/models/chat_type.dart';
import 'package:chatify/models/chat_user.dart';
import 'package:chatify/models/contact_model.dart';
import 'package:chatify/api_service.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class UserController extends GetxController {
  var searchResults = <ChatUser>[].obs;
  var isLoading = false.obs;
  final String baseUrl = APIs.url;

  final box = GetStorage();

  // for first time if user chat
  Future<dynamic> createChat(int otherUserId) async {
    final token = box.read("accessToken");

    final body = {
      "participantIds": [otherUserId],
      "type": "PRIVATE"
    };

    // print("Create Chat Payload: $body");

    try {
      isLoading.value = true;

      // final res = await http.post(
      //   Uri.parse("$baseUrl/api/chats"),
      //   headers: {
      //     "Authorization": "Bearer $token",
      //     "Content-Type": "application/json",
      //   },
      //   body: jsonEncode(body),
      // );

      final res = await ApiService.request(
        url: "$baseUrl/api/chats",
        method: "POST",
        body: body,
      );

      isLoading.value = false;

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        // print("Chat Created, data: $data");
        getAllChats();
        return ChatType.fromJson(data);
      } else {
        // print("Failed to create chat: ${res.statusCode} ${res.body}");
        return null;
      }
    } catch (e) {
      isLoading.value = false;
      // print("Exception while creating chat: $e");
      return null;
    }
  }

  Future<void> searchUsers(String phone) async {
    try {
      isLoading.value = true;

      final token = box.read("accessToken"); // Get stored JWT

      // final res = await http.get(
      //   Uri.parse("$baseUrl/api/users/search?q=$phone"),
      //   headers: {
      //     "Authorization": "Bearer $token",
      //     "Content-Type": "application/json",
      //   },
      // );
      final res = await ApiService.request(
          url: "$baseUrl/api/users/search?q=$phone", method: "GET");

      final data = jsonDecode(res.body);
      print("search... $data");

      if (res.statusCode == 200) {
        List users = data ?? [];
        searchResults.value = users.map((u) => ChatUser.fromJson(u)).toList();
      } else {
        searchResults.clear();
        Get.snackbar("Error", data['error'] ?? "No users found");
      }
    } catch (e) {
      Get.snackbar("Error--", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // All users
  var allChats = <ChatType>[].obs;
  var groupChats = <ChatType>[].obs;
  var user = ChatUser().obs;

  Future<void> getAllChats() async {
    try {
      isLoading.value = true;

      final token = box.read("accessToken");

      print('Token: $token'); // Get stored JWT

      // final res = await http.get(
      //   Uri.parse("$baseUrl/api/chats"),
      //   headers: {
      //     "Authorization": "Bearer $token",
      //     "Content-Type": "application/json",
      //   },
      // );

      final res =
          await ApiService.request(url: "$baseUrl/api/chats", method: "GET");

      final data = jsonDecode(res.body);
      // print("All chats... $data");

      if (res.statusCode == 200) {
        List users = data ?? [];
        allChats.value = users.map((u) => ChatType.fromJson(u)).toList();
        groupChats.value =
            allChats.where((chat) => chat.type == "GROUP").toList();
        print("Group chats: ${groupChats().map((chat) => chat.members!.map((d)=> d.userId).toList()).toList()}");
      } else {
        searchResults.clear();
        Get.snackbar("Error", data['error'] ?? "No chats found");
      }
    } catch (e) {
      Get.snackbar("Error--", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchUserProfile(int userId) async {
    try {
      final box = GetStorage();
      final token = box.read("accessToken");

      // final res = await http.get(
      //   Uri.parse("$baseUrl/api/user/$userId"),
      //   headers: {
      //     "Authorization": "Bearer $token",
      //     "Content-Type": "application/json",
      //   },
      // );

      final res = await ApiService.request(
          url: "$baseUrl/api/user/$userId", method: "GET");

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);

        final Map<String, dynamic> userJson =
            body is Map && (body['id'] != null)
                ? body
                : (body['user'] ?? body['data'] ?? body);
        // print(userJson);

        user.value = ChatUser.fromJson(Map<String, dynamic>.from(userJson));
      } else {
        print("Failed to fetch profile: ${res.statusCode} ${res.body}");
      }
    } catch (e) {
      print("Error fetchUserProfile: $e");
    }
  }

  // for contacts
  Future<List<String>> getPhoneContacts() async {
    // Ask permission
    if (!await FlutterContacts.requestPermission(readonly: true)) {
      return [];
    }

    // Get contacts with phones
    final contacts = await FlutterContacts.getContacts(withProperties: true);

    // print("Contacts: $contacts");
    List<String> phoneNumbers = [];
    for (var c in contacts) {
      for (var p in c.phones) {
        // remove non-digit characters
        String cleaned = p.number.replaceAll(RegExp(r'[^0-9]'), '');

        // keep only last 10 digits
        if (cleaned.length >= 10) {
          String last10 = cleaned.substring(cleaned.length - 10);
          phoneNumbers.add(last10);
        }
      }
    }
    return phoneNumbers.toSet().toList(); // unique 10-digit numbers
  }

// check if users are on app
  Future<List<ContactModel>> checkUsersOnApp(List<String> phoneNumbers) async {
    final token = box.read("accessToken");

    // final res = await http.post(
    //   Uri.parse("$baseUrl/api/user/contacts/sync"),
    //   headers: {
    //     "Authorization": "Bearer $token",
    //     "Content-Type": "application/json",
    //   },
    //   body: jsonEncode({"contacts": phoneNumbers}),
    // );

    final res = await ApiService.request(
        url: "$baseUrl/api/user/contacts/sync",
        method: "POST",
        body: {"contacts": phoneNumbers});

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      // print("Data: $data");
      return data.map((e) => ContactModel.fromJson(e)).toList();
    } else {
      print("Error: ${res.statusCode} ${res.body}");
      return [];
    }
  }

  RxList<ContactModel> registeredUsers = <ContactModel>[].obs;
  RxList<ContactModel> notRegisteredUsers = <ContactModel>[].obs;

  Future<void> _loadContacts() async {
    isLoading.value = true;
    final phoneNumbers = await getPhoneContacts();
    final users = await checkUsersOnApp(phoneNumbers);
    // for registered users
    registeredUsers.value = users.where((user) => user.registered!).toList();
    // for not registered users
    notRegisteredUsers.value =
        users.where((user) => !user.registered!).toList();
    final contacts = await FlutterContacts.getContacts(withProperties: true);
    //
    mergeNotRegisteredWithContacts(notRegisteredUsers, contacts);
    isLoading.value = false;
    // print("users: $users");
    // print("App users: $registeredUsers");
  }

  String normalizePhone(String number) {
    String cleaned = number.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length >= 10) {
      return cleaned.substring(cleaned.length - 10);
    }
    return cleaned;
  }

  void mergeNotRegisteredWithContacts(
      List<ContactModel> notRegisteredUsers, List<Contact> localContacts) {
    for (var user in notRegisteredUsers) {
      String apiPhone = normalizePhone(user.phoneNumber!);

      for (var c in localContacts) {
        for (var p in c.phones) {
          String contactPhone = normalizePhone(p.number);

          if (apiPhone == contactPhone) {
            // Fill missing details
            user.firstName ??= c.name.first;
            user.lastName ??= c.name.last;
          }
        }
      }
    }
  }

  // For pinned chats

  RxList<ChatType> selectedChats = <ChatType>[].obs;
  RxBool isSelectionMode = false.obs;

  void toggleSelection(ChatType chat) {
    if (selectedChats.contains(chat)) {
      selectedChats.remove(chat);
    } else {
      selectedChats.add(chat);
    }

    // Enable or disable selection mode based on list
    isSelectionMode.value = selectedChats.isNotEmpty;
  }

  void clearSelection() {
    selectedChats.clear();
    isSelectionMode.value = false;
  }

  // void pinSelected() {
  //   for (var chat in selectedChats) {
  //     chat.isPinned.value = true;
  //   }
  //   reorderChats();
  //   clearSelection();
  // }
  //
  // void unpinSelected() {
  //   for (var chat in selectedChats) {
  //     chat.isPinned.value = false;
  //   }
  //   reorderChats();
  //   clearSelection();
  // }

  void togglePinSelected() {
    // Check if all selected chats are already pinned
    final allPinned = selectedChats.every((chat) => chat.isPinned.value);

    // If all are pinned → unpin them; otherwise, pin them
    for (var chat in selectedChats) {
      chat.isPinned.value = !allPinned;
    }

    reorderChats();
    clearSelection();
  }

  bool get areAllSelectedPinned =>
      selectedChats.isNotEmpty &&
      selectedChats.every((chat) => chat.isPinned.value);

  void reorderChats() {
    allChats.sort((a, b) {
      if (a.isPinned.value && !b.isPinned.value) return -1;
      if (!a.isPinned.value && b.isPinned.value) return 1;
      return 0;
    });
    groupChats.sort((a, b) {
      if (a.isPinned.value && !b.isPinned.value) return -1;
      if (!a.isPinned.value && b.isPinned.value) return 1;
      return 0;
    });
  }

  @override
  void onInit() {
    super.onInit();
    getAllChats();
    _loadContacts();
  }
}
