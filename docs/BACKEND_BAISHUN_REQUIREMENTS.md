# Game APIs – codebase mein jo URLs use ho rahe hain

App **sirf yehi** game-related APIs hit karti hai (sab `ApiConstants` se, `baseUrl = https://shaheenstar.online/`):

| Kaam              | URL (codebase)                    | Kaun call karta hai   |
|-------------------|-----------------------------------|------------------------|
| One-time code     | `request_game_code.php`          | App (game open pe)    |
| SSToken (code se) | `get_sstoken.php`                | App / BAISHUN server  |
| SSToken (fallback)| `generate_sstoken.php`           | App (get_sstoken fail pe) |
| User info         | `get_user_info.php`              | BAISHUN server        |
| Balance change    | `change_balance.php`              | BAISHUN server        |

Yeh sab pehle se `api_constants.dart` mein defined hain; app inhi ko use karti hai. Backend inhi URLs pe available hai to games sahi chalenge.

Postman se test karne ke liye: `docs/POSTMAN_GAME_API_GUIDE.md`.

---

## Kyun TeenPatti / baaki games mein "Server connection failed" aata hai? (Dual path)

**App side:** Hum **getConfig** mein **user info** aur **ss_token** bhej rahe hain — yeh sahi hai aur kuch games (e.g. Fruit Carnival, LuckyChest) isi se chal jaate hain.

**Lekin TeenPatti jaise games do path use karte hain:**

1. **Path 1 – App → Game (WebView):**  
   Game `NativeBridge.getConfig()` / `callHandler('getConfig')` call karta hai → Flutter handler **ss_token, user_name, balance, uid** wapas bhejta hai. ✅ Yeh app already kar rahi hai.

2. **Path 2 – BAISHUN game server → Aapka backend:**  
   Game load hone ke baad **BAISHUN ka game server** (server-side) **aapke backend** ko khud call karta hai:
   - `POST https://shaheenstar.online/get_sstoken.php` (BAISHUN ka JSON body: app_id, user_id, code, signature, etc.)
   - `POST https://shaheenstar.online/get_user_info.php` (ss_token ya user_id ke sath)

   Agar **BAISHUN dashboard** mein yeh URLs sahi set nahi hain, **ya backend** un requests ko accept nahi karta / 4xx ya galat JSON return karta hai, to game "无法连接到服务器！" / "Server connection failed" dikhata hai — **chahe app getConfig mein data bhej rahi ho.**

**Summary:**  
- **App bhej rahi hai** = getConfig (WebView) path ✅  
- **TeenPatti / baaki games fail** = **BAISHUN server → aapka backend** (get_sstoken.php, get_user_info.php) path ❌  

**Fix:**  
1. **BAISHUN dashboard** mein **get_sstoken** aur **get_user_info** ke liye **aapke backend ke full URLs** set karo (e.g. `https://shaheenstar.online/get_sstoken.php`).  
2. **Backend** pe ensure karo ke `get_sstoken.php` aur `get_user_info.php` **BAISHUN ke request format** ko handle karte hain (POST JSON, signature verify) aur success pe `{ "code": 0, "data": { ... } }` return karte hain.
