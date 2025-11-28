enum MessageType { text, audio, offer, answer, candidate }

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isSent;
  final MessageType type;
  final String? audioPath;
  final Duration? audioDuration;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.isSent = true,
    this.type = MessageType.text,
    this.audioPath,
    this.audioDuration,
  });

  bool get isMe => isSent;
}
