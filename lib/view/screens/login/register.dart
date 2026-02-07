// import 'dart:io';

// import 'package:country_picker/country_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
// import 'package:shaheen_star_app/controller/provider/profile_update_provider.dart';
// import 'package:shaheen_star_app/utils/colors.dart';

// ImageProvider _getImageProvider(String? imagePath) {
//   if (imagePath == null ||
//       imagePath.isEmpty ||
//       imagePath == 'yyyy' ||
//       imagePath == 'Profile Url') {
//     return const AssetImage('assets/images/person.png');
//   }

//   if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
//     return NetworkImage(imagePath);
//   }

//   if (imagePath.startsWith('/data/') ||
//       imagePath.startsWith('/storage/') ||
//       imagePath.contains('cache')) {
//     try {
//       File file = File(imagePath);
//       if (file.existsSync()) {
//         return FileImage(file);
//       } else {
//         return const AssetImage('assets/images/person.png');
//       }
//     } catch (e) {
//       return const AssetImage('assets/images/person.png');
//     }
//   }

//   return const AssetImage('assets/images/person.png');
// }

// class ProfileSetupScreen extends StatefulWidget {
//   const ProfileSetupScreen({super.key});

//   @override
//   State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
// }

// class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
//   final ImagePicker _picker = ImagePicker();
//   File? _image;
//   String selectedGender = 'Boy';
//   File? _selectedImage;

//   String gender = 'boy';
//   DateTime? birthday;
//   Country? selectedCountry;

//   final nameController = TextEditingController();
//   final inviteController = TextEditingController(text: 'jvc2d54');

//   // Future<void> pickImage(ImageSource source) async {
//   //   final XFile? picked = await _picker.pickImage(source: source);
//   //   if (picked != null) {
//   //     setState(() => _image = File(picked.path));
//   //   }
//   // }

//   Future<void> _pickImage() async {
//     final picker = ImagePicker();
//     final picked = await picker.pickImage(source: ImageSource.gallery);

//     if (picked != null) {
//       setState(() {
//         _selectedImage = File(picked.path);
//       });
//       debugPrint("✅ Image selected: ${picked.path}");
//     }
//   }

//   Future<void> pickDate() async {
//     final DateTime? date = await showDatePicker(
//       context: context,
//       firstDate: DateTime(1950),
//       lastDate: DateTime.now(),
//       initialDate: birthday ?? DateTime(2000, 1, 1),
//     );
//     if (date != null) setState(() => birthday = date);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final provider = Provider.of<ProfileUpdateProvider>(context);
//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Color(0xff0F4C81), Color(0xff6EC6FF)],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         // decoration: const BoxDecoration(
//         //   image: DecorationImage(
//         //     image: AssetImage("assets/images/login_bg_pic.jpeg"),
//         //     fit: BoxFit.cover,
//         //   ),
//         // ),
//         child: SafeArea(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               children: [
//                 /// PROFILE IMAGE
//                 // Stack(
//                 //   alignment: Alignment.bottomRight,
//                 //   children: [
//                 //     CircleAvatar(
//                 //       radius: 55,
//                 //       backgroundColor: Colors.white,
//                 //       backgroundImage: _image != null
//                 //           ? FileImage(_image!)
//                 //           : null,
//                 //       child: _image == null
//                 //           ? Image.asset(
//                 //               gender == 'boy'
//                 //                   ? 'assets/images/boy.PNG'
//                 //                   : 'assets/images/girl.PNG',
//                 //               width: 70,
//                 //             )
//                 //           : null,
//                 //     ),
//                 //     IconButton(
//                 //       icon: const Icon(Icons.camera_alt, color: Colors.orange),
//                 //       onPressed: () => showModalBottomSheet(
//                 //         context: context,
//                 //         builder: (_) => Column(
//                 //           mainAxisSize: MainAxisSize.min,
//                 //           children: [
//                 //             ListTile(
//                 //               leading: const Icon(Icons.camera_alt),
//                 //               title: const Text('Camera'),
//                 //               onTap: () {
//                 //                 Navigator.pop(context);
//                 //                 pickImage(ImageSource.camera);
//                 //               },
//                 //             ),
//                 //             ListTile(
//                 //               leading: const Icon(Icons.photo),
//                 //               title: const Text('Gallery'),
//                 //               onTap: () {
//                 //                 Navigator.pop(context);
//                 //                 pickImage(ImageSource.gallery);
//                 //               },
//                 //             ),
//                 //           ],
//                 //         ),
//                 //       ),
//                 //     ),
//                 //   ],
//                 // ),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Stack(
//                       clipBehavior: Clip.none,
//                       children: [
//                         CircleAvatar(
//                           radius: 45,
//                           backgroundColor: AppColors.grey2,
//                           backgroundImage: _selectedImage != null
//                               ? FileImage(_selectedImage!)
//                               : (provider.profile_url != null &&
//                                     provider.profile_url!.isNotEmpty)
//                               ? _getImageProvider(provider.profile_url)
//                               : null,
//                           child:
//                               (_selectedImage == null &&
//                                   (provider.profile_url == null ||
//                                       provider.profile_url!.isEmpty))
//                               ? const Icon(
//                                   Icons.person,
//                                   size: 50,
//                                   color: AppColors.grey,
//                                 )
//                               : null,
//                         ),

//                         // Camera icon
//                         Positioned(
//                           bottom: 0,
//                           right: 0,
//                           child: GestureDetector(
//                             onTap: _pickImage,
//                             child: Container(
//                               width: 28,
//                               height: 28,
//                               decoration: BoxDecoration(
//                                 color: Colors.white,
//                                 shape: BoxShape.circle,
//                                 border: Border.all(
//                                   color: Colors.grey.shade300,
//                                   width: 1,
//                                 ),
//                                 boxShadow: const [
//                                   BoxShadow(
//                                     color: Colors.black12,
//                                     blurRadius: 2,
//                                     offset: Offset(0, 1),
//                                   ),
//                                 ],
//                               ),
//                               child: const Icon(
//                                 Icons.camera_alt,
//                                 color: AppColors.primaryColor,
//                                 size: 16,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),

//                 const SizedBox(height: 20),

//                 /// GENDER
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     genderButton('boy', 'assets/images/boy.PNG'),
//                     const SizedBox(width: 20),
//                     genderButton('girl', 'assets/images/girl.PNG'),
//                   ],
//                 ),

//                 const SizedBox(height: 25),

//                 /// BIRTHDAY
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 15),
//                   child: Column(
//                     children: [
//                       buildField('Name', nameController),

//                       const SizedBox(height: 15),
//                       GestureDetector(
//                         onTap: pickDate,
//                         child: buildReadOnlyField(
//                           'Birthday',
//                           birthday == null
//                               ? '2000-01-01'
//                               : DateFormat('yyyy-MM-dd').format(birthday!),
//                         ),
//                       ),

//                       const SizedBox(height: 15),

//                       /// COUNTRY PICKER WITH FLAGS
//                       GestureDetector(
//                         onTap: () {
//                           showCountryPicker(
//                             context: context,
//                             showPhoneCode: false,
//                             onSelect: (Country country) {
//                               setState(() => selectedCountry = country);
//                             },
//                           );
//                         },
//                         child: buildReadOnlyField(
//                           'Country / Region',
//                           selectedCountry == null
//                               ? 'Choose Country / Region'
//                               : '${selectedCountry!.flagEmoji}  ${selectedCountry!.name}',
//                         ),
//                       ),

//                       const SizedBox(height: 15),
//                       buildField('Invite Code', inviteController),

//                       const SizedBox(height: 30),
//                       Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 20.0),
//                         child: SizedBox(
//                           width: double.infinity,
//                           height: 45,
//                           child: ElevatedButton(
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.black,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(30),
//                               ),
//                             ),
//                             onPressed: () {},
//                             child: const Text(
//                               'Submit',
//                               style: TextStyle(
//                                 fontSize: 18,
//                                 color: Colors.white,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget genderButton(String value, String asset) {
//     final bool selected = gender == value;
//     return GestureDetector(
//       onTap: () => setState(() => gender = value),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(
//             color: selected ? Colors.orange : Colors.transparent,
//           ),
//         ),
//         child: Row(
//           children: [
//             Image.asset(asset, width: 22),
//             const SizedBox(width: 6),
//             Text(value.toUpperCase()),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget buildField(String label, TextEditingController controller) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 20.0),
//             child: Text(label),
//           ),
//           const SizedBox(height: 6),
//           TextField(
//             controller: controller,

//             decoration: InputDecoration(
//               isDense: true, // ⭐ height kam karta hai
//               contentPadding: const EdgeInsets.symmetric(
//                 horizontal: 20,
//                 vertical: 11, // 👈 is value se height control hoti hai
//               ),
//               filled: true,
//               fillColor: Colors.white,
//               hint: Text('XXXXXXX'),
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(30),
//                 borderSide: BorderSide.none,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget buildReadOnlyField(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 20.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 20.0),
//             child: Text(label),
//           ),
//           const SizedBox(height: 6),
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(30),
//             ),
//             child: Text(value),
//           ),
//         ],
//       ),
//     );
//   }
// }
