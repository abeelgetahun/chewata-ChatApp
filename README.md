
# Chewata 💬

Chewata is a modern, cross‑platform chat and social app built with Flutter. It features real‑time 1:1 chat, presence (online/last seen), read/delivered receipts, random connections, privacy controls, and a clean, responsive UI.


## Demo account (quick test) 🔑
- Email: abel@gmai.com
- Password: 123456

If this account isn’t available in your Firebase project, create it in Firebase Authentication (Email/Password) or sign up in the app once and then reuse the credentials.


## Highlights ✨
- 🔐 Authentication: Firebase Email/Password with robust error handling
- 💬 Real‑time chat: Firestore streams, unread badge per participant, lazy loading
- 🟢 Presence: Online/offline mirrored via RTDB + Firestore last seen
- ✅ Receipts: Single check = delivered, double blue check = seen
- 🔎 Search: Type‑ahead search by email and name prefixes
- 🛡️ Privacy: Mutual online visibility (both users must allow it)
- 🎲 Random Connect: Anonymous match to start a quick chat
- 🧽 Messages: Edit, soft‑delete, clear your side, hide chats
- 🌓 Theming: Light/Dark/System (persisted)
- 🛟 Stability: Global error guard, session auto‑logout after inactivity


## Quick start ⚡
Prerequisites
- Flutter (stable). 3.22+ recommended
- A Firebase project with Firestore, Authentication, and Realtime Database enabled

On Windows cmd.exe
1) Clone and enter the project
	```bat
	git clone https://github.com/abeelgetahun/chewata-ChatApp.git
	cd chewata
	```
2) Install dependencies
	```bat
	flutter pub get
	```
3) Configure Firebase
	- Add platform files (Android: android/app/google-services.json; iOS: GoogleService-Info.plist)
	- Create a `.env` file with Firebase keys used by `lib/firebase_options.dart`
	<details>
	<summary>Show .env keys (advanced)</summary>

	```
	WEB_API_KEY=
	WEB_APP_ID=
	WEB_MESSAGING_SENDER_ID=
	WEB_PROJECT_ID=
	WEB_AUTH_DOMAIN=
	WEB_STORAGE_BUCKET=
	WEB_MEASUREMENT_ID=

	ANDROID_API_KEY=
	ANDROID_APP_ID=
	ANDROID_MESSAGING_SENDER_ID=
	ANDROID_PROJECT_ID=
	ANDROID_STORAGE_BUCKET=

	IOS_API_KEY=
	IOS_APP_ID=
	IOS_MESSAGING_SENDER_ID=
	IOS_PROJECT_ID=
	IOS_STORAGE_BUCKET=
	IOS_BUNDLE_ID=

	MACOS_API_KEY=
	MACOS_APP_ID=
	MACOS_MESSAGING_SENDER_ID=
	MACOS_PROJECT_ID=
	MACOS_STORAGE_BUCKET=
	MACOS_BUNDLE_ID=

	WINDOWS_API_KEY=
	WINDOWS_APP_ID=
	WINDOWS_MESSAGING_SENDER_ID=
	WINDOWS_PROJECT_ID=
	WINDOWS_AUTH_DOMAIN=
	WINDOWS_STORAGE_BUCKET=
	WINDOWS_MEASUREMENT_ID=
	```

	Notes
	- `.env` is listed in `pubspec.yaml` assets. Don’t place production secrets here.
	- Update `lib/utils/link.dart` to your Realtime Database URL if different.
	</details>

4) Run the app
	```bat
	flutter run
	```
	Examples
	```bat
	flutter run -d chrome
	flutter run -d windows
	```


<details>
<summary><b>App structure 📦</b></summary>

```
lib/
  main.dart                  // Bootstraps Firebase, splash, dotenv, ThemeController
  app.dart                   // GetMaterialApp, routes, observers, session activity hooks
  controller/                // GetX controllers (auth, chat, account, theme, onboarding, ...)
  services/                  // AuthService, ChatService, Settings, UserService
  models/                    // UserModel, ChatModel, MessageModel
  screen/                    // UI (auth, chat, search, home, random connect, account, ...)
  utils/                     // constants, theme, helpers, links (.env + RTDB URL)
```

</details>


<details>
<summary><b>Data model and behavior 🗃️ (advanced)</b></summary>

Firestore collections
- users: user profile, preferences, presence mirror (isOnline, lastSeen)
- chats: per conversation
	- participants: [uid]
	- unreadCount: { uid: number }
	- hiddenBy: { uid: bool }
	- lastMessageText, lastMessageTime, lastMessageSenderId
	- pairKey: sorted pair key for 1:1 uniqueness
	- messages (subcollection): message documents
- messages (legacy): some older data stored top‑level; the app merges both sources

Realtime Database
- status/{uid}: { online: bool, lastChanged: server timestamp }
	- onDisconnect hook ensures reliable offline marking
	- Firestore is kept in sync for lastSeen and isOnline to power UI

Receipts and counts
- Delivered/Seen: message.isDelivered and message.isRead, with UI checkmarks
- Unread per user: chats.unreadCount[uid] maintained on send/read

Privacy reciprocity
- A user only sees another user’s online/last seen if BOTH have "showOnlineStatus" enabled

Messages
- Edit, soft delete, clear only your messages; optional hard delete for everyone

Pagination and performance
- Chats load in batches (lazy loading) with shimmer placeholders

Session management
- Inactivity timer (7 days) logs the user out; any activity resets the timer

</details>


## Feature tour (how to test) 🎯
1) Login
	- Use the demo account above, or tap Sign Up to create your own.
2) Search & start chat
	- Search a user by email or name prefix. Tap to create/open the chat.
3) Send messages
	- Observe delivered (✓) and seen (✓✓ blue) states. Unread count shows on the list.
4) Presence
	- Online dot and "last seen" respect privacy settings mutually.
5) Manage chats
	- Long‑press a message to copy/edit/delete. Long‑press a chat to hide, clear my messages, or delete for everyone.
6) Random connect
	- Use the Connect tab to start an anonymous, one‑off chat.
7) Theme
	- Tap the moon icon in the app bar to switch Light/Dark/System.


<details>
<summary><b>Required Firestore indexes 🧩</b></summary>

Firebase may prompt you to create these on first run:
- chats where participants arrayContains == <uid> ordered by lastMessageTime desc
- users ordered by email (prefix search) and by fullName (prefix search)

Create indexes from the Firebase console when links appear in logs, or pre‑create them in Firestore Indexes UI.

</details>


<details>
<summary><b>Troubleshooting 🔧</b></summary>

- Blank screen on startup: ensure .env contains all required keys and is listed under assets in pubspec.yaml (it is)
- Presence not updating: verify `lib/utils/link.dart` points to your RTDB URL and that Realtime Database is enabled
- Auth errors: make sure Email/Password sign‑in is enabled in Firebase Authentication; check Firestore/RTDB rules
- Missing chats/messages: if you migrated from legacy top‑level messages, ensure rules permit reads

</details>


<details>
<summary><b>Dependencies 📦 (selection)</b></summary>

- Firebase: firebase_core, firebase_auth, cloud_firestore, firebase_database
- State and routing: get
- UI/UX: google_fonts, flutter_svg, google_nav_bar, shimmer, lottie, intl
- Platform: shared_preferences, url_launcher, package_info_plus
- DevOps: flutter_native_splash, flutter_launcher_icons

See pubspec.yaml for full versions.

</details>


## License 📝
© 2025 Chewata. All rights reserved.