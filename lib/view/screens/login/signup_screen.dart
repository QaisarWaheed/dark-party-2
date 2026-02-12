import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/controller/provider/sign_up_provider.dart';

import 'package:shaheen_star_app/components/app_image.dart';
import 'package:shaheen_star_app/view/screens/login/register_profile.dart';

import '../../widgets/loading_icon_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  int _tapCount = 0;
  bool _showReviewerLogin = false;

  void _handleHiddenTap() {
    setState(() {
      _tapCount++;
      if (_tapCount >= 5) {
        _showReviewerLogin = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final googleProvider = Provider.of<SignUpProvider>(context);

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (_, __) {
        return Scaffold(
          body: Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(color: Colors.white),
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    children: [
                      // Top small label (right aligned)
                      Align(
                        alignment: Alignment.topRight,
                        child: GestureDetector(
                          onTap: _handleHiddenTap,
                          child: Padding(
                            padding: EdgeInsets.only(
                              top: 8.h,
                              right: 4.w,
                              bottom: 8.h,
                            ),
                            child: Text(
                              'Network Diagnostics',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),

                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Logo
                            Container(
                              width: 120.w,
                              height: 120.w,
                              decoration: BoxDecoration(shape: BoxShape.circle),
                              child: ClipOval(
                                child: AppImage.asset(
                                  'assets/images/app_logo.jpeg',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey.shade200,
                                      child: Icon(
                                        Icons.image_not_supported,
                                        size: 40.sp,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: 24.h),

                            // Headline text (two lines)
                            Text(
                              'Be yourself,',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              'you have the brilliance of a protagonist',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.black54,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Buttons area
                      Column(
                        children: [
                          LoadingIconButton(
                            backgroundColor: Colors.white,
                            isLoading: false,
                            onPressed: () =>
                                googleProvider.googleSignup(context),
                            label: 'Google',
                            iconPath: 'assets/images/Logo-google-icon-PNG.png',
                            textColor: Colors.black87,
                            height: 56,
                            borderRadius: 40,
                            fontSize: 16,
                            iconSize: 28,
                          ),
                          SizedBox(height: 16.h),
                          SizedBox(
                            width: double.infinity,
                            height: 56.h,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ProfileSetupScreen(),
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(40.r),
                                  side: BorderSide(color: Colors.grey.shade200),
                                ),
                                elevation: 2,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Left icon (same position as Google icon)
                                  SizedBox(
                                    height: 28.h,
                                    width: 28.w,
                                    child: Icon(
                                      Icons.phone_outlined,
                                      color: Colors.black,
                                      size: 22.sp,
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  // Centered label
                                  Expanded(
                                    child: Center(
                                      child: Text(
                                        'Phone',
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Keep spacing to balance icon on left (same as Google button)
                                  SizedBox(width: 28.w + 12.w),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 12.h),

                          // Register link
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProfileSetupScreen(),
                              ),
                            ),
                            child: Text(
                              'Register New Account',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13.sp,
                              ),
                            ),
                          ),

                          // ✅ Reviewer Login (Hidden by default, tap Network Diagnostics 5 times to reveal)
                          if (_showReviewerLogin)
                            TextButton(
                              onPressed: () =>
                                  googleProvider.reviewerLogin(context),
                              child: Text(
                                'Reviewer Login',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12.sp,
                                ),
                              ),
                            ),

                          SizedBox(height: 8.h),

                          // Footer small privacy text
                          Padding(
                            padding: EdgeInsets.only(bottom: 6.h),
                            child: Text(
                              'By signing up, you agree to our Teams of Service & Privacy Policy',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 11.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
