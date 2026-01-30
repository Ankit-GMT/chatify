import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/constants/time_format.dart';
import 'package:chatify/controllers/profile_controller.dart';
import 'package:chatify/models/chat_type.dart';
import 'package:chatify/models/chat_user.dart';
import 'package:chatify/services/presence_socket_service.dart';
import 'package:chatify/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatUserCard extends StatefulWidget {
  final int index;
  final Function()? onTap;
  final ChatUser? chatUser;
  final ChatType? chatType;
  final bool isSelected;
  final bool isSearch;

  const ChatUserCard(
      {super.key,
      required this.index,
      required this.onTap,
      required this.chatUser,
      required this.chatType,
      this.isSelected = false,
      this.isSearch = false});

  @override
  State<ChatUserCard> createState() => _ChatUserCardState();
}

class _ChatUserCardState extends State<ChatUserCard> {
  final profileController = Get.find<ProfileController>();

  @override
  Widget build(BuildContext context) {
    final type = widget.chatType?.type ?? '';
    final myId = profileController.user.value?.id;

    final socket = Get.find<SocketService>();
    final members = widget.chatType?.members;

// Calculate the other user's ID
    int? otherUserId;
    if (type != "GROUP" && members != null && members.length >= 2) {
      otherUserId = (myId == members[0].userId) ? members[1].userId : members[0].userId;
    }

    return ListTile(
      tileColor: widget.isSelected
          ? AppColors.primary.withAlpha(35)
          : Colors.transparent,
      onTap: widget.onTap,
      leading: InkWell(
        onTap: () {},
        child: Obx(() {
          // Check status from the global socket map
          final _ = socket.isConnected.value;
          bool isOnline = false;
          if (otherUserId != null) {
            isOnline = socket.onlineUsers[otherUserId] == true;
          }

          return Badge(
            // Only show green if online, otherwise transparent or grey
            backgroundColor: isOnline ? Colors.green : Colors.transparent,
            smallSize: 10,
            child: ProfileAvatar(
                imageUrl: type == "GROUP"
                    ? widget.chatType?.groupImageUrl ?? ''
                    : myId == widget.chatType?.members?[0].userId
                    ? (widget.chatType?.members?[1].profileImageUrl) ?? ''
                    : widget.chatType?.members?[0].profileImageUrl ?? '',
                radius: 20),
          );
        }),
      ),

      title: widget.isSearch
          ? Text("${widget.chatUser?.firstName} ${widget.chatUser?.lastName}")
          : type == "GROUP"
              ? Text(widget.chatType?.name ?? '')
              : Text(myId == widget.chatType?.members?[0].userId
                  ? ("${widget.chatType?.members?[1].firstName} ${widget.chatType?.members?[1].lastName}") ??
                      ''
                  : ("${widget.chatType?.members?[0].firstName} ${widget.chatType?.members?[0].lastName}") ??
                      ''),

      subtitle:Obx(() {
        //  Check for typing status from the socket
        final isTyping = socket.typingUsers[otherUserId ?? 0] == true;

        if (isTyping) {
          return Text(
            "Typing...",
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          );
        }

        return Row(
          children: [
            widget.chatType?.lastSenderId == myId
                ? const Icon(Icons.done_all_rounded, color: Colors.blue, size: 15)
                : const SizedBox.shrink(),
            const SizedBox(width: 5),
            SizedBox(
              width: Get.width * 0.35,
              child: Text(
                //  Use .value for the RxString
                widget.chatType?.lastMessageContent.value ?? '',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  //  Bold text if there are unread messages
                  fontWeight: (widget.chatType?.unreadCount.value ?? 0) == 0
                      ? FontWeight.w400
                      : FontWeight.w700,
                ),
                maxLines: 1,
              ),
            ),
          ],
        );
      }),

      //last message time
      trailing: Obx(() {
        final unreadCount = widget.chatType?.unreadCount.value ?? 0;
        final lastTime = widget.chatType?.lastMessageAt.value;
        print("Lasttime :- $lastTime");

        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  unreadCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (lastTime != '')
                  Text(
                    TimeFormat.formatTime(lastTime),
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (widget.chatType!.muted.value)
                      const Icon(Icons.volume_off, color: Colors.grey, size: 14),
                    if (widget.chatType!.pinned.value)
                      const Icon(Icons.push_pin, color: Colors.grey, size: 14),
                  ],
                ),
              ],
            ),
          ],
        );
      }),
    );
  }
}
