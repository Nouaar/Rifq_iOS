# Fix "No such module 'Firebase'" Error

This error means Firebase packages aren't properly linked to your target. Here's how to fix it:

## Solution: Link Firebase Products to Your Target

### Step 1: Open Project Settings

1. **Open Xcode** with your project
2. **Select your project** in the Project Navigator (blue icon at the top)
3. **Select your target** "vet.tn" under TARGETS
4. Go to **"General"** tab
5. Scroll down to **"Frameworks, Libraries, and Embedded Content"** section

### Step 2: Add Firebase Products

1. Click the **"+"** button in the "Frameworks, Libraries, and Embedded Content" section
2. You should see a list including:
   - **FirebaseMessaging**
   - **FirebaseCore**
3. Select **FirebaseMessaging** and click **"Add"**
4. Select **FirebaseCore** and click **"Add"** (if not automatically added)
5. Make sure both are set to **"Do Not Embed"** (or "Embed & Sign" if required)

### Step 3: Verify Package Dependencies

1. Still in project settings, go to **"Package Dependencies"** tab
2. You should see **"firebase-ios-sdk"** listed
3. If you don't see it:
   - Click **"+"** to add package
   - Enter: `https://github.com/firebase/firebase-ios-sdk`
   - Select **FirebaseMessaging** and **FirebaseCore**
   - Click **Add Package**

### Step 4: Clean and Rebuild

1. **Clean Build Folder**:
   - Go to **Product** → **Clean Build Folder** (Shift + Cmd + K)

2. **Reset Package Caches** (if needed):
   - Go to **File** → **Packages** → **Reset Package Caches**
   - Wait for it to complete

3. **Resolve Package Versions**:
   - Go to **File** → **Packages** → **Resolve Package Versions**
   - Wait for it to complete

4. **Build the project**:
   - Press **Cmd + B** to build
   - Wait for build to complete (this may take a few minutes on first build)

### Step 5: Alternative - Re-add Package (If Above Doesn't Work)

1. Go to **Project Settings** → **Package Dependencies** tab
2. Select **firebase-ios-sdk** and click the **"-"** button to remove it
3. Click **"+"** to add package again
4. Enter: `https://github.com/firebase/firebase-ios-sdk`
5. Wait for Xcode to resolve the package
6. Select these products:
   - ✅ **FirebaseMessaging**
   - ✅ **FirebaseCore**
7. Make sure **"Add to Target: vet.tn"** is checked
8. Click **"Add Package"**

## Quick Checklist

- [ ] Firebase packages are in Package Dependencies tab
- [ ] FirebaseMessaging is in "Frameworks, Libraries, and Embedded Content"
- [ ] FirebaseCore is in "Frameworks, Libraries, and Embedded Content"  
- [ ] Clean build folder completed
- [ ] Package caches reset (if needed)
- [ ] Project builds without errors (Cmd + B)

## If Still Not Working

1. **Close Xcode completely**
2. **Delete derived data**:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```
3. **Reopen Xcode**
4. **Clean build folder** again
5. **Build the project**

The error should be resolved after linking the products and rebuilding!

