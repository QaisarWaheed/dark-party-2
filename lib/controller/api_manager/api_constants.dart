import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static const String token = "bearermySuperSecretStaticToken123";
  static const String bearertoken = "mySuperSecretStaticToken123";

  static String _withTrailingSlash(String url) {
    if (url.endsWith('/')) return url;
    return '$url/';
  }

  static String _envOr(String key, String fallback) {
    return dotenv.env[key] ?? fallback;
  }

  static String get baseUrl =>
      _withTrailingSlash(_envOr('BASE_URL', 'https://shaheenstar.online/'));

  static String get createRoom => "${baseUrl}create_room.php";
  static String get login => "${baseUrl}login.php";
  static String get register => "${baseUrl}register.php";
  static String get getRooms => "${baseUrl}rooms";
  static String get getUserBanners => "${baseUrl}get_user_banners.php?user_id=";
  static String get getAllRooms => '${baseUrl}get_rooms.php';
  static String get singleUserupdate => '${baseUrl}google_auth.php';
  static String get logout => '${baseUrl}logout.php';

  // Merchant & Withdraw APIs
  static String get transactionHistory => '${baseUrl}TransactionHistoryApi.php';
  static String get merchantCoinsDistribution =>
      '${baseUrl}Merchant_Coins_Distribution_API.php';
  static String get userToUserGifting => '${baseUrl}Seat-Based_Gifting_API.php';
  static String get userCoinsBalance => '${baseUrl}User_Coins_Balance_API.php';
  // Note: Payout API might be part of TransactionHistoryApi or separate endpoint
  static String get getAllUsers => '${baseUrl}get_all_users.php';

  // Gift APIs
  static String get getGifts => '${baseUrl}get_gifts.php';
  static String get addGift => '${baseUrl}add_gift.php';
  static String get sendGift => '${baseUrl}send_gift.php';
  static String get giftTransactionsApi =>
      '${baseUrl}gift_transactions_report.php';
  static String get roomStatsApi =>
      '${baseUrl}room_user_interaction_stats_api.php';

  // Room Management APIs
  static String get joinRoomApi => '${baseUrl}join_room.php';
  static String get leaveRoomApi => '${baseUrl}Leave_Room_API.php';

  /// Zego voice token (for token auth – fixes 1001005 when Zego Console uses token auth)
  static String get getZegoTokenApi => '${baseUrl}get_zego_token.php';
  static String get getRoomMessagesApi => '${baseUrl}Get_Room_Messages_API.php';
  static String get sendMessageApi => '${baseUrl}Send_Message_API.php';
  static String get checkUserRoomApi => '${baseUrl}check_user_room.php';
  static String get updateRoomNameApi => '${baseUrl}update_room_name.php';
  static String get updateRoomProfileApi => '${baseUrl}update_room_profile.php';
  static String get roomSeatsManagementApi =>
      '${baseUrl}Room_Seats_Management_API.php';
  static String get fetchTotalCoinsApi =>
      '${baseUrl}room_user_interaction_stats_api.php';

  // Withdrawal System APIs
  static String get withdrawalSystem => '${baseUrl}withdrawal_system.php';
  // Transfer diamonds to merchant endpoint
  static String get transferDiamondToMerchant =>
      '${baseUrl}transfer_diamond_to_merchant.php';
  // Exchange diamonds to gold endpoint
  static String get exchangeDiamondToGold =>
      '${baseUrl}exchange_diamond_to_gold.php';

  // Level APIs
  static String get levelApi => '${baseUrl}level.php';
  // Lucky gift spinner API
  static String get luckyGiftApi => '${baseUrl}lucky_gift_api.php';

  // Agency APIs
  static String get getAllAgenciesApi => '${baseUrl}get_all_agencies.php';
  static String get agencyManagerApi => '${baseUrl}agency_manager.php';
  static String get agencyRequestsApi => '${baseUrl}agency_requests_api.php';

  // Store APIs
  static String get mallApi => '${baseUrl}mall_api.php';
  static String get purchaseItemApi => '${baseUrl}purchase_item.php';
  static String get getBackpackApi => '${baseUrl}get_backpack.php';
  static String get getBackpackResponseApi =>
      '${baseUrl}api/get_user_selected_backpack_item.php?user_id=1928307';

  // User Tags API
  static String get getUserTagsApi => '${baseUrl}get_user_tags.php';

  // User messages (coin transactions, admin messages e.g. welcome 5000 coins)
  static String get getUserMessagesApi => '${baseUrl}get_user_messages.php';

  // User Chat HTTP endpoints
  static String get sendChatMessageUrl => '${baseUrl}send_chat_message.php';
  static String get getChatUserStatusUrl =>
      '${baseUrl}get_chat_user_status.php';
  static String get getConversationsUrl => '${baseUrl}get_conversations.php';
  static String get getConversationMessagesUrl =>
      '${baseUrl}get_conversation_messages.php';
  static String get markAsReadUrl => '${baseUrl}mark_as_read.php';
  static String get blockUnblockUserUrl => '${baseUrl}block_unblock_user.php';

  // BAISHUN / Game integration endpoints (server-side PHP demo)
  static String get requestGameCode => '${baseUrl}request_game_code.php';
  static String get getUserInfoApi => '${baseUrl}get_user_info.php';
  static String get changeBalanceApi => '${baseUrl}change_balance.php';
  static String get getSstokenApi => '${baseUrl}get_sstoken.php';
  static String get generateSstokenApi => '${baseUrl}generate_sstoken.php';
  // Game list / info endpoints (BAISHUN)
  // Prefer backend-provided game list (BAISHUN). Point to BAISHUN test gamelist endpoint.
  static const String gameListApi =
      'https://game-cn-test.jieyou.shop/v1/api/gamelist';
  static const String oneGameInfoApi =
      'https://game-cn-test.jieyou.shop/v1/api/one_game_info';

  // BAISHUN app credentials (set correct values for production)
  // NOTE: Replace baishunAppKey with the real secret provided by BAISHUN.
  // Set to backend-provided BAISHUN App ID
  static const String baishunAppId = '5864440123';
  // WARNING: This key is sensitive. Keep it local and do NOT commit to version control.
  static const String baishunAppKey = 'VV7RlosNTR6xCMYmfbmSF0ilqHwYktSl';
  static const String baishunAppChannel = 'shaheen';

  // SUD (Short Video Game SDK) endpoints (game callbacks)
  // Prefer top-level endpoints as provided by backend
  static String get sudGetSstoken => '${baseUrl}get_sstoken.php';
  static String get sudUpdateSstoken => '${baseUrl}update_sstoken.php';
  static String get sudGetUserInfo => '${baseUrl}get_user_info.php';
  static String get sudReportGameInfo => '${baseUrl}report_game_info.php';
  static String get sudGetAccount => '${baseUrl}get_account.php';
  static String get sudGetScore => '${baseUrl}get_score.php';
  static String get sudUpdateScore => '${baseUrl}update_score.php';
  static String get sudGenerateSstoken => '${baseUrl}generate_sstoken.php';
  // Disable automatic local fallback when true. Set to false for production.
  static const bool enableLocalFallback = false;

  // WebSocket URLs
  // Room WebSocket Server - Port 8083 (for rooms, seats, messages, mic status)
  static String get webSocketUrl =>
      _envOr('WS_ROOM_URL', 'ws://shaheenstar.online:8083');
  // Gifts WebSocket Server - Port 8085 (for gift operations only)
  static String get giftsWebSocketUrl =>
      _envOr('WS_GIFTS_URL', 'ws://shaheenstar.online:8085');
  // User Chat WebSocket Server - Port 8089 (for user chat operations)
  static String get userChatWebSocketUrl =>
      _envOr('WS_CHAT_URL', 'ws://shaheenstar.online:8089');
  // Agency Management WebSocket Server - Port 8043 (for agency operations)
  static String get agencyWebSocketUrl =>
      _envOr('WS_AGENCY_URL', 'ws://shaheenstar.online:8043');
  static String get postWebSocketUrl =>
      _envOr('WS_POST_URL', 'ws://shaheenstar.online:8079');

  //ban admin user api
  static String get banAdminUserApi => '${baseUrl}games.php/ban_user.php';

  //..........................Invite Code Api.............................//
  //............baseurl invitecode
  static String get baseUrlInvite => "${baseUrl}api/invite_api.php";

  //GENERATE INVITE CODE
  static String get generateInviteCodeApi =>
      '${baseUrlInvite}?action=generate_code';
  //USE INVITE CODE (Add 3000 Coins)
  static String get useInviteCodeApi => '${baseUrlInvite}?action=use_invite';
  //GET USER STATS
  static String get getUserInviteStatsApi =>
      '${baseUrlInvite}?action=get_user_stats&user_id=123';
  //GET INVITE HISTORY
  static String get getInviteHistoryApi =>
      '${baseUrlInvite}?action=get_invite_history&user_id=123';

  //..........................USER ID+BAN UserAPI.............................//

  //User Unique ID API
  static String get userUniqueIdApi => '${baseUrl}user_unique_id.php';
  //Ban User API
  static String get banUserApi => '${baseUrl}ban_user.php';
}
