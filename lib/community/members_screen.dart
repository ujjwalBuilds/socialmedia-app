import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// --- MODIFIED: The screen now takes a communityId to fetch its own data ---
class MembersScreen extends StatefulWidget {
  final String communityId;

  const MembersScreen({
    Key? key,
    required this.communityId,
  }) : super(key: key);

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // --- NEW: State variables for managing members list and pagination ---
  final List<dynamic> _allMembers = []; // Holds all fetched members
  late List<dynamic> _filteredMembers; // Used to display search results

  int _currentPage = 1;
  int _totalMembers = 0;
  bool _hasNextPage = true;
  bool _isLoadingMore = false;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _filteredMembers = _allMembers;

    _fetchInitialMembers();
    _scrollController.addListener(_onScroll);
    searchController.addListener(_filterMembers);
  }

  @override
  void dispose() {
    searchController.removeListener(_filterMembers);
    _scrollController.removeListener(_onScroll);
    searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- NEW: Scroll listener to trigger fetching the next page ---
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && _hasNextPage && !_isLoadingMore) {
      log("Fetching next page...");
      _fetchMembers(page: _currentPage + 1);
    }
  }

  // --- NEW: Initial data fetch ---
  Future<void> _fetchInitialMembers() async {
    setState(() {
      _isFirstLoad = true;
      _allMembers.clear();
      _currentPage = 1;
    });
    await _fetchMembers(page: 1);
  }

  // --- NEW: Core API fetching logic ---
  Future<void> _fetchMembers({required int page}) async {
    if (page > 1) {
      setState(() => _isLoadingMore = true);
    }

    // You can replace this with a constant from your project
    const String baseUrl = "https://admin.ancobridge.ai/api";
    final uri = Uri.parse('$baseUrl/communities/${widget.communityId}/membersOfCommunity?page=$page&limit=20');

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> newMembers = data['memberDetails'] ?? [];
        final pagination = data['pagination'] ?? {};

        setState(() {
          _allMembers.addAll(newMembers);
          _currentPage = pagination['currentPage'] ?? _currentPage;
          _hasNextPage = pagination['hasNextPage'] ?? false;
          _totalMembers = pagination['totalMembers'] ?? data['memberCount'] ?? 0;
        });
      } else {
        log('Failed to load members: ${response.statusCode}');
      }
    } catch (e) {
      log('An error occurred: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isFirstLoad = false;
          _isLoadingMore = false;
          _filterMembers(); // Apply search filter to the updated list
        });
      }
    }
  }

  // --- NEW: Client-side search filtering ---
  void _filterMembers() {
    final query = searchController.text.toLowerCase();
    setState(() {
      _filteredMembers = _allMembers.where((member) => (member['name'] ?? '').toString().toLowerCase().contains(query)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text(
            'Members ($_totalMembers)', // Use state variable for count
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    hintText: "Search Members",
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[900],
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.purple, width: 1),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // --- MODIFIED: Main content area now handles loading states ---
                Expanded(
                  child: _isFirstLoad
                      ? const Center(child: CircularProgressIndicator(color: Colors.purple))
                      : _filteredMembers.isEmpty
                          ? const Center(
                              child: Text(
                                "No members found",
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController, // Attach controller
                              itemCount: _filteredMembers.length + (_isLoadingMore ? 1 : 0), // Add space for loader
                              itemBuilder: (context, index) {
                                // Show loader at the bottom
                                if (index == _filteredMembers.length) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: CircularProgressIndicator(color: Colors.purple),
                                    ),
                                  );
                                }

                                final member = _filteredMembers[index];
                                final name = member['name']?.toString().isNotEmpty == true ? member['name'] : 'User'; // Fallback name
                                final profilePic = member['profilePic'];
                                final avatar = member['avatar'];
                                final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.purple.withOpacity(0.7),
                                    backgroundImage: (profilePic != null && profilePic.isNotEmpty)
                                        ? NetworkImage(profilePic)
                                        : (avatar != null && avatar.isNotEmpty)
                                            ? NetworkImage(avatar)
                                            : null,
                                    child: (profilePic == null || profilePic.isEmpty) && (avatar == null || avatar.isEmpty) ? Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)) : null,
                                  ),
                                  title: Text(name, style: const TextStyle(color: Colors.white)),
                                  subtitle: const Text('member', style: TextStyle(color: Colors.grey)),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
