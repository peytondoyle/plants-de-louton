#!/bin/bash

# Setup script for Plants de Louton environment variables

echo "🌱 Plants de Louton Environment Setup"
echo "====================================="

# Check if .env file exists
if [ ! -f .env ]; then
    echo "Creating .env file..."
    touch .env
fi

# Prompt for OpenAI API key
echo ""
echo "Please enter your OpenAI API key:"
read -s OPENAI_API_KEY

# Add to .env file
echo "OPENAI_API_KEY=$OPENAI_API_KEY" > .env

echo ""
echo "✅ Environment variables configured!"
echo ""
echo "To use in Xcode:"
echo "1. Open your project in Xcode"
echo "2. Go to Product > Scheme > Edit Scheme"
echo "3. Select 'Run' on the left"
echo "4. Go to 'Arguments' tab"
echo "5. Under 'Environment Variables', add:"
echo "   Name: OPENAI_API_KEY"
echo "   Value: $OPENAI_API_KEY"
echo ""
echo "Or you can run the app from terminal with:"
echo "OPENAI_API_KEY=$OPENAI_API_KEY xcodebuild -project PlantsDeLouton.xcodeproj -scheme PlantsDeLouton -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build"
echo ""
echo "🌱 Your app is ready to use AI features!"
