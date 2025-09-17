class Message {
  final String id;
  final String text;
  final String sender;
  final DateTime time;
  final bool isMe;

  Message({
    required this.id,
    required this.text,
    required this.sender,
    required this.time,
    required this.isMe,
  });
}

List<Message> messages = [
  Message(
    id: "1",
    text: "Hey! How are you?",
    sender: "Alice",
    time: DateTime.now().subtract(Duration(minutes: 5)),
    isMe: false,
  ),
  Message(
    id: "2",
    text: "I'm good, thanks! How about you?",
    sender: "Me",
    time: DateTime.now().subtract(Duration(minutes: 4)),
    isMe: true,
  ),
  Message(
    id: "3",
    text: "Doing well, just working on a Flutter app 😃",
    sender: "Alice",
    time: DateTime.now().subtract(Duration(minutes: 3)),
    isMe: false,
  ),
  Message(
    id: "4",
    text: "That’s awesome! 🚀",
    sender: "Me",
    time: DateTime.now().subtract(Duration(minutes: 2)),
    isMe: true,
  ),
  Message(
    id: "5",
    text: "Hey! How are you?",
    sender: "Alice",
    time: DateTime.now().subtract(Duration(minutes: 5)),
    isMe: false,
  ),
  Message(
    id: "6",
    text: "I'm good, thanks! How about you?",
    sender: "Me",
    time: DateTime.now().subtract(Duration(minutes: 4)),
    isMe: true,
  ),
  Message(
    id: "7",
    text: "Doing well, just working on a Flutter app 😃",
    sender: "Alice",
    time: DateTime.now().subtract(Duration(minutes: 3)),
    isMe: false,
  ),
  Message(
    id: "8",
    text: "That’s awesome! 🚀",
    sender: "Me",
    time: DateTime.now().subtract(Duration(minutes: 2)),
    isMe: true,
  ),
  Message(
    id: "9",
    text: "Hey! How are you?",
    sender: "Alice",
    time: DateTime.now().subtract(Duration(minutes: 5)),
    isMe: false,
  ),
  Message(
    id: "10",
    text: "I'm good, thanks! How about you?",
    sender: "Me",
    time: DateTime.now().subtract(Duration(minutes: 4)),
    isMe: true,
  ),
  Message(
    id: "11",
    text: "Doing well, just working on a Flutter app 😃",
    sender: "Alice",
    time: DateTime.now().subtract(Duration(minutes: 3)),
    isMe: false,
  ),
  Message(
    id: "12",
    text: "That’s awesome! 🚀",
    sender: "Me",
    time: DateTime.now().subtract(Duration(minutes: 2)),
    isMe: true,
  ),

];