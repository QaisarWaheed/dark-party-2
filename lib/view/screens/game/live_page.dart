// // Flutter imports:
// import 'dart:convert';

// // import 'dart:ffi';

// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';

// // Project imports:
// import 'common.dart';
// import 'game_plugin.dart';
// import 'game_utils.dart';

// const String MG_NAME_LOGIN_AUTH_URL = 'https://prod-hellosud-base.s00.tech';
// const String MG_APPID = '1461564080052506636';
// const String MG_APPKEY = '03pNxK2lEXsKiiwrBQ9GbH541Fk2Sfnc';
// const bool MG_APP_IS_TEST_ENV = true;

// class LivePage extends StatefulWidget {
//   final String liveID;
//   final bool isHost;
//   final String senderid;

//   const LivePage({
//     super.key, required this.liveID, this.isHost = false, this.senderid,});

//   @override
//   State<StatefulWidget> createState() => LivePageState();
// }

// class LivePageState extends State<LivePage> {
//   String _authcode = '';
//   Widget? _gameView;
//   final GlobalKey _gameViewKey = GlobalKey();
//   final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

//   @override
//   void initState() {
//     super.initState();
//     print("SudMGPPlugin registerEventHandler");
//     SudMGPPlugin.registerEventHandler(onGameEvent);
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       print("addPostFrameCallback callback");
//     });
//     _gameView = getPlatformView('SudMGPPluginView', (int viewid) {});
//     // getCode();
//     // initGameSDK();
//   }

//   @override
//   void dispose() {
//     super.dispose();
//   }

//   void getCode() {
//     postRequest(MG_NAME_LOGIN_AUTH_URL, '/login/v3', {
//       'user_id': widget.senderid,
//       'app_id': MG_APPID,
//     }).then(
//       (rsp) => setState(() {
//         if (rsp['ret_code'] == 0) {
//           _authcode = rsp['data']['code'];
//         }
//         print("getCode:$rsp");
//       }),
//     );
//   }
// //// ya sab kuch chie apko current user id websocket wali or room id phir game live hogi gi
// ///
//     // final result = await YourClassName.loadGame(
//     //   currentUserId!,
//     //   widget.roomId,
//     //   code,
//     //   gameId,
//     //   language,
//     //   viewSize,
//     //   gameConfig,
//     // );

//   Future<Map> initGameSDK() async {
//     return await SudMGPPlugin.initSDK(MG_APPID, MG_APPKEY, MG_APP_IS_TEST_ENV);
//   }

//   void loadGame() {
//     postRequest(MG_NAME_LOGIN_AUTH_URL, '/login/v3', {
//       'user_id': widget.senderid,
//       'app_id': MG_APPID,
//     }).then(
//       (rsp) => setState(() async {
//         if (rsp['ret_code'] == 0) {
//           _authcode = rsp['data']['code'];

//           print("sud get code finished code:$_authcode");
//           var ret = await initGameSDK();
//           print("sud init sdk finished:$ret");
//           var errorCode = ret['errorCode'];
//           if (errorCode != 0) {
//             print("init sdk error:$ret");
//             return;
//           }
//           if (TargetPlatform.android == defaultTargetPlatform) {
//             loadAndroidGame();
//           } else if (TargetPlatform.iOS == defaultTargetPlatform) {
//             loadIOSGame();
//           }
//         }
//       }),
//     );
//   }

//   void loadIOSGame() {
//     print("Start Load Game");
//     SudMGPPlugin.loadGame(
//      widget.senderid.toString(),
//       widget.liveID,
//       _authcode,
//       1461227817776713818,
//       "en-US",
//       getGameViewSize(),
//       getGameConfig(),
//     ).then((ret) {
//       setState(() => {});
//     });
//   }

//   void loadAndroidGame() {
//     print("loadAndroidGame:$_authcode");
//     SudMGPPlugin.loadGame(
//        widget.senderid.toString(),
//       widget.liveID,
//       _authcode,
//       1461227817776713818,
//       "en-US",
//       getGameViewSize(),
//       getGameConfig(),
//     ).then((ret) {
//       setState(() {
//         // print("loadAndroidGame finished");
//         // _gameView = getPlatformView('SudMGPPluginView', (int viewid) => {});
//       });
//     });
//   }

//   void destroyGame() {
//     // if (TargetPlatform.android == defaultTargetPlatform) {
//     //   setState(() {
//     //     _gameView = null;
//     //   });
//     // }

//     SudMGPPlugin.destroyGame();
//   }

//   void onGameEvent(Map map) {
//     String method = map['method'];
//     print("flutter game event:$method");
//     switch (method) {
//       case 'onGameStarted':
//         setState(() {});
//         break;
//       case 'onGameDestroyed':
//         break;
//       case 'onGameStateChange':
//         String? state = map['state'];
//         String? dataJson = map['dataJson'];
//         print('onGameStateChange state:$state dataJson:$dataJson');
//         break;
//       case 'onGetGameCfg':
//         break;
//       case 'onPlayerStateChange':
//         String? state = map['state'];
//         String? dataJson = map['dataJson'];
//         print('onPlayerStateChange state:$state dataJson:$dataJson');
//         break;
//       case 'onExpireCode':
//         break;
//       default:
//     }
//   }

//   String getGameViewSize() {
//     final double scale = widgetsBinding.window.devicePixelRatio;
//     final screenWidth =
//         MediaQuery.of(context).size.width *
//         widgetsBinding.window.devicePixelRatio;
//     final screenHeight =
//         MediaQuery.of(context).size.height *
//         widgetsBinding.window.devicePixelRatio *
//         1.0;

//     final top = scale * 100; // margin
//     final bottom = scale * 200; // margin
//     return json.encode({
//       "view_size": {"width": screenWidth, "height": screenHeight},
//       "view_game_rect": {"left": 0, "top": top, "right": 0, "bottom": bottom},
//     });
//   }

//   String getGameConfig() {
//     return json.encode({});
//   }

//   @override
//   Widget build(BuildContext context) {
//     final buttonStyle = ElevatedButton.styleFrom(
//       fixedSize: const Size(150, 60),
//       backgroundColor: Color.fromARGB(255, 17, 122, 111).withOpacity(0.6),
//     );

//     return Scaffold(
//       body: Stack(
//         children: [
//           // Game View Container
//           Container(
//             color: Colors.blue, // Background color for gameView
//             child: Center(child: _gameView),
//           ),
//           // Operation Page Container
//           Align(
//             alignment: Alignment.bottomCenter,
//             child: Container(
//               color: const Color(
//                 0x00000000,
//               ), // Background color for the operation container
//               padding: EdgeInsets.all(16.0),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   SizedBox(height: 20), // Space above the buttons
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       ElevatedButton(
//                         onPressed: () {
//                           // Load Game action
//                           print('Load Game');
//                           loadGame();
//                         },
//                         child: Text('Load Game'),
//                       ),
//                       SizedBox(width: 20), // Space between the buttons
//                       ElevatedButton(
//                         onPressed: () {
//                           // Destroy Game action
//                           destroyGame();
//                           print('Destroy Game');
//                         },
//                         child: Text('Destroy Game'),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 20), // Space below the buttons
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
