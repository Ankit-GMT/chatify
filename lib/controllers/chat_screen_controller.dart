import 'dart:convert';
import 'dart:io';

import 'package:chatify/constants/apis.dart';
import 'package:chatify/models/chat_type.dart';
import 'package:chatify/models/message.dart';
import 'package:chatify/services/api_service.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:media_scanner/media_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatScreenController extends GetxController {
  final int chatId;

  ChatScreenController({required this.chatId});

  final String baseUrl = APIs.url;

  var chatType = Rxn<ChatType>();
  var type = ''.obs;

  RxList<Message> messages = <Message>[].obs;

  var isLoading = true.obs;

  Future<void> loadMessages(int id) async {
    final data = await fetchMessages(id);
    messages.value = data;
    await initializeDownloads();
  }

  void fetchChatType(int id) async {
    final data = await fetchChatTypeDetails(id);
    chatType.value = data;
    type.value = chatType.value?.type ?? '';
  }

  Future<ChatType?> fetchChatTypeDetails(int chatId) async {
    try {
      isLoading.value = true;
      final res = await ApiService.request(
          url: "$baseUrl/api/chats/$chatId", method: "GET");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return ChatType.fromJson(data);
      } else {
        print("Failed to load: ${res.statusCode} ${res.body}");
        return null;
      }
    } catch (e) {
      print("Error: $e");
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // for load messages
  Future<List<Message>> fetchMessages(int chatId) async {
    try {
      final res = await ApiService.request(
          url: "$baseUrl/api/chats/$chatId/messages", method: "GET");

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        // log(data.toString());
        return data.map((e) => Message.fromJson(e)).toList();
      } else {
        print("Failed to load: ${res.statusCode} ${res.body}");
        return [];
      }
    } catch (e) {
      print("Error: $e");
      return [];
    }
  }


  Future<Directory> getDownloadFolder() async {
    final storage = await Permission.storage.request();
    final manage = await Permission.manageExternalStorage.request();

    if (!storage.isGranted && !manage.isGranted) {
      throw Exception("Storage permission denied");
    }

    final folder = Directory("/storage/emulated/0/Chatify/Download");
    if (!folder.existsSync()) {
      folder.createSync(recursive: true);
    }
    return folder;
  }


  Future<void> downloadMedia(Message message) async {
    message.downloadProgress = 0;
    messages.refresh();

    final folder = await getDownloadFolder();

    final request = http.Request('GET', Uri.parse(message.fileUrl!));
    final response = await request.send();

    // Extract file name from Content-Disposition if available
    String? contentDisposition = response.headers['content-disposition'];
    String fileName;

    if (contentDisposition != null &&
        contentDisposition.contains('filename=')) {
      fileName = contentDisposition
          .split('filename=')[1]
          .replaceAll('"', '')
          .trim();
    } else {
      // Fallback to URL file name
      fileName = message.fileUrl!.split('/').last.split('?').first;
    }

    final savePath = "${folder.path}/$fileName";
    final file = File(savePath);

    if (file.existsSync()) {
      message.localPath = savePath;
      messages.refresh();
      return;
    }

    final totalBytes = response.contentLength ?? 0;
    int received = 0;
    final sink = file.openWrite();

    await response.stream.listen((chunk) {
      received += chunk.length;
      message.downloadProgress = received / totalBytes;
      messages.refresh();
      sink.add(chunk);
    }).asFuture();

    await sink.close();

    print("FILE SAVED: $savePath");
    message.localPath = savePath;

    //For gallary
    await scanFileToGallery(savePath);

    // for local save
    await saveLocalPath(message.id, savePath);

    messages.refresh();
  }


  Future<void> initializeDownloads() async {
    for (var msg in messages) {
      // Check SharedPreferences first
      final savedPath = await getLocalSavedPath(msg.id);

      if (savedPath != null && File(savedPath).existsSync()) {
        msg.localPath = savedPath;
        continue;
      }

      // Fallback to detect file by filename in folder
      if (msg.fileUrl != null) {
        final folder = Directory("/storage/emulated/0/Chatify/Download");
        final fileName = msg.fileUrl!.split('/').last.split('?').first;
        final localPath = "${folder.path}/$fileName";

        if (File(localPath).existsSync()) {
          msg.localPath = localPath;
          await saveLocalPath(msg.id, localPath); // save to preferences
        }
      }
    }

    messages.refresh();
  }


  Future<void> saveLocalPath(int messageId, String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("msgFile_$messageId", path);
  }

  Future<String?> getLocalSavedPath(int messageId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("msgFile_$messageId");
  }

  Future<void> scanFileToGallery(String path) async {
    try {
      await MediaScanner.loadMedia(path: path);
      print("Media scanned to gallery: $path");
    } catch (e) {
      print("Gallery scan failed: $e");
    }
  }


  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();

    fetchChatType(chatId);
    loadMessages(chatId);
  }
}
