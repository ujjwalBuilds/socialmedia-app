import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:socialmedia/utils/colors.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Terms & Conditions',
            style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Terms & Conditions',
                style: GoogleFonts.montserrat(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText),
              ),
              SizedBox(height: 16.h),
              RichText(
                textAlign: TextAlign.justify,
                text: TextSpan(
                  style: GoogleFonts.montserrat(
                    fontSize: 14.sp,
                    color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkText : AppColors.lightText,
                  ),
                  children: [
                    _buildHeading('Acceptance of Terms'),
                    const TextSpan(text: 'The services that ancoBridge provides to all users are subject to the following Terms of Use ("TOU"). ancoBridge reserves the right to update and modify the TOU at any time without notice. The most current version of the TOU can be reviewed by clicking on the "Terms of Use" hypertext link located at the bottom of our Web pages. When we make updates to the TOU, ancoBridge will update the date at the top of this page. By using the website after a new version of the TOU has been posted, you agree to the terms of such new version.\n\n'),
                    _buildHeading('Description of Services'),
                    const TextSpan(text: 'Through its network of Web properties, ancoBridge provides you with access to a variety of resources, including applications, download areas, communication forums and product information (collectively "Services"). The Services, including any updates, enhancements, new features, and/or the addition of any new Web properties, are subject to this TOU.\n\n'),
                    _buildHeading('Personal and Non-Commercial Use Limitation'),
                    const TextSpan(text: 'Unless otherwise specified, the Services are for your personal and non-commercial use. You may not modify, copy, distribute, transmit, display, perform, reproduce, publish, license, create derivative works from, transfer, or sell any information, software, products or services obtained from the Services.\n\n'),
                    _buildHeading('Privacy and Protection of Personal Information'),
                    const TextSpan(text: 'See the Privacy Statement disclosures relating to the collection and use of your personal data.\n\n'),
                    _buildHeading('Content'),
                    const TextSpan(text: 'All content included in or made available through the Services is the exclusive property of ancoBridge or its content suppliers and is protected by applicable intellectual property laws. All rights not expressly granted are reserved and retained by ancoBridge or its licensors.\n\n'),
                    _buildHeading('Software'),
                    const TextSpan(text: 'Any software available through the Services is copyrighted by ancoBridge and/or its suppliers. Use of the Software is governed by the end user license agreement. Unauthorized reproduction or redistribution is prohibited by law and may result in legal penalties.\n\n'),
                    _buildHeading('Restricted Rights Legend'),
                    const TextSpan(text: 'Software downloaded for or on behalf of the U.S. Government is provided with Restricted Rights as defined in applicable federal regulations. Manufacturer is ancoBridge Corporation, One ancoBridge Way, Redmond, WA 98052-6399.\n\n'),
                    _buildHeading('Documents'),
                    const TextSpan(text: 'Permission is granted to use Documents from the Services for non-commercial or personal use under specific conditions. Educational institutions may use them for classroom distribution. Any other use requires written permission.\n\nThese permissions do not include website design or layout elements, which may not be copied or imitated without express permission.\n\n'),
                    _buildHeading('Representations and Warranties'),
                    const TextSpan(text: 'Software and tools are provided "as is" without warranties except as specified in the license agreement. ancoBridge disclaims all other warranties including merchantability and fitness for a particular purpose.\n\n'),
                    _buildHeading('Limitation of Liability'),
                    const TextSpan(text: 'ancoBridge is not liable for any damages resulting from the use or inability to use the Services, including software, documents, or data.\n\n'),
                    _buildHeading('Member Account, Password, and Security'),
                    const TextSpan(text: 'You are responsible for maintaining the confidentiality of your account credentials and all activities that occur under your account. Unauthorized use must be reported immediately.\n\n'),
                    _buildHeading('No Unlawful or Prohibited Use'),
                    const TextSpan(text: 'You agree not to use the Services for unlawful purposes or in ways that impair, disable, or damage the Services or interfere with others\' use.\n\n'),
                    _buildHeading('Use of Services'),
                    const TextSpan(text: 'The Services may include communication tools. You agree to use them only to post and share appropriate, lawful content. Examples of prohibited actions include spamming, harassment, uploading viruses, and violating others\' rights.\n\n'),
                    _buildHeading('No spamming or chain messages'),
                    const TextSpan(text: 'No harassment or privacy violations\nNo posting inappropriate or unlawful content\nNo distribution of protected content without rights\nNo uploading of harmful software\nNo unauthorized advertising\nNo downloading of content that cannot be legally shared\nNo deletion of copyright or source information\nNo obstruction of others\' use of services\nNo identity falsification\nNo unlawful activity or violations of conduct codes\nancoBridge may remove content or suspend access at its discretion and is not responsible for content shared by users. Use caution when sharing personal information.\n\n'),
                    _buildHeading('AI Services'),
                    const TextSpan(text: 'AI Services may not be reverse engineered or used for scraping or training other AI systems. ancoBridge monitors inputs and outputs to prevent abuse. Users are responsible for legal compliance and third-party claims related to AI use.\n\n'),
                    _buildHeading('Materials Provided to ancoBridge'),
                    const TextSpan(text: 'By submitting content, you grant ancoBridge the rights to use it in connection with its Services. No compensation is provided. You must own or have permission to share submitted content, including images.\n\n'),
                    _buildHeading('Copyright Infringement'),
                    const TextSpan(text: 'To report copyright violations, follow the procedures under Title 17, U.S. Code, Section 512(c)(2). Non-relevant inquiries will not receive responses.\n\n'),
                    _buildHeading('Links to Third Party Sites'),
                    const TextSpan(text: 'Linked third-party websites are not under ancoBridge\'s control. ancoBridge is not responsible for their content or transmissions. Links are provided for convenience, not endorsement.\n\n'),
                    _buildHeading('Unsolicited Idea Submission Policy'),
                    const TextSpan(text: 'ancoBridge does not accept unsolicited ideas. If submitted, such materials are not treated as confidential or proprietary. This policy prevents disputes over similar ideas developed by ancoBridge.\n\n\n\n'),
                    _buildHeading('User Agreement'),
                    const TextSpan(text: 'Users must agree to the EULA, which strictly prohibits objectionable content or abuse. Admin reserves the right to remove such posts and flag or restrict offending users immediately.\n'),
                    const TextSpan(text: 'Age rating must reflect 17+')
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextSpan _buildHeading(String text) {
    return TextSpan(
      text: '$text\n',
      style: GoogleFonts.montserrat(
        fontSize: 16.sp,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
