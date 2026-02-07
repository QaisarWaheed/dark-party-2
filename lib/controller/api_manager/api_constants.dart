class ApiConstants {
  static const String token = "bearermySuperSecretStaticToken123";
  static const String bearertoken = "mySuperSecretStaticToken123";
  static const String baseUrl = "https://shaheenstar.online/";
  static const String createRoom = "${baseUrl}create_room.php";
  static const String login = "${baseUrl}login.php";
  static const String register = "${baseUrl}register.php";
  static const String getRooms = "${baseUrl}rooms";
  static const String getUserBanners =
      "${baseUrl}get_user_banners.php?user_id=";
  static const String getAllRooms = '${baseUrl}get_rooms.php';
  static const String singleUserupdate = '${baseUrl}google_auth.php';
  static const String logout = '${baseUrl}logout.php';

  // Merchant & Withdraw APIs
  static const String transactionHistory =
      '${baseUrl}TransactionHistoryApi.php';
  static const String merchantCoinsDistribution =
      '${baseUrl}Merchant_Coins_Distribution_API.php';
  static const String userToUserGifting =
      '${baseUrl}Seat-Based_Gifting_API.php';
  static const String userCoinsBalance = '${baseUrl}User_Coins_Balance_API.php';
  // Note: Payout API might be part of TransactionHistoryApi or separate endpoint
  static const String getAllUsers =
      '${baseUrl}get_all_users.php'; // ✅ Get all users endpoint

  // Gift APIs
  static const String getGifts = '${baseUrl}get_gifts.php';
  static const String addGift = '${baseUrl}add_gift.php';
  static const String sendGift = '${baseUrl}send_gift.php';
  static const String giftTransactionsApi =
      'https://shaheenstar.online/gift_transactions_report.php';
  static const String roomStatsApi = '${baseUrl}room_user_interaction_stats_api.php';
  
  // Room Management APIs
  static const String joinRoomApi = '${baseUrl}join_room.php';
  static const String leaveRoomApi = '${baseUrl}Leave_Room_API.php';
  /// Zego voice token (for token auth – fixes 1001005 when Zego Console uses token auth)
  static const String getZegoTokenApi = '${baseUrl}get_zego_token.php';
  static const String getRoomMessagesApi = '${baseUrl}Get_Room_Messages_API.php';
  static const String sendMessageApi = '${baseUrl}Send_Message_API.php';
  static const String checkUserRoomApi = '${baseUrl}check_user_room.php';
  static const String updateRoomNameApi = '${baseUrl}update_room_name.php';
  static const String updateRoomProfileApi = '${baseUrl}update_room_profile.php';
  static const String roomSeatsManagementApi = '${baseUrl}Room_Seats_Management_API.php';
  static const String fetchTotalCoinsApi = '${baseUrl}room_user_interaction_stats_api.php';

  // Withdrawal System APIs
  static const String withdrawalSystem = '${baseUrl}withdrawal_system.php';
    // Transfer diamonds to merchant endpoint
    static const String transferDiamondToMerchant = '${baseUrl}transfer_diamond_to_merchant.php';
    // Exchange diamonds to gold endpoint
    static const String exchangeDiamondToGold = '${baseUrl}exchange_diamond_to_gold.php';

  // Level APIs
  static const String levelApi = '${baseUrl}level.php';
    // Lucky gift spinner API
    static const String luckyGiftApi = '${baseUrl}lucky_gift_api.php';

  // Agency APIs
  static const String getAllAgenciesApi = '${baseUrl}get_all_agencies.php';
  static const String agencyManagerApi = '${baseUrl}agency_manager.php';
  static const String agencyRequestsApi = '${baseUrl}agency_requests_api.php';

  // Store APIs
  static const String mallApi = '${baseUrl}mall_api.php';
  static const String purchaseItemApi = '${baseUrl}purchase_item.php';
  static const String getBackpackApi = '${baseUrl}get_backpack.php';
 static const String getBackpackResponseApi = 'https://shaheenstar.online/api/get_user_selected_backpack_item.php?user_id=1928307';

  // User Tags API
  static const String getUserTagsApi = '${baseUrl}get_user_tags.php';

  // User messages (coin transactions, admin messages e.g. welcome 5000 coins)
  static const String getUserMessagesApi = '${baseUrl}get_user_messages.php';

    // User Chat HTTP endpoints
    static const String sendChatMessageUrl = '${baseUrl}send_chat_message.php';
    static const String getChatUserStatusUrl = '${baseUrl}get_chat_user_status.php';
    static const String getConversationsUrl = '${baseUrl}get_conversations.php';
    static const String getConversationMessagesUrl = '${baseUrl}get_conversation_messages.php';
    static const String markAsReadUrl = '${baseUrl}mark_as_read.php';
    static const String blockUnblockUserUrl = '${baseUrl}block_unblock_user.php';

    // BAISHUN / Game integration endpoints (server-side PHP demo)
    static const String requestGameCode = '${baseUrl}request_game_code.php';
    static const String getUserInfoApi = '${baseUrl}get_user_info.php';
    static const String changeBalanceApi = '${baseUrl}change_balance.php';
    static const String getSstokenApi = '${baseUrl}get_sstoken.php';
    static const String generateSstokenApi = '${baseUrl}generate_sstoken.php';
    // Game list / info endpoints (BAISHUN)
    // Prefer backend-provided game list (BAISHUN). Point to BAISHUN test gamelist endpoint.
    static const String gameListApi = 'https://game-cn-test.jieyou.shop/v1/api/gamelist';
    static const String oneGameInfoApi = 'https://game-cn-test.jieyou.shop/v1/api/one_game_info';

    // BAISHUN app credentials (set correct values for production)
    // NOTE: Replace baishunAppKey with the real secret provided by BAISHUN.
    // Set to backend-provided BAISHUN App ID
    static const String baishunAppId = '5864440123';
    // WARNING: This key is sensitive. Keep it local and do NOT commit to version control.
    static const String baishunAppKey = 'VV7RlosNTR6xCMYmfbmSF0ilqHwYktSl';
    static const String baishunAppChannel = 'shaheen';

    // SUD (Short Video Game SDK) endpoints (game callbacks)
    // Prefer top-level endpoints as provided by backend
    static const String sudGetSstoken = '${baseUrl}get_sstoken.php';
    static const String sudUpdateSstoken = '${baseUrl}update_sstoken.php';
    static const String sudGetUserInfo = '${baseUrl}get_user_info.php';
    static const String sudReportGameInfo = '${baseUrl}report_game_info.php';
    static const String sudGetAccount = '${baseUrl}get_account.php';
    static const String sudGetScore = '${baseUrl}get_score.php';
    static const String sudUpdateScore = '${baseUrl}update_score.php';
    static const String sudGenerateSstoken = '${baseUrl}generate_sstoken.php';
        // Disable automatic local fallback when true. Set to false for production.
        static const bool enableLocalFallback = false;

  // WebSocket URLs
  // Room WebSocket Server - Port 8083 (for rooms, seats, messages, mic status)
  static const String webSocketUrl = "ws://shaheenstar.online:8083";
  // Gifts WebSocket Server - Port 8085 (for gift operations only)
  static const String giftsWebSocketUrl = "ws://shaheenstar.online:8085";
    // User Chat WebSocket Server - Port 8089 (for user chat operations)
    static const String userChatWebSocketUrl = "ws://shaheenstar.online:8089";
  // Agency Management WebSocket Server - Port 8043 (for agency operations)
  static const String agencyWebSocketUrl = "ws://shaheenstar.online:8043";
    static const String postWebSocketUrl = "ws://shaheenstar.online:8079";

  //ban admin user api
  static const String banAdminUserApi = '${baseUrl}games.php/ban_user.php';

  //..........................Invite Code Api.............................//
  //............baseurl invitecode
  static const String baseUrlInvite = "${baseUrl}api/invite_api.php";

  //GENERATE INVITE CODE
  static const String generateInviteCodeApi =
      '$baseUrlInvite?action=generate_code';
  //USE INVITE CODE (Add 3000 Coins)
  static const String useInviteCodeApi = '$baseUrlInvite?action=use_invite';
  //GET USER STATS
  static const String getUserInviteStatsApi =
      '$baseUrlInvite?action=get_user_stats&user_id=123';
  //GET INVITE HISTORY
  static const String getInviteHistoryApi =
      '$baseUrlInvite?action=get_invite_history&user_id=123';

  //..........................USER ID+BAN UserAPI.............................//

  //User Unique ID API
  static const String userUniqueIdApi = '${baseUrl}user_unique_id.php';
  //Ban User API
  static const String banUserApi = '${baseUrl}ban_user.php';
}
