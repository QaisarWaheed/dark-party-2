# 🪑 Seats Not Loading - User ID Format Issue

## 🔍 Analysis: Is This Due to User ID?

**YES - This is likely a user_id format mismatch issue!**

---

## 📋 Current Behavior

### What Flutter Sends:
From your logs:
```
✅ [SeatProvider] Converted user_id to integer: 00100621 -> 100621
📤 [SeatProvider] Room ID: 73, User ID: 100621
```

**Flutter sends:** `{"action": "get_seats", "room_id": 73, "user_id": 100621}`

### What Backend Might Expect:
The backend might expect:
- **Option 1:** `user_id` as **string with leading zeros**: `"00100621"`
- **Option 2:** `user_id` as **integer without zeros**: `100621` (current)
- **Option 3:** `user_id` in the **same format as WebSocket connection**: `"00100621"`

---

## ⚠️ THE PROBLEM

**Inconsistency:**
- **WebSocket connection uses:** `user_id: "00100621"` (8-digit string with leading zeros)
- **get_seats request uses:** `user_id: 100621` (integer without leading zeros)

**Backend might be:**
1. ✅ Accepting WebSocket connection with `"00100621"`
2. ❌ Rejecting `get_seats` request with `100621` (format mismatch)
3. ❌ Not finding user in room because user_id format doesn't match

---

## ✅ SOLUTION: Try Sending User ID as String

### Option 1: Send User ID as String (Recommended)

**File:** `lib/controller/provider/seat_provider.dart`

**Current Code (Line 726-729):**
```dart
final sent = _wsService.sendAction('get_seats', {
  'room_id': roomIdInt,
  'user_id': userIdInt,  // ❌ Sending as integer
});
```

**Change To:**
```dart
final sent = _wsService.sendAction('get_seats', {
  'room_id': roomIdInt,
  'user_id': currentUserId,  // ✅ Send as string with leading zeros
});
```

**Why:** This matches the format used in WebSocket connection URL (`user_id=00100621`).

---

### Option 2: Keep Integer but Verify Backend Expects It

If backend truly expects integer, verify:
1. Backend receives `get_seats` request
2. Backend processes `user_id: 100621` correctly
3. Backend sends `seats:update` response

---

## 🧪 Testing

### Test 1: Check Backend Logs
1. Check backend logs when `get_seats` is received
2. Verify what `user_id` format backend expects
3. Check if backend finds user in room

### Test 2: Try String Format
1. Update code to send `user_id` as string
2. Test if seats load
3. Check backend logs for received format

### Test 3: Verify WebSocket Connection Format
From your logs:
```
📡 [WebSocketService] Query Parameters: {room_id: 73, user_id: 00100621, username: Csgsg}
```

**WebSocket uses:** `user_id: 00100621` (string with leading zeros)

**get_seats uses:** `user_id: 100621` (integer without zeros)

**These should match!**

---

## 📝 Recommended Fix

**Update `getSeats` method to send user_id as string:**

```dart
// ✅ Get seats (triggers seats:update from server)
Future<bool> getSeats(String roomId) async {
  try {
    // ... existing code ...
    
    // ✅ Get user_id from WebSocket service (stored as String like "00100400")
    final currentUserId = _wsService.currentUserId;
    if (currentUserId == null || currentUserId.isEmpty) {
      print("❌ [SeatProvider] ERROR: User ID not found - cannot send get_seats request");
      _errorMessage = 'User ID not found. Please reconnect.';
      notifyListeners();
      return false;
    }
    
    // ✅ DON'T convert to integer - keep as string to match WebSocket connection format
    // The backend might expect the same format as WebSocket connection
    print("✅ [SeatProvider] Using user_id as string: $currentUserId (matches WebSocket format)");
    
    // ✅ SERVER EXPECTS: {"action": "get_seats", "room_id": 73, "user_id": "00100621"}
    print("📤 [SeatProvider] Sending get_seats request in action format");
    print("📤 [SeatProvider] Room ID: $roomIdInt, User ID: $currentUserId (string)");
    
    final sent = _wsService.sendAction('get_seats', {
      'room_id': roomIdInt,
      'user_id': currentUserId,  // ✅ Send as string (matches WebSocket connection)
    });
    
    // ... rest of code ...
  }
}
```

---

## 🔍 Why This Matters

**Backend might be:**
1. **Tracking users by WebSocket connection** using `user_id: "00100621"`
2. **Looking up user in room** when `get_seats` is called
3. **Not finding user** because `get_seats` sends `user_id: 100621` (different format)
4. **Not responding** because user lookup fails

**By sending the same format as WebSocket connection, backend can:**
- ✅ Find user in room
- ✅ Return seats for that room
- ✅ Include user's seat status

---

## 📋 Checklist

- [ ] Check backend logs for `get_seats` requests
- [ ] Verify what `user_id` format backend expects
- [ ] Update code to send `user_id` as string (if needed)
- [ ] Test if seats load after fix
- [ ] Verify backend responds with `seats:update` event

---

**Last Updated**: 2025-12-08  
**Status**: ⚠️ **User ID format mismatch likely causing seats not to load**

