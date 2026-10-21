# 🚀 Agency Module - Quick Testing Guide

## ⚡ Quick Test Flow (5 Minutes)

### Step 1: Agency Setup (Admin)
1. Admin creates agency via admin panel
2. Assign agency to User A (as owner)
3. ✅ **Check:** Agency appears in All Agency Screen list

### Step 2: Create Join Request (As User B)
1. Login as User B (different account)
2. Go to **All Agency Screen**
3. Click on "My Test Agency" (created by User A)
4. Click **"Join Agency"** button
5. ✅ **Check:** Success message "Join request sent successfully"

### Step 3: Accept Join Request (As User A - Owner)
1. Login back as User A (agency owner)
2. Go to **All Agency Screen** → Click "My Test Agency"
3. Click **"Host Application"** button
4. You should see User B's join request
5. Click **"Agree"** button
6. ✅ **Check:** 
   - Success message "User accepted into agency"
   - Navigates to Member Management Screen
   - User B appears in members list

### Step 4: View Members (As User A)
1. On **Member Management Screen**
2. ✅ **Check:**
   - User B appears in the list
   - Shows User B's name, ID, join time
   - Member count is correct

### Step 5: Create Quit Request (As User B)
1. Login as User B (member)
2. Navigate to appropriate screen (where quit option is)
3. Create quit request
4. ✅ **Check:** Request sent successfully

### Step 6: Accept Quit Request (As User A)
1. Login as User A (owner)
2. Go to **Join/Quit Request Page** → **"Apply to quit"** tab
3. See User B's quit request
4. Click **"Agree"**
5. ✅ **Check:**
   - Success message "User removed from agency"
   - User B removed from members list

---

## 📱 Screen Navigation Map

```
Home Screen
  └─> Profile Screen
       └─> Agency Center (AllAgencyScreen)
            ├─> [+ Button] → Create Agency Dialog
            ├─> [Click Agency] → Agency Profile Center Screen
            │    ├─> [Join Agency Button] → Create Join Request (if not owner)
            │    └─> [Host Application Button] → Join/Quit Request Page (if owner)
            │         ├─> Join Request Tab → View/Accept/Decline Join Requests
            │         └─> Apply to Quit Tab → View/Accept/Decline Quit Requests
            │              └─> [Agree] → Member Management Screen
            └─> [Search] → Filter Agencies

Agency Profile Center Screen
  └─> [Host Application] → Join/Quit Request Page
       └─> [Agree on Request] → Member Management Screen
            └─> [Click Member] → Agency Notification Screen

Agency Center Screen (User's Own Agency)
  └─> [Apply to join] → Host Center Screen
       └─> [Wallet] → Agency Profile Center Screen
```

---

## ✅ Testing Checklist

### Basic Flow
- [ ] Create agency
- [ ] View all agencies
- [ ] Search agencies
- [ ] Click agency → View details
- [ ] Create join request (as non-owner)
- [ ] View join requests (as owner)
- [ ] Accept join request
- [ ] Decline join request
- [ ] View members
- [ ] Create quit request
- [ ] View quit requests
- [ ] Accept quit request
- [ ] Decline quit request

### Edge Cases
- [ ] Try to create second agency (should fail)
- [ ] Try to create duplicate join request (should fail)
- [ ] Try to accept request without being owner (should fail)
- [ ] Try to join own agency (should not show join button)
- [ ] Network error handling
- [ ] Invalid agency ID handling

### UI/UX
- [ ] Loading states show correctly
- [ ] Error messages display properly
- [ ] Success messages display properly
- [ ] Navigation works smoothly
- [ ] Back button works
- [ ] Refresh button works
- [ ] Data refreshes after actions

---

## 🔍 Debug Console Logs

Watch for these log patterns:

### Successful Operations
```
✅ [AgencyProvider] Agency created successfully
✅ [AgencyProvider] Loaded X agencies via HTTP API
✅ [AgencyProvider] Join request created successfully
✅ [AgencyProvider] User accepted into agency
```

### API Calls
```
🏢 ========== AGENCY MANAGER API ==========
📋 ========== AGENCY REQUESTS API ==========
```

### Errors
```
❌ [AgencyProvider] Error: ...
⚠️ [AgencyProvider] ...
```

---

## 🎯 Key Test Points

1. **Create Agency** - Should work only if user doesn't have one
2. **Join Request** - Should work only if user is not already a member
3. **Accept Request** - Should work only if user is agency owner
4. **View Members** - Should show all members with correct data
5. **Quit Request** - Should work only if user is a member
6. **Navigation** - All screens should navigate correctly
7. **Data Refresh** - Lists should update after actions

---

## 🐛 Common Issues & Solutions

### Issue: "+" button not showing
- **Solution:** Check if user already has an agency (button only shows if no agency)

### Issue: "Join Agency" button not showing
- **Solution:** Check if you're viewing your own agency (only shows for other agencies)

### Issue: Requests not loading
- **Solution:** 
  - Verify you're logged in as agency owner
  - Check network connection
  - Verify agency_id is correct
  - Check console logs for errors

### Issue: Accept/Decline not working
- **Solution:**
  - Verify request_id is valid
  - Check if you're the agency owner
  - Check console logs for API errors

---

## 📊 Expected API Responses

### Create Agency
```json
{
  "status": "success",
  "message": "Agency created successfully",
  "data": {
    "id": 5,
    "agency_name": "Test Agency",
    "agency_code": "12345678",
    ...
  }
}
```

### Get Join Requests
```json
{
  "status": "success",
  "data": [
    {
      "request_id": 1,
      "user_id": 100623,
      "username": "testuser",
      "created_at": "2025-12-10 16:33:54",
      "country": "Argentina"
    }
  ]
}
```

### Accept Join Request
```json
{
  "status": "success",
  "message": "User accepted into agency"
}
```

---

## 🎉 Ready to Test!

Start with the quick 5-minute flow above, then test edge cases and error scenarios.

Good luck! 🚀

