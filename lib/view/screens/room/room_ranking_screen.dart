import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/components/app_image.dart';
import 'package:shaheen_star_app/components/animated_name_text.dart';
import 'package:shaheen_star_app/components/rank_cards.dart';
import 'package:shaheen_star_app/controller/provider/get_all_room_provider.dart';
import 'package:shaheen_star_app/controller/provider/period_toggle_provider.dart';
import 'package:shaheen_star_app/controller/provider/room_ranking_provider.dart';
import 'package:shaheen_star_app/utils/country_flag_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RoomRankingScreen extends StatefulWidget {
  final int? roomId;
  final String initialFilter; // "sender" or "receiver"
  final bool isPopup;

  const RoomRankingScreen({
    super.key,
    this.roomId,
    this.initialFilter = "sender",
    this.isPopup = false,
  });

  @override
  State<RoomRankingScreen> createState() => _RoomRankingScreenState();
}

class _RoomRankingScreenState extends State<RoomRankingScreen> {
  static const String _crownBg = 'assets/images/crown_sender.png';
  static const String _receiverCrownBg = 'assets/images/reciever_background.png';
  static const String _rank1Bg = 'assets/images/1st_rank.png';
  static const String _rank23Bg = 'assets/images/rank_sender_2.png';

  late SharedPreferences sharedPreferences;
  int currentUserId = 0;

  bool _isSender = true;
  int _selectedTopTab = 0;
  int _selectedPeriod = 0;

  @override
  void initState() {
    super.initState();
    _isSender = widget.initialFilter == "sender";
    _selectedTopTab = _isSender ? 0 : 1;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initStateData();
    });
  }

  Future<void> _initStateData() async {
    sharedPreferences = await SharedPreferences.getInstance();
    final storedId = sharedPreferences.getInt('user_id') ??
        int.tryParse(sharedPreferences.getString('user_id') ?? '') ??
        0;

    if (!mounted) return;

    setState(() {
      currentUserId = storedId;
    });

    final periodProvider = context.read<PeriodToggleProvider>();
    setState(() {
      _selectedPeriod = _periodIndex(periodProvider.selectedPeriod);
    });

    final roomRankingProvider = context.read<RoomRankingProvider>();
    final getAllRoomProvider = context.read<GetAllRoomProvider>();

    roomRankingProvider.setAllUsersMap(getAllRoomProvider.allUsersMap);
    roomRankingProvider.changeFilter(_isSender ? "sender" : "receiver");
    roomRankingProvider.changePeriod(periodProvider.selectedPeriod);
    roomRankingProvider.fetchRoomRanking(
      roomId: widget.roomId,
      type: _isSender ? "sender" : "receiver",
    );
  }

  int _periodIndex(PeriodType period) {
    switch (period) {
      case PeriodType.daily:
        return 0;
      case PeriodType.weekly:
        return 1;
      case PeriodType.monthly:
        return 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isCharm = _selectedTopTab == 1;
    final backgroundAsset = 'assets/images/Rectangle_35.png';
    final content = _buildRankingContent(size);

    if (widget.isPopup) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (isCharm)
              Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF790566),
                          Color(0xFFAC2689),
                        ],
                      ),
                    ),
                  ),
                  ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 63.3,
                        sigmaY: 63.3,
                      ),
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                ],
              )
            else ...[
              Container(color: const Color(0xFF3B0C0C)),
              AppImage.asset(
                backgroundAsset,
                fit: BoxFit.cover,
              ),
            ],
            LayoutBuilder(
              builder: (context, constraints) {
                final popupSize =
                    Size(constraints.maxWidth, constraints.maxHeight);
                return _buildRankingContent(
                  popupSize,
                  topPadding: 12,
                );
              },
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: isCharm
          ? Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF790566),
                        Color(0xFFAC2689),
                      ],
                    ),
                  ),
                ),
                ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 63.3,
                      sigmaY: 63.3,
                    ),
                    child: Container(color: Colors.transparent),
                  ),
                ),
                Scaffold(
                  backgroundColor: Colors.transparent,
                  appBar: AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    centerTitle: true,
                    title: const Text(
                      'Contrib. list',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    leading: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    ),
                  ),
                  body: content,
                ),
              ],
            )
          : Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(backgroundAsset),
                  fit: BoxFit.cover,
                ),
              ),
              child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: const Text(
              'Contrib. list',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            ),
          ),
          body: content,
        ),
            ),
    );
  }

  Widget _buildRankingContent(Size size, {double topPadding = 0}) {
    return Consumer2<RoomRankingProvider, PeriodToggleProvider>(
      builder: (context, roomRankingProvider, periodProvider, _) {
        final isCharm = _selectedTopTab == 1;
        if (roomRankingProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        final topUsers = roomRankingProvider.topThreeUsers;
        final remainingUsers = roomRankingProvider.remainingUsers;

        final baseTopPadding = topPadding + size.height * 0.02;
        final adjustedTopPadding = baseTopPadding - 100;

        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              top: adjustedTopPadding < 0 ? 0 : adjustedTopPadding,
              bottom: size.height * 0.02,
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTopTab('Contrib. list', 0),
                      const SizedBox(width: 16),
                      _buildTopTab('Charm', 1),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPeriodChip('Daily', 0, roomRankingProvider, periodProvider),
                      const SizedBox(width: 8),
                      _buildPeriodChip('Weekly', 1, roomRankingProvider, periodProvider),
                      const SizedBox(width: 8),
                      _buildPeriodChip('Monthly', 2, roomRankingProvider, periodProvider),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (topUsers.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: _buildTopThreeSection(
                      topUsers,
                      roomRankingProvider,
                      receiverBackdropAsset: isCharm ? _receiverCrownBg : null,
                      crownAsset: isCharm ? null : _crownBg,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (remainingUsers.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ...remainingUsers.map((user) {
                      return RankCards(
                        country: CountryFlagUtils.getFlagEmoji(user.country),
                        name: user.username,
                        coins: user.totalGold.toString(),
                        profile: roomRankingProvider.normalizeRoomProfileUrl(user.profileUrl),
                      );
                    }),
                  ],
                ] else
                  const Text(
                    'No Data',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  ImageProvider _profileImageProvider(
    UserRanking user,
    RoomRankingProvider roomRankingProvider,
  ) {
    final normalized = roomRankingProvider.normalizeRoomProfileUrl(user.profileUrl);
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return NetworkImage(normalized);
    }
    return AssetImage(normalized);
  }

  Widget _buildTopThreeSection(
    List<UserRanking> topUsers,
    RoomRankingProvider roomRankingProvider, {
    String? receiverBackdropAsset,
    String? crownAsset,
  }) {
    final rank1 = topUsers.isNotEmpty ? topUsers[0] : null;
    final rank2 = topUsers.length > 1 ? topUsers[1] : null;
    final rank3 = topUsers.length > 2 ? topUsers[2] : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final centerWidth = width * 0.5;
        final centerHeight = width * 0.74;
        final sideWidth = width * 0.4;
        final sideHeight = width * 0.62;
        final crownWidth = width * 0.9 < 377.0 ? width * 0.9 : 377.0;
        final crownHeight = crownWidth * (326.0 / 377.0);

        return SizedBox(
          height: width * 1.0,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              if (receiverBackdropAsset != null)
                Positioned(
                  top: width * 0.02,
                  left: (width - crownWidth) / 2,
                  child: AppImage.asset(
                    receiverBackdropAsset,
                    width: crownWidth,
                    height: crownHeight,
                    fit: BoxFit.contain,
                  ),
                ),
              if (crownAsset != null)
                Positioned(
                  top: width * 0.02 - 100,
                  left: (width - crownWidth) / 2,
                  child: AppImage.asset(
                    crownAsset,
                    width: crownWidth,
                    height: crownHeight,
                    fit: BoxFit.contain,
                  ),
                ),

              // RANK 2 (Left)
              Positioned(
                left: width * 0.02,
                top: width * 0.46,
                child: _buildWingCard(
                  user: rank2,
                  rank: 2,
                  backgroundAsset: _rank23Bg,
                  roomRankingProvider: roomRankingProvider,
                  cardWidth: sideWidth,
                  cardHeight: sideHeight,
                ),
              ),

              // RANK 3 (Right)
              Positioned(
                right: width * 0.02,
                top: width * 0.46,
                child: _buildWingCard(
                  user: rank3,
                  rank: 3,
                  backgroundAsset: _rank23Bg,
                  roomRankingProvider: roomRankingProvider,
                  cardWidth: sideWidth,
                  cardHeight: sideHeight,
                ),
              ),

              // RANK 1 (Center) - Keep on top
              Positioned(
                top: width * 0.34,
                child: _buildRankOnePodium(
                  user: rank1,
                  roomRankingProvider: roomRankingProvider,
                  cardWidth: centerWidth,
                  cardHeight: centerHeight,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---- FIXED: Rank 2 & 3 Card Logic ----
  Widget _buildWingCard({
    required UserRanking? user,
    required int rank,
    required String backgroundAsset,
    required RoomRankingProvider roomRankingProvider,
    required double cardWidth,
    required double cardHeight,
  }) {
    // Adjust these values if avatar is slightly off-center
    final avatarSize = cardWidth * 0.34;
    const avatarOffsetX = 0.0;
    const avatarOffsetY = 18.0;
    final avatarLeft = (cardWidth - avatarSize) / 2 + avatarOffsetX;
    final avatarTop = cardHeight * 0.2 + avatarOffsetY;

    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // LAYER 1: Avatar (Sabse Neeche - Behind the frame)
          if (user != null)
            Positioned(
              top: avatarTop,
              left: avatarLeft,
              child: ClipOval(
                child: Image(
                  image: _profileImageProvider(user, roomRankingProvider),
                  width: avatarSize,
                  height: avatarSize,
                  fit: BoxFit.cover,
                ),
              ),
            ),

          // LAYER 2: Frame (Avatar ke Upar)
          AppImage.asset(
            backgroundAsset,
            width: cardWidth,
            height: cardHeight,
            fit: BoxFit.contain,
          ),

          // LAYER 3: Data (Name & Coins - Sabse Upar)
          if (user != null)
            Positioned(
              bottom: cardHeight * 0.38,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    CountryFlagUtils.getFlagEmoji(user.country),
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  AnimatedNameText(
                    text: user.username,
                    fontSize: 11,
                    color: Colors.white,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1)),
                    ],
                  ),
                ],
              ),
            ),
          if (user != null)
            Positioned(
              bottom: cardHeight * 0.28,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppImage.asset(
                    "assets/images/gold_coin.png",
                    height: 14,
                    width: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    user.totalGold.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ---- NEW: Rank 1 Card Logic (Fixes Missing Function) ----
  Widget _buildRankOnePodium({
    required UserRanking? user,
    required RoomRankingProvider roomRankingProvider,
    required double cardWidth,
    required double cardHeight,
  }) {
    // Adjust these for Rank 1 Size
    final avatarSize = cardWidth * 0.4;
    const avatarOffsetX = 0.0;
    const avatarOffsetY = 20.0;
    final avatarLeft = (cardWidth - avatarSize) / 2 + avatarOffsetX;
    final avatarTop = cardHeight * 0.18 + avatarOffsetY;

    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // LAYER 1: Avatar (Behind Frame)
          if (user != null)
            Positioned(
              top: avatarTop,
              left: avatarLeft,
              child: ClipOval(
                child: Image(
                  image: _profileImageProvider(user, roomRankingProvider),
                  width: avatarSize,
                  height: avatarSize,
                  fit: BoxFit.cover,
                ),
              ),
            ),

          // LAYER 2: Frame
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Transform.scale(
              scale: 1.08,
              child: AppImage.asset(
                _rank1Bg,
                width: cardWidth,
                height: cardHeight,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // LAYER 3: Data
          if (user != null)
            Positioned(
              bottom: cardHeight * 0.38,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    CountryFlagUtils.getFlagEmoji(user.country),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 4),
                  AnimatedNameText(
                    text: user.username,
                    fontSize: 13,
                    color: Colors.white,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1)),
                    ],
                  ),
                ],
              ),
            ),
          if (user != null)
            Positioned(
              bottom: cardHeight * 0.28,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppImage.asset(
                    "assets/images/gold_coin.png",
                    height: 18,
                    width: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    user.totalGold.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopTab(String title, int index) {
    final isSelected = _selectedTopTab == index;
    return GestureDetector(
      onTap: () {
        if (_selectedTopTab == index) return;

        final newIsSender = index == 0;
        setState(() {
          _selectedTopTab = index;
          _isSender = newIsSender;
        });

        final roomRankingProvider = context.read<RoomRankingProvider>();
        roomRankingProvider.changeFilter(newIsSender ? "sender" : "receiver");
        roomRankingProvider.fetchRoomRanking(
          roomId: widget.roomId,
          type: newIsSender ? "sender" : "receiver",
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 28,
            height: 2,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFFD54F) : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(
    String label,
    int index,
    RoomRankingProvider roomRankingProvider,
    PeriodToggleProvider periodProvider,
  ) {
    final isSelected = _selectedPeriod == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedPeriod = index);

        final period = index == 0
            ? PeriodType.daily
            : index == 1
                ? PeriodType.weekly
                : PeriodType.monthly;

        roomRankingProvider.changePeriod(period);
        periodProvider.setPeriod(period);

        if (roomRankingProvider.currentFilter == "sender") {
          roomRankingProvider.fetchRoomRanking(
            roomId: widget.roomId,
            type: "sender",
          );
        } else {
          roomRankingProvider.fetchRoomRanking(
            roomId: widget.roomId,
            type: "receiver",
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFD54F) : Colors.black.withOpacity(0.35),
          borderRadius: BorderRadius.circular(14),
          border: isSelected ? null : Border.all(color: Colors.white24, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}