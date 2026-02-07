// // ignore_for_file: depend_on_referenced_packages

// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:provider/provider.dart';
// import 'package:shaheen_star_app/controller/provider/sign_up_provider.dart';
// import 'package:shaheen_star_app/utils/colors.dart';

// class LoginWithPasswordScreen extends StatelessWidget {

//   const LoginWithPasswordScreen({super.key});

//   @override
  
//   Widget build(BuildContext context) {
//       final googleProvider = Provider.of<SignUpProvider>(context);
//     return ScreenUtilInit(
//       designSize: const Size(390, 844),
//       minTextAdapt: true,
//       builder: (_, __) {
//         return Scaffold(
//           body: Container(
//             width: double.infinity,
//             height: double.infinity,
//             decoration: const BoxDecoration(
//               image: DecorationImage(
//                 image: AssetImage('assets/images/login_bg_pic.jpg'),
//                 fit: BoxFit.cover,
//               ),
//             ),
//             child: SafeArea(
//               child: SingleChildScrollView(
//                 padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 50.h),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Logo text
//                     Center(
//                       child: Text(
//                         "Logo",
//                         style: TextStyle(
//                           color: AppColors.logoColor,
//                           fontSize: 28.sp,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                     SizedBox(height: 80.h),

//                     // Email label
//                     Text(
//                       "E-mail",
//                       style: TextStyle(
//                         color: AppColors.textColor,
//                         fontSize: 14.sp,
//                         fontWeight: FontWeight.w400,
//                       ),
//                     ),
//                     SizedBox(height: 8.h),

//                     // Email field
//                     TextField(
//                       style: TextStyle(fontSize: 14.sp, color: Colors.black),
//                       decoration: InputDecoration(
//                         filled: true,
//                         fillColor: AppColors.bgColor,
//                         hintText: "Enter your email",
//                         hintStyle: TextStyle(
//                           color: Colors.grey,
//                           fontSize: 14.sp,
//                         ),
//                         contentPadding: EdgeInsets.symmetric(
//                           vertical: 14.h,
//                           horizontal: 16.w,
//                         ),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12.r),
//                           borderSide: BorderSide.none,
//                         ),
//                       ),
//                     ),
//                     SizedBox(height: 20.h),

//                     // Password label
//                     Text(
//                       "Password",
//                       style: TextStyle(
//                         color: AppColors.textColor,
//                         fontSize: 14.sp,
//                         fontWeight: FontWeight.w400,
//                       ),
//                     ),
//                     SizedBox(height: 8.h),

//                     // Password field
//                     TextField(
//                       obscureText: true,
//                       style: TextStyle(fontSize: 14.sp, color: Colors.black),
//                       decoration: InputDecoration(
//                         filled: true,
//                         fillColor: Colors.white,
//                         hintText: "Enter your password",
//                         hintStyle: TextStyle(
//                           color: Colors.grey,
//                           fontSize: 14.sp,
//                         ),
//                         contentPadding: EdgeInsets.symmetric(
//                           vertical: 14.h,
//                           horizontal: 14.w,
//                         ),
//                         suffixIcon: Icon(
//                           Icons.visibility_off_outlined,
//                           color: Colors.grey,
//                           size: 20.sp,
//                         ),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12.r),
//                           borderSide: BorderSide.none,
//                         ),
//                       ),
//                     ),

//                     SizedBox(height: 8.h),

//                     // Forgot password
//                     Align(
//                       alignment: Alignment.centerRight,
//                       child: TextButton(
//                         onPressed: () {},
//                         style: TextButton.styleFrom(
//                           padding: EdgeInsets.zero,
//                           minimumSize: Size.zero,
//                           tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                         ),
//                         child: Text(
//                           "Forgot Password?",
//                           style: TextStyle(
//                             color: AppColors.buttonColor,
//                             fontSize: 14.sp,
//                             decoration: TextDecoration.underline,
//                             decorationColor: AppColors.buttonColor,
//                           ),
//                         ),
//                       ),
//                     ),
//                     SizedBox(height: 25.h),

//                     // Login button
//                     SizedBox(
//                       width: double.infinity,
//                       height: 44.h,
//                       child: ElevatedButton(
//                         onPressed: () {},
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: AppColors.primaryColor,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(25.r),
//                           ),
//                         ),
//                         child: Text(
//                           "Login",
//                           style: TextStyle(
//                             fontSize: 14.sp,
//                             color:AppColors.bgColor,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                     ),
//                     SizedBox(height: 20.h),

//                     // Divider text
//                     Center(
//                       child: Text(
//                         "or login with",
//                         style: TextStyle(
//                           color: AppColors.bgColor,
//                           fontSize: 14.sp,
//                         ),
//                       ),
//                     ),
//                     SizedBox(height: 20.h),

                   
//                    SizedBox(
//                         width: double.infinity,
//                         height: 50.h,
//                         child: ElevatedButton.icon(
//                           onPressed: googleProvider.isLoading
//                               ? null
//                               : () => googleProvider.handleGoogleAuth(context),
//                           icon: googleProvider.isLoading
//                               ? SizedBox(
//                                   height: 24.h,
//                                   width: 24.w,
//                                   child: const CircularProgressIndicator(
//                                     strokeWidth: 2,
//                                     color: Colors.black,
//                                   ),
//                                 )
//                               : SvgPicture.asset(
//                                   'assets/svg/google_icon.svg',
//                                   height: 24.h,
//                                   width: 24.w,
//                                 ),
//                           label: Text(
//                             googleProvider.isLoading
//                                 ? "Please wait..."
//                                 : " SignUp with Google",
//                             style: TextStyle(
//                               color: Colors.black,
//                               fontSize: 16.sp,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.white,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(25.r),
//                             ),
//                             elevation: 2,
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
