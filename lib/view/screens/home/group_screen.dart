import 'package:flutter/material.dart';

class GroupScreen extends StatefulWidget {
  const GroupScreen({super.key});

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  ImageProvider _getSafeImageProvider(dynamic imagePath) {
    // ✅ Convert to string and check for invalid values
    String? img = imagePath?.toString();
    if (img == null || 
        img.isEmpty || 
        img == 'yyyy' || 
        img == 'Profile Url' ||
        img == 'upload' ||
        img == 'jgh' ||
        !img.startsWith('assets/')) {
      return const AssetImage('assets/images/person.png');
    }
    
    // ✅ Only use AssetImage for valid asset paths
    if (img.startsWith('assets/')) {
      return AssetImage(img);
    }
    
    // ✅ Default to placeholder
    return const AssetImage('assets/images/person.png');
  }
  int selectedTab = 1; // 0 = Message, 1 = Group

  final String topBg = 'assets/images/bg_home.png';
  final String bottomBg = 'assets/images/bg_bottom_nav.png';

  final List<Map<String, dynamic>> recommendList = [
    {
      "name": "MD",
      "subtitle": "WC",
      "badge": "1",
      "image": "assets/images/person.png",
    },
    {
      "name": "وفا شاعر 🌸",
      "subtitle": "خوش امدید احباب",
      "badge": "2",
      "image": "assets/images/person.png",
    },
    {
      "name": "HaarmFULLTWT",
      "subtitle": "",
      "badge": null,
      "image": "assets/images/person.png",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 380;

    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFFFFAF0),
      body: Stack(
        children: [
          // 🔹 Top Background with gradient
          Container(
            width: double.infinity,
            height: size.height * 0.35,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(topBg),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFA54F),
                  Color(0xFFFFF4D9),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 🔸 Top Bar: Message | Group (+)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.06,
                    vertical: size.height * 0.015,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _buildTopTab("Message", 0),
                          SizedBox(width: size.width * 0.05),
                          _buildTopTab("Group", 1),
                        ],
                      ),
                      const Icon(Icons.add, color: Colors.white, size: 26),
                    ],
                  ),
                ),

                // 🔸 Empty Group Section
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: size.height * 0.05),
                        Center(
                          child: Column(
                            children: [
                              Image.asset(
                                'assets/images/sms.png',
                                width: size.width * 0.23,
                                height: size.width * 0.23,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "You haven't joined any groups yet",
                                style: TextStyle(
                                  fontSize: isSmall ? 13 : 15,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () {},
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.deepPurpleAccent),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                icon: const Icon(Icons.add, color: Colors.deepPurpleAccent, size: 18),
                                label: const Text(
                                  "Create Group",
                                  style: TextStyle(
                                    color: Colors.deepPurpleAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: size.height * 0.05),

                        // 🔸 Recommend Section
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
                          child: Text(
                            "Recommend",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isSmall ? 15 : 17,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: recommendList.length,
                          padding: EdgeInsets.symmetric(horizontal: size.width * 0.02),
                          itemBuilder: (context, index) {
                            final item = recommendList[index];
                            return Container(
                              margin: EdgeInsets.symmetric(vertical: size.height * 0.008),
                              padding: EdgeInsets.symmetric(
                                vertical: size.height * 0.01,
                                horizontal: size.width * 0.04,
                              ),
                              decoration: BoxDecoration(
                           
                                borderRadius: BorderRadius.circular(12),
                               
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundImage: _getSafeImageProvider(item["image"]),
                                  ),
                                  SizedBox(width: size.width * 0.03),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              item["name"],
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            if (item["badge"] != null) ...[
                                              const SizedBox(width: 5),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.lightBlueAccent,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  item["badge"],
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        if ((item["subtitle"] as String).isNotEmpty)
                                          Text(
                                            item["subtitle"],
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 13,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {},
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.grey.shade200,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: const Text(
                                      "Details",
                                      style: TextStyle(color: Colors.black87, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // 🔸 Bottom Navigation Bar
      // bottomNavigationBar: SizedBox(
      //   height: 70,
      //   child: CustomBottomNavBar(backgroundImage: bottomBg),
      // ),
    );
  }

  Widget _buildTopTab(String title, int index) {
    final bool isSelected = selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => selectedTab = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: isSelected ? 20 : 18,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 3),
              height: 2,
              width: 35,
              color: Colors.white,
            ),
        ],
      ),
    );
  }
}
