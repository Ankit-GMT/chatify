
class Message {
  final int id;
  final int roomId;
  final int senderId;
  final String senderFirstName;
  final String senderLastName;
  final String? senderProfileImageUrl;

  final String content;
  final String type;

  // File fields (for IMAGE, VIDEO, AUDIO, DOCUMENT)
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final String? fileMimeType;
  final String? thumbnailUrl;
  final int? duration;

  final DateTime sentAt;

  // Message state
  final bool deleted;
  final bool edited;
  final DateTime? editedAt;

  // ===== Local States (not coming from API) =====
  String? localPath; // where file is stored locally
  double downloadProgress; // 0 - 1 value

  bool get isDownloaded => localPath != null;

  Message({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderFirstName,
    required this.senderLastName,
    required this.senderProfileImageUrl,
    required this.content,
    required this.type,
    required this.sentAt,

    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.fileMimeType,
    this.thumbnailUrl,
    this.duration,

    required this.deleted,
    required this.edited,
    this.editedAt,

    // default values
    this.localPath,
    this.downloadProgress = 0.0,

  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      roomId: json['roomId'],
      senderId: json['senderId'],

      senderFirstName: json['senderFirstName'],
      senderLastName: json['senderLastName'],
      senderProfileImageUrl: json['senderProfileImageUrl'],

      content: json['content'] ?? "",
      type: json['type'] ?? "TEXT",

      // File fields
      fileUrl: json['fileUrl'],
      fileName: json['fileName'],
      fileSize: json['fileSize'],
      fileMimeType: json['fileMimeType'],
      thumbnailUrl: json['thumbnailUrl'],
      duration: json['duration'],

      sentAt: DateTime.parse(json['sentAt']),

      deleted: json['deleted'] ?? false,
      edited: json['edited'] ?? false,
      editedAt: json['editedAt'] != null ? DateTime.parse(json['editedAt']) : null,
    );
  }
}







// class Message {
//   final int id;
//   final int roomId;
//   final int senderId;
//   final String content;
//   final String type;
//   final DateTime sentAt;
//   final String senderFirstName;
//   final String senderLastName;
//   final String senderProfileImageUrl;
//
//    Message({
//     required this.id,
//     required this.roomId,
//     required this.senderId,
//     required this.content,
//     required this.type,
//     required this.sentAt,
//      required this.senderFirstName,
//      required this.senderLastName,
//      required this.senderProfileImageUrl,
//   });
//
//   factory Message.fromJson(Map<String, dynamic> json) {
//     return Message(
//       id: json['id'],
//       roomId: json['roomId'],
//       senderId: json['senderId'],
//       content: json['content'],
//       type: json['type'],
//       sentAt: DateTime.parse(json['sentAt']),
//       senderFirstName: json['senderFirstName'],
//       senderLastName: json['senderLastName'],
//       senderProfileImageUrl: json['senderProfileImageUrl'],
//
//     );
//   }
// }
