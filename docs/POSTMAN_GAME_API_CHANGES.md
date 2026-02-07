Summary of changes to game-related Postman collection

- Converted BAISHUN-facing endpoints to use JSON POST bodies (`application/json`) as required by the BAISHUN spec (signature fields carried in JSON).
- Ensured `change_balance` example includes `order_id`, `game_round_id`, `currency_diff`, `game_id`, `room_id`, `diff_msg`, and signature fields.
- Replaced incomplete `Get SSToken` example (formdata/raw missing) with a BAISHUN-compatible JSON `get_sstoken` example that includes `app_id`, `user_id`, `code`, `signature_nonce`, `timestamp`, and `signature`.
- Added missing endpoints: `one_game_info.php` (returns download_url/game_version/game_mode etc.), `gamelist.php` (game list), and `v2/api/balance_info.php` (game balance query).
- Documented placeholders in collection for `signature_nonce`, `timestamp`, and `signature`. Signature algorithm: md5(signatureNonce + AppKey + timestamp) lower-case hex.

Notes & next steps
- Test the new collection in Postman against your staging URL; set `{{URL}}` to your BAISHUN-facing server or the test server.
- Ensure server verifies `signature_nonce` replay (15s window) and enforces per-user locking on `change_balance`.
- If you want, I can update your original Postman collection file in-place instead of creating a new one.
