import 'dart:convert';

import 'package:chatify/services/api_service.dart';
import 'package:chatify/constants/apis.dart';
import 'package:chatify/controllers/profile_controller.dart';
import 'package:chatify/models/chat_type.dart';
import 'package:chatify/models/contact_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class TabBarController extends GetxController {

  final String baseUrl = APIs.url;

  var isLoading1 = false.obs;
  var isLoading2 = false.obs;

  final box = GetStorage();

  // for local storing
  void saveContactsToLocal() {
    box.write(registeredKey, registeredUsers.map((e) => e.toJson()).toList());
    box.write(notRegisteredKey, notRegisteredUsers.map((e) => e.toJson()).toList());
  }

  void loadContactsFromLocal() {
    final registeredData = box.read(registeredKey);
    final notRegisteredData = box.read(notRegisteredKey);

    if (registeredData != null) {
      registeredUsers.value = List<ContactModel>.from(
        registeredData.map((e) => ContactModel.fromJson(e)),
      );
    }
    if (notRegisteredData != null) {
      notRegisteredUsers.value = List<ContactModel>.from(
        notRegisteredData.map((e) => ContactModel.fromJson(e)),
      );
    }

    // immediately reflect in filtered lists
    filterContacts();
    print("Print 1 loadContactsFromLocal");
  }


  var searchQuery = ''.obs;
  RxInt currentIndex = 0.obs;
  final searchController = TextEditingController();


  void updateSearch(String value) {
    searchQuery.value = value.toLowerCase();
  }

  final filteredChatsList = <ChatType>[].obs;
  final filteredGroupsList = <ChatType>[].obs;
  final filteredRegisteredList = <ContactModel>[].obs;
  final filteredNotRegisteredList = <ContactModel>[].obs;

  // final searchQuery = ''.obs;
  final ProfileController profileController = Get.put(ProfileController());

  @override
  void onInit() async {
    super.onInit();
    // Listen to search query changes
    await getAllChats();
    await _loadContacts();
    filterChats();
    print("Print 2 on in it");
    filterContacts();
    ever(searchQuery, (_) {
      filterChats();
      filterContacts();
    });
  }

  var allChats = <ChatType>[].obs;
  var groupChats = <ChatType>[].obs;

  RxList<ContactModel> registeredUsers = <ContactModel>[].obs;
  RxList<ContactModel> notRegisteredUsers = <ContactModel>[].obs;

  Future<void> getAllChats() async {
    try {
      isLoading1.value = true;

      final res =
          await ApiService.request(url: "$baseUrl/api/chats", method: "GET");

      final data = jsonDecode(res.body);
      // print("All chats... $data");

      if (res.statusCode == 200) {
        List users = data ?? [];
        allChats.value = users.map((u) => ChatType.fromJson(u)).toList();
        groupChats.value =
            allChats.where((chat) => chat.type == "GROUP").toList();
        print(
            "Group chats: ${groupChats().map((chat) => chat.members!.map((d) => d.userId).toList()).toList()}");

        filterChats();

      } else {
        Get.snackbar("Error", data['error'] ?? "No chats found");
      }
    } catch (e) {
      Get.snackbar("Error--", e.toString());
    } finally {
      isLoading1.value = false;
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

  // void updateSearch(String value) {
  //   searchQuery.value = value.toLowerCase();
  // }

  void filterChats() {
    final myId = profileController.user.value?.id;
    final query = searchQuery.value;

    if (query.isEmpty) {
      filteredChatsList.assignAll(allChats);
      filteredGroupsList.assignAll(groupChats);
      print("filteredChatsList: ${filteredChatsList.length}");
      print("filteredChatsList: ${allChats.length}");
      return;
    }

    final result = allChats.where((chat) {
      if (chat.type == "GROUP") {
        return chat.name?.toLowerCase().contains(query) ?? false;
      } else {
        final member0 = chat.members?[0];
        final member1 = chat.members?[1];

        final member0Name =
            "${member0?.firstName ?? ''} ${member0?.lastName ?? ''}"
                .toLowerCase();
        final member1Name =
            "${member1?.firstName ?? ''} ${member1?.lastName ?? ''}"
                .toLowerCase();

        if (myId == member0?.userId) {
          return member1Name.contains(query);
        } else {
          return member0Name.contains(query);
        }
      }
    }).toList();

    final resultGroup = groupChats.where((chat) {
      return chat.name?.toLowerCase().contains(query) ?? false;
    }).toList();

    filteredChatsList.assignAll(result);
    filteredGroupsList.assignAll(resultGroup);
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

  Future<void> _loadContacts({bool forceRefresh = false}) async {

    print(DateTime.now());
    
    // Show cached instantly
    final cachedRegistered = box.read(registeredKey);
    final cachedNotRegistered = box.read(notRegisteredKey);

    if (cachedRegistered != null || cachedNotRegistered != null) {
      loadContactsFromLocal();
    }

    // Only show loader if user explicitly refreshes
    if (forceRefresh) isLoading2.value = true;

    try {
      // Run in background
      final phoneNumbers = await getPhoneContacts();

      if (phoneNumbers.isEmpty) {
        debugPrint("No contacts found or permission denied");
        return;
      }

      final users = await checkUsersOnApp(phoneNumbers);

      // update reactive lists
      registeredUsers.value = users.where((u) => u.registered!).toList();
      notRegisteredUsers.value = users.where((u) => !u.registered!).toList();

      final contacts = await FlutterContacts.getContacts(withProperties: true);
      mergeNotRegisteredWithContacts(notRegisteredUsers, contacts);

      // save new cache
      saveContactsToLocal();

      // refresh UI
      filterContacts();
    } catch (e) {
      debugPrint("Error refreshing contacts: $e");
    } finally {
      isLoading2.value = false;
    }
    print(DateTime.now());
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

  // filter Contacts

  void filterContacts() {
    final query = searchQuery.value;

    if (query.isEmpty) {
      filteredRegisteredList.assignAll(registeredUsers);
      filteredNotRegisteredList.assignAll(notRegisteredUsers);
      print("filtered not-registered: ${filteredNotRegisteredList.length}");
      print("filtered registered: ${filteredRegisteredList.length}");
      return;
    }

    final resultRegistered = registeredUsers.where((chat) {
      return '${chat.firstName?.toLowerCase()} ${chat.lastName?.toLowerCase()}'
          .contains(query);
    }).toList();

    final resultNotRegistered = notRegisteredUsers.where((chat) {
      return '${chat.firstName?.toLowerCase()} ${chat.lastName?.toLowerCase()}'
          .contains(query);
    }).toList();

    filteredRegisteredList.assignAll(resultRegistered);
    filteredNotRegisteredList.assignAll(resultNotRegistered);
  }


  // For Mute users

  Future<bool> muteUser({
    required int mutedUserId,
    required int durationHours,
  }) async {
    try {

      final body = {
        "mutedUserId": mutedUserId,
        "durationHours": durationHours,
      };

      final response = await ApiService.request(
        url: "$baseUrl/api/mute/user",
        method: "POST",
        body: body
      );

      if (response.statusCode == 200) {
        print("User muted successfully");
        return true;
      } else {
        print("Mute failed: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Mute error: $e");
      return false;
    }
  }

  // For Unmute user

  Future<bool> unmuteUser({
    required int userId,
  }) async {
    try {

      final response = await ApiService.request(
          url: "$baseUrl/api/mute/user/$userId", method: "DELETE");

      if (response.statusCode == 200) {
        print("User unmuted successfully");
        return true;
      } else {
        print("Unmute failed: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error unmuting user: $e");
      return false;
    }
  }

  // For mute group
  Future<bool> muteGroup({
    required int muteGroupId,
    required int durationHours,
  }) async {
    try {

      final body = {
        "groupId": muteGroupId,
        "durationHours": durationHours
      };

      final response = await ApiService.request(
          url: "$baseUrl/api/mute/group",
          method: "POST",
          body: body
      );

      if (response.statusCode == 200) {
        print("Group muted successfully");
        return true;
      } else {
        print("Mute failed: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Mute error: $e");
      return false;
    }
  }

  // For Unmute user

  Future<bool> unMuteGroup({
    required int groupId,
  }) async {
    try {

      final response = await ApiService.request(
          url: "$baseUrl/api/mute/group/$groupId", method: "DELETE");

      if (response.statusCode == 200) {
        print("Group unmuted successfully");
        return true;
      } else {
        print("Unmute failed: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error unmuting group: $e");
      return false;
    }
  }

}
