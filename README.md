
# Chewata

Chewata is a cross-platform chat and social app built with Flutter, designed to connect sports enthusiasts and friends. It offers real-time messaging, random connections, group chats, privacy controls, and a modern, customizable UI.

 
## Features
- **User Authentication**: Secure login and registration using Firebase Auth.
- **Real-Time Chat**: 1-to-1 and group messaging with online status indicators.
- **Random Connections**: Connect and chat anonymously with random users.
- **Group Chats**: Create and join group chats for fun and collaboration.
- **Profile Management**: Edit personal info, profile picture, and privacy settings.
- **Theme Support**: Light, dark, and system themes.
- **Privacy Controls**: Manage online status visibility and notifications.
- **Modern UI**: Animated transitions, custom icons, and responsive design.
- **Multi-Platform**: Runs on Android, iOS, Web, Windows, macOS, and Linux.

## Screenshots
> _Add screenshots of main screens here (Home, Chat, Connect, Fun, Account)_

## Getting Started
1. **Clone the repository:**
	```sh
	git clone https://github.com/abeelgetahun/chewata-ChatApp.git
	cd chewata
	```
2. **Install dependencies:**
	```sh
	flutter pub get
	```
3. **Set up Firebase:**
	- Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) to the respective folders.
	- Update `firebase_options.dart` using the [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/).
4. **Run the app:**
	```sh
	flutter run
	```
5. **Web/Desktop:**
	```sh
	flutter run -d chrome   # For web
	flutter run -d windows  # For Windows
	flutter run -d macos    # For macOS
	flutter run -d linux    # For Linux
	```

## Project Structure
```
chewata/
  lib/
	 app.dart                # Main app widget and routing
	 main.dart               # Entry point, Firebase & theme init
	 controller/             # State management controllers
	 models/                 # Data models (User, Chat, Message)
	 screen/                 # UI screens (Home, Chat, Connect, Fun, Account)
	 services/               # Business logic (Auth, Chat, Settings)
	 utils/                  # Utilities and themes
  assets/
	 fonts/                  # Custom fonts (Poppins, WinkySans)
	 icons/                  # SVG and PNG icons
	 images/                 # App images
  android/ios/web/windows/linux/macos/  # Platform-specific code
  pubspec.yaml              # Dependencies and assets
  README.md                 # Project documentation
```

## Dependencies
Key packages:
- `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_database`: Backend and real-time data
- `get`: State management and navigation
- `flutter_native_splash`, `flutter_launcher_icons`: Branding
- `intl`, `lottie`, `shimmer`, `package_info_plus`, `shared_preferences`, `uuid`, `url_launcher`, `flutter_svg`, `google_nav_bar`, `iconsax`, `smooth_page_indicator`

See `pubspec.yaml` for the full list.

## Functionality Overview
- **Home Screen**: Tab navigation for Chewata (chat), Connect (random chat), Fun (group chat), and Account.
- **Chat**: Real-time messaging, unread counts, online status, search users, animated transitions.
- **Connect**: Match with random users based on activity and age similarity, anonymous chat, end chat anytime.
- **Fun**: Create/join group chats, select members, send messages, group info and avatars.
- **Account**: View/edit profile, privacy settings, theme selection, help center, terms & privacy, logout.
- **Privacy & Notifications**: Toggle online status, enable/disable notifications.
- **About App**: App info, version, social media (coming soon).

## Contributing
Pull requests are welcome! For major changes, please open an issue first to discuss what you would like to change.

## License
© 2025 Chewata. All rights reserved.
