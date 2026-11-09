# NoteOn — Cloud Notes & Tasks

A complete, production-quality **notes + tasks app** built with Flutter that syncs through **Firebase Cloud Firestore** and works fully offline.

Designed for speed, clean UX, and seamless productivity with full **Arabic (RTL)** and **English (LTR)** localization, Material 3 dynamic color theming (Light / Dark / AMOLED Black), and biometrics security.

---

## 🌟 Key Features

### 1. Free-form Notes
- **Rich Text & Formatting**: Bold, italic, underline, strikethrough, headings (H1-H3), bullet/numbered lists, blockquotes, code blocks, links, per-paragraph text direction detection.
- **Checklists & Notes**: Interactive checklists, custom note colors (12 pastel/neutral palettes), pinned notes, folder organization (nestable), and labels.
- **Note Templates**: 1-tap pre-built templates for Meeting Notes, Daily Journal, Shopping List, and Project Plans.
- **Version History**: Subcollection snapshots (keeps last 10 versions) with instant 1-tap restore.
- **Biometric Lock**: Protect sensitive notes with fingerprint or device PIN (content hidden in list previews).
- **Export**: Share as plain text, Markdown, or print/export directly as formatted **PDF**.

### 2. Task Management & Productivity
- **Smart Lists**: Today, Upcoming, Overdue, Important, No Date, Completed, All.
- **Natural-Language Quick Add**: Type phrases like `"Call Ahmed tomorrow 5pm !high #work"` or `"الاتصال بأحمد غداً 5 مساءً !عاجل #عمل"` to automatically extract date, time, priority, and tags in real-time.
- **Views**:
  - **List View** with swipe actions (swipe right to complete, swipe left to postpone +1 day).
  - **Kanban Board** with drag-and-drop between *To Do*, *In Progress*, and *Done*.
  - **Calendar View** with month/week picker, day event markers, and combined day schedule.
  - **Agenda View** grouped chronologically.
- **Subtasks**: Unlimited subtasks with live progress bar.
- **Recurrence Engine**: Daily, weekly (selected weekdays), monthly (with month-end clamping), yearly, and "after completion" (e.g. 3 days after finish).
- **Focus Timer (Pomodoro)**: 25-minute focus session timer with time-spent tracking per task.
- **Bulk Actions**: Multi-select to complete, delete, move, or postpone tasks in batch.

### 3. Notes ↔ Tasks Integration
- Convert any checklist item in a note directly into a task with linked reference.
- Notes show their live linked tasks with completion checkboxes; tasks show their linked note for quick navigation.

### 4. Collaboration & Real-Time Sharing
- Share notes and task lists by **email** with granular roles: **Viewer** and **Editor**.
- **Privacy-First Email Lookup**: Uses SHA-256 hashed lowercase emails (`userDirectory/{emailHash}`) so raw emails are never exposed or listed.
- Revoke access at any time.

### 5. Offline Persistence & Free Spark Plan Constraint
- **100% Spark Plan Compatible**: Uses only Firebase Authentication and Cloud Firestore (no Cloud Functions or Cloud Storage required).
- **Offline First**: Cloud Firestore offline cache is permanently enabled; UI never blocks on network.
- **Attachments Feature Flag**: Image/file attachments are gated behind `AppConstants.kAttachmentsEnabled = false` (enabled when upgrading to Blaze plan).
- **Debounced Writes**: Edits are automatically debounced (800 ms) to conserve Spark plan daily quotas.

---

## 🛠 Tech Stack

- **Flutter**: 3.x (Dart 3.x null-safety)
- **State Management**: [Riverpod](https://riverpod.dev/) (`flutter_riverpod: 2.6.1`)
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router)
- **Firebase**: `firebase_core`, `firebase_auth`, `cloud_firestore`, `google_sign_in`
- **Rich Text**: `flutter_quill` (stores Delta JSON)
- **Notifications**: `flutter_local_notifications`, `timezone`
- **Security & Storage**: `local_auth` (biometrics), `shared_preferences`, `flutter_secure_storage`
- **Localization**: `flutter_localizations`, ARB files (`app_en.arb`, `app_ar.arb`), full RTL support

---

## 📁 Project Structure

```
lib/
  core/
    constants/       # AppConstants (kAttachmentsEnabled, debounce times, colors)
    errors/          # AppException, Result<T> sealed class
    l10n/            # ARB localization files (ar, en) & LocaleProvider
    router/          # GoRouter configuration & routes
    theme/           # AppTheme (Light, Dark, AMOLED), ThemeProvider
    utils/           # ArabicSearchNormalizer, NaturalLanguageParser, RecurrenceEngine, ConflictHandler
  data/
    models/          # UserModel, NoteModel, TaskModel, TaskListModel, LabelModel, FolderModel
    providers/       # Riverpod repository & sync status providers
    repositories/    # Auth, Notes, Tasks, TaskLists, Labels, Folders, Sharing
  features/
    auth/            # Onboarding, AuthScreen, FirebaseSetupScreen
    calendar/        # TableCalendar integration & day agenda
    export_import/   # JSON full backup, CSV export, Markdown & PDF export
    folders/         # Folder browser & nesting
    home/            # MainShellScreen (BottomNav + Speed Dial FAB), SyncStatusIndicator
    labels/          # Label management & tag filtering
    notes/           # NotesListScreen, NoteEditorScreen, NoteCardWidget, VersionHistory, Trash, Archive
    reminders/       # ReminderService (local scheduled notifications & agenda)
    search/          # Instant search with Arabic normalization
    settings/        # AppLockScreen, AppLockService, SettingsScreen
    sharing/         # ShareDocumentDialog, SharedWithMeScreen
    stats/           # Productivity KPIs & 7-day completion BarChart
    tasks/           # TasksScreen, TaskDetailScreen, KanbanBoardView, QuickAddDialog
    widgets/         # HomeWidgetService (Android home-screen widgets)
  firebase_options.dart
  main.dart
firestore.rules       # Strict security rules (deny by default, field validation)
firestore.indexes.json# Composite indexes for memberIds & sorting
firebase.json        # Firebase configuration & emulator ports
```

---

## 🚀 Firebase Setup Guide

Follow these exact steps to connect NoteOn to your Firebase project:

### Firebase Project Details
- **Project Name**: Note On
- **Project ID**: `note-on-mkdevofficial`

### Step 1: Install & Log in to Firebase CLI
```bash
npm install -g firebase-tools
firebase login
```

### Step 2: Configure FlutterFire
From the project root directory, run:
```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=note-on-mkdevofficial
```
Select **Android** (and any other target platforms e.g. Web/iOS). This updates `lib/firebase_options.dart` and places `android/app/google-services.json`.

### Step 3: Get SHA-1 and SHA-256 Fingerprints for Android
In the `android/` directory, run:
```bash
cd android
./gradlew signingReport
```
Copy the **SHA-1** and **SHA-256** from the `debug` (and `release`) variant and add them to:
**Firebase Console → Project Settings → Your Android App → Add fingerprint**.

*Note for GitHub Actions CI*: If building release APKs in GitHub Actions, generate a keystore or add the CI keystore fingerprint to the Firebase Console so Google Sign-In functions on CI builds.

### Step 4: Enable Authentication Providers
In **Firebase Console → Authentication → Sign-in method**, enable:
1. **Email/Password**
2. **Google**
3. **Anonymous**

### Step 5: Create Cloud Firestore Database
1. Go to **Firebase Console → Firestore Database**.
2. Click **Create database** (start in standard mode).
3. Select your preferred Cloud region.

### Step 6: Deploy Security Rules & Composite Indexes
Deploy the pre-written strict security rules and composite indexes:
```bash
firebase deploy --only firestore:rules,firestore:indexes
```

---

## 🧪 Testing

### 1. Flutter Unit & Widget Tests
Run the complete test suite:
```bash
flutter test
```
All unit tests verify:
- **Arabic Search Normalization**: Stripping tashkeel, unifying Alef/Yaa/Taa Marbuta variations.
- **Natural Language Parsing**: English and Arabic quick-add strings with dates, times, priorities, and tags.
- **Recurrence Engine**: Daily, weekly (specific weekdays), monthly (month boundary clamping), and after-completion recurrence.
- **Conflict Handling**: Last-write-wins by timestamp with automatic history snapshot archiving.

### 2. Firestore Security Rules Unit Tests
Start the Firebase emulator:
```bash
firebase emulators:start --only firestore
```
In another terminal, run:
```bash
cd test/rules
npm install
npm test
```

---

## 📦 Building Release APKs

Build optimized release APKs split per CPU architecture (`armeabi-v7a`, `arm64-v8a`, `x86_64`):
```bash
flutter build apk --split-per-abi
```
The resulting APKs will be located in:
`build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`
`build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`

---

## 📄 License
MIT License.
