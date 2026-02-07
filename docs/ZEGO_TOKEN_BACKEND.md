# Zego Voice Token – Backend (fixes 1001005)

Voice room join fail (error **1001005** / LOGIN_FAILED) tab hota hai jab Zego project **token authentication** use karta hai lekin app ko token nahi milta.

## App side (done)

- App ab room join se pehle **get_zego_token.php** call karti hai: `POST room_id`, `user_id`.
- Agar response mein `token` milta hai to use **Zego joinRoom** mein pass kiya jata hai.

## Backend: get_zego_token.php

**URL:** `https://shaheenstar.online/get_zego_token.php`  
**Method:** POST  
**Body (form or JSON):** `room_id`, `user_id`

**Response (any one):**

- `{ "token": "04xxxxxxxx..." }`  
  ya  
- `{ "code": 0, "data": { "token": "04xxxxxxxx..." } }`

Token **Zego Token04** format mein hona chahiye. Zego Console se:

1. **Project** → **Token** (ya Authentication).
2. **Server Secret** copy karo (same as in app’s `ZegoConfig.serverSecret` for testing only; production mein server pe rahega).
3. Token generate karne ke liye Zego ka server-side generator use karo:  
   https://github.com/ZEGOCLOUD/zego_server_assistant  
   (e.g. PHP/Node) – **AppID**, **ServerSecret**, **userID**, **roomID** (optional) se token banao.

PHP example (pseudo): call Zego’s token04 generator with your AppID + ServerSecret + request’s `user_id` and `room_id`, return `{ "token": "<generated_token>" }`.

## Agar backend abhi implement nahi karega

- App token na mile to **empty token** se join try karegi (pehle jaisa).
- Agar Zego project **Token auth** pe set hai to phir bhi **1001005** aayega jab tak backend token return nahi karega.
- **Alternative:** Zego Console mein project ko **App Sign** auth pe switch karo (development) – us case mein empty token bhi chal sakta hai, lekin App Sign sahi/valid hona chahiye.

## Summary

| Scenario | Solution |
|----------|----------|
| Zego project = Token auth | Backend pe `get_zego_token.php` implement karo; app already call karti hai. |
| Zego project = App Sign only | Token zaroori nahi; 1001005 ho to App Sign / AppID Zego Console se check karo. |
