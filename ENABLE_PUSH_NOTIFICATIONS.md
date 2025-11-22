# Enable Push Notifications - Step by Step Guide

Now that Firebase is integrated, you need to enable Push Notifications capability in Xcode.

## Step 1: Enable Push Notifications Capability

1. **Open Xcode** with your project (`vet.tn.xcodeproj`)

2. **Select your project** in the Project Navigator (left sidebar)
   - Click on the blue "vet.tn" icon at the top

3. **Select your target**
   - In the main panel, click on **"vet.tn"** under **TARGETS**

4. **Go to Signing & Capabilities tab**
   - Click the **"Signing & Capabilities"** tab at the top

5. **Add Push Notifications**
   - Click the **"+ Capability"** button (top left of the capabilities area)
   - In the search box, type: `Push Notifications`
   - Double-click **"Push Notifications"** or select it and click **Add**
   - You should now see "Push Notifications" added to your capabilities list

## Step 2: Enable Background Modes

1. **Still in Signing & Capabilities tab**

2. **Add Background Modes**
   - Click **"+ Capability"** again
   - Type: `Background Modes`
   - Double-click **"Background Modes"** or select it and click **Add**

3. **Enable Remote notifications**
   - After adding Background Modes, you'll see checkboxes appear
   - **Check the box** next to: ✅ **"Remote notifications"**

## Step 3: Verify Everything is Set Up

Your capabilities should now show:
- ✅ Push Notifications
- ✅ Background Modes
  - ✅ Remote notifications (checked)

## Step 4: Build and Test

1. **Clean Build Folder**
   - Go to: **Product** → **Clean Build Folder** (or press `Shift + Cmd + K`)

2. **Connect a physical iOS device** (push notifications don't work on simulator)
   - Connect via USB
   - Select your device in Xcode's device dropdown (top toolbar)

3. **Build and Run**
   - Click the **Play** button (or press `Cmd + R`)
   - Wait for the app to build and install on your device

4. **Check Console Logs**
   - Open Xcode's console (View → Debug Area → Activate Console, or `Cmd + Shift + C`)
   - Look for these messages when the app launches:
     - `✅ Push notification permission granted`
     - `✅ FCM token obtained: <token>`
     - `✅ FCM token sent to backend`

## Step 5: Verify in Backend

1. **Check backend logs** for:
   - `POST /users/fcm-token` request
   - Status 200 response

2. **Check database** (optional):
   - Verify users have `fcmToken` field populated after login

## Troubleshooting

### "No such module 'Firebase'"
- Make sure you opened the project correctly (`.xcodeproj` or `.xcworkspace` if using CocoaPods)
- Clean build folder and rebuild

### Push Notifications Not Working on Simulator
- **This is normal!** Push notifications only work on **physical devices**
- Use a real iPhone/iPad to test

### FCM Token Not Generated
- Make sure you're running on a physical device
- Check that `GoogleService-Info.plist` is in your project
- Verify Firebase initialization in console logs
- Check notification permissions are granted

### Capability Not Showing
- Make sure you selected the correct target (vet.tn)
- Try restarting Xcode
- Check that your Apple Developer account is properly configured

---

## Next: Test End-to-End

Once everything is set up:

1. **User A** logs into the app (on Device 1)
2. **User B** logs into the app (on Device 2) 
3. **User A** sends a message to **User B**
4. **User B** should receive a push notification!

Check backend logs for FCM notification sending status.

