import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:socialmedia/users/story_section.dart';

class StoryAvatar extends StatelessWidget {
  final Story_Item story;

  const StoryAvatar({
    required this.story,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: story.isLive
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF7400A5),
                    border: Border.all(
                      color: Colors.transparent,
                      width: 0.5,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(2),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(story.profilepic),
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'is Live',
                  style: GoogleFonts.poppins(fontSize: 9.sp, color: Color(0xFF7400A5), fontWeight: FontWeight.w400),
                ),
                SizedBox(height: 1),
                Text(
                  story.name,
                  style: GoogleFonts.poppins(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontSize: 12.sp, fontWeight: FontWeight.w500),
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: story.seen == 0 ? Color(0xFF7400A5) : Colors.grey,
                    border: Border.all(
                      color: Colors.transparent,
                      width: 0.5,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(2),
                    child: CircleAvatar(radius: 30, backgroundImage: NetworkImage(story.profilepic)),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  story.name.length > 10 ? '${story.name.substring(0, 10)}...' : story.name,
                  style: GoogleFonts.poppins(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontSize: 12.sp, fontWeight: FontWeight.w500),
                ),
              ],
            ),
    );
  }
}

class Story_Item {
  final String imageUrl;
  final String name;
  final String profilepic;
  final String authorId;
  final int createdAt;
  final String ago;
  final String storyid;
  final bool isLive;
  final String? channelName;
  final int seen;

  Story_Item({required this.imageUrl, required this.name, required this.profilepic, required this.authorId, required this.createdAt, required this.ago, required this.isLive, this.channelName, required this.storyid, required this.seen});

  // Named factory constructor to convert JSON to StoryItem
  factory Story_Item.fromJson(Map<String, dynamic> json) {
    return Story_Item(imageUrl: json['url'] ?? '', name: json['name'] ?? '', authorId: json['author'] ?? '', createdAt: json['createdAt'] ?? 0, ago: json['ago_time'] ?? '', storyid: json['_id'], isLive: json['isLive'] ?? false, seen: json['seen'] ?? 0, profilepic: json['profilePic'] ?? '');
  }
}
