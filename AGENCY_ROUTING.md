# Agency Module - Routing Guide

## 📱 Complete Navigation Flow

### Main Entry Points

1. **Profile Screen** → **Agency Center** (AllAgencyScreen)
   - Condition: Only shows if `hasAgencyAvailable == true` (from login response)
   - Location: Profile Screen → Menu List → "Agency Center"

---

## 🗺️ Complete Routing Map

```
Profile Screen
  └─> [Agency Center] (if hasAgencyAvailable)
       └─> AllAgencyScreen
            ├─> [Search] → Filter agencies (client-side)
            └─> [Click Agency] → AgencyProfileCenterScreen
                 ├─> [Join Agency] (if NOT owner) → Creates join request
                 ├─> [Host Application] (if owner) → JoinQuiteRequestPage
                 │    ├─> Join Request Tab → View/Accept/Decline join requests
                 │    └─> Apply to Quit Tab → View/Accept/Decline quit requests
                 │         └─> [Agree] → MemberManagementScreen
                 └─> [Initiate invitation] → AllAgencyScreen

AgencyProfileCenterScreen (from AllAgencyScreen)
  └─> [Host Application] → JoinQuiteRequestPage
       └─> [Agree on Request] → MemberManagementScreen
            └─> [Click Member] → AgencyNotificationScreen

HostCenterScreen (from AgencyCenterScreen - "Apply to join" button)
  └─> [Wallet] → AgencyProfileCenterScreen
       └─> [Host Application] → JoinQuiteRequestPage

AgencyCenterScreen (if exists - shows user's own agency)
  └─> [Apply to join] → HostCenterScreen
       └─> [Wallet] → AgencyProfileCenterScreen
```

---

## 📋 Screen Details

### 1. **AllAgencyScreen**
- **Route:** Profile → Agency Center
- **Purpose:** List all agencies, search agencies
- **Navigation:**
  - Click agency → `AgencyProfileCenterScreen`
  - Search bar → Filter agencies (client-side)

### 2. **AgencyProfileCenterScreen**
- **Route:** AllAgencyScreen → Click agency
- **Purpose:** View agency details
- **Navigation:**
  - If owner: "Host Application" → `JoinQuiteRequestPage`
  - If not owner: "Join Agency" → Creates join request (API call)
  - "Initiate invitation" → `AllAgencyScreen`

### 3. **JoinQuiteRequestPage**
- **Route:** AgencyProfileCenterScreen → "Host Application" (owner only)
- **Purpose:** Manage join/quit requests
- **Navigation:**
  - "Agree" on join request → `MemberManagementScreen`
  - Back button → Previous screen

### 4. **MemberManagementScreen**
- **Route:** JoinQuiteRequestPage → "Agree" on request
- **Purpose:** View and manage agency members
- **Navigation:**
  - Click member → `AgencyNotificationScreen` (if implemented)
  - Back button → Previous screen

### 5. **HostCenterScreen**
- **Route:** AgencyCenterScreen → "Apply to join" button
- **Purpose:** Host-related information
- **Navigation:**
  - "Wallet" → `AgencyProfileCenterScreen`
  - Back button → Previous screen

### 6. **AgencyCenterScreen**
- **Route:** (Currently not directly navigated - may be unused)
- **Purpose:** Display user's own agency information
- **Navigation:**
  - "Apply to join" → `HostCenterScreen`

---

## 🔄 Key Routing Rules

1. **Agency Creation:**
   - ❌ NOT available in frontend
   - ✅ Created by admin panel from backend
   - ✅ Users can only view and join existing agencies

2. **Join Request:**
   - Users can create join requests from `AgencyProfileCenterScreen`
   - Only shows "Join Agency" button if user is NOT the owner
   - Only shows "Host Application" button if user IS the owner

3. **Navigation Conditions:**
   - `AllAgencyScreen` only accessible if `hasAgencyAvailable == true`
   - `JoinQuiteRequestPage` only accessible to agency owners
   - `MemberManagementScreen` accessible after accepting join request

---

## ✅ Routing Checklist

- [ ] Profile Screen → AllAgencyScreen (when hasAgencyAvailable)
- [ ] AllAgencyScreen → AgencyProfileCenterScreen (click agency)
- [ ] AgencyProfileCenterScreen → JoinQuiteRequestPage (owner only)
- [ ] AgencyProfileCenterScreen → Create join request (non-owner)
- [ ] JoinQuiteRequestPage → MemberManagementScreen (after accept)
- [ ] HostCenterScreen → AgencyProfileCenterScreen (wallet button)
- [ ] All navigation back buttons work correctly
- [ ] No broken routes or missing screens

---

## 🐛 Common Routing Issues

### Issue: "Agency Center" not showing in Profile
- **Solution:** Check if `hasAgencyAvailable` is true in login response

### Issue: "Join Agency" button not showing
- **Solution:** Verify you're viewing an agency you don't own

### Issue: "Host Application" button not showing
- **Solution:** Verify you're the agency owner (check user_id matches agency user_id)

### Issue: Navigation crashes
- **Solution:** 
  - Check if agency data is passed correctly
  - Verify agency_id is not null
  - Check console logs for errors

---

## 📝 Notes

- Agencies are created by admin panel, not from frontend
- Users can only view, search, and join agencies
- Agency owners can manage requests and members
- All routing uses `Navigator.push` with `MaterialPageRoute`

