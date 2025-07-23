import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:http/http.dart' as http;
import 'package:socialmedia/utils/constants.dart';

class PrivacyToggleScreen extends StatefulWidget {
  const PrivacyToggleScreen({super.key});

  @override
  State<PrivacyToggleScreen> createState() => _PrivacyToggleScreenState();
}

class _PrivacyToggleScreenState extends State<PrivacyToggleScreen> {
  late bool isPrivate;

  Future<void> updatePrivacyStatus(bool isPrivate) async {
    final userProvider = Provider.of<UserProviderall>(context, listen: false);
    final uri = Uri.parse("${BASE_URL}api/edit-profile");

    try {
      final request = http.MultipartRequest("PUT", uri);

      // Headers
      request.headers.addAll({
        "userid": userProvider.userId ?? "",
        "token": userProvider.userToken ?? "",
      });

      // Form Data
      request.fields["public"] = isPrivate ? "0" : "1";

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Update provider value after successful API call
        userProvider.setPublicStatus(isPrivate ? 0 : 1);

        print("Privacy status updated successfully.");
      } else {
        debugPrint("Failed to update status: ${response.body}");
        // Optionally show error to user
      }
    } catch (e) {
      debugPrint("Error updating privacy status: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    final public =
        Provider.of<UserProviderall>(context, listen: false).publicStatus ?? 1;
    isPrivate = public == 0;
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.poppins(
      fontSize: 16,
      color: Colors.white,
    );

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(
            "Privacy Settings",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.black,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Private Account", style: textStyle),
                Switch(
                  value: isPrivate,
                  activeColor: Color(0xFF7400A5),
                  activeTrackColor: Colors.grey.shade700,
                  inactiveThumbColor: Colors.grey.shade400,
                  inactiveTrackColor: Colors.grey.shade800,
                  onChanged: (val) async {
                    setState(() => isPrivate = val);
                    await updatePrivacyStatus(val);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
