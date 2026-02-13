# Permanent Fix for Broadcast & Room Animation

## Issue Analysis
The issue where "Receiver Name" and "Gift Image" were missing, and "Room Animation" was not playing, was caused by **two** separate listeners processing the same WebSocket event with inconsistent logic.

1.  **Broadcast Banner ("Patti")**: This is controlled by `BroadcastProvider.dart`. It had its own WebSocket listener that was using simplified parsing (only checking top-level keys). It did not search deep into the JSON (e.g., `to_user.name` or `gift.image`), causing it to receive `null` or empty strings.
2.  **Room Animation**: This is controlled by `RoomScreen.dart`. While we improved it earlier, it was still susceptible to "empty string" overwrites (`""`) instead of falling back to proper values.

## Fixes Applied

### 1. Robust `BroadcastProvider`
We completely rewrote the listener in `lib/controller/provider/broadcast_provider.dart`.
*   **Deep Search**: It now searches over 15 different key paths for every field (e.g., `sender`, `sender_name`, `from_name`, `sender.username`, etc.).
*   **Safe Strings**: It wraps every extraction in a `safeString()` helper that trims whitespace and converts `"null"` or empty strings to real `null`, ensuring valid data is prioritized.
*   **Consolidated Events**: It now handles both `gift:sent` and `gift_sent` events with the same robust logic.

### 2. Robust `RoomScreen`
We updated `lib/view/screens/room/room_screen.dart` to match the robust logic of `BroadcastProvider`.
*   **Empty String Protection**: We added the same `safeString()` protection to prevent a blank name from the backend from overwriting a valid name found in the Seat list.
*   **Animation Fix**: The gift animation URL extraction now also uses the deep search, ensuring `.svga` or `.mp4` files are found even if nested in the payload.

## Verification
Please run the app (`flutter run`).
1.  **Broadcast**: Send a high-value gift. The "Patti" should now show "Sender Name Send Receiver Name" correctly, with both avatars.
2.  **Animation**: The SVGA animation should play in the room center.
3.  **Logs**: If issues persist, check the Debug Console. We added `🔔 [BroadcastProvider]` logs that print the exact raw data received.
