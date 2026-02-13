# API Documentation - Shaheen Star App

## Overview
Yeh document app mein use hone wale sabhi APIs ka detailed description provide karta hai.

## API Structure

### Base Configuration
- **Base URL**: `https://shaheenstar.online/`
- **Authorization**: Bearer Token (`mySuperSecretStaticToken123`)
- **Default Timeout**: 30 seconds
- **Max Retries**: 3 attempts

---

## API Categories

### 1. Authentication APIs

#### `googleSignup`
- **Endpoint**: `register.php`
- **Method**: POST (Multipart)
- **Purpose**: Google account se user registration
- **Parameters**:
  - `google_id`: Google user ID
  - `username`: User ka username
  - `email`: User ka email
  - `name`: User ka name (optional)
  - `firebaseToken`: Firebase authentication token
- **Returns**: `UserSignUpModel` with user data and token

#### `googleLogin`
- **Endpoint**: `login.php`
- **Method**: POST (Multipart)
- **Purpose**: Google account se login
- **Parameters**:
  - `google_id`: Google user ID
- **Returns**: `UserSignUpModel` with user data, token, and agency_info

---

### 2. Room Management APIs

#### `createRoom`
- **Endpoint**: `create_room.php`
- **Method**: POST
- **Purpose**: Naya room create karna
- **Parameters**:
  - `name`: Room ka name
  - `topic`: Room ka topic
  - `userId`: Creator ka user ID
  - `isPrivate`: Private (0) ya Public (1)
- **Returns**: Room creation response

#### `joinRoom`
- **Endpoint**: `join_room.php`
- **Method**: POST
- **Purpose**: Room mein join karna
- **Parameters**:
  - `user_id`: User ka ID
  - `room_id`: Room ka ID
  - `password`: Room password (if private)
  - `is_private`: Private room flag
- **Returns**: Join room response

#### `leaveRoom`
- **Endpoint**: `Leave_Room_API.php`
- **Method**: POST
- **Purpose**: Room se leave karna
- **Parameters**:
  - `user_id`: User ka ID
  - `roomc_id`: Room ka ID
- **Returns**: `LeaveRoomModel`

#### `getRoomMessages`
- **Endpoint**: `Get_Room_Messages_API.php`
- **Method**: POST
- **Purpose**: Room ki messages fetch karna
- **Parameters**:
  - `room_id`: Room ka ID
- **Returns**: Messages list

#### `sendMessage`
- **Endpoint**: `Send_Message_API.php`
- **Method**: POST (JSON)
- **Purpose**: Room mein message send karna
- **Parameters**:
  - `user_id`: Sender ka ID
  - `room_id`: Room ka ID
  - `message`: Message text
- **Returns**: `SendMessageRoomModel`

#### `checkUserRoom`
- **Endpoint**: `check_user_room.php`
- **Method**: POST
- **Purpose**: Check karna ki user kisi room mein hai ya nahi
- **Parameters**:
  - `user_id`: User ka ID
- **Returns**: Current room information

---

### 3. Room Seats Management APIs

#### `getSeats`
- **Endpoint**: `Room_Seats_Management_API.php`
- **Method**: POST
- **Purpose**: Room ki seats fetch karna
- **Parameters**:
  - `action`: `get_seats`
  - `room_id`: Room ka ID
- **Returns**: Seats list with occupancy status

#### `initializeSeats`
- **Endpoint**: `Room_Seats_Management_API.php`
- **Method**: POST
- **Purpose**: Room ki seats initialize karna
- **Parameters**:
  - `action`: `initialize`
  - `room_id`: Room ka ID
- **Returns**: Initialization response

#### `occupySeat`
- **Endpoint**: `Room_Seats_Management_API.php`
- **Method**: POST
- **Purpose**: Seat occupy karna
- **Parameters**:
  - `action`: `occupy`
  - `room_id`: Room ka ID
  - `user_id`: User ka ID
  - `seat_number`: Seat number
- **Returns**: Occupancy response

#### `vacateSeat`
- **Endpoint**: `Room_Seats_Management_API.php`
- **Method**: POST
- **Purpose**: Seat se vacate karna
- **Parameters**:
  - `action`: `vacate`
  - `room_id`: Room ka ID
  - `user_id`: User ka ID
- **Returns**: Vacate response

---

### 4. Room Statistics APIs

#### `fetchTotalCoins`
- **Endpoint**: `room_user_interaction_stats_api.php`
- **Method**: GET
- **Purpose**: Room mein total coins sent fetch karna
- **Parameters**:
  - `room_id`: Room ka ID
  - `sort_by`: `total_sent_value`
- **Returns**: Room summary with total_sent_value
- **Response Structure**:
  ```json
  {
    "status": "success",
    "data": {
      "room_summary": {
        "total_sent_value": 12345.67
      }
    }
  }
  ```

#### `fetchRoomStats`
- **Endpoint**: `gift_102.php`
- **Method**: GET
- **Purpose**: Room ki detailed statistics fetch karna
- **Parameters**:
  - `page`: Page number
  - `limit`: Items per page
  - `room_id`: Room ka ID (optional)
  - `sender_id`: Sender ka ID (optional)
  - `receiver_id`: Receiver ka ID (optional)
  - `gift_id`: Gift ka ID (optional)
  - `sort_by`: Sort field
  - `sort_order`: ASC/DESC
- **Returns**: `RoomGiftResponse`

---

### 5. Coins & Balance APIs

#### `getUserCoinsBalance`
- **Endpoint**: `User_Coins_Balance_API.php`
- **Method**: POST (Multipart)
- **Purpose**: User ki coins balance fetch karna
- **Parameters**:
  - `user_id`: User ka ID
- **Returns**: `UserBalanceResponse` with gold_coins and diamond_coins

#### `transferCoinsMerchantToUser`
- **Endpoint**: `Merchant_Coins_Distribution_API.php`
- **Method**: POST (Multipart)
- **Purpose**: Merchant se user ko coins transfer karna
- **Parameters**:
  - `admin_id`: Merchant ka ID
  - `merchant_id`: Merchant ka ID
  - `user_id`: Receiver ka ID
  - `amount`: Transfer amount
  - `action_type`: `merchant_to_user`
- **Returns**: `CoinTransferResponse`

#### `transferCoinsUserToUser`
- **Endpoint**: `Seat-Based_Gifting_API.php`
- **Method**: POST (Multipart)
- **Purpose**: User se user ko coins transfer (gifting)
- **Parameters**:
  - `sender_id`: Sender ka ID
  - `receiver_id`: Receiver ka ID
  - `room_id`: Room ka ID (default: "0")
  - `gift_value`: Gift amount
- **Returns**: `CoinTransferResponse`

---

### 6. Gift APIs

#### `getGifts`
- **Endpoint**: `get_gifts.php`
- **Method**: POST
- **Purpose**: Available gifts list fetch karna
- **Returns**: `GiftResponse` with gifts list

#### `sendGift`
- **Endpoint**: `send_gift.php`
- **Method**: POST
- **Purpose**: Gift send karna
- **Parameters**:
  - `sender_id`: Sender ka ID
  - `receiver_id`: Receiver ka ID
  - `gift_id`: Gift ka ID
  - `quantity`: Gift quantity
  - `room_id`: Room ka ID
- **Returns**: `SendGiftResponse`

---

### 7. User Profile APIs

#### `updateProfile`
- **Endpoint**: `google_auth.php`
- **Method**: POST (Multipart)
- **Purpose**: User profile update karna
- **Parameters**:
  - `id`: User ka ID
  - `google_id`: Google ID (optional)
  - Profile fields (username, name, etc.)
- **Returns**: `UpdateProfileModel`

#### `getUserBanners`
- **Endpoint**: `get_user_banners.php?user_id={userId}`
- **Method**: GET
- **Purpose**: User ki banners fetch karna
- **Parameters**:
  - `user_id`: User ka ID (query parameter)
- **Returns**: `BannerModel`

---

### 8. Store & Backpack APIs

#### `getMallData`
- **Endpoint**: `mall_api.php`
- **Method**: GET
- **Purpose**: Mall items fetch karna
- **Returns**: `MallResponse`

#### `purchaseItem`
- **Endpoint**: `purchase_item.php`
- **Method**: POST
- **Purpose**: Item purchase karna
- **Parameters**:
  - `user_id`: User ka ID
  - `item_id`: Item ka ID
- **Returns**: `PurchaseResponse`

#### `getBackpack`
- **Endpoint**: `get_backpack.php`
- **Method**: POST
- **Purpose**: User ka backpack fetch karna
- **Parameters**:
  - `user_id`: User ka ID
- **Returns**: `BackpackResponse`

---

### 9. WebSocket Connections

#### Room WebSocket
- **URL**: `ws://shaheenstar.online:8083`
- **Purpose**: Room events (seats, messages, mic status)
- **Events**: `user:joined`, `user:left`, `seat:occupied`, `seat:vacated`, `message:new`, `mic:toggle`

#### Gifts WebSocket
- **URL**: `ws://shaheenstar.online:8085`
- **Purpose**: Gift operations
- **Events**: `gift:sent`, `gift:received`

-#### User Chat WebSocket
- **URL**: `ws://shaheenstar.online:8089`
- **Purpose**: User-to-user chat
- **Events**: `chat:new`, `chat:read`

---

## API Best Practices Implementation

### 1. Centralized API Service (`ApiService`)
- ✅ Consistent error handling
- ✅ Retry logic (3 attempts)
- ✅ Timeout handling (30 seconds)
- ✅ Response parsing utilities
- ✅ Logging and debugging

### 2. Error Handling
- ✅ All APIs return `ApiResponse<T>` wrapper
- ✅ Consistent error messages
- ✅ Proper exception handling
- ✅ Network error detection

### 3. Response Parsing
- ✅ HTML comment removal
- ✅ JSON extraction from mixed responses
- ✅ Type-safe parsing
- ✅ Null safety

### 4. Code Organization
- ✅ API constants centralized (`ApiConstants`)
- ✅ API methods in `ApiManager`
- ✅ Service layer separation (`ApiService`)
- ✅ Clear documentation

---

## Usage Examples

### Fetch Total Coins (Room Screen)
```dart
final response = await ApiManager.fetchTotalCoins(roomId: widget.roomId);
if (response != null && response['status'] == 'success') {
  final totalCoins = response['data']['room_summary']['total_sent_value'];
}
```

### Send Message
```dart
final messageModel = await ApiManager.sendMessage(
  userId: userId,
  roomId: roomId,
  message: messageText,
);
```

### Get User Balance
```dart
final balance = await ApiManager.getUserCoinsBalance(userId: userId);
if (balance != null) {
  final goldCoins = balance.data?.goldCoins ?? 0.0;
  final diamondCoins = balance.data?.diamondCoins ?? 0.0;
}
```

---

## Notes

1. **Hardcoded Values**: Some APIs still have hardcoded cookies/PHPSESSID - yeh production mein environment variables se manage karna chahiye.

2. **Error Messages**: Sabhi APIs consistent error messages return karti hain with `status` and `message` fields.

3. **Response Format**: Most APIs return:
   ```json
   {
     "status": "success" | "error",
     "message": "Optional message",
     "data": { ... }
   }
   ```

4. **WebSocket Events**: Real-time updates WebSocket se aate hain, REST APIs mostly initial data fetch ke liye use hoti hain.

5. **Retry Logic**: Network failures par automatically 3 attempts hoti hain with 2-second delay.

---

## Future Improvements

1. ✅ Environment-based configuration (dev/staging/prod)
2. ✅ Request/Response interceptors
3. ✅ Caching layer
4. ✅ Rate limiting
5. ✅ API versioning
6. ✅ Comprehensive unit tests
