import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:socialmedia/bottom_nav_bar/activity/acitivity_screen.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/show-liked-post-users.dart'
    show ReactionsScreen;
import 'package:socialmedia/users/show_post_content.dart';
import 'package:socialmedia/utils/reaction_constants.dart';

enum MediaType { image, video, document, audio }

class Message {
  final String id;
  final String content;
  final String senderId;
  final DateTime timestamp;
  final SharedPost? sharedPost;
  final StoryReply? entity;
  final String? replyToMessageId;
  final Message? replyToMessage;
  final String? media;
  final MediaType? mediaType;
  final String? mediaName;
  final int? mediaSize;
  final String? time;
  final List<Reaction>? reactions;
  final String? currentUserReaction;

  Message({
    required this.id,
    required this.content,
    required this.senderId,
    required this.timestamp,
    this.sharedPost,
    this.entity,
    this.replyToMessageId,
    this.replyToMessage,
    this.media,
    this.mediaType,
    this.mediaName,
    this.mediaSize,
    this.time,
    this.reactions,
    this.currentUserReaction,
  });

  Message copyWith({
    String? id,
    String? content,
    String? senderId,
    DateTime? timestamp,
    SharedPost? sharedPost,
    StoryReply? entity,
    String? replyToMessageId,
    Message? replyToMessage,
    String? media,
    MediaType? mediaType,
    String? mediaName,
    int? mediaSize,
    String? time,
    List<Reaction>? reactions,
    String? currentUserReaction,
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      senderId: senderId ?? this.senderId,
      timestamp: timestamp ?? this.timestamp,
      sharedPost: sharedPost ?? this.sharedPost,
      entity: entity ?? this.entity,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToMessage: replyToMessage ?? this.replyToMessage,
      media: media ?? this.media,
      mediaType: mediaType ?? this.mediaType,
      mediaName: mediaName ?? this.mediaName,
      mediaSize: mediaSize ?? this.mediaSize,
      time: time ?? this.time,
      reactions: reactions ?? this.reactions,
      currentUserReaction: currentUserReaction ?? this.currentUserReaction,
    );
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    SharedPost? sharedPost;
    StoryReply? storyReply;
    String content = json['content'] ?? '';

    // Try to decode content as JSON for shared posts
    try {
      final decodedContent = jsonDecode(content);
      if (decodedContent is Map<String, dynamic>) {
        if (decodedContent.containsKey('_id') &&
            decodedContent.containsKey('data')) {
          sharedPost = SharedPost.fromJson(decodedContent);
        }
      }
    } catch (e) {
      // If parsing fails, it means content is a normal text message
    }

    // Try to decode entity for story replies
    // try {
    //   final entityDecoded = jsonDecode(json['entity'] ?? '{}');
    //   if (entityDecoded is Map<String, dynamic> &&
    //       entityDecoded.containsKey('entityId') &&
    //       entityDecoded.containsKey('entity')) {
    //     storyReply = StoryReply.fromJson(entityDecoded);
    //   }
    // } catch (e) {}
    // Try to decode entity for story replies
    try {
      if (json['entity'] != null) {
        if (json['entity'] is Map<String, dynamic>) {
          // Entity is already a Map
          storyReply = StoryReply.fromJson(json['entity']);
        } else if (json['entity'] is String) {
          // Entity is a JSON string, decode it
          final entityDecoded = jsonDecode(json['entity']);
          if (entityDecoded is Map<String, dynamic>) {
            storyReply = StoryReply.fromJson(entityDecoded);
          }
        }
      }
    } catch (e) {
      print('Error parsing entity: $e');
    }

    // Handle timestamp conversion
    // DateTime parsedTimestamp;
    // if (json['timestamp'] != null) {
    //   if (json['timestamp'] is int) {
    //     parsedTimestamp =
    //         DateTime.fromMillisecondsSinceEpoch(json['timestamp'] * 1000);
    //   } else if (json['timestamp'] is String) {
    //     parsedTimestamp = DateTime.parse(json['timestamp']);
    //   } else {
    //     parsedTimestamp = DateTime.now();
    //   }
    // } else {
    //   parsedTimestamp = DateTime.now();
    // }
    // Replace the timestamp handling section with:
    DateTime parsedTimestamp;
    if (json['timestamp'] != null) {
      if (json['timestamp'] is int) {
        parsedTimestamp = DateTime.fromMillisecondsSinceEpoch(json['timestamp'] * 1000);
      } else if (json['timestamp'] is String) {
        parsedTimestamp = DateTime.parse(json['timestamp']);
      } else {
        parsedTimestamp = DateTime.now();
      }
      // Convert UTC to IST (+05:30)
      parsedTimestamp = parsedTimestamp.add(Duration(hours: 5, minutes: 30));
    } else {
      parsedTimestamp = DateTime.now().add(Duration(hours: 5, minutes: 30));
    }

    // Handle media type
    MediaType? mediaType;
    if (json['mediaType'] != null) {
      mediaType = MediaType.values.firstWhere(
        (e) => e.toString() == 'MediaType.${json['mediaType']}',
        orElse: () => MediaType.image,
      );
    }

    // Handle reactions
    List<Reaction>? reactions;
    if (json['reactions'] != null) {
      reactions = (json['reactions'] as List<dynamic>)
          .map((reaction) => Reaction.fromJson(reaction))
          .toList();
    }

    return Message(
      id: json['_id'] ?? json['id'] ?? '',
      content: sharedPost != null ? '' : content,
      senderId: json['senderId'] ?? json['senderInfo']?['_id'] ?? '',
      timestamp: parsedTimestamp,
      sharedPost: sharedPost,
      entity: storyReply,
      replyToMessageId: json['replyTo'] ?? json['replyToMessageId'],
      replyToMessage: json['replyToMessage'] != null
          ? Message.fromJson(json['replyToMessage'])
          : null,
      media: json['media'],
      mediaType: mediaType,
      mediaName: json['mediaName'],
      mediaSize: json['mediaSize'],
      time: json['time'],
      reactions: reactions,
      currentUserReaction: json['currentUserReaction'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'content': content,
      'senderId': senderId,
      'timestamp': timestamp.toIso8601String(),
      'sharedPost': sharedPost?.toJson(),
      'entity': entity?.toJson(),
      'replyToMessageId': replyToMessageId,
      'media': media,
      'mediaType': mediaType?.toString().split('.').last,
      'mediaName': mediaName,
      'mediaSize': mediaSize,
      'time': time,
      'reactions': reactions?.map((r) => r.toJson()).toList(),
      'currentUserReaction': currentUserReaction,
    };
  }
}

class SharedPost {
  final String id;
  final String author;
  final PostData data;
  final String feedId;
  final String name;

  SharedPost({
    required this.id,
    required this.author,
    required this.data,
    required this.feedId,
    required this.name,
  });

  factory SharedPost.fromJson(Map<String, dynamic> json) {
    return SharedPost(
      id: json['_id'],
      author: json['author'],
      data: PostData.fromJson(json['data']),
      feedId: json['feedId'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'author': author,
      'data': data.toJson(),
      'feedId': feedId,
      'name': name,
    };
  }
}

class PostData {
  final String content;
  final List<Media>? media;

  PostData({
    required this.content,
    this.media,
  });

  factory PostData.fromJson(Map<String, dynamic> json) {
    return PostData(
      content: json['content'],
      media: (json['media'] as List?)
          ?.map((e) => Media.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'media': media?.map((m) => m.toJson()).toList(),
    };
  }
}

class Media {
  final String url;
  final String type;

  Media({
    required this.url,
    required this.type,
  });

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      url: json['url'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'type': type,
    };
  }
}

class StoryReply {
  final String content;
  final String? storyUrl;
  final bool isBot;

  StoryReply({
    required this.content,
    this.storyUrl,
    required this.isBot,
  });

  // factory StoryReply.fromJson(Map<String, dynamic> json) {
  //   final entityDetails = json['entity'] is Map ? json['entity'] : json;
  //   return StoryReply(
  //     content: json["content"],
  //     storyUrl: entityDetails['url'],
  //     isBot: json["isBot"] ?? false,
  //   );
  // }
  factory StoryReply.fromJson(Map<String, dynamic> json) {
    // Check if there's nested entity data
    final entityDetails = json.containsKey('entity') && json['entity'] is Map ? json['entity'] as Map<String, dynamic> : json;

    return StoryReply(
      content: json["content"] ?? "",
      storyUrl: entityDetails['url'] ?? entityDetails['storyUrl'],
      isBot: json["isBot"] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'storyUrl': storyUrl,
      'isBot': isBot,
    };
  }
}

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isSender;
  final Map<String, Participant> participantsMap;
  final String currentUserId;
  final List<Reaction> reactions;
  final Function(String messageId, String emoji) onReactionSelected;
  final Function(Message message)? onReply;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isSender,
    required this.participantsMap,
    required this.currentUserId,
    required this.reactions,
    required this.onReactionSelected,
    this.onReply,
  }) : super(key: key);

  String _getSenderName() {
    if (isSender) return '';
    final participant = participantsMap[message.senderId];
    return participant?.name ?? 'Unknown User';
  }

  Widget _buildReplyPreview(BuildContext context, Message repliedMessage) {
    print('🎯 Building reply preview:');
    print('  📩 Original Message ID: ${message.id}');
    print('  ↩️ Reply To Message ID: ${message.replyToMessageId}');
    print('  💬 Reply Content: ${repliedMessage.content}');
    print('  👤 Reply Sender: ${repliedMessage.senderId}');

    final replySenderName =
        participantsMap[repliedMessage.senderId]?.name ?? 'Unknown';
    final isReplySender = repliedMessage.senderId == currentUserId;

    return Container(
      padding: EdgeInsets.all(8),
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSender ? Colors.purple[900] : Colors.grey[700],
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: Colors.white.withOpacity(0.5),
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isReplySender ? 'You' : replySenderName,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            repliedMessage.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactions() {
    if (reactions.isEmpty) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSender ? Colors.purple[900] : Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 4,
        children: reactions.map((reaction) {
          return Row(
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
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final senderName = _getSenderName();
    bool hasMedia = message.media != null && message.media!.isNotEmpty;

    if (message.replyToMessage != null) {
      print('  📝 Reply Content: ${message.replyToMessage!.content}');
    }
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
        Dismissible(
          key: Key(message.id),
          direction: DismissDirection.startToEnd,
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              if (onReply != null) {
                onReply!(message);
              }
              return false;
            }
            return false;
          },
          background: Container(
            color: Colors.purple[900]!.withOpacity(0.2),
            padding: EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Icon(
                  Icons.reply,
                  color: Colors.purple[900],
                ),
                SizedBox(width: 8),
                Text(
                  'Reply',
                  style: TextStyle(
                    color: Colors.purple[900],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 4, horizontal: 10),
            child: Column(
              crossAxisAlignment:
                  isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Stack(
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
                          if (message.replyToMessage != null)
                            _buildReplyPreview(context, message.replyToMessage!),
                          if (message.entity != null)
                            _buildStoryReply(context)
                          else if (message.sharedPost != null)
                            _buildSharedPost(context)
                          else if (hasMedia)
                            _buildMediaMessage(context)
                          else
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
                      Positioned(
                        bottom: -8,
                        right: isSender ? -8 : null,
                        left: isSender ? null : -8,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ReactionsScreen(
                                  feedId: message.id,
                                  isMessage: true,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSender ? Colors.purple[900] : Colors.grey[800],
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: reactions.map((reaction) {
                                final isCurrentUserReacted = reaction.users
                                    .any((user) => user.userId == currentUserId);
                                return Container(
                                  margin: EdgeInsets.only(right: 4),
                                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isCurrentUserReacted
                                        ? Colors.purple.withOpacity(0.2)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        reaction.emoji,
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      if (reaction.count > 0) ...[
                                        SizedBox(width: 2),
                                        Text(
                                          '${reaction.count}',
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStoryReply(BuildContext context) {
    print('🎭 Building story reply - Entity: ${message.entity}');
  print('🎭 Story URL: ${message.entity?.storyUrl}');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('replied to your story'),
            SizedBox(width: 8),
            
          ],
        ),
        SizedBox(height: 8),
        if (message.entity!.storyUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              message.entity!.storyUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 150,
            ),
          ),
                        if (message.content.isNotEmpty) ...[
                      SizedBox(height: 4),
                      Text(
                        message.content,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
      ],
    );
  }

  // Widget _buildStoryReply(BuildContext context) {
  //   return Row(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       // Left side - Text content
  //       Expanded(
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             Text(
  //               'Replied to story',
  //               style: TextStyle(
  //                 color: Colors.grey[300],
  //                 fontSize: 12,
  //                 fontStyle: FontStyle.italic,
  //               ),
  //             ),
  //             if (message.content.isNotEmpty) ...[
  //               SizedBox(height: 4),
  //               Text(
  //                 message.content,
  //                 style: GoogleFonts.poppins(
  //                   color: Colors.white,
  //                   fontSize: 14,
  //                 ),
  //               ),
  //             ],
  //           ],
  //         ),
  //       ),

  //       // Right side - Story thumbnail
  //       if (message.entity!.storyUrl != null) ...[
  //         SizedBox(width: 12),
  //         ClipRRect(
  //           borderRadius: BorderRadius.circular(8),
  //           child: Container(
  //             width: 60,
  //             height: 80,
  //             child: Image.network(
  //               message.entity!.storyUrl!,
  //               fit: BoxFit.cover,
  //               errorBuilder: (context, error, stackTrace) {
  //                 print('Error loading story image: $error');
  //                 return Container(
  //                   width: 60,
  //                   height: 80,
  //                   color: Colors.grey[600],
  //                   child: Center(
  //                     child: Icon(
  //                       Icons.broken_image,
  //                       color: Colors.white,
  //                       size: 20,
  //                     ),
  //                   ),
  //                 );
  //               },
  //               loadingBuilder: (context, child, loadingProgress) {
  //                 if (loadingProgress == null) return child;
  //                 return Container(
  //                   width: 60,
  //                   height: 80,
  //                   color: Colors.grey[600],
  //                   child: Center(
  //                     child: CircularProgressIndicator(
  //                       color: Colors.white,
  //                       strokeWidth: 2,
  //                     ),
  //                   ),
  //                 );
  //               },
  //             ),
  //           ),
  //         ),
  //       ],
  //     ],
  //   );
  // }

  Widget _buildSharedPost(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PostDetailsScreen(feedId: message.sharedPost!.feedId),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                backgroundImage: AssetImage('assets/avatar/4.png'),
                radius: 12,
              ),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  message.sharedPost!.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          if (message.sharedPost!.data.media != null &&
              message.sharedPost!.data.media!.isNotEmpty)
            Column(
              children: message.sharedPost!.data.media!.map((media) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      media.url,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 150,
                    ),
                  ),
                );
              }).toList(),
            ),
          if (message.sharedPost!.data.content.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                top: message.sharedPost!.data.media != null &&
                        message.sharedPost!.data.media!.isNotEmpty
                    ? 8
                    : 0,
              ),
              child: Text(
                message.sharedPost!.data.content,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMediaMessage(BuildContext context) {
    if (message.media == null) return SizedBox.shrink();

    // Check if the media is base64 encoded
    bool isBase64 =
        message.media!.startsWith('/9j/') || message.media!.startsWith('iVBOR');
    // Check if the media URL is a local file path
    bool isLocalFile =
        message.media!.startsWith('/') || message.media!.startsWith('file://');

    if (message.mediaType == MediaType.image) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: isBase64
            ? Image.memory(
                base64Decode(message.media!),
                fit: BoxFit.cover,
                width: double.infinity,
                height: 200,
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading base64 image: $error');
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: Center(
                      child: Icon(Icons.broken_image, size: 40),
                    ),
                  );
                },
              )
            : isLocalFile
                ? Image.file(
                    File(message.media!),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 200,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: Center(
                          child: Icon(Icons.broken_image, size: 40),
                        ),
                      );
                    },
                  )
                : Image.network(
                    message.media!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 200,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          color: Color(0xFF7400A5),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: Center(
                          child: Icon(Icons.broken_image, size: 40),
                        ),
                      );
                    },
                  ),
      );
    }

    return SizedBox.shrink();
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class Reaction {
  final String type;
  final int count;
  final List<ReactionUser> users;

  Reaction({
    required this.type,
    required this.count,
    required this.users,
  });

  Reaction copyWith({
    String? type,
    int? count,
    List<ReactionUser>? users,
  }) {
    return Reaction(
      type: type ?? this.type,
      count: count ?? this.count,
      users: users ?? this.users,
    );
  }

  factory Reaction.fromJson(Map<String, dynamic> json) {
    return Reaction(
      type: json['reactionType'],
      count: json['count'],
      users: (json['users'] as List<dynamic>)
          .map((user) => ReactionUser.fromJson(user))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'count': count,
      'users': users.map((u) => u.toJson()).toList(),
    };
  }

  String get emoji => ReactionConstants.reactionTypeToEmoji[type] ?? '❓';
}

class ReactionUser {
  final String userId;
  final String? name;
  final String? profilePic;

  ReactionUser({
    required this.userId,
    this.name,
    this.profilePic,
  });

  factory ReactionUser.fromJson(Map<String, dynamic> json) {
    return ReactionUser(
      userId: json['userId'],
      name: json['name'],
      profilePic: json['profilePic'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'profilePic': profilePic,
    };
  }
}

class ReactionSelector extends StatelessWidget {
  final Function(String) onReactionSelected;

  const ReactionSelector({required this.onReactionSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: ReactionConstants.availableReactionTypes.length,
        itemBuilder: (context, index) {
          final reactionType = ReactionConstants.availableReactionTypes[index];
          final emoji = ReactionConstants.reactionTypeToEmoji[reactionType]!;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: GestureDetector(
              onTap: () => onReactionSelected(reactionType),
              child: Text(
                emoji,
                style: TextStyle(fontSize: 32),
              ),
            ),
          );
        },
      ),
    );
  }
}
