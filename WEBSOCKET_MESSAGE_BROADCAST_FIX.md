# WebSocket Message Broadcasting Fix

## Problem
Messages were not being broadcast to other users because the backend wasn't tracking users when they connected via WebSocket URL parameters.

**Backend logs showed:**
```
📡 Broadcasted message to 0 users in room 68
```

## Root Cause
The backend's `onOpen()` method was not extracting URL parameters (`room_id`, `user_id`, `username`, `profile_url`) and registering users in `$this->userConnections`. This meant `broadcastToRoom()` found 0 users.

## Solution

### Backend Fix Required
The backend developer needs to update the `onOpen()` method to:
1. Extract URL parameters from the WebSocket connection
2. Register users immediately in `$this->userConnections`
3. Initialize room seats if needed

**Updated `onOpen()` method:**
```php
public function onOpen(ConnectionInterface $conn) {
    $this->clients->attach($conn);
    $connId = $this->getConnectionId($conn);
    
    // ✅ EXTRACT URL PARAMETERS
    $queryParams = [];
    if ($conn->httpRequest) {
        parse_str($conn->httpRequest->getUri()->getQuery(), $queryParams);
    }
    
    $roomId = isset($queryParams['room_id']) ? (int)$queryParams['room_id'] : null;
    $userId = isset($queryParams['user_id']) ? (int)$queryParams['user_id'] : null;
    $username = $queryParams['username'] ?? null;
    $profileUrl = $queryParams['profile_url'] ?? null;
    
    echo "🔗 New connection: {$connId}\n";
    echo "📋 URL Params - Room: $roomId, User: $userId, Username: $username\n";
    
    // ✅ REGISTER USER IMMEDIATELY IF PARAMETERS PROVIDED
    if ($roomId && $userId) {
        // Get REAL user info from database
        $userInfo = $this->getUserInfo($userId);
        
        if ($userInfo) {
            // Store user connection info
            $this->userConnections[$connId] = [
                'room_id' => $roomId,
                'user_id' => $userId,
                'username' => $userInfo['username'],
                'name' => $userInfo['name'],
                'profile_url' => $userInfo['profile_url'],
                'connection' => $conn
            ];
            
            // Initialize room seats if needed
            if (!isset($this->roomSeats[$roomId])) {
                $this->initializeRoomSeats($roomId);
            }
            
            echo "✅ User {$userInfo['username']} ($userId) registered in room $roomId\n";
            echo "📊 Total users in room $roomId: " . $this->countUsersInRoom($roomId) . "\n";
        } else {
            echo "❌ User $userId not found in database\n";
        }
    } else {
        echo "⚠️ Connection without room_id/user_id - user will need to send join_room action\n";
    }
}

// ✅ Helper method to count users in a room
private function countUsersInRoom($roomId) {
    $count = 0;
    foreach ($this->userConnections as $userInfo) {
        if ($userInfo['room_id'] == $roomId) {
            $count++;
        }
    }
    return $count;
}
```

### Frontend Status
✅ **Frontend is already correctly configured:**
- Passes `room_id`, `user_id`, `username`, and `profile_url` in WebSocket URL
- Sends `join_room` action as fallback after connection
- Listens for `message` events properly

## Testing Guide

### Step 1: Check Frontend Connection
When a user joins a room, the frontend should connect with URL parameters:

**Expected Frontend Logs:**
```
📡 [SeatProvider] WebSocket connection params:
   - Room ID: 68
   - User ID: 00100423
   - Username: khan
   - Profile URL: https://shaheenstar.online/uploads/profiles/profile_100423_1765027247.jpg

📡 [WebSocketService] Query Parameters: {room_id: 68, user_id: 00100423, username: khan, profile_url: https://shaheenstar.online/uploads/profiles/profile_100423_1765027247.jpg}
```

**Actual WebSocket URL:**
```
ws://shaheenstar.online:8083?room_id=68&user_id=00100423&username=khan&profile_url=https://shaheenstar.online/uploads/profiles/profile_100423_1765027247.jpg
```

### Step 2: Check Backend Registration
After the backend fix, you should see:

**Expected Backend Logs:**
```
🔗 New connection: 000000003c983a47000000001f2f09c2
📋 URL Params - Room: 68, User: 100423, Username: khan
🔍 Attempting to register user from URL params...
✅ Found user in DB: ID=100423, Username=khan
✅ User khan (100423) registered in room 68
📊 Total users in room 68: 1
```

### Step 3: Test Message Broadcasting
When User A sends a message, both users should receive it:

**User A sends message:**
```
📤 [WebSocketService] Sending: {"action":"send_message","room_id":68,"user_id":100423,"message":"hello"}
```

**Expected Backend Logs:**
```
📨 Action: send_message, Room: 68, User: 100423
💬 Handling send message
✅ Found user in DB: ID=100423, Username=khan
💾 Message saved to database with ID: 625
📡 Attempting to broadcast message to room 68
📊 Users currently registered in room 68:
   👤 khan (ID: 100423, Conn: 000000003c983a47000000001f2f09c2)
   👤 testuser (ID: 100252, Conn: 00000000abc123def456789)
📤 Broadcasting message to 2 users
   ✅ Sent to khan (000000003c983a47000000001f2f09c2)
   ✅ Sent to testuser (00000000abc123def456789)
📡 Broadcasted message to 2 users in room 68
```

**Expected Frontend Logs (User B receiving):**
```
💬 [SeatProvider] ===== ROOM MESSAGE EVENT RECEIVED =====
💬 [SeatProvider] Event: message
💬 [SeatProvider] Data keys: [message_id, room_id, user_id, username, user_name, message, message_text, profile_url, timestamp, created_at]
💬 [SeatProvider] Message: hello
💬 [SeatProvider] User ID: 100423
💬 [SeatProvider] Username: khan
✅ [SeatProvider] onMessageReceived callback executed
```

## Verification Checklist

- [ ] Backend `onOpen()` extracts URL parameters
- [ ] Backend registers users in `$this->userConnections` on connection
- [ ] Backend logs show user registration: `✅ User X registered in room Y`
- [ ] Backend logs show user count: `📊 Total users in room X: N`
- [ ] When sending message, backend shows: `📡 Broadcasted message to N users` (N > 0)
- [ ] Other users receive messages via `message` event
- [ ] Messages show real usernames (not "User 100423")

## Troubleshooting

### If backend still shows "0 users":
1. Check if `onOpen()` is extracting URL parameters correctly
2. Verify `$this->userConnections` is being populated
3. Check if `broadcastToRoom()` is checking the correct room_id
4. Ensure users are connecting with URL parameters (not just sending `join_room` action)

### If messages aren't received:
1. Check frontend logs for `💬 [SeatProvider] ===== ROOM MESSAGE EVENT RECEIVED =====`
2. Verify `onMessageReceived` callback is set in `RoomScreen`
3. Check if message event name matches (`message`, `room_message`, etc.)
4. Verify room filtering isn't blocking messages

### If usernames show as "User 100423":
1. Backend should use `getUserInfo()` to fetch real username from database
2. Check database query in `getUserInfo()` method
3. Verify `users` table has correct `username` or `name` field

## Success Criteria

✅ **Backend logs show:**
- User registration on connection
- User count > 0 when broadcasting
- Messages broadcasted to correct number of users

✅ **Frontend logs show:**
- Connection with URL parameters
- Message events received
- Real usernames displayed

✅ **User experience:**
- Messages appear for all users in room
- Real usernames shown (not "User X")
- Profile images displayed correctly
- Messages appear in real-time

