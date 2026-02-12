import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shaheen_star_app/controller/provider/agency_provider.dart';
import 'package:shaheen_star_app/controller/provider/backback_provider.dart';
import 'package:shaheen_star_app/controller/provider/banner_provider.dart';
import 'package:shaheen_star_app/controller/provider/broadcast_provider.dart';
import 'package:shaheen_star_app/controller/provider/bottom_nav_provider.dart';
import 'package:shaheen_star_app/controller/provider/cp_provider.dart';
import 'package:shaheen_star_app/controller/provider/cp_toggle_provider.dart';
import 'package:shaheen_star_app/controller/provider/create_room_provider.dart';
import 'package:shaheen_star_app/controller/provider/get_all_room_provider.dart';
import 'package:shaheen_star_app/controller/provider/gift_display_provider.dart';
import 'package:shaheen_star_app/controller/provider/gift_provider.dart';
import 'package:shaheen_star_app/controller/provider/join_room_provider.dart';
import 'package:shaheen_star_app/controller/provider/leave_room_provider.dart';
import 'package:shaheen_star_app/controller/provider/merchant_list_provider.dart';
import 'package:shaheen_star_app/controller/provider/merchant_profile_provider.dart';
import 'package:shaheen_star_app/controller/provider/moment_provider.dart';
import 'package:shaheen_star_app/controller/provider/payout_provider.dart';
import 'package:shaheen_star_app/controller/provider/period_toggle_provider.dart';
import 'package:shaheen_star_app/controller/provider/profile_update_provider.dart';
import 'package:shaheen_star_app/controller/provider/ranking_provider.dart';
import 'package:shaheen_star_app/controller/provider/room_message_provider.dart';
import 'package:shaheen_star_app/controller/provider/room_ranking_provider.dart';
import 'package:shaheen_star_app/controller/provider/seat_provider.dart';
import 'package:shaheen_star_app/controller/provider/sign_up_provider.dart';
import 'package:shaheen_star_app/controller/provider/store_provider.dart';
import 'package:shaheen_star_app/controller/provider/user_chat_provider.dart';
import 'package:shaheen_star_app/controller/provider/user_follow_provider.dart';
import 'package:shaheen_star_app/controller/provider/user_message_provider.dart';
import 'package:shaheen_star_app/controller/provider/vip_provider.dart';
import 'package:shaheen_star_app/controller/provider/withdraw_provider.dart';
import 'package:shaheen_star_app/controller/provider/zego_voice_provider.dart';
import 'package:shaheen_star_app/components/app_image.dart';
import 'package:shaheen_star_app/firebase_options.dart';
import 'package:shaheen_star_app/routes/app_routes.dart';
import 'package:shaheen_star_app/view/screens/login/splash_screen.dart';

import 'controller/provider/bottom_sheet_bg_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env.prod');
  // Defer Firebase init until after first frame so platform channels are ready (fixes channel-error on Android).
  runApp(const _FirebaseInitWrapper());
}

/// Wrapper that initializes Firebase after the first frame, then shows MyApp or error.
class _FirebaseInitWrapper extends StatefulWidget {
  const _FirebaseInitWrapper();

  @override
  State<_FirebaseInitWrapper> createState() => _FirebaseInitWrapperState();
}

class _FirebaseInitWrapperState extends State<_FirebaseInitWrapper> {
  bool _initialized = false;
  String? _error;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initFirebase());
  }

  void _initFirebase() async {
    if (_started) return;
    _started = true;
    await Future.delayed(const Duration(milliseconds: 150));
    for (int attempt = 1; attempt <= 3 && !_initialized; attempt++) {
      try {
        if (Firebase.apps.isEmpty) {
          if (!kIsWeb &&
              defaultTargetPlatform == TargetPlatform.android &&
              attempt == 1) {
            await Firebase.initializeApp();
          } else {
            await Firebase.initializeApp(
              options: DefaultFirebaseOptions.currentPlatform,
            );
          }
        }
        if (mounted)
          setState(() {
            _initialized = true;
            _error = null;
          });
        return;
      } catch (e) {
        if (mounted)
          setState(() {
            _error = e.toString();
          });
        if (attempt < 3)
          await Future.delayed(const Duration(milliseconds: 300));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return FirebaseInitErrorApp(error: _error!);
    }
    if (_initialized) {
      return const MyApp();
    }
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: AppImage.asset(
                  'assets/images/app_logo.jpeg',
                  width: 160,
                  height: 160,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.image_not_supported,
                    size: 64,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Starting...',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    print("🏗️ [MyApp] Building widget tree...");
    print("📦 [MyApp] Setting up providers...");

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            print("✅ [MyApp] Creating SignUpProvider");
            return SignUpProvider();
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            print("✅ [MyApp] Creating CreateRoomProvider");
            return CreateRoomProvider();
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            print("✅ [MyApp] Creating ProfileUpdateProvider");
            return ProfileUpdateProvider();
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            print("✅ [MyApp] Creating BannerProvider");
            return BannerProvider();
          },
        ),
        ChangeNotifierProvider(create: (_) => BroadcastProvider()),
        ChangeNotifierProvider(
          create: (_) {
            print("✅ [MyApp] Creating GetAllRoomProvider");
            return GetAllRoomProvider();
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            print("✅ [MyApp] Creating JoinRoomProvider");
            return JoinRoomProvider();
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            print("✅ [MyApp] Creating LeaveRoomProvider");
            return LeaveRoomProvider();
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            print("✅ [MyApp] Creating RoomMessageProvider");
            return RoomMessageProvider();
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            print("✅ [MyApp] Creating BottomNavProvider");
            return BottomNavProvider();
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            print("✅ [MyApp] Creating UserMessageProvider");
            return UserMessageProvider();
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            print("✅ [MyApp] Creating VipProvider");
            return VipProvider();
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            print("✅ [MyApp] Creating SeatProvider");
            return SeatProvider();
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            print("✅ [MyApp] Creating BackpackProvider");
            return BackpackProvider();
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            print("✅ [MyApp] Creating MerchantProfileProvider");
            return MerchantProfileProvider();
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            print("✅ [MyApp] Creating PayoutProvider");
            return PayoutProvider();
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            print("✅ [MyApp] Creating WithdrawProvider");
            return WithdrawProvider();
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            print("✅ [MyApp] Creating MerchantListProvider");
            return MerchantListProvider();
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            print("✅ [MyApp] Creating GiftProvider");
            return GiftProvider();
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            print("✅ [MyApp] Creating MomentProvider");
            return MomentProvider();
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            print("✅ [MyApp] Creating GiftDisplayProvider");
            return GiftDisplayProvider();
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            print("✅ [MyApp] Creating UserChatProvider");
            return UserChatProvider();
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            print("✅ [MyApp] Creating UserFollowProvider");
            return UserFollowProvider();
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            print("✅ [MyApp] Creating AgencyProvider");
            return AgencyProvider();
          },
        ),
        ChangeNotifierProvider(create: (_) => BottomSheetBackgroundProvider()),
        ChangeNotifierProvider(
          create: (_) {
            print("✅ [MyApp] Creating ZegoVoiceProvider");
            return ZegoVoiceProvider();
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            print("✅ [MyApp] Creating StoreProvider");
            return StoreProvider();
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            print("✅ [MyApp] Creating StoreProvider");
            return PeriodToggleProvider();
          },
        ),
        //RankingProvider
        ChangeNotifierProvider(
          create: (_) {
            print("✅ [MyApp] Creating RankingProvider");
            return RankingProvider();
          },
        ),
        //RankingProvider
        ChangeNotifierProvider(
          create: (_) {
            print("✅ [MyApp] Creating CpProvider");
            return CpProvider();
          },
        ),
        //RankingProvider
        ChangeNotifierProvider(
          create: (_) {
            print("✅ [MyApp] Creating CpRoggleProvider");
            return CpPeriodToggleProvider();
          },
        ),
        //RoomRankingProvider
        ChangeNotifierProvider(
          create: (_) {
            print("✅ [MyApp] Creating RoomRankingProvider");
            return RoomRankingProvider();
          },
        ),
        //PeriodToggleProvider
      ],
      child: Builder(
        builder: (context) {
          print("🎨 [MyApp] Building MaterialApp...");
          print("📍 [MyApp] Initial route: ${AppRoutes.splash}");
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Dark Party',
            theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
            initialRoute: AppRoutes.splash,
            onGenerateRoute: AppRoutes.generateRoute,
            onUnknownRoute: (settings) {
              print(
                "⚠️ [MyApp] Unknown route: ${settings.name}, redirecting to SplashScreen",
              );
              return MaterialPageRoute(builder: (_) => const SplashScreen());
            },
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(1.0)),
                child: Stack(
                  children: [
                    child ?? const SplashScreen(),
                    Consumer<BroadcastProvider>(
                      builder: (context, broadcast, _) {
                        if (!broadcast.isBroadcastVisible)
                          return const SizedBox.shrink();
                        // Broadcast banner
                        return Positioned(
                          top: 90,
                          left: 12,
                          right: 12,
                          child: Material(
                            color: Colors.transparent,
                            child: GestureDetector(
                              onTap: () => broadcast.hideBroadcast(),
                              child: SizedBox(
                                height: 72,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Background
                                    Positioned.fill(
                                      child: Image.asset(
                                        broadcast.giftImage ==
                                                'assets/images/broadcasting_image.png'
                                            ? 'assets/images/broadcasting_image.png'
                                            : 'assets/images/lucky_main_patti.png',
                                        fit: BoxFit.fill,
                                      ),
                                    ),

                                    // Left frame + avatar
                                    Positioned(
                                      left: 8,
                                      top: 10,
                                      child: SizedBox(
                                        width: 50,
                                        height: 50,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Image.asset(
                                              'assets/images/lucky_patti_left.png',
                                              fit: BoxFit.contain,
                                            ),
                                            Positioned.fill(
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  8.0,
                                                ),
                                                child: ClipOval(
                                                  child:
                                                      broadcast
                                                          .senderProfileUrl
                                                          .isNotEmpty
                                                      ? CachedNetworkImage(
                                                          imageUrl: broadcast
                                                              .senderProfileUrl,
                                                          fit: BoxFit.cover,
                                                          placeholder:
                                                              (
                                                                context,
                                                                url,
                                                              ) => const Center(
                                                                child:
                                                                    CircularProgressIndicator(
                                                                      strokeWidth:
                                                                          2,
                                                                    ),
                                                              ),
                                                          errorWidget:
                                                              (
                                                                _,
                                                                __,
                                                                ___,
                                                              ) => Container(
                                                                color:
                                                                    Colors.grey,
                                                                child: const Icon(
                                                                  Icons.person,
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                              ),
                                                        )
                                                      : Container(
                                                          color: Colors.grey,
                                                          child: const Icon(
                                                            Icons.person,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Center text
                                    Positioned(
                                      left: 78,
                                      right: 78,
                                      top: 0,
                                      bottom: 0,
                                      child: Builder(
                                        builder: (context) {
                                          debugPrint(
                                            "🎨 [MainBanner] Render: Sen='${broadcast.senderName}', Gift='${broadcast.giftName}', Coins='${broadcast.giftAmount}'",
                                          );
                                          return Center(
                                            child: RichText(
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              text: TextSpan(
                                                style: TextStyle(
                                                  fontFamily: 'Roboto',
                                                  fontSize: 14,
                                                  shadows: [
                                                    Shadow(
                                                      color: Colors.black,
                                                      blurRadius: 2,
                                                      offset: Offset(1, 1),
                                                    ),
                                                  ],
                                                ),
                                                children: [
                                                  TextSpan(
                                                    text:
                                                        "${broadcast.senderName} ",
                                                    style: TextStyle(
                                                      color: Color(0xFFFFD700),
                                                      fontWeight:
                                                          FontWeight.w900,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: "send ",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text:
                                                        "${broadcast.giftName} ",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text:
                                                        "${broadcast.giftAmount.toStringAsFixed(0)} coins",
                                                    style: TextStyle(
                                                      color: Color(0xFFFFD700),
                                                      fontWeight:
                                                          FontWeight.w900,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),

                                    // Right frame + count
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      bottom: 8,
                                      child: AspectRatio(
                                        aspectRatio: 1,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Image.asset(
                                              'assets/images/lucky_patti_right.png',
                                              fit: BoxFit.contain,
                                            ),
                                            Positioned(
                                              bottom: 6,
                                              right: 6,
                                              child: Text(
                                                "x${broadcast.giftCount}",
                                                style: TextStyle(
                                                  color: Colors.yellowAccent,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w900,
                                                  shadows: [
                                                    Shadow(
                                                      color: Colors.black,
                                                      offset: Offset(1, 1),
                                                      blurRadius: 3,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Shown when Firebase fails to initialize. Shows the real error so you can fix it.
class FirebaseInitErrorApp extends StatelessWidget {
  final String error;

  const FirebaseInitErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    final displayError = error.length > 400
        ? '${error.substring(0, 400)}...'
        : error;
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                const SizedBox(height: 24),
                const Text(
                  'Initialization Error',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  child: Text(
                    displayError,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
