import 'package:flutter/material.dart';

class ChatMessage extends StatelessWidget {
  final Map<String, dynamic> messageData;

  ChatMessage({required this.messageData});

  @override
  Widget build(BuildContext context) {
    // Extracting the necessary information
    var senderInfo = messageData['senderInfo'];
    var name = senderInfo['name'] ?? 'Unknown';
    var profilePic = senderInfo['profilePic'] ?? '';
    var message = messageData['message'] ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Circle avatar for the sender
          CircleAvatar(
            backgroundColor: Colors.grey.shade300,
            backgroundImage: profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
            child: profilePic.isEmpty
                ? Text(
                    name[0].toUpperCase(),
                    style: TextStyle(color: Colors.black),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          // Message container
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    message,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
