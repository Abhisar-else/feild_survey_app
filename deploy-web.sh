#!/bin/bash

# Field Survey App - Web Deployment Script
# This script builds and deploys your Flutter app to Firebase Hosting

echo ""
echo "============================================"
echo " Field Survey App - Firebase Deployment"
echo "============================================"
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "Error: Flutter is not installed or not in PATH"
    exit 1
fi

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "Error: Firebase CLI is not installed"
    echo "Install it with: npm install -g firebase-tools"
    exit 1
fi

echo "Step 1: Cleaning previous build..."
flutter clean

echo ""
echo "Step 2: Enabling web support..."
flutter config --enable-web

echo ""
echo "Step 3: Building web release..."
flutter build web --release

if [ $? -ne 0 ]; then
    echo "Error: Build failed"
    exit 1
fi

echo ""
echo "Step 4: Deploying to Firebase..."
firebase deploy

if [ $? -ne 0 ]; then
    echo "Error: Firebase deployment failed"
    echo "Make sure you've run: firebase login"
    exit 1
fi

echo ""
echo "============================================"
echo " Deployment Successful!"
echo "============================================"
echo ""
echo "Your app is now live!"
echo ""
echo "Next steps:"
echo "1. Note your Firebase URL from the output above"
echo "2. Generate a QR code pointing to that URL"
echo "3. Share the QR code with users"
echo ""
echo "To generate QR code:"
echo "  npm install -g qrcode"
echo "  qrcode \"YOUR_FIREBASE_URL\""
echo ""
