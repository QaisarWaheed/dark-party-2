import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/controller/provider/store_provider.dart';
import 'package:shaheen_star_app/model/store_model.dart';
import 'package:shaheen_star_app/components/store_item_animation_overlay.dart';
import 'package:shaheen_star_app/view/screens/widget/cached_network_image.dart';

class BackpackScreen extends StatefulWidget {
  const BackpackScreen({super.key});

  @override
  State<BackpackScreen> createState() => _BackpackScreenState();
}

class _BackpackScreenState extends State<BackpackScreen> {
  @override
  void initState() {
    super.initState();
    // Load backpack items when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final storeProvider = Provider.of<StoreProvider>(context, listen: false);
      storeProvider.loadBackpack(storeProvider.currentUserId.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.05,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                   children: [
                    // Back Button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios,
                          color: Color(0xFF333333),
                          size: 18,
                        ),
                      ),
                    ),    
                    const SizedBox(width: 70),
                    // Title with icon
              const Text(
                          "My Backpack",
                          style: TextStyle(
                            fontSize: 22,
                            color: Color(0xFF333333),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ), ],
                ),
              ),
              const SizedBox(height: 24),

              // Backpack Items List
              Expanded(
                child: Consumer<StoreProvider>(
                  builder: (context, storeProvider, _) {
                    if (storeProvider.isLoadingBackpack) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF333333)),
                        ),
                      );
                    }

                    if (storeProvider.backpackItems.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.inventory_2_outlined,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              "Your Backpack is Empty",
                              style: TextStyle(
                                fontSize: 22,
                                color: Colors.grey[800],
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                "Purchase items from the store and they will appear here",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey[600],
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 32),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF333333),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Text(
                                "Visit Store",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Only show active items (filter out expired items)
                    final activeItems = storeProvider.backpackItems;
                  
                   
                  
                    return RefreshIndicator(
                      onRefresh: () => storeProvider.loadBackpack(storeProvider.currentUserId.toString()),
                      color: const Color(0xFF333333),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Active Items Section
                            if (activeItems.isNotEmpty) ...[
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.65,
                                ),
                                itemCount: activeItems.length,
                                itemBuilder: (context, index) {
                                  return _BackpackItemCard(
                                    item: activeItems[index],
                                    isActive: activeItems[index].isActive,
                                    status:activeItems[index].status
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
     
      ),
    );
  }
}

class _BackpackItemCard extends StatefulWidget {
  final BackpackItem item;
  final bool isActive;
  final String status;

  const _BackpackItemCard({
    required this.item,
    required this.isActive,
    required this.status,
    super.key,
  });

  @override
  State<_BackpackItemCard> createState() => _BackpackItemCardState();
}

class _BackpackItemCardState extends State<_BackpackItemCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late bool _isActive;
  late String _status;


  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _isActive = widget.isActive;
    _status = widget.status;
    
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDate(String dateString) {
    try {
      // Parse date string like "2025-12-22 21:19:22"
      final dateTime = DateTime.parse(dateString);
      // Format as "Dec 22, 2025"
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return "${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}";
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isActive
                  ? const Color(0xFF4CAF50).withOpacity(0.3)
                  : Colors.grey[300]!,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Item Image Container
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFFF9F9F9),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: widget.item.imageUrl.isNotEmpty
                            ? cachedImage(
                                widget.item.imageUrl,
                                fit: BoxFit.fill,
                                width: double.infinity,
                                height: double.infinity,
                             
                              )
                            : Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 40,
                                  color: Colors.grey[400],
                                ),
                              ),
                      ),
                       // Play Icon on top right of image
                         if (_isActive &&
                           widget.item.svgaUrl != null &&
                           widget.item.svgaUrl!.isNotEmpty)
                         Positioned(
                           top: 8,
                           right: 8,
                           child: GestureDetector(
                             onTap: () {
                               // Show SVGA animation when play icon is clicked
                               final storeItem = StoreItem(
                                 id: widget.item.itemId,
                                 itemName: widget.item.itemName,
                                 price: '0',
                                 imageUrl: widget.item.imageUrl,
                                 category: widget.item.itemCategory,
                                 svgaFile: widget.item.svgaUrl,
                                 animationFile: widget.item.svgaUrl,
                               );
                               
                               showDialog(
                                 context: context,
                                 barrierColor: Colors.transparent,
                                 barrierDismissible: true,
                                 builder: (overlayContext) {
                                   return StoreItemAnimationOverlay(
                                     item: storeItem,
                                     onComplete: () {
                                       Navigator.of(overlayContext).pop();
                                     },
                                   );
                                 },
                               );
                             },
                             child: Container(
                               width: 32,
                               height: 32,
                               decoration: BoxDecoration(
                                 color: const Color(0xFFFFFFFF),
                                 shape: BoxShape.circle,
                                 boxShadow: [
                                   BoxShadow(
                                     color: Colors.black.withOpacity(0.2),
                                     blurRadius: 4,
                                     offset: const Offset(0, 2),
                                   ),
                                 ],
                               ),
                               child: const Icon(
                                 Icons.play_arrow,
                                 color: Colors.black,
                                 size: 18,
                               ),
                             ),
                           ),
                         ),
                    ],
                  ),
                ),
              ),

              // Content Section
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Row 1: Item Name and Expiry Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Item Name
                          Expanded(
                            child: Text(
                              widget.item.itemName,
                              style: TextStyle(
                                color: widget.isActive
                                    ? const Color(0xFF333333)
                                    : Colors.grey[600],
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                letterSpacing: 0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Days Remaining / Expired Status
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: widget.isActive
                                  ? const Color(0xFF4CAF50).withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: widget.isActive
                                    ? const Color(0xFF4CAF50).withOpacity(0.3)
                                    : Colors.red.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  widget.isActive ? Icons.access_time : Icons.cancel,
                                  size: 10,
                                  color: widget.isActive
                                      ? const Color(0xFF4CAF50)
                                      : Colors.red,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  widget.isActive
                                      ? "${widget.item.daysRemaining}d"
                                      : "Exp",
                                  style: TextStyle(
                                    color: widget.isActive
                                        ? const Color(0xFF4CAF50)
                                        : Colors.red,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      
                      // Row 2: Category and Expiration Date
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Item Category
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.item.itemCategory.toUpperCase(),
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          // Expires At Date
                          if (widget.item.expiresAt.isNotEmpty)
                            Expanded(
                              child: Text(
                                _formatDate(widget.item.expiresAt),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 9,
                                  fontWeight: FontWeight.w400,
                                ),
                                textAlign: TextAlign.right,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height:10),
                      
Row(mainAxisAlignment: MainAxisAlignment.end,children: [
                    GestureDetector(
      onTap: (){
        setState(() {
          if (_status == "active") {
            _status = "deactive";
            _isActive = false;
          } else {
            _status = "active";
            _isActive = true;
          }
        });
      },
     
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 50,
        height:20,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: _status == "active" ? Colors.green : Colors.red,
          borderRadius: BorderRadius.circular(50),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: _status == "active"  ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20 - 6,
            height: 20 - 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    )
])
                    ],
                  ),
                ),
              ),
             ],
           ),
         
     );
   }
 }

