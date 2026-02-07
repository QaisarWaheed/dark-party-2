import 'dart:io';

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

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  File? _selectedImage;
  String selectedGender = 'Male';
  DateTime? birthday;
  Country? selectedCountry;

  final nameController = TextEditingController();

  // Step management
  int currentStep = 1; // 1 = Avatar, 2 = Birthday, 3 = Country, 4 = Final Form
  DateTime selectedBirthday = DateTime(1989, 12, 1);

  // Lime green color from screenshots
  static const Color limeGreen = Color(0xFFC8FF00);

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
      debugPrint("✅ Image selected: ${picked.path}");
    }
  }


  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProfileUpdateProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade200, // Light grey background
      body: SafeArea(
        child: Stack(
          children: [
            // Background Logo (Dark Party) - partially visible
            Positioned(
              top: -50,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: AppImage.asset(
                      'assets/images/app_logo.jpeg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade800,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.nightlight_round,
                                  size: 60,
                                  color: limeGreen,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Dark Party',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: limeGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            // Main Content - White Card Overlay (Steps 1-3)
            if (currentStep <= 3)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                top: 100,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 20,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: _buildStepContent(context, provider),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(BuildContext context, ProfileUpdateProvider provider) {
    switch (currentStep) {
      case 1:
        return _buildAvatarSelectionStep();
      case 2:
        return _buildBirthdayStep();
      case 3:
        return _buildCountryStep();
      default:
        return const SizedBox();
    }
  }

  // Step 1: Avatar Selection
  Widget _buildAvatarSelectionStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with back button and progress
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
                      color: limeGreen,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
            ],
          ),
          const SizedBox(height: 20),
          // Title
          const Text(
            'Choose your favorite avatar',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'An interesting profile is your first impression..',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 40),
          // Profile Picture Preview
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade200,
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 3,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: _selectedImage != null
                          ? Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            )
                          : Icon(
                              Icons.person,
                              size: 80,
                              color: Colors.grey.shade400,
                            ),
                    ),
                  ),
                  // Camera Icon Overlay
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: limeGreen,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          // Gallery Button
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library,
                    color: Colors.grey.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Choose from Gallery',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          // Next Button
          GestureDetector(
            onTap: () {
              // Step 1 validation: Picture must be selected
              if (_selectedImage == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Please select a profile picture!"),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              setState(() => currentStep = 2);
            },
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: limeGreen,
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Center(
                child: Text(
                  'Next',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Step 2: Birthday Picker
  Widget _buildBirthdayStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with back button and progress
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() => currentStep--);
                },
                child: const Icon(Icons.arrow_back_ios, size: 20),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '$currentStep/3',
                    style: TextStyle(
                      color: limeGreen,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
            ],
          ),
          const SizedBox(height: 20),
          // Title
          const Text(
            'Hi, Tell me your birthday',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Fill in the correct birthday to know your zodiac sign...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          // Date Picker
          Expanded(
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              maximumDate: DateTime.now(),
              minimumDate: DateTime(1950),
              initialDateTime: selectedBirthday,
              onDateTimeChanged: (DateTime dt) {
                setState(() {
                  selectedBirthday = dt;
                  birthday = dt;
                });
              },
            ),
          ),
          const SizedBox(height: 20),
          // Next Button
          GestureDetector(
            onTap: () {
              // Step 2 validation: Birthday must be selected
              // Check if birthday is set (either from previous selection or current picker)
              final birthdayToUse = birthday ?? selectedBirthday;
              setState(() {
                birthday = selectedBirthday;
                currentStep = 3;
              });
            },
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: limeGreen,
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Center(
                child: Text(
                  'Next',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Step 3: Country Selection + Name + Gender + Submit
  Widget _buildCountryStep() {
    final provider = Provider.of<ProfileUpdateProvider>(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with back button and progress
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() => currentStep--);
                },
                child: const Icon(Icons.arrow_back_ios, size: 20),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '$currentStep/3',
                    style: TextStyle(
                      color: limeGreen,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
            ],
          ),
          const SizedBox(height: 20),
          
          // Gender Selection
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Row(
              children: [
                Expanded(child: genderCard('assets/images/boy.PNG', 'Male')),
                const SizedBox(width: 16),
                Expanded(child: genderCard('assets/images/girl.PNG', 'Female')),
              ],
            ),
          ),
          const SizedBox(height: 30),
          
          // Name Field
          buildField('Name', nameController),
          const SizedBox(height: 15),
          
          // Country Picker
          GestureDetector(
            onTap: () => _showCountryPicker(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Country / Region',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedCountry == null
                              ? 'Choose Country / Region'
                              : '${selectedCountry!.flagEmoji}  ${selectedCountry!.name}',
                          style: TextStyle(
                            fontSize: 14,
                            color: selectedCountry == null
                                ? Colors.grey.shade600
                                : Colors.black87,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          
          // Submit Button (Account Create)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              onPressed: provider.isLoading
                  ? null
                  : () async {
                      // Step 3 validation: Name, Gender, Country required
                      if (nameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Name is required!"),
                          ),
                        );
                        return;
                      }
                      if (selectedGender.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please select your gender!"),
                          ),
                        );
                        return;
                      }
                      if (selectedCountry == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Please select your country!",
                            ),
                          ),
                        );
                        return;
                      }

                      final prefs = await SharedPreferences.getInstance();
                      final userId = prefs.getString('userId') ?? 'EMPTY';

                      // Use birthday from Step 2, or default to selectedBirthday, or current date
                      DateTime dobToUse = birthday ?? selectedBirthday ?? DateTime.now().subtract(const Duration(days: 365 * 18));

                      await provider.submitUserData(
                        context: context,
                        name: nameController.text.trim(),
                        country: selectedCountry!.name,
                        gender: selectedGender,
                        image: _selectedImage,
                        dob: DateFormat('yyyy-MM-dd').format(dobToUse),
                      );
                    },
              child: provider.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Submit',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showCountryPicker(BuildContext context) {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      onSelect: (Country country) {
        setState(() => selectedCountry = country);
      },
    );
  }

  Widget genderCard(String imagePath, String gender) {
    final bool isSelected = selectedGender == gender;
    
    // Colors for Male (boyish - blue) and Female (girlish - pink)
    final Color maleColor = const Color(0xFF4A90E2); // Blue - boyish color
    final Color femaleColor = const Color(0xFFFF69B4); // Pink - girlish color
    
    final Color buttonColor = isSelected
        ? (gender == 'Male' ? maleColor : femaleColor)
        : Colors.white;
    
    final Color borderColor = isSelected
        ? (gender == 'Male' ? maleColor.withOpacity(0.3) : femaleColor.withOpacity(0.3))
        : (gender == 'Male' ? maleColor : femaleColor);
    
    final Color iconColor = isSelected
        ? Colors.white
        : (gender == 'Male' ? maleColor : femaleColor);
    
    final Color textColor = isSelected
        ? Colors.white
        : (gender == 'Male' ? maleColor : femaleColor);
    
    return GestureDetector(
      onTap: () => setState(() => selectedGender = gender),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: borderColor,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppImage.asset(
              imagePath,
              height: 30,
              width: 30,
              fit: BoxFit.contain,
              color: iconColor,
            ),
            const SizedBox(width: 8),
            Text(
              gender,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),
            filled: true,
            fillColor: Colors.white,
            hintText: 'XXXXXXX',
            hintStyle: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: value == 'Choose Country / Region' || value == '2000-01-01'
                  ? Colors.grey.shade600
                  : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
