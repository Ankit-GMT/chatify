import 'package:chatify/Screens/main_screen.dart';
import 'package:chatify/constants/apis.dart';
import 'package:chatify/services/api_service.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class GroupController extends GetxController {
  var isLoading = false.obs;
  final String baseUrl = APIs.url;

  final box = GetStorage();

  final RxSet<int> selectedContacts = <int>{}.obs;
  final RxSet<int> currentGroupMembers = <int>{}.obs;

  void loadCurrentMembers(List<int> memberIds) {
    currentGroupMembers.assignAll(memberIds);
  }

  Future<void> createGroup({
    required String name,
    required String groupImageUrl,
    required List<int> memberIds,
    required int currentUserId,
  }) async {
    if (memberIds.isEmpty) {
      Get.snackbar("Error", "Select at least 1 contact");
      return;
    }

    final body = {
      "name": name,
      "groupImageUrl": groupImageUrl,
      "memberIds": memberIds
          .where((id) => id != currentUserId) // exclude yourself
          .toList(),
    };

    print("API Payload: $body");

    try {
      isLoading.value = true;
      final token = box.read("accessToken");

      // final res = await http.post(
      //   Uri.parse("$baseUrl/api/groups"),
      //   headers: {
      //     "Content-Type": "application/json",
      //     "Authorization": "Bearer $token",
      //   },
      //   body: jsonEncode(body),
      // );

      final res = await ApiService.request(
          url: "$baseUrl/api/groups", method: "POST", body: body);

      isLoading.value = false;

      if (res.statusCode == 200 || res.statusCode == 201) {
        Get.snackbar("Success", "Group created successfully");
        selectedContacts.clear();
        Get.offAll(()=> MainScreen());
        print("Group Created: ${res.body}");
      } else {
        Get.snackbar("Error", "Failed: ${res.statusCode}");
        print("Error: ${res.body}");
      }
    } catch (e) {
      isLoading.value = false;
      Get.snackbar("Error", "Something went wrong");
      print("Exception: $e");
    }
  }

  // for add member

  Future<void> addMembers({
    required int groupId,
    required List<int> memberIds,
  }) async {
    final body = {"memberIds": memberIds};

    try {
      isLoading.value = true;
      final response = await ApiService.request(
          url: "$baseUrl/api/groups/$groupId/members",
          method: "POST",
          body: body);

      isLoading.value = false;
      if (response.statusCode == 200) {
        Get.snackbar("Success", "Members added successfully");
        selectedContacts.clear();
        Get.offAll(()=> MainScreen());
      } else {
        print("Failed to add members: ${response.body}");
      }
    } catch (e) {
      isLoading.value = false;
      Get.snackbar("Error", "Something went wrong");
    }
  }

  // for delete group (admin)

  Future<void> deleteGroup({
    required int groupId,
  }) async {
    try {
      isLoading.value = true;
      final response = await ApiService.request(
          url: "$baseUrl/api/groups/$groupId",
          method: "DELETE");

      isLoading.value = false;
      if (response.statusCode == 200) {
        Get.snackbar("Success", "Group deleted successfully");
        Get.offAll(()=> MainScreen());
      } else {
        Get.snackbar("Error","Failed to delete group: ${response.body}");
      }
    } catch (e) {
      isLoading.value = false;
      Get.snackbar("Error", "Something went wrong");
    }
  }

  // For exit group (except admin)

  Future<void> exitGroup({
    required int groupId,
  }) async {
    try {
      isLoading.value = true;
      final response = await ApiService.request(
          url: "$baseUrl/api/groups/$groupId/exit",
          method: "POST");

      isLoading.value = false;
      if (response.statusCode == 200) {
        Get.snackbar("Success", "You have left the group successfully");
        Get.offAll(()=> MainScreen());
      } else {
        Get.snackbar("Error","Failed to exit group: ${response.body}");
      }
    } catch (e) {
      isLoading.value = false;
      Get.snackbar("Error", "Something went wrong");
    }
  }

  void onTap(int id) {
    if (selectedContacts.contains(id)) {
      selectedContacts.remove(id);
    } else {
      selectedContacts.add(id);
    }
    update();
  }

  @override
  void onClose() {
    // TODO: implement onClose
    super.onClose();
    selectedContacts.clear();
  }
}
