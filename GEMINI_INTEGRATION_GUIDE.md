# Google Gemini Integration Guide

## How Google Gemini Works

### Overview
Google Gemini is a multimodal AI model that can understand and generate text. For this app, we're using **Gemini 1.5 Flash** which is:
- **Fast**: Optimized for quick responses
- **Free Tier**: 15 requests/minute, 1M tokens/day
- **Context-Aware**: Can understand complex prompts with pet medical history

### How It Works
1. **API Request**: Your app sends a prompt (text) to Google's API
2. **AI Processing**: Gemini analyzes the prompt and generates a response
3. **Response**: Returns text that you parse and display

### API Flow
```
Your App → HTTP POST → Google Gemini API → JSON Response → Parsed Text → Display
```

## Setup Instructions

### Step 1: Get Your API Key
1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Click "Create API Key"
4. Copy the API key

### Step 2: Add API Key to Info.plist
1. Open `vet-tn-Info.plist`
2. Add a new key: `GEMINI_API_KEY`
3. Set the value to your API key

```xml
<key>GEMINI_API_KEY</key>
<string>YOUR_API_KEY_HERE</string>
```

### Step 3: Add Package Dependency (if needed)
The current implementation uses URLSession, so no additional packages are required. However, if you want to use the official SDK later:

```swift
// In Package.swift or Xcode Package Manager
dependencies: [
    .package(url: "https://github.com/google/generative-ai-swift", from: "0.1.0")
]
```

## Integration Architecture

### Files Created
1. **GeminiService.swift** - Handles API communication
2. **PetAIViewModel.swift** - Manages AI interactions for pets

### How It's Used

#### 1. Tips Generation
```swift
let viewModel = PetAIViewModel()
await viewModel.generateTips(for: pet)
// Access tips via: viewModel.tips
```

#### 2. Recommendations
```swift
await viewModel.generateRecommendations(for: pet)
// Access via: viewModel.recommendations
```

#### 3. Reminders
```swift
await viewModel.generateReminders(for: pet)
// Access via: viewModel.reminders
```

## Usage Examples

### In PetProfileView
```swift
@StateObject private var aiViewModel = PetAIViewModel()

// Generate tips when view appears
.onAppear {
    Task {
        await aiViewModel.generateTips(for: pet)
    }
}

// Display tips
if !aiViewModel.tips.isEmpty {
    ForEach(aiViewModel.tips, id: \.self) { tip in
        Text(tip)
    }
}
```

### Custom Prompts
You can extend `GeminiService` to create custom prompts:

```swift
func generateCustomResponse(prompt: String) async throws -> String {
    return try await geminiService.generateText(
        prompt: prompt,
        temperature: 0.7,
        maxTokens: 500
    )
}
```

## Features

### 1. Tips
- **Input**: Pet info + medical history
- **Output**: 3-5 daily care tips
- **Use Case**: Show in pet profile or home screen

### 2. Recommendations
- **Input**: Pet info + medical history
- **Output**: Vaccination schedules, medication reminders, check-ups
- **Use Case**: Health recommendations section

### 3. Reminders
- **Input**: Pet info + medications + vaccinations
- **Output**: Specific reminders with timing
- **Use Case**: Auto-generate calendar reminders

## Cost & Limits

### Free Tier
- **15 requests per minute**
- **1 million tokens per day**
- **No credit card required**

### Rate Limiting
The service automatically handles rate limits. If you exceed:
- Wait 1 minute before retrying
- Implement caching (same pet = same recommendations)

## Best Practices

### 1. Caching
Cache responses for the same pet to reduce API calls:
```swift
private var cachedTips: [String: [String]] = [:]

func getCachedTips(for petId: String) -> [String]? {
    return cachedTips[petId]
}
```

### 2. Error Handling
Always handle errors gracefully:
```swift
if let error = aiViewModel.error {
    Text("Error: \(error)")
        .foregroundColor(.red)
}
```

### 3. Loading States
Show loading indicators:
```swift
if aiViewModel.isLoading {
    ProgressView()
} else {
    // Show results
}
```

### 4. Prompt Optimization
- Be specific about what you want
- Include all relevant context (medical history)
- Use clear formatting instructions

## Security

### API Key Security
- **Never commit API keys to Git**
- Store in Info.plist (not in code)
- Use environment variables for CI/CD
- Rotate keys if exposed

### Data Privacy
- Pet medical data is sent to Google's servers
- Review Google's privacy policy
- Consider on-device models for sensitive data

## Troubleshooting

### "API Key Missing" Error
- Check Info.plist has `GEMINI_API_KEY`
- Verify key is not empty
- Restart app after adding key

### Rate Limit Errors
- Implement request queuing
- Add delays between requests
- Cache responses

### Empty Responses
- Check prompt format
- Verify API key is valid
- Check network connection

## Next Steps

1. **Add API Key** to Info.plist
2. **Test the service** with a simple prompt
3. **Integrate into views** (PetProfileView, HomeView)
4. **Add caching** for better performance
5. **Monitor usage** to stay within free tier

## Example Integration Points

### PetProfileView
- Show AI tips in a card
- Generate recommendations on demand
- Display reminders section

### HomeView
- Daily tips carousel
- Health recommendations
- Upcoming reminders

### Calendar Integration
- Auto-generate reminders from AI recommendations
- Suggest vaccination dates
- Medication schedule optimization

