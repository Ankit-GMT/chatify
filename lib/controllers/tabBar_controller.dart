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
    box.write(
        notRegisteredKey, notRegisteredUsers.map((e) => e.toJson()).toList());
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

  final ProfileController profileController = Get.put(ProfileController());

  @override
  void onInit() async {
    super.onInit();
    // Listen to search query changes
    await getAllChats();
    await _loadContacts();
    filterChats();
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
            "Group chats: ${groupChats().map((chat) =>
                chat.members!.map((d) => d.userId).toList()).toList()}");

        filterChats();
      } else {
        Get.snackbar("Error", data['error'] ?? "No chats found");
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
      print(e.toString());
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

  void mergeNotRegisteredWithContacts(List<ContactModel> notRegisteredUsers,
      List<Contact> localContacts) {
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

// For checking which icon to show in homescreen
  bool get areAllSelectedMuted =>
      selectedChats.isNotEmpty &&
          selectedChats.every((chat) => chat.muted.value);


// Mute API
  Future<bool> muteChatsBulk({
    required List<Map<String, dynamic>> targets,
    required int durationHours,
  }) async {

    try {
      final body = {
        "targets": targets,
        "durationHours": durationHours,
      };

      final response = await ApiService.request(
          url: "$baseUrl/api/mute/bulk", method: "POST", body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print("Mute error: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      print("Mute exception: $e");
      return false;
    }
  }

  // Mute function for UI
  Future<void> muteSelectedChats({int durationHours = 8}) async {
    if (selectedChats.isEmpty) return;
    final myId = profileController.user.value?.id;

    final targets = selectedChats.map((chat) {
      return {
        "targetType": chat.type == "GROUP" ? "GROUP" : "USER",
        "targetId": chat.type == "GROUP" ? chat.id : (chat.members?[0].userId == myId ? (chat.members?[1].userId) : (chat.members?[0].userId)),
      };
    }).toList();

    final success = await muteChatsBulk(
      targets: targets,
      durationHours: durationHours,
    );

    if (success) {
      // Updating local state
      for (var chat in selectedChats) {
        chat.muted.value = true;
      }

      clearSelection();
      update();
      await getAllChats();

      Get.snackbar("Muted", "Selected chats have been muted");
    } else {
      Get.snackbar("Error", "Failed to mute chats");
    }
  }

  // UnMute API
  Future<bool> unMuteChatsBulk({
    required List<Map<String, dynamic>> targets,
  }) async {

    try {
      final body = {
        "targets": targets,
      };

      final response = await ApiService.request(
          url: "$baseUrl/api/mute/bulk", method: "DELETE",body: body);


      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print("UnMute error: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      print("UnMute exception: $e");
      return false;
    }
  }

  // UnMute function for UI
  Future<void> unMuteSelectedChats() async {
    if (selectedChats.isEmpty) return;

    final myId = profileController.user.value?.id;
    final targets = selectedChats.map((chat) {
      return {
        "targetType": chat.type == "GROUP" ? "GROUP" : "USER",
        "targetId": chat.type == "GROUP" ? chat.id : (chat.members?[0].userId == myId ? (chat.members?[1].userId) : (chat.members?[0].userId)),
      };
    }).toList();
    print("Targets :- $targets");
    final success = await unMuteChatsBulk(
      targets: targets,
    );

    if (success) {
      // Updating local state
      for (var chat in selectedChats) {
        chat.muted.value = false;
      }

      clearSelection();
      update();
      await getAllChats();

      Get.snackbar("UnMuted", "Selected chats have been Unmuted");
    } else {
      Get.snackbar("Error", "Failed to Unmute chats");
    }
  }


  // For Pin chats

  bool get areAllSelectedPinned =>
      selectedChats.isNotEmpty &&
          selectedChats.every((chat) => chat.pinned.value);

// Pin API
  Future<bool> pinChatsBulk({
    required List<Map<String, dynamic>> targets,
  }) async {

    try {
      final body = {
        "targets": targets,
      };

      final response = await ApiService.request(
          url: "$baseUrl/api/pin/bulk", method: "POST", body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print(response.body);
        return true;

      } else {
        print("Error in pin chat: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      print("Pin exception: $e");
      return false;
    }
  }

  // Pin function for UI
  Future<void> pinSelectedChats() async {
    if (selectedChats.isEmpty) return;

    final myId = profileController.user.value?.id;
    final targets = selectedChats.map((chat) {
      return {
        "targetType": chat.type == "GROUP" ? "GROUP" : "USER",
        "targetId": chat.type == "GROUP" ? chat.id : (chat.members?[0].userId == myId ? (chat.members?[1].userId) : (chat.members?[0].userId)),
      };
    }).toList();

    final success = await pinChatsBulk(
      targets: targets,
    );

    if (success) {
      // Updating local state
      for (var chat in selectedChats) {
        chat.pinned.value = true;
      }

      clearSelection();
      update();
      await getAllChats();

      Get.snackbar("Pinned", "Selected chats have been pinned");
    } else {
      Get.snackbar("Error", "Failed to pin chats");
    }
  }

  // UnPin API
  Future<bool> unPinChatsBulk({
    required List<Map<String, dynamic>> targets,
  }) async {

    try {
      final body = {
        "targets": targets,
      };

      final response = await ApiService.request(
          url: "$baseUrl/api/pin/bulk", method: "DELETE",body: body);


      if (response.statusCode == 200 || response.statusCode == 201) {
        print(response.body);
        return true;
      } else {
        print("UnPin error: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      print("UnPin exception: $e");
      return false;
    }
  }

  // UnPin function for UI
  Future<void> unPinSelectedChats() async {
    if (selectedChats.isEmpty) return;

    final myId = profileController.user.value?.id;
    final targets = selectedChats.map((chat) {
      return {
        "targetType": chat.type == "GROUP" ? "GROUP" : "USER",
        "targetId": chat.type == "GROUP" ? chat.id : (chat.members?[0].userId == myId ? (chat.members?[1].userId) : (chat.members?[0].userId)),
      };
    }).toList();
    print("Targets :- $targets");
    final success = await unPinChatsBulk(
      targets: targets,
    );

    if (success) {
      // Updating local state
      for (var chat in selectedChats) {
        chat.pinned.value = false;
      }
      clearSelection();
      update();
      await getAllChats();

      Get.snackbar("UnPinned", "Selected chats have been Unpinned");
    } else {
      Get.snackbar("Error", "Failed to Unpin chats");
    }
  }

}
