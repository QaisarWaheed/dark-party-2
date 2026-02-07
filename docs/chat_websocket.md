# Chat WebSocket System Documentation

## Overview

The Chat WebSocket system provides real-time messaging capabilities for your application. It supports text, image, and voice messages with instant delivery to connected users.

## Table of Contents

1. Server Setup
2. Client Connection
3. Sending Messages
4. Receiving Events
5. Event Types
6. API Reference
7. Examples
8. Troubleshooting

## 1. Server Setup

### Starting the WebSocket Server

The WebSocket server runs on port 8089. To start it:

```bash
cd /var/www/shaheen-star/public
php chat_websocket.php
```

You should see output like:

- Starting Chat WebSocket Server...
- Database connection established
- Chat WebSocket Server Started
- Listening on port 8089
- Event loop connected - Direct event polling enabled (every 10ms)
- Chat WebSocket Server running on port 8089
- Use ws://localhost:8089 for connections
- Direct broadcast via: chat_websocket_broadcast.php

### Running as a Background Service

To run the server in the background:

```bash
nohup php chat_websocket.php > /var/log/chat_websocket.log 2>&1 &
```

To stop the server:

```bash
pkill -f chat_websocket.php
```

## 2. Client Connection

### JavaScript/HTML Connection

Connect to the WebSocket server from your web application:

```js
// WebSocket connection URL
const wsUrl = 'ws://localhost:8089';
// Add user_id as query parameter
const userId = 1928800; // Your user ID
const username = 'john_doe'; // Optional
const name = 'John Doe'; // Optional
const socket = new WebSocket(`${wsUrl}?user_id=${userId}&username=${username}&name=${name}`)

// Connection opened
socket.onopen = function(event) {
  console.log('Connected to chat server');
  console.log('User ID:', userId);
};

// Receive messages
socket.onmessage = function(event) {
  const data = JSON.parse(event.data);
  console.log('Received event:', data.event);
  console.log('Event data:', data.data);
  // Handle different event types
  switch(data.event) {
    case 'chat:connected':
      console.log('Successfully connected to chat server');
      break;
    case 'chat:message':
      handleChatMessage(data.data);
      break;
    case 'chat:user_status':
      handleUserStatus(data.data);
      break;
    case 'chat:typing':
      handleTyping(data.data);
      break;
    case 'chat:read':
      handleReadReceipt(data.data);
      break;
  }
};

// Connection closed
socket.onclose = function(event) {
  console.log('Disconnected from chat server');
  // Optionally reconnect
  setTimeout(() => {
    // Reconnect logic here
  }, 3000);
};

// Error handling
socket.onerror = function(error) {
  console.error('WebSocket error:', error);
};
```

### Connection Parameters

When connecting, you can pass these query parameters:

- `user_id` (required): The user ID of the person connecting
- `username` (optional): Username for display
- `name` (optional): Full name for display

Example:

```
ws://localhost:8089?user_id=1928800&username=john&name=John%20Doe
```

## 3. Sending Messages

### Via API (Recommended)

Use the `send_chat_message.php` API to send messages.

#### Send Text Message

```js
fetch('https://shaheenstar.online/send_chat_message.php', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    sender_id: 1928798,
    receiver_id: 1928800,
    message: 'Hello, how are you?'
  })
})
.then(response => response.json())
.then(data => {
  console.log('Message sent:', data);
})
.catch(error => {
  console.error('Error:', error);
});
```

#### Send Image Message

```js
const formData = new FormData();
formData.append('sender_id', 1928798);
formData.append('receiver_id', 1928800);
formData.append('image', imageFile); // File object from input
fetch('https://shaheenstar.online/send_chat_message.php', {
  method: 'POST',
  body: formData
})
.then(response => response.json())
.then(data => {
  console.log('Image sent:', data);
});
```

#### Send Voice Message

```js
const formData = new FormData();
formData.append('sender_id', 1928798);
formData.append('receiver_id', 1928800);
formData.append('voice', voiceFile); // File object
formData.append('duration', 15); // Duration in seconds (optional)
fetch('https://shaheenstar.online/send_chat_message.php', {
  method: 'POST',
  body: formData
})
.then(response => response.json())
.then(data => {
  console.log('Voice message sent:', data);
});
```

## 4. API Response Format

```json
{
  "status": "success",
  "message": "Message sent successfully",
  "data": {
    "message_id": 123,
    "sender_id": 1928798,
    "receiver_id": 1928800,
    "message_type": "text",
    "message": "Hello, how are you?",
    "created_at": "2026-01-23 20:30:45"
  }
}
```

## 5. Receiving Events

### Event Structure

All events follow this structure:

```json
{
  "event": "event_name",
  "data": {
    // Event-specific data
  }
}
```

### Handling Events

```js
socket.onmessage = function(event) {
  const message = JSON.parse(event.data);
  switch(message.event) {
    case 'chat:message':
      // New message received
      displayMessage(message.data);
      break;
    case 'chat:user_status':
      // User online/offline status changed
      updateUserStatus(message.data.user_id, message.data.status);
      break;
    case 'chat:typing':
      // User is typing
      showTypingIndicator(message.data.sender_id);
      break;
    case 'chat:read':
      // Message was read
      markMessageAsRead(message.data.message_id);
      break;
    case 'chat:connected':
      // Successfully connected
      console.log('Connected!', message.data);
      break;
  }
};
```

## 6. Event Types

### 1. `chat:connected`

Sent when a user successfully connects to the WebSocket server.

Data example:

```json
{
  "event": "chat:connected",
  "data": {
    "user_id": 1928800,
    "message": "Successfully connected to chat server",
    "timestamp": "2026-01-23 20:30:45",
    "connected_users": 5
  }
}
```

### 2. `chat:message`

Sent when a new message is received.

Data example (text message):

```json
{
  "event": "chat:message",
  "data": {
    "message_id": 123,
    "sender_id": 1928798,
    "receiver_id": 1928800,
    "message_type": "text",
    "message": "Hello!",
    "sender": {
      "user_id": 1928798,
      "username": "john_doe",
      "name": "John Doe",
      "profile_url": "https://shaheenstar.online/uploads/profiles/user.jpg"
    },
    "created_at": "2026-01-23 20:30:45"
  }
}
```

Data example (image):

```json
{
  "event": "chat:message",
  "data": {
    "message_id": 124,
    "sender_id": 1928798,
    "receiver_id": 1928800,
    "message_type": "image",
    "media_url": "https://shaheenstar.online/uploads/chat/images/image.jpg",
    "file_size": 245678,
    "sender": { ... },
    "created_at": "2026-01-23 20:30:50"
  }
}
```

Data example (voice):

```json
{
  "event": "chat:message",
  "data": {
    "message_id": 125,
    "sender_id": 1928798,
    "receiver_id": 1928800,
    "message_type": "voice",
    "media_url": "https://shaheenstar.online/uploads/chat/voice/voice.mp3",
    "media_duration": 15,
    "file_size": 456789,
    "sender": { ... },
    "created_at": "2026-01-23 20:30:55"
  }
}
```

### 3. `chat:user_status`

Sent when a user’s online/offline status changes.

Data example:

```json
{
  "event": "chat:user_status",
  "data": {
    "user_id": 1928798,
    "status": "online",
    "timestamp": "2026-01-23 20:30:45"
  }
}
```

Status values: `online` or `offline`.

### 4. `chat:typing`

Sent when a user is typing (requires manual implementation).

Data example:

```json
{
  "event": "chat:typing",
  "data": {
    "sender_id": 1928798,
    "is_typing": true
  }
}
```

### 5. `chat:read`

Sent when a message is read (requires manual implementation).

Data example:

```json
{
  "event": "chat:read",
  "data": {
    "message_id": 123,
    "read_by": 1928800
  }
}
```

## 7. API Reference

### Send Chat Message API

- **Endpoint:** `POST /send_chat_message.php`
- **Parameters:**
  - `sender_id` (integer) — Yes
  - `receiver_id` (integer) — Yes
  - `message` (string) — Yes for text
  - `image` (file) — Yes for image
  - `voice` (file) — Yes for voice
  - `duration` (integer) — No (voice duration)

> At least one of `message`, `image`, or `voice` must be provided.

**Success response:**

```json
{
  "status": "success",
  "message": "Message sent successfully",
  "data": { ... }
}
```

**Error response:**

```json
{
  "status": "error",
  "message": "Error message here"
}
```

### Get Conversations API

- **Endpoint:** `GET/POST /get_conversations.php`
- **Parameters:**
  - `user_id` (integer) — Yes
  - `limit` (integer) — No (default: 50)
  - `offset` (integer) — No (default: 0)

### Get Conversation Messages API

- **Endpoint:** `GET/POST /get_conversation_messages.php`
- **Parameters:**
  - `user_id` (integer) — Yes
  - `other_user_id` (integer) — Yes
  - `limit` (integer) — No (default: 50)
  - `offset` (integer) — No (default: 0)
  - `before_message_id` (integer) — No (for pagination)

## 8. Examples

Included are multiple client examples (plain HTML/JS and React) demonstrating connect, send, and receive flows. See repository examples in this doc for complete snippets.

## Troubleshooting

### Connection Issues

**Problem:** Cannot connect to WebSocket server

**Solutions:**

1. Check if the server is running:

```bash
ps aux | grep chat_websocket.php
```

2. Verify port 8089 is not blocked by firewall.
3. Check server logs for errors.
4. Ensure the WebSocket URL is correct: `ws://localhost:8089` or `ws://your-domain.com:8089`.

### Messages Not Received

**Problem:** Messages are sent but not received

**Solutions:**

1. Verify the `receiver_id` matches the connected user’s `user_id`.
2. Check if the receiver is actually connected (check WebSocket server logs).
3. Verify the WebSocket connection is still open.
4. Check browser console for errors.
5. Check WebSocket server logs for broadcast messages.

### Server Not Starting

**Problem:** WebSocket server fails to start

**Solutions:**

1. Check if port 8089 is already in use:

```bash
netstat -tulpn | grep 8089
```

2. Verify PHP extensions are installed (required: `php-sockets`, `php-mbstring`).
3. Check database connection in `websocket_config.php`.
4. Verify file permissions on `chat_websocket.php`.

### Performance Issues

**Problem:** High CPU usage or slow message delivery

**Solutions:**

1. The server polls every 10ms — this is normal for instant delivery.
2. If too many connections, consider load balancing.
3. Monitor server logs for errors.
4. Check database query performance.

## Security Considerations

1. Authentication: Always validate user authentication before allowing WebSocket connections.
2. Authorization: Verify users can only send messages to authorized recipients.
3. Rate Limiting: Implement rate limiting to prevent spam.
4. Input Validation: Validate all message content before sending.
5. File Uploads: Validate file types and sizes for image/voice messages.
6. HTTPS/WSS: Use secure WebSocket (WSS) in production.

## Support

For issues or questions:

- Check server logs: `/var/log/chat_websocket.log`
- Check PHP error logs
- Review WebSocket server console output
- Verify database connectivity

## Version Information

- WebSocket Server: Port 8089
- Direct Event System: 10ms polling interval
- Supported Message Types: Text, Image, Voice
- File Upload Limits: Images (10MB), Voice (20MB)

_Last Updated: January 2026_
