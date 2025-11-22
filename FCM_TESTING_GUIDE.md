# FCM Testing Guide - How to Verify It's Working

Follow these steps to verify that Firebase Cloud Messaging is working correctly.

## Prerequisites

✅ Firebase SDK installed  
✅ GoogleService-Info.plist added  
✅ Firebase code uncommented  
✅ Push Notifications capability enabled  
✅ Background Modes enabled  
✅ App builds without errors  

---

## Step 1: Run the App on a Physical Device

**Important**: Push notifications DO NOT work on the iOS Simulator. You must use a **real iPhone or iPad**.

1. Connect your iOS device via USB
2. Select your device in Xcode (top toolbar)
3. Build and Run (Cmd + R)

---

## Step 2: Check FCM Token Registration

### In Xcode Console (when app launches):

Look for these messages:

```
✅ Push notification permission granted
✅ FCM token obtained: <long-token-string>
✅ FCM token sent to backend
```

**What to look for:**
- If you see `✅ FCM token obtained`, Firebase is working!
- The token is a long string like: `cXyZ123abc...` (usually 150+ characters)

### In Backend Logs:

When you log in, you should see:

```
POST /users/fcm-token
Status: 200
```

**Check your backend terminal/console** for this request.

---

## Step 3: Verify Token is Stored in Database

### Option A: Check Backend Logs
- When FCM token is sent, backend should log success

### Option B: Check Database (MongoDB)
```javascript
// Connect to your MongoDB
db.users.findOne({ email: "your-email@example.com" }, { fcmToken: 1 })

// Should show:
{
  "_id": "...",
  "fcmToken": "cXyZ123abc..."  // ✅ Token should be here
}
```

---

## Step 4: Test Sending a Message

### Setup:
1. **User A** logged in on **Device 1**
2. **User B** logged in on **Device 2** (or different device)

### Test:
1. **User A** sends a message to **User B**
2. **Check Backend Logs** for:
   ```
   [FcmService] Successfully sent notification: projects/rifq-7294b/messages/0:...
   ```
   OR
   ```
   Failed to send FCM notification: ...
   ```

### Expected Result:
- **User B** should receive a push notification on Device 2
- Notification should show:
  - **Title**: User A's name
  - **Body**: Message content

---

## Step 5: Test Real-Time Message Delivery

### Scenario 1: App is Open (Foreground)
1. User B has the chat open with User A
2. User A sends a message
3. **Expected**: Message should appear immediately in User B's chat
4. **Check**: No need for polling - message appears instantly

### Scenario 2: App is in Background
1. User B minimizes the app (background)
2. User A sends a message
3. **Expected**: 
   - Push notification appears on User B's device
   - Badge count updates
   - Tapping notification opens the chat

### Scenario 3: App is Closed
1. User B force-closes the app
2. User A sends a message
3. **Expected**:
   - Push notification appears
   - Tapping notification opens the app and shows the message

---

## Troubleshooting: What If It's Not Working?

### ❌ No FCM Token in Console

**Check:**
- [ ] Firebase SDK is properly installed
- [ ] `GoogleService-Info.plist` is in the project
- [ ] App is running on a **physical device** (not simulator)
- [ ] Push notification permission was granted

**Fix:**
- Check Xcode console for error messages
- Verify Firebase initialization in `vet_tnApp.swift`

### ❌ FCM Token Not Sent to Backend

**Check:**
- [ ] User is logged in
- [ ] Backend is running
- [ ] Network request to `/users/fcm-token` appears in logs

**Fix:**
- Check backend logs for errors
- Verify authentication token is valid
- Check network connectivity

### ❌ Notifications Not Received

**Check:**
- [ ] Recipient has valid `fcmToken` in database
- [ ] Backend FCM service is initialized (check backend logs on startup)
- [ ] APNs certificate/key is uploaded to Firebase Console
- [ ] Device has internet connection

**Backend Log Check:**
When backend starts, you should see:
```
[FcmService] Firebase Admin initialized with service account JSON file
```

If you see errors about Firebase initialization, check `firebase-service-account.json` file.

### ❌ Messages Still Use Polling

**Check:**
- [ ] ChatViewModel is listening for FCM notifications
- [ ] Polling is disabled (check `useFCM = true` in ChatViewModel)
- [ ] FCM notifications are being received

**Fix:**
- Verify FCM notification handlers are set up
- Check that `useFCM` is set to `true` in ChatViewModel

---

## Quick Verification Checklist

### ✅ App Side
- [ ] FCM token appears in Xcode console on app launch
- [ ] Token is sent to backend (check network logs)
- [ ] No errors in Xcode console

### ✅ Backend Side
- [ ] Firebase Admin SDK initialized (check startup logs)
- [ ] FCM token stored in database for users
- [ ] When message sent, backend logs FCM notification attempt
- [ ] No FCM errors in backend console

### ✅ End-to-End Test
- [ ] User A sends message to User B
- [ ] User B receives push notification
- [ ] Message appears in real-time (no polling needed)
- [ ] Notification shows correct sender name and message

---

## Success Indicators

You'll know FCM is working when:

1. ✅ **FCM token generated** on app launch
2. ✅ **Token stored** in backend database
3. ✅ **Messages trigger notifications** (check backend logs)
4. ✅ **Recipients receive push notifications** on their devices
5. ✅ **Real-time delivery** - messages appear instantly without polling

---

## Monitoring in Firebase Console

You can also check Firebase Console:

1. Go to: https://console.firebase.google.com
2. Select your project: **rifq-7294b**
3. Go to **Cloud Messaging** section
4. Check **Reports** tab for:
   - Message delivery statistics
   - Success/failure rates
   - Device token information

---

## Test Script

Here's a quick test sequence:

1. **Device 1**: Launch app → Login → Check console for FCM token ✅
2. **Device 2**: Launch app → Login → Check console for FCM token ✅
3. **Backend**: Check both users have `fcmToken` in database ✅
4. **Device 1**: Send message to Device 2's user
5. **Backend**: Check logs for FCM notification attempt ✅
6. **Device 2**: Should receive push notification ✅
7. **Device 2**: Message appears in chat (if app open) ✅

If all steps show ✅, FCM is working perfectly! 🎉

