import 'package:chatify/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatUserCard extends StatefulWidget {
  final index;

  const ChatUserCard({super.key, required this.index});

  @override
  State<ChatUserCard> createState() => _ChatUserCardState();
}

class _ChatUserCardState extends State<ChatUserCard> {
  final List<String> peopleImages = [
    "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d",
    // portrait man
    "https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e",
    // smiling woman
    "https://images.unsplash.com/photo-1520813792240-56fc4a3765a7",
    // group of friends
    "https://images.unsplash.com/photo-1544005313-94ddf0286df2",
    // woman portrait
    "https://images.unsplash.com/photo-1524504388940-b1c1722653e1",
    // man portrait
    "https://images.unsplash.com/photo-1500648767791-00dcc994a43e",
    // business look
    "https://images.unsplash.com/photo-1517841905240-472988babdf9",
    // friends laughing
    "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d",
    // portrait man
    "https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e",
    // smiling woman
    "https://images.unsplash.com/photo-1520813792240-56fc4a3765a7",
    // group of friends
    "https://images.unsplash.com/photo-1544005313-94ddf0286df2",
    // woman portrait
    "https://images.unsplash.com/photo-1524504388940-b1c1722653e1",
    // man portrait
    "https://images.unsplash.com/photo-1500648767791-00dcc994a43e",
    // business look
    "https://images.unsplash.com/photo-1517841905240-472988babdf9",
    // friends laughing
    "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d",
    // portrait man
    "https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e",
    // smiling woman
    "https://images.unsplash.com/photo-1520813792240-56fc4a3765a7",
    // group of friends
    "https://images.unsplash.com/photo-1544005313-94ddf0286df2",
    // woman portrait
    "https://images.unsplash.com/photo-1524504388940-b1c1722653e1",
    // man portrait
    "https://images.unsplash.com/photo-1500648767791-00dcc994a43e",
    // business look
  ];

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {},
      leading: InkWell(
          onTap: () {},
          child: Badge(
            backgroundColor: Colors.green,
            smallSize: 10,
            child: CircleAvatar(
                backgroundImage: NetworkImage(peopleImages[widget.index])),
          )),

      title: Text("Ankit Patel"),

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
                style: GoogleFonts.poppins(fontSize: 12), maxLines: 1),
          ),
        ],
      ),

      //last message time
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "05:15",
            style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w400
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 5,vertical: 1),
            // width: 34,
            // height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(82),
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
