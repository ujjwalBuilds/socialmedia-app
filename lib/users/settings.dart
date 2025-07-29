import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/api_service/user_provider.dart';
import 'package:socialmedia/pages/onboarding_screens/privacyPolicyScreen.dart';
import 'package:socialmedia/pages/onboarding_screens/start_screen.dart';
import 'package:socialmedia/pages/onboarding_screens/termsAndConditionsScreen.dart';
import 'package:socialmedia/services/user_Service_provider.dart';
import 'package:socialmedia/users/blocker_users.dart';
import 'package:socialmedia/users/change_password.dart';
import 'package:socialmedia/users/deleteAccount.dart';
import 'package:socialmedia/users/edit_profile.dart';
import 'package:socialmedia/users/public_private_toggle.dart';
import 'package:socialmedia/users/referral_screen.dart';
import 'package:socialmedia/users/report_issue.dart';
import 'package:socialmedia/services/voice_settings.dart';
import 'package:socialmedia/users/reset_password.dart';
import 'package:socialmedia/utils/colors.dart';

class SettingsScreen extends StatefulWidget {
  bool privacyLev;
  final String? referralCode;
  final int? refferCount;

  SettingsScreen({
    super.key,
    required this.privacyLev,
    this.referralCode,
    this.refferCount,
  }); // Constructor

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late UserProviderall userProvider;
  String currentVoice = 'Bon'; // Default voice name

  @override
  void initState() {
    super.initState();
    userProvider = Provider.of<UserProviderall>(context, listen: false);
    userProvider.loadUserData().then((_) {
      setState(() {});
    });
    _loadVoicePreference();
  }

  Future<void> _loadVoicePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentVoice = prefs.getString('chat_voice') ?? 'Bon';
    });
  }

  Future<void> _saveVoicePreference(String voiceName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chat_voice', voiceName);
    await prefs.setString('chat_title', voiceName == 'Bon' ? 'BonChat' : 'Sora');
    setState(() {
      currentVoice = voiceName;
    });
  }

  void _showPrivacyToast() {
    String message = widget.privacyLev ? "Privacy level is ON" : "Privacy level is OFF";

    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black,
      textColor: Colors.white,
    );
  }

  void _logout(BuildContext context) async {
    // Show the alert dialog before logging out
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(color: Color(0xFF7400A5), width: 1.0),
          ),
          title: Column(
            children: [
              SvgPicture.asset(
                'assets/images/ancologog.svg', // Use the SVG file path
                width: 25.w, // Adjust size as needed
                height: 50.h,
              ),
              SizedBox(height: 12.h),
              Text(
                'Logout',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to logout?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
              fontSize: 14,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            SizedBox(
              width: 120,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  side: BorderSide(color: Colors.grey[300]!),
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(width: 16),
            SizedBox(
              width: 120,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop(); // Close the dialog

                  // Perform logout operations
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  final userProvider = Provider.of<UserProviderall>(context, listen: false);

                  // Call clearUserData function from UserProvider
                  userProvider.clearUserData();

                  prefs.setString('loginstatus', '2');
                  await prefs.remove('temp_userid');
                  await prefs.remove('temp_token');
                  await prefs.remove('socketTocken');
                  await prefs.remove('deviceId');

                  // Show logout toast
                  Fluttertoast.showToast(
                    msg: "Logged out successfully",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    backgroundColor: Colors.black,
                    textColor: Colors.white,
                  );

                  // Navigate to Login Screen and remove all previous routes
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => StartScreen()), // Replace with your LoginScreen widget
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Logout',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white, // Set background color to black
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text(
            'Settings',
            style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.w600, color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText),
          ),
          backgroundColor: Colors.black26, // Black app bar
          elevation: 0,
        ),
        body: ListView(
          children: [
            _buildSettingsItem(
              icon: Icons.person,
              title: 'Edit Profile',
              onTap: () {
                // Navigate to Edit Profile Screen
                Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfileScreen(avatar: '', selectedInterests: <String>[])));
              },
            ),
            _buildSettingsItem(
              icon: Icons.record_voice_over,
              title: 'Voice Settings',
              onTap: () {
                _showVoiceSettingsDialog(context);
              },
            ),
            _buildSettingsItem(
              icon: Icons.report_problem,
              title: 'Report an Issue',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ReportIssueScreen()));
              },
            ),
            _buildSettingsItem(
              icon: Icons.lock,
              title: 'Account Privacy Status',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => PrivacyToggleScreen()));
              },
            ),
            _buildSettingsItem(
              icon: Icons.block,
              title: 'Blocked Accounts',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => BlockedUsersScreen()));
              },
            ),
            _buildSettingsItem(
              icon: Icons.password_rounded,
              title: 'Change Password',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ChangePasswordScreen()));
              },
            ),
            _buildSettingsItem(
              icon: Icons.note_alt_rounded,
              title: 'Terms & Conditions',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => TermsAndConditionsScreen()));
              },
            ),
            _buildSettingsItem(
              icon: Icons.privacy_tip,
              title: 'Privacy Policy',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => PrivacyPolicyScreen()));
              },
            ),
            _buildSettingsItem(
              icon: Icons.delete,
              title: 'Delete Account',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => DeleteAccountScreen()));
              },
            ),
            if (widget.referralCode != null)
              _buildSettingsItem(
                icon: Icons.share,
                title: 'Referral Code',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReferralCodeScreen(
                        referralCode: widget.referralCode!,
                        refferCount: widget.refferCount!,
                      ),
                    ),
                  );
                },
              ),
            _buildSettingsItem(
              icon: Icons.logout,
              title: 'Logout',
              onTap: () {
                _logout(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText),
      title: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 16, color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText),
      ),
      onTap: onTap,
      trailing: Icon(Icons.arrow_forward_ios, color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText, size: 16),
    );
  }

  void _showVoiceSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Color(0xFF7400A5), width: 1.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/images/ancologog.svg',
                  width: 25.w,
                  height: 50.h,
                ),
                SizedBox(height: 12.h),
                Text(
                  'Voice Settings',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark ? Color(0xFF1E1E1E) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // Male Voices Section
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Icon(Icons.male, color: Colors.blue, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Male Voices',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ListTile(
                        leading: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.male, color: Colors.blue),
                        ),
                        title: Text(
                          'Michael',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          'Deep, confident voice',
                          style: GoogleFonts.poppins(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        trailing: currentVoice == 'Bon' ? Icon(Icons.check_circle, color: Color(0xFF7400A5)) : null,
                        onTap: () async {
                          await _saveVoicePreference('Bon');
                          await VoiceSettings.setSelectedVoice('male');
                          Navigator.pop(context);
                          Fluttertoast.showToast(
                            msg: "Michael voice selected",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            backgroundColor: Color(0xFF7400A5),
                            textColor: Colors.white,
                          );
                        },
                      ),
                      ListTile(
                        leading: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.male, color: Colors.blue),
                        ),
                        title: Row(
                          children: [
                            Text(
                              'Robert',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.lock, size: 16, color: Colors.grey),
                          ],
                        ),
                        subtitle: Text(
                          'Rich, authoritative voice',
                          style: GoogleFonts.poppins(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Icon(Icons.lock_outline, color: Colors.grey),
                        onTap: () {
                          Fluttertoast.showToast(
                            msg: "This voice is locked. Upgrade to unlock more voices.",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            backgroundColor: Color(0xFF7400A5),
                            textColor: Colors.white,
                          );
                        },
                      ),
                      ListTile(
                        leading: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.male, color: Colors.blue),
                        ),
                        title: Row(
                          children: [
                            Text(
                              'Lonnie',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.lock, size: 16, color: Colors.grey),
                          ],
                        ),
                        subtitle: Text(
                          'Smooth, engaging voice',
                          style: GoogleFonts.poppins(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Icon(Icons.lock_outline, color: Colors.grey),
                        onTap: () {
                          Fluttertoast.showToast(
                            msg: "This voice is locked. Upgrade to unlock more voices.",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            backgroundColor: Color(0xFF7400A5),
                            textColor: Colors.white,
                          );
                        },
                      ),
                      Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
                      // Female Voices Section
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Icon(Icons.female, color: Colors.pink, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Female Voices',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ListTile(
                        leading: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.pink.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.female, color: Colors.pink),
                        ),
                        title: Text(
                          'Vanessa',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          'Warm, friendly voice',
                          style: GoogleFonts.poppins(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        trailing: currentVoice == 'Sora' ? Icon(Icons.check_circle, color: Color(0xFF7400A5)) : null,
                        onTap: () async {
                          await _saveVoicePreference('Sora');
                          await VoiceSettings.setSelectedVoice('female');
                          Navigator.pop(context);
                          Fluttertoast.showToast(
                            msg: "Vanessa voice selected",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            backgroundColor: Color(0xFF7400A5),
                            textColor: Colors.white,
                          );
                        },
                      ),
                      ListTile(
                        leading: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.pink.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.female, color: Colors.pink),
                        ),
                        title: Row(
                          children: [
                            Text(
                              'Sonia',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.lock, size: 16, color: Colors.grey),
                          ],
                        ),
                        subtitle: Text(
                          'Elegant, sophisticated voice',
                          style: GoogleFonts.poppins(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Icon(Icons.lock_outline, color: Colors.grey),
                        onTap: () {
                          Fluttertoast.showToast(
                            msg: "This voice is locked. Upgrade to unlock more voices.",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            backgroundColor: Color(0xFF7400A5),
                            textColor: Colors.white,
                          );
                        },
                      ),
                      ListTile(
                        leading: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.pink.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.female, color: Colors.pink),
                        ),
                        title: Row(
                          children: [
                            Text(
                              'Mabel',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.lock, size: 16, color: Colors.grey),
                          ],
                        ),
                        subtitle: Text(
                          'Cheerful, energetic voice',
                          style: GoogleFonts.poppins(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Icon(Icons.lock_outline, color: Colors.grey),
                        onTap: () {
                          Fluttertoast.showToast(
                            msg: "This voice is locked. Upgrade to unlock more voices.",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            backgroundColor: Color(0xFF7400A5),
                            textColor: Colors.white,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF7400A5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Close',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
