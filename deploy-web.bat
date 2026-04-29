@echo off
REM Field Survey App - Web Deployment Script
REM This script builds and deploys your Flutter app to Firebase Hosting

echo.
echo ============================================
echo  Field Survey App - Firebase Deployment
echo ============================================
echo.

REM Check if Flutter is installed
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo Error: Flutter is not installed or not in PATH
    pause
    exit /b 1
)

REM Check if Firebase CLI is installed
where firebase >nul 2>nul
if %errorlevel% neq 0 (
    echo Error: Firebase CLI is not installed
    echo Install it with: npm install -g firebase-tools
    pause
    exit /b 1
)

echo Step 1: Cleaning previous build...
call flutter clean

echo.
echo Step 2: Enabling web support...
call flutter config --enable-web

echo.
echo Step 3: Building web release...
call flutter build web --release

if %errorlevel% neq 0 (
    echo Error: Build failed
    pause
    exit /b 1
)

echo.
echo Step 4: Deploying to Firebase...
call firebase deploy

if %errorlevel% neq 0 (
    echo Error: Firebase deployment failed
    echo Make sure you've run: firebase login
    pause
    exit /b 1
)

echo.
echo ============================================
echo  Deployment Successful!
echo ============================================
echo.
echo Your app is now live!
echo.
echo Next steps:
echo 1. Note your Firebase URL from the output above
echo 2. Generate a QR code pointing to that URL
echo 3. Share the QR code with users
echo.
echo To generate QR code:
echo   npm install -g qrcode
echo   qrcode "YOUR_FIREBASE_URL"
echo.
pause
