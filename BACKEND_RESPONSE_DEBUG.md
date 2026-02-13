# 🔍 Backend Response Debugging Guide

## ❌ Current Issue: Seats Not Loading

**From Your Logs:**
```
📤 [SeatProvider] Full payload: {'action': 'get_seats', 'room_id': 73, 'user_id': 100623}
✅ [SeatProvider] Get seats event sent via WebSocket
⏳ Waiting for seats... (5000ms / 5000ms)
! Seats not received after 5000ms - server may be slow
```

**Problem:** Backend is **NOT responding** to `get_seats` request.

---

## 🔍 What We're Sending

```json
{
  "action": "get_seats",
  "room_id": 73,
  "user_id": 100623,
  "user_id_string": "00100623"
}
```

**✅ All correct:**
- `room_id`: Integer (73)
- `user_id`: Integer (100623) - **PRIMARY** (backend expects this for database queries)
- `user_id_string`: String ("00100623") - **BACKUP** (for compatibility)

---

## 🔍 What Backend Should Respond With

### Option 1: Direct Response (Same Action)
```json
{
  "action": "get_seats",
  "data": {
    "room_id": 73,
    "seats": [
      {"seat_number": 1, "is_occupied": false, ...},
      {"seat_number": 2, "is_occupied": true, "user_id": 100623, ...},
      ...
    ]
  }
}
```

### Option 2: Event-Based Response (Preferred)
```json
{
  "event": "seats:update",
  "data": {
    "room_id": 73,
    "seats": [
      {"seat_number": 1, "is_occupied": false, ...},
      {"seat_number": 2, "is_occupied": true, "user_id": 100623, ...},
      ...
    ]
  }
}
```

### Option 3: Success Response Then Event
```json
// First response:
{
  "status": "success",
  "message": "Seats retrieved successfully",
  "action": "get_seats"
}

// Then event:
{
  "event": "seats:update",
  "data": {
    "room_id": 73,
    "seats": [...]
  }
}
```

---

## 🔍 Backend Requirements

### 1. **Receive `get_seats` Request**
Backend should:
- ✅ Receive WebSocket message with `action: "get_seats"`
- ✅ Extract `room_id: 73` (integer)
- ✅ Extract `user_id: 100623` (integer) - **USE THIS FOR DATABASE QUERIES**
- ✅ Extract `user_id_string: "00100623"` (optional, for reference)

### 2. **Process Request**
Backend should:
- Query database: `SELECT * FROM seats WHERE room_id = 73`
- Query database: `SELECT * FROM seat_occupants WHERE room_id = 73 AND user_id = 100623`
- Build seats array with current state

### 3. **Send Response**
Backend should send **ONE** of these formats:

**Format A: Direct Response (Recommended)**
```json
{
  "event": "seats:update",
  "data": {
    "room_id": 73,
    "seats": [
      {
        "seat_number": 1,
        "is_occupied": false,
        "is_reserved": false,
        "user_id": null,
        "username": null,
        "profile_url": null
      },
      {
        "seat_number": 2,
        "is_occupied": true,
        "is_reserved": false,
        "user_id": 100623,
        "username": "User Name",
        "profile_url": "https://..."
      },
      ...
    ],
    "total_seats": 8,
    "occupied_seats": 1,
    "available_seats": 7
  }
}
```

**Format B: Action Response**
```json
{
  "action": "get_seats",
  "data": {
    "room_id": 73,
    "seats": [...]
  }
}
```

**Format C: Success + Event**
```json
// First:
{
  "status": "success",
  "message": "Seats retrieved",
  "action": "get_seats"
}

// Then:
{
  "event": "seats:update",
  "data": {
    "room_id": 73,
    "seats": [...]
  }
}
```

---

## 🔍 Debugging Steps for Backend Developer

### Step 1: Check if Request is Received
**Backend logs should show:**
```
Received get_seats request:
- room_id: 73 (integer)
- user_id: 100623 (integer)
- user_id_string: 00100623 (string)
```

**If NOT received:**
- Check WebSocket connection handling
- Check action routing/dispatching
- Check if `get_seats` action is registered

### Step 2: Check Database Query
**Backend should query:**
```sql
SELECT * FROM seats WHERE room_id = 73;
SELECT * FROM seat_occupants WHERE room_id = 73;
```

**Verify:**
- Database connection is working
- Room 73 exists
- Seats table has data for room 73
- Query returns results

### Step 3: Check Response Format
**Backend should send:**
- Event name: `seats:update` OR `get_seats`
- Data structure matches expected format
- `room_id` included in response
- `seats` array is populated

### Step 4: Check WebSocket Broadcasting
**Backend should:**
- Send response to correct WebSocket connection
- Include `room_id` in response for filtering
- Use correct event name (`seats:update` or `get_seats`)

---

## 🔍 Common Backend Issues

### Issue 1: Action Not Registered
**Symptom:** Request received but no processing
**Fix:** Register `get_seats` action handler

### Issue 2: Database Query Fails
**Symptom:** Request processed but no data returned
**Fix:** Check database connection and query syntax

### Issue 3: Wrong Event Name
**Symptom:** Response sent but client doesn't receive it
**Fix:** Use `seats:update` or `get_seats` event name

### Issue 4: Missing room_id in Response
**Symptom:** Response sent but filtered out by client
**Fix:** Include `room_id: 73` in response data

### Issue 5: User ID Format Mismatch
**Symptom:** Query returns no results
**Fix:** Use integer `user_id: 100623` for database queries (not string)

---

## 🧪 Test Commands

### Test 1: Manual WebSocket Test
Connect to WebSocket and send:
```json
{
  "action": "get_seats",
  "room_id": 73,
  "user_id": 100623,
  "user_id_string": "00100623"
}
```

**Expected Response:**
```json
{
  "event": "seats:update",
  "data": {
    "room_id": 73,
    "seats": [...]
  }
}
```

### Test 2: Check Backend Logs
Look for:
- `get_seats` request received
- Database query executed
- Response sent

### Test 3: Check Database
```sql
SELECT * FROM seats WHERE room_id = 73;
SELECT * FROM seat_occupants WHERE room_id = 73;
```

---

## ✅ Backend Checklist

- [ ] `get_seats` action handler is registered
- [ ] Handler receives `room_id: 73` (integer)
- [ ] Handler receives `user_id: 100623` (integer)
- [ ] Database query uses integer `user_id` (not string)
- [ ] Database query returns seats for room 73
- [ ] Response includes `room_id: 73`
- [ ] Response uses event name: `seats:update` OR `get_seats`
- [ ] Response includes `seats` array
- [ ] Response is sent to correct WebSocket connection
- [ ] Response format matches expected structure

---

## 🆘 If Still Not Working

1. **Check backend WebSocket logs** - verify request is received
2. **Check backend database logs** - verify query executes
3. **Check backend response logs** - verify response is sent
4. **Test manually** - use WebSocket client to send request
5. **Verify event name** - check what backend actually sends
6. **Check room filtering** - verify response includes `room_id`

---

**Last Updated**: 2025-12-08  
**Status**: ⚠️ **Backend not responding to get_seats request**

