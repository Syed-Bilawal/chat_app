import 'package:flutter/material.dart';

class UserTile extends StatefulWidget {
  final String name;
  final VoidCallback? onTap; 

  const UserTile({super.key, required this.name, this.onTap});

  @override
  State<UserTile> createState() => _UserTileState();
}

class _UserTileState extends State<UserTile> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(radius: 25, child: Icon(Icons.person)),
            const SizedBox(width: 16),
            Text(widget.name),
          ],
        ),
      ),
    );
  }
}
