# Security Notes

## API Keys

⚠️ **IMPORTANT**: Never commit API keys to the repository!

The `GEMINI_API_KEY` in `Info.plist` was previously committed and has been revoked by Google.

### To Fix:

**Option 1: Use Backend Only (Recommended for Production)**
- The app primarily uses the backend API (which has its own key in `.env`)
- The frontend key is only used as a fallback when backend fails
- You can leave `YOUR_GEMINI_API_KEY_HERE` as-is if you only want backend
- This is the safest option - no frontend key means no frontend key to leak

**Option 2: Use Same Key (Simple but Less Secure)**
- You CAN use the same key from backend `.env` in `Info.plist`
- Simpler to manage, but if frontend key leaks, backend is compromised too
- Replace `YOUR_GEMINI_API_KEY_HERE` with your backend key

**Option 3: Use Different Key (Best Security Practice)**
- Get a NEW API key from https://makersuite.google.com/app/apikey
- Use a DIFFERENT key than your backend key
- This provides security isolation - if one leaks, the other is safe
- Replace `YOUR_GEMINI_API_KEY_HERE` with your new frontend key

**For team members:**
- Copy `vet-tn-Info.plist.template` to `vet-tn-Info.plist` (if not already exists)
- Replace `YOUR_GEMINI_API_KEY_HERE` with your chosen key (or leave as placeholder)
- The actual `Info.plist` is tracked in git but now has a placeholder

3. **Remove leaked key from git history (if repo is public):**
   ```bash
   # Use git filter-branch or BFG Repo-Cleaner to remove the key from history
   # Or create a new repository if the key was exposed publicly
   ```

### Best Practice:
- Use environment variables or build-time configuration for secrets
- Keep `Info.plist` in `.gitignore` and use a template file
- Use separate keys for development and production
