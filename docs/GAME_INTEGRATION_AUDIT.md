# Game Integration Audit – Code + Logs

**Date:** 2026-02-04  
**Scope:** BAISHUN game loading, getConfig, backend calls, and “games not working” issues.

---

## 1. Code Audit Summary

### 1.1 App flow (room_screen.dart + api_manager)

| Step | What happens | Status |
|------|----------------|--------|
| Game list | `ApiManager.getGameList()` → BAISHUN `game-cn-test.jieyou.shop/v1/api/gamelist` | OK – returns list with `download_url` |
| Game tap | If `meta.gameId` present → `ApiManager.getOneGameInfo(gameId)` → BAISHUN `one_game_info` | OK – 200, `download_url` used |
| URL fallback | If no valid URL from backend, name-based fallbacks (Teen Patti, Fruit Carnival, etc.) | OK – many games covered |
| Session code | `ApiManager.requestGameCode(userId, roomId)` → `https://shaheenstar.online/request_game_code.php` | **FAIL in logs** – “no response from primary or fallback” |
| Fallback code | Local `_generateOneTimeCode()` when request fails | OK – used so game still opens |
| URL params | `appChannel`, `appId`, `userId`, `code`, `roomId`, `game_id` appended to game URL | OK |
| WebView | `InAppWebView` + `initialUserScripts` AT_DOCUMENT_START (NativeBridge) | OK |
| getConfig | Handler returns full config, `return config` (Promise gets object) | OK – fixed earlier |
| NativeBridge | `doGetConfig` retries up to 50× if bridge not ready | OK |
| Loading | Overlay waits for `gameLoaded` or 12s timeout | OK |
| Lifecycle notify | `_notifyGameLifecycle(createGameUrl, …)` when opening/closing game | **Fixed** – skipped when URL is localhost to avoid Connection refused |

### 1.2 Backend (hosted – not in this repo)

Backend is maintained separately. App expects these endpoints at `https://shaheenstar.online/`:

| Endpoint | Purpose | Notes |
|----------|---------|--------|
| `request_game_code.php` | Returns one-time `code` (JWT) for app | If not reachable, app uses local hex code |
| `get_sstoken.php` | BAISHUN calls with `code` → returns `ss_token` | Expects JSON POST; one-time code; app_key 5864440123 |
| `get_user_info.php` | BAISHUN calls with `ss_token` → returns user/balance | Required for game to get user info |

---

## 2. Log Audit Summary

### 2.1 What works (from captured logs)

- **getOneGameInfo:** 200, `download_url` used (e.g. BigEater, game_id 1067).
- **getConfig:** “getConfig handler called by game”, “Called game jsCallback successfully”, “Game reported loaded”.
- **NativeBridge:** “Available methods: getConfig,destroy,gameRecharge,gameLoaded”.
- **WebSocket (game ↔ BAISHUN):** Connects (e.g. teen_patti/ws, greedy_lion/ws2, big_eater/ws2) with `code` in URL.
- **Game route:** XHR to `game_route/get_addr` returns 200 with `http_addr` and `ws_addr`.

### 2.2 What fails

1. **requestGameCode**
   - Log: `[ApiManager] requestGameCode no response from primary or fallback`
   - Cause: `https://shaheenstar.online/request_game_code.php` not responding (timeout / connection issue from app).
   - Effect: App uses locally generated code; game still opens and getConfig works.

2. **Game error message**
   - Log: `GAME ERROR: 无法连接到服务器！ 402` / `404` / `405` (Cannot connect to server).
   - Cause: Game client receives HTTP 402/404/405. These come from **BAISHUN game server** when it calls **your app server** (get_sstoken or get_user_info). So either:
     - BAISHUN is not configured with your server URLs, or
     - The configured URL is wrong (404), or
     - Your server returns 4xx (e.g. 402/405) or is unreachable.
   - Effect: Game loads and WebSocket connects, but then shows “无法连接到服务器！” and may not fully work.

3. **_notifyGameLifecycle**
   - Log: `_notifyGameLifecycle error: SocketException: Connection refused ... 127.0.0.1`
   - Cause: `createGameUrl` / `closeGameUrl` default to `http://127.0.0.1` when meta has no create_url/close_url.
   - Fix applied: Skip lifecycle notify when host is localhost so this error no longer appears.

---

## 3. Root Causes for “Games Not Working”

| Issue | Layer | Fix |
|-------|--------|-----|
| “无法连接到服务器！ 402/404/405” | Backend + BAISHUN config | 1) Ensure BAISHUN has your **production** app server URLs: get_sstoken, get_user_info (and change_balance). 2) Ensure those URLs return 200 and correct JSON (see BAISHUN doc 3.1, 3.2). |
| request_game_code “no response” | Your server / network | 1) Ensure `https://shaheenstar.online/request_game_code.php` is reachable from the internet and returns 200 with `{ "code": 0, "data": { "code": "<one-time-code>" } }`. 2) Check firewall, SSL, and PHP errors. |
| Lifecycle Connection refused | App | Done – skip notify when URL is localhost. |

---

## 4. Checklist So Every Game Can Work

### 4.1 Your server (shaheenstar.online)

- [ ] **request_game_code.php** – Reachable, returns 200 and body with `code` (or `data.code`). App already falls back to local code if this fails.
- [ ] **get_sstoken.php** – Accepts POST JSON from BAISHUN (app_id, user_id, code, signature_nonce, timestamp, signature). Returns 200 and `{ "code": 0, "data": { "ss_token": "...", "expire_date": ... } }`. Must use same app_key as in BAISHUN backend.
- [ ] **get_user_info.php** – Accepts POST JSON (ss_token, etc.). Returns 200 and user_id, user_name, user_avatar, balance.
- [ ] **change_balance.php** – Implemented for betting/settlement (BAISHUN doc 3.4).

### 4.2 BAISHUN backend configuration

- [ ] In BAISHUN’s customer/merchant backend, set **app server base URL** (or per-endpoint URLs) to:
  - get_sstoken: `https://shaheenstar.online/get_sstoken.php` (or your actual path)
  - get_user_info: `https://shaheenstar.online/get_user_info.php`
  - change_balance: `https://shaheenstar.online/change_balance.php`
- [ ] App ID and App Key must match: app_id `5864440123`, app_key as in your server `config.php` and ApiConstants.

### 4.3 App (already done or optional)

- [x] getConfig returns full config (no empty `{}`).
- [x] NativeBridge at document start + retry when bridge not ready.
- [x] Loading overlay until gameLoaded or 12s.
- [x] Skip lifecycle notify for localhost.
- [ ] Optional: shorten requestGameCode timeout or add retry so UI feels faster when server is slow.

---

## 5. How to Verify After Fixes

1. **Request game code**
   - From device/emulator: open any game.
   - Logs: expect `[ApiManager] requestGameCode response status: 200` and `Received SESSION code from server`. If you still see “no response”, the backend URL is not reachable.

2. **Game no longer shows “无法连接到服务器！”**
   - Open same game; play until you need balance or user info.
   - If BAISHUN is calling your get_sstoken/get_user_info correctly and they return 200, this error should disappear.

3. **Backend logs**
   - On the server, check PHP/web server logs for POSTs to get_sstoken.php and get_user_info.php from BAISHUN’s IPs. That confirms they’re calling your URLs.

---

## 6. Why only some games “open” (Fruit Carnival, LuckyChest)

- **App side:** All games get the same flow: same URL params, getConfig, NativeBridge, loading.
- **What differs:** Many games (Teen Patti, Dragon Tiger, RoulettePro, Lucky77, etc.) need the **game server** to call your app’s **get_sstoken** and **get_user_info**. If that fails (URL not configured in BAISHUN or your server returns 4xx), the game shows “无法连接到服务器！” and stays on loading.
- **Fruit Carnival / LuckyChest:** May show the first screen or not call the backend immediately, so they appear to “open” even when backend is not configured.
- **Fix:** Configure BAISHUN with your app server URLs (get_sstoken, get_user_info) and ensure `request_game_code.php` is reachable. See sections 3 and 4.

---

## 7. Game list and URL fallbacks (reference)

- Games with valid `download_url` from `getGameList` or `one_game_info` are opened with that URL.
- If URL is missing/invalid, name-based fallbacks are used (e.g. Teen Patti, Fruit Carnival, Greedy Lion, Big Eater, etc.) – see `room_screen.dart` around lines 1992–2090.
- All games use the same getConfig/NativeBridge/loading flow; fixing backend and BAISHUN config fixes behavior for **all** games that rely on get_sstoken/get_user_info.
