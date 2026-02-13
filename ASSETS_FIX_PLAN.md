# Assets Fix Plan – Blur + Spaces in Names

## Problem 1: Images blur dikh rahi hain

**Possible reasons:**
- **Scaling:** Choti image ko bari jagah show karte waqt Flutter scale karta hai, is se blur lag sakta hai.
- **filterQuality:** Flutter default me `FilterQuality.low` use karta hai scaling pe – is se blur badh jata hai.
- **Figma export:** Agar 1x resolution export kiya hai to 2x/3x screens pe blur dikhega.

**Fix ka tareeqa:**
1. **Code me `filterQuality: FilterQuality.high` add karna**  
   Jahan bhi `Image.asset()` ya `AssetImage` use ho raha hai, wahan (jahan possible ho) `filterQuality: FilterQuality.high` set karenge taake scale hote waqt image sharp rahe.
2. **Ek common widget banana (optional)**  
   `SharpImage.asset()` jaisa widget jo hamesha `filterQuality: FilterQuality.high` use kare – baad me naye screens me yahi use kar sakte ho.
3. **Figma side (recommendation)**  
   Assets ko 2x ya 3x resolution pe export karo (e.g. 48px icon → 96px ya 144px) taake high-DPI screens pe blur na aaye.

---

## Problem 2: Assets ke names me space

**Issue:**  
Space wale filenames (e.g. `Group 33.png`, `image 16.png`) kabhi kabhar build/cache ya platforms par problem dete hain. Code me path bhi `'assets/icons/Group 33.png'` jaisa rehna padta hai.

**Spaces wali files (ab tak ki list):**

**assets/icons/**
- `Group 29.png` → `Group_29.png`
- `Group 182.png` → `Group_182.png`
- `Group 31.png` → `Group_31.png`
- `Group 33.png` → `Group_33.png`
- `Group 28.png` → `Group_28.png`
- `supporter Gold.png` → `supporter_Gold.png`
- `Supporter bronze.png` → `Supporter_bronze.png`
- `winning 1.png` → `winning_1.png`
- `Screenshot_2026-01-27_123551-removebg-preview 1.png` → `Screenshot_2026-01-27_123551-removebg-preview_1.png`
- `Screenshot_2026-01-27_123551-removebg-preview 2.png` → `..._2.png`
- `Screenshot_2026-01-27_123551-removebg-preview 3.png` → `..._3.png`
- `Screenshot_2026-01-27_123551-removebg-preview 4.png` → `..._4.png`
- `Screenshot_2026-01-26_124437-removebg-preview 2.png` → `..._2.png`

**assets/images/**
- `image 16.png` → `image_16.png`
- `image 9.png` → `image_9.png`
- `Rectangle 35.png` → `Rectangle_35.png`
- `unnamed__6_-removebg-preview 1.png` → `unnamed__6_-removebg-preview_1.png`
- `unnamed__7_-removebg-preview 1.png` → `..._1.png`
- `unnamed__7_-removebg-preview 2.png` → `..._2.png`

**Fix ka tareeqa:**
1. **Rename files**  
   Har file ka naam change karke space ki jagah underscore (_) use karunga (jaise upar).
2. **Code update**  
   `lib/` me jahan bhi in paths ka use hai (e.g. `assets/icons/Group 33.png`), wahan naya path likhunga (e.g. `assets/icons/Group_33.png`).
3. **PDF**  
   `BAISHUN Game Access Documentation V1.2.8.pdf` ko rename karna optional hai (code me use ho to bata dena).

---

## Execution order

1. **Pehle:** Spaces wale names fix  
   - Saari listed asset files rename (space → `_`).  
   - Saari code references update.
2. **Phir:** Blur fix  
   - Important screens (splash, login/signup, home, bottom nav, profile, room) me `Image.asset` / `AssetImage` jahan bhi scale ho raha ho wahan `filterQuality: FilterQuality.high` add karunga.  
   - Agar chaho to ek `SharpImage` (ya similar) helper widget bhi bana sakte hain.

---

## Aap kya karein

- Is plan se agree ho to bolo: **"fix karo"** / **"execute karo"** – main step 1 (rename + code update) aur step 2 (filterQuality) dono kar dunga.
- Agar koi file rename nahi karni (e.g. koi specific icon) to bata dena, usko list se hata dunga.
- Figma se ab se assets 2x/3x export karna better rahega taake blur kam aaye.
