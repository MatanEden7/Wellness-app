#!/bin/bash

# Setup script to add macOS support to the wellness app

echo "Setting up macOS support..."

# Create temporary project to copy macOS files
cd /tmp
rm -rf temp_wellness_macos 2>/dev/null

# Use the system Flutter if available, otherwise try common paths
FLUTTER_CMD=""
if command -v flutter &> /dev/null; then
    FLUTTER_CMD="flutter"
elif [ -f "/usr/local/bin/flutter" ]; then
    FLUTTER_CMD="/usr/local/bin/flutter"
elif [ -f "$HOME/flutter/bin/flutter" ]; then
    FLUTTER_CMD="$HOME/flutter/bin/flutter"
elif [ -f "$HOME/fvm/versions/3.22.2/bin/flutter" ]; then
    FLUTTER_CMD="$HOME/fvm/versions/3.22.2/bin/flutter"
else
    echo "Flutter not found. Please install Flutter or use FVM."
    exit 1
fi

echo "Using Flutter: $FLUTTER_CMD"

# Create temporary project
$FLUTTER_CMD create temp_wellness_macos --platforms=macos

if [ $? -eq 0 ]; then
    echo "Copying macOS files..."
    cp -r temp_wellness_macos/macos /Users/matan/Desktop/WellnessApp/
    
    # Update the macOS app name and bundle identifier
    sed -i '' 's/temp_wellness_macos/wellnessapp/g' /Users/matan/Desktop/WellnessApp/macos/Runner.xcodeproj/project.pbxproj
    sed -i '' 's/com.example.tempWellnessMacos/com.example.wellnessapp/g' /Users/matan/Desktop/WellnessApp/macos/Runner.xcodeproj/project.pbxproj
    
    echo "Cleaning up..."
    rm -rf temp_wellness_macos
    
    echo "macOS support added successfully!"
    echo "You can now run: fvm flutter run -d macos"
else
    echo "Failed to create temporary project"
    exit 1
fi
