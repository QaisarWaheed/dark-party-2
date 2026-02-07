// ignore_for_file: prefer_is_empty, unnecessary_to_list_in_spreads

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/components/app_image.dart';
import 'package:shaheen_star_app/components/cp_card.dart';
import 'package:shaheen_star_app/controller/api_manager/api_constants.dart';
import 'package:shaheen_star_app/controller/provider/cp_provider.dart';
import 'package:shaheen_star_app/controller/provider/cp_toggle_provider.dart';
import 'package:shaheen_star_app/controller/provider/get_all_room_provider.dart';
import 'package:shaheen_star_app/utils/country_flag_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../components/cp_period_toggle_widget.dart';
import '../../../controller/api_manager/number_format.dart';

class CpScreen extends StatefulWidget {
  const CpScreen({super.key});

  @override
  State<CpScreen> createState() => _CpScreenState();
}

class _CpScreenState extends State<CpScreen> {
  int? currentUserId;
  // Local time range selection: daily, weekly, monthly
  String _selectedTimeRange = 'Daily';
  String _formatDateSafe(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (e) {
      // If parsing fails, return the raw string (or empty)
      return dateStr;
    }
  }
  @override
  void initState() {
    super.initState();

    /// 🔥 API CALL ON SCREEN LOAD
    WidgetsBinding.instance.addPostFrameCallback((_) async {
          final prefs = await SharedPreferences.getInstance();
      // ✅ Handle userId as both int and String
      final userIdValue = prefs.get('user_id');
      print('🆔 Raw user_id value: $userIdValue (type: ${userIdValue?.runtimeType})');
      
      if (userIdValue != null) {
        if (userIdValue is int) {
          currentUserId = userIdValue;  
        } else if (userIdValue is String) {
          currentUserId = int.tryParse(userIdValue);
        }
      }
      final getAllRoomProvider = Provider.of<GetAllRoomProvider>(context, listen: false);
       final cpProvider = Provider.of<CpProvider>(context, listen: false);

       final cpToggleProvider = context.read<CpPeriodToggleProvider>();

        // Set default period to daily (today)
      cpToggleProvider.setPeriod(CpPeriodType.Ranking);
      cpProvider.changeCpPeriod(CpPeriodType.Ranking);
      
  if(cpProvider.currentPeriod==CpPeriodType.CpWall){
cpProvider.fetchCpWall();
}else if(cpProvider.currentPeriod==CpPeriodType.Ranking){
cpProvider.fetchCpRanking();
}
      
       //  cpProvider.fetchRanking(senderId: currentUserId,type:"sender");
    });
  }

  @override
Widget build(BuildContext context) {
   final size = MediaQuery.of(context).size;
  return Container(
    width: double.infinity,
    height: double.infinity,
    decoration: const BoxDecoration(
      image: DecorationImage(
        image: AssetImage('assets/images/cpbackground.png'), // 🔥 background image (updated)
        fit: BoxFit.cover,
      ),
    ),
    child: Scaffold(
      backgroundColor: Colors.transparent,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
       
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: SafeArea(

         child:
        
         Consumer2<CpProvider, CpPeriodToggleProvider>(
          builder: (context, cpProvider, cpPeriodToggleProvider, _) {
            if (cpProvider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

          // final topUsers = cpProvider.topThreeUsers;
          // final remainingUsers = cpProvider.remainingUsers;

          //  if (topUsers.isEmpty) {
          //   return const Center(
          //     child: Text(
          //       "No cp ranking data",
          //       style: TextStyle(color: Colors.white),
          //     ),
          //   );
          // }

            return SingleChildScrollView(
            
              child:Column(
                children: [

                  // Top time-range toggle (Daily / Weekly / Monthly)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ChoiceChip(
                          label: const Text('Daily'),
                          selected: _selectedTimeRange == 'Daily',
                          onSelected: (v) {
                            setState(() => _selectedTimeRange = 'Daily');
                            if (cpProvider.currentPeriod == CpPeriodType.CpWall) {
                              cpProvider.fetchCpWall();
                            } else {
                              cpProvider.fetchCpRanking();
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Weekly'),
                          selected: _selectedTimeRange == 'Weekly',
                          onSelected: (v) {
                            setState(() => _selectedTimeRange = 'Weekly');
                            if (cpProvider.currentPeriod == CpPeriodType.CpWall) {
                              cpProvider.fetchCpWall();
                            } else {
                              cpProvider.fetchCpRanking();
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Monthly'),
                          selected: _selectedTimeRange == 'Monthly',
                          onSelected: (v) {
                            setState(() => _selectedTimeRange = 'Monthly');
                            if (cpProvider.currentPeriod == CpPeriodType.CpWall) {
                              cpProvider.fetchCpWall();
                            } else {
                              cpProvider.fetchCpRanking();
                            }
                          },
                        ),
                      ],
                    ),
                  ),


                  
                 Center(
  child:  SizedBox(
                    width: size.width * 0.9,
                    child: CpPeriodToggleWidget(
                      onCpPeriodChanged: (CpPeriodType newCpPeriod) {
                        
                        final cpProvider = context.read<CpProvider>();
                        final getAllRoomProvider = Provider.of<GetAllRoomProvider>(context, listen: false);
                         
                        

                           cpProvider.changeCpPeriod(newCpPeriod);
if(newCpPeriod==CpPeriodType.CpWall){
cpProvider.fetchCpWall();
}else if(newCpPeriod==CpPeriodType.Ranking){
cpProvider.fetchCpRanking();
}
                     
                        
                       
                         }
                      
                    ),
                  ),),
                
                if(cpProvider.currentPeriod==CpPeriodType.CpWall)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 50),
                    child: SizedBox(height:200,width:size.width,child:Stack(children: [
                  Positioned(left: 0,right:0,top:30,child:AppImage.asset("assets/images/cp3.png",width:size.width * 0.6,height:220),),
 (cpProvider.users.length>0)?Positioned(
      top:30,

      
      left:0,
      right:0,
        child: 
        (cpProvider.users[0].profileUrl!="")?CachedNetworkImage(imageUrl:ApiConstants.baseUrl+cpProvider.users[0].profileUrl ,width:50,height: 50,fit: BoxFit.contain,):
       AppImage.asset("assets/images/person.png",width:55,height: 55,fit: BoxFit.contain,)
       
      ):SizedBox.shrink(),

      Positioned(left:0,top:50,child:AppImage.asset("assets/images/cp.png",width:size.width/2,height:140),),
            (cpProvider.users.length>1)? Positioned(
      left:75,top:80,
        child: (cpProvider.users[1].profileUrl!="")?CachedNetworkImage(imageUrl:ApiConstants.baseUrl+cpProvider.users[1].profileUrl ,width:50,height: 50,fit: BoxFit.contain,):
      AppImage.asset("assets/images/person.png",width:50,height: 50,fit: BoxFit.contain,)
       
      ):SizedBox.shrink(),
        Positioned(right:0,top:35,child:AppImage.asset("assets/images/cp2.png",width:size.width/2,height:155),),
               (cpProvider.users.length>2)? Positioned(
      right:75,top:80,
        child: (cpProvider.users[2].profileUrl!="")?CachedNetworkImage(imageUrl:ApiConstants.baseUrl+cpProvider.users[2].profileUrl ,width:50,height: 50,fit: BoxFit.contain,):
      AppImage.asset("assets/images/person.png",width:50,height: 50,fit: BoxFit.contain,)
       
      ):SizedBox.shrink(),

                ]),),
                  ),
                

           
 const SizedBox(height: 20),
               

                  ...cpProvider.users.map((user) {
                    return
                  Padding(
    padding: const EdgeInsets.only(bottom: 10), // 10 pixels space between cards
    child:CpCards(
      id1: user.id.toString(),
      id2:user.cpUser!.id.toString(),
                    cpType: cpProvider.currentPeriod,
                    weekEnd: _formatDateSafe(user.weekEnd),
                    weekStart: _formatDateSafe(user.weekStart),
                    name1: user.name,
                    name2: user.cpUser!.name,
                    profile1: cpProvider.normalizeRoomProfileUrl(user.profileUrl),
                    profile2: cpProvider.normalizeRoomProfileUrl(user.cpUser!.profileUrl),
                    country1: CountryFlagUtils.getFlagEmoji(user.country),
                    country2: CountryFlagUtils.getFlagEmoji(user.cpUser!.country),
                    goldValue: formatNumberReadable(user.totalAmount).toString(),
                     
                    ))
                     ;
                  }).toList(),
                 
                ],
              )
            );
          },
        ),
      ),
    ),
  );
}


}
