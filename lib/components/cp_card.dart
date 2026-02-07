
import 'dart:developer' as developer;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shaheen_star_app/controller/api_manager/api_manager.dart';
import 'package:flutter/material.dart';
import 'package:shaheen_star_app/components/app_image.dart';

import '../controller/provider/cp_toggle_provider.dart';
import '../view/screens/profile/detailed_profile_screen.dart';
import 'package:shaheen_star_app/model/cp_gift_response.dart';

class CpCards extends StatelessWidget {
final CpPeriodType? cpType;
  final String? profile1,profile2;
    final String? id1,id2;
  final String? name1,name2;
  final String? goldValue;
  final String? country1,country2;
  final String? weekStart,weekEnd;
  const CpCards({
    super.key,
    this.cpType,
     this.profile1,this.profile2,
        this.id1,this.id2,
   this.name1,this.name2,
   this.goldValue,
   this.country1,this.country2,
   this.weekStart,this.weekEnd
  });

  @override
  Widget build(BuildContext context) {
      final size = MediaQuery.of(context).size;

    void showCpPairSheet(BuildContext context) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) {
          return DraggableScrollableSheet(
            initialChildSize: 0.32,
            maxChildSize: 0.9,
            minChildSize: 0.18,
            expand: false,
            builder: (context, scrollController) {
              final hasCpPartner = (profile2 != null && profile2!.isNotEmpty);

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: hasCpPartner
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                decoration: BoxDecoration(
                                  image: const DecorationImage(
                                    image: AssetImage('assets/images/cpbackground.png'),
                                    fit: BoxFit.cover,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.pop(context);
                                            Navigator.push(context, MaterialPageRoute(builder: (_) => DetailedProfileScreen(userId: id1.toString(), screen: 'cp')));
                                          },
                                          child: CircleAvatar(
                                            radius: 48,
                                            backgroundColor: Colors.white,
                                            child: ClipOval(
                                              child: SizedBox(
                                                width: 88,
                                                height: 88,
                                                child: CachedNetworkImage(
                                                  imageUrl: profile1 ?? '',
                                                  fit: BoxFit.cover,
                                                  errorWidget: (_, __, ___) => AppImage.asset('assets/images/person.png'),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(30)),
                                          child: const Icon(Icons.favorite, color: Colors.pink, size: 28),
                                        ),
                                        const SizedBox(width: 12),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.pop(context);
                                            Navigator.push(context, MaterialPageRoute(builder: (_) => DetailedProfileScreen(userId: id2.toString(), screen: 'cp')));
                                          },
                                          child: CircleAvatar(
                                            radius: 48,
                                            backgroundColor: Colors.white,
                                            child: ClipOval(
                                              child: SizedBox(
                                                width: 88,
                                                height: 88,
                                                child: CachedNetworkImage(
                                                  imageUrl: profile2 ?? '',
                                                  fit: BoxFit.cover,
                                                  errorWidget: (_, __, ___) => AppImage.asset('assets/images/person.png'),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text('CP Rank: ${goldValue ?? '0'}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    Text(name1 ?? '', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    Wrap(alignment: WrapAlignment.center, spacing: 6, children: [Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)), child: const Text('Owner', style: TextStyle(color: Colors.white, fontSize: 12))), Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)), child: const Text('Host', style: TextStyle(color: Colors.white, fontSize: 12))), Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(4)), child: const Text('23', style: TextStyle(color: Colors.white, fontSize: 12)))]),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), decoration: BoxDecoration(color: const Color(0xFF2BA84A), borderRadius: BorderRadius.circular(8)), child: Row(children: [ClipOval(child: SizedBox(width: 36, height: 36, child: CachedNetworkImage(imageUrl: profile2 ?? '', fit: BoxFit.cover, errorWidget: (_, __, ___) => AppImage.asset('assets/images/person.png')))), const SizedBox(width: 8), Expanded(child: Text(name2 ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))), Text('ID:${id2 ?? ''}', style: const TextStyle(color: Colors.white70))])),
                              const SizedBox(height: 12),
                              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_ActionColumn(icon: Icons.favorite_border, label: 'Followed', onTap: () {}), _ActionColumn(icon: Icons.alternate_email, label: '@', onTap: () {}), _ActionColumn(icon: Icons.chat_bubble, label: 'Say hi', onTap: () {}), _ActionColumn(icon: Icons.card_giftcard, label: 'Gift', onTap: () {})]),
                              const SizedBox(height: 12),
                            ]
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 12),
                              Center(child: Column(children: [CircleAvatar(radius: 48, backgroundColor: Colors.white, child: ClipOval(child: SizedBox(width: 92, height: 92, child: CachedNetworkImage(imageUrl: profile1 ?? '', fit: BoxFit.cover, errorWidget: (_, __, ___) => AppImage.asset('assets/images/person.png'))))), const SizedBox(height: 12), Row(mainAxisSize: MainAxisSize.min, children: [Text(name1 ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(width: 8), const Icon(Icons.mic, size: 16, color: Colors.grey), const SizedBox(width: 4), const Icon(Icons.star, size: 16, color: Colors.grey), const SizedBox(width: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.pink.shade100, borderRadius: BorderRadius.circular(12)), child: const Text('Q 21', style: TextStyle(fontSize: 12, color: Colors.white))) ]), const SizedBox(height: 6), Text('ID: ${id1 ?? ''}', style: const TextStyle(color: Colors.grey))])),
                              const SizedBox(height: 12),
                              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)), child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [_StatChip(label: '0', icon: Icons.emoji_events), const SizedBox(width: 8), _StatChip(label: '0', icon: Icons.shield), const SizedBox(width: 8), _StatChip(label: '0', icon: Icons.star_border)])),
                              const SizedBox(height: 16),
                              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12), backgroundColor: Colors.blue), child: const Text('Follow', style: TextStyle(color: Colors.white))), _CircleAction(icon: Icons.alternate_email, label: '@', onTap: () {}), _CircleAction(icon: Icons.chat_bubble, label: 'Say hi', onTap: () {}), _CircleAction(icon: Icons.card_giftcard, label: 'Gift', onTap: () {})]),
                              const SizedBox(height: 12),
                            ],
                          ),
                  ),
                ),
              );
            },
          );
        },
      );
    }

    // Helper to show CP pair sheet from API models
    void showCpPairSheetWithData(BuildContext context, CpUser user, CpUserPartner partner) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) {
          return DraggableScrollableSheet(
            initialChildSize: 0.32,
            maxChildSize: 0.9,
            minChildSize: 0.18,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            image: const DecorationImage(
                              image: AssetImage('assets/images/cpbackground.png'),
                              fit: BoxFit.cover,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pop(context);
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => DetailedProfileScreen(userId: user.id.toString(), screen: 'cp')));
                                    },
                                    child: CircleAvatar(
                                      radius: 48,
                                      backgroundColor: Colors.white,
                                      child: ClipOval(
                                        child: SizedBox(
                                          width: 88,
                                          height: 88,
                                          child: CachedNetworkImage(
                                            imageUrl: user.profileUrl,
                                            fit: BoxFit.cover,
                                            errorWidget: (_, __, ___) => AppImage.asset('assets/images/person.png'),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(30)),
                                    child: const Icon(Icons.favorite, color: Colors.pink, size: 28),
                                  ),
                                  const SizedBox(width: 12),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pop(context);
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => DetailedProfileScreen(userId: partner.id.toString(), screen: 'cp')));
                                    },
                                    child: CircleAvatar(
                                      radius: 48,
                                      backgroundColor: Colors.white,
                                      child: ClipOval(
                                        child: SizedBox(
                                          width: 88,
                                          height: 88,
                                          child: CachedNetworkImage(
                                            imageUrl: partner.profileUrl,
                                            fit: BoxFit.cover,
                                            errorWidget: (_, __, ___) => AppImage.asset('assets/images/person.png'),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text('CP Rank: ${user.totalDiamond}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Wrap(alignment: WrapAlignment.center, spacing: 6, children: [Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)), child: const Text('Owner', style: TextStyle(color: Colors.white, fontSize: 12))), Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)), child: const Text('Host', style: TextStyle(color: Colors.white, fontSize: 12))), Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(4)), child: const Text('23', style: TextStyle(color: Colors.white, fontSize: 12)))]),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), decoration: BoxDecoration(color: const Color(0xFF2BA84A), borderRadius: BorderRadius.circular(8)), child: Row(children: [ClipOval(child: SizedBox(width: 36, height: 36, child: CachedNetworkImage(imageUrl: partner.profileUrl, fit: BoxFit.cover, errorWidget: (_, __, ___) => AppImage.asset('assets/images/person.png')))), const SizedBox(width: 8), Expanded(child: Text(partner.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))), Text('ID:${partner.id}', style: const TextStyle(color: Colors.white70))])),
                        const SizedBox(height: 12),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_ActionColumn(icon: Icons.favorite_border, label: 'Followed', onTap: () {}), _ActionColumn(icon: Icons.alternate_email, label: '@', onTap: () {}), _ActionColumn(icon: Icons.chat_bubble, label: 'Say hi', onTap: () {}), _ActionColumn(icon: Icons.card_giftcard, label: 'Gift', onTap: () {})]),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    }

    return  Column(
      
      
      children: [
        if(cpType==CpPeriodType.Ranking)Stack(children: [
 AppImage.asset("assets/images/xc.png",width:size.width,height:40),
Positioned(top:12,bottom: 0,left:0,right:0,child:SizedBox(
 
  child: Text(
   '$weekStart - $weekEnd',
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    textAlign: TextAlign.center,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  ),
),)
        ],),
        
        SizedBox(height: 5,),
        Stack(
        children: [
          AppImage.asset("assets/images/cp_card.png",width:size.width,height:120),

          Positioned(left:30,right:30,top:5,bottom:5,child:Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,children: [
 SizedBox(width:size.width/10,height: 120,child:AppImage.asset("assets/images/11.png")),
Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,children: [
  Column(crossAxisAlignment: CrossAxisAlignment.center,mainAxisAlignment: MainAxisAlignment.center,children: [
    
    
    GestureDetector(onTap: () async{
                      final hasPartner = (profile2 != null && profile2!.isNotEmpty);
                      developer.log('Tapped left user id:${id1 ?? ''} hasCpPartner:$hasPartner', name: 'cp_card');
              
                      // Fetch CP info and decide which sheet to show
                      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                      try {
                        final resp = await ApiManager.fetchCpRankingUserById(id1 ?? '');
                        developer.log('fetchCpRankingUserById: status=${resp.status} users=${resp.data.users.length}', name: 'cp_card');
                      if (resp.data.users.isNotEmpty && resp.data.users[0].cpUser != null) {
                        final CpUser user = resp.data.users[0];
                        final CpUserPartner partner = user.cpUser!;
                        Navigator.pop(context);
                        showCpPairSheetWithData(context, user, partner);
                        } else {
                          Navigator.pop(context);
                          developer.log('User ${id1 ?? ''} has no CP partner', name: 'cp_card');
                          showCpPairSheet(context);
                        }
                      } catch (e) {
                        Navigator.pop(context);
                        developer.log('Error fetching CP user for id ${id1 ?? ''}: $e', name: 'cp_card');
                        showCpPairSheet(context);
                      }
    },child:
    Stack(children: [
AppImage.asset("assets/images/frame.png",height: 60,),
 Positioned.fill(child:Padding(padding: EdgeInsets.all(8),child:ClipRRect(borderRadius: BorderRadius.circular(100),child:CachedNetworkImage(imageUrl: profile1!,fit: BoxFit.cover,),)))

    ]),),
SizedBox(height:2),
 Text(country1??"",style:TextStyle(fontSize: 11,) ,),
SizedBox(
  width: 70, 
  child: Text(
    name1 ?? "",
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    textAlign: TextAlign.center,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  ),
),
  ],),
  SizedBox(width:size.width/10),
  Column(crossAxisAlignment: CrossAxisAlignment.center,mainAxisAlignment: MainAxisAlignment.center,children: [

SizedBox(height:62),


SizedBox(
  width: 40,
  child: Stack(
    children: [
      // Outline
      Text(
        goldValue ?? "",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = const Color.fromARGB(255, 137, 7, 118), // outline color
        ),
      ),
      // Fill
      Text(
        goldValue ?? "",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 248, 200, 233), // fill color
        ),
      ),
    ],
  ),
),
  ],),
  SizedBox(width:size.width/10),
Column(crossAxisAlignment: CrossAxisAlignment.center,mainAxisAlignment: MainAxisAlignment.center,children: [
  GestureDetector(onTap: () async{
                final hasPartner = (profile1 != null && profile1!.isNotEmpty);
                developer.log('Tapped right user id:${id2 ?? ''} hasCpPartner:$hasPartner', name: 'cp_card');
                // Fetch CP info for right user
                showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                try {
                  final resp = await ApiManager.fetchCpRankingUserById(id2 ?? '');
                  developer.log('fetchCpRankingUserById: status=${resp.status} users=${resp.data.users.length}', name: 'cp_card');
                  if (resp.data.users.isNotEmpty && resp.data.users[0].cpUser != null) {
                    final CpUser user = resp.data.users[0];
                    final CpUserPartner partner = user.cpUser!;
                    Navigator.pop(context);
                    showCpPairSheetWithData(context, user, partner);
                  } else {
                    Navigator.pop(context);
                    developer.log('User ${id2 ?? ''} has no CP partner', name: 'cp_card');
                    showCpPairSheet(context);
                  }
                } catch (e) {
                  Navigator.pop(context);
                  developer.log('Error fetching CP user for id ${id2 ?? ''}: $e', name: 'cp_card');
                  showCpPairSheet(context);
                }
   },child:Stack(children: [
AppImage.asset("assets/images/frame.png",height: 60,),
Positioned.fill(child:Padding(padding: EdgeInsets.all(8),child:ClipRRect(borderRadius: BorderRadius.circular(100),child:CachedNetworkImage(imageUrl: profile2!,fit: BoxFit.cover,),)))

    ]),),
SizedBox(height:2),
 Text(country2??"",style:TextStyle(fontSize: 11,) ,),
SizedBox(
  width: 70, 
  child: Text(
    name2 ?? "",
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    textAlign: TextAlign.center,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  ),

)
  ],),

],),
 SizedBox(width:size.width/35,height: 120,)
          ],))
         
        ],
    
    )]);
  }
  
}

  class _ActionColumn extends StatelessWidget {
    final IconData icon;
    final String label;
    final VoidCallback onTap;
    const _ActionColumn({super.key, required this.icon, required this.label, required this.onTap});

    @override
    Widget build(BuildContext context) {
      return GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.black87, size: 22),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      );
    }
  }

class _StatChip extends StatelessWidget {
      final String label;
      final IconData icon;
      const _StatChip({super.key, required this.label, required this.icon});

      @override
      Widget build(BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
          child: Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        );
      }
    }

class _CircleAction extends StatelessWidget {
      final IconData icon;
      final String label;
      final VoidCallback onTap;
      const _CircleAction({super.key, required this.icon, required this.label, required this.onTap});

      @override
      Widget build(BuildContext context) {
        return GestureDetector(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
                child: Icon(icon, color: Colors.black54, size: 22),
              ),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        );
      }
    }
