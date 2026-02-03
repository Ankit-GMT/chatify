import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chatify/Screens/broadcast/broadcast_media_preview_screen.dart';
import 'package:chatify/Screens/broadcast/voice_broadcast_screen.dart';
import 'package:chatify/Screens/chat_screen.dart';
import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/constants/custom_snackbar.dart';
import 'package:chatify/controllers/chat_screen_controller.dart';
import 'package:chatify/services/api_service.dart';
import 'package:chatify/constants/apis.dart';
import 'package:chatify/controllers/profile_controller.dart';
import 'package:chatify/models/chat_type.dart';
import 'package:chatify/models/contact_model.dart';
import 'package:chatify/services/presence_socket_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class TabBarController extends GetxController {
  final String baseUrl = APIs.url;
  final socket = Get.find<SocketService>();

  var isLoading1 = false.obs;
  var isLoading2 = false.obs;
  var isLoading3 = false.obs;

  late stt.SpeechToText _speech;
  final isListening = false.obs;

  final box = GetStorage();

  // Inside your Controller that fetches the chat list
  void onChatsLoaded(List<ChatType> chats) {
    final socket = Get.find<SocketService>();
    final myId = GetStorage().read("userId");

    for (var chat in chats) {
      if (chat.type != "GROUP") {
        final otherId = (myId == chat.members?[0].userId)
            ? (chat.members?[1].userId)
            : chat.members?[0].userId;
        print("onChAtsLoaded:_ $otherId");

        if (otherId != null) {
          socket.subscribeToUserStatus(otherId);
        }
      }
    }
  }

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
    // filterContacts();
    // debugPrint("Print 1 loadContactsFromLocal");
  }

  var searchQuery = ''.obs;
  RxInt currentIndex = 0.obs;
  final searchController = TextEditingController();

  void updateSearch(String value) {
    searchQuery.value = value.toLowerCase();
  }

  Future<void> startVoiceSearch() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'notListening') {
          isListening.value = false;
        }
      },
      onError: (_) => isListening.value = false,
    );

    if (!available) return;

    isListening.value = true;

    _speech.listen(
      listenOptions: stt.SpeechListenOptions(listenMode: stt.ListenMode.search),
      onResult: (result) {
        searchController.text = result.recognizedWords;
        updateSearch(result.recognizedWords);
      },
    );
  }

  void stopVoiceSearch() {
    _speech.stop();
    isListening.value = false;
  }

  final filteredChatsList = <ChatType>[].obs;
  final filteredGroupsList = <ChatType>[].obs;
  final filteredUnreadList = <ChatType>[].obs;
  final filteredRegisteredList = <ContactModel>[].obs;
  final filteredNotRegisteredList = <ContactModel>[].obs;

  final ProfileController profileController = Get.put(ProfileController());

  void _handleIncomingSocketMessage(Map<String, dynamic> data) {
    final int? incomingChatId = data['roomId'] ?? data['chatId'];
    if (incomingChatId == null) return;

    // --- NEW: Check if this is the active chat ---
    final activeChatId = box.read("activeChatId");

    // If the user is currently IN this chat, we don't update the "Last Message"
    // on the home screen card for this specific notification.
    bool isCurrentChat = activeChatId != null && activeChatId.toString() == incomingChatId.toString();
    debugPrint("Socket Msg for: $incomingChatId | Currently in: $activeChatId | Block Update: $isCurrentChat");

    // --- NEW: Handle Read Status Update ---
    if (data['type'] == 'READ_RECEIPT' || data['messageType'] == 'READ') {
      int index = allChats.indexWhere((c) => c.id == incomingChatId);
      if (index != -1) {
        allChats[index].unreadCount.value = 0;
        allChats.refresh();
        _syncFilteredLists();
      }
      return;
    }

    // --- Existing Message Logic ---
    int index = allChats.indexWhere((c) => c.id == incomingChatId);
    if (index != -1) {
      final chat = allChats[index];
      if (!isCurrentChat) {
        print("isCurrent :- false");
        chat.lastMessageContent.value = data['content'] ?? '';
        chat.lastMessageAt.value = data['sentAt'] ?? DateTime.now().toIso8601String();

        final myId = box.read("userId");
        if (data['senderId'] != myId) {
          chat.unreadCount.value++;
        }
      }
      else{
        print("isCurrent :- true");
        print("isCurrent :- ${Get.isRegistered<ChatScreenController>()}");
        if (Get.isRegistered<ChatScreenController>()) {
          final chatController = Get.find<ChatScreenController>();
          chatController.markChatAsRead(activeChatId);
        }
      }

      allChats.removeAt(index);
      allChats.insert(0, chat);
    } else {
      getAllChats();
    }
    _syncFilteredLists();
  }

  void _syncFilteredLists() {
    if (searchQuery.isEmpty) {
      filteredChatsList.assignAll(allChats);
      filteredGroupsList
          .assignAll(allChats.where((c) => c.type == "GROUP").toList());
      filteredUnreadList
          .assignAll(allChats.where((c) => c.unreadCount.value > 0).toList());
    } else {
      filterChats();
    }
  }

  @override
  void onInit() async {
    super.onInit();
    socket.connect();
    _speech = stt.SpeechToText();
    print("Active Chat ID;- ${box.read("activeChatId")}");

    // 1. Initial Data Load
    await getAllChats();
    await getUnreadChats();
    await _loadContacts();

    // 2. Setup socket listener IMMEDIATELY
    // Don't wait for 'ever' if already connected
    if (socket.isConnected.value) {
      _setupMessageListener();
    }

    // 3. Keep listening for connection changes (like after a reconnect)
    ever(socket.isConnected, (bool connected) {
      if (connected) {
        _setupMessageListener();
      }
    });

    ever(searchQuery, (_) {
      filterChats();
      filterContacts();
    });
  }

// Extract this to a separate method
  void _setupMessageListener() {
    final myId = box.read("userId");
    if (myId != null) {
      socket.subscribeMyMessages(myId, (data) {
        _handleIncomingSocketMessage(data);
      });
    }
  }

  var allChats = <ChatType>[].obs;
  var groupChats = <ChatType>[].obs;
  var unreadChats = <ChatType>[].obs;

  RxList<ContactModel> registeredUsers = <ContactModel>[].obs;
  RxList<ContactModel> notRegisteredUsers = <ContactModel>[].obs;

  Future<void> getAllChats() async {
    try {
      isLoading1.value = true;

      final res =
          await ApiService.request(url: "$baseUrl/api/chats", method: "GET")
          // .timeout(const Duration(seconds: 10))
          ;

      final data = jsonDecode(res.body);
      debugPrint("All chats... $data");

      if (res.statusCode == 200) {
        List users = data ?? [];
        allChats.value = users.map((u) => ChatType.fromJson(u)).toList();
        groupChats.value =
            allChats.where((chat) => chat.type == "GROUP").toList();
        // debugPrint(
        //     "Group chats: ${groupChats().map((chat) =>
        //         chat.members!.map((d) => d.userId).toList()).toList()}");
        onChatsLoaded(allChats);

        filterChats();
      } else {
        CustomSnackbar.error("Error", data['error'] ?? "No chats found");
      }
    } catch (e) {
      CustomSnackbar.error("Error", e.toString());
      debugPrint(e.toString());
    } finally {
      isLoading1.value = false;
    }
  }

  // unread chats

  Future<void> getUnreadChats() async {
    try {
      isLoading3.value = true;

      final res = await ApiService.request(
              url: "$baseUrl/api/chats/unread", method: "GET")
          // .timeout(const Duration(seconds: 10))
          ;

      final data = jsonDecode(res.body);
      debugPrint("Unread chats... $data");

      if (res.statusCode == 200) {
        List users = data ?? [];
        unreadChats.value = users.map((u) => ChatType.fromJson(u)).toList();
        print("$unreadChats");
        filterChats();
      } else {
        CustomSnackbar.error("Error", data['error'] ?? "No unread chats found");
      }
    } catch (e) {
      CustomSnackbar.error("Error", e.toString());
      debugPrint(e.toString());
    } finally {
      isLoading3.value = false;
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
      filteredUnreadList.assignAll(unreadChats);
      debugPrint("filteredChatsList: ${filteredChatsList.length}");
      debugPrint("filteredChatsList: ${allChats.length}");
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
    final resultUnread = unreadChats.where((chat) {
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

    filteredChatsList.assignAll(result);
    filteredGroupsList.assignAll(resultGroup);
    filteredUnreadList.assignAll(resultUnread);
  }

  // for contacts
  // Future<List<String>> getPhoneContacts() async {
  //   // Ask permission
  //   if (!await FlutterContacts.requestPermission(readonly: true)) {
  //     return [];
  //   }
  //
  //   // Get contacts with phones
  //   final contacts = await FlutterContacts.getContacts(withProperties: true);
  //
  //   // debugPrint("Contacts: $contacts");
  //   List<String> phoneNumbers = [];
  //   for (var c in contacts) {
  //     for (var p in c.phones) {
  //       // remove non-digit characters
  //       String cleaned = p.number.replaceAll(RegExp(r'[^0-9]'), '');
  //
  //       // keep only last 10 digits
  //       if (cleaned.length >= 10) {
  //         String last10 = cleaned.substring(cleaned.length - 10);
  //         phoneNumbers.add(last10);
  //       }
  //     }
  //   }
  //   return phoneNumbers.toSet().toList(); // unique 10-digit numbers
  // }

// check if users are on app
  Future<List<ContactModel>> checkUsersOnApp(List<String> phoneNumbers) async {
    final res = await ApiService.request(
        url: "$baseUrl/api/user/contacts/sync",
        method: "POST",
        body: {"contacts": phoneNumbers});

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      // debugPrint("Data: $data");
      return data.map((e) => ContactModel.fromJson(e)).toList();
    } else {
      debugPrint("Error: ${res.statusCode} ${res.body}");
      return [];
    }
  }

  // Future<void> _loadContacts({bool forceRefresh = false}) async {
  //   debugPrint(DateTime.now());
  //
  //   // Show cached instantly
  //   final cachedRegistered = box.read(registeredKey);
  //   final cachedNotRegistered = box.read(notRegisteredKey);
  //
  //   if (cachedRegistered != null || cachedNotRegistered != null) {
  //     loadContactsFromLocal();
  //   }
  //
  //   // Only show loader if user explicitly refreshes
  //   if (forceRefresh) isLoading2.value = true;
  //
  //   try {
  //     // Run in background
  //     final phoneNumbers = await getPhoneContacts();
  //
  //     if (phoneNumbers.isEmpty) {
  //       debugPrint("No contacts found or permission denied");
  //       return;
  //     }
  //
  //     final users = await checkUsersOnApp(phoneNumbers);
  //
  //     // update reactive lists
  //     registeredUsers.value = users.where((u) => u.registered!).toList();
  //     notRegisteredUsers.value = users.where((u) => !u.registered!).toList();
  //
  //     final contacts = await FlutterContacts.getContacts(withProperties: true);
  //     mergeNotRegisteredWithContacts(notRegisteredUsers, contacts);
  //
  //     // save new cache
  //     saveContactsToLocal();
  //
  //     // refresh UI
  //     filterContacts();
  //   } catch (e) {
  //     debugPrint("Error refreshing contacts: $e");
  //   } finally {
  //     isLoading2.value = false;
  //   }
  //   debugPrint(DateTime.now());
  // }

  Future<ContactsResult> getContactsOnce() async {
    if (!await FlutterContacts.requestPermission(readonly: true)) {
      return ContactsResult(
        phoneNumbers: [],
        contacts: [],
      );
    }

    final contacts = await FlutterContacts.getContacts(withProperties: true);

    final numbers = <String>{};

    for (var c in contacts) {
      for (var p in c.phones) {
        final phone = normalizePhone(p.number);
        if (phone.length == 10) {
          numbers.add(phone);
        }
      }
    }

    return ContactsResult(
      phoneNumbers: numbers.toList(),
      contacts: contacts,
    );
  }

  Map<String, Contact> buildContactMap(List<Contact> contacts) {
    final map = <String, Contact>{};

    for (var c in contacts) {
      for (var p in c.phones) {
        final phone = normalizePhone(p.number);
        if (phone.length == 10) {
          map[phone] = c;
        }
      }
    }

    return map;
  }

  void mergeNotRegisteredFast(
    List<ContactModel> notRegistered,
    Map<String, Contact> contactMap,
  ) {
    for (var user in notRegistered) {
      final phone = normalizePhone(user.phoneNumber ?? '');
      final contact = contactMap[phone];

      if (contact != null) {
        user.firstName ??= contact.name.first;
        user.lastName ??= contact.name.last;
      }
    }
  }

  Future<void> _loadContacts({bool forceRefresh = false}) async {
    //  Load cached data instantly
    if (box.hasData(registeredKey) || box.hasData(notRegisteredKey)) {
      loadContactsFromLocal();
    }

    if (forceRefresh) isLoading2.value = true;

    try {
      // Fetch contacts ONCE
      final result = await getContactsOnce();

      final phoneNumbers = result.phoneNumbers;
      final localContacts = result.contacts;

      if (phoneNumbers.isEmpty) {
        debugPrint("No contacts or permission denied");
        return;
      }

      // Sync with backend
      final users = await checkUsersOnApp(phoneNumbers);

      final registered = users.where((u) => u.registered == true).toList();
      final notRegistered = users.where((u) => u.registered == false).toList();

      // Fast merge using hashmap
      final contactMap = buildContactMap(localContacts);
      mergeNotRegisteredFast(notRegistered, contactMap);

      // Update reactive lists ONCE
      registeredUsers.assignAll(registered);
      notRegisteredUsers.assignAll(notRegistered);

      saveContactsToLocal();
      filterContacts();
    } catch (e) {
      debugPrint("Contact sync error: $e");
    } finally {
      isLoading2.value = false;
    }
  }

  String normalizePhone(String number) {
    String cleaned = number.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length >= 10) {
      return cleaned.substring(cleaned.length - 10);
    }
    return cleaned;
  }

  // void mergeNotRegisteredWithContacts(List<ContactModel> notRegisteredUsers,
  //     List<Contact> localContacts) {
  //   for (var user in notRegisteredUsers) {
  //     String apiPhone = normalizePhone(user.phoneNumber!);
  //
  //     for (var c in localContacts) {
  //       for (var p in c.phones) {
  //         String contactPhone = normalizePhone(p.number);
  //
  //         if (apiPhone == contactPhone) {
  //           // Fill missing details
  //           user.firstName ??= c.name.first;
  //           user.lastName ??= c.name.last;
  //         }
  //       }
  //     }
  //   }
  // }

  // filter Contacts

  void filterContacts() {
    final query = searchQuery.value;

    if (query.isEmpty) {
      filteredRegisteredList.assignAll(registeredUsers);
      filteredNotRegisteredList.assignAll(notRegisteredUsers);
      // print("filtered not-registered: ${filteredNotRegisteredList.length}");
      // print("filtered registered: ${filteredRegisteredList.length}");
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
        "targetId": chat.type == "GROUP"
            ? chat.id
            : (chat.members?[0].userId == myId
                ? (chat.members?[1].userId)
                : (chat.members?[0].userId)),
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
      await getUnreadChats();

      CustomSnackbar.error("Muted", "Selected chats have been muted");
    } else {
      CustomSnackbar.error("Error", "Failed to mute chats");
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
          url: "$baseUrl/api/mute/bulk", method: "DELETE", body: body);

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
        "targetId": chat.type == "GROUP"
            ? chat.id
            : (chat.members?[0].userId == myId
                ? (chat.members?[1].userId)
                : (chat.members?[0].userId)),
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
      await getUnreadChats();

      CustomSnackbar.success("UnMuted", "Selected chats have been Unmuted");
    } else {
      CustomSnackbar.error("Error", "Failed to Unmute chats");
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
        "targetId": chat.type == "GROUP"
            ? chat.id
            : (chat.members?[0].userId == myId
                ? (chat.members?[1].userId)
                : (chat.members?[0].userId)),
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
      await getUnreadChats();

      CustomSnackbar.success("Pinned", "Selected chats have been pinned");
    } else {
      CustomSnackbar.error("Error", "Failed to pin chats");
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
          url: "$baseUrl/api/pin/bulk", method: "DELETE", body: body);

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
        "targetId": chat.type == "GROUP"
            ? chat.id
            : (chat.members?[0].userId == myId
                ? (chat.members?[1].userId)
                : (chat.members?[0].userId)),
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
      await getUnreadChats();

      CustomSnackbar.success("UnPinned", "Selected chats have been Unpinned");
    } else {
      CustomSnackbar.error("Error", "Failed to Unpin chats");
    }
  }

  // for verify

  Future<bool> verifyChatPin({
    required int chatId,
    required String pin,
  }) async {
    try {
      final body = {"pin": pin};
      final res = await ApiService.request(
          url: "$baseUrl/api/chats/$chatId/lock/verify",
          method: 'POST',
          body: body);

      final data = jsonDecode(res.body);
      return res.statusCode == 200 && data['success'] == true;
    } catch (e) {
      debugPrint("Verify PIN Error: $e");
      return false;
    }
  }

  void handleChatOpen(ChatType chat) {
    if (chat.locked.value == true) {
      showUnlockChatSheet(chat.id!);
    } else {
      openChat(chat.id!);
    }
  }

  void openChat(int chatId) {
    int index = allChats.indexWhere((c) => c.id == chatId);
    if (index != -1) {
      allChats[index].unreadCount.value = 0;
      allChats.refresh();
    }

    Get.to(
      () => ChatScreen(chatId: chatId),
      arguments: chatId,
    )?.then((_) {
      Get.find<TabBarController>().getAllChats();
      Get.find<TabBarController>().getUnreadChats();
    });
  }

  void showUnlockChatSheet(int chatId) {
    String? otpCode;
    final tabController = Get.find<TabBarController>();

    showDialog(
        context: Get.context!,
        builder: (_) {
          return Dialog(
            backgroundColor: AppColors.black,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock, size: 40, color: Colors.white),
                  const SizedBox(height: 10),
                  const Text(
                    "Enter PIN",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "This chat is locked",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: Get.width * 0.04),
                    child: PinCodeTextField(
                      appContext: Get.context!,
                      length: 4,
                      textStyle: TextStyle(color: Colors.black),
                      obscureText: true,
                      onChanged: (value) {
                        otpCode = value;
                      },
                      onCompleted: (value) {
                        debugPrint("OTP Entered: $value");
                      },
                      keyboardType: TextInputType.number,
                      cursorColor: AppColors.black,
                      cursorWidth: 0.5,
                      showCursor: true,
                      cursorHeight: 15,
                      autoFocus: true,
                      pinTheme: PinTheme(
                        fieldOuterPadding: EdgeInsets.symmetric(horizontal: 10),
                        shape: PinCodeFieldShape.box,
                        borderRadius: BorderRadius.circular(12),
                        fieldHeight: Get.height * 0.05,
                        fieldWidth: Get.width * 0.1,
                        activeFillColor: Colors.white,
                        inactiveFillColor: Colors.white,
                        selectedFillColor: Colors.white,
                        activeColor: Colors.grey.shade400,
                        inactiveColor: Colors.grey.shade300,
                        selectedColor: AppColors.primary,
                        activeBoxShadow: [
                          BoxShadow(
                            color: Color(0xff63636333).withAlpha(51),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      enableActiveFill: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: Get.width * 0.5,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text("Unlock"),
                      onPressed: () async {
                        if (otpCode?.length != 4) {
                          CustomSnackbar.error("Error", "Enter valid PIN");
                          return;
                        }
                        final success = await tabController.verifyChatPin(
                            chatId: chatId, pin: otpCode!);

                        if (success) {
                          Get.back();
                          openChat(chatId);
                        } else {
                          CustomSnackbar.error("Wrong PIN", "Please try again");
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  // For Broadcast msg

  Future<void> pickMediaForBroadcast(String type) async {
    File? file;

    if (type == "IMAGE") {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked != null) file = File(picked.path);
    }

    if (type == "VIDEO") {
      final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
      if (picked != null) file = File(picked.path);
    }

    if (type == "DOCUMENT") {
      final result = await FilePicker.platform.pickFiles();
      if (result != null) file = File(result.files.single.path!);
    }

    if (file != null) {
      Get.to(
        () => BroadcastMediaPreviewScreen(),
        arguments: {
          "file": file,
          "type": type,
        },
      );
    }
  }

  // For send birthday - single user

  var isLoading4 = false.obs;
  var isLoading5 = false.obs;

  Future<void> sendBirthdayMessage({
    required String recipientUserId,
    required String message,
  }) async {
    try {
      isLoading4.value = true;

      final body = {
        "recipientUserId": recipientUserId,
        "message": message,
      };

      final res = await ApiService.request(
          url: "$baseUrl/api/birthdays/send-message",
          method: "POST",
          body: body);

      final data = jsonDecode(res.body);
      debugPrint("Birthday Message Response: $data");

      if (res.statusCode == 200 && data['success'] == true) {
        CustomSnackbar.success(
          "Sent",
          data['message'] ?? "Birthday wish sent successfully",
        );
      } else {
        CustomSnackbar.error(
          "Error",
          data['message'] ?? "Failed to send birthday message",
        );
      }
    } catch (e) {
      debugPrint("sendBirthdayMessage Error: $e");
      CustomSnackbar.error("Error", e.toString());
    } finally {
      isLoading4.value = false;
    }
  }

  // for multiple-user

  Future<void> sendBirthdayMessageToAll({
    required List<int> recipientUserIds,
    required String message,
  }) async {
    try {
      isLoading5.value = true;
      final body = {
        "recipientUserIds": recipientUserIds,
        "message": message,
      };

      final res = await ApiService.request(
          url: "$baseUrl/api/birthdays/send-message-to-all",
          method: "POST",
          body: body);

      final data = jsonDecode(res.body);
      debugPrint("Birthday Message To All Response: $data");

      if (res.statusCode == 200 && data['success'] == true) {
        CustomSnackbar.success(
          "Sent",
          data['message'] ?? "Birthday wishes sent successfully",
        );
      } else {
        CustomSnackbar.error(
          "Error",
          data['message'] ?? "Failed to send birthday wishes",
        );
      }
    } catch (e) {
      debugPrint("sendBirthdayMessageToAll Error: $e");
      CustomSnackbar.error("Error", e.toString());
    } finally {
      isLoading5.value = false;
    }
  }

  // For voice record - broadcast msg

  final AudioRecorder _audioRecorder = AudioRecorder();
  var isRecording = false.obs;
  var recordDuration = 0.obs;
  Timer? _recordTimer;
  String? _latestPath;

  void startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      final dir = await getTemporaryDirectory();
      _latestPath =
          "${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a";

      await _audioRecorder.start(const RecordConfig(), path: _latestPath!);
      isRecording.value = true;
      recordDuration.value = 0;
      _recordTimer = Timer.periodic(
          const Duration(seconds: 1), (t) => recordDuration.value++);
    }
  }

  void stopRecording() async {
    _recordTimer?.cancel();
    final path = await _audioRecorder.stop();
    isRecording.value = false;

    if (path != null) {
      Get.to(() => VoiceBroadcastScreen(), arguments: {
        "path": path,
        "duration": recordDuration.value,
      });
    }
  }
}

class ContactsResult {
  final List<String> phoneNumbers;
  final List<Contact> contacts;

  ContactsResult({
    required this.phoneNumbers,
    required this.contacts,
  });
}
