import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';


class PrivacyPolicyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Privacy Policy'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Privacy Policy',
                style: GoogleFonts.montserrat(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'The Officers of BondBridge LLC are firmly committed to guarding the confidence you have placed in our company and to use, responsibly and professionally, any information you volunteer. We strive to collect only that information that we think is necessary for our legitimate business interests, such as to better understand you (our customer), to provide better service, to improve the marketing our products, to educate customers and to ensure that our proprietary information is protected. We are committed to using the information collected only for these purposes. The protection of privacy and personal data is a priority.\n\nBondBridge LLC does not rent, sell or lease User Information we have collected through our Website. However, we may share User Information, collected through our Website, with other BondBridge LLC entities or with our direct business partners for research purposes and to provide you with updated information that we feel would be of benefit to you. Our policy is to give our Users the opportunity to opt out of receiving any direct research or marketing contact. We have designed this website, our webapplications and mobile applications with the same rules and politicies in place for a secure User experience.\n\nLocal country laws are applied where they differ from this policy. Links to third party websites, from this website, are provided solely as convenience for the end user. If these links are Used, the User will leave our Website. We have not reviewed, nor do we monitor these third party sites and we do not control, nor are we responsible for, any of these websites, their content or their private policies (if any). This policy discloses our information gathering and usage practices for BondBridge\'s online services.\n\nIn order to improve our problem resolution process through better product and case tracking, BondBridge\'s tech support department has implemented online registration and technical support services. We require contact information to identify you and to direct you to the proper service. This information is also used to manage your case, notify you when necessary of issues related to your transaction. Occasionally, we may send e-mails to give customers information we think you will find useful, such as information about new features, products or promotions.\n\nWhen we contact or e-mail you, we will always provide instructions explaining how to unsubscribe so you will not receive and contact or any e-mails in the future. You may also opt-out of receiving future BondBridge and/or partner communications by submitting your request through our online feedback form. We strive to make the BondBridge User experience and safe, secure, fulfilling and pleasant one. We welcome any and all feedback in regard to how to make our product, safer, more secure, more fulfilling and easier to utilize.\n\nContact Us: If there are any questions or issues regarding this website, our practices, or any of our policies, please contact us via e-mail at: info@bondbridge.com',
                style: GoogleFonts.montserrat(
                  fontSize: 14.sp,
                ),
                textAlign: TextAlign.justify,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
