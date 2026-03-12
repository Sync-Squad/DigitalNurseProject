# Fix for Gemini API Key 403 Error

## Problem
The Gemini API key has been reported as leaked by Google and is returning a 403 error:
```
Your API key was reported as leaked. Please use another API key.
```

## Solution

### Step 1: Get a New Gemini API Key

1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey) or [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
2. Create a new API key for Gemini
3. **Important**: Restrict the API key to only the Gemini API to prevent abuse

### Step 2: Update the API Key in the Database

You have two options:

#### Option A: Using the API Endpoint (Recommended)

Use the new PUT endpoint to update the key:

```bash
curl -X PUT http://your-api-url/api/config/gemini-api-key \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{"apiKey": "YOUR_NEW_API_KEY"}'
```

#### Option B: Direct Database Update

Update directly in the database:

```sql
UPDATE "AppConfig" 
SET "configValue" = 'YOUR_NEW_API_KEY', 
    "updatedAt" = NOW()
WHERE "configKey" = 'gemini_api_key';
```

### Step 3: Clear Cached Key in Mobile App

The mobile app caches the API key locally. You need to clear it:

#### Option A: Re-login
Simply log out and log back in. The app will fetch the new key from the database.

#### Option B: Programmatically Clear
If you have access to the app code, you can call:
```dart
await AppConfig.clearDatabaseCachedGeminiApiKey();
await ConfigService().clearCachedGeminiApiKey();
```

#### Option C: Clear App Data
On Android: Settings → Apps → Digital Nurse → Storage → Clear Data
On iOS: Delete and reinstall the app

## Changes Made

1. **Backend**: Added `PUT /api/config/gemini-api-key` endpoint to update the API key
2. **Mobile**: Added `clearCachedGeminiApiKey()` method to ConfigService
3. **Mobile**: Removed hardcoded default API key (security improvement)
4. **Mobile**: Updated API key retrieval logic to prioritize database key

## Prevention

To prevent this issue in the future:

1. **Never commit API keys to version control**
2. **Use environment variables or secure storage** for API keys
3. **Restrict API keys** in Google Cloud Console to specific APIs and IPs
4. **Rotate API keys regularly**
5. **Monitor API usage** for unusual activity

## Testing

After updating the key:

1. Clear the cached key in the mobile app (re-login)
2. Try using a Gemini feature (e.g., food analysis)
3. Check logs to confirm the new key is being used
4. Verify no 403 errors occur

## Notes

- The old hardcoded default key has been removed for security
- The app will now only use keys from the database or environment variables
- All API key updates require authentication (JWT token)

