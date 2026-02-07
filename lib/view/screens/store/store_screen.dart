import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shaheen_star_app/components/app_image.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/components/store_bottom_sheet.dart';
import 'package:shaheen_star_app/controller/provider/store_provider.dart';
import 'package:shaheen_star_app/model/store_model.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  @override
  void initState() {
    super.initState();
    // Load mall data when screen initializes
      WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StoreProvider>().loadMallData();
      context.read<StoreProvider>().loadBackpack("");
      // Show full-screen tabbed store view on enter (matches provided screenshot)
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => SizedBox(
          height: MediaQuery.of(context).size.height,
          child: StoreBottomSheet(initialTab: 'headwear'),
        ),
      );
    });
  }

  static ImageProvider _getSafeImageProvider(String imagePath) {
    // ✅ Check for invalid values
    if (imagePath.isEmpty || 
        imagePath == 'yyyy' || 
        imagePath == 'Profile Url' ||
        imagePath == 'upload' ||
        imagePath == 'jgh' ||
        !imagePath.startsWith('assets/')) {
      return const AssetImage('assets/images/person.png');
    }
    
    // ✅ Only use AssetImage for valid asset paths
    if (imagePath.startsWith('assets/')) {
      return AssetImage(imagePath);
    }
    
    // ✅ Default to placeholder
    return const AssetImage('assets/images/person.png');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Consumer<StoreProvider>(
      builder: (context, storeProvider, child) {
        return Scaffold(
      backgroundColor: Colors.deepPurple.shade900,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4B0082), Color(0xFF7B1FA2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: size.height * 0.05),

            /// ======= Header =======
          
Padding(
  padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      // Back Arrow
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 22),
      ),

      // Title
      Center(
        child: Text(
          "Store",
          style: GoogleFonts.poppins(
            fontSize: size.width * 0.06,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      Container(
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.03,
          vertical: size.height * 0.007,
        ),
        
        
      ),


      
    ],
   ),
  ),

            SizedBox(height: size.height * 0.02),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
              Container(
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.01,
          vertical: size.height * 0.002,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF42A5F5), Color(0xFFBBDEFB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20),bottomLeft: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_outline, color: Colors.white, size: 18),
            const SizedBox(width: 5),
            Text(
              "Bag",
              style: GoogleFonts.poppins(
                fontSize: size.width * 0.04,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
            ],),

            /// ======= Center Logo =======
            Container(
              width: size.width * 0.25,
              height: size.width * 0.25,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage("assets/images/person.png"),
                  fit: BoxFit.cover,
                ),
              ),
            ),

              //  SizedBox(height: size.height * 0.02),

            /// ======= Frame Section =======
            Container(
              padding: EdgeInsets.symmetric(
                  vertical: size.height * 0.1,
                  horizontal: size.width * 0.1),
              decoration: BoxDecoration(
                image: const DecorationImage(
                  image: AssetImage("assets/images/store_frame.png"),
                  fit: BoxFit.fill,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  buildFrameItem(size, "assets/images/person.png", "7999"),
                  buildFrameItem(size, "assets/images/person.png", "8999"),
                  buildFrameItem(size, "assets/images/person.png", "8999"),
                ],
              ),
            ),

            // SizedBox(height: size.height * 0.03),

            /// ======= Scrollable Category Section =======
            Expanded(
              child: storeProvider.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : storeProvider.errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                storeProvider.errorMessage!,
                                style: const TextStyle(color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  storeProvider.loadMallData();
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : Padding(
                          padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final categories = storeProvider.categories;
                              
                              if (categories.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'No categories available',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                );
                              }

                              // Color mapping for categories
                              final colorMap = {
                                'headwear': [Colors.blue.shade100, Colors.blue.shade900],
                                'ride': [Colors.pink.shade100, Colors.purple.shade900],
                                'vehicle': [Colors.pink.shade100, Colors.purple.shade900],
                                'business card': [Colors.green.shade100, Colors.green.shade900],
                                'bubble': [Colors.orange.shade100, Colors.deepOrange.shade900],
                                'effect': [Colors.purple.shade100, Colors.deepPurple.shade900],
                                'frame': [Colors.blue.shade100, Colors.blue.shade900],
                                'theme': [Colors.blue.shade100, Colors.blue.shade900],
                              };

                              final boxes = categories.map((category) {
                                final colors = colorMap[category.id.toLowerCase()] ?? 
                                              [Colors.grey.shade100, Colors.grey.shade900];
                                return buildCategoryCard(
                                  context,
                                  size,
                                  category: category,
                                  color1: colors[0],
                                  color2: colors[1],
                                );
                              }).toList();

                              return SingleChildScrollView(
                                child: Wrap(
                                  alignment: boxes.length % 2 == 0
                                      ? WrapAlignment.center
                                      : WrapAlignment.start,
                                  spacing: size.width * 0.05,
                                  runSpacing: size.height * 0.02,
                                  children: [
                                    ...boxes,
                                    if (boxes.length.isOdd)
                                      SizedBox(width: size.width * 0.4),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }

  /// ======= Frame Item Widget =======
  Widget buildFrameItem(Size size, String imagePath, String coins) {
    return Column(
      children: [
        Container(
          width: size.width * 0.20,
          height: size.width * 0.20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            image: DecorationImage(
              image: _getSafeImageProvider(imagePath),
              fit: BoxFit.cover,
            ),
          ),
        ),
        SizedBox(height: size.height * 0.008),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.circle, color: Colors.amber, size: 18),
            const SizedBox(width: 5),
            Text(
              coins,
              style: GoogleFonts.poppins(
                fontSize: size.width * 0.040,
                color: Colors.amber,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }








Widget buildCategoryCard(
   BuildContext context,
  Size size, {
  required StoreCategory category,
  required Color color1,
  required Color color2,
}) {
  return GestureDetector(
    onTap: () {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => StoreBottomSheet(
          initialTab: category.name,
          categoryId: category.id,
        ),
      );
    },
    child: SizedBox(
      width: size.width * 0.42,
      height: size.height * 0.27,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            top: size.height * 0.01,
            left: size.width * 0.02,
            right: size.width * 0.02,
            bottom: size.height * 0.01,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(
                  colors: [color1, color2],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(size.width * 0.03),
                      child: AppImage.asset(
                        "assets/images/person.png",
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.category, color: Colors.white, size: 40);
                        },
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFF7B2CBF),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: size.height * 0.008,
                    ),
                    child: Text(
                      category.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: size.width * 0.04,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Positioned.fill(
          //   child: AppImage.asset('assets/images/image_border.png', fit: BoxFit.fill),
          // ),
        ],
      ),
    ),
  );
}
}