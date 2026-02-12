import os
import shutil

# Base paths
FRONTEND_DIR = r"c:\dark-party\frontend"
IMAGES_DIR = os.path.join(FRONTEND_DIR, "assets", "images")
ICONS_DIR = os.path.join(FRONTEND_DIR, "assets", "icons")
SVG_DIR = os.path.join(FRONTEND_DIR, "assets", "svg")

# Images to DELETE (not used in code)
UNUSED_IMAGES = [
    "1.2M.png", "2.png", "22.png", "3.png", "33.png", "120k.png", "12k.png", 
    "600k.png", "60k.png", "abouticon.png", "admin_seat.png", 
    "agency_settings_background.png", "backlogo.jpeg", "baclogo.png", 
    "banner_pic(1).png", "banner_pic(2).png", "below3.png", "bg_cp.png", 
    "bg_id.png", "bg_mine.png", "boy.PNG", "checkIcon.png", "circle_lock.png", 
    "CpBG.png", "cpleaderboard.png", "darkpartylogo.png", "dddf.PNG", 
    "dollar.png", "editprofileicon.png", "exiticon.png", "fb.png", 
    "feedbackicon.png", "gameleaderboard.png", "gifter.jpeg", "gifterbanner.jpeg", 
    "gifterlist.png", "girl.PNG", "goliveicon.png", "google.jpeg", "heart.png", 
    "image_border.png", "invite_img.png", "king_icon.png", "login_bg_pic.jpeg", 
    "login_bg_pic.jpg", "logo.png", "lucky_profile.png", "lv0.png", "lv0_bg.png", 
    "lv1.png", "lv10.png", "lv100.png", "lv100_bg.png", "lv10_bg.png", "lv1_bg.png", 
    "lv20.png", "lv20_bg.png", "lv30.png", "lv30_bg.png", "lv40.png", "lv40_bg.png", 
    "lv50.png", "lv50_bg.png", "lv60.png", "lv60_bg.png", "lv70.png", "lv70_bg.png", 
    "lv80.png", "lv80_bg.png", "lv90.png", "lv90_bg.png", "message_icon.png", 
    "mine_badge.png", "mine_earning.png", "mine_family.png", "mine_host.png", 
    "mine_kf.png", "mine_level.png", "mine_vip.png", "myagencyicon.png", 
    "newid.svg", "phone.png", "privacyicon.png", "sender_profile.png", 
    "settingicon.png", "snapchat.png", "switchicon.png", "taskcentericon.png", 
    "unnamed__6_-removebg-preview_1.png", "unnamed__7_-removebg-preview_1.png", 
    "unnamed__7_-removebg-preview_2.png", "vipicon.png", "walletcoin.png", 
    "yellow_seat.png"
]

# Icons to DELETE (not used in code)
UNUSED_ICONS = [
    "4.png", "5.png", "6.png", "7.png", "8.png", "9.png", "10.png", "12.png", 
    "13.png", "404.png", "505.png", "606.png", "707.png", "808.png",
    "diamond_exchange.png", "diamond_transfer.png", "diamond_withdraw.png", 
    "Group_33.png", "pfp1.png", "pfp2.png", 
    "Screenshot_2026-01-26_124352-removebg-preview_1.png",
    "Screenshot_2026-01-26_124437-removebg-preview_2.png",
    "Screenshot_2026-01-27_123551-removebg-preview_1.png",
    "Gemini_Generated_Image_bdsa8dbdsa8dbdsa-removebg-preview 1 (1).svg",
    "menu_1.svg", " confirm_follow.png", "follow.png", "chat.png",
    "Supporter_bronze.png", "supporter_Gold.png", "support_silver.png"
]

def delete_files(directory, file_list):
    deleted_count = 0
    not_found_count = 0
    
    for filename in file_list:
        filepath = os.path.join(directory, filename)
        try:
            if os.path.exists(filepath):
                os.remove(filepath)
                print(f"✓ Deleted: {filename}")
                deleted_count += 1
            else:
                not_found_count += 1
        except Exception as e:
            print(f"✗ Error deleting {filename}: {e}")
    
    return deleted_count, not_found_count

def main():
    print("=" * 60)
    print("DELETING UNUSED ASSETS")
    print("=" * 60)
    
    # Delete unused images
    print(f"\n📁 Processing images in: {IMAGES_DIR}")
    img_deleted, img_not_found = delete_files(IMAGES_DIR, UNUSED_IMAGES)
    print(f"   Images deleted: {img_deleted}, not found: {img_not_found}")
    
    # Delete unused icons
    print(f"\n📁 Processing icons in: {ICONS_DIR}")
    icon_deleted, icon_not_found = delete_files(ICONS_DIR, UNUSED_ICONS)
    print(f"   Icons deleted: {icon_deleted}, not found: {icon_not_found}")
    
    # Summary
    total_deleted = img_deleted + icon_deleted
    print("\n" + "=" * 60)
    print(f"✅ CLEANUP COMPLETE!")
    print(f"   Total files deleted: {total_deleted}")
    print("=" * 60)

if __name__ == "__main__":
    main()
