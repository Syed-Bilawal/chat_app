import 'package:chat_app/services/auth_service.dart';
import 'package:chat_app/services/chat/chat_service.dart';
import 'package:chat_app/utils/app_utils.dart';
import 'package:chat_app/views/chat_page.dart';
import 'package:chat_app/views/user_tile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ChatService chatService = ChatService();
  final AuthService authService = AuthService();
  void logout() async {
    if (!mounted) return;
    AppUtils.showLoading(context);
    await authService.signOut();
    AppUtils.hideLoading(context);
  }

  User getCurrentUser() {
    return authService.currentUser!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        centerTitle: true,
        actions: [IconButton(onPressed: logout, icon: Icon(Icons.logout))],
      ),
      body: _buildUserList(),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: chatService.getUserStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          final users = snapshot.data!;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return _buildUserListItem(user, context);
            },
          );
        } else {
          return const Center(child: Text('No users found'));
        }
      },
    );
  }

  Widget _buildUserListItem(
    Map<String, dynamic> userData,
    BuildContext context,
  ) {
    if (userData['email'] != getCurrentUser().email) {
      return UserTile(
        name: userData['email'],
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatPage(
                receiverEmail: userData['email'],
                receiverId: userData['uid'],
              ),
            ),
          );
        },
      );
    }
    return SizedBox();
  }
}
