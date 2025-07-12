# Pup - AI-Powered Route Optimization for Pet Care

A SwiftUI app that helps dog walkers and pet sitters optimize their daily routes using Google Gemini AI.

## Features

- 🏠 **Home Base Management**: Set your starting location (current location or manual address)
- 🗓️ **Visit Scheduling**: Add visits with flexible time windows and service types
- 🤖 **AI Route Optimization**: Powered by Google Gemini for intelligent route planning
- 🗺️ **Interactive Map**: Visualize your optimized route with custom markers
- 📊 **Efficiency Metrics**: Track distance, travel time, and optimization scores

## Setup

### Google Gemini API Configuration

1. **Get Your API Key**:
   - Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
   - Create a new API key for Gemini

2. **Add Your API Key**:
   - Open `pup/Config/Config.swift`
   - Replace `YOUR_GEMINI_API_KEY_HERE` with your actual API key:
   ```swift
   static let geminiAPIKey = "your_actual_api_key_here"
   ```

3. **Build and Run**:
   - The app will automatically use Gemini AI for route optimization
   - If the API fails, it falls back to basic time-based optimization

## How It Works

### Route Optimization Process

1. **Input Data**: The app sends Gemini your:
   - Home base location
   - Visit addresses and time windows
   - Service types and durations
   - Special notes for each visit

2. **AI Analysis**: Gemini considers:
   - Time window constraints
   - Travel time between locations
   - Traffic patterns (Austin, TX)
   - Service durations
   - Overall efficiency

3. **Optimized Results**: Get back:
   - Optimal visit order
   - Distance and time estimates
   - Efficiency score
   - AI reasoning explanation

### Example Usage

```
Home Base: 123 Main St, Austin, TX

Visits:
1. Max (Sarah Johnson) - 456 Downtown Ave - 1:30-3:00 PM - Dog Walk
2. Luna (Mike Chen) - 789 North Blvd - 3:00-4:00 PM - Pet Sitting  
3. Buddy (Emily) - 321 South St - 11:00 AM-12:00 PM - Drop-in

AI Result: Visit order [3, 1, 2] for optimal efficiency
```

## Privacy & Data

- Your location data is only used for route calculation
- Visit information is sent to Google Gemini for optimization
- No data is stored permanently on external servers
- All personal information remains on your device

## Requirements

- iOS 16.0+
- Xcode 15.0+
- Google Gemini API key
- Location permissions for optimal routing

## License

This project is for educational and personal use. 