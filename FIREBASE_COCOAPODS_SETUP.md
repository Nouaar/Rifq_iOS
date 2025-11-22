# Firebase Setup Using CocoaPods (Alternative Method)

If Swift Package Manager is taking too long or hanging, CocoaPods is a more reliable alternative for Firebase.

## Step 1: Install CocoaPods (if not already installed)

1. Open **Terminal**
2. Run this command:
   ```bash
   sudo gem install cocoapods
   ```
3. Enter your password when prompted
4. Wait for installation to complete

## Step 2: Navigate to Your Project Directory

In Terminal:
```bash
cd /Users/mac/Rifq_iOS
```

## Step 3: Create Podfile

1. In Terminal, run:
   ```bash
   pod init
   ```

2. This creates a `Podfile` in your project directory

## Step 4: Edit Podfile

1. Open `Podfile` in a text editor or Terminal:
   ```bash
   open -a TextEdit Podfile
   ```
   Or use your preferred editor

2. Find the section for your `vet.tn` target and add Firebase dependencies:

   ```ruby
   platform :ios, '15.0'  # or your minimum iOS version

   target 'vet.tn' do
     # Add Firebase dependencies here
     pod 'Firebase/Messaging'
     pod 'Firebase/Core'
     
     # Your existing pods (if any)
   end
   ```

3. Save and close the file

## Step 5: Install Pods

In Terminal, run:
```bash
pod install
```

This will:
- Download Firebase SDK and dependencies
- Create a `.xcworkspace` file
- Set up the project structure

**Note**: This may take several minutes depending on your internet connection.

## Step 6: Open Workspace (IMPORTANT!)

**Critical**: After installing CocoaPods, you must open the `.xcworkspace` file, NOT the `.xcodeproj` file!

1. Close Xcode if it's open
2. Open Terminal and run:
   ```bash
   open vet.tn.xcworkspace
   ```
   
   OR double-click `vet.tn.xcworkspace` in Finder

3. Always use the `.xcworkspace` file from now on!

## Step 7: Verify Installation

1. In Xcode, check **Project Navigator** (left sidebar)
2. You should see a new **Pods** folder
3. Expand it to see Firebase frameworks:
   - FirebaseMessaging
   - FirebaseCore
   - etc.

## Step 8: Update Code to Use Firebase

Now you can uncomment the Firebase imports in your code:
- `FCMManager.swift`
- `vet_tnApp.swift`

The imports should work:
```swift
import Firebase
import FirebaseMessaging
```

## Troubleshooting

### If `pod install` fails:
1. Try updating CocoaPods repo:
   ```bash
   pod repo update
   ```

2. Clear CocoaPods cache:
   ```bash
   pod cache clean --all
   pod install
   ```

### If you get "No such module 'Firebase'":
- Make sure you opened `.xcworkspace`, not `.xcodeproj`
- Clean build folder: **Product > Clean Build Folder** (Shift+Cmd+K)
- Build again: **Product > Build** (Cmd+B)

### To remove CocoaPods later (if needed):
```bash
pod deintegrate
rm Podfile
rm Podfile.lock
rm -rf Pods/
rm -rf .xcworkspace
```

---

## Comparison: CocoaPods vs SPM

| Feature | CocoaPods | Swift Package Manager |
|---------|-----------|----------------------|
| Speed | Usually faster | Can hang on large packages |
| Reliability | Very reliable | Sometimes problematic |
| File Type | `.xcworkspace` | `.xcodeproj` |
| Setup | Requires `pod install` | Built into Xcode |

For Firebase specifically, **CocoaPods is often the better choice** because:
- More stable for large packages
- Better tested with Firebase
- Faster downloads
- More reliable caching

