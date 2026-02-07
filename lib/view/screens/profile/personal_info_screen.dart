

import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/controller/provider/profile_update_provider.dart';
import 'package:shaheen_star_app/controller/provider/sign_up_provider.dart';
import 'package:shaheen_star_app/routes/app_routes.dart';
// removed unused country picker/utils imports (not used in new UI)

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  File? _pickedImage;

  final _nameController = TextEditingController();
  final _countryController = TextEditingController();
  final _dobController = TextEditingController();
  String? _gender;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ProfileUpdateProvider>(context, listen: false);
    provider.fetchUserData().then((_) {
      print('📱 Loaded Data in PersonalInfoScreen:');
      print('   - Username: ${provider.username}');
      print('   - Country: ${provider.country}');
      print('   - Gender: ${provider.gender}');
      print('   - DOB: ${provider.dob}');
      print('   - Image: ${provider.profile_url}');

      _nameController.text = provider.username ?? '';
      _countryController.text = provider.country ?? '';
      _dobController.text = provider.dob ?? '';
      _gender =
          provider.gender?.isNotEmpty == true
              ? provider.gender![0].toUpperCase() +
                  provider.gender!.substring(1).toLowerCase()
              : 'Male';
      setState(() {});
    });
  }

  Future<void> _pickImage() async {
    print("📸 ========== IMAGE PICKER STARTED ==========");
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile != null) {
        print("✅ Image selected from gallery");
        print("   - Original path: ${pickedFile.path}");
        print("   - Name: ${pickedFile.name}");
        print("   - Size: ${await File(pickedFile.path).length()} bytes");

        final imageFile = File(pickedFile.path);
        final fileExists = await imageFile.exists();
        print("   - File exists: $fileExists");

        if (fileExists) {
          final fileSize = await imageFile.length();
          print("   - File size: ${fileSize / 1024} KB");

          setState(() {
            _pickedImage = imageFile;
          });

          print("✅ Image file set in state: ${_pickedImage?.path}");
          print("   - State file exists: ${await _pickedImage!.exists()}");
        } else {
          print("❌ ERROR: Selected file does not exist!");
        }
      } else {
        print("⚠️ No image selected (user cancelled)");
      }
    } catch (e, stackTrace) {
      print("❌ ERROR in _pickImage: $e");
      print("   Stack trace: $stackTrace");
    }
    print("📸 ========== IMAGE PICKER ENDED ==========");
  }

  Future<void> _editField(
    String title,
    TextEditingController controller,
  ) async {
    await showDialog(
      context: context,
      builder: (context) {
        final tempController = TextEditingController(text: controller.text);
        return AlertDialog(
          title: Text('Edit $title'),
          content: TextField(
            controller: tempController,
            decoration: InputDecoration(hintText: title),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  controller.text = tempController.text;
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectBirthday() async {
    DateTime selectedDate =
        DateTime.tryParse(_dobController.text) ?? DateTime(2000, 1, 1);
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.38,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: selectedDate,
                  maximumDate: DateTime.now(),
                  minimumDate: DateTime(1950),
                  onDateTimeChanged: (date) {
                    selectedDate = date;
                  },
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _dobController.text =
                        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
                  });
                  Navigator.pop(context);
                },
                child: const Text('Select'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editGender() async {
    await showDialog(
      context: context,
      builder: (context) {
        String tempGender = _gender ?? 'Male';
        return AlertDialog(
          title: const Text('Select Gender'),
          content: DropdownButton<String>(
            value: tempGender,
            items:
                ['Male', 'Female', 'Other']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
            onChanged: (val) {
              setState(() {
                tempGender = val!;
              });
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _gender = tempGender;
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  ImageProvider _getProfileImage(String? imagePath) {
    if (imagePath == null ||
        imagePath.isEmpty ||
        imagePath == 'yyyy' ||
        imagePath == 'Profile Url') {
      return const AssetImage('assets/images/person.png');
    }

    print("🖼️ Image Path: $imagePath");

    // ✅ Check if it's a network URL
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return NetworkImage(imagePath);
    }

    // ✅ LOCAL FILE PATH - FileImage use karo
    if (imagePath.startsWith('/data/') ||
        imagePath.startsWith('/storage/') ||
        imagePath.startsWith('/') ||
        imagePath.contains('cache')) {
      try {
        File file = File(imagePath);
        if (file.existsSync()) {
          return FileImage(file);
        } else {
          print('❌ File does not exist: $imagePath');
          return const AssetImage('assets/images/person.png');
        }
      } catch (e) {
        print('❌ Error loading file: $e');
        return const AssetImage('assets/images/person.png');
      }
    }

    // ✅ If it's not a URL or file path, it might be an invalid string
    // Don't try to use it as an asset path
    return const AssetImage('assets/images/person.png');
  }

  // ✅ LOGOUT FUNCTION
  Future<void> _logout() async {
    // ✅ Save screen context before showing dialog
    final screenContext = context;

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    // ✅ Check if user confirmed logout and widget is still mounted
    if (shouldLogout == true && mounted) {
      try {
        // ✅ Logout karo
        await Provider.of<SignUpProvider>(
          screenContext,
          listen: false,
        ).logout();

        // ✅ Check if still mounted before navigation
        if (!mounted) return;

        // ✅ Navigate to signup/login screen using correct route
        Navigator.pushNamedAndRemoveUntil(
          screenContext,
          AppRoutes.signup,
          (route) => false,
        );

        // ✅ Show success message if still mounted
        if (mounted) {
          ScaffoldMessenger.of(screenContext).showSnackBar(
            const SnackBar(
              content: Text('Logged out successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('❌ Logout error: $e');
        if (mounted) {
          ScaffoldMessenger.of(screenContext).showSnackBar(
            SnackBar(
              content: Text('Logout error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProfileUpdateProvider>(context);

    if (_nameController.text.isEmpty && provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Account & Security',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        actions: [
          // ✅ SAVE BUTTON
          TextButton(
            onPressed:
                provider.isLoading
                    ? null
                    : () async {
                      print("💾 ========== SAVE BUTTON PRESSED ==========");
                      print("   - Name: ${_nameController.text}");
                      print("   - Country: ${_countryController.text}");
                      print("   - Gender: ${_gender ?? 'Male'}");
                      print("   - DOB: ${_dobController.text}");
                      print("   - Image selected: ${_pickedImage != null}");

                      if (_pickedImage != null) {
                        print("   - Image path: ${_pickedImage!.path}");
                        final exists = await _pickedImage!.exists();
                        print("   - Image file exists: $exists");
                        if (exists) {
                          final size = await _pickedImage!.length();
                          print("   - Image file size: ${size / 1024} KB");
                        } else {
                          print("   ❌ WARNING: Image file does not exist!");
                        }
                      } else {
                        print("   ⚠️ No image selected for upload");
                      }

                      await provider.submitUserData(
                        context: context,
                        name: _nameController.text,
                        country: _countryController.text,
                        gender: (_gender ?? 'Male'),
                        dob: _dobController.text,
                        image: _pickedImage,
                      );

                      // ✅ Update ke baad fresh data fetch
                      await provider.fetchUserData();

                      // ✅ Clear picked image after successful save so it shows network URL from provider
                      if (mounted) {
                        setState(() {
                          _pickedImage = null; // Clear local image, now show network URL
                        });
                      }

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile updated successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                      print("💾 ========== SAVE COMPLETED ==========");
                    },
            child: const Text('Save', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Light grey pill under title (as in screenshot)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 18),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Account & Security', style: TextStyle(color: Colors.black54)),
                  ),

                  // Avatar row with green ring and chevron
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Avatar'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.greenAccent.shade400, width: 3),
                            ),
                            child: CircleAvatar(
                              radius: 28,
                              backgroundImage: _pickedImage != null
                                  ? FileImage(_pickedImage!) as ImageProvider
                                  : _getProfileImage(provider.profile_url),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                    onTap: _pickImage,
                  ),

                  const SizedBox(height: 12),

                  // Album dashed box (simple bordered box with camera icon)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6.0),
                    child: Text('Album', style: TextStyle(color: Colors.black54)),
                  ),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.115,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300, width: 1.2),
                        color: Colors.white,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.photo_camera_outlined, color: Colors.grey, size: 30),
                            SizedBox(height: 6),
                            Text('Only five photos can be uploaded and displayed', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Nickname
                  ListTile(
                    title: const Text('Nickname'),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(provider.username ?? '—', style: const TextStyle(color: Colors.grey)),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ]),
                    onTap: () => _editField('Nickname', _nameController),
                  ),

                  const Divider(height: 1),

                  // Gender
                  ListTile(
                    title: const Text('Gender'),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(_gender ?? '-', style: const TextStyle(color: Colors.grey)),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ]),
                    onTap: _editGender,
                  ),

                  const Divider(height: 1),

                  // Birthday
                  ListTile(
                    title: const Text('Birthday'),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(_dobController.text.isEmpty ? '-' : _dobController.text, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ]),
                    onTap: _selectBirthday,
                  ),

                  const Divider(height: 1),

                  // Signature
                  ListTile(
                    title: const Text('Signature'),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () => _editField('Signature', TextEditingController()),
                  ),

                  const Divider(height: 1),

                  // Security Password - highlighted row
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.profileUpdate);
                    },
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text('Security Password', style: TextStyle(fontWeight: FontWeight.w500)),
                          Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),

                  // Reset Password
                  ListTile(
                    title: const Text('Reset Password'),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () => Navigator.pushNamed(context, AppRoutes.profileUpdate),
                  ),

                  const Divider(height: 1),

                  // Phone
                  ListTile(
                    title: const Text('Phone'),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(provider.phone ?? 'Unable', style: const TextStyle(color: Colors.grey)),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ]),
                    onTap: () {},
                  ),

                  const SizedBox(height: 24),

                  // Logout Button
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Logout',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
