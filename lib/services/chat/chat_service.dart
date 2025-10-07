import 'dart:io';
import 'package:chat_app/model/message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  // get user stream
  Stream<List<Map<String, dynamic>>> getUserStream() {
    return _firestore.collection('Users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final user = doc.data();
        return user;
      }).toList();
    });
  }

  // Send text message
  Future<void> sendMessage(String receiverId, String message) async {
    final String currentUserId = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();
    
    // Create a text message
    Message newMessage = Message(
      senderId: currentUserId,
      senderEmail: currentUserEmail,
      receiverId: receiverId,
      message: message,
      timestamp: timestamp,
      type: MessageType.text, // Explicitly set as text message
    );

    // Generate chat room ID from user IDs
    final List<String> ids = [currentUserId, receiverId];
    ids.sort();
    final String chatId = ids.join('_');

    // Add message to Firestore
    await _firestore
        .collection('chat_rooms')
        .doc(chatId)
        .collection('messages')
        .add(newMessage.toMap());
  }

  // Upload image to Firebase Storage and return download URL
  Future<String> _uploadImageToStorage(File imageFile, String chatId) async {
    try {
      // Create a unique filename using timestamp
      final String fileName = 'chat_images/${chatId}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Create reference to Firebase Storage
      final Reference storageRef = _storage.ref().child(fileName);
      
      // Upload the file
      final UploadTask uploadTask = storageRef.putFile(imageFile);
      
      // Wait for upload to complete and get download URL
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Send image message
  Future<void> sendImageMessage(String receiverId, File imageFile) async {
    final String currentUserId = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();

    // Generate chat room ID
    final List<String> ids = [currentUserId, receiverId];
    ids.sort();
    final String chatId = ids.join('_');

    try {
      // Upload image to Firebase Storage and get download URL
      final String imageUrl = await _uploadImageToStorage(imageFile, chatId);
      
      // Create an image message
      Message newMessage = Message(
        senderId: currentUserId,
        senderEmail: currentUserEmail,
        receiverId: receiverId,
        message: imageUrl, // Store image URL in message field
        timestamp: timestamp,
        type: MessageType.image, // Set as image message
        imageUrl: imageUrl, // Also store in dedicated imageUrl field for clarity
      );

      // Add message to Firestore
      await _firestore
          .collection('chat_rooms')
          .doc(chatId)
          .collection('messages')
          .add(newMessage.toMap());
    } catch (e) {
      throw Exception('Failed to send image: $e');
    }
  }

  // get messages
  Stream<QuerySnapshot> getMessages(String userId, String otherUserId) {
    final List<String> ids = [userId, otherUserId];
    ids.sort();
    final String chatId = ids.join('_');
    return _firestore
        .collection('chat_rooms')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }
}
