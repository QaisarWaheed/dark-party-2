import 'dart:async';
import 'package:flutter/services.dart';

class SudMGPPlugin {
  static var shared = SudMGPPlugin();
  static const MethodChannel _methodChannel = MethodChannel('SudMGPPlugin');
  static const EventChannel _eventChannel = EventChannel('SudMGPPluginEvent');
  static StreamSubscription<dynamic>? streamSubscription;

  static void Function(Map map)? onEvent;
  static void registerEventHandler(Function(Map map) eventHandle) async {
    onEvent = eventHandle;
    streamSubscription = _eventChannel.receiveBroadcastStream().listen(eventListener);
  }

  static void eventListener(dynamic data) {
    print("flutter eventListener event begin");
    var map = Map.from(data);
    String method = map['method'];
    print("flutter eventListener event:$method");
    onEvent!(map);
  }

  static Future<Map> getVersion() async {
    return await _methodChannel.invokeMethod("getVersion", {});
  }

  static Future<Map> initSDK(String appid, String appkey, bool isTestEnv) async {
    return await _methodChannel.invokeMethod("initSDK", {"appid": appid, "appkey": appkey, "isTestEnv": isTestEnv});
  }

  static Future<Map> getGameList() async {
    return await _methodChannel.invokeMethod("getGameList", {});
  }

  static Future<Map> loadGame(String userid, String roomid, String code, int gameid, String language, String viewSize, String gameConfig) async {
    return await _methodChannel.invokeMethod("loadGame", {
      "userid": userid,
      "roomid": roomid,
      "code": code,
      "gameid": gameid,
      "language": language,
      "viewSize": viewSize,
      "gameConfig": gameConfig,
    });
  }

  static Future<Map> pauseMG() async {
    return await _methodChannel.invokeMethod("pauseMG", {});
  }

  static Future<Map> playMG() async {
    return await _methodChannel.invokeMethod("playMG", {});
  }

  static Future<Map> updateCode(String code) async {
    return await _methodChannel.invokeMethod("updateCode", {"code": code});
  }

  static Future<Map> destroyGame() async {
    return await _methodChannel.invokeMethod("destroyGame", {});
  }

  static Future<Map> notifyStateChange(String state, String dataJson) async {
    return await _methodChannel.invokeMethod("notifyStateChange", {
      "state": state,
      "dataJson": dataJson,
    });
  }

  // 发送音频流数据
  static Future<Map> pushAudio(Uint8List byteArray) async {
    return await _methodChannel.invokeMethod("pushAudio", byteArray);
  }
}
