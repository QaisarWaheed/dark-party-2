#!/bin/bash
cd c:/dark-party/frontend/assets/images

# Delete unused images
rm -f 1.2M.png 2.png 22.png 3.png 33.png 120k.png 12k.png 600k.png 60k.png
rm -f boy.PNG girl.PNG abouticon.png admin_seat.png agency_settings_background.png
rm -f backlogo.jpeg baclogo.png "banner_pic(1).png" "banner_pic(2).png" below3.png
rm -f bg_cp.png bg_id.png bg_mine.png checkIcon.png circle_lock.png CpBG.png
rm -f cpleaderboard.png darkpartylogo.png dddf.PNG dollar.png editprofileicon.png
rm -f exiticon.png fb.png feedbackicon.png gameleaderboard.png gifter.jpeg
rm -f gifterbanner.jpeg gifterlist.png goliveicon.png google.jpeg heart.png
rm -f image_border.png invite_img.png king_icon.png login_bg_pic.jpeg
rm -f login_bg_pic.jpg logo.png lucky_profile.png newid.svg phone.png
rm -f privacyicon.png sender_profile.png settingicon.png snapchat.png
rm -f switchicon.png taskcentericon.png vipicon.png walletcoin.png yellow_seat.png

# Delete level images
rm -f lv0.png lv0_bg.png lv1.png lv1_bg.png lv10.png lv10_bg.png
rm -f lv20.png lv20_bg.png lv30.png lv30_bg.png lv40.png lv40_bg.png
rm -f lv50.png lv50_bg.png lv60.png lv60_bg.png lv70.png lv70_bg.png
rm -f lv80.png lv80_bg.png lv90.png lv90_bg.png lv100.png lv100_bg.png

# Delete mine images
rm -f mine_badge.png mine_earning.png mine_family.png mine_host.png
rm -f mine_kf.png mine_level.png mine_vip.png message_icon.png

# Delete unnamed images
rm -f unnamed__6_-removebg-preview_1.png unnamed__7_-removebg-preview_1.png
rm -f unnamed__7_-removebg-preview_2.png

echo "✓ Images cleaned: $(ls | wc -l) files remaining"

# Clean icons
cd c:/dark-party/frontend/assets/icons
rm -f 4.png 5.png 6.png 7.png 8.png 9.png 10.png 12.png 13.png
rm -f 404.png 505.png 606.png 707.png 808.png
rm -f pfp1.png pfp2.png Group_33.png diamond_exchange.png diamond_transfer.png diamond_withdraw.png
rm -f "Screenshot_2026-01-26_124352-removebg-preview_1.png"
rm -f "Screenshot_2026-01-26_124437-removebg-preview_2.png"
rm -f "Screenshot_2026-01-27_123551-removebg-preview_1.png"
rm -f chat.png confirm_follow.png follow.png Supporter_bronze.png supporter_Gold.png support_silver.png
rm -f "Gemini_Generated_Image_bdsa8dbdsa8dbdsa-removebg-preview 1 (1).svg"

echo "✓ Icons cleaned: $(ls | wc -l) files remaining"

# Clean SVG  
cd c:/dark-party/frontend/assets/svg
rm -f Group_28.svg Group_29.svg Group_31.svg Group_32.svg Group_33.svg home.svg room_seat.svg

echo "✓ SVG cleaned: $(ls | wc -l) files remaining"
echo "✅ Cleanup complete!"
