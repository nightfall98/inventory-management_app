# Firebase Setup Guide for IMM App

This guide will help you set up Firebase for the Inventory Movement Management (IMM) App.

## 🔥 Firebase Integration Features

The IMM App now supports:

- **Firebase Authentication**: Secure user login/signup with email/password
- **Cloud Firestore**: Real-time database for inventory items
- **Offline Support**: Automatic sync between local SQLite and Firebase
- **User-specific Data**: Each user has their own inventory collection
- **Real-time Updates**: Live sync across devices

## 📋 Prerequisites

1. **Flutter SDK** installed on your machine
2. **Google Account** for Firebase Console access
3. **Node.js** (for Firebase CLI - optional but recommended)

## 🚀 Step-by-Step Setup

### Step 1: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Enter project name: `imm-app-[your-name]`
4. Enable Google Analytics (optional)
5. Click "Create project"

### Step 2: Enable Authentication

1. In Firebase Console, go to **Authentication**
2. Click **Get started**
3. Go to **Sign-in method** tab
4. Enable **Email/Password** authentication
5. Click **Save**

### Step 3: Set up Firestore Database

1. In Firebase Console, go to **Firestore Database**
2. Click **Create database**
3. Choose **Start in test mode** (for development)
4. Select a location (choose closest to your users)
5. Click **Done**

### Step 4: Add Firebase to your Flutter app

#### Option A: Using Firebase CLI (Recommended)

1. Install Firebase CLI:
   ```bash
   npm install -g firebase-tools
   ```

2. Install FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```

3. Login to Firebase:
   ```bash
   firebase login
   ```

4. Configure Firebase for your project:
   ```bash
   flutterfire configure
   ```
    - Select your Firebase project
    - Choose platforms (Web, Android, iOS, Windows, macOS)
    - This will generate `firebase_options.dart` automatically

#### Option B: Manual Configuration

1. **For Web Platform:**
    - Go to Project Settings > General
    - Scroll to "Your apps" section
    - Click "Web" icon
    - Register app with nickname: `imm-app-web`
    - Copy the configuration object

2. **For Android:**
    - Click "Android" icon
    - Package name: `com.example.imm_app`
    - Download `google-services.json`
    - Place it in `android/app/`

3. **For iOS:**
    - Click "iOS" icon
    - Bundle ID: `com.example.immApp`
    - Download `GoogleService-Info.plist`
    - Add to `ios/Runner/`

4. **Update `firebase_options.dart`:**
   Replace the demo values in `lib/firebase_options.dart` with your actual Firebase config values.

### Step 5: Update Firebase Configuration

Edit `lib/firebase_options.dart` and replace the demo values with your actual Firebase project
configuration:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'your-web-api-key',
  appId: 'your-web-app-id',
  messagingSenderId: 'your-sender-id',
  projectId: 'your-project-id',
  authDomain: 'your-project-id.firebaseapp.com',
  storageBucket: 'your-project-id.appspot.com',
  measurementId: 'your-measurement-id',
);

static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'your-android-api-key',
  appId: 'your-android-app-id',
  messagingSenderId: 'your-sender-id',
  projectId: 'your-project-id',
  storageBucket: 'your-project-id.appspot.com',
);

// Similar for iOS, macOS, and Windows...
```

### Step 6: Set up Firestore Security Rules

1. Go to **Firestore Database** > **Rules**
2. Replace the default rules with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Allow access to user's items subcollection
      match /items/{itemId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

3. Click **Publish**

### Step 7: Run the App

1. Get dependencies:
   ```bash
   flutter pub get
   ```

2. Run the app:
   ```bash
   flutter run
   ```

## 🔧 App Functionality

### Authentication Flow

1. **Offline Mode**: Users can use the app without signing in (data stored locally in SQLite)
2. **Sign Up**: Create new account with email/password
3. **Sign In**: Login with existing credentials
4. **Auto-sync**: Local data automatically syncs to Firebase upon login

### Data Storage

- **SQLite (Offline)**: When not authenticated, data is stored locally
- **Firebase (Online)**: When authenticated, data is stored in Firestore
- **Hybrid Mode**: App intelligently switches between local and cloud storage

### Features Available

#### Offline (SQLite)

- ✅ Add, edit, delete items
- ✅ Search and filter
- ✅ Category management
- ✅ Dashboard statistics
- ✅ All core functionality

#### Online (Firebase)

- ✅ All offline features
- ✅ Real-time sync across devices
- ✅ User authentication
- ✅ Data backup in cloud
- ✅ Multi-device access

## 🛠️ Testing

### Test Accounts

For testing, you can create accounts with:

- Email: `test@example.com`
- Password: `password123`

### Demo Data

The app includes sample data for testing:

- Sample Laptop (Electronics)
- Office Chairs (Office)

## 🔒 Security Features

1. **User Authentication**: Email/password authentication
2. **Data Isolation**: Each user can only access their own data
3. **Secure Rules**: Firestore security rules prevent unauthorized access
4. **Local Storage**: SQLite for offline functionality

## 📱 Platform Support

- ✅ **Windows** (Desktop)
- ✅ **Web** (Browser)
- ✅ **Android** (Mobile)
- ✅ **iOS** (Mobile)
- ✅ **macOS** (Desktop)

## 🎯 Production Considerations

### Before deploying to production:

1. **Update Security Rules**: Make them more restrictive
2. **Enable App Check**: Add additional security layer
3. **Set up Monitoring**: Use Firebase Analytics and Crashlytics
4. **Optimize Queries**: Add proper indexing for Firestore queries
5. **Environment Variables**: Store sensitive configuration securely

### Firestore Indexes

For better performance, create indexes for:

```
Collection: users/{userId}/items
- category (Ascending) + created_at (Descending)
- name (Ascending)
```

## 🆘 Troubleshooting

### Common Issues:

1. **Build Errors**:
    - Run `flutter clean && flutter pub get`
    - Check if all dependencies are properly installed

2. **Authentication Errors**:
    - Verify Firebase configuration
    - Check if email/password auth is enabled

3. **Firestore Permission Errors**:
    - Verify security rules
    - Ensure user is properly authenticated

4. **Windows Build Issues**:
    - Make sure Windows desktop support is enabled
    - Check if all Windows dependencies are installed

### Getting Help

1. Check Firebase Console for error logs
2. Use Flutter DevTools for debugging
3. Review Firestore security rules
4. Check network connectivity

## 🚀 Next Steps

After Firebase setup:

1. **Customize**: Modify the app to fit your specific needs
2. **Deploy**: Deploy to your preferred platforms
3. **Monitor**: Set up Firebase Analytics
4. **Scale**: Optimize for production use

---

**Need help?** Check the [Firebase Documentation](https://firebase.google.com/docs)
or [Flutter Firebase Documentation](https://firebase.flutter.dev/).

🎉 **Congratulations!** Your IMM App is now connected to Firebase with full offline/online hybrid
functionality!