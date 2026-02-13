# User Chat WebSocket Testing Guide

## 🔍 Issues Found and Fixed

### 1. **Connection Status Issue**
- **Problem**: `_isConnected` was set to `true` immediately after creating the channel, but connection might not be established yet
- **Fix**: Wait for first message or timeout before marking as connected

### 2. **Error Message Mismatch**
- **Problem**: Error message mentioned port 8087 but URL is 8088
- **Fix**: Updated error message to show correct port

### 3. **Stream Controllers**
- **Problem**: Stream controllers were being closed on disconnect, preventing reuse
- **Fix**: Don't close controllers on disconnect

### 4. **Error Handling**
- **Problem**: `cancelOnError: true` was causing connection to close on errors
- **Fix**: Changed to `cancelOnError: false` to keep connection alive

---

## 🧪 How to Test WebSocket Connection

### **Method 1: Check Logs in Flutter Console**

1. **Open the app and navigate to Chat screen**
2. **Check Flutter console for these logs:**

```
✅ Expected Success Logs:
🔌 Connecting to WebSocket...
📍 UserID: [your_user_id], Username: [username], Name: [name]
🌐 Connecting to: ws://shaheenstar.online:8089?user_id=...
🌐 WebSocket URL: ws://shaheenstar.online:8089
⏳ WebSocket channel created, waiting for connection...
✅ WebSocket connected successfully! (First message received)
📨 Received raw message: [message]
📊 Parsed message: [parsed_data]

❌ Error Logs (if connection fails):
❌ [UserChatWebSocket] Connection failed: [error]
❌ [UserChatWebSocket] Port 8088 might not be running or server is down
❌ WebSocket stream error: [error]
```

### **Method 2: Test Connection Status**

Add this test button in your chat screen:

```dart
// In your chat screen widget
Consumer<UserChatProvider>(
  builder: (context, provider, child) {
    return Column(
      children: [
        Text('Connection Status: ${provider.isConnected ? "✅ Connected" : "❌ Disconnected"}'),
        Text('Is Loading: ${provider.isLoading}'),
        Text('Error: ${provider.error ?? "None"}'),
        ElevatedButton(
          onPressed: () {
            provider.initialize();
          },
          child: Text('Reconnect'),
        ),
      ],
    );
  },
)
```

### **Method 3: Test with WebSocket Client Tool**

Use an online WebSocket client to test the server:

1. **Go to**: https://www.websocket.org/echo.html
2. **Connect to**: `ws://shaheenstar.online:8089?user_id=100423&username=test&name=Test User`
3. **Send test message**:
```json
{
  "action": "get_chatrooms",
  "user_id": 100423
}
```

### **Method 4: Test Individual Actions**

#### **Test 1: Get Chat Rooms**
```dart
// In your provider or test widget
_websocket.getChatRooms(userId);
// Check logs for: ✅ Chatrooms list received
```

#### **Test 2: Search Users**
```dart
_websocket.searchUsers(userId, "test");
// Check logs for: ✅ User search results received
```

#### **Test 3: Send Message**
```dart
_websocket.sendMessage(userId, chatroomId, "Hello!");
// Check logs for: ✅ Messages received
```

#### **Test 4: Create Chatroom**
```dart
_websocket.createChatroom(userId, otherUserId);
// Check logs for: ✅ Chatroom created
```

---

## 🔧 Debugging Steps

### **Step 1: Verify WebSocket Server is Running**

```bash
# Test if port 8089 is open
telnet shaheenstar.online 8089

# Or use curl
curl -i -N -H "Connection: Upgrade" -H "Upgrade: websocket" \
  -H "Sec-WebSocket-Version: 13" \
  -H "Sec-WebSocket-Key: test" \
  http://shaheenstar.online:8089
```

### **Step 2: Check Network Permissions**

Make sure your `AndroidManifest.xml` has internet permission:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

### **Step 3: Check URL Format**

The WebSocket URL should be:
```
ws://shaheenstar.online:8089?user_id=100423&username=test&name=Test%20User
```

### **Step 4: Monitor Network Traffic**

Use Flutter DevTools or Android Studio Network Inspector to see:
- WebSocket connection attempts
- Messages sent/received
- Connection errors

---

## 📋 Common Issues and Solutions

### **Issue 1: "Connection failed" immediately**
**Possible Causes:**
- WebSocket server not running on port 8088
- Firewall blocking connection
- Wrong URL format

**Solutions:**
1. Verify server is running: `telnet shaheenstar.online 8088`
2. Check URL in `api_constants.dart`: Should be `ws://shaheenstar.online:8089`
3. Check network connectivity

### **Issue 2: "WebSocket stream error"**
**Possible Causes:**
- Server closed connection
- Network interruption
- Invalid message format

**Solutions:**
1. Check server logs
2. Verify message format matches server expectations
3. Implement reconnection logic

### **Issue 3: "No messages received"**
**Possible Causes:**
- Connection not established
- Wrong event names
- Server not sending messages

**Solutions:**
1. Check if `_isConnected` is `true`
2. Verify event names match server (check `_handleMessage` method)
3. Test with WebSocket client tool

### **Issue 4: "Stream subscription error"**
**Possible Causes:**
- Stream controllers closed
- Multiple subscriptions
- Provider disposed

**Solutions:**
1. Don't close stream controllers on disconnect
2. Cancel subscriptions in dispose method
3. Check if provider is still mounted

---

## 🎯 Testing Checklist

- [ ] WebSocket connects successfully
- [ ] Connection status shows "Connected"
- [ ] Can send messages
- [ ] Can receive messages
- [ ] Can get chat rooms
- [ ] Can search users
- [ ] Can create chatrooms
- [ ] Reconnection works after disconnect
- [ ] Error handling works properly
- [ ] Streams receive data correctly

---

## 📱 Testing on Real Device

1. **Enable USB Debugging** on your device
2. **Connect device** via USB
3. **Run app** in debug mode
4. **Check logs** in Android Studio or VS Code
5. **Test all chat features** and monitor logs

---

## 🔗 Useful Commands

```bash
# Check if port is open
nc -zv shaheenstar.online 8089

# Test WebSocket with wscat (if installed)
wscat -c ws://shaheenstar.online:8089?user_id=100423&username=test

# Monitor network traffic (Android)
adb logcat | grep -i websocket
```

---

## 📞 Support

If issues persist:
1. Check server logs
2. Verify WebSocket server configuration
3. Test with WebSocket client tool
4. Check network connectivity
5. Review Flutter logs for detailed error messages

