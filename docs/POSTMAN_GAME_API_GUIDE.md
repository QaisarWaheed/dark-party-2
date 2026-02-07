# Postman – Game APIs Test Guide

Backend endpoints backend developer ke paas hain. Is guide se aap Postman se un URLs ko test kar sakte ho. BAISHUN dashboard mein bhi wahi production URLs set hone chahiye (backend dev se confirm karo).

---

## Step 0: Environment set karo

1. Postman top-right pe **"No environment"** dikh raha hai – uspe click karo.
2. **Create Environment** → naam do: `Shaheen Game`.
3. Variable add karo:
   - **Variable:** `URL`
   - **Initial Value:** `https://shaheenstar.online`
   - **Current Value:** `https://shaheenstar.online`
4. Save karo, phir top-right se **Shaheen Game** select karo.  
   Ab `{{URL}}` resolve hoga.

---

## 1. Request Game Code (app isko call karti hai)

**URL:** `POST {{URL}}/request_game_code.php`

**Headers:**  
- `Content-Type: application/x-www-form-urlencoded`  
  **ya**  
- `Content-Type: application/json`

**Body (form-urlencoded):**
| Key      | Value        |
|----------|--------------|
| user_id  | 1928987989   |
| room_id  | 102          |

**Body (agar JSON use kar rahe ho):**
```json
{
  "user_id": "1928987989",
  "room_id": "102"
}
```

**Success response:**
```json
{
  "code": 0,
  "message": "success",
  "data": { "code": "eyJhbGc..." }
}
```
Yahi `data.code` app game URL mein bhejti hai. Agar **404** aaye to yeh file server pe sahi path pe nahi hai.

---

## 2. Get SSToken (BAISHUN isko call karta hai)

**URL:** `POST {{URL}}/get_sstoken.php` (ya jo URL backend pe hai, e.g. `generate_sstoken.php` — backend dev se confirm karo.)

**Headers:**  
- `Content-Type: application/json`

**Signature formula (BAISHUN doc):**  
`signature = md5(signature_nonce + appKey + timestamp)` — lowercase hex, 32 chars.

**Values (config se):**
- `app_id`: `5864440123`
- `app_key`: `VV7RlosNTR6xCMYmfbmSF0ilqHwYktSl`

**Body (raw JSON):**
- `code` = step 1 se mila hua `data.code` (ek hi baar use hota hai).
- `signature_nonce` = koi bhi random string (e.g. `abc123def456`).
- `timestamp` = current Unix time in **seconds** (e.g. `1770183623`).

Example (timestamp/signature khud calculate karo):

```json
{
  "app_id": 5864440123,
  "user_id": "1928987989",
  "code": "YAHI_WOH_CODE_JO_STEP_1_SE_MILA",
  "signature_nonce": "abc123def456",
  "timestamp": 1770183623,
  "signature": "calculated_md5_here"
}
```

**Signature calculate (online ya script):**  
`md5("abc123def456" + "VV7RlosNTR6xCMYmfbmSF0ilqHwYktSl" + "1770183623")` → 32 char lowercase hex.

**Success response:**
```json
{
  "code": 0,
  "message": "succeed",
  "data": {
    "ss_token": "a1b2c3d4e5f6...",
    "expire_date": 1770788423000
  }
}
```
Yahi `ss_token` get_user_info mein use hoga.

---

## 3. Get User Info (BAISHUN isko call karta hai)

**URL:** `POST {{URL}}/get_user_info.php`

**Headers:**  
- `Content-Type: application/json`

**Body (raw JSON):**
- `ss_token` = step 2 se mila hua `data.ss_token`.
- Same signature formula: `signature_nonce`, `timestamp`, `signature`.

```json
{
  "app_id": 5864440123,
  "user_id": "1928987989",
  "ss_token": "YAHI_STEP_2_SE_MILA_SS_TOKEN",
  "signature_nonce": "xyz789",
  "timestamp": 1770183630,
  "signature": "calculated_md5_here"
}
```

**Success response:**
```json
{
  "code": 0,
  "message": "succeed",
  "data": {
    "user_id": "1928987989",
    "user_name": "Demo User",
    "user_avatar": "https://example.com/avatar.png",
    "balance": 1000
  }
}
```

---

## Order of testing

1. **Request Game Code** → Send → 200 + `code: 0`, `data.code` milna chahiye.  
   - 404 = file deploy nahi hai ya path galat.
2. **Get SSToken** → Body raw JSON: `app_id`, `user_id`, `code` (step 1 ka), `signature_nonce`, `timestamp`, `signature` → 200 + `data.ss_token`.  
   - Same `code` dobara bhejo → 1001 (code_used) aana chahiye.
3. **Get User Info** → Body mein wahi `ss_token` daalo + signature → 200 + user + balance.

---

## Signature helper (JavaScript – Postman Pre-request Script)

Get SSToken / Get User Info ke liye **Pre-request Script** tab mein ye daal sakte ho (app_key same rakhna):

```javascript
const appKey = 'VV7RlosNTR6xCMYmfbmSF0ilqHwYktSl';
const nonce = pm.variables.replaceIn('{{$randomAlphaNumeric}}') || 'testnonce';
const ts = Math.floor(Date.now() / 1000);
const sig = CryptoJS.MD5(nonce + appKey + ts).toString();
pm.environment.set('signature_nonce', nonce);
pm.environment.set('timestamp', ts);
pm.environment.set('signature', sig);
```

(Postman mein CryptoJS built-in hai.) Phir Body mein `{{signature_nonce}}`, `{{timestamp}}`, `{{signature}}` use karo.

---

## Change Balance

**URL:** `POST {{URL}}/change_balance.php`  
BAISHUN doc 3.4 ke hisaab se body: `app_id`, `user_id`, `ss_token`, `currency_diff`, `game_id`, `room_id`, `change_time_at`, `order_id`, `diff_msg`, + signature.  
Pehle 1–3 theek karo, phir change_balance test karna.
