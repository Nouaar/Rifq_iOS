# iOS Firebase Setup Guide - Step by Step

This guide will help you add Firebase SDK to your iOS project and configure GoogleService-Info.plist.

## Prerequisites

- Xcode installed (Version 14.0 or later recommended)
- Firebase project created at https://console.firebase.google.com
- Your project: `rifq-7294b`

---

## Step 1: Get GoogleService-Info.plist from Firebase Console

### 1.1 Go to Firebase Console
1. Open your browser and go to: https://console.firebase.google.com
2. Select your project: **rifq-7294b**

### 1.2 Add iOS App (if not already added)
1. Click the **⚙️ Settings (gear icon)** in the top left
2. Select **Project settings**
3. Scroll down to **Your apps** section
4. If you don't see an iOS app:
   - Click **Add app** button
   - Select the **iOS** icon
   - Enter your **Bundle ID** (check in Xcode: Project Settings > General > Bundle Identifier)
     - Common format: `com.yourcompany.vet.tn` or similar
   - Enter **App nickname**: "Rifq iOS" (optional)
   - Enter **App Store ID**: (optional, leave blank for now)
   - Click **Register app**

### 1.3 Download GoogleService-Info.plist
1. After adding the iOS app, you'll see a download button
2. Click **Download GoogleService-Info.plist**
3. **Important**: Save this file somewhere you can find it (Downloads folder is fine)
4. The file will be named: `GoogleService-Info.plist`

---

## Step 2: Add GoogleService-Info.plist to Xcode Project

### 2.1 Open Your Xcode Project
1. Open Xcode
2. Open your project: `/Users/mac/Rifq_iOS/vet.tn.xcodeproj`
3. Wait for Xcode to fully load

### 2.2 Add the File to Your Project
1. In Xcode, right-click on the **`vet.tn`** folder in the Project Navigator (left sidebar)
2. Select **Add Files to "vet.tn"...**
3. Navigate to where you saved `GoogleService-Info.plist`
4. Select the `GoogleService-Info.plist` file
5. **IMPORTANT**: Make sure these options are checked:
   - ✅ **Copy items if needed** (this copies the file into your project)
   - ✅ **Add to targets: vet.tn** (check the box next to your app target)
6. Click **Add**

### 2.3 Verify the File is Added
1. In the Project Navigator, you should now see `GoogleService-Info.plist` in your project
2. Select the file to verify its contents
3. You should see keys like:
   - `PROJECT_ID`
   - `BUNDLE_ID`
   - `GOOGLE_APP_ID`
   - etc.

---

## Step 3: Add Firebase SDK via Swift Package Manager

### 3.1 Add Firebase Package
1. In Xcode, go to **File** menu → **Add Package Dependencies...**
   - **Shortcut**: You can also go to **Project Settings** → **Package Dependencies** tab
2. In the search field, paste this URL:
   ```
   https://github.com/firebase/firebase-ios-sdk
   ```
3. Click **Add Package**
4. Wait for Xcode to fetch the package (this may take a minute)

### 3.2 Select Firebase Products
1. After the package is fetched, you'll see a list of Firebase products
2. Select these products:
   - ✅ **FirebaseMessaging** (required for push notifications)
   - ✅ **FirebaseCore** (automatically included as dependency)
3. Make sure **Add to Target: vet.tn** is selected
4. Click **Add Package**
5. Wait for Xcode to resolve and add the packages

### 3.3 Verify Packages are Added
1. In the Project Navigator, expand **Package Dependencies**
2. You should see:
   - `firebase-ios-sdk`
3. Check **Project Settings** → **Package Dependencies** tab
4. You should see Firebase packages listed

---

## Step 4: Uncomment Firebase Code

Now that Firebase SDK is added, you need to uncomment the Firebase code.

### 4.1 Update FCMManager.swift

Open `vet.tn/ViewModel/FCMManager.swift` and uncomment:

1. **Line ~11-12**: Uncomment the imports
   ```swift
   import Firebase
   import FirebaseMessaging
   ```

2. **Line ~63-73**: Uncomment the `getFCMToken()` implementation
   ```swift
   do {
       let token = try await Messaging.messaging().token()
       await MainActor.run {
           self.fcmToken = token
           await self.sendTokenToBackend(token: token)
       }
       #if DEBUG
       print("✅ FCM token obtained: \(token)")
       #endif
   } catch {
       #if DEBUG
       print("❌ Failed to get FCM token: \(error)")
       #endif
   }
   ```
   Remove or comment out the simulated token code.

3. **Line ~88**: Uncomment the Messaging delegate setup
   ```swift
   Messaging.messaging().delegate = self
   ```

4. **Line ~153-170**: Uncomment the `MessagingDelegate` extension at the bottom

### 4.2 Update vet_tnApp.swift

Open `vet.tn/vet_tnApp.swift` and uncomment:

1. **Line ~13-14**: Uncomment the imports
   ```swift
   import Firebase
   import FirebaseMessaging
   ```

2. **Line ~16-20**: Uncomment Firebase initialization in `didFinishLaunchingWithOptions`
   ```swift
   // Configure Firebase
   FirebaseApp.configure()
   
   // Set FCM delegate
   Messaging.messaging().delegate = FCMManager.shared
   ```

3. **Line ~35**: Uncomment APNS token forwarding
   ```swift
   Messaging.messaging().apnsToken = deviceToken
   ```

---

## Step 5: Enable Push Notifications Capability

### 5.1 Add Push Notifications Capability
1. In Xcode, select your project in the Project Navigator
2. Select the **vet.tn** target
3. Go to the **Signing & Capabilities** tab
4. Click the **+ Capability** button (top left)
5. Search for and double-click **Push Notifications**
6. This will add Push Notifications capability

### 5.2 Add Background Modes
1. Still in **Signing & Capabilities** tab
2. Click **+ Capability** again
3. Search for and double-click **Background Modes**
4. Check the box for:
   - ✅ **Remote notifications**

---

## Step 6: Configure APNs in Firebase Console

### 6.1 Get Your APNs Key
1. Go to Apple Developer Portal: https://developer.apple.com/account
2. Go to **Certificates, Identifiers & Profiles**
3. Under **Keys**, create a new key (or use existing one)
4. Enable **Apple Push Notifications service (APNs)**
5. Download the `.p8` key file
6. Note your **Key ID** and **Team ID**

### 6.2 Upload to Firebase
1. Go back to Firebase Console
2. Go to **Project Settings** → **Cloud Messaging** tab
3. Under **Apple app configuration**, click **Upload**
4. Select **APNs Authentication Key** option
5. Upload your `.p8` key file
6. Enter your **Key ID** and **Team ID**
7. Click **Upload**

---

## Step 7: Build and Test

### 7.1 Clean Build
1. In Xcode: **Product** → **Clean Build Folder** (Shift + Cmd + K)
2. Wait for cleaning to complete

### 7.2 Build the Project
1. Select a **physical iOS device** (push notifications don't work on simulator)
2. Click **Build** (Cmd + B) to build the project
3. Fix any compilation errors if they appear

### 7.3 Run on Device
1. Connect your iOS device via USB
2. Select your device in Xcode
3. Click **Run** (Cmd + R)
4. The app should install and launch on your device

### 7.4 Verify FCM Token Registration
1. Open the app on your device
2. Log in to the app
3. Check Xcode console for:
   - `✅ FCM token obtained: <token>`
   - `✅ FCM token sent to backend`
4. Check backend logs for:
   - `POST /users/fcm-token` request
   - Status 200 response

---

## Troubleshooting

### "No such module 'Firebase'"
- Make sure you added the Firebase packages correctly
- Try: **File** → **Packages** → **Reset Package Caches**
- Then: **File** → **Packages** → **Update to Latest Package Versions**

### "GoogleService-Info.plist not found"
- Make sure the file is in your project folder
- Check that it's added to your target in Build Phases

### Push Notifications Not Working
- Make sure you're testing on a **physical device** (not simulator)
- Verify APNs key is uploaded to Firebase
- Check device notification permissions are granted

### FCM Token Not Generated
- Make sure Firebase is initialized in `didFinishLaunchingWithOptions`
- Check that `Messaging.messaging().delegate` is set
- Verify `GoogleService-Info.plist` has correct Bundle ID

---

## Verification Checklist

After completing all steps, verify:

- [ ] `GoogleService-Info.plist` is in the project
- [ ] Firebase packages are added (visible in Package Dependencies)
- [ ] Firebase imports are uncommented in code
- [ ] Push Notifications capability is added
- [ ] Background Modes with Remote notifications is enabled
- [ ] APNs key is uploaded to Firebase Console
- [ ] App builds without errors
- [ ] FCM token is generated when app runs
- [ ] FCM token is sent to backend (`POST /users/fcm-token`)

Once all checks are complete, FCM notifications should work! 🎉

