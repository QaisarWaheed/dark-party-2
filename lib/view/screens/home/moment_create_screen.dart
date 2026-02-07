import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../controller/provider/moment_provider.dart';
import '../../../utils/user_id_utils.dart';

class MomentCreateScreen extends StatefulWidget {
  const MomentCreateScreen({super.key});

  @override
  State<MomentCreateScreen> createState() => _MomentCreateScreenState();
}

class _MomentCreateScreenState extends State<MomentCreateScreen> {
 final TextEditingController _postController = TextEditingController();
  File? _selectedImage;
  String? _base64Image;
  final ImagePicker _picker = ImagePicker();
  bool _isPosting = false;

  final String topBg = 'assets/images/bg_home.png';
  dynamic userId;
  dynamic userName;
  dynamic profileUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      userId = await _getUserIdFromPrefs();
      userName = await _getUserNameFromPrefs();
      profileUrl = await _getUserProfileUrlFromPrefs();
      setState(() {});
    });
  }

Future<void> pickAndUpload(ImageSource source) async {
  try {
    // Pick image
    final XFile? pickedFile =
        await _picker.pickImage(source: source, imageQuality: 80);

    if (pickedFile == null) return;

    final file = File(pickedFile.path);

    // Detect MIME type from file extension
    String mimeType = 'image/jpeg'; // default
    final extension = file.path.split('.').last.toLowerCase();
    if (extension == 'png') {
      mimeType = 'image/png';
    } else if (extension == 'jpg' || extension == 'jpeg') {
      mimeType = 'image/jpeg';
    } else if (extension == 'gif') {
      mimeType = 'image/gif';
    }

    // Convert file to Base64
    final bytes = await file.readAsBytes();
    final base64String = base64Encode(bytes);

    // Full Data URI format
    final dataUri = "data:$mimeType;base64,$base64String";

    setState(() {
      _selectedImage = file;
      _base64Image = dataUri; // ✅ full Base64 string with MIME type
      print("Base64 Image (Data URI): $_base64Image");
    });

    // Example: Send to API
    // await uploadImage(_base64Image);

  } catch (e) {
    print("Error picking or encoding image: $e");
  }
}


  List<String> _extractHashtags(String text) {
    final regex = RegExp(r'\B#\w\w+');
    return regex
        .allMatches(text)
        .map((e) => e.group(0)!.replaceAll('#', ''))
        .toList();
  }

  Future<void> _createPost() async {
  final text = _postController.text.trim();
  if (text.isEmpty && _selectedImage == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please add content or an image')),
    );
    return;
  }

  if (userId == null || userName == null || profileUrl == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User data not loaded yet. Please wait.')),
    );
    return;
  }


  setState(() => _isPosting = true);

  final momentProvider = Provider.of<MomentProvider>(context, listen: false);

  try {
   final success = await momentProvider.createPost(
  userId: userId,
  caption: _postController.text.trim(),
  mediaUrl: _base64Image,
  mediaType: _selectedImage != null ? 'image' : 'text',
  visibility: 'public',
  hashtags: _extractHashtags(_postController.text),
);

    if (!mounted) return;

    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Post created successfully'
          ),
        backgroundColor:Colors.green,
      ),
    );
  _postController.clear();
    Navigator.pop(context);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
      _postController.clear();
  } finally {
      _postController.clear();
    if (mounted) setState(() => _isPosting = false);
  }
}
static Future<String> _getUserIdFromPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  String rawUserId = '';

  if (prefs.containsKey('user_id')) rawUserId = prefs.get('user_id')?.toString() ?? '';
  if (rawUserId.isEmpty && prefs.containsKey('database_user_id')) {
    rawUserId = prefs.get('database_user_id')?.toString() ?? '';
  }
  return UserIdUtils.formatTo8Digits(rawUserId) ?? '';
}

static Future<String> _getUserNameFromPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  String rawUserName = '';
  if (prefs.containsKey('user_name')) rawUserName = prefs.get('user_name')?.toString() ?? '';
  if (prefs.containsKey('username')) rawUserName = prefs.get('username')?.toString() ?? '';
  if (rawUserName.isEmpty && prefs.containsKey('database_user_name')) {
    rawUserName = prefs.get('database_user_name')?.toString() ?? '';
  }
  if (rawUserName.isEmpty && prefs.containsKey('database_username')) {
    rawUserName = prefs.get('database_username')?.toString() ?? '';
  }
  return rawUserName;
}

static Future<String> _getUserProfileUrlFromPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  String rawUserProfile = '';
  if (prefs.containsKey('profile_url')) rawUserProfile = prefs.get('profile_url')?.toString() ?? '';
  if (prefs.containsKey('profileUrl')) rawUserProfile = prefs.get('profileUrl')?.toString() ?? '';
  if (rawUserProfile.isEmpty && prefs.containsKey('database_profile_url')) {
    rawUserProfile = prefs.get('database_profile_url')?.toString() ?? '';
  }
  if (rawUserProfile.isEmpty && prefs.containsKey('database_profileUrl')) {
    rawUserProfile = prefs.get('database_profileUrl')?.toString() ?? '';
  }
  return rawUserProfile;
}


  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              topBg,
              width: size.width,
              fit: BoxFit.cover,
              height: size.height * 0.25,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Center(
                          child: Text(
                            "Post",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 44),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _postController,
                      maxLines: 6,
                      maxLength: 1000,
                      keyboardType: TextInputType.multiline,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: const InputDecoration(
                        counterStyle: TextStyle(color: Colors.white),
                        hintText: "What's on your mind?",
                        hintStyle: TextStyle(color: Colors.black),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Add Picture',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      builder: (_) {
                        return SizedBox(
                          height: 120,
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.photo, color: Colors.black),
                                title: const Text("Gallery", style: TextStyle(color: Colors.black)),
                                onTap: () {
                                  Navigator.pop(context);
                                  pickAndUpload(ImageSource.gallery);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.camera_alt, color: Colors.black),
                                title: const Text("Camera", style: TextStyle(color: Colors.black)),
                                onTap: () {
                                  Navigator.pop(context);
                                  pickAndUpload(ImageSource.camera);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 15),
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Center(
                                child: Icon(Icons.add_a_photo, color: Colors.black, size: 40),
                              ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isPosting ? null : _createPost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFd3902f),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: _isPosting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Create Post",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
