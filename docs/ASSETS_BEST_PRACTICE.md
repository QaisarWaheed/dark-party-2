# Assets – Best & Permanent Approach

## 1. Blur fix (permanent)

### Problem
Flutter scales images with default `FilterQuality.low`, so they look blurry when scaled.

### Permanent solution: **Single way to load assets**

- **Ek hi widget/helper** use karo saari jagah: `AppImage.asset()` (ya `SharpImage.asset()`).
- Is widget ke andar hamesha:
  - `filterQuality: FilterQuality.high`
  - Consistent `fit` / `cacheWidth` / `cacheHeight` (optional, for performance)
- Naye screens / nayi assets add karte waqt bhi **sirf yahi** use karo.  
  → Blur dubara nahi aayega, kyunki sab jagah same, high-quality loading hogi.

### Extra (recommended)

- Figma se assets **2x / 3x** export karo (especially icons & key UI).  
- Isko project me document karo (e.g. assets folder README) taake sab follow karein.

---

## 2. Spaces in names (permanent)

### Problem
Filenames me space (e.g. `Group 33.png`) build/cache/code paths me issues de sakta hai.

### Permanent solution: **One-time rename + rule**

1. **One-time:**
   - Saari assets jinke names me space hai, unhe rename karo: space → `_` (e.g. `Group 33.png` → `Group_33.png`).
   - Poora codebase me in assets ke references update karo.

2. **Permanent rule:**
   - **Nayi assets add karte waqt:** names me **space mat use karo**; hyphen `-` ya underscore `_` use karo.
   - Is rule ko project me likh do (e.g. `assets/README.md` ya `ASSETS_FIX_PLAN.md`) taake naye log bhi follow karein.

Optional: agar chaho to baad me pre-commit hook ya script add kar sakte ho jo nayi files me space check kare.

---

## 3. Summary – best permanent approach

| Issue        | One-time fix                    | Permanent fix                                              |
|-------------|----------------------------------|------------------------------------------------------------|
| **Blur**    | Important screens me high quality | **Ek `AppImage.asset()` widget** – sab jagah isi se load  |
| **Spaces**  | Saari space wali files rename + refs update | **Rule:** nayi assets me names me space na ho; doc me likho |

Is approach se:
- Blur long-term fix rehta hai (single loading path + optional 2x/3x export).
- Names me space wala problem ek bar fix, phir rule se prevent.
