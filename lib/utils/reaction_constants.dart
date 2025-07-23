// Create a new file reaction_constants.dart
class ReactionConstants {
  static const Map<String, String> reactionTypeToEmoji = {
    'like': '👍',
    'love': '❤️',
    'haha': '😂',
    'wow': '😮',
    'sad': '😢',
    'pray': '🙏',
  };

  static const Map<String, String> emojiToReactionType = {
    '👍': 'like',
    '❤️': 'love',
    '😂': 'haha',
    '😮': 'wow',
    '😢': 'sad',
    '🙏': 'pray',
  };

  static const List<String> availableReactionTypes = [
    'like',
    'love',
    'haha',
    'wow',
    'sad',
    'pray',
  ];
}