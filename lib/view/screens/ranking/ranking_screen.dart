import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:shaheen_star_app/components/animated_name_text.dart';
import 'package:shaheen_star_app/components/period_toggle_widget.dart';
import 'package:shaheen_star_app/components/rank_cards.dart';
import 'package:shaheen_star_app/controller/provider/get_all_room_provider.dart';
import 'package:shaheen_star_app/controller/provider/period_toggle_provider.dart';
import 'package:shaheen_star_app/controller/provider/ranking_provider.dart';
import 'package:shaheen_star_app/utils/country_flag_utils.dart';
import 'package:shaheen_star_app/view/widgets/rank_user_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../profile/detailed_profile_screen.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  int? currentUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final userIdValue = prefs.get('user_id');
      if (userIdValue != null) {
        if (userIdValue is int) {
          currentUserId = userIdValue;
        } else if (userIdValue is String) {
          currentUserId = int.tryParse(userIdValue);
        }
      }

      final getAllRoomProvider = Provider.of<GetAllRoomProvider>(context, listen: false);
      final rankingProvider = context.read<RankingProvider>();
      final periodProvider = context.read<PeriodToggleProvider>();

      rankingProvider.setAllUsersMap(getAllRoomProvider.allUsersMap);
      periodProvider.setPeriod(PeriodType.daily);
      rankingProvider.changePeriod(PeriodType.daily);

      // default to sender on load
      rankingProvider.changeFilter('sender');
      rankingProvider.fetchRanking(senderId: currentUserId, type: 'sender');
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final rankingProvider = Provider.of<RankingProvider>(context);

    final isSender = rankingProvider.currentFilter == 'sender';
    final isReceiver = rankingProvider.currentFilter == 'receiver';

    return Stack(
      fit: StackFit.expand,
      children: [
        if (isSender)
          Image.asset(
            'assets/images/image66.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          )
        else if (isReceiver)
          Image.asset(
            'assets/images/image68.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          )
        else
          Container(color: const Color(0xff1c0c26)),

        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: InkWell(
              onTap: () {
                final getAllRoomProvider = Provider.of<GetAllRoomProvider>(context, listen: false);
                final rankingProvider = context.read<RankingProvider>();
                final periodProvider = context.read<PeriodToggleProvider>();

                rankingProvider.setAllUsersMap(getAllRoomProvider.allUsersMap);
                rankingProvider.changeFilter('sender');
                rankingProvider.changePeriod(periodProvider.selectedPeriod);
                rankingProvider.fetchRanking(senderId: currentUserId, type: 'sender');
              },
              child: const Text(
                'Gift',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            centerTitle: true,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            ),
            actions: [
              InkWell(
                onTap: () {
                  final getAllRoomProvider = Provider.of<GetAllRoomProvider>(context, listen: false);
                  final rankingProvider = context.read<RankingProvider>();
                  final periodProvider = context.read<PeriodToggleProvider>();

                  rankingProvider.setAllUsersMap(getAllRoomProvider.allUsersMap);
                  rankingProvider.changeFilter('receiver');
                  rankingProvider.changePeriod(periodProvider.selectedPeriod);
                  rankingProvider.fetchRanking(receiverId: currentUserId, type: 'receiver');
                },
                child: const Padding(
                  padding: EdgeInsets.only(right: 20),
                  child: AnimatedNameText(text: 'Receiver', fontSize: 18),
                ),
              ),
            ],
          ),
          body: Consumer2<RankingProvider, PeriodToggleProvider>(
            builder: (context, rankingProvider, periodProvider, _) {
              if (rankingProvider.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              final topUsers = rankingProvider.topThreeUsers;
              final remainingUsers = rankingProvider.remainingUsers;

              if (topUsers.isEmpty) {
                return const Center(
                  child: Text(
                    'No ranking data',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              return SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: size.height * 0.01),
                  child: Column(
                    children: [
                      // PERIOD TOGGLE
                      SizedBox(
                        width: size.width * 0.7,
                        child: PeriodToggleWidget(
                          onPeriodChanged: (PeriodType newPeriod) {
                            final rankingProvider = context.read<RankingProvider>();
                            final getAllRoomProvider = Provider.of<GetAllRoomProvider>(context, listen: false);
                            rankingProvider.setAllUsersMap(getAllRoomProvider.allUsersMap);
                            if (rankingProvider.currentFilter == 'sender') {
                              rankingProvider.changePeriod(newPeriod);
                              rankingProvider.fetchRanking(senderId: currentUserId, type: 'sender');
                            } else {
                              rankingProvider.changePeriod(newPeriod);
                              rankingProvider.fetchRanking(receiverId: currentUserId, type: 'receiver');
                            }
                          },
                        ),
                      ),

                      const SizedBox(height: 8),

                      // RANK 1
                      _buildRankOne(topUsers[0], rankingProvider),

                      const SizedBox(height: 20),

                      // RANK 2 & 3
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (topUsers.length > 1)
                            RankUserCard(
                              country: CountryFlagUtils.getFlagEmoji(topUsers[1].country),
                              name: topUsers[1].username,
                              coins: topUsers[1].totalGold.toString(),
                              avatarPath: rankingProvider.normalizeRoomProfileUrl(topUsers[1].profileUrl ?? ''),
                              backgroundPath: (rankingProvider.currentFilter == 'sender' || rankingProvider.currentFilter == 'receiver')
                                  ? 'assets/images/top2sender.png'
                                  : 'assets/images/rank2.png',
                              avatarRadius: 45,
                              userId: topUsers[1].userId,
                              textOffset: 25,
                            ),
                          const SizedBox(width: 10),
                          if (topUsers.length > 2)
                            RankUserCard(
                              country: CountryFlagUtils.getFlagEmoji(topUsers[2].country),
                              name: topUsers[2].username,
                              coins: topUsers[2].totalGold.toString(),
                              avatarPath: rankingProvider.normalizeRoomProfileUrl(topUsers[2].profileUrl ?? ''),
                              backgroundPath: (rankingProvider.currentFilter == 'sender' || rankingProvider.currentFilter == 'receiver')
                                  ? 'assets/images/top3sender.png'
                                  : 'assets/images/rank3.png',
                              avatarRadius: 50,
                              userId: topUsers[2].userId,
                              textOffset: 30,
                            ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // RANK 4+
                      ...remainingUsers
                          .map(
                            (user) => RankCards(
                              country: CountryFlagUtils.getFlagEmoji(user.country),
                              name: user.username,
                              coins: user.totalGold.toString(),
                              profile: rankingProvider.normalizeRoomProfileUrl(user.profileUrl ?? ''),
                              userId: user.userId,
                            ),
                          )
                          ,
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // RANK 1 UI
  Widget _buildRankOne(UserRanking user, RankingProvider rankingProvider) {
    final backgroundPath = (rankingProvider.currentFilter == 'sender' || rankingProvider.currentFilter == 'receiver')
        ? 'assets/images/top1sender.png'
        : 'assets/images/rank1.png';

    final imageUrl = rankingProvider.normalizeRoomProfileUrl(user.profileUrl ?? '');
    final ImageProvider avatarImage = (imageUrl.isEmpty || !imageUrl.startsWith('http'))
        ? const AssetImage('assets/images/person.png')
        : NetworkImage(imageUrl) as ImageProvider;

    return SizedBox(
      height: 180,
      width: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Image.asset(
              backgroundPath,
              fit: BoxFit.cover,
            ),
          ),

          // Avatar positioned inside the decorative circle
          Align(
            alignment: const Alignment(0, -0.25),
            child: Transform.translate(
              offset: const Offset(0, 30), // avatar offset
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailedProfileScreen(userId: user.userId.toString()),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 38,
                  backgroundImage: avatarImage,
                ),
              ),
            ),
          ),

          // Info at the bottom
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Transform.translate(
              offset: const Offset(0, 27),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(CountryFlagUtils.getFlagEmoji(user.country)),
                      const SizedBox(width: 5),
                      AnimatedNameText(text: user.username, fontSize: 13),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/gold_coin.png',
                        height: 20,
                        width: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        user.totalGold.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
