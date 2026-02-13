# 🪑 Seats Not Loading - Debugging Guide

## 🔍 Current Status

**From Your Logs:**
- ✅ `get_seats` request sent: `{"action": "get_seats", "room_id": 71, "user_id": "00100623"}`
- ✅ WebSocket connected: `true`
- ✅ Event listeners registered: `seats:update`, `seat_update`, `get_seats`
- ❌ **No response received** from backend after 5 seconds
- ❌ Seats not loading

---

## 🔍 Possible Causes

### 1. Backend Not Responding
**Symptoms:**
- Request sent but no WebSocket message received
- No `seats:update` event in logs

**Check:**
- Backend logs - verify `get_seats` request is received
- Backend code - verify it sends `seats:update` response
- Network - verify WebSocket connection is stable

### 2. User ID Format Mismatch
**Symptoms:**
- Backend receives request but doesn't process it
- Backend might expect integer user_id for `get_seats` action

**Current:**
- WebSocket connection: `user_id: "00100623"` (string)
- `get_seats` request: `user_id: "00100623"` (string) ✅ Fixed

**Possible Issue:**
- Backend might still expect integer: `user_id: 100623` for `get_seats`

### 3. Event Name Mismatch
**Symptoms:**
- Backend sends response but with different event name
- Response is received but not handled

**Current Listeners:**
- `seats:update` ✅
- `seat_update` ✅
- `get_seats` ✅ (action response)

**Check:**
- What event name does backend actually send?

### 4. Room Filtering Issue
**Symptoms:**
- Response received but filtered out by room ID
- Event has wrong room_id or no room_id

**Check:**
- WebSocket logs for "IGNORING EVENT - Room mismatch"
- Verify response includes correct `room_id`

---

## 🧪 Debugging Steps

### Step 1: Check Backend Logs
1. Check backend server logs when `get_seats` is sent
2. Verify backend receives the request
3. Verify backend processes it
4. Verify backend sends response

### Step 2: Check WebSocket Messages
Look for these logs in Flutter:
```
📥 [WebSocketService] ===== PARSING WEBSOCKET MESSAGE =====
📥 [WebSocketService] Raw message: ...
```

**If you see NO messages after `get_seats`:**
- Backend is not responding
- Check backend code/logs

**If you see messages but no `seats:update`:**
- Backend sends different event name
- Check what event name backend uses

### Step 3: Check Room Filtering
Look for these logs:
```
🔕 [WebSocketService] IGNORING EVENT - Room mismatch
```

**If you see this:**
- Response has wrong room_id
- Backend needs to include correct room_id in response

### Step 4: Try Integer User ID
If backend expects integer user_id for `get_seats`:

**Temporary Test:**
Change `get_seats` to send integer:
```dart
'user_id': userIdInt,  // Instead of currentUserId
```

**If this works:**
- Backend expects integer for `get_seats` action
- Need to handle both formats or standardize

---

## ✅ Solutions

### Solution 1: Backend Not Responding
**Fix:** Update backend to:
1. Receive `get_seats` action
2. Process request with `user_id: "00100623"` (string format)
3. Send `seats:update` event with seats array

### Solution 2: User ID Format
**Fix:** Backend should accept both formats:
- String: `"00100623"` (from WebSocket connection)
- Integer: `100623` (for backward compatibility)

Or standardize on one format.

### Solution 3: Event Name
**Fix:** Backend should send one of:
- `seats:update` (preferred)
- `seat_update` (alternative)
- `get_seats` (action response)

### Solution 4: Room ID in Response
**Fix:** Backend response should include:
```json
{
  "event": "seats:update",
  "data": {
    "room_id": 71,  // ✅ Include room_id
    "seats": [...],
    ...
  }
}
```

---

## 📋 Backend Requirements

**What Backend Should Do:**

1. **Receive `get_seats` request:**
   ```json
   {
     "action": "get_seats",
     "room_id": 71,
     "user_id": "00100623"  // String format (matches WebSocket)
   }
   ```

2. **Process request:**
   - Find user in room (using `user_id: "00100623"`)
   - Get seats for room 71
   - Return seats array

3. **Send response:**
   ```json
   {
     "event": "seats:update",
     "data": {
       "room_id": 71,
       "seats": [
         {"seat_number": 1, "is_occupied": false, ...},
         {"seat_number": 2, "is_occupied": true, "user_id": "00100623", ...},
         ...
       ],
       "total_seats": 8,
       "occupied_seats": 1,
       "available_seats": 7
     }
   }
   ```

---

## 🧪 Test Commands

### Test 1: Check if Backend Receives Request
**Backend logs should show:**
```
Received get_seats request:
- room_id: 71
- user_id: 00100623
```

### Test 2: Check if Backend Sends Response
**Backend logs should show:**
```
Sending seats:update event:
- room_id: 71
- seats count: 8
```

### Test 3: Check WebSocket Messages
**Flutter logs should show:**
```
📥 [WebSocketService] ===== PARSING WEBSOCKET MESSAGE =====
📥 [WebSocketService] Raw message: {"event":"seats:update",...}
```

---

## 🆘 If Still Not Working

1. **Check backend code** - verify `get_seats` handler exists
2. **Check backend logs** - see what's happening
3. **Test manually** - send `get_seats` via WebSocket client
4. **Verify event name** - check what backend actually sends
5. **Check room filtering** - verify response has correct room_id

---

**Last Updated**: 2025-12-08  
**Status**: ⚠️ **Backend not responding to get_seats request**

