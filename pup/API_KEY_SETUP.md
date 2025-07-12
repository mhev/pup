# API Key Setup Guide

This guide walks you through securely configuring your Google Gemini API key for the Pup app.

## Why This Approach?

- **Security**: API keys are kept out of version control
- **Team-friendly**: Each developer uses their own API key
- **Production-ready**: Supports environment variables for CI/CD
- **Fallback-safe**: App gracefully handles missing keys

## Step-by-Step Setup

### 1. Get Your Google Gemini API Key

1. Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Click "Create API Key"
4. Copy the generated API key

### 2. Create Your Secure Configuration File

1. In Finder, navigate to your project folder: `pup/Config/`
2. Copy `APIKeys.plist.template` and rename it to `APIKeys.plist`
3. Open `APIKeys.plist` in Xcode or a text editor
4. Replace `YOUR_GEMINI_API_KEY_HERE` with your actual API key:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>GeminiAPIKey</key>
    <string>AIzaSyBjgqsPWquP8d159a9NOEwm69zGJ9MFFmU</string>
</dict>
</plist>
```

### 3. Add APIKeys.plist to Your Xcode Project

**This is crucial - the file must be included in your Xcode project bundle:**

1. Open your project in Xcode
2. Right-click on the `Config` folder in the Project Navigator
3. Select "Add Files to 'pup'"
4. Navigate to `pup/Config/APIKeys.plist`
5. Select the file and click "Add"
6. **Important**: Make sure "Add to target" is checked for your main app target

### 4. Verify the Setup

1. Build and run your app
2. Check the Xcode console for one of these messages:
   - ✅ `Successfully loaded Gemini API key from APIKeys.plist`
   - ❌ `Warning: No Gemini API key found`

If you see the warning, double-check that:
- The `APIKeys.plist` file is in the correct location
- The file is added to your Xcode project target
- The XML format is correct
- Your API key is properly entered

### 5. Test API Key Validation

Add this code to your app startup to validate the configuration:

```swift
// In your App.swift or main view
if Config.validateAPIKey() {
    print("🚀 Ready to use Gemini AI optimization!")
} else {
    print("⚠️ Please configure your API key first")
}
```

## Security Features

### What's Protected

- ✅ `APIKeys.plist` - Excluded from Git automatically
- ✅ Your actual API key never appears in version control
- ✅ Each developer uses their own key
- ✅ Production deployments can use environment variables

### What's Safe to Commit

- ✅ `APIKeys.plist.template` - Template with placeholder
- ✅ `Config.swift` - Contains the loading logic, not the key
- ✅ `.gitignore` - Protects your sensitive files

## Troubleshooting

### "No Gemini API key found"

1. Verify `APIKeys.plist` exists in `pup/Config/`
2. Check that the file is added to your Xcode project
3. Ensure the XML format is correct
4. Verify your API key is valid (not the placeholder)

### "Bundle.main.path returned nil"

This means the `APIKeys.plist` file isn't included in your app bundle:

1. Select your project in Xcode
2. Go to your app target → Build Phases → Copy Bundle Resources
3. Add `APIKeys.plist` if it's not there

### API Key Not Working

1. Verify your API key is valid at [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Check that you have the Gemini API enabled
3. Ensure there are no extra spaces or characters in your key

## For Team Development

### Sharing the Project

When sharing with other developers:

1. **Never commit** your `APIKeys.plist` file
2. Share the `APIKeys.plist.template` file
3. Each developer creates their own `APIKeys.plist`
4. Document the setup process for your team

### CI/CD Integration

For automated builds, use environment variables:

```bash
export GEMINI_API_KEY="your_api_key_here"
```

The app will automatically use the environment variable if the plist file isn't available.

## Alternative: Environment Variables Only

If you prefer to use only environment variables:

1. Set the environment variable: `GEMINI_API_KEY=your_key_here`
2. The app will automatically detect and use it
3. No plist file needed

This approach is especially useful for:
- CI/CD pipelines
- Docker deployments
- Server-side Swift applications

## Best Practices

1. **Never hardcode API keys** in your source code
2. **Use different keys** for development and production
3. **Rotate keys regularly** for security
4. **Monitor API usage** in Google Cloud Console
5. **Set up billing alerts** to avoid unexpected charges

## Questions?

If you run into issues:
1. Check the console output for debugging messages
2. Verify the file structure matches the guide
3. Ensure the API key is valid and has the correct permissions
4. Review the Xcode project settings for bundle resources 