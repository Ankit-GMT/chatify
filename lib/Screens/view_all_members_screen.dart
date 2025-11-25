import 'package:chatify/models/chat_type.dart';
import 'package:flutter/material.dart';

class ViewAllMembersScreen extends StatelessWidget {
  final ChatType? chatType;
  const ViewAllMembersScreen({super.key, required this.chatType});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
       Text(
          "Members",
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
      body:
      Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: chatType!.members!.length,
            scrollDirection: Axis.vertical,
            itemBuilder: (context, index) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(
                      chatType!.members![index].profileImageUrl! ?? ''),
                ),
                title: Text(
                    "${chatType!.members![index].firstName} ${chatType!.members![index].lastName}"),
                subtitle: Text(
                  chatType!.members![index].role!,
                  style: TextStyle(fontSize: 12),
                ),
              );
            },
            separatorBuilder: (context, index) {
              return Divider(
                thickness: 0.5,
                indent: 15,
                endIndent: 15,
              );
            }),
      ),
    );
  }
}
