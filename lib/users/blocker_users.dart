import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:socialmedia/utils/constants.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  List<dynamic> blockedUsers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchBlockedUsers();
  }

  Future<void> unblockUser(String blockedUserId) async {
    // Instantly remove from list
    setState(() {
      blockedUsers.removeWhere((user) => user['userId'] == blockedUserId);
    });

    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    final url = Uri.parse('${BASE_URL}api/unblock-user');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'userid': userProvider.userId ?? '',
          'token': userProvider.userToken ?? '',
        },
        body: jsonEncode({'blocked': blockedUserId}),
      );

      if (response.statusCode == 200) {
        debugPrint('Unblocked successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('User unblocked', style: GoogleFonts.poppins())),
        );
      } else {
        debugPrint('Unblock failed: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Unblock failed', style: GoogleFonts.poppins())),
        );
      }
    } catch (e) {
      debugPrint('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error', style: GoogleFonts.poppins())),
      );
    }
  }

  Future<void> fetchBlockedUsers() async {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);

    final url = Uri.parse('${BASE_URL}api/get-blocked-users');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'userid': userProvider.userId ?? '',
          'token': userProvider.userToken ?? '',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          blockedUsers = data['blockedUsers'] ?? [];
          isLoading = false;
        });
      } else {
        debugPrint('Error: ${response.body}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('Exception: $e');
      setState(() => isLoading = false);
    }
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Blocked Users', style: GoogleFonts.poppins()),
        backgroundColor: Colors.black,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : blockedUsers.isEmpty
              ? Center(
                  child: Text('No blocked users',
                      style: GoogleFonts.poppins(color: Colors.white)))
              : ListView.builder(
                  itemCount: blockedUsers.length,
                  itemBuilder: (context, index) {
                    final user = blockedUsers[index];
                    return Card(
                      color: Colors.grey[900],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              NetworkImage(user['profilePic'] ?? ''),
                        ),
                        title: Text(user['name'] ?? '',
                            style: GoogleFonts.poppins(color: Colors.white)),
                        trailing: TextButton(
                          onPressed: () => unblockUser(user['userId']),
                          child: Text('Unblock',
                              style:
                                  GoogleFonts.poppins(color: Colors.redAccent)),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
