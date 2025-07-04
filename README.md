# IMM App - Inventory Movement Management

A modern Flutter-based inventory management application with Firebase integration and offline
support.

## 🚀 Features

### 📱 **Core Functionality**

- **Inventory Management**: Add, edit, delete, and search inventory items
- **Real-time Dashboard**: View statistics and analytics of your inventory
- **Category Management**: Organize items by categories with filtering
- **Data Persistence**: Hybrid storage system (Firebase Cloud + Local SQLite)

### 🔐 **Authentication**

- **Firebase Authentication**: Email/password authentication for cloud storage
- **Local Authentication**: Username/password for offline usage
- **Automatic Account Detection**: Seamlessly switches between Firebase and local accounts

### 🌐 **Cross-Platform Support**

- **Android**: Supports API 21+ (Android 5.0+)
- **iOS**: iPhone and iPad support
- **Web**: Progressive Web App capabilities
- **Desktop**: Windows, macOS, and Linux support

### 🔄 **Data Management**

- **Cloud Storage**: Firebase Firestore for authenticated users
- **Offline Support**: SQLite for local storage when offline
- **Data Sync**: Automatic synchronization between local and cloud data
- **User Isolation**: Each user has their own private inventory data

## 🛠️ **Setup Instructions**

### **Prerequisites**

- Flutter SDK (3.0.0 or higher)
- Dart SDK (2.17.0 or higher)
- Android Studio / VS Code
- Firebase project (for cloud features)

### **Installation**

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/imm-app.git
   cd imm-app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup** (Optional - for cloud features)
    - Create a Firebase project at [Firebase Console](https://console.firebase.google.com)
    - Enable Authentication and Firestore Database
    - Add your `google-services.json` to `android/app/`
    - Update `lib/firebase_options.dart` with your Firebase configuration

4. **Run the application**
   ```bash
   flutter run
   ```

## 📖 **Usage Guide**

### **Account Types**

#### **🔥 Firebase Account (Cloud Storage)**

- Sign up/in with email format: `user@example.com`
- Data automatically syncs to Firebase Cloud
- Access inventory from any device
- Requires internet connection for sync

#### **💾 Local Account (Offline Storage)**

- Sign in with username: `admin` / password: `admin`
- Data stored locally on device
- Works completely offline
- Perfect for demo and testing

### **Key Features**

1. **Dashboard**
    - View total items and quantities
    - Category breakdown
    - Quick statistics overview

2. **Inventory Management**
    - Add new items with details (name, category, quantity, description)
    - Edit existing items
    - Delete items with confirmation
    - Search and filter by category

3. **Multi-Platform Access**
    - Hamburger menu for navigation
    - Sign out options in multiple locations
    - Responsive design for different screen sizes

## 🏗️ **Project Structure**

```
lib/
├── main.dart                 # App entry point
├── firebase_options.dart     # Firebase configuration
├── models/                   # Data models
│   └── item.dart            # Inventory item model
├── pages/                    # UI screens
│   ├── login_page.dart      # Authentication screen
│   ├── signup_page.dart     # Registration screen
│   ├── home_page.dart       # Main application screen
│   └── item_form.dart       # Add/edit item form
├── services/                 # Business logic
│   ├── auth_service.dart    # Authentication management
│   ├── db_service.dart      # Local SQLite operations
│   ├── firebase_service.dart # Firebase operations
│   └── hybrid_service.dart  # Unified data service
└── widgets/                  # Reusable UI components
    ├── dashboard_stats.dart  # Statistics widget
    └── item_card.dart       # Item display widget
```

## 🔧 **Configuration**

### **Firebase Setup**

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create/select your project
3. Enable Authentication (Email/Password)
4. Enable Firestore Database
5. Set Firestore security rules:
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /users/{userId}/{document=**} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
     }
   }
   ```

### **Android Configuration**

- Minimum SDK: API 21 (Android 5.0)
- Target SDK: API 34
- Compile SDK: API 35
- Supports multidex for compatibility

## 📱 **Build Instructions**

### **Android APK**

```bash
flutter build apk --release
```

### **iOS IPA**

```bash
flutter build ios --release
```

### **Web**

```bash
flutter build web --release
```

### **Desktop**

```bash
flutter build windows --release  # Windows
flutter build macos --release    # macOS
flutter build linux --release    # Linux
```

## 🤝 **Contributing**

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 **Support**

For support and questions:

- Create an issue on GitHub
- Email: support@imm-app.com
- Documentation: [Wiki](https://github.com/your-username/imm-app/wiki)

## 🎯 **Roadmap**

- [ ] Barcode scanning for item input
- [ ] Export/Import functionality (CSV, Excel)
- [ ] Push notifications for low stock
- [ ] Multi-user collaboration
- [ ] Advanced reporting and analytics
- [ ] Dark mode support
- [ ] Tablet-optimized layouts

---

**Made with ❤️ using Flutter and Firebase**
