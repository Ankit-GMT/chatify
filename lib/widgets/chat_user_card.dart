import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/controllers/profile_controller.dart';
import 'package:chatify/models/chat_type.dart';
import 'package:chatify/models/chat_user.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatUserCard extends StatefulWidget {
  final int index;
  final Function()? onTap;
  final ChatUser? chatUser;
  final ChatType? chatType;
  final bool isSearch;

  const ChatUserCard(
      {super.key,
      required this.index,
      required this.onTap,
      required this.chatUser,
      required this.chatType,

      this.isSearch = false});

  @override
  State<ChatUserCard> createState() => _ChatUserCardState();
}

class _ChatUserCardState extends State<ChatUserCard> {
  final profileController = Get.put(ProfileController());

  @override
  Widget build(BuildContext context) {
    final type = widget.chatType?.type ?? '';
    final myId = profileController.user.value?.id;

    return ListTile(
      onTap: widget.onTap,
      leading: InkWell(
        onTap: () {},
        child: Badge(
          backgroundColor: Colors.green,
          smallSize: 10,
          child: CircleAvatar(
            backgroundImage: NetworkImage(type=="GROUP" ? widget.chatType?.groupImageUrl ?? '' :  myId==widget.chatType?.members?[0].userId ? (widget.chatType?.members?[1].profileImageUrl) ?? '' : widget.chatType?.members?[0].profileImageUrl ?? ''),
          ),
        ),
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

      subtitle: Row(
        children: [
          true
              ? const Icon(Icons.done_all_rounded, color: Colors.blue, size: 15)
              : const Icon(Icons.done_all, color: Colors.white, size: 15),
          SizedBox(
            width: 5,
          ),
          SizedBox(
            width: 130,
            child: Text('Hey, How are you?',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 12),
                maxLines: 1),
          ),
        ],
      ),

      //last message time
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "05:15",
            style:
                GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            // width: 34,
            // height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(100),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              "55",
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }
}
