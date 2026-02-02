import 'package:get/get.dart';

class Message {
  final int id;
  final int roomId;
  final int senderId;

  final String senderFirstName;
  final String senderLastName;
  final String? senderProfileImageUrl;

  final String content;
  final String type; // TEXT, SYSTEM_BACKGROUND_CHANGE, etc.

  // File / Media
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

  // Status reply
  final bool isStatusReply;
  final int? statusId;
  final String? statusPreview;

  // Date grouping
  final String? dateLabel; // "19/01/2026", "Today"

  // Delivery / read
  final RxBool isDelivered;
  final RxBool isRead;
  final Rx<DateTime?> deliveredAt;
  final Rx<DateTime?> readAt;

  final int totalRecipients;
  final int deliveredCount;
  final int readCount;
  final dynamic readReceipts;

  // Local only
  final Rx<String?> localPath;
  final RxDouble downloadProgress;

  bool get isDownloaded => localPath.value != null;

  Message({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderFirstName,
    required this.senderLastName,
    required this.senderProfileImageUrl,
    required this.content,
    required this.type,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.fileMimeType,
    this.thumbnailUrl,
    this.duration,
    required this.sentAt,
    required this.deleted,
    required this.edited,
    this.editedAt,
    required this.isStatusReply,
    this.statusId,
    this.statusPreview,
    required this.dateLabel,
    required bool isDelivered,
    required bool isRead,
    DateTime? deliveredAt,
    DateTime? readAt,
    required this.totalRecipients,
    required this.deliveredCount,
    required this.readCount,
    this.readReceipts,
    String? localPath,
    double downloadProgress = 0.0,
  })  : isDelivered = isDelivered.obs,
        isRead = isRead.obs,
        deliveredAt = deliveredAt.obs,
        readAt = readAt.obs,
        localPath = localPath.obs,
        downloadProgress = downloadProgress.obs;

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      roomId: json['roomId'],
      senderId: json['senderId'],
      senderFirstName: json['senderFirstName'] ?? "",
      senderLastName: json['senderLastName'] ?? "",
      senderProfileImageUrl: json['senderProfileImageUrl'],
      content: json['content'] ?? "",
      type: json['type'] ?? "TEXT",
      fileUrl: json['fileUrl'],
      fileName: json['fileName'],
      fileSize: (json['fileSize'] as num?)?.toInt(),
      fileMimeType: json['fileMimeType'],
      thumbnailUrl: json['thumbnailUrl'],
      duration: json['duration'],
      sentAt: DateTime.parse(json['sentAt']),
      deleted: json['deleted'] ?? false,
      edited: json['edited'] == true,
      editedAt:
          json['editedAt'] != null ? DateTime.parse(json['editedAt']) : null,
      isStatusReply: json['isStatusReply'] ?? false,
      statusId: json['statusId'],
      statusPreview: json['statusPreview'],
      dateLabel: json['dateLabel'] ?? "",
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'])
          : null,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      isDelivered: json['isDelivered'] ?? false,
      isRead: json['isRead'] ?? false,
      totalRecipients: json['totalRecipients'] ?? 0,
      deliveredCount: json['deliveredCount'] ?? 0,
      readCount: json['readCount'] ?? 0,
      readReceipts: json['readReceipts'],
    );
  }
}

// class Message {
//   final int id;
//   final int roomId;
//   final int senderId;
//   final String senderFirstName;
//   final String senderLastName;
//   final String? senderProfileImageUrl;
//
//   final String content;
//   final String type;
//
//   // File fields (for IMAGE, VIDEO, AUDIO, DOCUMENT)
//   final String? fileUrl;
//   final String? fileName;
//   final int? fileSize;
//   final String? fileMimeType;
//   final String? thumbnailUrl;
//   final int? duration;
//
//   final DateTime sentAt;
//
//   // Message state
//   final bool deleted;
//   final bool edited;
//   final DateTime? editedAt;
//
//   // ===== Local States (not coming from API) =====
//   String? localPath; // where file is stored locally
//   double downloadProgress; // 0 - 1 value
//
//   bool get isDownloaded => localPath != null;
//   final String? dateLabel;
//
//   Message({
//     required this.id,
//     required this.roomId,
//     required this.senderId,
//     required this.senderFirstName,
//     required this.senderLastName,
//     required this.senderProfileImageUrl,
//     required this.content,
//     required this.type,
//     required this.sentAt,
//
//     this.fileUrl,
//     this.fileName,
//     this.fileSize,
//     this.fileMimeType,
//     this.thumbnailUrl,
//     this.duration,
//
//     required this.deleted,
//     required this.edited,
//     this.editedAt,
//
//     // default values
//     this.localPath,
//     this.downloadProgress = 0.0,
//     this.dateLabel = "",
//
//   });
//
//   factory Message.fromJson(Map<String, dynamic> json) {
//     return Message(
//       id: json['id'],
//       roomId: json['roomId'],
//       senderId: json['senderId'],
//
//       senderFirstName: json['senderFirstName'] ?? "",
//       senderLastName: json['senderLastName'] ?? "",
//       senderProfileImageUrl: json['senderProfileImageUrl'],
//
//       content: json['content'] ?? "",
//       type: json['type'] ?? "TEXT",
//
//       // File fields
//       fileUrl: json['fileUrl'],
//       fileName: json['fileName'],
//       fileSize: json['fileSize'],
//       fileMimeType: json['fileMimeType'],
//       thumbnailUrl: json['thumbnailUrl'],
//       duration: json['duration'],
//
//       sentAt: DateTime.parse(json['sentAt']),
//
//       deleted: json['deleted'] ?? false,
//       edited: json['edited'] ?? false,
//       editedAt: json['editedAt'] != null ? DateTime.parse(json['editedAt']) : null,
//       dateLabel: json['dateLabel'],
//     );
//   }
// }
