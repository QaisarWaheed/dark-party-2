import 'dart:io';

import 'package:country_flags/country_flags.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/components/app_image.dart';
import 'package:shaheen_star_app/controller/provider/profile_update_provider.dart';
import 'package:shaheen_star_app/utils/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

ImageProvider _getImageProvider(String? imagePath) {
  if (imagePath == null ||
      imagePath.isEmpty ||
      imagePath == 'yyyy' ||
      imagePath == 'Profile Url') {
    return const AssetImage('assets/images/person.png');
  }

  if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
    return NetworkImage(imagePath);
  }

  if (imagePath.startsWith('/data/') ||
      imagePath.startsWith('/storage/') ||
      imagePath.contains('cache')) {
    try {
      File file = File(imagePath);
      if (file.existsSync()) {
        return FileImage(file);
      } else {
        return const AssetImage('assets/images/person.png');
      }
    } catch (e) {
      return const AssetImage('assets/images/person.png');
    }
  }

  return const AssetImage('assets/images/person.png');
}

class ProfileUpdateScreen extends StatefulWidget {
  const ProfileUpdateScreen({super.key});

  @override
  State<ProfileUpdateScreen> createState() => _ProfileUpdateScreenState();
}

class _ProfileUpdateScreenState extends State<ProfileUpdateScreen> {
  File? _selectedImage;
  String? selectedCountryCode;
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController birthdayController = TextEditingController();
  final TextEditingController countryController = TextEditingController();

  String selectedGender = 'Boy';

  // Stepper state for profile update steps (1/3)
  int currentStep = 1;
  // Six avatar slots for step 1; users pick images from gallery
  final List<File?> avatarChoices = List<File?>.filled(6, null);
  // Selected birthday for step 2
  DateTime selectedBirthday = DateTime(2000, 1, 1);

  Future<void> pickAvatar(int index) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() {
        avatarChoices[index] = File(picked.path);
        // use selected avatar as the top profile preview
        _selectedImage = avatarChoices[index];
      });
      debugPrint("✅ Avatar $index selected: ${picked.path}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProfileUpdateProvider>(context);

    Future<void> pickImage() async {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);

      if (picked != null) {
        setState(() {
          _selectedImage = File(picked.path);
        });
        debugPrint("✅ Image selected: ${picked.path}");
      }
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xffb7a8d1), Color(0xfff9d2d5)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Main scrollable content stays in background
              ListView(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 30),
                children: [
                  // Profile Avatar (top preview)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 45,
                            backgroundColor: AppColors.grey2,
                            backgroundImage: _selectedImage != null
                                ? FileImage(_selectedImage!)
                                : (provider.profile_url != null && provider.profile_url!.isNotEmpty)
                                    ? _getImageProvider(provider.profile_url)
                                    : null,
                            child: (_selectedImage == null && (provider.profile_url == null || provider.profile_url!.isEmpty))
                                ? const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: AppColors.grey,
                                  )
                                : null,
                          ),

                          // Camera icon
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: pickImage,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 2,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: AppColors.primaryColor,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // Keep the rest of the existing form under the step sheet
                  // Gender Selection
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 60),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        genderCard('assets/images/male.png', 'Boy'),
                        const SizedBox(width: 10),
                        genderCard('assets/images/female.png', 'Girl'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  const Text(
                    "Birthday",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _selectBirthday(context),
                    child: DisplayContainer(
                      value: birthdayController.text,
                      borderRadius: 30,
                    ),
                  ),

                  const SizedBox(height: 30),
                  const Text(
                    "Country Region",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _showCountryPicker(context),
                    child: DisplayContainer(
                      value: countryController.text,
                      borderRadius: 30,
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (selectedCountryCode != null) CountryFlag.fromCountryCode(selectedCountryCode!),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_ios_outlined,
                            color: Colors.grey,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Submit Button (remains in background)
                  ElevatedButton(
                    onPressed: provider.isLoading
                        ? null
                        : () async {
                            final prefs = await SharedPreferences.getInstance();
                            final userId = prefs.getString('userId') ?? 'EMPTY';

                            if (birthdayController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Please select your birthday!"),
                                ),
                              );
                              return;
                            }

                            if (countryController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Please select your country!"),
                                ),
                              );
                              return;
                            }

                            await provider.submitUserData(
                              context: context,
                              name: usernameController.text.trim(),
                              country: countryController.text.trim(),
                              gender: selectedGender,
                              image: _selectedImage,
                              dob: birthdayController.text,
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffb25529),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      minimumSize: const Size(double.infinity, 44),
                    ),
                    child: provider.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Submit",
                            style: TextStyle(fontSize: 14, color: Colors.white),
                          ),
                  ),

                  const SizedBox(height: 120), // space for the overlay
                ],
              ),

              // Step 1 overlay sheet for avatar selection
              if (currentStep == 1)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 420,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, -4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                // back behavior for stepper
                                if (currentStep > 1) {
                                  setState(() => currentStep--);
                                } else {
                                  Navigator.of(context).maybePop();
                                }
                              },
                              child: const Icon(Icons.arrow_back_ios, size: 20),
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  '$currentStep/3',
                                  style: TextStyle(
                                    color: const Color(0xFFC8FF00),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Choose your favorite avatar',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'An interesting profile is your first impression..',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),

                        // Avatar grid
                        Expanded(
                          child: GridView.count(
                            crossAxisCount: 3,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1,
                            physics: const NeverScrollableScrollPhysics(),
                            children: List.generate(6, (index) {
                              final img = avatarChoices[index];
                              return GestureDetector(
                                onTap: () => pickAvatar(index),
                                child: Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
                                  ),
                                  child: ClipOval(
                                    child: Container(
                                      width: 72,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        image: img != null ? DecorationImage(image: FileImage(img), fit: BoxFit.cover) : null,
                                        border: Border.all(color: Colors.white, width: 4),
                                      ),
                                      child: img == null
                                          ? (index == 5
                                              ? Center(
                                                  child: Container(
                                                    width: 44,
                                                    height: 44,
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey.shade200,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(Icons.refresh, color: Colors.grey, size: 28),
                                                  ),
                                                )
                                              : const Center(
                                                  child: Icon(Icons.add, color: Colors.grey, size: 28),
                                                ))
                                          : null,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),

                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              currentStep = 2; // move to next step (placeholder)
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFC8FF00),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: const Center(
                              child: Text(
                                'Next',
                                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Step 2: birthday picker overlay (matches screenshot)
              if (currentStep == 2)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 420,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, -4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (currentStep > 1) {
                                  setState(() => currentStep--);
                                } else {
                                  Navigator.of(context).maybePop();
                                }
                              },
                              child: const Icon(Icons.arrow_back_ios, size: 20),
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  '$currentStep/3',
                                  style: TextStyle(
                                    color: const Color(0xFFC8FF00),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Hi, Tell me your birthday',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Fill in the correct birthday to know your zodiac sign...',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: CupertinoDatePicker(
                            mode: CupertinoDatePickerMode.date,
                            maximumDate: DateTime.now(),
                            minimumDate: DateTime(1950),
                            initialDateTime: selectedBirthday,
                            onDateTimeChanged: (DateTime dt) {
                              setState(() {
                                selectedBirthday = dt;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              birthdayController.text = DateFormat('yyyy-MM-dd').format(selectedBirthday);
                              currentStep = 3; // go to country step
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFC8FF00),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: const Center(
                              child: Text(
                                'Next',
                                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Step 3: country / region picker overlay
              if (currentStep == 3)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 300,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, -4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (currentStep > 1) {
                                  setState(() => currentStep--);
                                } else {
                                  Navigator.of(context).maybePop();
                                }
                              },
                              child: const Icon(Icons.arrow_back_ios, size: 20),
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  '$currentStep/3',
                                  style: TextStyle(
                                    color: const Color(0xFFC8FF00),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Country / Region',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Choose the country you are currently residing in...',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => _showCountryPicker(context),
                          child: DisplayContainer(
                            value: countryController.text.isEmpty ? 'Choose Country / Region' : countryController.text,
                            borderRadius: 30,
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (selectedCountryCode != null) CountryFlag.fromCountryCode(selectedCountryCode!),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_ios_outlined,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            // finish stepper and close overlay
                            setState(() => currentStep = 0);
                          },
                          child: Container(
                            width: double.infinity,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFC8FF00),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: const Center(
                              child: Text(
                                'Next',
                                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Gender card
  Widget genderCard(String imagePath, String gender) {
    final isSelected = selectedGender == gender;
    return GestureDetector(
      onTap: () => setState(() => selectedGender = gender),
      child: Container(
        height: 50,
        width: 120,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xffc1abd1) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xffcff7ff), width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppImage.asset(imagePath, height: 30, width: 30, fit: BoxFit.contain),
            const SizedBox(width: 8),
            Text(
              gender,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCountryPicker(BuildContext context) {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      onSelect: (Country country) {
        setState(() {
          countryController.text = country.name;
          selectedCountryCode = country.countryCode; // save code
        });
      },
    );
  }

  void _selectBirthday(BuildContext context) async {
    DateTime selectedDate = DateTime(2000, 1, 1);

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        height: 350,
        child: Column(
          children: [
            const Text(
              "Your Birthday",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                maximumDate: DateTime.now(),
                minimumDate: DateTime(1950),
                initialDateTime: selectedDate,
                onDateTimeChanged: (DateTime dateTime) {
                  selectedDate = dateTime;
                },
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                setState(() {
                  birthdayController.text = DateFormat(
                    'yyyy-MM-dd',
                  ).format(selectedDate);
                });
                Navigator.pop(context);
              },
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFD5BFF), Color(0xFF8C68FF)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Center(
                  child: Text(
                    "Sure",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// DisplayContainer for birthday/country
class DisplayContainer extends StatelessWidget {
  final String value;
  final double borderRadius;
  final Color? fillColor;
  final double? height;
  final Widget? suffixIcon;

  const DisplayContainer({
    super.key,
    required this.value,
    this.borderRadius = 12,
    this.fillColor,
    this.height,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? 48,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: fillColor ?? AppColors.bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Text(
                value.isEmpty ? "Select your value" : value,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
          ),
          if (suffixIcon != null) suffixIcon!,
        ],
      ),
    );
  }
}
