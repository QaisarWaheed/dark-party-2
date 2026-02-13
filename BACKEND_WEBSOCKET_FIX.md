# 🔧 Backend WebSocket Fix for `get_seats`

## Issue Identified

The `handleGetSeats` method in your WebSocket server needs to properly handle the incoming request data and ensure the response is sent correctly.

## Current Code (Line ~580)

```php
private function handleGetSeats(ConnectionInterface $conn, $data) {
    $roomId = $data['room_id'];
    
    if (!isset($this->roomSeats[$roomId])) {
        $this->initializeRoomSeats($roomId);
    }
    
    $this->sendSeatUpdate($conn, $roomId);
}
```

## Problems

1. **No validation** - Doesn't check if `room_id` exists in `$data`
2. **No type conversion** - Should ensure `room_id` is an integer
3. **No logging** - Hard to debug if request is received
4. **No error handling** - Doesn't send error if `room_id` is missing

## ✅ Fixed Code

Replace the `handleGetSeats` method with this:

```php
/**
 * ✅ FIXED: Handle get_seats request with proper validation and logging
 */
private function handleGetSeats(ConnectionInterface $conn, $data) {
    echo "📊 [get_seats] Received request\n";
    echo "📊 [get_seats] Data received: " . json_encode($data) . "\n";
    
    // ✅ Validate room_id exists
    if (!isset($data['room_id'])) {
        echo "❌ [get_seats] Missing room_id in request\n";
        $this->sendError($conn, 'Missing room_id');
        return;
    }
    
    // ✅ Convert to integer (handle both string and int)
    $roomId = (int)$data['room_id'];
    $userId = isset($data['user_id']) ? $data['user_id'] : null;
    
    echo "📊 [get_seats] Room ID: $roomId (Type: " . gettype($roomId) . ")\n";
    if ($userId) {
        echo "📊 [get_seats] User ID: $userId (Type: " . gettype($userId) . ")\n";
    }
    
    // ✅ Validate room_id is valid
    if ($roomId <= 0) {
        echo "❌ [get_seats] Invalid room_id: $roomId\n";
        $this->sendError($conn, 'Invalid room_id');
        return;
    }
    
    // ✅ Initialize seats if room doesn't exist
    if (!isset($this->roomSeats[$roomId])) {
        echo "🎯 [get_seats] Initializing seats for room $roomId\n";
        $this->initializeRoomSeats($roomId);
    }
    
    // ✅ Send seat update to requester
    echo "📤 [get_seats] Sending seats:update event to requester\n";
    $this->sendSeatUpdate($conn, $roomId);
    
    echo "✅ [get_seats] Successfully sent seats for room $roomId\n";
    echo "==========================================\n";
}
```

## Additional Fix: Ensure `sendSeatUpdate` sends correct format

Make sure your `sendSeatUpdate` method (around line ~750) sends the response in the correct format:

```php
private function sendSeatUpdate(ConnectionInterface $conn, $roomId) {
    if (!isset($this->roomSeats[$roomId])) {
        $this->initializeRoomSeats($roomId);
    }
    
    $occupiedCount = 0;
    $availableCount = 0;
    
    foreach ($this->roomSeats[$roomId] as $seat) {
        if ($seat['is_occupied']) {
            $occupiedCount++;
        } else {
            $availableCount++;
        }
    }
    
    // ✅ Prepare response in format Flutter expects
    $response = [
        "event" => "seats:update",  // ✅ This is the event name Flutter listens for
        "data" => [
            "room_id" => (int)$roomId,
            "total_seats" => 20,
            "occupied_seats" => $occupiedCount,
            "available_seats" => $availableCount,
            "seats" => array_values($this->roomSeats[$roomId])  // ✅ Convert to indexed array
        ]
    ];
    
    $responseJson = json_encode($response);
    
    echo "📤 [sendSeatUpdate] Sending response for room $roomId:\n";
    echo "   - Event: seats:update\n";
    echo "   - Total seats: 20\n";
    echo "   - Occupied: $occupiedCount\n";
    echo "   - Available: $availableCount\n";
    echo "   - Response length: " . strlen($responseJson) . " bytes\n";
    
    $conn->send($responseJson);
    
    echo "✅ [sendSeatUpdate] Response sent successfully\n";
}
```

## Testing

After making these changes:

1. **Restart the WebSocket server:**
   ```bash
   php websocket_server.php
   ```

2. **Check server logs** when frontend sends `get_seats`:
   - You should see: `📊 [get_seats] Received request`
   - You should see: `📊 [get_seats] Data received: {...}`
   - You should see: `📤 [get_seats] Sending seats:update event`
   - You should see: `✅ [get_seats] Successfully sent seats`

3. **If you don't see these logs:**
   - The `get_seats` action might not be reaching the handler
   - Check if the action is being parsed correctly in `onMessage`
   - Verify the WebSocket connection is active

## Expected Frontend Request

The frontend sends:
```json
{
  "action": "get_seats",
  "room_id": 73,
  "user_id": "100623"
}
```

## Expected Backend Response

The backend should send:
```json
{
  "event": "seats:update",
  "data": {
    "room_id": 73,
    "total_seats": 20,
    "occupied_seats": 0,
    "available_seats": 20,
    "seats": [
      {
        "seat_number": 1,
        "is_occupied": false,
        "user_id": null,
        "username": null,
        "name": null,
        "profile_url": null,
        "occupied_at": null,
        "is_reserved": false
      },
      ... (20 seats total)
    ]
  }
}
```

## Debugging Steps

1. **Add logging to `onMessage` method** to see if `get_seats` is being received:
   ```php
   echo "📨 Action: $action, Room: $roomId, User: $userId\n";
   echo "📨 Full data: " . json_encode($data) . "\n";
   ```

2. **Check if the action is being routed correctly:**
   - Verify the `case 'get_seats':` is being hit
   - Add `echo "✅ Routing to handleGetSeats\n";` before calling the method

3. **Verify connection is active:**
   - Check if `$conn` is still valid
   - Ensure WebSocket connection hasn't closed

4. **Test manually with WebSocket client:**
   ```javascript
   const ws = new WebSocket('ws://shaheenstar.online:8083?room_id=73&user_id=00100623');
   ws.onopen = () => {
     ws.send(JSON.stringify({
       action: 'get_seats',
       room_id: 73,
       user_id: '100623'
     }));
   };
   ws.onmessage = (event) => {
     console.log('Response:', event.data);
   };
   ```

---

**Priority**: 🔴 **CRITICAL** - This fix should resolve the seats not loading issue  
**Status**: ⚠️ **Backend code update required**

