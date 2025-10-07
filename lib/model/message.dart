import 'package:cloud_firestore/cloud_firestore.dart';

// Enum to define message types
enum MessageType { text, image }

class Message {
  final String senderId;
  final String senderEmail;
  final String receiverId;
  final String message; // For text messages, this contains the text. For images, this contains the image URL
  final Timestamp timestamp;
  final MessageType type; // New field to distinguish between text and image messages
  final String? imageUrl; // Optional: Store image URL separately for clarity

  Message({
    required this.senderId,
    required this.senderEmail,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.type = MessageType.text, // Default to text message
    this.imageUrl,
  });

  // Convert Message object → Map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderEmail': senderEmail,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp,
      'type': type.toString(), // Convert enum to string for Firestore
      'imageUrl': imageUrl,
    };
  }

  // Convert Firestore Map → Message object
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      senderId: map['senderId'] ?? '',
      senderEmail: map['senderEmail'] ?? '',
      receiverId: map['receiverId'] ?? '',
      message: map['message'] ?? '',
      timestamp: (map['timestamp'] as Timestamp),
      type: _parseMessageType(map['type']), // Parse string back to enum
      imageUrl: map['imageUrl'],
    );
  }

  // Helper method to parse message type from string
  static MessageType _parseMessageType(String? typeString) {
    if (typeString == null) return MessageType.text;
    
    switch (typeString) {
      case 'MessageType.image':
        return MessageType.image;
      case 'MessageType.text':
      default:
        return MessageType.text;
    }
  }
}
