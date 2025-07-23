import 'dart:convert';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:socialmedia/bottom_nav_bar/explore-pages/show-liked-post-users.dart';
import 'package:socialmedia/utils/colors.dart';
import 'package:socialmedia/utils/constants.dart';

// 1. Create a provider to manage reactions globally
class ReactionsProvider extends ChangeNotifier {
  // Map to store reactions by entityId
  final Map<String, List<ReactionData>> _reactionsByEntity = {};
  // Map to track current user reactions by entityId
  final Map<String, String?> _userReactionsByEntity = {};
  // Map to track loading state by entityId
  final Map<String, bool> _loadingStates = {};

  String? getUserReactionForEntity(String entityId) {
    return _userReactionsByEntity[entityId];
  }

  List<ReactionData> getReactionsForEntity(String entityId) {
    return _reactionsByEntity[entityId] ?? [];
  }

  bool isLoadingForEntity(String entityId) {
    return _loadingStates[entityId] ?? false;
  }

  int getTotalReactionsCount(String entityId) {
    int count = 0;
    final reactions = _reactionsByEntity[entityId] ?? [];
    for (var reaction in reactions) {
      count += reaction.count;
    }
    return count;
  }

  void setLoadingState(String entityId, bool isLoading) {
    _loadingStates[entityId] = isLoading;
    notifyListeners();
  }

  Future<void> fetchReactions(String entityId, String entityType, String userId, String token) async {
    setLoadingState(entityId, true);

    try {
      final response = await http.post(
        Uri.parse('${BASE_URL}api/get-all-reactions'),
        headers: {
          'Content-Type': 'application/json',
          'userId': userId,
          'token': token,
        },
        body: jsonEncode({
          'entityId': entityId,
          'entityType': entityType,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<ReactionData> fetchedReactions = [];
        String? userReaction;

        for (var reaction in data['reactions']) {
          final reactionData = ReactionData(
            type: reaction['reactionType'],
            count: reaction['count'],
            users: (reaction['users'] as List)
                .map((user) => UserData(
                      id: user['userId'],
                      name: user['name'],
                      profilePic: user['profilePic'],
                    ))
                .toList(),
          );

          fetchedReactions.add(reactionData);

          // Check if current user has reacted
          final userHasReacted = reactionData.users.any((user) => user.id == userId);
          if (userHasReacted) {
            userReaction = reactionData.type;
          }
        }

        _reactionsByEntity[entityId] = fetchedReactions;
        _userReactionsByEntity[entityId] = userReaction;
        setLoadingState(entityId, false);
      } else {
        print('Failed to fetch reactions: ${response.statusCode}');
        setLoadingState(entityId, false);
      }
    } catch (e) {
      print('Error fetching reactions: $e');
      setLoadingState(entityId, false);
    }
  }

  Future<void> addReaction(String entityId, String entityType, String reactionType, String userId, String token) async {
    // Store the previous reaction for potential rollback
    final previousReaction = _userReactionsByEntity[entityId];

    // Optimistically update the UI
    _optimisticallyUpdateReaction(entityId, reactionType, userId);

    try {
      final response = await http.post(
        Uri.parse('${BASE_URL}api/reaction'),
        headers: {
          'Content-Type': 'application/json',
          'userId': userId,
          'token': token,
        },
        body: jsonEncode({
          'entityId': entityId,
          'entityType': entityType,
          'reactionType': reactionType,
        }),
      );

      if (response.statusCode != 200) {
        // If the API call fails, revert the change
        _userReactionsByEntity[entityId] = previousReaction;
        // We need to reverse the optimistic update
        _optimisticallyRemoveReaction(entityId, userId, reactionType);
        if (previousReaction != null) {
          _optimisticallyUpdateReaction(entityId, previousReaction, userId);
        }
        notifyListeners();
      }
      // On success, the UI is already updated, so we don't need to do anything here.
      // This prevents the flicker.
    } catch (e) {
      // If there's an error, revert the change
      _userReactionsByEntity[entityId] = previousReaction;
      _optimisticallyRemoveReaction(entityId, userId, reactionType);
      if (previousReaction != null) {
        _optimisticallyUpdateReaction(entityId, previousReaction, userId);
      }
      notifyListeners();
    }
  }

  void _optimisticallyUpdateReaction(String entityId, String type, String userId) {
    final reactions = _reactionsByEntity[entityId];
    if (reactions == null) {
      _reactionsByEntity[entityId] = [];
    }

    // Remove previous reaction from user
    _optimisticallyRemoveReaction(entityId, userId, _userReactionsByEntity[entityId]);

    // Add new reaction
    var reactionData = _reactionsByEntity[entityId]!.firstWhere((r) => r.type == type, orElse: () {
      final newReaction = ReactionData(type: type, count: 0, users: []);
      _reactionsByEntity[entityId]!.add(newReaction);
      return newReaction;
    });

    if (!reactionData.users.any((u) => u.id == userId)) {
      reactionData.count++;
      reactionData.users.add(UserData(id: userId, name: 'You', profilePic: null));
    }
    _userReactionsByEntity[entityId] = type;
    notifyListeners();
  }

  void _optimisticallyRemoveReaction(String entityId, String userId, String? reactionType) {
    if (reactionType == null) return;
    final reactions = _reactionsByEntity[entityId];
    if (reactions == null) return;

    var reactionData = reactions.firstWhere((r) => r.type == reactionType, orElse: () => ReactionData(type: '', count: 0, users: []));

    if (reactionData.type.isNotEmpty) {
      final userIndex = reactionData.users.indexWhere((u) => u.id == userId);
      if (userIndex != -1) {
        reactionData.count--;
        reactionData.users.removeAt(userIndex);
      }
    }
  }

  Future<void> removeReaction(String entityId, String entityType, String userId, String token) async {
    final previousReaction = _userReactionsByEntity[entityId];
    if (previousReaction == null) return;

    // Optimistically update the UI
    _optimisticallyRemoveReaction(entityId, userId, previousReaction);
    _userReactionsByEntity[entityId] = null;
    notifyListeners();

    try {
      final response = await http.delete(
        Uri.parse('${BASE_URL}api/reaction'),
        headers: {
          'Content-Type': 'application/json',
          'userId': userId,
          'token': token,
        },
        body: jsonEncode({
          'entityId': entityId,
          'entityType': entityType,
        }),
      );

      if (response.statusCode != 200) {
        // Revert on failure
        _userReactionsByEntity[entityId] = previousReaction;
        _optimisticallyUpdateReaction(entityId, previousReaction, userId);
        notifyListeners();
      }
    } catch (e) {
      // Revert on error
      _userReactionsByEntity[entityId] = previousReaction;
      _optimisticallyUpdateReaction(entityId, previousReaction, userId);
      notifyListeners();
    }
  }
}

// 2. Revamp the ReactionButton widget to use the provider
class ReactionButton extends StatefulWidget {
  final String entityId;
  final String entityType;
  final String userId;
  final String token;

  const ReactionButton({
    Key? key,
    required this.entityId,
    required this.entityType,
    required this.userId,
    required this.token,
    String? communityId,
  }) : super(key: key);

  @override
  _ReactionButtonState createState() => _ReactionButtonState();
}

class _ReactionButtonState extends State<ReactionButton> {
  bool _initialLoadDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_initialLoadDone) {
        _initialLoadDone = true;
        _fetchReactions();
      }
    });
  }

  @override
  void didUpdateWidget(ReactionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the entity ID changes, fetch new reactions
    if (oldWidget.entityId != widget.entityId) {
      _fetchReactions();
    }
  }

  Future<void> _fetchReactions() async {
    final provider = Provider.of<ReactionsProvider>(context, listen: false);
    await provider.fetchReactions(widget.entityId, widget.entityType, widget.userId, widget.token);
  }

  void _handleTap() {
    final provider = Provider.of<ReactionsProvider>(context, listen: false);
    final currentReaction = provider.getUserReactionForEntity(widget.entityId);

    if (currentReaction != null) {
      provider.removeReaction(widget.entityId, widget.entityType, widget.userId, widget.token);
    } else {
      provider.addReaction(widget.entityId, widget.entityType, 'like', widget.userId, widget.token);
    }
  }

  void _showReactionPicker(BuildContext context) {
    // Get the position of the reaction button
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);

    // Calculate position for the floating menu (above the button)
    final double topPosition = position.dy - 60; // 60 pixels above the button
    final double leftPosition = position.dx - 50; // Center aligned with some offset

    final provider = Provider.of<ReactionsProvider>(context, listen: false);
    final currentReaction = provider.getUserReactionForEntity(widget.entityId);

    // Show the floating reaction picker
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: topPosition,
        left: leftPosition,
        child: Material(
          color: Colors.transparent,
          elevation: 0,
          child: Consumer<ReactionsProvider>(
            builder: (context, provider, _) {
              final currentReaction = provider.getUserReactionForEntity(widget.entityId);
              return FloatingReactionPicker(
                onReactionSelected: (type) {
                  if (currentReaction == type) {
                    provider.removeReaction(widget.entityId, widget.entityType, widget.userId, widget.token);
                  } else {
                    provider.addReaction(widget.entityId, widget.entityType, type, widget.userId, widget.token);
                  }
                  // Remove the overlay when a reaction is selected
                  overlayEntry.remove();
                },
                currentReaction: currentReaction,
                onDismiss: () {
                  overlayEntry.remove();
                },
              );
            },
          ),
        ),
      ),
    );

    // Add the overlay to the overlay state
    Overlay.of(context).insert(overlayEntry);

    // Auto dismiss after 3 seconds if no selection
    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReactionsProvider>(
      builder: (context, provider, _) {
        final isLoading = provider.isLoadingForEntity(widget.entityId);
        final currentReaction = provider.getUserReactionForEntity(widget.entityId);
        final totalCount = provider.getTotalReactionsCount(widget.entityId);

        return Row(
          children: [
            GestureDetector(
              onTap: _handleTap,
              onLongPress: () => _showReactionPicker(context),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: _getReactionIcon(currentReaction, isLoading),
              ),

              /* Icon(

                _getReactionIcon(currentReaction, isLoading),
                color: _getReactionColor(currentReaction, context),
                size: 30.sp,
              ),*/
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReactionsScreen(
                      feedId: widget.entityId,
                    ),
                  ),
                );
              },
              child: Container(
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Text(
                    '$totalCount',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Text _getReactionIcon(String? currentUserReaction, bool isLoading) {
    if (isLoading) {
      return Text('👍', key: const ValueKey('loading'), style: TextStyle(fontSize: 25));
    }

    switch (currentUserReaction) {
      case 'like':
        return Text(
          '👍',
          key: const ValueKey('like'),
          style: TextStyle(fontSize: 25),
        );
      case 'love':
        return Text('❤️', key: const ValueKey('love'), style: TextStyle(fontSize: 25));
      case 'haha':
        return Text('😂', key: const ValueKey('haha'), style: TextStyle(fontSize: 25));
      case 'dislike':
        return Text('👎', key: const ValueKey('dislike'), style: TextStyle(fontSize: 25));
      case 'wow':
        return Text('😲', key: const ValueKey('wow'), style: TextStyle(fontSize: 25));
      case 'sad':
        return Text('😢', key: const ValueKey('sad'), style: TextStyle(fontSize: 25));
      default:
        return Text('👍', key: const ValueKey('default'), style: TextStyle(fontSize: 25));
    }
  }

  Color _getReactionColor(String? currentUserReaction, BuildContext context) {
    if (currentUserReaction == null) {
      return Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : Colors.grey.shade600;
    }

    switch (currentUserReaction) {
      case 'like':
        return Colors.blue;
      case 'love':
        return Colors.red;
      case 'haha':
        return Color(0xFF7400A5);
      case 'dislike':
        return Colors.blue;
      case 'wow':
        return Color(0xFF7400A5);
      case 'sad':
        return Color(0xFF7400A5);
      default:
        return Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText;
    }
  }
}

// Keep the FloatingReactionPicker as before
class FloatingReactionPicker extends StatelessWidget {
  final Function(String) onReactionSelected;
  final String? currentReaction;
  final VoidCallback onDismiss;

  const FloatingReactionPicker({
    Key? key,
    required this.onReactionSelected,
    required this.onDismiss,
    this.currentReaction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss, // Dismiss when tapping outside the reactions
      child: Container(
        width: MediaQuery.of(context).size.width * 0.65,
        height: 50,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade900 : Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildReactionButton(
              context,
              'like',
              '👍',
              'Like',
            ),
            _buildReactionButton(
              context,
              'love',
              '❤️',
              'Love',
            ),
            _buildReactionButton(
              context,
              'haha',
              '😂',
              'Haha',
            ),
            _buildReactionButton(
              context,
              'dislike',
              '👎',
              'dislike',
            ),
            _buildReactionButton(
              context,
              'wow',
              '😲',
              'Wow',
            ),
            _buildReactionButton(
              context,
              'sad',
              '😢',
              'Sad',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionButton(
    BuildContext context,
    String type,
    String emoji,
    String label,
  ) {
    final isSelected = currentReaction == type;

    return GestureDetector(
      onTap: () => onReactionSelected(type),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: isSelected
            ? BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                shape: BoxShape.circle,
              )
            : null,
        child: Text(
          emoji,
          style: const TextStyle(
            fontSize: 24,
          ),
        ),
      ),
    );
  }
}

// Data models remain the same
class ReactionData {
  final String type;
  int count;
  final List<UserData> users;

  ReactionData({
    required this.type,
    required this.count,
    required this.users,
  });
}

class UserData {
  final String id;
  final String name;
  final String? profilePic;

  UserData({
    required this.id,
    required this.name,
    this.profilePic,
  });
}
