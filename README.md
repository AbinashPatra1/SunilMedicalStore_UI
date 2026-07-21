# sunil_medical_store

A new Flutter project.

## Project purpose
<!-- Add project purpose here -->

## Features
<!-- Add features here -->

## Tech stack
<!-- Add tech stack here -->

## Folder structure
<!-- Add folder structure here -->

## How to run
Step 1: Check Flutter

Open a terminal in your project and run:

flutter doctor

Ideally, you should see green checkmarks for:

✅ Flutter
✅ Android toolchain
✅ Android Studio
✅ Connected device (once the emulator is running)

If there are any errors, fix those first.

Step 2: Start an Android Emulator
Option 1: From Android Studio (Recommended)
Open Android Studio.
Click More Actions (or Tools) → Device Manager.
If you already have a virtual device, click the ▶ Play button.
Wait for Android to boot completely.

If you don't have one yet:

Click Create Device
Select a device (e.g. Pixel 8 or Pixel 9)
Download a system image if prompted
Finish the wizard
Start the emulator
Step 3: Verify Flutter Sees It

Run:

flutter devices

Example output:

Found 2 connected devices:

Android SDK built for x86 (mobile)
Windows (desktop)

If your emulator appears, you're ready.

Step 4: Run the App

From your project directory:

flutter run

Flutter will:

Build the app
Install it on the emulator
Launch it automatically

The first build may take a few minutes.

Step 5: Hot Reload

Once the app is running:

Press:

r

to perform a Hot Reload.

Or, if you're using VS Code:

F5 to start debugging
Click the Hot Reload button, or save a file if Auto Save is enabled

Hot Reload updates the UI almost instantly without restarting the app.

Using VS Code

If you're using VS Code:

Open your Flutter project.
Press Ctrl + Shift + P.
Run Flutter: Select Device.
Choose your emulator.
Press F5 or click Run > Start Debugging.

VS Code will build and launch the app.

If Flutter Doesn't Detect the Emulator

Run:

flutter emulators

Example:

2 available emulators:

Pixel_9_API_36
Medium_Phone_API_35

Start one with:

flutter emulators --launch Pixel_9_API_36

Replace Pixel_9_API_36 with the name shown on your machine.

Useful Commands
flutter devices          # List connected devices
flutter emulators        # List available emulators
flutter run              # Run the app
flutter clean            # Clean build artifacts
flutter pub get          # Install dependencies
flutter doctor           # Check environment
If You Get an Error

If flutter run fails, send me the output of these two commands:

flutter doctor

and

flutter devices
