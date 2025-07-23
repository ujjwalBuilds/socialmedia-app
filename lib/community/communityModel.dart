class Community {
  final String id;
  final String name;
  final String description;
  final int postsCount;
  final int membersCount;
  final String profilePicture;
  final String backgroundImage;
  final String interest;
  final String status;
  final int likesCount;
  final int commentsCount;
  final String bio;
  final List<String> members;
  final List<String> posts;
  final DateTime createdAt;
  final DateTime updatedAt;

  Community({
    required this.id,
    required this.name,
    required this.description,
    required this.postsCount,
    required this.membersCount,
    this.profilePicture = '',
    this.backgroundImage = '',
    this.interest = '',
    this.status = '',
    this.likesCount = 0,
    this.commentsCount = 0,
    this.bio = '',
    this.members = const [],
    this.posts = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      id: json['_id'] ?? json['communityId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      postsCount: json['postCount'] ?? 0,
      membersCount: (json['members'] as List?)?.length ?? 0,
      profilePicture: json['profilePicture'] ?? '',
      backgroundImage: json['backgroundImage'] ?? '',
      interest: json['interest'] ?? '',
      status: json['status'] ?? '',
      likesCount: json['likesCount'] ?? 0,
      commentsCount: json['commentsCount'] ?? 0,
      bio: json['bio'] ?? '',
      members: List<String>.from(json['members'] ?? []),
      posts: List<String>.from(json['posts'] ?? []),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    );
  }
}
