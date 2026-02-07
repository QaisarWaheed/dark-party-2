import 'package:flutter/material.dart';

class FilterCard extends StatefulWidget {
  const FilterCard({super.key});

  @override
  State<FilterCard> createState() => _FilterCardState();
}

class _FilterCardState extends State<FilterCard> {
  final ScrollController _controller = ScrollController();

  bool showStartArrow = false;
  bool showEndArrow = true;

  int selectedIndex = 0;

  final List<String> filters = [
    "🔥 Hot",
    "🇵🇰 Pakistan",
    "🇮🇳 India",
    "🇦🇺 Australia",
    "🇳🇵 Nepal",
    "🇧🇩 Bangladesh",
    "🇿🇦 South Africa",
  ];

  @override
  void initState() {
    super.initState();

    _controller.addListener(() {
      final maxScroll = _controller.position.maxScrollExtent;
      final current = _controller.offset;

      setState(() {
        showStartArrow = current > 0;
        showEndArrow = current < maxScroll;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void scrollLeft() {
    _controller.animateTo(
      (_controller.offset - 120).clamp(
        0,
        _controller.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void scrollRight() {
    _controller.animateTo(
      (_controller.offset + 120).clamp(
        0,
        _controller.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: Row(mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

         if (showStartArrow)
  Center(
    child: IconButton(
      icon: const Icon(Icons.arrow_left), // filled left arrow
      padding: EdgeInsets.zero, // remove default padding
      constraints: const BoxConstraints(), // remove default min size
      onPressed: scrollLeft,
    ),
  ),


          /// FILTER LIST
          Expanded(
            child: ListView.separated(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isSelected = selectedIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color:
                          isSelected ? Colors.yellow : Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      filters[index],
                      style: TextStyle(
                        color:
                            isSelected ? Colors.black : Colors.grey.shade400,
                        fontWeight:  isSelected ?FontWeight.bold:FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

       if (showEndArrow)
  Center(
    child: IconButton(
      icon: const Icon(Icons.arrow_right),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: scrollRight,
    ),
  ),

        ],
      ),
    );
  }
}
