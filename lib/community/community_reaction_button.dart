import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:socialmedia/utils/colors.dart';
import 'community_reactions_provider.dart';

class CommunityReactionButton extends StatefulWidget {
  final String postId;
  final String communityId;
  final String userId;
  final String token;
  final int initialReactionCount;
  final bool initialHasReacted;
  final Function(bool, int)? onReactionChanged;

  const CommunityReactionButton({
    Key? key,
    required this.postId,
    required this.communityId,
    required this.userId,
    required this.token,
    this.initialReactionCount = 0,
    this.initialHasReacted = false,
    this.onReactionChanged,
  }) : super(key: key);

  @override
  _CommunityReactionButtonState createState() => _CommunityReactionButtonState();
}

class _CommunityReactionButtonState extends State<CommunityReactionButton> {
  bool _initialLoadDone = false;
  late CommunityReactionsProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = CommunityReactionsProvider();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_initialLoadDone) {
        _initialLoadDone = true;
        _fetchReactions();
      }
    });
  }

  @override
  void didUpdateWidget(CommunityReactionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.postId != widget.postId) {
      _fetchReactions();
    }
  }

  Future<void> _fetchReactions() async {
    await _provider.fetchReactions(
      widget.postId, 
      widget.communityId, 
      widget.userId, 
      widget.token
    );
  }

  void _handleTap() {
    final currentReaction = _provider.getUserReactionForEntity(widget.postId);

    if (currentReaction != null) {
      _provider.removeReaction(widget.postId, widget.communityId, widget.userId, widget.token);
      if (widget.onReactionChanged != null) {
        widget.onReactionChanged!(false, _provider.getTotalReactionsCount(widget.postId));
      }
    } else {
      _provider.addReaction(widget.postId, widget.communityId, 'love', widget.userId, widget.token);
      if (widget.onReactionChanged != null) {
        widget.onReactionChanged!(true, _provider.getTotalReactionsCount(widget.postId));
      }
    }
  }

  void _showReactionPicker(BuildContext context) {
    // Get the position of the reaction button
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);

    // Calculate position for the floating menu (above the button)
    final double topPosition = position.dy - 60; // 60 pixels above the button
    final double leftPosition = position.dx - 50; // Center aligned with some offset

    final currentReaction = _provider.getUserReactionForEntity(widget.postId);

    // Show the floating reaction picker
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: topPosition,
        left: leftPosition,
        child: Material(
          color: Colors.transparent,
          elevation: 0,
          child: FloatingReactionPicker(
            onReactionSelected: (type) {
              if (currentReaction == type) {
                _provider.removeReaction(widget.postId, widget.communityId, widget.userId, widget.token);
                if (widget.onReactionChanged != null) {
                  widget.onReactionChanged!(false, _provider.getTotalReactionsCount(widget.postId));
                }
              } else {
                log('Adding reaction: $type');
                log('CID: ${widget.communityId}');
                
                _provider.addReaction(widget.postId, widget.communityId, type, widget.userId, widget.token);
                if (widget.onReactionChanged != null) {
                  widget.onReactionChanged!(true, _provider.getTotalReactionsCount(widget.postId));
                }
              }
              // Remove the overlay when a reaction is selected
              overlayEntry.remove();
            },
            currentReaction: currentReaction,
            onDismiss: () {
              overlayEntry.remove();
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
    final isLoading = _provider.isLoadingForEntity(widget.postId);
    final currentReaction = _provider.getUserReactionForEntity(widget.postId);
    final totalCount = _provider.getTotalReactionsCount(widget.postId);

    return ListenableBuilder(
      listenable: _provider,
      builder: (context, _) {
        return Row(
          children: [
            GestureDetector(
              onTap: _handleTap, 
              onLongPress: () => _showReactionPicker(context), 
              child: _getReactionIcon(currentReaction, isLoading)
            ),
            const SizedBox(width: 4),
            Text(
              '${totalCount > 0 ? totalCount : widget.initialReactionCount}',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? 
                  AppColors.darkText : AppColors.lightText,
                fontSize: 13,
              ),
            ),
          ],
        );
      }
    );
  }

  Text _getReactionIcon(String? currentUserReaction, bool isLoading) {
    if (isLoading) {
      return Text('👍', style: TextStyle(fontSize: 25));
    }

    switch (currentUserReaction) {
      case 'like':
        return Text('👍', style: TextStyle(fontSize: 25));
      case 'love':
        return Text('❤️', style: TextStyle(fontSize: 25));
      case 'haha':
        return Text('😂', style: TextStyle(fontSize: 25));
      case 'dislike':
        return Text('👎', style: TextStyle(fontSize: 25));
      case 'wow':
        return Text('😲', style: TextStyle(fontSize: 25));
      case 'sad':
        return Text('😢', style: TextStyle(fontSize: 25));
      default:
        return Text('👍', style: TextStyle(fontSize: 25));
    }
  }
}

// Floating Reaction Picker
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
            _buildReactionButton(context, 'like', '👍', 'Like'),
            _buildReactionButton(context, 'love', '❤️', 'Love'),
            _buildReactionButton(context, 'haha', '😂', 'Haha'),
            _buildReactionButton(context, 'dislike', '👎', 'dislike'),
            _buildReactionButton(context, 'wow', '😲', 'Wow'),
            _buildReactionButton(context, 'sad', '😢', 'Sad'),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionButton(BuildContext context, String type, String emoji, String label) {
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

// Data models
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