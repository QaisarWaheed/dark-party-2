import 'package:flutter/material.dart';

class ThemeSelectionScreen extends StatelessWidget {
  // ✅ Image paths - apne assets ke according change karo
  static const List<String> imagePaths = [
    'assets/images/f1.jpeg',
    'assets/images/f2.jpeg', 
    'assets/images/f3.jpeg',
    'assets/images/f4.jpeg',
    'assets/images/f5.jpeg', 
    'assets/images/f6.jpeg',
    'assets/images/f7.jpeg',
    'assets/images/f8.jpeg', 
    'assets/images/f9.jpeg',
    'assets/images/f10.jpeg',
    
  ];

  const ThemeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Theme Selection'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, // ✅ 3 images in one line
            crossAxisSpacing: 10, // ✅ Space between images
            mainAxisSpacing: 10,
            childAspectRatio: 0.55, // ✅ Square images
          ),
          itemCount: imagePaths.length,
          itemBuilder: (context, index) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  imagePaths[index],
                  fit: BoxFit.cover, // ✅ Image properly fit hogi
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: Icon(Icons.error, color: Colors.red),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}