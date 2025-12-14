# QuadConnect - Student Social Network

A comprehensive Flutter-based social networking app designed for students to connect, share, and engage with campus life.

## 📱 Features

### Core Features
- ✅ **Authentication**: Secure email/password authentication with Firebase
- ✅ **User Profiles**: Customizable profiles with bio, social links, and profile pictures
- ✅ **Dynamic News Feed**: Instagram-style feed with posts, images, videos, and text
- ✅ **Social Engagement**: Like, comment, and share posts
- ✅ **Direct Messaging**: Real-time chat with images, emojis, replies, and read receipts
- ✅ **Campus Events**: Create, discover, and RSVP to campus events
- ✅ **Push Notifications**: Real-time notifications for likes, comments, shares, and events
- ✅ **Search**: Search users, posts, and events

### Advanced Features
- ✅ **Image/Video Posts**: Upload photos and videos
- ✅ **Custom Text Backgrounds**: Create colorful text posts
- ✅ **Comment Threading**: Reply to comments with nested conversations
- ✅ **Read Receipts**: See when messages are read
- ✅ **Typing Indicators**: Know when someone is typing
- ✅ **Message Replies**: Reply to specific messages
- ✅ **Emoji Support**: Full emoji picker in messages
- ✅ **Event Categories & Tags**: Organize events with categories and tags
- ✅ **Event Capacity**: Set and enforce attendee limits

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.9.2 or higher)
- Dart SDK
- Firebase account
- Android Studio / Xcode (for mobile development)
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd quadconnect
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Enable Authentication (Email/Password)
   - Enable Cloud Firestore
   - Enable Firebase Storage
   - Enable Firebase Cloud Messaging
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place them in:
     - `android/app/google-services.json`
     - `ios/Runner/GoogleService-Info.plist`

4. **Configure Firebase Options**
   ```bash
   flutterfire configure
   ```
   Or manually create `lib/firebase_options.dart` with your Firebase configuration.

5. **Deploy Firebase Rules**
   ```bash
   # Deploy Firestore rules
   firebase deploy --only firestore:rules
   
   # Deploy Storage rules
   firebase deploy --only storage
   ```

6. **Run the app**
   ```bash
   flutter run
   ```

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── user_model.dart
│   ├── post_model.dart
│   ├── comment_model.dart
│   ├── event_model.dart
│   └── chat_message_model.dart
├── screens/                  # UI screens
│   ├── login_page.dart
│   ├── feed_page.dart
│   ├── profile_page.dart
│   ├── create_post_page.dart
│   ├── comments_page.dart
│   ├── chat_page.dart
│   ├── messages_page.dart
│   ├── events_page.dart
│   ├── create_event_page.dart
│   ├── search_page.dart
│   └── notifications_page.dart
├── services/                 # Business logic
│   ├── auth_service.dart
│   ├── user_service.dart
│   ├── post_service.dart
│   ├── comment_service.dart
│   ├── message_service.dart
│   ├── event_service.dart
│   ├── notification_service.dart
│   └── share_service.dart
├── widgets/                  # Reusable widgets
│   ├── post_card.dart
│   ├── share_bottom_sheet.dart
│   ├── skeleton_loader.dart
│   └── ...
├── theme/                    # App theming
│   └── app_theme.dart
└── utils/                    # Utilities
    ├── error_messages.dart
    ├── responsive.dart
    └── page_transitions.dart
```

## 🔧 Configuration

### Firebase Configuration

#### Firestore Rules
Located in `firestore.rules`. Deploy with:
```bash
firebase deploy --only firestore:rules
```

#### Storage Rules
Located in `storage.rules`. Deploy with:
```bash
firebase deploy --only storage
```

#### Firestore Indexes
Located in `firestore.indexes.json`. Deploy with:
```bash
firebase deploy --only firestore:indexes
```

### Android Configuration

1. **Minimum SDK**: 21 (Android 5.0)
2. **Target SDK**: 33+
3. **Permissions**: Already configured in `AndroidManifest.xml`
   - Internet
   - Camera
   - Storage

### iOS Configuration

1. **Minimum iOS**: 12.0
2. **Permissions**: Configure in `Info.plist`
   - Camera usage
   - Photo library access

## 🏗️ Building for Production

### Android APK
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (for Play Store)
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

### iOS
```bash
flutter build ios --release
```

## 📦 Dependencies

### Core Dependencies
- `firebase_core`: Firebase initialization
- `firebase_auth`: Authentication
- `cloud_firestore`: Database
- `firebase_storage`: File storage
- `firebase_messaging`: Push notifications

### UI & Utilities
- `cached_network_image`: Optimized image loading
- `image_picker`: Camera/gallery access
- `emoji_picker_flutter`: Emoji picker
- `share_plus`: Sharing functionality
- `url_launcher`: Open URLs
- `timeago`: Relative time formatting
- `intl`: Internationalization

## 🔐 Security

- All Firebase rules are configured for security
- User authentication required for sensitive operations
- Ownership validation for edits/deletes
- Secure file uploads with validation

## 🧪 Testing

### Run Tests
```bash
flutter test
```

### Test Coverage
- Unit tests for services
- Widget tests for UI components
- Integration tests for critical flows

## 📊 Performance Optimizations

- ✅ Image caching with `CachedNetworkImage`
- ✅ Optimized memory usage (memCacheWidth/Height)
- ✅ Client-side filtering to avoid composite indexes
- ✅ Efficient real-time streams
- ✅ Skeleton loaders for better UX
- ✅ Lazy loading for lists

## 🐛 Troubleshooting

### Common Issues

1. **Firebase not initialized**
   - Ensure `firebase_options.dart` exists
   - Check Firebase project configuration

2. **Image upload fails**
   - Check Firebase Storage is enabled
   - Verify Storage rules are deployed
   - Check billing plan (Blaze plan required)

3. **Notifications not working**
   - Ensure FCM is configured
   - Check notification permissions
   - Verify `google-services.json` is correct

4. **Build errors**
   - Run `flutter clean`
   - Run `flutter pub get`
   - Check Flutter version compatibility

## 📝 API Documentation

### Firebase Services

#### Authentication
- Email/Password authentication
- User registration and login
- Session management

#### Firestore Collections
- `users`: User profiles
- `posts`: User posts
- `comments`: Post comments
- `messages`: Direct messages
- `events`: Campus events
- `notifications`: User notifications

#### Storage Paths
- `profile_images/`: Profile pictures
- `images/`: Post images
- `videos/`: Post videos
- `messages/`: Message images

## 🎨 Design System

- **Primary Color**: Blue
- **Background**: White
- **Text**: Black/Grey scale
- **Icons**: Material Design Icons

## 📄 License

This project is for educational purposes.

## 👥 Contributors

- Development Team

## 📞 Support

For issues and questions, please contact the development team.

---

**Version**: 2.0.0  
**Last Updated**: 2024
