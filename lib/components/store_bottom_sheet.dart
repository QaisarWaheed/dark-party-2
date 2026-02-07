import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/controller/provider/store_provider.dart';
import 'package:shaheen_star_app/model/store_model.dart';
import 'package:shaheen_star_app/view/screens/store/backpack_screen.dart';
import 'package:shaheen_star_app/components/store_item_animation_overlay.dart';
import 'package:shaheen_star_app/utils/colors.dart';
import 'package:shaheen_star_app/view/screens/widget/cached_network_image.dart';

class StoreBottomSheet extends StatefulWidget {
  final String initialTab;
  final String? categoryId;
  const StoreBottomSheet({
    super.key,
    required this.initialTab,
    this.categoryId,
  });

  @override
  State<StoreBottomSheet> createState() => _StoreBottomSheetState();
}

class _StoreBottomSheetState extends State<StoreBottomSheet>
  with TickerProviderStateMixin {
  late TabController _tabController;
  int? selectedIndex; // 👈 for selected item index
  int _selectedDays = 30; // Default 30 days
  bool _backpackRequested = false;

  @override
  void initState() {
    super.initState();
    // Create a default controller; we'll recreate it safely when categories load
    _tabController = TabController(length: 1, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    // Will be re-created when categories update; only act when stable
    if (!_tabController.indexIsChanging) {
      final storeProvider = context.read<StoreProvider>();
      final categories = storeProvider.categories;
      if (categories.isNotEmpty && _tabController.index >= 0 && _tabController.index < categories.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            storeProvider.selectCategory(categories[_tabController.index].id);
            setState(() {
              selectedIndex = null;
            });
          }
        });
      }
    }
  }

  @override
  void dispose() {
    // remove listener and dispose controller to avoid lingering tickers
    try {
      _tabController.removeListener(_onTabChanged);
    } catch (_) {}
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Consumer<StoreProvider>(
      builder: (context, storeProvider, child) {
        final categories = storeProvider.categories;
        final selectedItem = storeProvider.selectedItem;

        // Ensure TabController length matches categories. If categories just loaded
        // and count differs, recreate controller safely to avoid assertion errors.
        final desiredLength = categories.isNotEmpty ? categories.length : 1;
        if (_tabController.length != desiredLength) {
          final oldIndex = _tabController.index;
          _tabController.removeListener(_onTabChanged);
          _tabController.dispose();

          // Determine initial index from widget.initialTab or widget.categoryId
          int initialIndex = 0;
          if (categories.isNotEmpty) {
            final idx = categories.indexWhere((cat) =>
                cat.name.toLowerCase() == widget.initialTab.toLowerCase() ||
                cat.id.toLowerCase() == (widget.categoryId ?? '').toLowerCase());
            if (idx >= 0) initialIndex = idx;
            // If oldIndex is valid and within new range, prefer keeping it
            if (oldIndex >= 0 && oldIndex < desiredLength) initialIndex = oldIndex;
            if (initialIndex >= desiredLength) initialIndex = 0;
          }

          _tabController = TabController(length: desiredLength, vsync: this, initialIndex: initialIndex);
          _tabController.addListener(_onTabChanged);

          // Select initial category after frame to avoid build conflicts
          if (categories.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) storeProvider.selectCategory(categories[_tabController.index].id);
            });
          }
        }

        return Stack(
          children: [
            // Bottom Sheet Content (full height so sheet can occupy full screen)
            Container(
              height: size.height,
              decoration: const BoxDecoration(
                color: Color(0xFF5A0098),
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                      height: 4,
                      width: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
              const SizedBox(height: 30),

              /// ==== Tabs ====
              if (categories.isNotEmpty)
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.deepPurple,
                  labelColor: Colors.deepPurple,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  isScrollable: true,
                  tabs: categories.map((cat) => Tab(text: cat.name)).toList(),
                )
              else
                const SizedBox(height: 48),

              /// ==== Tab Views ====
              Expanded(
                child: categories.isEmpty
                    ? Center(
                        child: storeProvider.isLoading
                            ? const CircularProgressIndicator()
                            : Text(
                                storeProvider.errorMessage ?? 'No categories available',
                                style: const TextStyle(color: Colors.grey),
                              ),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: categories.map((category) {
                          return buildTabContent(category.id, storeProvider);
                        }).toList(),
                      ),
              ),

              /// ==== Bottom Buttons ==== only show when item selected
              if (selectedItem != null)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration:   BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft  ,
                      end: Alignment.topRight,
                      stops: [0.0, 1.0],
                      colors: [
                        AppColors.primaryColor,
                          AppColors.primaryColor.withOpacity(0.8),
                    ],
                  ),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      // Days selector - Only 7 and 30 days available from API
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Days: ',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          DropdownButton<int>(
                            value: _selectedDays == 7 || _selectedDays == 30 ? _selectedDays : 30,
                            dropdownColor: const Color(0xFF8C68FF),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                            items: [7, 30].map((days) {
                              return DropdownMenuItem(
                                value: days,
                                child: Text(
                                  '$days days',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedDays = value;
                                });
                                storeProvider.setSelectedDays(value);
                              }
                            },
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${selectedItem.getPriceForDays(_selectedDays).toStringAsFixed(2)} Gold / ${_selectedDays}D",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: storeProvider.isPurchasing
                                    ? null
                                    : () async {
                                        final response = await storeProvider.purchaseItem(
                                          itemId: selectedItem.id,
                                          days: _selectedDays,
                                        );
                                        
                                        if (response != null && response.isSuccess) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(response.message),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                            Navigator.pop(context);
                                          }
                                        } else {
                                          if (mounted) {
                                            // Show exact backend error message
                                            final errorMessage = response?.message ?? storeProvider.errorMessage ?? 'Purchase failed';
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  errorMessage,
                                                  style: const TextStyle(color: Colors.white),
                                                ),
                                                backgroundColor: Colors.red,
                                                duration: const Duration(seconds: 5),
                                                action: SnackBarAction(
                                                  label: 'OK',
                                                  textColor: Colors.white,
                                                  onPressed: () {},
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF8C68FF),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: storeProvider.isPurchasing
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8C68FF)),
                                        ),
                                      )
                                    : const Text(
                                        "Buy",
                                        style: TextStyle(
                                          color: Color(0xFF8C68FF),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
          ],
        );
      },
    );
  }

  /// Each Tab Content
  Widget buildTabContent(String categoryId, StoreProvider storeProvider) {
    final items = storeProvider.getItemsForCategory(categoryId);

    // Find category object to detect special categories (e.g., Business card)
    final category = storeProvider.categories.firstWhere(
      (c) => c.id.toLowerCase() == categoryId.toLowerCase(),
      orElse: () => storeProvider.categories.isNotEmpty ? storeProvider.categories[0] : StoreCategory(id: categoryId, name: categoryId),
    );

    // If this is the Business Card tab, show backpack (bag) contents instead
    if (category.name.toLowerCase().contains('business')) {
      // Trigger backpack load once
      if (!_backpackRequested && !storeProvider.isLoadingBackpack && storeProvider.backpackItems.isEmpty) {
        _backpackRequested = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) storeProvider.loadBackpack(null);
        });
      }

      final backpack = storeProvider.backpackItems;

      if (storeProvider.isLoadingBackpack) {
        return const Center(child: CircularProgressIndicator());
      }

      if (backpack.isEmpty) {
        // align empty state just under the tab header (top of tab view)
        return Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No items available in this category',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF5A0098),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BackpackScreen()));
                  },
                  child: const Text('Open Backpack'),
                ),
              ],
            ),
          ),
        );
      }

      // Show backpack items in a grid
      final bottomExtra = storeProvider.selectedItem != null ? 140.0 + MediaQuery.of(context).padding.bottom : 24.0;
      return GridView.builder(
        // smaller top padding so grid starts closer to the tab header
        padding: EdgeInsets.fromLTRB(12, 8, 12, bottomExtra),
        itemCount: backpack.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.9,
        ),
        itemBuilder: (context, index) {
          final bp = backpack[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: bp.imageUrl.isNotEmpty
                        ? cachedImage(bp.imageUrl, height: 70, fit: BoxFit.contain)
                        : const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  bp.itemName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${bp.daysRemaining} days left',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      );
    }

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No items available in this category',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // When purchase bar is visible, add extra bottom padding so last rows
    // are not hidden behind the action bar or system gesture area.
    final bottomExtra = storeProvider.selectedItem != null ? 140.0 + MediaQuery.of(context).padding.bottom : 24.0;

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(12, 12, 12, bottomExtra),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final bool isSelected = storeProvider.selectedItem?.id == item.id;
        
        // Check if item has SVGA animation
        final hasSvga = item.hasSvgaAnimation || 
                       (item.hasAnimation && 
                        (item.animationFile?.toLowerCase().contains('.svga') ?? false));

        return Stack(
          children: [
            // Card - Clickable for purchase
            GestureDetector(
              onTap: () {
                // Normal selection behavior for purchase
                // If tapping the same one, unselect
                if (isSelected) {
                  storeProvider.selectItem(null);
                  setState(() {
                    selectedIndex = null;
                  });
                } else {
                  storeProvider.selectItem(item);
                  setState(() {
                    selectedIndex = index;
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isSelected ? Colors.deepPurple : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Image
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: item.imageUrl.isNotEmpty
                            ? cachedImage(
                                item.imageUrl,
                                height: 70,
                                fit: BoxFit.contain,
                               
                              )
                            : const Icon(
                                Icons.image_not_supported,
                                size: 50,
                                color: Colors.grey,
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Price - Show price range if available, otherwise show single price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.circle, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            item.price7Days != null && item.price30Days != null
                                ? "${item.price7Days} / ${item.price30Days}"
                                : item.price,
                            style: const TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
            
            // Play Icon Overlay - Only show if item has SVGA animation
            if (hasSvga)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () {
                    // Show full screen SVGA animation overlay above everything
                    print('🎬 [StoreBottomSheet] Play icon clicked, showing SVGA animation');
                    print('   - Item: ${item.itemName}');
                    print('   - SVGA URL: ${item.svgaFile ?? item.animationFile}');
                    
                    // Show overlay using Navigator overlay to appear above bottom sheet
                    showDialog(
                      context: context,
                      barrierColor: Colors.transparent,
                      barrierDismissible: true,
                      builder: (overlayContext) {
                        return StoreItemAnimationOverlay(
                          item: item,
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
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
