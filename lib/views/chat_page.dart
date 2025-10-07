import 'dart:io';
import 'package:chat_app/model/message.dart';
import 'package:chat_app/services/auth_service.dart';
import 'package:chat_app/services/chat/chat_service.dart';
import 'package:chat_app/services/permission/permission_handler.dart';
import 'package:chat_app/utils/app_utils.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ChatPage extends StatefulWidget {
  final String receiverEmail;
  final String receiverId;
  const ChatPage({
    super.key,
    required this.receiverEmail,
    required this.receiverId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

final TextEditingController messageController = TextEditingController();
final AuthService authService = AuthService();
final ChatService chatService = ChatService();

class _ChatPageState extends State<ChatPage> {
  final ImagePicker _imagePicker = ImagePicker();

  // Send text message
  void sendMessage() {
    final String message = messageController.text.trim();
    if (message.isNotEmpty) {
      chatService.sendMessage(widget.receiverId, message);
      messageController.clear();
    }
  }

  // Handle gallery button tap - Request permission and pick image
  Future<void> _onGalleryButtonTapped() async {
    try {
      print('🔍 Gallery button tapped - requesting permission...');
      
      // Request gallery permission using our PermissionHandler
      final bool hasPermission = await PermissionHandler.requestGalleryPermission(context);
      
      print('📋 Permission result: $hasPermission');
      
      if (!hasPermission) {
        // Permission denied, show error message
        print('❌ Permission denied');
        AppUtils.showErrorToast('Gallery permission is required to send images');
        return;
      }

      print('✅ Permission granted, proceeding to pick image...');
      // Permission granted, proceed to pick image
      await _pickAndSendImage();
    } catch (e) {
      print('💥 Error in gallery button tap: $e');
      AppUtils.showErrorToast('Error accessing gallery: $e');
    }
  }

  // Pick image from gallery and send it
  Future<void> _pickAndSendImage() async {
    try {
      // Show loading while picking image
      AppUtils.showLoading(context);
      
      // Pick image from gallery
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Compress image to reduce file size
        maxWidth: 1024,   // Limit image width for better performance
        maxHeight: 1024,  // Limit image height for better performance
      );

      // Hide loading
      if (mounted) AppUtils.hideLoading(context);

      if (pickedFile != null) {
        // Convert XFile to File
        final File imageFile = File(pickedFile.path);
        
        // Show loading while uploading image
        if (mounted) AppUtils.showLoading(context);
        
        // Send image message using ChatService
        await chatService.sendImageMessage(widget.receiverId, imageFile);
        
        // Hide loading after successful upload
        if (mounted) AppUtils.hideLoading(context);
        
        // Show success message
        AppUtils.showSuccessToast('Image sent successfully!');
      }
    } catch (e) {
      // Hide loading in case of error
      if (mounted) AppUtils.hideLoading(context);
      
      // Show error message
      AppUtils.showErrorToast('Failed to send image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: Text(widget.receiverEmail)),
      body: Column(
        children: [
          Expanded(child: buildMessageList()),
          buildMessageInput(),
        ],
      ),
    );
  }

  Widget buildMessageList() {
    return StreamBuilder(
      stream: chatService.getMessages(
        authService.currentUser!.uid,
        widget.receiverId,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          final messages = snapshot.data!.docs;
          return ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final messageData = messages[index].data() as Map<String, dynamic>;
              
              // Parse message type (default to text for backward compatibility)
              final String messageTypeString = messageData['type'] ?? 'MessageType.text';
              final bool isImageMessage = messageTypeString == 'MessageType.image';
              
              bool isCurrentUser = messageData['senderId'] == authService.currentUser!.uid;
              var alignment = isCurrentUser ? Alignment.centerRight : Alignment.centerLeft;
              
              return Align(
                alignment: alignment,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.all(8),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7, // Limit message width
                  ),
                  decoration: BoxDecoration(
                    color: isCurrentUser ? Colors.blue : Colors.grey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: isImageMessage 
                    ? _buildImageMessage(messageData['message']) // Build image widget
                    : _buildTextMessage(messageData['message']),   // Build text widget
                ),
              );
            },
          );
        } else {
          return const Center(
            child: Text(
              'No messages found',
              style: TextStyle(color: Colors.black),
            ),
          );
        }
      },
    );
  }

  // Build text message widget
  Widget _buildTextMessage(String message) {
    return Text(
      message,
      style: const TextStyle(color: Colors.white),
    );
  }

  // Build image message widget
  Widget _buildImageMessage(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
        width: 200,
        height: 200,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          
          // Show loading indicator while image loads
          return Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          // Show error widget if image fails to load
          return Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Colors.red),
                Text('Failed to load image', style: TextStyle(color: Colors.red)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          // Gallery button - allows users to pick and send images
          IconButton(
            icon: const Icon(Icons.photo, color: Colors.blue),
            onPressed: _onGalleryButtonTapped, // Call our gallery handler
            tooltip: 'Send Image', // Helpful tooltip for users
          ),
          
          // Text input field
          Expanded(
            child: TextFormField(
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please enter a message';
                }
                return null;
              },
              controller: messageController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Type your message',
              ),
              // Allow users to send message by pressing Enter
              onFieldSubmitted: (value) => sendMessage(),
            ),
          ),
          
          // Send button for text messages
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blue), 
            onPressed: sendMessage,
            tooltip: 'Send Message',
          ),
        ],
      ),
    );
  }
}
