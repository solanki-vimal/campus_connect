# 🎓 CampusConnect — Your Campus, Connected

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Cloudinary](https://img.shields.io/badge/Cloudinary-Image%20Storage-3448C5?logo=cloudinary&logoColor=white)](https://cloudinary.com)
[![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white)](https://developer.android.com)

**CampusConnect** is a centralized college utility and communication mobile application powered by Flutter and Firebase. Built with a **decentralized content management model**, authorized faculty and club coordinators manage notices and events relevant to their specific department or club, eliminating the bottleneck of a single central administrator while keeping students connected to campus life in real time.

---

## 📱 Key Features & Modules

### 🔐 1. Authentication & Role-Based Access Control (RBAC)
- **Institutional Domain Gating:** Registration is restricted to verified university emails (e.g. `@ddu.ac.in`).
- **Four Distinct Role Dashboards:**
  - **Student:** Immediate access; department-filtered notices, event discovery & RSVP, lost & found feed.
  - **Faculty:** Publish department-targeted or college-wide notices, create events, and moderate content. Requires Super Admin verification.
  - **Club Coordinator:** Create club events and monitor attendee registrations. Requires Super Admin verification.
  - **Super Admin:** Approve/reject faculty and club coordinator accounts, manage university metadata, and view analytics.
- **Dedicated Forgot Password Flow:** In-app reset request with automatic email validation and pre-fill integration.

### 📢 2. Notices Module
- **Targeted Audiences:** Filter notices between **College-Wide (General)** and specific **Departmental** channels.
- **Priority Tags:** Visual badges for Normal, Important, and Urgent notices.
- **Moderation:** Faculty and administrators can edit or delete notices directly with full safety dialogs.

### 📅 3. Events & In-App Registration (RSVP)
- **Interactive Event Discovery:** Upcoming events display with calendar date blocks, schedules, and venue indicators.
- **One-Tap In-App Registration:** Students can reserve a spot in upcoming workshops or activities.
- **Capacity Management:** Enforces attendee limits dynamically; organizers can view registered students via the **Registrants View**.

### 🔍 4. Lost & Found Module
- **Photo Uploads:** Snap a photo directly using the **Camera** or pick from the **Gallery**.
- **Cloud Storage:** Integrated with Cloudinary for fast, secure image delivery without expensive cloud dependencies.
- **Interactive Viewer:** Tap any item photo to inspect details with full-screen pinch-to-zoom.
- **Lifecycle Management:** Filter between Lost, Found, and My Reports, and mark items as resolved once claimed.

### 🔔 5. Real-Time In-App Notification Feed
- **Live Unread Bell Badge:** An interactive notification bell with a live red badge indicator in every dashboard's top bar.
- **Automated Firestore Fan-Out:** Automatic notifications created for relevant students whenever a new notice or event is published.
- **Deep Linking:** Tap any notification to jump directly into the full notice or event detail screen.

### ⚙️ 6. Administration & Metadata Management
- **User Governance:** Review pending faculty and club coordinator registrations with single-tap Approve, Reject, or Role Change actions.
- **Dynamic Configuration:** Add, edit, or remove Departments, Event Categories, Notice Categories, and Clubs on the fly without updating app code.
- **College Analytics:** Live counts of active users, notices posted, and organized events.

---

## 🛠️ Architecture & Tech Stack

```
lib/
├── firebase_options.dart          # Platform Firebase configuration
├── main.dart                      # App entry point, theme & providers
├── models/                        # Domain data models with serialization
│   ├── app_notification.dart
│   ├── app_user.dart
│   ├── event.dart
│   ├── event_registration.dart
│   ├── lost_item.dart
│   ├── notice.dart
│   └── user_profile.dart
├── providers/                     # State management (Provider)
│   └── user_provider.dart
├── screens/                       # Application views grouped by feature
│   ├── admin/                     # User management & metadata settings
│   ├── auth/                      # Login, Signup, Forgot Password
│   ├── auth_gate.dart             # Real-time auth & role routing
│   ├── club_coordinator/          # Club coordinator dashboard
│   ├── events/                    # List, details, create/edit, registrants
│   ├── faculty/                   # Faculty dashboard
│   ├── lost_found/                # List, report, details with zoom
│   ├── notices/                   # List, details, create/edit
│   ├── notifications/             # Notification feed screen
│   ├── pending_approval_screen.dart
│   ├── profile/                   # View profile & edit bio/contact
│   └── student/                   # Student dashboard
├── services/                      # Backend & business logic services
│   ├── admin_settings_service.dart
│   ├── auth_service.dart
│   ├── event_service.dart
│   ├── image_upload_service.dart  # Cloudinary REST integration
│   ├── in_app_notification_service.dart
│   ├── lost_found_service.dart
│   ├── notice_service.dart
│   ├── notification_service.dart  # FCM & local channels
│   ├── profile_stats_service.dart
│   ├── user_profile_service.dart
│   └── user_service.dart
├── utils/                         # Date/time formatters & shared helpers
│   └── date_format_utils.dart
└── widgets/                       # Reusable UI components
    ├── confirm_delete_dialog.dart
    ├── dashboard_home_tab.dart
    ├── entity_action_menu.dart
    ├── event_card.dart
    ├── notice_card.dart
    └── notification_bell.dart
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.12.2` or newer)
- Android Studio / Android SDK (API level 21+)
- A [Firebase Project](https://console.firebase.google.com/) (Free Spark Plan)
- A [Cloudinary Account](https://cloudinary.com/) (Free Tier for media uploads)

---

### Step 1: Clone the Repository
```bash
git clone https://github.com/solanki-vimal/campus_connect.git
cd campus_connect
```

### Step 2: Install Dependencies
```bash
flutter pub get
```

### Step 3: Firebase Configuration
1. Register an Android application in your Firebase console with package name `com.example.campus_connect` (or your configured package ID).
2. Download `google-services.json` and place it in:
   ```
   android/app/google-services.json
   ```
3. Enable **Email/Password** under **Authentication → Sign-in method**.
4. Create a **Cloud Firestore** database.

### Step 4: Configure Cloudinary (For Lost & Found Images)
1. In your [Cloudinary Console](https://cloudinary.com), navigate to **Settings → Upload Presets**.
2. Click **Add Upload Preset**, set **Signing Mode** to **`Unsigned`**, and enter preset name `campus_connect`.
3. Open [`lib/services/image_upload_service.dart`](lib/services/image_upload_service.dart) and configure your cloud details:
   ```dart
   class _CloudinaryConfig {
     static const cloudName = 'YOUR_CLOUD_NAME';
     static const uploadPreset = 'campus_connect';
     // ...
   }
   ```

### Step 5: Run the Application
Connect an Android device or start an Android Virtual Device (AVD), then execute:
```bash
flutter run
```

---

## 🔒 Security Rules

### Firestore Security Rules
Ensure your Cloud Firestore security rules are configured to protect user data and enforce role permissions:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isSignedIn() { return request.auth != null; }
    function myRole() { return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role; }
    function isAdmin() { return isSignedIn() && myRole() == 'super_admin'; }
    function isFaculty() { return isSignedIn() && myRole() == 'faculty'; }
    function isClubCoordinator() { return isSignedIn() && myRole() == 'club_coordinator'; }
    function canPostContent() { return isFaculty() || isAdmin(); }
    function canCreateEvent() { return isFaculty() || isClubCoordinator() || isAdmin(); }

    match /users/{uid} {
      allow read: if isSignedIn();
      allow create: if isSignedIn() && request.auth.uid == uid;
      allow update, delete: if isAdmin() || (isSignedIn() && request.auth.uid == uid);
    }
    match /profiles/{uid} {
      allow read, write: if isSignedIn() && request.auth.uid == uid;
    }
    match /notices/{noticeId} {
      allow read: if isSignedIn();
      allow create: if canPostContent() && request.resource.data.postedBy == request.auth.uid;
      allow update, delete: if isAdmin() || (isFaculty() && resource.data.postedBy == request.auth.uid);
    }
    match /events/{eventId} {
      allow read: if isSignedIn();
      allow create: if canCreateEvent() && request.resource.data.organizerId == request.auth.uid;
      allow update, delete: if isAdmin() || (isSignedIn() && resource.data.organizerId == request.auth.uid);

      match /registrations/{uid} {
        allow read: if isSignedIn();
        allow create, delete: if isSignedIn() && request.auth.uid == uid;
      }
    }
    match /lost_found/{itemId} {
      allow read: if isSignedIn();
      allow create: if isSignedIn() && request.resource.data.postedBy == request.auth.uid;
      allow update, delete: if isAdmin() || (isSignedIn() && resource.data.postedBy == request.auth.uid);
    }
    match /notifications/{uid}/items/{docId} {
      allow read: if isSignedIn() && request.auth.uid == uid;
      allow create: if canPostContent() || canCreateEvent();
      allow update: if isSignedIn() && request.auth.uid == uid;
      allow delete: if isAdmin() || (isSignedIn() && request.auth.uid == uid);
    }
    match /{metadata}/{docId} {
      allow read: if true;
      allow write: if isAdmin();
    }
  }
}
```

---

## 📦 Building for Production

To create an optimized release APK for Android devices:

```bash
flutter build apk --release
```
The output file will be generated at:
```
build/app/outputs/flutter-apk/app-release.apk
```

---

## 🧪 Testing

Run static analysis and unit/widget tests:
```bash
# Check code quality & formatting
flutter analyze

# Execute test suite
flutter test
```

---

## 📄 License
This project is developed as part of university coursework for academic and educational purposes.
