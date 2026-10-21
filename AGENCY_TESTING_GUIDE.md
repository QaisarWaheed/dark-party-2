# Agency Module Testing Guide

## 📋 Complete Agency Flow Testing Checklist

### Prerequisites
- ✅ User is logged in
- ✅ User has a valid user_id
- ✅ Backend API is accessible at `https://shaheenstar.online/`

---

## 🧪 Test Scenarios

### 1. **Agency Creation Flow**

**Note:** Agencies are created by admin panel from backend. Users cannot create agencies from the app.

#### Test: Verify Agencies Created by Admin
1. Admin creates agency via admin panel
2. Navigate to **All Agency Screen** (Profile → Agency Center)
3. **Expected Result:**
   - ✅ Agency appears in the list
   - ✅ Agency shows correct name, code, and owner
   - ✅ Agency is visible to all users

---

### 2. **View All Agencies Flow**

#### Test: View All Agencies List
1. Navigate to **All Agency Screen**
2. **Expected Result:**
   - ✅ Loading indicator shows initially
   - ✅ List of all agencies displays
   - ✅ Each agency shows:
     - Agency name
     - Agency code
     - Member count
     - Owner username
   - ✅ Agencies load quickly (parallel API calls)

#### Test: Search Agencies
1. On **All Agency Screen**, use search bar
2. Type agency name or code
3. **Expected Result:**
   - ✅ Filtered results show
   - ✅ Search works in real-time
   - ✅ Shows matching agencies only

#### Test: Click on Agency
1. Click any agency from the list
2. **Expected Result:**
   - ✅ Navigates to **Agency Profile Center Screen**
   - ✅ Shows correct agency details
   - ✅ Displays agency name and code

---

### 3. **Agency Profile Center Flow**

#### Test: View Agency Details
1. Navigate to **Agency Profile Center Screen** (from agency list)
2. **Expected Result:**
   - ✅ Shows agency name
   - ✅ Shows agency code
   - ✅ Shows owner information
   - ✅ Shows member count
   - ✅ Shows statistics (if available)

#### Test: Navigate to Wallet
1. On **Agency Profile Center Screen**
2. Click "Wallet" button
3. **Expected Result:**
   - ✅ Navigates to wallet screen (if implemented)
   - ✅ Or shows appropriate message

---

### 4. **Join Request Flow**

#### Test: Create Join Request (As Regular User)
1. Navigate to **All Agency Screen**
2. Find an agency you want to join (NOT your own agency)
3. Click on the agency → Opens **Agency Profile Center Screen**
4. Look for **"Join Agency"** button (bottom left)
5. Click "Join Agency"
6. **Expected Result:**
   - ✅ Loading indicator shows
   - ✅ Join request created
   - ✅ Success message: "Join request sent successfully" (green SnackBar)
   - ✅ User cannot create duplicate requests (error if try again)
   - ✅ Request appears in owner's join requests list

#### Test: View Join Requests (As Agency Owner)
1. Navigate to **Agency Profile Center Screen** (as owner - your own agency)
2. Click **"Host Application"** button (bottom left) → Opens **Join/Quit Request Page**
3. Select **"Join Request"** tab (default)
4. **Expected Result:**
   - ✅ Loading indicator shows initially
   - ✅ Shows list of pending join requests
   - ✅ Each request shows:
     - User name
     - User ID
     - Application time
     - Country (if available)
   - ✅ "Agree" and "Reject" buttons visible for pending requests
   - ✅ Badge shows count of pending requests (red circle with number)

#### Test: Accept Join Request
1. On **Join/Quit Request Page** → "Join Request" tab
2. Click "Agree" on a pending request
3. **Expected Result:**
   - ✅ Loading indicator shows
   - ✅ Success message: "User accepted into agency"
   - ✅ Request removed from list
   - ✅ User added to agency members
   - ✅ Navigates to Member Management Screen
   - ✅ Member count increases

#### Test: Decline Join Request
1. On **Join/Quit Request Page** → "Join Request" tab
2. Click "Reject" on a pending request
3. **Expected Result:**
   - ✅ Loading indicator shows
   - ✅ Success message: "Request rejected"
   - ✅ Request removed from list
   - ✅ User NOT added to agency

#### Test: Duplicate Join Request Prevention
1. Try to create join request when one is already pending
2. **Expected Result:**
   - ✅ Error: "You already have a pending request"
   - ✅ Request not created

---

### 5. **Member Management Flow**

#### Test: View Agency Members
1. Navigate to **Member Management Screen**
2. **Expected Result:**
   - ✅ Loading indicator shows initially
   - ✅ List of all members displays
   - ✅ Each member shows:
     - Profile image/avatar
     - Name
     - User ID
     - Join time
     - Country (if available)
   - ✅ Stats show:
     - Total members count
     - Currently broadcasting
     - Add hosts
     - Inactive hosts

#### Test: Refresh Members List
1. On **Member Management Screen**
2. Click refresh button (top right)
3. **Expected Result:**
   - ✅ Members list reloads
   - ✅ Latest data fetched from API

#### Test: Click on Member
1. Click on any member card
2. **Expected Result:**
   - ✅ Navigates to member details or notification screen
   - ✅ Shows member information

---

### 6. **Quit Request Flow**

#### Test: Create Quit Request (As Member)
1. As a member of an agency
2. Navigate to appropriate screen (where quit option is available)
3. Click "Quit" or "Leave Agency" button
4. **Expected Result:**
   - ✅ Quit request created
   - ✅ Success message: "Quit request sent"
   - ✅ Request appears in owner's quit requests list

#### Test: View Quit Requests (As Agency Owner)
1. Navigate to **Join/Quit Request Page**
2. Select "Apply to quit" tab
3. **Expected Result:**
   - ✅ Shows list of pending quit requests
   - ✅ Each request shows:
     - User name
     - User ID
     - Application time
   - ✅ "Agree" and "Reject" buttons visible

#### Test: Accept Quit Request
1. On **Join/Quit Request Page** → "Apply to quit" tab
2. Click "Agree" on a pending quit request
3. **Expected Result:**
   - ✅ Loading indicator shows
   - ✅ Success message: "User removed from agency"
   - ✅ Request removed from list
   - ✅ User removed from members
   - ✅ Member count decreases
   - ✅ Members list refreshes

#### Test: Decline Quit Request
1. On **Join/Quit Request Page** → "Apply to quit" tab
2. Click "Reject" on a pending quit request
3. **Expected Result:**
   - ✅ Loading indicator shows
   - ✅ Success message: "Quit request declined"
   - ✅ Request removed from list
   - ✅ User STAYS in agency (not removed)

---

### 7. **Agency Update Flow**

#### Test: Update Agency Name
1. Navigate to agency settings/update screen
2. Change agency name
3. Click "Update" or "Save"
4. **Expected Result:**
   - ✅ Agency name updated
   - ✅ Success message shown
   - ✅ Updated name reflects in all screens

---

### 8. **Agency Deletion Flow**

#### Test: Delete Agency (As Owner)
1. Navigate to agency settings
2. Click "Delete Agency"
3. Confirm deletion
4. **Expected Result:**
   - ✅ Agency deleted successfully
   - ✅ All members removed
   - ✅ Agency removed from list
   - ✅ Success message shown

---

### 9. **Navigation Flow**

#### Test: Complete Navigation Path
1. **Home** → **Profile** → **Agency Center**
2. **Agency Center** → **All Agency Screen**
3. **All Agency Screen** → Click agency → **Agency Profile Center**
4. **Agency Profile Center** → **Host Application** → **Join/Quit Request Page**
5. **Join/Quit Request Page** → **Agree** → **Member Management Screen**
6. **Member Management Screen** → Click member → **Agency Notification**
7. **Agency Profile Center** → **Wallet** button
8. **Host Center Screen** → **Wallet** → **Agency Profile Center**

**Expected Result:**
- ✅ All navigation works smoothly
- ✅ No crashes
- ✅ Back button works correctly
- ✅ Data persists during navigation

---

### 10. **Error Handling Tests**

#### Test: Network Error
1. Turn off internet/WiFi
2. Try to load agencies
3. **Expected Result:**
   - ✅ Error message shown
   - ✅ Retry option available
   - ✅ App doesn't crash

#### Test: Invalid Agency ID
1. Try to access agency with invalid ID
2. **Expected Result:**
   - ✅ Error message: "Agency not found"
   - ✅ Graceful error handling

#### Test: Unauthorized Actions
1. Try to accept/decline requests without being owner
2. **Expected Result:**
   - ✅ Error: "Permission denied"
   - ✅ Action blocked

---

## 🔍 Debugging Tips

### Check Logs
Look for these log prefixes in console:
- `🏢 [AgencyProvider]` - Agency provider operations
- `📋 [AgencyProvider]` - Request operations
- `🏢 ========== AGENCY MANAGER API ==========` - API calls
- `📋 ========== AGENCY REQUESTS API ==========` - Request API calls

### Common Issues

1. **Agencies not loading:**
   - Check if user is logged in
   - Check network connection
   - Verify API endpoint is correct
   - Check console logs for errors

2. **Requests not showing:**
   - Verify user is agency owner
   - Check if requests exist in database
   - Verify agency_id is correct
   - Check console logs

3. **Accept/Decline not working:**
   - Verify request_id is valid
   - Check if user has permission (is owner)
   - Verify API response in logs

---

## ✅ Success Criteria

All tests should pass:
- ✅ All API calls return success
- ✅ Data displays correctly
- ✅ Navigation works smoothly
- ✅ Error handling works
- ✅ Loading states show properly
- ✅ Success/error messages display
- ✅ No crashes or exceptions
- ✅ Data refreshes after actions

---

## 📱 Quick Test Checklist

- [ ] Create agency
- [ ] View all agencies
- [ ] Search agencies
- [ ] Click agency → View details
- [ ] Create join request
- [ ] View join requests (as owner)
- [ ] Accept join request
- [ ] Decline join request
- [ ] View members
- [ ] Create quit request
- [ ] View quit requests (as owner)
- [ ] Accept quit request
- [ ] Decline quit request
- [ ] Update agency
- [ ] Delete agency
- [ ] Test all navigation paths
- [ ] Test error scenarios

---

## 🚀 Ready to Test!

Start with the basic flow:
1. Create an agency
2. View it in the list
3. Create a join request (from another account)
4. Accept the request
5. View members
6. Test quit request flow

Good luck! 🎉

