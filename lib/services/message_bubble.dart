import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:socialmedia/services/message.dart';
import 'package:socialmedia/bottom_nav_bar/activity/acitivity_screen.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isSender;
  final Map<String, Participant> participantsMap;
  final String currentUserId;
  final Message? repliedToMessage;
  final List<Reaction> reactions;
  final Function(String, String)? onReactionSelected;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isSender,
    required this.participantsMap,
    required this.currentUserId,
    this.repliedToMessage,
    this.reactions = const [],
    this.onReactionSelected,
  }) : super(key: key);

  String _getSenderName() {
    if (isSender) return ''; // Don't show name for your own messages
    final participant = participantsMap[message.senderId];
    return participant?.name ?? 'Unknown User';
  }

  Widget _buildReplyPreview(BuildContext context) {
    if (message.replyToMessage == null) return SizedBox.shrink();

    final repliedMessage = message.replyToMessage!;
    final repliedToUser = participantsMap[repliedMessage.senderId]?.name ?? 'Unknown User';

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reply to $repliedToUser',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            repliedMessage.content,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 12,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildReactions() {
    if (reactions.isEmpty) return SizedBox.shrink();

    return Wrap(
      spacing: 4,
      children: reactions.map((reaction) {
        final isSelected = message.currentUserReaction == reaction.type;
        return GestureDetector(
          onTap: () {
            if (onReactionSelected != null) {
              onReactionSelected!(
                message.id,
                isSelected ? '' : reaction.type,
              );
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.purple.withOpacity(0.3)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  reaction.emoji,
                  style: TextStyle(fontSize: 16),
                ),
                if (reaction.count > 0) ...[
                  SizedBox(width: 4),
                  Text(
                    '${reaction.count}',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final senderName = _getSenderName();

    return Column(
      crossAxisAlignment:
          isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (senderName.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 2),
            child: Text(
              senderName,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        Container(
          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 10),
          child: Column(
            crossAxisAlignment:
                isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                decoration: BoxDecoration(
                  color:
                      isSender ? const Color(0xFF7400A5) : Colors.grey[800],
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildReplyPreview(context),
                    Text(
                      message.content,
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                    if (message.time != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          message.time!,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 9,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (reactions.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: _buildReactions(),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
